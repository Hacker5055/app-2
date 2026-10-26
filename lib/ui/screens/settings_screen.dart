import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/ble_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/radar_colors.dart';
import '../../domain/models/ble_device.dart';
import '../../domain/models/ble_status.dart';
import '../../domain/models/distance_unit.dart';
import '../widgets/common/glow_button.dart';
import '../widgets/common/labels.dart';
import '../widgets/common/neon_card.dart';
import '../widgets/common/screen_header.dart';

/// Full settings tab: language, units, alerts, demo mode, signal calibration.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final BleController ble = context.watch<BleController>();
    final AppStrings strings = context.strings;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 130),
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          ScreenHeader(
            kicker: 'CONFIG',
            title: strings.settingsTitle,
            subtitle: strings.appName,
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: strings.sectionAppearance,
            children: <Widget>[
              _SettingRow(
                icon: Icons.translate_rounded,
                color: RadarColors.cyan,
                title: strings.language,
                subtitle: settings.isArabic ? strings.languageArabic : strings.languageEnglish,
                trailing: _SegmentedPair(
                  firstLabel: 'العربية',
                  secondLabel: 'EN',
                  firstActive: settings.isArabic,
                  onFirst: () => settings.setLanguage('ar'),
                  onSecond: () => settings.setLanguage('en'),
                ),
              ),
              _SettingRow(
                icon: Icons.straighten_rounded,
                color: RadarColors.purple,
                title: strings.units,
                subtitle: settings.units == DistanceUnit.meters
                    ? strings.unitsMetric
                    : strings.unitsImperial,
                trailing: _SegmentedPair(
                  firstLabel: 'm',
                  secondLabel: 'ft',
                  firstActive: settings.units == DistanceUnit.meters,
                  onFirst: () => settings.setUnits(DistanceUnit.meters),
                  onSecond: () => settings.setUnits(DistanceUnit.feet),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: strings.sectionAlerts,
            children: <Widget>[
              _SwitchRow(
                icon: Icons.volume_up_rounded,
                color: RadarColors.orange,
                title: strings.soundAlerts,
                subtitle: strings.playSoundHint,
                value: settings.soundEnabled,
                onChanged: settings.setSoundEnabled,
              ),
              _SwitchRow(
                icon: Icons.vibration_rounded,
                color: RadarColors.purple,
                title: strings.hapticAlerts,
                subtitle: strings.zoneHintHot,
                value: settings.hapticsEnabled,
                onChanged: settings.setHapticsEnabled,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: strings.sectionScanning,
            children: <Widget>[
              _SwitchRow(
                icon: Icons.science_rounded,
                color: RadarColors.purple,
                title: strings.mockData,
                subtitle: strings.mockDataHint,
                value: settings.mockMode,
                onChanged: (bool value) => context.read<BleController>().setMockMode(value),
              ),
              _SettingRow(
                icon: Icons.devices_rounded,
                color: RadarColors.cyan,
                title: strings.devicesInRange(ble.allDevices.length),
                subtitle: ble.status == BleSessionStatus.paused ? strings.paused : strings.scanning,
                trailing: Text(
                  '${ble.allDevices.length}',
                  style: AppTheme.mono.copyWith(fontSize: 18, color: RadarColors.cyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: strings.sectionSignal,
            children: <Widget>[
              _SliderRow(
                label: strings.emaAlpha,
                hint: strings.emaAlphaHint,
                valueLabel: settings.emaAlpha.toStringAsFixed(2),
                value: settings.emaAlpha,
                min: AppConstants.minEmaAlpha,
                max: AppConstants.maxEmaAlpha,
                divisions: 16,
                onChanged: settings.setEmaAlpha,
              ),
              _SliderRow(
                label: strings.pathLoss,
                hint: strings.pathLossHint,
                valueLabel: settings.pathLossExponent.toStringAsFixed(1),
                value: settings.pathLossExponent,
                min: AppConstants.minPathLossExponent,
                max: AppConstants.maxPathLossExponent,
                divisions: 12,
                onChanged: settings.setPathLossExponent,
              ),
              _SliderRow(
                label: strings.txPower,
                hint: strings.txPowerHint,
                valueLabel: '${settings.txPower.round()} dBm',
                value: settings.txPower,
                min: AppConstants.minTxPower,
                max: AppConstants.maxTxPower,
                divisions: 55,
                onChanged: settings.setTxPower,
              ),
              _SliderRow(
                label: strings.radarRange,
                hint: strings.radarRangeHint,
                valueLabel: '${settings.radarRange.round()} m',
                value: settings.radarRange,
                min: AppConstants.minRadarRangeMeters,
                max: AppConstants.maxRadarRangeMeters,
                divisions: 9,
                onChanged: settings.setRadarRange,
              ),
              const SizedBox(height: 6),
              _CalibrationTile(ble: ble, settings: settings),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: strings.sectionAbout,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF103340), Color(0xFF0B1A2A)],
                      ),
                      border: Border.all(color: RadarColors.cyan.withValues(alpha: 0.35)),
                    ),
                    child: const Icon(Icons.radar_rounded, color: RadarColors.cyan, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.appName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: RadarColors.textPrimary,
                        ),
                      ),
                      Text(
                        strings.version(AppConstants.appVersion),
                        style: AppTheme.monoLabel(size: 9, color: RadarColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                strings.aboutBody,
                style: const TextStyle(fontSize: 11.5, height: 1.65, color: RadarColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Text(
                strings.permissionsInfo.toUpperCase(),
                style: AppTheme.monoLabel(size: 8.5, color: RadarColors.textMuted, letterSpacing: 2),
              ),
              const SizedBox(height: 5),
              Text(
                strings.permissionListBody,
                style: AppTheme.monoLabel(
                  size: 9.5,
                  color: RadarColors.textSecondary,
                  letterSpacing: 0,
                  weight: FontWeight.w400,
                ).copyWith(height: 1.6),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RadarColors.amber.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: RadarColors.amber.withValues(alpha: 0.22)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.info_outline_rounded, size: 14, color: RadarColors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.disclaimer,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.55,
                          color: RadarColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlowButton(
            label: strings.resetDefaults,
            icon: Icons.restart_alt_rounded,
            variant: GlowButtonVariant.ghost,
            onPressed: () => _confirmReset(context, strings, settings),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              '${strings.appName} · v${AppConstants.appVersion}',
              style: AppTheme.monoLabel(size: 8.5, color: RadarColors.textMuted.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    AppStrings strings,
    SettingsController settings,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: RadarColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: RadarColors.border),
        ),
        title: Text(
          strings.resetConfirmTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: RadarColors.textPrimary),
        ),
        content: Text(
          strings.resetConfirmBody,
          style: const TextStyle(fontSize: 12.5, height: 1.5, color: RadarColors.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel, style: const TextStyle(color: RadarColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: RadarColors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(strings.reset),
          ),
        ],
      ),
    );
    if (confirmed == true) settings.resetSignalDefaults();
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> spaced = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        spaced.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: RadarColors.border),
          ),
        );
      }
      spaced.add(children[i]);
    }
    return NeonCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionLabel(label: title),
          const SizedBox(height: 13),
          ...spaced,
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.11),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _IconBox(icon: icon, color: color),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: RadarColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.monoLabel(
                  size: 8.5,
                  color: RadarColors.textMuted,
                  letterSpacing: 0.1,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingRow(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.hint,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: RadarColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: RadarColors.cyan.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: RadarColors.cyan.withValues(alpha: 0.22)),
              ),
              child: Text(
                valueLabel,
                style: AppTheme.monoLabel(size: 9.5, color: RadarColors.cyan, letterSpacing: 0.2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
        Text(
          hint,
          style: const TextStyle(fontSize: 9.5, height: 1.5, color: RadarColors.textMuted),
        ),
      ],
    );
  }
}

