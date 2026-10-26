import 'package:bluetooth_finder_radar/core/constants/app_constants.dart';
import 'package:bluetooth_finder_radar/domain/models/ble_device.dart';
import 'package:bluetooth_finder_radar/domain/models/device_kind.dart';
import 'package:bluetooth_finder_radar/domain/models/distance_unit.dart';
import 'package:bluetooth_finder_radar/domain/models/proximity_zone.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/device_factory.dart';

void main() {
  group('signal quality', () {
    test('signal bars follow the classic thresholds', () {
      expect(device(rssi: -40).signalBars, 4);
      expect(device(rssi: -55).signalBars, 4);
      expect(device(rssi: -56).signalBars, 3);
      expect(device(rssi: -67).signalBars, 3);
      expect(device(rssi: -68).signalBars, 2);
      expect(device(rssi: -78).signalBars, 2);
      expect(device(rssi: -79).signalBars, 1);
      expect(device(rssi: -88).signalBars, 1);
      expect(device(rssi: -89).signalBars, 0);
    });

    test('signal fraction normalises dBm into 0 … 1', () {
      expect(device(rssi: -100).signalFraction, closeTo(0, 1e-9));
      expect(device(rssi: -70).signalFraction, closeTo(0.5, 1e-9));
      expect(device(rssi: -40).signalFraction, 1.0);
      expect(device(rssi: -120).signalFraction, 0.0);
    });

    test('zone is derived from the estimated distance', () {
      expect(device(distanceMeters: 0.4).zone, ProximityZone.hot);
      expect(device(distanceMeters: 2).zone, ProximityZone.warm);
      expect(device(distanceMeters: 6).zone, ProximityZone.moderate);
      expect(device(distanceMeters: 18).zone, ProximityZone.cold);
    });
  });

  group('radar geometry', () {
    test('a device at the centre sits on the inner radius, not at 0', () {
      expect(
        device(distanceMeters: 0).radarRadiusFraction(20),
        AppConstants.radarInnerRadiusFraction,
      );
    });

    test('a device at the range edge sits on the outer ring', () {
      expect(device(distanceMeters: 20).radarRadiusFraction(20), closeTo(1, 1e-9));
      expect(device(distanceMeters: 500).radarRadiusFraction(20), closeTo(1, 1e-9));
    });

    test('fraction grows monotonically with distance', () {
      final double near = device(distanceMeters: 2).radarRadiusFraction(20);
      final double mid = device(distanceMeters: 10).radarRadiusFraction(20);
      final double far = device(distanceMeters: 19).radarRadiusFraction(20);
      expect(near, lessThan(mid));
      expect(mid, lessThan(far));
      expect(near, greaterThan(AppConstants.radarInnerRadiusFraction));
    });

    test('an invalid range falls back to the default 20 m scale', () {
      expect(
        device(distanceMeters: 20).radarRadiusFraction(0),
        closeTo(1, 1e-9),
      );
    });
  });

  group('identity + units', () {
    test('shortId keeps the last 8 hex characters', () {
      expect(device(id: 'AA:BB:CC:DD:EE:01').shortId, 'CCDDEE01');
      expect(device(id: 'mock:airpods-pro-2').shortId, 'PODSPRO2');
      expect(device(id: 'ABCD1234').shortId, 'ABCD1234');
    });

    test('distanceIn converts to feet', () {
      expect(device(distanceMeters: 1).distanceIn(DistanceUnit.feet), closeTo(3.28084, 1e-5));
      expect(device(distanceMeters: 1).distanceIn(DistanceUnit.meters), 1);
    });

    test('hasName detects unnamed beacons', () {
      expect(device(name: '  ').hasName, isFalse);
      expect(device(name: 'Tile Mate').hasName, isTrue);
    });
  });

  group('freshness', () {
    final DateTime now = DateTime.utc(2026, 5, 1, 9);

    test('age and staleness use an 18 s timeout', () {
      expect(device(lastSeen: now).isStale(now), isFalse);
      expect(
        device(lastSeen: now.subtract(const Duration(seconds: 17))).isStale(now),
        isFalse,
      );
      expect(
        device(lastSeen: now.subtract(const Duration(seconds: 19))).isStale(now),
        isTrue,
      );
      expect(AppConstants.deviceStaleTimeout, const Duration(seconds: 18));
    });

    test('historyOr falls back when no history was recorded', () {
      expect(device().historyOr(fallback: <double>[-70]), <double>[-70]);
      expect(
        device(signalHistory: <double>[-60, -61]).historyOr(fallback: <double>[-70]),
        <double>[-60, -61],
      );
    });
  });

  group('copyWith', () {
    test('keeps untouched fields', () {
      final BleDevice original = device(id: 'AA:BB:CC:DD:EE:01', kind: DeviceKind.tracker);
      final BleDevice updated = original.copyWith(rssi: -50, smoothedRssi: -52);
      expect(updated.rssi, -50);
      expect(updated.smoothedRssi, -52);
      expect(updated.id, original.id);
      expect(updated.kind, DeviceKind.tracker);
    });

    test('can clear txPower with an explicit null', () {
      final BleDevice original = device(txPower: -58);
      expect(original.copyWith(txPower: null).txPower, isNull);
      expect(original.copyWith().txPower, -58);
    });
  });

  group('List<BleDevice> helpers', () {
    final List<BleDevice> devices = <BleDevice>[
      device(id: 'A', distanceMeters: 9),
      device(id: 'B', distanceMeters: 1.2),
      device(id: 'C', distanceMeters: 4),
      device(id: 'D', distanceMeters: 1.2, smoothedRssi: -50),
      device(id: 'E', distanceMeters: 1.2, smoothedRssi: -70),
    ];

    test('sortedByDistance is nearest first and breaks ties by signal', () {
      final List<String> ids =
          devices.sortedByDistance().map((BleDevice d) => d.id).toList();
      expect(ids, <String>['D', 'B', 'E', 'C', 'A']);
    });

    test('nearest is the first element of that ordering', () {
      expect(devices.nearest?.id, 'D');
      expect(<BleDevice>[].nearest, isNull);
    });

    test('sortedBySignal is strongest first', () {
      expect(devices.sortedBySignal().first.id, 'D');
    });

    test('maxDistance reports the farthest target', () {
      expect(devices.maxDistance, 9);
      expect(<BleDevice>[].maxDistance, 0);
    });
  });

  group('factory', () {
    test('fromAdvertisement seeds history and distance', () {
      final DateTime stamp = DateTime.utc(2026, 3, 4);
      final BleDevice created = BleDevice.fromAdvertisement(
        id: 'AA:BB',
        name: 'Beacon',
        smoothedRssi: -64,
        distanceMeters: 3.2,
        kind: DeviceKind.unknown,
        timestamp: stamp,
      );
      expect(created.firstSeen, stamp);
      expect(created.lastSeen, stamp);
      expect(created.rssi, -64);
      expect(created.signalHistory, <double>[-64]);
      expect(created.txPowerUsed, AppConstants.defaultTxPower);
      expect(created.pathLossExponentUsed, AppConstants.defaultPathLossExponent);
      expect(created.bearingFromSweep, isFalse);
      expect(created.bearingRadians, inInclusiveRange(0.0, 6.2832));
    });
  });
}
