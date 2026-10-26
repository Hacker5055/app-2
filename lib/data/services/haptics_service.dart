import 'package:flutter/services.dart';

/// Geiger-counter haptics.
///
/// Android maps `heavyImpact` / `mediumImpact` to different waveform
/// amplitudes, giving a genuinely tactile sense of "getting hotter" when the
/// tick frequency increases.
class HapticsService {
  HapticsService({this.enabled = true});

  bool enabled;

  /// Short tick whose strength follows the proximity intensity (0…1).
  Future<void> tick(double intensity) async {
    if (!enabled) return;
    if (intensity >= 0.75) {
      await HapticFeedback.heavyImpact();
    } else if (intensity >= 0.4) {
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> tap() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }

  Future<void> alert() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// A little celebration pattern: three accelerating impacts.
  Future<void> success() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 110));
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.heavyImpact();
  }
}
