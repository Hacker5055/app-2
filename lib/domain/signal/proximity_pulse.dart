import 'dart:math' as math;

import '../../core/constants/app_constants.dart';

/// Translates a distance into the cadence of the Geiger-counter feedback.
///
/// Rather than using four discrete intervals, the cadence is continuous:
/// at 0 m the ping fires every ~130 ms, at the radar edge every ~1600 ms,
/// with a `t^0.65` curve so it accelerates noticeably in the last metre.
class ProximityPulse {
  const ProximityPulse._();

  static Duration intervalForDistance(
    double meters, {
    double maxRange = AppConstants.defaultRadarRangeMeters,
    int fastestMs = AppConstants.geigerFastestIntervalMs,
    int slowestMs = AppConstants.geigerSlowestIntervalMs,
  }) {
    final double safeRange = maxRange <= 0 ? AppConstants.defaultRadarRangeMeters : maxRange;
    final double normalized = (meters.abs() / safeRange).clamp(0.0, 1.0).toDouble();
    final double eased = math.pow(normalized, 0.65).toDouble();
    final double ms = fastestMs + (slowestMs - fastestMs) * eased;
    return Duration(milliseconds: ms.round());
  }

  /// Slightly slower than the audio ping so haptics never feel like a buzz saw.
  static Duration hapticIntervalForDistance(double meters, {double maxRange = AppConstants.defaultRadarRangeMeters}) {
    final Duration audio = intervalForDistance(meters, maxRange: maxRange);
    return Duration(milliseconds: (audio.inMilliseconds * 1.45).round());
  }

  /// 0 (far) … 1 (immediate), used for glow strength and pulse rings.
  static double intensityForDistance(
    double meters, {
    double maxRange = AppConstants.defaultRadarRangeMeters,
  }) {
    if (!meters.isFinite) return 0;
    final double safeRange = maxRange <= 0 ? AppConstants.defaultRadarRangeMeters : maxRange;
    final double normalized = (meters.abs() / safeRange).clamp(0.0, 1.0).toDouble();
    return (1.0 - normalized) * (1.0 - normalized);
  }

  /// Ping volume rises as the operator closes in, but never reaches 1.0.
  static double volumeForDistance(double meters, {double maxRange = AppConstants.defaultRadarRangeMeters}) {
    return (0.18 + 0.55 * intensityForDistance(meters, maxRange: maxRange)).clamp(0.0, 1.0).toDouble();
  }
}
