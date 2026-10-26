import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../../domain/signal/exponential_moving_average.dart';

/// Thin, defensive wrapper around `flutter_compass`.
///
/// The magnetometer is optional: emulators and some tablets do not have one.
/// [isSupported] lets the sweep assistant fall back to a simulated rotation
/// instead of showing a dead dial.
class CompassService {
  CompassService();

  final MedianOfThree _median = MedianOfThree();
  Stream<double>? _headingStream;
  bool? _supported;

  bool get isSupported {
    if (_supported != null) return _supported!;
    try {
      _supported = FlutterCompass.events != null;
    } on Exception catch (error) {
      debugPrint('Compass unavailable: $error');
      _supported = false;
    }
    return _supported!;
  }

  /// Broadcast stream of smoothed headings in degrees (0 = north, clockwise).
  Stream<double> get headings {
    return _headingStream ??= _buildStream().asBroadcastStream();
  }

  Stream<double> _buildStream() {
    try {
      final Stream<CompassEvent>? events = FlutterCompass.events;
      if (events == null) return const Stream<double>.empty();
      return events
          .handleError((Object error) {
            debugPrint('Compass stream error: $error');
          })
          .map((CompassEvent event) => event.heading)
          .where((double? heading) => heading != null && heading.isFinite)
          .map((double? heading) => _median.add(heading!))
          .where((double heading) => heading.isFinite);
    } on Exception catch (error) {
      debugPrint('Compass stream failed: $error');
      return const Stream<double>.empty();
    }
  }

  void dispose() {
    _median.reset();
    _headingStream = null;
  }
}
