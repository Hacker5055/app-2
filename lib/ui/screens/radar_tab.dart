import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/ble_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/radar_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/ble_device.dart';
import '../../domain/models/proximity_zone.dart';
import '../navigation.dart';
import '../widgets/common/labels.dart';
import '../widgets/common/neon_card.dart';
import '../widgets/common/screen_header.dart';
import '../widgets/device/device_glyph.dart';
import '../widgets/radar/radar_viewport.dart';

/// Overview radar showing every discovered device at once.
class RadarTab extends StatelessWidget {
  const RadarTab({super.key});

  @override
  Widget build(BuildContext context) {
    final BleController ble = context.watch<BleController>();
    final SettingsController settings = context.watch<SettingsController>();
    final AppStrings strings = context.strings;
    final List<BleDevice> devices = ble.allDevices;
    final BleDevice? nearest = devices.isEmpty ? null : devices.sortedByDistance().first;

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: ScreenHeader(
              kicker: '360° PROXIMITY',
              title: strings.radarTitle,
              subtitle: strings.radarSubtitle,
              trailing: _RangeBadge(range: settings.radarRange, onChanged: settings.setRadarRange),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  RadarViewport(
                    devices: devices,
                    maxRangeMeters: settings.radarRange,
                    selectedId: nearest?.id,
                    onDeviceTap: (BleDevice device) => openDeviceRadar(context, device),
                    isScanning: ble.isScanning,
                    isMock: settings.mockMode,
                    centerLabel: strings.radarCenter,
                  ),
                  if (devices.isEmpty)
                    _RadarEmptyOverlay(
                      isMockMode: settings.mockMode,
                      onEnableDemo: () => ble.setMockMode(true),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Column(
              children: <Widget>[
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 7,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final ProximityZone zone in ProximityZone.values)
                      ZoneChip(zone: zone, compact: true, showRange: false),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  strings.radarLegendHint,
                  textAlign: TextAlign.center,
                  style: AppTheme.monoLabel(
                    size: 9,
                    color: RadarColors.textMuted,
                    letterSpacing: 0.3,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (nearest != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _NearestDeviceCard(
                device: nearest,
                onTap: () => openDeviceRadar(context, nearest),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _RangeBadge extends StatelessWidget {
  const _RangeBadge({required this.range, required this.onChanged});

  final double range;
  final ValueChanged<double> onChanged;

  static const List<double> _presets = <double>[10, 20, 30, 50];

  void _cycle() {
    final int currentIndex = _presets.indexWhere((double value) => (value - range).abs() < 0.5);
    final int next = currentIndex < 0 ? 1 : (currentIndex + 1) % _presets.length;
    onChanged(_presets[next]);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _cycle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: RadarColors.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RadarColors.cyan.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.radar_rounded, size: 14, color: RadarColors.cyan),
            const SizedBox(height: 4),
            Text(
              '${range.round()} m',
              style: AppTheme.monoLabel(size: 10, color: RadarColors.cyan, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearestDeviceCard extends StatelessWidget {
  const _NearestDeviceCard({required this.device, required this.onTap});

  final BleDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final AppStrings strings = context.strings;
    final Color color = device.zone.color;

    return NeonCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      glowColor: color,
      borderColor: color.withValues(alpha: 0.35),
      child: Row(
        children: <Widget>[
          DeviceGlyph(kind: device.kind, color: color, selected: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.nearestDevice,
                  style: AppTheme.monoLabel(size: 8.5, color: RadarColors.textMuted, letterSpacing: 2),
                ),
                const SizedBox(height: 3),
                Text(
                  device.hasName ? device.name : strings.unknownDevice,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: RadarColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    Formatters.distanceValue(device.distanceMeters, settings.units),
                    style: AppTheme.mono.copyWith(fontSize: 22, color: color),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    settings.units.symbolFor(settings.isArabic),
                    style: AppTheme.monoLabel(size: 9.5, color: RadarColors.textMuted),
                  ),
                ],
              ),
              Text(
                '${strings.zoneLabel(device.zone)} · ${Formatters.rssiWithUnit(device.smoothedRssi)}',
                style: AppTheme.monoLabel(size: 8.5, color: color.withValues(alpha: 0.8)),
              ),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: RadarColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _RadarEmptyOverlay extends StatelessWidget {
  const _RadarEmptyOverlay({required this.isMockMode, required this.onEnableDemo});

  final bool isMockMode;
  final VoidCallback onEnableDemo;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    return IgnorePointer(
      ignoring: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: RadarColors.background.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: RadarColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.bluetooth_searching_rounded, size: 26, color: RadarColors.cyan),
            const SizedBox(height: 8),
            Text(
              strings.scanningHint,
              textAlign: TextAlign.center,
              style: AppTheme.monoLabel(
                size: 10,
                color: RadarColors.textSecondary,
                letterSpacing: 0.2,
                weight: FontWeight.w500,
              ),
            ),
            if (!isMockMode) ...<Widget>[
              const SizedBox(height: 10),
              TextButton(
                onPressed: onEnableDemo,
                child: Text(
                  strings.continueDemo,
                  style: const TextStyle(fontSize: 11, color: RadarColors.cyan),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
