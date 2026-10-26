import 'package:bluetooth_finder_radar/core/utils/formatters.dart';
import 'package:bluetooth_finder_radar/domain/models/distance_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.distanceValue', () {
    test('two decimals below one metre', () {
      expect(Formatters.distanceValue(0.84, DistanceUnit.meters), '0.84');
      expect(Formatters.distanceValue(0.05, DistanceUnit.meters), '0.05');
    });

    test('one decimal below ten metres', () {
      expect(Formatters.distanceValue(3.62, DistanceUnit.meters), '3.6');
      expect(Formatters.distanceValue(9.44, DistanceUnit.meters), '9.4');
    });

    test('whole metres above ten', () {
      expect(Formatters.distanceValue(14.2, DistanceUnit.meters), '14');
      expect(Formatters.distanceValue(120.6, DistanceUnit.meters), '121');
    });

    test('imperial values are converted first', () {
      expect(Formatters.distanceValue(1, DistanceUnit.feet), '3.3');
      expect(Formatters.distanceValue(36.5, DistanceUnit.feet), '120');
    });
  });

  group('Formatters.distanceWithUnit', () {
    test('uses the language-appropriate symbol', () {
      expect(Formatters.distanceWithUnit(2.5, DistanceUnit.meters, arabic: false), '2.5 m');
      expect(Formatters.distanceWithUnit(2.5, DistanceUnit.meters, arabic: true), '2.5 م');
      expect(Formatters.distanceWithUnit(1, DistanceUnit.feet, arabic: true), '3.3 قدم');
    });
  });

  group('signal + numbers', () {
    test('rssi rounds and optionally carries the unit', () {
      expect(Formatters.rssi(-64.4), '-64');
      expect(Formatters.rssi(-64.6), '-65');
      expect(Formatters.rssiWithUnit(-64.6), '-65 dBm');
    });

    test('percent and oneDecimal', () {
      expect(Formatters.percent(0.523), '52%');
      expect(Formatters.percent(0.523, digits: 1), '52.3%');
      expect(Formatters.oneDecimal(2.04), '2.0');
    });

    test('signed always shows the sign', () {
      expect(Formatters.signed(3.14), '+3.1');
      expect(Formatters.signed(-1.26), '-1.3');
      expect(Formatters.signed(0), '+0.0');
    });
  });

  group('headings', () {
    test('compassPoint resolves the 8 directions', () {
      expect(Formatters.compassPoint(0), 'N');
      expect(Formatters.compassPoint(45), 'NE');
      expect(Formatters.compassPoint(90), 'E');
      expect(Formatters.compassPoint(180), 'S');
      expect(Formatters.compassPoint(271), 'W');
      expect(Formatters.compassPoint(359), 'N');
    });

    test('heading wraps and rounds', () {
      expect(Formatters.heading(89.6), '90°');
      expect(Formatters.heading(370), '10°');
      expect(Formatters.heading(-10), '350°');
    });
  });

  group('relativeAge', () {
    String now() => 'now';
    String seconds(int value) => '${value}s ago';
    String minutes(int value) => '${value}m ago';

    test('under two seconds reads as now', () {
      expect(
        Formatters.relativeAge(Duration.zero, now: now(), secondsAgo: seconds, minutesAgo: minutes),
        'now',
      );
    });

    test('seconds then minutes', () {
      expect(
        Formatters.relativeAge(const Duration(seconds: 7), now: now(), secondsAgo: seconds, minutesAgo: minutes),
        '7s ago',
      );
      expect(
        Formatters.relativeAge(const Duration(minutes: 3), now: now(), secondsAgo: seconds, minutesAgo: minutes),
        '3m ago',
      );
    });
  });

  group('macLike', () {
    test('formats 12-digit identifiers', () {
      expect(Formatters.macLike('aabbccddee01'), 'AA:BB:CC:DD:EE:01');
      expect(Formatters.macLike('AA:BB:CC:DD:EE:01'), 'AA:BB:CC:DD:EE:01');
      expect(Formatters.macLike('aabb-ccdd-ee01'), 'AA:BB:CC:DD:EE:01');
    });

    test('leaves non-MAC ids readable', () {
      expect(Formatters.macLike('mock:airpods'), 'MOCK:AIRPODS');
    });
  });

  group('DistanceUnit', () {
    test('exposes metric and imperial symbols', () {
      expect(DistanceUnit.meters.symbolFor(false), 'm');
      expect(DistanceUnit.meters.symbolFor(true), 'م');
      expect(DistanceUnit.feet.symbolFor(false), 'ft');
      expect(DistanceUnit.feet.symbolFor(true), 'قدم');
      expect(DistanceUnit.values.length, 2);
    });
  });
}
