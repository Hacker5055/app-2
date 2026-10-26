import 'package:bluetooth_finder_radar/core/constants/app_constants.dart';
import 'package:bluetooth_finder_radar/domain/signal/proximity_pulse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Geiger cadence', () {
    test('fastest at the target, slowest at the radar edge', () {
      expect(
        ProximityPulse.intervalForDistance(0).inMilliseconds,
        AppConstants.geigerFastestIntervalMs,
      );
      expect(
        ProximityPulse.intervalForDistance(20).inMilliseconds,
        AppConstants.geigerSlowestIntervalMs,
      );
      expect(
        ProximityPulse.intervalForDistance(500).inMilliseconds,
        AppConstants.geigerSlowestIntervalMs,
      );
    });

    test('never gets faster than the configured floor or slower than the ceiling', () {
      for (final double meters in <double>[0, 0.2, 1, 3, 8, 20, 60]) {
        final int ms = ProximityPulse.intervalForDistance(meters).inMilliseconds;
        expect(ms, greaterThanOrEqualTo(AppConstants.geigerFastestIntervalMs));
        expect(ms, lessThanOrEqualTo(AppConstants.geigerSlowestIntervalMs));
      }
    });

    test('monotonically slows down with distance', () {
      int previous = 0;
      for (final double meters in <double>[0, 0.5, 1, 2, 4, 8, 12, 20]) {
        final int ms = ProximityPulse.intervalForDistance(meters).inMilliseconds;
        expect(ms, greaterThanOrEqualTo(previous));
        previous = ms;
      }
    });

    test('accelerates inside the last metre', () {
      final int atZero = ProximityPulse.intervalForDistance(0).inMilliseconds;
      final int atOne = ProximityPulse.intervalForDistance(1).inMilliseconds;
      final int atTen = ProximityPulse.intervalForDistance(10).inMilliseconds;
      expect(atZero, lessThan(atOne));
      expect(atOne, lessThan(atTen));
    });

    test('distance is treated as an absolute value', () {
      expect(
        ProximityPulse.intervalForDistance(-2),
        ProximityPulse.intervalForDistance(2),
      );
    });

    test('invalid range falls back to the default scale', () {
      expect(
        ProximityPulse.intervalForDistance(0, maxRange: 0),
        ProximityPulse.intervalForDistance(0),
      );
    });
  });

  group('haptics', () {
    test('haptic ticks are slightly slower than audio pings', () {
      final Duration audio = ProximityPulse.intervalForDistance(1);
      final Duration haptic = ProximityPulse.hapticIntervalForDistance(1);
      expect(haptic.inMilliseconds, (audio.inMilliseconds * 1.45).round());
      expect(haptic.inMilliseconds, greaterThan(audio.inMilliseconds));
    });
  });

  group('intensity + volume', () {
    test('intensity is 1 at the target and 0 at the edge', () {
      expect(ProximityPulse.intensityForDistance(0), 1.0);
      expect(ProximityPulse.intensityForDistance(20), 0.0);
      expect(ProximityPulse.intensityForDistance(10), closeTo(0.25, 1e-9));
      expect(ProximityPulse.intensityForDistance(double.nan), 0.0);
    });

    test('volume rises towards the target but stays below 1', () {
      expect(ProximityPulse.volumeForDistance(20), closeTo(0.18, 1e-9));
      expect(ProximityPulse.volumeForDistance(0), closeTo(0.73, 1e-9));
      expect(ProximityPulse.volumeForDistance(0), lessThan(1.0));
    });
  });
}
