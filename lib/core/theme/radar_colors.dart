import 'package:flutter/material.dart';

/// The cyber-radar palette.
///
/// Every hue is deliberately saturated against the near-black background so
/// that glowing rings and proximity colours stay legible outdoors.
class RadarColors {
  const RadarColors._();

  // Backgrounds ---------------------------------------------------------------
  static const Color background = Color(0xFF08090E);
  static const Color backgroundDeep = Color(0xFF05060A);
  static const Color surface = Color(0xFF0F121C);
  static const Color surfaceHigh = Color(0xFF141928);
  static const Color surfaceHighest = Color(0xFF1A2133);
  static const Color border = Color(0xFF232B3F);
  static const Color borderBright = Color(0xFF31405E);

  // Typography ---------------------------------------------------------------
  static const Color textPrimary = Color(0xFFEFF4FF);
  static const Color textSecondary = Color(0xFF9AA6C2);
  static const Color textMuted = Color(0xFF5D6884);

  // Neon accents -------------------------------------------------------------
  static const Color cyan = Color(0xFF00E5FF);
  static const Color purple = Color(0xFFB14BFF);
  static const Color orange = Color(0xFFFF8A1F);
  static const Color red = Color(0xFFFF3355);
  static const Color green = Color(0xFF2BFFB0);
  static const Color amber = Color(0xFFFFC857);

  // Radar canvas ------------------------------------------------------------
  static const Color radarGrid = Color(0xFF1A2740);
  static const Color radarGridStrong = Color(0xFF24C8E8);
  static const Color radarCenter = Color(0xFF00E5FF);
  static const Color radarBackground = Color(0xFF070A12);

  // Misc --------------------------------------------------------------------
  static const Color scrim = Color(0xE6080910);

  /// Subtle vertical glow used behind the app bar and the radar viewport.
  static const LinearGradient screenGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0x1A00E5FF), Color(0x0008090E)],
  );

  static const LinearGradient hotGradient = LinearGradient(
    colors: <Color>[Color(0xFFFF3355), Color(0xFFFF8A1F)],
  );

  static const LinearGradient coldGradient = LinearGradient(
    colors: <Color>[Color(0xFF00E5FF), Color(0xFFB14BFF)],
  );

  /// Base gradient of every glass card.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF151B2A), Color(0xFF0B0E17)],
  );

  /// Overlay tint for cards: a barely-there diagonal sheen.
  static const LinearGradient cardSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0x14FFFFFF), Color(0x00FFFFFF)],
  );

  static Color glowOf(Color color, [double alpha = 0.45]) =>
      color.withValues(alpha: alpha);
}
