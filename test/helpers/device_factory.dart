import 'package:bluetooth_finder_radar/domain/models/ble_device.dart';
import 'package:bluetooth_finder_radar/domain/models/device_kind.dart';

/// Deterministic [BleDevice] factory so tests do not repeat 18 named args.
BleDevice device({
  String id = 'AA:BB:CC:DD:EE:01',
  String name = 'Test Pods',
  double rssi = -65,
  double? smoothedRssi,
  double? distanceMeters,
  DeviceKind kind = DeviceKind.earbuds,
  DateTime? firstSeen,
  DateTime? lastSeen,
  int? txPower,
  bool isConnectable = true,
  bool isMock = true,
  double bearingRadians = 0,
  bool bearingFromSweep = false,
  List<double> signalHistory = const <double>[],
  bool supportsAlertService = false,
  bool alertsChecked = false,
  double txPowerUsed = -59,
  double pathLossExponentUsed = 2.5,
}) {
  final DateTime stamp = firstSeen ?? DateTime.utc(2026, 1, 1, 12);
  return BleDevice(
    id: id,
    name: name,
    rssi: rssi,
    smoothedRssi: smoothedRssi ?? rssi,
    distanceMeters: distanceMeters ?? 6.2,
    kind: kind,
    firstSeen: stamp,
    lastSeen: lastSeen ?? stamp,
    txPower: txPower,
    isConnectable: isConnectable,
    isMock: isMock,
    bearingRadians: bearingRadians,
    bearingFromSweep: bearingFromSweep,
    signalHistory: signalHistory,
    supportsAlertService: supportsAlertService,
    alertsChecked: alertsChecked,
    txPowerUsed: txPowerUsed,
    pathLossExponentUsed: pathLossExponentUsed,
  );
}
