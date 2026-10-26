import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/ble_advertisement.dart';
import '../../domain/models/ble_status.dart';
import 'ble_scanner_service.dart';

/// Real BLE scanner backed by flutter_blue_plus 1.35.x.
///
/// Design notes
/// ------------
/// * `continuousUpdates: true` (with `continuousDivisor: 1`) is the modern
///   replacement for the old `allowDuplicates` flag: every advertisement packet
///   is emitted, which is what makes RSSI smoothing possible. Without it
///   Android reports each device roughly once per scan session.
/// * The scan itself is continuous. A 10 s watchdog only restarts it when the
///   OS silently stopped scanning (adapter toggled, OEM battery manager),
///   because restarting every few seconds would trip Android's scan throttling.
/// * flutter_blue_plus re-emits every known device whenever any packet arrives;
///   `_lastPacketAt` keeps only genuinely fresh samples so the EMA is not fed
///   stale readings.
/// * The controller turns the raw stream into immutable UI snapshots at 1 Hz.
class FlutterBlueScannerService implements BleScannerService {
  FlutterBlueScannerService();

  final StreamController<BleAdvertisement> _advertisements =
      StreamController<BleAdvertisement>.broadcast();
  final StreamController<BleAdapterStatus> _adapterStatus =
      StreamController<BleAdapterStatus>.broadcast();
  final StreamController<String> _errors = StreamController<String>.broadcast();

  StreamSubscription<List<ScanResult>>? _resultsSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  Timer? _restartTimer;

  BleAdapterStatus _currentStatus = BleAdapterStatus.unknown;
  bool _started = false;
  bool _disposed = false;

  /// flutter_blue_plus re-emits every known device whenever *any* packet
  /// arrives; the timestamp lets us ignore the stale entries so the EMA only
  /// consumes genuinely fresh samples.
  final Map<String, DateTime> _lastPacketAt = <String, DateTime>{};

  @override
  String get name => 'flutter_blue_plus';

  @override
  bool get isMock => false;

  @override
  Stream<BleAdvertisement> get advertisements => _advertisements.stream;

  @override
  Stream<BleAdapterStatus> get adapterStatus => _adapterStatus.stream;

  @override
  Stream<String> get errors => _errors.stream;

  @override
  BleAdapterStatus get currentAdapterStatus => _currentStatus;

  void _ensureListeners() {
    _resultsSubscription ??= FlutterBluePlus.scanResults.listen(
      _onScanResults,
      onError: (Object error) {
        debugPrint('BLE scan stream error: $error');
        if (!_errors.isClosed) _errors.add(error.toString());
      },
    );
    _adapterSubscription ??= FlutterBluePlus.adapterState.listen(
      (BluetoothAdapterState state) {
        _currentStatus = _mapAdapterState(state);
        if (!_adapterStatus.isClosed) _adapterStatus.add(_currentStatus);
      },
      onError: (Object error) {
        debugPrint('BLE adapter stream error: $error');
      },
    );
  }

