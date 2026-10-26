import 'dart:math' as math;

/// Deterministic pseudo-azimuth for devices that have not been through the
/// 360° sweep yet.
///
/// BLE advertisements carry RSSI only — they do **not** carry an angle unless
/// the phone has an antenna array (AoA/AoD). Real direction finding therefore
/// requires the user to rotate, which is exactly what the sweep assistant does.
/// Until then each device is parked on a stable, hash-derived spoke so that its
/// radar node stays in the same place instead of teleporting every second.
class StableAngle {
  const StableAngle._();

  static double radiansFromId(String id) {
    if (id.isEmpty) return 0;
    int hash = 0x811C9DC5; // FNV-1a 32 bit offset basis.
    for (final int codeUnit in id.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    // Golden-angle stride spreads neighbouring ids far apart on the circle.
    final int slot = hash % 3600;
    return slot / 3600.0 * 2 * math.pi;
  }

  static double degreesFromId(String id) => radiansFromId(id) * 180.0 / math.pi;
}
