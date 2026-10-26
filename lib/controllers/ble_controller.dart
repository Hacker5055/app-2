import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/stable_angle.dart';
import '../data/repositories/ble_repository.dart';
import '../data/services/ble_scanner_service.dart';
import '../data/services/gatt_alert_service.dart';
import '../data/services/permission_service.dart';
import '../domain/models/ble_advertisement.dart';
import '../domain/models/ble_device.dart';
import '../domain/models/ble_status.dart';
import '../domain/models/device_classifier.dart';
import '../domain/models/device_kind.dart';
import '../domain/signal/exponential_moving_average.dart';
import '../domain/signal/path_loss_calculator.dart';
import 'settings_controller.dart';

/// Mutable per-device pipeline state — never leaves this library.
class _DevicePipeline {
  _DevicePipeline({
    required this.id,
    required this.isMock,
    required DateTime timestamp,
    required this.ema,
    required this.name,
    required this.kind,
  })  : firstSeen = timestamp,
        lastSeen = timestamp;

  final String id;
  final bool isMock;
  final DateTime firstSeen;
  final ExponentialMovingAverage ema;

  DateTime lastSeen;
  String name;
  DeviceKind kind;
  List<String> serviceUuids = const <String>[];
  int? txPower;
  bool isConnectable = false;
  double rawRssi = 0;
  double smoothedRssi = 0;
  double bearing = 0;
  bool bearingFromSweep = false;
  bool supportsAlertService = false;
  bool alertsChecked = false;
  bool found = false;
  final List<double> history = <double>[];
}

/// Orchestrates the BLE pipeline:
///
/// ```
/// radio → BleRepository → EMA filter → path-loss model → 1 Hz snapshot → UI
/// ```
///
/// Advertisement packets can arrive 5–20× per second per device. The controller
/// absorbs all of them into the filters but only publishes immutable
/// [BleDevice] snapshots once per second, so the radar never flickers.
class BleController extends ChangeNotifier {
  BleController({
    required BleRepository repository,
    required SettingsController settings,
    required PermissionService permissions,
  })  : _repository = repository,
        _settings = settings,
        _permissions = permissions {
    _settings.addListener(_onSettingsChanged);
  }

  final BleRepository _repository;
  final SettingsController _settings;
  final PermissionService _permissions;

  final Map<String, _DevicePipeline> _pipelines = <String, _DevicePipeline>{};

  BleSessionStatus _status = BleSessionStatus.initializing;
  BleAdapterStatus _adapterStatus = BleAdapterStatus.unknown;
  String? _errorMessage;
  bool _permissionPermanentlyDenied = false;
  bool _activeSourceIsMock = false;
  bool _paused = false;
  bool _initialized = false;
  bool _disposed = false;
  bool _switchingSource = false;

  DeviceKind? _kindFilter;
  String _query = '';
  String? _selectedId;
  List<BleDevice> _devices = const <BleDevice>[];
  DateTime _now = DateTime.now();

  StreamSubscription<BleAdvertisement>? _realAdSubscription;
  StreamSubscription<BleAdvertisement>? _mockAdSubscription;
  StreamSubscription<BleAdapterStatus>? _realAdapterSubscription;
  StreamSubscription<BleAdapterStatus>? _mockAdapterSubscription;
  StreamSubscription<String>? _realErrorSubscription;
  StreamSubscription<String>? _mockErrorSubscription;
  Timer? _uiTimer;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------
  BleSessionStatus get status => _status;

  BleAdapterStatus get adapterStatus => _adapterStatus;

  String? get errorMessage => _errorMessage;

  bool get permissionPermanentlyDenied => _permissionPermanentlyDenied;

  bool get isMockMode => _settings.mockMode;

  bool get isPaused => _paused;

  bool get isScanning => _status.isScanningActive && !_paused;

  DateTime get now => _now;

  DeviceKind? get kindFilter => _kindFilter;

  String get query => _query;

  String? get selectedId => _selectedId;

  List<BleDevice> get allDevices => _devices;

  /// Filtered + sorted (nearest first) list for the scanner screen.
  List<BleDevice> get devices {
    final String needle = _query.trim().toLowerCase();
    final List<BleDevice> filtered = _devices.where((BleDevice device) {
      if (_kindFilter != null && device.kind != _kindFilter) return false;
      if (needle.isEmpty) return true;
      return device.name.toLowerCase().contains(needle) ||
          device.id.toLowerCase().contains(needle) ||
          device.shortId.toLowerCase().contains(needle);
    }).toList(growable: false);
    return filtered.sortedByDistance();
  }

  List<BleDevice> sortedBySignal() => _devices.sortedBySignal();

  BleDevice? get nearest {
    final List<BleDevice> list = devices;
    return list.isEmpty ? null : list.first;
  }