  @override
  Future<void> start() async {
    if (_disposed) return;
    _ensureListeners();
    _started = true;

    try {
      final bool supported = await FlutterBluePlus.isSupported;
      if (!supported) {
        _currentStatus = BleAdapterStatus.unsupported;
        if (!_adapterStatus.isClosed) _adapterStatus.add(_currentStatus);
        return;
      }

      final BluetoothAdapterState state = await FlutterBluePlus.adapterState.first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => BluetoothAdapterState.unknown,
      );
      _currentStatus = _mapAdapterState(state);
      if (!_adapterStatus.isClosed) _adapterStatus.add(_currentStatus);
      if (_currentStatus != BleAdapterStatus.poweredOn) return;

      await _startScan();
      _restartTimer?.cancel();
      _restartTimer = Timer.periodic(AppConstants.scanWatchdogInterval, (Timer _) {
        _restartScanIfNeeded();
      });
    } on Exception catch (error) {
      _reportStartFailure(error.toString());
    }
  }

  void _reportStartFailure(String message) {
    final bool permission = message.toLowerCase().contains('security') ||
        message.toLowerCase().contains('permission') ||
        message.toLowerCase().contains('not authorized');
    if (!_errors.isClosed) {
      _errors.add(BleScanException(message, isPermissionError: permission).toString());
    }
  }

  Future<void> _startScan() async {
    await FlutterBluePlus.startScan(
      // continuousUpdates is flutter_blue_plus' replacement for the old
      // allowDuplicates flag: Android reports *every* advertisement packet so
      // the EMA filter has fresh samples instead of one reading per device.
      continuousUpdates: true,
      continuousDivisor: 1,
      // We request permissions ourselves (BLUETOOTH_SCAN with neverForLocation
      // on Android 12+), so the plugin must not require GPS to be enabled.
      androidCheckLocationServices: false,
      androidScanMode: AndroidScanMode.lowLatency,
    );
  }

  Future<void> _restartScanIfNeeded() async {
    if (_disposed || !_started) return;
    if (_currentStatus != BleAdapterStatus.poweredOn) return;
    try {
      if (!FlutterBluePlus.isScanningNow) {
        await _startScan();
      }
    } on Exception catch (error) {
      debugPrint('BLE scan restart failed: $error');
      if (!_errors.isClosed) _errors.add(error.toString());
    }
  }

  void _onScanResults(List<ScanResult> results) {
    if (_disposed) return;
    final DateTime now = DateTime.now();
    for (final ScanResult result in results) {
      if (result.rssi == 0) continue;
      final String deviceId = result.device.remoteId.str;
      final DateTime? previous = _lastPacketAt[deviceId];
      if (previous != null && !result.timeStamp.isAfter(previous)) continue;
      _lastPacketAt[deviceId] = result.timeStamp;
      final AdvertisementData data = result.advertisementData;
      final String advertisedName = data.advName.trim();
      final String platformName = result.device.platformName.trim();
      if (!_advertisements.isClosed) {
        _advertisements.add(
          BleAdvertisement(
            id: deviceId,
            name: advertisedName.isNotEmpty ? advertisedName : platformName,
            rssi: result.rssi,
            timestamp: now,
            txPower: data.txPowerLevel,
            isConnectable: data.connectable,
            serviceUuids: data.serviceUuids
                .map((Guid uuid) => uuid.str.toLowerCase())
                .toList(growable: false),
            manufacturerData: _manufacturerPayload(data),
          ),
        );
      }
    }
  }

  /// flutter_blue_plus exposes manufacturer data as `{companyId: payload}`;
  /// the classifier wants the raw AD bytes, which start with the company id.
  List<int> _manufacturerPayload(AdvertisementData data) {
    if (data.manufacturerData.isEmpty) return const <int>[];
    final int companyId = data.manufacturerData.keys.first & 0xFFFF;
    final List<int> payload = data.manufacturerData.values.first;
    return <int>[
      companyId & 0xFF,
      (companyId >> 8) & 0xFF,
      ...payload,
    ];
  }

  BleAdapterStatus _mapAdapterState(BluetoothAdapterState state) {
    switch (state) {
      case BluetoothAdapterState.on:
        return BleAdapterStatus.poweredOn;
      case BluetoothAdapterState.off:
        return BleAdapterStatus.poweredOff;
      case BluetoothAdapterState.unauthorized:
        return BleAdapterStatus.unauthorized;
      case BluetoothAdapterState.unavailable:
        return BleAdapterStatus.unsupported;
      case BluetoothAdapterState.unknown:
        return BleAdapterStatus.unknown;
      case BluetoothAdapterState.turningOn:
      case BluetoothAdapterState.turningOff:
        return BleAdapterStatus.unknown;
    }
  }

  /// Android only: shows the system "turn on Bluetooth" consent dialog.
  Future<bool> requestTurnOn() async {
    try {
      await FlutterBluePlus.turnOn();
      return true;
    } on Exception catch (error) {
      debugPrint('turnOn failed: $error');
      return false;
    }
  }

  @override
  Future<void> stop() async {
    _started = false;
    _lastPacketAt.clear();
    _restartTimer?.cancel();
    _restartTimer = null;
    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
    } on Exception catch (error) {
      debugPrint('stopScan failed: $error');
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _resultsSubscription?.cancel();
    await _adapterSubscription?.cancel();
    _resultsSubscription = null;
    _adapterSubscription = null;
    await _advertisements.close();
    await _adapterStatus.close();
    await _errors.close();
  }
}
