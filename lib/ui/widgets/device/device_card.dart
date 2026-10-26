import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/settings_controller.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/radar_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/ble_device.dart';
import '../common/labels.dart';
import '../common/neon_card.dart';
import '../common/signal_bars.dart';
import 'device_glyph.dart';

/// One row in the scanner list.
class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  final BleDevice device;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final AppStrings strings = context.strings;
    final Color zone = device.zone.color;
    final String name = device.hasName ? device.name : strings.unknownDevice;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 12), child: child),
        );
      },
      child: NeonCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 11),
        borderColor: selected ? zone.withValues(alpha: 0.55) : RadarColors.border,
        glowColor: selected ? zone : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 3,
              height: 54,
              decoration: BoxDecoration(
                color: zone.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                boxShadow: <BoxShadow>[
                  BoxShadow(color: zone.withValues(alpha: 0.5), blurRadius: 10),
                ],
              ),
            ),
            const SizedBox(width: 12),
            DeviceGlyph(kind: device.kind, color: zone, selected: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: RadarColors.textPrimary,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      if (device.isMock) ...<Widget>[
                        const SizedBox(width: 6),
                        CodeBadge(label: strings.demoBadge, color: RadarColors.purple),
                      ],
                      if (device.bearingFromSweep) ...<Widget>[
                        const SizedBox(width: 6),
                        const Icon(Icons.gps_fixed_rounded, size: 11, color: RadarColors.green),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          Formatters.macLike(device.id).replaceFirst('MOCK:', ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.monoLabel(size: 9, color: RadarColors.textMuted),
                        ),
                      ),
                      const SizedBox(width: 7),
                      CodeBadge(label: device.kind.code, color: zone),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: <Widget>[
                      SignalBars(rssi: device.smoothedRssi, color: zone, height: 15, barWidth: 3),
                      const SizedBox(width: 7),
                      Text(
                        Formatters.rssiWithUnit(device.smoothedRssi),
                        style: AppTheme.monoLabel(size: 9.5, color: RadarColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        Formatters.distanceValue(device.distanceMeters, settings.units),
                        style: AppTheme.mono.copyWith(fontSize: 15, color: zone),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        settings.units.symbolFor(settings.isArabic),
                        style: AppTheme.monoLabel(size: 9, color: RadarColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: RadarColors.textMuted, matchTextDirection: true),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
