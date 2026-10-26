import 'dart:math' as math;

import '../../core/constants/app_constants.dart';

/// Log-distance path-loss model.
///
/// ```text
/// RSSI(d) = TxPower - 10 · n · log10(d)
/// d       = 10 ^ ((TxPower - RSSI) / (10 · n))
/// ```
///
/// * [txPower] — RSSI measured at exactly one metre (a.k.a. RSSI@1m).
/// * [pathLossExponent] — n; 2.0 free space, 2.5 typical room, 3.0+ obstacles.
class PathLossCalculator {
  const PathLossCalculator({
    this.txPower = AppConstants.defaultTxPower,
    this.pathLossExponent = AppConstants.defaultPathLossExponent,
  })  : assert(pathLossExponent > 0, 'n must be positive'),
        assert(txPower < 0, 'TxPower is a negative dBm value');

  final double txPower;
  final double pathLossExponent;

  /// Converts a (preferably smoothed) RSSI value into metres.
  ///
  /// Extreme readings are clamped: RSSI below -127 dBm is below the BLE
  /// sensitivity floor, and anything above -20 dBm is physically implausible.
  /// The result is always finite and inside `[0.05 m, 200 m]`.
  double distanceMeters(double rssi) {
    if (!rssi.isFinite) return AppConstants.defaultRadarRangeMeters;
    final double safeRssi = rssi.clamp(-127.0, -20.0).toDouble();
    final double exponent = (txPower - safeRssi) / (10.0 * pathLossExponent);
    final double meters = math.pow(10.0, exponent).toDouble();
    return meters.clamp(AppConstants.minDistanceMeters, AppConstants.maxDistanceMeters).toDouble();
  }

  /// Forward model: expected RSSI at [meters].
  double rssiAtDistance(double meters) {
    final double safeMeters = meters.clamp(0.1, 500.0).toDouble();
    final double log10 = math.log(safeMeters) / math.ln10;
    return txPower - 10.0 * pathLossExponent * log10;
  }

  /// Calibration helper: learns TxPower from a live reading taken at 1 m.
  PathLossCalculator calibratedFromOneMeterReading(double rssiAtOneMeter) {
    return PathLossCalculator(
      txPower: rssiAtOneMeter.clamp(AppConstants.minTxPower, AppConstants.maxTxPower).toDouble(),
      pathLossExponent: pathLossExponent,
    );
  }

  PathLossCalculator copyWith({double? txPower, double? pathLossExponent}) {
    return PathLossCalculator(
      txPower: txPower ?? this.txPower,
      pathLossExponent: pathLossExponent ?? this.pathLossExponent,
    );
  }

  static double metersToFeet(double meters) => meters * AppConstants.feetPerMeter;

  static double feetToMeters(double feet) => feet / AppConstants.feetPerMeter;

  @override
  String toString() =>
      'PathLossCalculator(txPower: $txPower dBm, n: $pathLossExponent)';
}
