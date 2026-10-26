import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/radar_colors.dart';
import '../common/glow_button.dart';
import '../radar/radar_painter.dart';

/// Illustrated empty state with a frozen mini radar.
class ScannerEmptyState extends StatelessWidget {
  const ScannerEmptyState({
    super.key,
    required this.filtered,
    required this.isMockMode,
    required this.onEnableDemo,
    required this.onRefresh,
    required this.onClearFilter,
  });

  final bool filtered;
  final bool isMockMode;
  final VoidCallback onEnableDemo;
  final VoidCallback onRefresh;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        children: <Widget>[
          const SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                ClipOval(
                  child: SizedBox(
                    width: 190,
                    height: 190,
                    child: CustomPaint(
                      painter: RadarGridPainter(
                        ringCount: 3,
                        maxRangeMeters: 15,
                        accent: RadarColors.cyan,
                        showLabels: false,
                        radiusFactor: 0.98,
                      ),
                    ),
                  ),
                ),
                Icon(Icons.bluetooth_searching_rounded, size: 34, color: RadarColors.cyan),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            filtered ? strings.emptyFilterTitle : strings.emptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: RadarColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filtered ? strings.emptyFilterBody : strings.emptyBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.6,
              color: RadarColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          if (filtered)
            GlowButton(
              label: strings.clearFilter,
              icon: Icons.filter_alt_off_rounded,
              onPressed: onClearFilter,
              variant: GlowButtonVariant.secondary,
            )
          else if (!isMockMode)
            GlowButton(
              label: strings.continueDemo,
              icon: Icons.science_rounded,
              onPressed: onEnableDemo,
            ),
          if (!filtered) ...<Widget>[
            const SizedBox(height: 10),
            GlowButton(
              label: strings.refresh,
              icon: Icons.refresh_rounded,
              variant: GlowButtonVariant.ghost,
              onPressed: onRefresh,
            ),
          ],
        ],
      ),
    );
  }
}
