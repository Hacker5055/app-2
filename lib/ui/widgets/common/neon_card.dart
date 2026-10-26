import 'package:flutter/material.dart';

import '../../../core/theme/radar_colors.dart';

/// Frosted, neon-bordered surface used by every panel in the app.
class NeonCard extends StatelessWidget {
  const NeonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderColor,
    this.glowColor,
    this.radius = 22,
    this.onTap,
    this.gradient,
    this.innerGradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? borderColor;
  final Color? glowColor;
  final double radius;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Gradient? innerGradient;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final Color accent = glowColor ?? RadarColors.cyan;
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: borderColor ?? RadarColors.border),
          boxShadow: glowColor == null
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 28,
                    spreadRadius: -6,
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient ?? RadarColors.cardGradient,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: accent.withValues(alpha: 0.07),
                highlightColor: accent.withValues(alpha: 0.035),
                child: Stack(
                  children: <Widget>[
                    if (innerGradient != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(decoration: BoxDecoration(gradient: innerGradient)),
                        ),
                      ),
                    Padding(padding: padding, child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
