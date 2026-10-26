import 'dart:math' as math;

import '../../core/constants/app_constants.dart';

/// Exponential Moving Average (EMA) for noisy RSSI streams.
///
/// ```text
/// s[0] = x[0]
/// s[i] = α · x[i] + (1 - α) · s[i-1]
/// ```
///
/// With α = 0.35 a single 20 dB spike moves the smoothed value by only 7 dB,
/// which keeps radar nodes from teleporting across the screen while still
/// reacting within a couple of advertising packets.
class ExponentialMovingAverage {
  ExponentialMovingAverage({
    double alpha = AppConstants.defaultEmaAlpha,
    double? initialValue,
  })  : assert(alpha > 0 && alpha <= 1, 'alpha must be in (0, 1]'),
        _alpha = alpha,
        _value = initialValue;

  double _alpha;
  double? _value;
  int _samples = 0;

  double get alpha => _alpha;

  /// Updating alpha keeps the current smoothed value (no visible jump).
  set alpha(double value) {
    if (value <= 0 || value > 1) return;
    _alpha = value;
  }

  bool get isInitialized => _value != null;

  /// Current smoothed value, or `null` before the first sample.
  double? get value => _value;

  int get sampleCount => _samples;

  /// Feeds a raw RSSI sample and returns the new smoothed value.
  ///
  /// Non-finite samples are ignored so a corrupt packet can never poison the
  /// filter.
  double add(double sample) {
    if (!sample.isFinite) return _value ?? sample.clamp(-127.0, -20.0).toDouble();
    _samples++;
    final double? previous = _value;
    if (previous == null) {
      _value = sample;
      return sample;
    }
    final double next = _alpha * sample + (1 - _alpha) * previous;
    _value = next;
    return next;
  }

  /// Convenience wrapper that also enforces the BLE sensitivity range.
  double addRssi(double sample) =>
      add(sample.clamp(-127.0, -20.0).toDouble());

  /// Clears the filter; an optional [seed] immediately re-initialises it.
  void reset({double? seed}) {
    _value = seed;
    _samples = 0;
  }
}

/// Median-of-three pre-filter used only for the compass heading: it removes the
/// occasional magnetometer spike without the lag of a full low-pass filter.
class MedianOfThree {
  final List<double> _window = <double>[];

  double add(double sample) {
    if (!sample.isFinite) {
      return _window.isEmpty ? 0 : _window.last;
    }
    _window.add(sample);
    if (_window.length > 3) _window.removeAt(0);
    final List<double> sorted = List<double>.of(_window)..sort();
    return sorted[sorted.length ~/ 2];
  }

  void reset() => _window.clear();
}

/// Circular median helper kept for angle math (unwraps 359° → 2° correctly).
double circularMedian(List<double> degrees) {
  if (degrees.isEmpty) return 0;
  final List<double> radians = degrees
      .map((double d) => d * math.pi / 180.0)
      .toList(growable: false);
  double x = 0;
  double y = 0;
  for (final double r in radians) {
    x += math.cos(r);
    y += math.sin(r);
  }
  final double mean = math.atan2(y, x) * 180.0 / math.pi;
  return (mean + 360.0) % 360.0;
}
