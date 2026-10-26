import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/radar_colors.dart';
import '../../../domain/models/proximity_zone.dart';

/// Small uppercase mono heading with a gradient hairline.
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.label, this.trailing, this.accent = RadarColors.textMuted});

  final String label;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: AppTheme.monoLabel(size: 10.5, color: accent, letterSpacing: 2),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[accent.withValues(alpha: 0.35), accent.withValues(alpha: 0.02)],
              ),
            ),
          ),
        ),
        if (trailing != null) ...<Widget>[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

/// Coloured proximity pill (Immediate / Close / Moderate / Far).
class ZoneChip extends StatelessWidget {
  const ZoneChip({super.key, required this.zone, this.compact = false, this.showRange = true});

  final ProximityZone zone;
  final bool compact;
  final bool showRange;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: zone.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: zone.color.withValues(alpha: 0.45)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: zone.color.withValues(alpha: 0.18), blurRadius: 12),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: compact ? 5 : 6,
            height: compact ? 5 : 6,
            decoration: BoxDecoration(color: zone.color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 5 : 7),
          Text(
            strings.zoneLabel(zone),
            style: TextStyle(
              color: zone.color,
              fontSize: compact ? 10.5 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          if (showRange) ...<Widget>[
            const SizedBox(width: 6),
            Text(
              strings.zoneRange(zone),
              style: AppTheme.monoLabel(size: compact ? 9 : 10, color: zone.color.withValues(alpha: 0.75)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact code badge (EARBUDS / WATCH / TRACKER / BLE).
class CodeBadge extends StatelessWidget {
  const CodeBadge({
    super.key,
    required this.label,
    this.color = RadarColors.textSecondary,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: AppTheme.monoLabel(size: 9, color: color, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

/// Label/value pair used in diagnostic grids.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.color = RadarColors.textPrimary,
    this.icon,
  });

  final String label;
  final String value;
  final String? unit;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 11, color: RadarColors.textMuted),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.monoLabel(size: 9, color: RadarColors.textMuted, letterSpacing: 1.1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.mono.copyWith(fontSize: 15, color: color),
              ),
            ),
            if (unit != null) ...<Widget>[
              const SizedBox(width: 3),
              Text(unit!, style: AppTheme.monoLabel(size: 9.5, color: RadarColors.textMuted)),
            ],
          ],
        ),
      ],
    );
  }
}
