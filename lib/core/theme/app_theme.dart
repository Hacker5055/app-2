import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../domain/models/proximity_zone.dart';
import 'radar_colors.dart';

/// Global dark "cyber radar" theme.
class AppTheme {
  const AppTheme._();

  static const String _displayFont = 'Roboto';
  static const String monoFont = 'monospace';

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: RadarColors.cyan,
      brightness: Brightness.dark,
    ).copyWith(
      primary: RadarColors.cyan,
      onPrimary: const Color(0xFF031014),
      secondary: RadarColors.purple,
      onSecondary: const Color(0xFF12031C),
      tertiary: RadarColors.orange,
      onTertiary: const Color(0xFF1A0D00),
      error: RadarColors.red,
      onError: const Color(0xFF1C0207),
      surface: RadarColors.background,
      onSurface: RadarColors.textPrimary,
      outline: RadarColors.border,
      outlineVariant: RadarColors.borderBright,
      scrim: RadarColors.scrim,
    );

    final TextTheme textTheme = const TextTheme(
      displayLarge: TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        height: 1.05,
        color: RadarColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        height: 1.1,
        color: RadarColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: RadarColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: RadarColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: RadarColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: RadarColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: RadarColors.textSecondary,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        height: 1.5,
        color: RadarColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        height: 1.45,
        color: RadarColors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        color: RadarColors.textMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
      labelMedium: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: RadarColors.textMuted,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
        color: RadarColors.textMuted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: RadarColors.background,
      canvasColor: RadarColors.background,
      fontFamily: _displayFont,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: RadarColors.textPrimary, size: 22),
        titleTextStyle: TextStyle(
          fontFamily: _displayFont,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: RadarColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: RadarColors.border,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return RadarColors.cyan;
          }
          return RadarColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return RadarColors.cyan.withValues(alpha: 0.28);
          }
          return RadarColors.surfaceHigh;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? RadarColors.cyan.withValues(alpha: 0.6)
              : RadarColors.border,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: RadarColors.cyan,
        inactiveTrackColor: RadarColors.surfaceHighest,
        thumbColor: RadarColors.cyan,
        overlayColor: RadarColors.cyan.withValues(alpha: 0.15),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: RadarColors.surfaceHigh,
        contentTextStyle: const TextStyle(color: RadarColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: RadarColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: RadarColors.textSecondary,
        textColor: RadarColors.textPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: RadarColors.cyan,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: RadarColors.surfaceHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(color: RadarColors.textPrimary, fontSize: 12),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable text styles
  // ---------------------------------------------------------------------------
  static const TextStyle mono = TextStyle(
    fontFamily: monoFont,
    fontWeight: FontWeight.w700,
    fontFeatures: <FontFeature>[FontFeature('tnum')],
    color: RadarColors.textPrimary,
  );

  static TextStyle monoLabel({
    double size = 11,
    Color color = RadarColors.textMuted,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 1.2,
  }) =>
      TextStyle(
        fontFamily: monoFont,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle zone(ProximityZone zone) => TextStyle(
        color: zone.color,
        fontFamily: monoFont,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      );

  static List<BoxShadow> neon(Color color, {double blur = 24, double alpha = 0.4}) =>
      <BoxShadow>[
        BoxShadow(color: color.withValues(alpha: alpha), blurRadius: blur),
        BoxShadow(
          color: color.withValues(alpha: alpha * 0.35),
          blurRadius: blur * 2.2,
          spreadRadius: 1,
        ),
      ];
}

extension ZoneColorX on ProximityZone {
  Color get glow => color.withValues(alpha: 0.45);
}
