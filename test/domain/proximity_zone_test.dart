import 'package:bluetooth_finder_radar/core/constants/app_constants.dart';
import 'package:bluetooth_finder_radar/domain/models/proximity_zone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('zone thresholds (spec: 1 m / 3 m / 10 m)', () {
    test('inside one metre is hot', () {
      expect(ProximityZone.fromDistance(0), ProximityZone.hot);
      expect(ProximityZone.fromDistance(0.5), ProximityZone.hot);
      expect(ProximityZone.fromDistance(0.999), ProximityZone.hot);
    });

    test('1 – 3 m is warm', () {
      expect(ProximityZone.fromDistance(1.0), ProximityZone.warm);
      expect(ProximityZone.fromDistance(2.99), ProximityZone.warm);
    });

    test('3 – 10 m is moderate', () {
      expect(ProximityZone.fromDistance(3.0), ProximityZone.moderate);
      expect(ProximityZone.fromDistance(9.99), ProximityZone.moderate);
    });

    test('10 m and beyond is cold', () {
      expect(ProximityZone.fromDistance(10.0), ProximityZone.cold);
      expect(ProximityZone.fromDistance(80), ProximityZone.cold);
    });

    test('invalid distances collapse to hot, never to cold', () {
      expect(ProximityZone.fromDistance(-3), ProximityZone.hot);
      expect(ProximityZone.fromDistance(double.nan), ProximityZone.hot);
      expect(ProximityZone.fromDistance(double.infinity), ProximityZone.hot);
    });

    test('constants match the zone boundaries', () {
      expect(AppConstants.hotZoneMeters, 1.0);
      expect(AppConstants.warmZoneMeters, 3.0);
      expect(AppConstants.moderateZoneMeters, 10.0);
    });
  });

  group('zone palette', () {
    test('hot = neon red, warm = electric orange, moderate = vibrant purple, cold = deep cyan', () {
      expect(ProximityZone.hot.color, const Color(0xFFFF3355));
      expect(ProximityZone.warm.color, const Color(0xFFFF8A1F));
      expect(ProximityZone.moderate.color, const Color(0xFFB14BFF));
      expect(ProximityZone.cold.color, const Color(0xFF00E5FF));
    });

    test('every zone carries a ping cadence and a haptic cadence', () {
      for (final ProximityZone zone in ProximityZone.values) {
        expect(zone.pingInterval.inMilliseconds, greaterThan(0));
        expect(zone.hapticInterval.inMilliseconds, greaterThan(0));
        expect(zone.labelEn, isNotEmpty);
        expect(zone.labelAr, isNotEmpty);
      }
    });

    test('Geiger cadence tightens as the device gets closer', () {
      expect(
        ProximityZone.hot.pingInterval.inMilliseconds,
        lessThan(ProximityZone.warm.pingInterval.inMilliseconds),
      );
      expect(
        ProximityZone.warm.pingInterval.inMilliseconds,
        lessThan(ProximityZone.moderate.pingInterval.inMilliseconds),
      );
      expect(
        ProximityZone.moderate.pingInterval.inMilliseconds,
        lessThan(ProximityZone.cold.pingInterval.inMilliseconds),
      );
      expect(ProximityZone.hot.pingInterval.inMilliseconds,
          AppConstants.geigerFastestIntervalMs);
      expect(ProximityZone.cold.pingInterval.inMilliseconds,
          AppConstants.geigerSlowestIntervalMs);
    });

    test('glow strength decreases with distance', () {
      expect(ProximityZone.hot.glowStrength, greaterThan(ProximityZone.warm.glowStrength));
      expect(ProximityZone.warm.glowStrength, greaterThan(ProximityZone.moderate.glowStrength));
      expect(ProximityZone.moderate.glowStrength, greaterThan(ProximityZone.cold.glowStrength));
    });
  });
}