class _SegmentedPair extends StatelessWidget {
  const _SegmentedPair({
    required this.firstLabel,
    required this.secondLabel,
    required this.firstActive,
    required this.onFirst,
    required this.onSecond,
  });

  final String firstLabel;
  final String secondLabel;
  final bool firstActive;
  final VoidCallback onFirst;
  final VoidCallback onSecond;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: RadarColors.backgroundDeep,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: RadarColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _SegmentButton(label: firstLabel, active: firstActive, onTap: onFirst),
          _SegmentButton(label: secondLabel, active: !firstActive, onTap: onSecond),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minWidth: 42),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: active
              ? LinearGradient(
                  colors: <Color>[
                    RadarColors.cyan.withValues(alpha: 0.28),
                    RadarColors.cyan.withValues(alpha: 0.08),
                  ],
                )
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? RadarColors.cyan : RadarColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _CalibrationTile extends StatelessWidget {
  const _CalibrationTile({required this.ble, required this.settings});

  final BleController ble;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    final BleDevice? target = ble.nearest ?? ble.selectedDevice;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: RadarColors.cyan.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: RadarColors.cyan.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.gps_fixed_rounded, size: 15, color: RadarColors.cyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.calibrate,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: RadarColors.textPrimary,
                  ),
                ),
              ),
              GlowButton(
                label: strings.calibrate,
                variant: GlowButtonVariant.secondary,
                compact: true,
                expand: false,
                height: 32,
                icon: Icons.tune_rounded,
                onPressed: () {
                  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
                  if (target == null) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(strings.calibrateFailed)),
                    );
                    return;
                  }
                  settings.applyOneMeterCalibration(target.smoothedRssi);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(strings.calibrated(target.smoothedRssi.round().toString())),
                      backgroundColor: RadarColors.surfaceHigh,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            strings.calibrateHint,
            style: const TextStyle(fontSize: 9.5, height: 1.5, color: RadarColors.textMuted),
          ),
        ],
      ),
    );
  }
}
