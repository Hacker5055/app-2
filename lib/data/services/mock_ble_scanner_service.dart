import 'dart:async';
import 'dart:math' as math;

import '../../domain/models/ble_advertisement.dart';
import '../../domain/models/ble_status.dart';
import '../../domain/signal/path_loss_calculator.dart';
import 'ble_scanner_service.dart';

/// A single scripted device used by the mock scanner.
class SimulatedDevice {
  SimulatedDevice({
    required this.id,
    required this.name,
    required this.txPower,
    required this.distance,
    this.connectable = true,
    this.hasAlertService = false,
    this.appleType,
    this.serviceUuids = const <String>[],
    this.visibility = 1.0,
    this.packetSkip = 0,
  });

  final String id;
  final String name;
  final int txPower;
  final double distance;
  final bool connectable;
  final bool hasAlertService;

  /// Apple continuity frame type (0x10 AirPods, 0x12 Find My) when relevant.
  final int? appleType;
  final List<String> serviceUuids;

  /// 1.0 = always visible, 0.0 = never (used to fade devices in/out).
  final double visibility;

  /// Emit only every n-th tick, mimicking slower advertisers.
  final int packetSkip;

}

/// Deterministic BLE simulator for emulators and the in-app demo mode.
///
/// It walks each device's distance with a bounded random walk and converts the
/// distance back into RSSI through the *same* path-loss model used by the real
/// pipeline. That means demo mode exercises the exact smoothing, zoning and
/// Geiger code paths — nothing is faked at the UI layer.
class MockBleScannerService implements BleScannerService {
  MockBleScannerService({math.Random? random, this.tick = const Duration(milliseconds: 350)})
      : _random = random ?? math.Random(42);

  static final List<SimulatedDevice> _script = <SimulatedDevice>[
    SimulatedDevice(
      id: 'mock:airpods-pro-2',
      name: 'AirPods Pro',
      txPower: -58,
      distance: 0.7,
      appleType: 0x10,
      hasAlertService: false,
    ),
    SimulatedDevice(
      id: 'mock:galaxy-watch-6',
      name: 'Galaxy Watch6',
      txPower: -61,
      distance: 2.4,
      serviceUuids: <String>['0000180d-0000-1000-8000-00805f9b34fb'],
    ),
    SimulatedDevice(
      id: 'mock:smarttag-2',
      name: 'Galaxy SmartTag2',
      txPower: -63,
      distance: 4.2,
      hasAlertService: true,
      serviceUuids: <String>['00001802-0000-1000-8000-00805f9b34fb'],
    ),
    SimulatedDevice(
      id: 'mock:airtag',
      name: 'AirTag',
      txPower: -55,
      distance: 8.5,
      connectable: false,
      appleType: 0x12,
    ),
    SimulatedDevice(
      id: 'mock:mi-band-8',
      name: 'Mi Smart Band 8',
      txPower: -60,
      distance: 12.0,
      serviceUuids: <String>['0000180d-0000-1000-8000-00805f9b34fb'],
      visibility: 0.85,
      packetSkip: 1,
    ),
    SimulatedDevice(
      id: 'mock:tile-mate',
      name: 'Tile Mate',
      txPower: -66,
      distance: 16.0,
      hasAlertService: true,
      visibility: 0.7,
      packetSkip: 1,
    ),
    SimulatedDevice(
      id: 'mock:wh-1000xm5',
      name: 'WH-1000XM5',
      txPower: -62,
      distance: 6.0,
      visibility: 0.9,
      packetSkip: 1,
    ),
    SimulatedDevice(
      id: 'mock:beacon-19a4',
      name: '',
      txPower: -70,
      distance: 11.5,
      visibility: 0.6,
      packetSkip: 2,
    ),
  ];

  final math.Random _random;
  final Duration tick;

  final StreamController<BleAdvertisement> _advertisements =
      StreamController<BleAdvertisement>.broadcast();
  final StreamController<BleAdapterStatus> _adapterStatus =
      StreamController<BleAdapterStatus>.broadcast();
  final StreamController<String> _errors = StreamController<String>.broadcast();

  final Map<String, double> _distances = <String, double>{};
  Timer? _timer;
  int _ticks = 0;
  bool _disposed = false;

  @override
  String get name => 'mock';

  @override
  bool get isMock => true;

  @override
  Stream<BleAdvertisement> get advertisements => _advertisements.stream;

  @override
  Stream<BleAdapterStatus> get adapterStatus => _adapterStatus.stream;

  @override
  Stream<String> get errors => _errors.stream;

  @override
  BleAdapterStatus get currentAdapterStatus => BleAdapterStatus.poweredOn;

  @override
  Future<void> start() async {
    if (_disposed) return;
    for (final SimulatedDevice device in _script) {
      _distances.putIfAbsent(device.id, () => device.distance);
    }
    if (!_adapterStatus.isClosed) _adapterStatus.add(BleAdapterStatus.poweredOn);
    _timer?.cancel();
    _timer = Timer.periodic(tick, (Timer _) => _emit());
  }

  void _emit() {
    if (_disposed) return;
    _ticks++;
    final DateTime now = DateTime.now();
    for (final SimulatedDevice device in _script) {
      if (device.packetSkip > 0 && _ticks % (device.packetSkip + 1) != 0) continue;

      final double roll = _random.nextDouble();
      final bool visible = roll < device.visibility;
      if (!visible) continue;

      // Bounded random walk + slow sine "operator movement".
      final double previous = _distances[device.id] ?? device.distance;
      final double walk = (_random.nextDouble() - 0.5) * 0.55;
      final double drift = math.sin(_ticks / 23.0 + device.distance) * 0.08;
      final double next = (previous + walk + drift).clamp(0.35, 24.0).toDouble();
      _distances[device.id] = next;

      final PathLossCalculator calculator = PathLossCalculator(
        txPower: device.txPower.toDouble(),
        pathLossExponent: 2.5,
      );
      final double noise = _gaussian() * 1.8;
      final int rssi = (calculator.rssiAtDistance(next) + noise).round().clamp(-100, -28);

      final List<int> manufacturerData = device.appleType == null
          ? const <int>[0x4D, 0x00]
          : <int>[0x4C, 0x00, device.appleType!, 0x01, 0x00, 0x20];

      if (!_advertisements.isClosed) {
        _advertisements.add(
          BleAdvertisement(
            id: device.id,
            name: device.name,
            rssi: rssi,
            timestamp: now,
            txPower: device.txPower,
            isConnectable: device.connectable,
            isMock: true,
            serviceUuids: device.serviceUuids,
            manufacturerData: manufacturerData,
          ),
        );
      }
    }
  }

  /// Box–Muller transform for realistic Gaussian RSSI noise.
  double _gaussian() {
    final double u1 = math.max(_random.nextDouble(), 1e-9);
    final double u2 = _random.nextDouble();
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _advertisements.close();
    await _adapterStatus.close();
    await _errors.close();
  }
}
