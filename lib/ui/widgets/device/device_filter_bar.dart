import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/radar_colors.dart';
import '../../../domain/models/device_kind.dart';
import 'device_glyph.dart';

/// Horizontally scrollable category chips: All / Earbuds / Watches / Trackers /
/// Unknown, each with a live count.
class DeviceFilterBar extends StatelessWidget {
  const DeviceFilterBar({
    super.key,
    required this.selected,
    required this.counts,
    required this.total,
    required this.onChanged,
  });

  final DeviceKind? selected;
  final Map<DeviceKind, int> counts;
  final int total;
  final ValueChanged<DeviceKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    final List<Widget> chips = <Widget>[
      _FilterChip(
        label: strings.filterAll,
        icon: Icons.radar_rounded,
        count: total,
        active: selected == null,
        color: RadarColors.cyan,
        onTap: () => onChanged(null),
      ),
      _FilterChip(
        label: strings.filterEarbuds,
        icon: iconForKind(DeviceKind.earbuds),
        count: counts[DeviceKind.earbuds] ?? 0,
        active: selected == DeviceKind.earbuds,
        color: RadarColors.cyan,
        onTap: () => onChanged(DeviceKind.earbuds),
      ),
      _FilterChip(
        label: strings.filterWatches,
        icon: iconForKind(DeviceKind.watch),
        count: counts[DeviceKind.watch] ?? 0,
        active: selected == DeviceKind.watch,
        color: RadarColors.purple,
        onTap: () => onChanged(DeviceKind.watch),
      ),
      _FilterChip(
        label: strings.filterTrackers,
        icon: iconForKind(DeviceKind.tracker),
        count: counts[DeviceKind.tracker] ?? 0,
        active: selected == DeviceKind.tracker,
        color: RadarColors.orange,
        onTap: () => onChanged(DeviceKind.tracker),
      ),
      _FilterChip(
        label: strings.filterUnknown,
        icon: iconForKind(DeviceKind.unknown),
        count: counts[DeviceKind.unknown] ?? 0,
        active: selected == DeviceKind.unknown,
        color: RadarColors.textSecondary,
        onTap: () => onChanged(DeviceKind.unknown),
      ),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) => chips[index],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.count,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = active ? color : RadarColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: active
              ? LinearGradient(
                  colors: <Color>[color.withValues(alpha: 0.24), color.withValues(alpha: 0.08)],
                )
              : null,
          color: active ? null : RadarColors.surface.withValues(alpha: 0.7),
          border: Border.all(color: active ? color.withValues(alpha: 0.55) : RadarColors.border),
          boxShadow: active
              ? <BoxShadow>[BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 14)]
              : null,
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 14, color: tint),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? color : RadarColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: tint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
