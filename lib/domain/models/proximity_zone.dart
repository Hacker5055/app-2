import 'dart:ui' show Color;

/// The four proximity buckets required by the product spec.
///
/// Boundaries (inclusive-lower / exclusive-upper):
///   hot      : 0 m  – 1 m   → neon red    + haptics
///   warm     : 1 m  – 3 m   → electric orange
///   moderate : 3 m  – 10 m  → vibrant purple
///   cold     : 10 m and up  → deep cyan
enum ProximityZone {
  hot(
    labelEn: 'Immediate',
    labelAr: 'قريب جدًا',
    rangeEn: '< 1 m',
    rangeAr: 'أقل من 1 م',
    color: Color(0xFFFF3355),
    pingInterval: Duration(milliseconds: 130),
    hapticInterval: Duration(milliseconds: 320),
    glowStrength: 1.0,
  ),
  warm(
    labelEn: 'Close',
    labelAr: 'قريب',
    rangeEn: '1 – 3 m',
    rangeAr: '1 – 3 م',
    color: Color(0xFFFF8A1F),
    pingInterval: Duration(milliseconds: 380),
    hapticInterval: Duration(milliseconds: 620),
    glowStrength: 0.82,
  ),
  moderate(
    labelEn: 'Moderate',
    labelAr: 'متوسط',
    rangeEn: '3 – 10 m',
    rangeAr: '3 – 10 م',
    color: Color(0xFFB14BFF),
    pingInterval: Duration(milliseconds: 800),
    hapticInterval: Duration(milliseconds: 1100),
    glowStrength: 0.6,
  ),
  cold(
    labelEn: 'Far',
    labelAr: 'بعيد',
    rangeEn: '> 10 m',
    rangeAr: 'أكثر من 10 م',
    color: Color(0xFF00E5FF),
    pingInterval: Duration(milliseconds: 1600),
    hapticInterval: Duration(milliseconds: 1600),
    glowStrength: 0.42,
  );

  const ProximityZone({
    required this.labelEn,
    required this.labelAr,
    required this.rangeEn,
    required this.rangeAr,
    required this.color,
    required this.pingInterval,
    required this.hapticInterval,
    required this.glowStrength,
  });

  final String labelEn;
  final String labelAr;
  final String rangeEn;
  final String rangeAr;
  final Color color;
  final Duration pingInterval;
  final Duration hapticInterval;
  final double glowStrength;

  /// Maps a smoothed distance (metres) onto a zone.
  ///
  /// Negative or non-finite inputs collapse to [hot] — a broken reading should
  /// never look like a far-away device.
  static ProximityZone fromDistance(double meters) {
    if (!meters.isFinite || meters < 0) return ProximityZone.hot;
    if (meters < 1.0) return ProximityZone.hot;
    if (meters < 3.0) return ProximityZone.warm;
    if (meters < 10.0) return ProximityZone.moderate;
    return ProximityZone.cold;
  }

  bool get isHot => this == ProximityZone.hot;

  /// 0 (far) … 1 (hot). Handy for gauges and glow intensity.
  double get intensity => switch (this) {
        ProximityZone.hot => 1.0,
        ProximityZone.warm => 0.75,
        ProximityZone.moderate => 0.5,
        ProximityZone.cold => 0.25,
      };

  /// Ordering helper for sorting / highlighting the nearest zone.
  int get rank => switch (this) {
        ProximityZone.cold => 0,
        ProximityZone.moderate => 1,
        ProximityZone.warm => 2,
        ProximityZone.hot => 3,
      };
}
