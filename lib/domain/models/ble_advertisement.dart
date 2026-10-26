import 'package:flutter/foundation.dart';

/// A single BLE advertisement packet, normalised from whichever scanner
/// implementation produced it (real radio or mock generator).
@immutable
class BleAdvertisement {
  const BleAdvertisement({
    required this.id,
    required this.name,
    required this.rssi,
    required this.timestamp,
    this.txPower,
    this.isConnectable = false,
    this.isMock = false,
    this.serviceUuids = const <String>[],
    this.manufacturerData = const <int>[],
  });

  /// Stable device identifier: the MAC address on Android, a platform UUID on
  /// iOS, or a synthetic id such as `mock:airpods` in demo mode.
  final String id;

  /// Advertised local name (may be empty — BLE devices are not obliged to
  /// broadcast one).
  final String name;

  /// Raw RSSI in dBm, typically -30 (touching) … -100 (edge of range).
  final int rssi;

  final DateTime timestamp;

  /// Calibrated transmission power advertised by the device, when available.
  final int? txPower;

  final bool isConnectable;
  final bool isMock;

  /// Advertised service UUIDs, lower-case 16-bit shorthand when possible.
  final List<String> serviceUuids;

  /// Raw manufacturer data — begins with the 16-bit company id (little endian).
  final List<int> manufacturerData;

  BleAdvertisement copyWith({
    String? id,
    String? name,
    int? rssi,
    DateTime? timestamp,
    int? txPower,
    bool? isConnectable,
    bool? isMock,
    List<String>? serviceUuids,
    List<int>? manufacturerData,
  }) {
    return BleAdvertisement(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      timestamp: timestamp ?? this.timestamp,
      txPower: txPower ?? this.txPower,
      isConnectable: isConnectable ?? this.isConnectable,
      isMock: isMock ?? this.isMock,
      serviceUuids: serviceUuids ?? this.serviceUuids,
      manufacturerData: manufacturerData ?? this.manufacturerData,
    );
  }

  @override
  String toString() => 'BleAdvertisement($id, name: "$name", rssi: $rssi dBm)';
}