  BleDevice? get strongest {
    final List<BleDevice> ranked = _devices.sortedBySignal();
    return ranked.isEmpty ? null : ranked.first;
  }

  BleDevice? get selectedDevice => deviceById(_selectedId);

  /// Live (sub-second) smoothed RSSI for the sweep assistant.
  ///
  /// The radar UI only refreshes at 1 Hz, but the direction finder samples at
  /// up to 20 Hz while the user rotates, so it reads straight from the filter.
  double? latestSmoothedRssi(String id) => _pipelines[id]?.smoothedRssi;

  BleDevice? deviceById(String? id) {
    if (id == null) return null;
    for (final BleDevice device in _devices) {
      if (device.id == id) return device;
    }
    return null;
  }

  Map<DeviceKind, int> get kindCounts {
    final Map<DeviceKind, int> counts = <DeviceKind, int>{
      for (final DeviceKind kind in DeviceKind.values) kind: 0,
    };
    for (final BleDevice device in _devices) {
      counts[device.kind] = (counts[device.kind] ?? 0) + 1;
    }
    return counts;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  Future<void> initialize() async {
    if (_initialized || _disposed) return;
    _initialized = true;
    _bindStreams();
    _uiTimer = Timer.periodic(AppConstants.uiRefreshInterval, (Timer _) => _emitSnapshot());

    if (_settings.mockMode) {
      await _startMock();
      return;
    }

    if (!await _permissions.hasBlePermissions()) {
      _setStatus(BleSessionStatus.permissionRequired);
      return;
    }
    await _startReal();
  }

  void _bindStreams() {
    _realAdSubscription = _repository.realAdvertisements.listen(_onAdvertisement);
    _mockAdSubscription = _repository.mockAdvertisements.listen(_onAdvertisement);
    _realAdapterSubscription = _repository.realAdapterStatus.listen(_onAdapterStatus);
    _mockAdapterSubscription = _repository.mockAdapterStatus.listen((BleAdapterStatus status) {
      if (_settings.mockMode) _adapterStatus = status;
    });
    _realErrorSubscription = _repository.realErrors.listen(_onScannerError);
    _mockErrorSubscription = _repository.mockErrors.listen(_onScannerError);
  }

  // ---------------------------------------------------------------------------
  // Scanner state machine
  // ---------------------------------------------------------------------------
  Future<void> requestPermissions() async {
    _errorMessage = null;
    _setStatus(BleSessionStatus.initializing);
    final PermissionOutcome outcome = await _permissions.requestBlePermissions();
    _permissionPermanentlyDenied = outcome.permanentlyDenied;
    if (!outcome.granted) {
      _setStatus(
        outcome.permanentlyDenied
            ? BleSessionStatus.permissionPermanentlyDenied
            : BleSessionStatus.permissionDenied,
      );
      return;
    }
    await _startReal();
  }

  Future<void> continueInDemoMode() async {
    _permissionPermanentlyDenied = false;
    _errorMessage = null;
    if (_settings.mockMode) {
      await _startMock();
    } else {
      // Flipping the preference restarts the pipeline through
      // _onSettingsChanged, including when the permission gate is showing.
      _settings.setMockMode(true);
      if (!_activeSourceIsMock) await _startMock();
    }
  }

  Future<void> openSystemSettings() async {
    await _permissions.openAppSettingsPage();
  }

  Future<void> enableBluetooth() async {
    final bool requested = await _repository.requestBluetoothEnable();
    if (!requested) {
      await _permissions.openAppSettingsPage();
    } else {
      // The adapter stream reports the new state; nudge it just in case.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await retry();
    }
  }

  Future<void> retry() async {
    _errorMessage = null;
    if (_settings.mockMode) {
      await _startMock();
    } else {
      await requestPermissions();
    }
  }

  Future<void> _startMock() async {
    if (_disposed) return;
    _paused = false;
    _activeSourceIsMock = true;
    _adapterStatus = BleAdapterStatus.poweredOn;
    _setStatus(BleSessionStatus.demoMode);
    try {
      await _repository.activate(useMock: true);
    } on Exception catch (error) {
      _fail('Mock scanner failed: $error');
    }
  }

  Future<void> _startReal() async {
    if (_disposed) return;
    if (!await _permissions.hasBlePermissions()) {
      _setStatus(BleSessionStatus.permissionRequired);
      return;
    }
    _paused = false;
    _activeSourceIsMock = false;
    try {
      await _repository.activate(useMock: false);
    } on BleScanException catch (error) {
      _handleScanException(error);
      return;
    } on Exception catch (error) {
      _fail(error.toString());
      return;
    }

    _adapterStatus = _repository.realAdapterState;
    switch (_adapterStatus) {
      case BleAdapterStatus.poweredOn:
        _setStatus(BleSessionStatus.scanning);
      case BleAdapterStatus.poweredOff:
        _setStatus(BleSessionStatus.adapterOff);
      case BleAdapterStatus.unsupported:
        _setStatus(BleSessionStatus.adapterUnsupported);
      case BleAdapterStatus.unauthorized:
        _setStatus(BleSessionStatus.unauthorized);
      case BleAdapterStatus.unknown:
        _setStatus(BleSessionStatus.scanning);
    }
  }

  void _handleScanException(BleScanException error) {
    _errorMessage = error.message;
    if (error.isPermissionError) {
      _setStatus(BleSessionStatus.permissionDenied);
    } else {
      _fail(error.message, status: BleSessionStatus.error);
    }
  }

  void _onAdapterStatus(BleAdapterStatus status) {
    _adapterStatus = status;
    if (_settings.mockMode || _status == BleSessionStatus.permissionRequired) return;
    if (_status == BleSessionStatus.permissionDenied ||
        _status == BleSessionStatus.permissionPermanentlyDenied ||
        _status == BleSessionStatus.initializing) {
      return;
    }
    switch (status) {
      case BleAdapterStatus.poweredOn:
        if (_status != BleSessionStatus.scanning && _status != BleSessionStatus.paused) {
          _setStatus(BleSessionStatus.scanning);
        }
      case BleAdapterStatus.poweredOff:
        _setStatus(BleSessionStatus.adapterOff);
      case BleAdapterStatus.unsupported:
        _setStatus(BleSessionStatus.adapterUnsupported);
      case BleAdapterStatus.unauthorized:
        _setStatus(BleSessionStatus.unauthorized);
      case BleAdapterStatus.unknown:
        break;
    }
  }

  void _onScannerError(String message) {
    if (_settings.mockMode) return;
    _errorMessage = message;
    final String lower = message.toLowerCase();
    if (lower.contains('security') || lower.contains('permission') || lower.contains('authorized')) {
      _setStatus(BleSessionStatus.permissionDenied);
    } else {
      notifyListeners();
    }
  }

  void _fail(String message, {BleSessionStatus status = BleSessionStatus.error}) {
    _errorMessage = message;
    _setStatus(status);
  }

  void _setStatus(BleSessionStatus status) {
    if (_status == status) {
      notifyListeners();
      return;
    }
    _status = status;
    notifyListeners();
  }

  Future<void> togglePause() async {
    _paused = !_paused;
    try {
      if (_paused) {
        await _repository.stopAll();
        _setStatus(BleSessionStatus.paused);
      } else if (_settings.mockMode) {
        await _startMock();
      } else {
        await _startReal();
      }
    } on Exception catch (error) {
      _fail(error.toString());
    }
    notifyListeners();
  }

  Future<void> _restartSource() async {
    if (_switchingSource || _disposed) return;
    _switchingSource = true;
    try {
      _pipelines.clear();
      _devices = const <BleDevice>[];
      _selectedId = null;
      if (_settings.mockMode) {
        await _startMock();
      } else {
        await _startReal();
      }
    } finally {
      _switchingSource = false;
    }
  }

  Future<void> setMockMode(bool enabled) async {
    if (_settings.mockMode == enabled) return;
    _settings.setMockMode(enabled);
  }

  Future<void> rescan() async {
    await _restartSource();
  }

  // ---------------------------------------------------------------------------
  // Signal pipeline
  // ---------------------------------------------------------------------------
  void _onAdvertisement(BleAdvertisement advertisement) {
    if (_disposed) return;
    if (advertisement.isMock != _settings.mockMode) return;
    if (_paused) return;

    _DevicePipeline? pipeline = _pipelines[advertisement.id];
    if (pipeline == null) {
      if (_pipelines.length >= AppConstants.maxDevices) {
        _evictOldest();
      }
      final String resolvedName = advertisement.name.trim();
      pipeline = _DevicePipeline(
        id: advertisement.id,
        isMock: advertisement.isMock,
        timestamp: advertisement.timestamp,
        ema: ExponentialMovingAverage(alpha: _settings.emaAlpha),
        name: resolvedName,
        kind: DeviceClassifier.classify(
          name: resolvedName,
          advertisedName: advertisement.name,
          serviceUuids: advertisement.serviceUuids,
          manufacturerData: advertisement.manufacturerData,
        ),
      )..bearing = StableAngle.radiansFromId(advertisement.id);
      _pipelines[advertisement.id] = pipeline;
    }

    final String resolvedName =
        advertisement.name.trim().isNotEmpty ? advertisement.name.trim() : pipeline.name;
    pipeline.ema.alpha = _settings.emaAlpha;
    final double smoothed = pipeline.ema.addRssi(advertisement.rssi.toDouble());

    pipeline
      ..name = resolvedName
      ..lastSeen = advertisement.timestamp
      ..rawRssi = advertisement.rssi.toDouble()
      ..smoothedRssi = smoothed
      ..isConnectable = advertisement.isConnectable
      ..serviceUuids = advertisement.serviceUuids
      ..txPower = advertisement.txPower ?? pipeline.txPower
      ..kind = DeviceClassifier.classify(
        name: resolvedName,
        advertisedName: advertisement.name,
        serviceUuids: advertisement.serviceUuids,
        manufacturerData: advertisement.manufacturerData,
      );
    if (pipeline.supportsAlertService == false && !pipeline.alertsChecked) {
      pipeline.supportsAlertService = GattAlertService.advertisesAlertService(advertisement.serviceUuids);
    }

    pipeline.history.add(smoothed);
    if (pipeline.history.length > AppConstants.maxSignalHistory) {
      pipeline.history.removeAt(0);
    }
  }

  void _evictOldest() {
    String? oldestId;
    DateTime? oldestTimestamp;
    for (final MapEntry<String, _DevicePipeline> entry in _pipelines.entries) {
      if (oldestTimestamp == null || entry.value.lastSeen.isBefore(oldestTimestamp)) {
        oldestTimestamp = entry.value.lastSeen;
        oldestId = entry.key;
      }
    }
    if (oldestId != null) _pipelines.remove(oldestId);
  }

  void _emitSnapshot() {
    if (_disposed) return;
    _now = DateTime.now();
    if (!_paused) {
      _pipelines.removeWhere(
        (String _, _DevicePipeline pipeline) =>
            _now.difference(pipeline.lastSeen) > AppConstants.deviceStaleTimeout,
      );
    }

    final PathLossCalculator calculator = _settings.calculator;
    final List<BleDevice> snapshot = <BleDevice>[];
    for (final _DevicePipeline pipeline in _pipelines.values) {
      final double distance = calculator.distanceMeters(pipeline.smoothedRssi);
      snapshot.add(
        BleDevice(
          id: pipeline.id,
          name: pipeline.name,
          rssi: pipeline.rawRssi,
          smoothedRssi: pipeline.smoothedRssi,
          distanceMeters: distance,
          kind: pipeline.kind,
          firstSeen: pipeline.firstSeen,
          lastSeen: pipeline.lastSeen,
          txPower: pipeline.txPower,
          isConnectable: pipeline.isConnectable,
          isMock: pipeline.isMock,
          bearingRadians: pipeline.bearing,
          bearingFromSweep: pipeline.bearingFromSweep,
          signalHistory: List<double>.unmodifiable(pipeline.history),
          supportsAlertService: pipeline.supportsAlertService,
          alertsChecked: pipeline.alertsChecked,
          txPowerUsed: calculator.txPower,
          pathLossExponentUsed: calculator.pathLossExponent,
        ),
      );
    }
    _devices = snapshot;
    notifyListeners();
  }

  void refreshNow() => _emitSnapshot();

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------
  void setKindFilter(DeviceKind? kind) {
    if (_kindFilter == kind) return;
    _kindFilter = kind;
    notifyListeners();
  }

  void clearFilter() => setKindFilter(null);

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void selectDevice(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  void selectDeviceObject(BleDevice? device) => selectDevice(device?.id);

  void markFound(String id) {
    final _DevicePipeline? pipeline = _pipelines[id];
    if (pipeline != null) pipeline.found = true;
  }

  /// Locks the bearing discovered by the 360° sweep onto the radar node.
  void applyBearing(String id, double radians) {
    final _DevicePipeline? pipeline = _pipelines[id];
    if (pipeline == null) return;
    pipeline
      ..bearing = radians
      ..bearingFromSweep = true;
    _emitSnapshot();
  }

  void updateAlertSupport(String id, bool supported) {
    final _DevicePipeline? pipeline = _pipelines[id];
    if (pipeline == null) return;
    pipeline
      ..supportsAlertService = supported
      ..alertsChecked = true;
    _emitSnapshot();
  }

  void _onSettingsChanged() {
    if (_disposed) return;
    if (_settings.mockMode != _activeSourceIsMock && _initialized) {
      unawaited(_restartSource());
    } else {
      _emitSnapshot();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _uiTimer?.cancel();
    _settings.removeListener(_onSettingsChanged);
    unawaited(_realAdSubscription?.cancel() ?? Future<void>.value());
    unawaited(_mockAdSubscription?.cancel() ?? Future<void>.value());
    unawaited(_realAdapterSubscription?.cancel() ?? Future<void>.value());
    unawaited(_mockAdapterSubscription?.cancel() ?? Future<void>.value());
    unawaited(_realErrorSubscription?.cancel() ?? Future<void>.value());
    unawaited(_mockErrorSubscription?.cancel() ?? Future<void>.value());
    unawaited(_repository.dispose());
    super.dispose();
  }
}
