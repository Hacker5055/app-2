import 'dart:math' as math;

/// One reading captured while the user rotates through the 360° sweep.
class SweepSample {
  const SweepSample({
    required this.headingDegrees,
    required this.rssi,
    required this.timestampMs,
  });

  /// Compass heading of the phone, 0° = north, clockwise.
  final double headingDegrees;

  /// Smoothed RSSI captured at that heading, in dBm.
  final double rssi;

  /// Milliseconds since epoch (used to weight recent samples higher).
  final int timestampMs;

  double get headingRadians => headingDegrees * math.pi / 180.0;
}

/// Result of the direction-finder sweep.
class SweepResult {
  const SweepResult({
    required this.headingDegrees,
    required this.peakHeadingDegrees,
    required this.bestRssi,
    required this.confidence,
    required this.sampleCount,
    required this.coverageDegrees,
    required this.isComplete,
  });

  /// Weighted circular mean — the fused estimate of the strongest direction.
  final double headingDegrees;

  /// Heading of the single strongest raw sample (fast, but noisier).
  final double peakHeadingDegrees;

  /// Strongest RSSI that was recorded during the sweep.
  final double bestRssi;

  /// Resultant vector length, 0 (uniform/no idea) … 1 (very directional).
  final double confidence;

  final int sampleCount;

  /// How much of the circle the user actually covered.
  final double coverageDegrees;

  final bool isComplete;

  double get headingRadians => headingDegrees * math.pi / 180.0;

  /// 8-point compass label of the fused heading.
  String get compassPoint {
    const List<String> points = <String>['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final int index = (((headingDegrees % 360) + 22.5) ~/ 45) % 8;
    return points[index];
  }

  SweepResult copyWith({
    double? headingDegrees,
    double? peakHeadingDegrees,
    double? bestRssi,
    double? confidence,
    int? sampleCount,
    double? coverageDegrees,
    bool? isComplete,
  }) {
    return SweepResult(
      headingDegrees: headingDegrees ?? this.headingDegrees,
      peakHeadingDegrees: peakHeadingDegrees ?? this.peakHeadingDegrees,
      bestRssi: bestRssi ?? this.bestRssi,
      confidence: confidence ?? this.confidence,
      sampleCount: sampleCount ?? this.sampleCount,
      coverageDegrees: coverageDegrees ?? this.coverageDegrees,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

/// Computes the direction of the strongest signal from a sweep.
///
/// The estimator uses a **weighted circular mean** instead of a plain average:
/// RSSI values are mapped to positive weights above the weakest reading, so
/// headings that never produced a signal contribute almost nothing. Because
/// angles live on a circle, the classic arithmetic average would break around
/// 0°/360° — vector summation does not.
class AzimuthEstimator {
  const AzimuthEstimator._();

  static SweepResult? estimate(
    List<SweepSample> samples, {
    double coverageDegrees = 360.0,
    bool isComplete = true,
  }) {
    if (samples.isEmpty) return null;

    double minRssi = samples.first.rssi;
    double maxRssi = samples.first.rssi;
    for (final SweepSample sample in samples) {
      if (!sample.rssi.isFinite) continue;
      minRssi = math.min(minRssi, sample.rssi);
      maxRssi = math.max(maxRssi, sample.rssi);
    }

    final double span = maxRssi - minRssi;
    double sumX = 0;
    double sumY = 0;
    double sumWeight = 0;

    for (final SweepSample sample in samples) {
      if (!sample.rssi.isFinite) continue;
      // Normalised weight in [0.05, 1]. A floor keeps every heading relevant
      // while still letting the strongest lobe dominate.
      final double normalized = span <= 0.01 ? 1.0 : (sample.rssi - minRssi) / span;
      final double weight = 0.05 + 0.95 * normalized * normalized;
      final double radians = sample.headingRadians;
      sumX += weight * math.cos(radians);
      sumY += weight * math.sin(radians);
      sumWeight += weight;
    }

    if (sumWeight <= 0) return null;

    final double meanDegrees = (math.atan2(sumY, sumX) * 180.0 / math.pi + 360.0) % 360.0;
    final double resultant = math.sqrt(sumX * sumX + sumY * sumY) / sumWeight;

    SweepSample strongest = samples.first;
    for (final SweepSample sample in samples) {
      if (sample.rssi > strongest.rssi) strongest = sample;
    }

    return SweepResult(
      headingDegrees: meanDegrees,
      peakHeadingDegrees: strongest.headingDegrees,
      bestRssi: maxRssi,
      confidence: resultant.clamp(0.0, 1.0).toDouble(),
      sampleCount: samples.length,
      coverageDegrees: coverageDegrees,
      isComplete: isComplete,
    );
  }
}
