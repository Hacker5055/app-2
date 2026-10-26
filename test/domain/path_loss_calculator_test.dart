import 'package:bluetooth_finder_radar/core/constants/app_constants.dart';
import 'package:bluetooth_finder_radar/domain/signal/path_loss_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const PathLossCalculator calculator = PathLossCalculator();

  group('defaults', () {
    test('uses TxPower = -59 dBm and n = 2.5', () {
      expect(calculator.txPower, -59.0);
      expect(calculator.pathLossExponent, 2.5);
      expect(calculator.txPower, AppConstants.defaultTxPower);
      expect(calculator.pathLossExponent, AppConstants.defaultPathLossExponent);
    });

    test('one metre maps back to the configured TxPower', () {
      // d = 10^((TxPower - RSSI) / (10n)); RSSI == TxPower at exactly 1 m.
      expect(calculator.distanceMeters(-59), closeTo(1.0, 1e-9));
      expect(calculator.rssiAtDistance(1), closeTo(-59.0, 1e-9));
    });
  });

  group('inverse model — distance = 10 ^ ((TxPower - RSSI) / (10n))', () {
    test('10 dB below TxPower is 2.51 m indoors (n = 2.5)', () {
      expect(calculator.distanceMeters(-69), closeTo(2.511886, 1e-6));
    });

    test('known dBm values match the spec formula', () {
      final double expected = 10.0 * 10.0; // 10^((−59 − −109)/25) = 10^2
      expect(calculator.distanceMeters(-109), closeTo(expected, 1e-6));
      expect(calculator.distanceMeters(-84), closeTo(10.0, 1e-6));
      expect(calculator.distanceMeters(-34), closeTo(0.1, 0.005));
    });

    test('strong readings are clamped to the 5 cm floor', () {
      // −20 dBm is physically implausible (RFID-tag-at-the-antenna close).
      expect(calculator.distanceMeters(-25), AppConstants.minDistanceMeters);
      expect(calculator.distanceMeters(-20), AppConstants.minDistanceMeters);
    });

    test('weak readings are clamped to 200 m', () {
      expect(calculator.distanceMeters(-127), AppConstants.maxDistanceMeters);
      expect(calculator.distanceMeters(-200), AppConstants.maxDistanceMeters);
    });

    test('non-finite readings fall back to the radar range, never NaN', () {
      expect(calculator.distanceMeters(double.nan), AppConstants.defaultRadarRangeMeters);
      expect(calculator.distanceMeters(double.infinity), AppConstants.defaultRadarRangeMeters);
      expect(calculator.distanceMeters(double.negativeInfinity), isNot(isNaN));
    });
  });

  group('forward model', () {
    test('RSSI at 10 m with n = 2.5 is -84 dBm', () {
      expect(calculator.rssiAtDistance(10), closeTo(-84.0, 1e-9));
      expect(calculator.rssiAtDistance(2), closeTo(-66.5258, 1e-3));
    });

    test('rssiAtDistance clamps near-zero distances', () {
      // 0 m would be log10(0) = -∞; clamped to 0.1 m.
      expect(calculator.rssiAtDistance(0), closeTo(-59.0 + 25.0, 1e-9));
    });
  });

  group('calibration + copies', () {
    test('calibratedFromOneMeterReading replaces TxPower only', () {
      final PathLossCalculator calibrated = calculator.calibratedFromOneMeterReading(-72);
      expect(calibrated.txPower, -72.0);
      expect(calibrated.pathLossExponent, 2.5);
      expect(calibrated.distanceMeters(-72), closeTo(1.0, 1e-9));
    });

    test('calibration values outside -90…-35 dBm are clamped', () {
      expect(calculator.calibratedFromOneMeterReading(-120).txPower, -90.0);
      expect(calculator.calibratedFromOneMeterReading(-10).txPower, -35.0);
    });

    test('copyWith keeps untouched fields', () {
      final PathLossCalculator custom = calculator.copyWith(pathLossExponent: 3.0);
      expect(custom.txPower, -59.0);
      expect(custom.pathLossExponent, 3.0);
    });
  });

  group('unit conversion', () {
    test('metersToFeet and feetToMeters round-trip', () {
      expect(PathLossCalculator.metersToFeet(1), closeTo(3.28084, 1e-5));
      expect(PathLossCalculator.feetToMeters(3.28084), closeTo(1.0, 1e-5));
    });
  });

  test('custom exponents move the estimate', () {
    // Free space (n = 2) reports a farther distance for the same RSSI than a
    // cluttered room (n = 3.5).
    final PathLossCalculator open = calculator.copyWith(pathLossExponent: 2.0);
    final PathLossCalculator cluttered = calculator.copyWith(pathLossExponent: 3.5);
    expect(open.distanceMeters(-79), greaterThan(cluttered.distanceMeters(-79)));
  });
}
