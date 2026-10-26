import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/stable_angle.dart';
import 'device_kind.dart';
import 'distance_unit.dart';
import 'proximity_zone.dart';

/// Immutable, UI-ready view of a nearby BLE device.
///
/// The controller owns the mutable pipeline state (EMA filter, history) and
/// emits fresh immutable snapshots once per second — widgets never see a
/// half-updated device.
@immutable
class BleDevice {
  const BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.smoothedRssi,
    required this.distanceMeters,
    required this.kind,
    required this.firstSeen,
    required this.lastSeen,
    this.txPower,
    this.isConnectable = false,
    this.isMock = false,
    this.bearingRadians = 0,
    this.bearingFromSweep = false,
    this.signalHistory = const <double>[],
    this.supportsAlertService = false,
    this.alertsChecked = false,
    this.txPowerUsed = AppConstants.defaultTxPower,
    this.pathLossExponentUsed = AppConstants.defaultPathLossExponent,
  });

  final String id;
  final String name;

  /// Last raw RSSI (dBm) straight from the radio.
  final double rssi;

  /// EMA-filtered RSSI used for distance and every visual.
  final double smoothedRssi;

  /// Estimated distance in metres, derived from [smoothedRssi].
  final double distanceMeters;

  final DeviceKind kind;
  final DateTime firstSeen;
  final DateTime lastSeen;

  /// Advertised TxPower reading, if the device broadcasts one.
  final int? txPower;

  final bool isConnectable;
  final bool isMock;

  /// Azimuth used to place the node on the radar (0 = up/north, clockwise).
  final double bearingRadians;

  /// True when the bearing came from a completed 360° sweep (instead of the
  /// deterministic placeholder angle).
  final bool bearingFromSweep;

  /// Smoothed RSSI history, oldest first (max [AppConstants.maxSignalHistory]).
  final List<double> signalHistory;

  /// Whether the GATT Immediate Alert service was detected on the device.
  final bool supportsAlertService;

  /// Whether GATT service discovery has already run for this device.
  final bool alertsChecked;

  /// Model parameters that produced [distanceMeters] — useful in diagnostics.
  final double txPowerUsed;
  final double pathLossExponentUsed;

  ProximityZone get zone => ProximityZone.fromDistance(distanceMeters);

  bool get hasName => name.trim().isNotEmpty;

  double distanceIn(DistanceUnit unit) =>
      unit == DistanceUnit.meters ? distanceMeters : distanceMeters * AppConstants.feetPerMeter;

  /// 0 (outer ring) … 1 (dead centre), with a small inner offset so that a
  /// 0.1 m target is still rendered as a visible dot rather than a pixel.
  double radarRadiusFraction(double maxRangeMeters) {
    final double range = maxRangeMeters <= 0 ? AppConstants.defaultRadarRangeMeters : maxRangeMeters;
    final double normalized = (distanceMeters / range).clamp(0.0, 1.0).toDouble();
    return AppConstants.radarInnerRadiusFraction +
        (1 - AppConstants.radarInnerRadiusFraction) * normalized;
  }

  /// 0 … 1 signal quality for bars and gauges (S9 meter mapping).
  double get signalFraction => ((smoothedRssi + 100.0) / 60.0).clamp(0.0, 1.0).toDouble();

  /// Classic 0 … 4 signal bars.
  int get signalBars {
    if (smoothedRssi >= -55) return 4;
    if (smoothedRssi >= -67) return 3;
    if (smoothedRssi >= -78) return 2;
    if (smoothedRssi >= -88) return 1;
    return 0;
  }

  Duration age(DateTime now) => now.difference(lastSeen);

  bool isStale(DateTime now) => age(now) > AppConstants.deviceStaleTimeout;

  /// Short, human-friendly identifier (last 8 chars of a MAC / UUID).
  String get shortId {
    final String cleaned = id.replaceAll(':', '').replaceAll('-', '');
    if (cleaned.length <= 8) return cleaned.toUpperCase();
    return cleaned.substring(cleaned.length - 8).toUpperCase();
  }

  /// Timestamped sparkline data for the detail screen.
  List<double> historyOr({required List<double> fallback}) =>
      signalHistory.isEmpty ? fallback : signalHistory;

  static const Object _unset = Object();

  BleDevice copyWith({
    String? id,
    String? name,
    double? rssi,
    double? smoothedRssi,
    double? distanceMeters,
    DeviceKind? kind,
    DateTime? firstSeen,
    DateTime? lastSeen,
    Object? txPower = _unset,
    bool? isConnectable,
    bool? isMock,
    double? bearingRadians,
    bool? bearingFromSweep,
    List<double>? signalHistory,
    bool? supportsAlertService,
    bool? alertsChecked,
    double? txPowerUsed,
    double? pathLossExponentUsed,
  }) {
    return BleDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      smoothedRssi: smoothedRssi ?? this.smoothedRssi,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      kind: kind ?? this.kind,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      txPower: identical(txPower, _unset) ? this.txPower : txPower as int?,
      isConnectable: isConnectable ?? this.isConnectable,
      isMock: isMock ?? this.isMock,
      bearingRadians: bearingRadians ?? this.bearingRadians,
      bearingFromSweep: bearingFromSweep ?? this.bearingFromSweep,
      signalHistory: signalHistory ?? this.signalHistory,
      supportsAlertService: supportsAlertService ?? this.supportsAlertService,
      alertsChecked: alertsChecked ?? this.alertsChecked,
      txPowerUsed: txPowerUsed ?? this.txPowerUsed,
      pathLossExponentUsed: pathLossExponentUsed ?? this.pathLossExponentUsed,
    );
  }

  /// Creates the first snapshot of a device from a raw advertisement.
  factory BleDevice.fromAdvertisement({
    required String id,
    required String name,
    required double smoothedRssi,
    required double distanceMeters,
    required DeviceKind kind,
    required DateTime timestamp,
    int? txPower,
    bool isConnectable = false,
    bool isMock = false,
    double? bearingRadians,
    double txPowerUsed = AppConstants.defaultTxPower,
    double pathLossExponentUsed = AppConstants.defaultPathLossExponent,
  }) {
    return BleDevice(
      id: id,
      name: name,
      rssi: smoothedRssi,
      smoothedRssi: smoothedRssi,
      distanceMeters: distanceMeters,
      kind: kind,
      firstSeen: timestamp,
      lastSeen: timestamp,
      txPower: txPower,
      isConnectable: isConnectable,
      isMock: isMock,
      bearingRadians: bearingRadians ?? StableAngle.radiansFromId(id),
      signalHistory: <double>[smoothedRssi],
      txPowerUsed: txPowerUsed,
      pathLossExponentUsed: pathLossExponentUsed,
    );
  }

  @override
  String toString() =>
      'BleDevice($id, ${kind.name}, rssi: ${rssi.toStringAsFixed(1)}, '
      'smoothed: ${smoothedRssi.toStringAsFixed(1)}, d: ${distanceMeters.toStringAsFixed(2)} m)';
}

extension BleDeviceListX on List<BleDevice> {
  /// Nearest first, ties broken by the strongest smoothed signal.
  List<BleDevice> sortedByDistance() {
    final List<BleDevice> copy = List<BleDevice>.of(this);
    copy.sort((BleDevice a, BleDevice b) {
      final int byDistance = a.distanceMeters.compareTo(b.distanceMeters);
      if (byDistance != 0) return byDistance;
      return b.smoothedRssi.compareTo(a.smoothedRssi);
    });
    return copy;
  }

  List<BleDevice> sortedBySignal() {
    final List<BleDevice> copy = List<BleDevice>.of(this);
    copy.sort((BleDevice a, BleDevice b) => b.smoothedRssi.compareTo(a.smoothedRssi));
    return copy;
  }

  BleDevice? get nearest => isEmpty ? null : sortedByDistance().first;

  double get maxDistance =>
      isEmpty ? 0 : fold<double>(0, (double max, BleDevice d) => math.max(max, d.distanceMeters));
}
