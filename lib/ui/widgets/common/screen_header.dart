import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/radar_colors.dart';
import 'pulse_dot.dart';

/// Kicker + headline + subtitle block used at the top of every tab.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.kicker,
    this.subtitle,
    this.trailing,
    this.accent = RadarColors.cyan,
  });

  final String title;
  final String? kicker;
  final String? subtitle;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (kicker != null) ...<Widget>[
          Row(
            children: <Widget>[
              PulseDot(color: accent, size: 5, haloScale: 2),
              const SizedBox(width: 8),
              Text(
                kicker!.toUpperCase(),
                style: AppTheme.monoLabel(size: 9, color: accent, letterSpacing: 3),
              ),
            ],
          ),
          const SizedBox(height: 9),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.7,
                      color: RadarColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      style: AppTheme.monoLabel(
                        size: 10,
                        color: RadarColors.textMuted,
                        letterSpacing: 0.4,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 10),
              trailing!,
            ],
          ],
        ),
      ],
    );
  }
}
