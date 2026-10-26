import 'package:bluetooth_finder_radar/core/constants/app_constants.dart';
import 'package:bluetooth_finder_radar/domain/signal/exponential_moving_average.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExponentialMovingAverage', () {
    test('defaults to alpha 0.35', () {
      expect(ExponentialMovingAverage().alpha, AppConstants.defaultEmaAlpha);
      expect(AppConstants.defaultEmaAlpha, 0.35);
    });

    test('first sample seeds the filter verbatim', () {
      final ExponentialMovingAverage ema = ExponentialMovingAverage();
      expect(ema.isInitialized, isFalse);
      expect(ema.add(-60), -60);
      expect(ema.isInitialized, isTrue);
      expect(ema.value, -60);
      expect(ema.sampleCount, 1);
    });

    test('subsequent samples follow s = a·x + (1 - a)·s', () {
      final ExponentialMovingAverage ema = ExponentialMovingAverage();
      ema.add(-80);
      final double step = ema.add(-40);
      // 0.35 * -40 + 0.65 * -80 = -14 - 52 = -66
      expect(step, closeTo(-66.0, 1e-9));
      expect(ema.value, closeTo(-66.0, 1e-9));
    });

    test('a single 20 dB spike moves the output by only 7 dB', () {
      final ExponentialMovingAverage ema = ExponentialMovingAverage();
      ema.add(-70);
      final double afterSpike = ema.add(-50);
      expect(afterSpike - (-70), closeTo(7.0, 1e-9));
      expect(afterSpike, closeTo(-63.0, 1e-9));
    });

    test('noise converges towards the mean instead of following it', () {
      final ExponentialMovingAverage ema = ExponentialMovingAverage();
      for (int i = 0; i < 200; i++) {
        ema.add(i.isEven ? -70.0 : -60.0);
      }
      expect(ema.value, closeTo(-65.0, 1.5));
    });

    test('higher alpha reacts faster', () {
      final ExponentialMovingAverage slow = ExponentialMovingAverage(alpha: 0.1);
      final ExponentialMovingAverage fast = ExponentialMovingAverage(alpha: 0.9);
      for (final ExponentialMovingAverage ema in <ExponentialMovingAverage>[slow, fast]) {
        ema.add(-90);
        ema.add(-50);
      }
      expect(fast.value!, greaterThan(slow.value!));
    });

    test('non-finite samples are ignored', () {
      final ExponentialMovingAverage ema = ExponentialMovingAverage();
      ema.add(-70);
      expect(ema.add(double.nan), -70);
      expect(ema.add(double.infinity), -70);
      expect(ema.sampleCount, 1);
    });

    test('initialValue pre-seeds without consuming a sample', () {
      final ExponentialMovingAverage ema =
          ExponentialMovingAverage(initialValue: -42, alpha: 0.5);
      expect(ema.isInitialized, isTrue);
      expect(ema.value, -42);
      expect(ema.add(-40), closeTo(-41.0, 1e-9));
      expect(ema.sampleCount, 1);
    });

    test('addRssi clamps to the BLE sensitivity window', () {
      final ExponentialMovingAverage ema = ExponentialMovingAverage();
      expect(ema.addRssi(-200), -127.0);
      ema.reset();
      expect(ema.addRssi(10), -20.0);
    });

    test('alpha setter ignores out-of-range values', () {
      final ExponentialMovingAverage ema = ExponentialMovingAverage();
      ema.alpha = 0.5;
      expect(ema.alpha, 0.5);
      ema.alpha = 0;
      expect(ema.alpha, 0.5);
      ema.alpha = 2;
      expect(ema.alpha, 0.5);
    });

    test('reset clears the state and can re-seed', () {
      final ExponentialMovingAverage ema = ExponentialMovingAverage();
      ema.add(-70);
      ema.reset();
      expect(ema.value, isNull);
      expect(ema.sampleCount, 0);
      ema.reset(seed: -55);
      expect(ema.value, -55);
    });
  });

  group('MedianOfThree', () {
    test('suppresses a single magnetometer spike', () {
      final MedianOfThree filter = MedianOfThree();
      filter.add(90);
      filter.add(91);
      filter.add(400);
      expect(filter.add(92), 92);
    });

    test('needs three samples before it can reject outliers', () {
      final MedianOfThree filter = MedianOfThree();
      expect(filter.add(10), 10);
      expect(filter.add(20), 20);
    });
  });

  group('circularMedian', () {
    test('unwraps the 359° → 0° seam', () {
      expect(circularMedian(<double>[359, 1]), anyOf(closeTo(0, 1e-6), closeTo(360, 1e-6)));
    });

    test('plain average for samples inside one quadrant', () {
      expect(circularMedian(<double>[80, 90, 100]), closeTo(90.0, 1e-6));
    });

    test('empty input returns 0', () {
      expect(circularMedian(<double>[]), 0);
    });
  });
}
