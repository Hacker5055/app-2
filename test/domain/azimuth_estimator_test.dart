import 'dart:math' as math;

import 'package:bluetooth_finder_radar/domain/signal/azimuth_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

SweepSample sample(double heading, double rssi) =>
    SweepSample(headingDegrees: heading, rssi: rssi, timestampMs: 0);

void main() {
  group('SweepSample', () {
    test('converts heading to radians', () {
      expect(sample(180, -60).headingRadians, closeTo(math.pi, 1e-9));
      expect(sample(90, -60).headingRadians, closeTo(math.pi / 2, 1e-9));
    });
  });

  group('AzimuthEstimator.estimate', () {
    test('returns null for an empty sweep', () {
      expect(AzimuthEstimator.estimate(<SweepSample>[]), isNull);
    });

    test('points at the strongest lobe', () {
      final SweepResult? result = AzimuthEstimator.estimate(<SweepSample>[
        sample(0, -85),
        sample(45, -80),
        sample(90, -45),
        sample(135, -78),
        sample(180, -88),
        sample(225, -90),
        sample(270, -86),
        sample(315, -84),
      ]);
      expect(result, isNotNull);
      expect(result!.headingDegrees, closeTo(90, 12));
      expect(result.peakHeadingDegrees, 90);
      expect(result.bestRssi, -45);
      expect(result.compassPoint, 'E');
      expect(result.sampleCount, 8);
      expect(result.confidence, inInclusiveRange(0.0, 1.0));
      expect(result.isComplete, isTrue);
      expect(result.coverageDegrees, 360);
    });

    test('handles the 0° / 360° seam without flipping to the opposite side', () {
      final SweepResult? result = AzimuthEstimator.estimate(<SweepSample>[
        sample(350, -50),
        sample(355, -48),
        sample(0, -47),
        sample(5, -49),
        sample(10, -52),
        sample(180, -90),
        sample(90, -95),
        sample(270, -92),
      ]);
      expect(result, isNotNull);
      // 357° should resolve to ~357°, not ~177°.
      expect(result!.headingDegrees, anyOf(lessThan(15), greaterThan(345)));
      expect(result.compassPoint, 'N');
    });

    test('a uniform ring of equal readings has low confidence', () {
      final SweepResult? result = AzimuthEstimator.estimate(<SweepSample>[
        sample(0, -70),
        sample(90, -70),
        sample(180, -70),
        sample(270, -70),
      ]);
      expect(result, isNotNull);
      expect(result!.confidence, lessThan(0.2));
    });

    test('ignores non-finite readings', () {
      final SweepResult? result = AzimuthEstimator.estimate(<SweepSample>[
        sample(0, -80),
        sample(45, double.nan),
        sample(90, -40),
      ]);
      expect(result, isNotNull);
      expect(result!.sampleCount, 3);
      expect(result.bestRssi, -40);
    });

    test('carries coverage + completion flags from the caller', () {
      final SweepResult? result = AzimuthEstimator.estimate(
        <SweepSample>[sample(120, -60)],
        coverageDegrees: 90,
        isComplete: false,
      );
      expect(result!.coverageDegrees, 90);
      expect(result.isComplete, isFalse);
    });

    test('copyWith keeps the untouched fields', () {
      final SweepResult? base = AzimuthEstimator.estimate(<SweepSample>[sample(10, -60)]);
      final SweepResult locked = base!.copyWith(confidence: 0.9);
      expect(locked.confidence, 0.9);
      expect(locked.headingDegrees, base.headingDegrees);
      expect(locked.sampleCount, base.sampleCount);
    });
  });

  group('SweepResult.compassPoint', () {
    SweepResult at(double heading) => SweepResult(
          headingDegrees: heading,
          peakHeadingDegrees: heading,
          bestRssi: -50,
          confidence: 1,
          sampleCount: 1,
          coverageDegrees: 360,
          isComplete: true,
        );

    test('maps the 8 principal directions', () {
      expect(at(0).compassPoint, 'N');
      expect(at(44).compassPoint, 'NE');
      expect(at(90).compassPoint, 'E');
      expect(at(135).compassPoint, 'SE');
      expect(at(180).compassPoint, 'S');
      expect(at(225).compassPoint, 'SW');
      expect(at(270).compassPoint, 'W');
      expect(at(315).compassPoint, 'NW');
      expect(at(359).compassPoint, 'N');
      expect(at(720).compassPoint, 'N');
    });
  });
}
