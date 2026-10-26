import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/radar_colors.dart';

enum GlowButtonVariant { primary, secondary, success, danger, ghost }

/// The app's signature button: gradient fill, neon halo, pulse-friendly.
class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = GlowButtonVariant.primary,
    this.expand = true,
    this.height = 52,
    this.busy = false,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final GlowButtonVariant variant;
  final bool expand;
  final double height;
  final bool busy;
  final bool compact;

  Color get _accent => switch (variant) {
        GlowButtonVariant.primary => RadarColors.cyan,
        GlowButtonVariant.secondary => RadarColors.purple,
        GlowButtonVariant.success => RadarColors.green,
        GlowButtonVariant.danger => RadarColors.red,
        GlowButtonVariant.ghost => RadarColors.borderBright,
      };

  Gradient? get _fill => switch (variant) {
        GlowButtonVariant.primary =>
          const LinearGradient(colors: <Color>[Color(0xFF5CF6FF), Color(0xFF00B8D4)]),
        GlowButtonVariant.secondary =>
          const LinearGradient(colors: <Color>[Color(0xFFB14BFF), Color(0xFF6E2BD9)]),
        GlowButtonVariant.success =>
          const LinearGradient(colors: <Color>[Color(0xFF66FFC9), Color(0xFF00C98A)]),
        GlowButtonVariant.danger =>
          const LinearGradient(colors: <Color>[Color(0xFFFF4D6D), Color(0xFFC1123B)]),
        GlowButtonVariant.ghost => null,
      };

  Color get _labelColor => switch (variant) {
        GlowButtonVariant.primary => const Color(0xFF02181D),
        GlowButtonVariant.secondary => Colors.white,
        GlowButtonVariant.success => const Color(0xFF00231A),
        GlowButtonVariant.danger => Colors.white,
        GlowButtonVariant.ghost => RadarColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !busy;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: SizedBox(
        height: height,
        width: expand ? double.infinity : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _fill,
            color: _fill == null ? RadarColors.surfaceHigh.withValues(alpha: 0.85) : null,
            border: Border.all(
              color: variant == GlowButtonVariant.ghost
                  ? RadarColors.border
                  : _accent.withValues(alpha: 0.55),
            ),
            boxShadow: variant == GlowButtonVariant.ghost
                ? null
                : AppTheme.neon(_accent, blur: 18, alpha: 0.24),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.white.withValues(alpha: 0.12),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (busy)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_labelColor),
                          ),
                        )
                      else if (icon != null)
                        Icon(icon, size: compact ? 16 : 19, color: _labelColor),
                      if (busy || icon != null) const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _labelColor,
                            fontSize: compact ? 12.5 : 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round, glowing icon button used in app bars and control strips.
class NeonIconButton extends StatelessWidget {
  const NeonIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color = RadarColors.cyan,
    this.size = 42,
    this.iconSize = 20,
    this.filled = false,
    this.tooltip,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double size;
  final double iconSize;
  final bool filled;
  final String? tooltip;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final Widget button = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color.withValues(alpha: 0.16) : RadarColors.surfaceHigh.withValues(alpha: 0.7),
          border: Border.all(color: color.withValues(alpha: filled ? 0.5 : 0.22)),
          boxShadow: filled ? AppTheme.neon(color, blur: 14, alpha: 0.2) : null,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: iconSize,
                  color: onPressed == null ? RadarColors.textMuted : color,
                ),
                if (badge != null) PositionedDirectional(top: 6, end: 6, child: badge!),
              ],
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
