import '../../core/constants/app_constants.dart';
import '../../domain/models/distance_unit.dart';

/// Small, dependency-free formatting helpers shared by every widget.
class Formatters {
  const Formatters._();

  /// Distance digits adapt to magnitude: 0.84 m, 3.6 m, 14 m, 120 ft.
  static String distanceValue(double meters, DistanceUnit unit) {
    final double value = unit == DistanceUnit.meters ? meters : meters * AppConstants.feetPerMeter;
    if (value < 0.1) return value.toStringAsFixed(2);
    if (value < 1) return value.toStringAsFixed(2);
    if (value < 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(0);
  }

  static String distanceWithUnit(double meters, DistanceUnit unit, {required bool arabic}) =>
      '${distanceValue(meters, unit)} ${unit.symbolFor(arabic)}';

  static String rssi(double value) => '${value.round()}';

  static String rssiWithUnit(double value) => '${value.round()} dBm';

  static String percent(double fraction, {int digits = 0}) =>
      '${(fraction * 100).toStringAsFixed(digits)}%';

  static String oneDecimal(double value) => value.toStringAsFixed(1);

  static String signed(double value, {int digits = 1}) {
    final String text = value.abs().toStringAsFixed(digits);
    return value >= 0 ? '+$text' : '-$text';
  }

  /// 8-point compass abbreviation (N, NE, E, …).
  static String compassPoint(double headingDegrees) {
    const List<String> points = <String>['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final int index = ((headingDegrees % 360 + 22.5) ~/ 45) % 8;
    return points[index];
  }

  static String heading(double degrees) => '${degrees.round() % 360}°';

  /// "now" / "3s ago" / "2m ago".
  static String relativeAge(Duration age, {
    required String now,
    required String Function(int seconds) secondsAgo,
    required String Function(int minutes) minutesAgo,
  }) {
    if (age.inSeconds < 2) return now;
    if (age.inMinutes < 1) return secondsAgo(age.inSeconds);
    return minutesAgo(age.inMinutes);
  }

  static String macLike(String id) {
    final String compact = id.replaceAll(':', '').replaceAll('-', '').toUpperCase();
    if (compact.length != 12) return id.toUpperCase();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < 12; i += 2) {
      if (i > 0) buffer.write(':');
      buffer.write(compact.substring(i, i + 2));
    }
    return buffer.toString();
  }
}
