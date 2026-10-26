import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/ble_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/radar_colors.dart';
import '../../domain/models/ble_status.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/glow_button.dart';
import '../widgets/common/neon_card.dart';
import '../widgets/radar/radar_painter.dart';

/// Startup gate: boot animation, permission explainer, Bluetooth-off recovery
/// and the escape hatch into demo mode.
class PermissionGateScreen extends StatelessWidget {
  const PermissionGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BleController ble = context.watch<BleController>();
    final SettingsController settings = context.watch<SettingsController>();
    final AppStrings strings = context.strings;
    final BleSessionStatus status = ble.status;

    final bool isPermissionState = status == BleSessionStatus.permissionRequired ||
        status == BleSessionStatus.permissionDenied ||
        status == BleSessionStatus.permissionPermanentlyDenied;
    final bool isAdapterState = status == BleSessionStatus.adapterOff ||
        status == BleSessionStatus.adapterUnsupported ||
        status == BleSessionStatus.unauthorized;

    final Color accent = switch (status) {
      BleSessionStatus.permissionDenied ||
      BleSessionStatus.permissionPermanentlyDenied ||
      BleSessionStatus.error =>
        RadarColors.red,
      BleSessionStatus.adapterOff => RadarColors.amber,
      BleSessionStatus.adapterUnsupported ||
      BleSessionStatus.unauthorized =>
        RadarColors.orange,
      _ => RadarColors.cyan,
    };

    final IconData heroIcon = switch (status) {
      BleSessionStatus.permissionRequired ||
      BleSessionStatus.permissionDenied ||
      BleSessionStatus.permissionPermanentlyDenied =>
        Icons.bluetooth_searching_rounded,
      BleSessionStatus.adapterOff => Icons.bluetooth_disabled_rounded,
      BleSessionStatus.adapterUnsupported => Icons.bluetooth_disabled_rounded,
      BleSessionStatus.unauthorized => Icons.lock_outline_rounded,
      BleSessionStatus.error => Icons.error_outline_rounded,
      _ => Icons.radar_rounded,
    };

    final String title = switch (status) {
      BleSessionStatus.initializing => strings.initTitle,
      BleSessionStatus.permissionRequired ||
      BleSessionStatus.permissionDenied ||
      BleSessionStatus.permissionPermanentlyDenied =>
        strings.permissionTitle,
      BleSessionStatus.adapterOff => strings.bluetoothOffTitle,
      BleSessionStatus.adapterUnsupported => strings.bluetoothUnsupportedTitle,
      BleSessionStatus.unauthorized => strings.unauthorizedTitle,
      BleSessionStatus.error => strings.scanError,
      _ => strings.appName,
    };

    final String body = switch (status) {
      BleSessionStatus.initializing => strings.initBody,
      BleSessionStatus.permissionRequired ||
      BleSessionStatus.permissionDenied ||
      BleSessionStatus.permissionPermanentlyDenied =>
        strings.permissionBody,
      BleSessionStatus.adapterOff => strings.bluetoothOffBody,
      BleSessionStatus.adapterUnsupported => strings.bluetoothUnsupportedBody,
      BleSessionStatus.unauthorized => strings.unauthorizedBody,
      BleSessionStatus.error => ble.errorMessage ?? strings.disclaimer,
      _ => strings.appSubtitle,
    };

    return AppBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '${strings.appName} · v${AppConstants.appVersion}',
                        style: AppTheme.monoLabel(
                          size: 8.5,
                          color: RadarColors.textMuted.withValues(alpha: 0.7),
                          letterSpacing: 0.8,
                        ),
                      ),
                      NeonIconButton(
                        icon: Icons.translate_rounded,
                        size: 36,
                        iconSize: 17,
                        color: RadarColors.textSecondary,
                        filled: true,
                        onPressed: settings.toggleLanguage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _GateHero(accent: accent, icon: heroIcon, busy: status == BleSessionStatus.initializing),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      height: 1.2,
                      color: RadarColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, height: 1.65, color: RadarColors.textSecondary),
                  ),
                  const SizedBox(height: 22),
                  if (isPermissionState) ...<Widget>[
                    _PermissionList(strings: strings),
                    const SizedBox(height: 16),
                    if (status == BleSessionStatus.permissionPermanentlyDenied)
                      _Notice(
                        color: RadarColors.red,
                        icon: Icons.lock_rounded,
                        text: strings.permissionPermanentlyDenied,
                      )
                    else if (status == BleSessionStatus.permissionDenied)
                      _Notice(
                        color: RadarColors.amber,
                        icon: Icons.info_outline_rounded,
                        text: strings.permissionDenied,
                      ),
                  ],
                  if (isAdapterState) ...<Widget>[
                    _Notice(
                      color: accent,
                      icon: Icons.info_outline_rounded,
                      text: status == BleSessionStatus.adapterOff
                          ? strings.bluetoothOffBody
                          : strings.bluetoothUnsupportedBody,
                    ),
                  ],
                  if (status == BleSessionStatus.error) ...<Widget>[
                    _Notice(
                      color: RadarColors.red,
                      icon: Icons.error_outline_rounded,
                      text: ble.errorMessage ?? strings.scanError,
                    ),
                  ],
                  if (status == BleSessionStatus.initializing) ...<Widget>[
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2, color: RadarColors.cyan),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ..._buildActions(context, ble, strings, status),
                  const SizedBox(height: 22),
                  Text(
                    strings.disclaimer,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      height: 1.55,
                      color: RadarColors.textMuted.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    BleController ble,
    AppStrings strings,
    BleSessionStatus status,
  ) {
    final Widget demoButton = GlowButton(
      label: strings.continueDemo,
      icon: Icons.science_rounded,
      variant: GlowButtonVariant.ghost,
      onPressed: () => ble.continueInDemoMode(),
    );
    final Widget settingsButton = GlowButton(
      label: strings.openSettings,
      icon: Icons.settings_rounded,
      variant: GlowButtonVariant.ghost,
      onPressed: () => ble.openSystemSettings(),
    );
    final Widget retryButton = GlowButton(
      label: strings.retry,
      icon: Icons.refresh_rounded,
      variant: GlowButtonVariant.secondary,
      onPressed: () => ble.retry(),
    );

    switch (status) {
      case BleSessionStatus.permissionRequired:
        return <Widget>[
          GlowButton(
            label: strings.grantPermissions,
            icon: Icons.shield_rounded,
            onPressed: () => ble.requestPermissions(),
          ),
          const SizedBox(height: 10),
          demoButton,
        ];
      case BleSessionStatus.permissionDenied:
        return <Widget>[
          GlowButton(
            label: strings.grantPermissions,
            icon: Icons.shield_rounded,
            onPressed: () => ble.requestPermissions(),
          ),
          const SizedBox(height: 10),
          settingsButton,
          const SizedBox(height: 10),
          demoButton,
        ];
      case BleSessionStatus.permissionPermanentlyDenied:
        return <Widget>[
          GlowButton(
            label: strings.openSettings,
            icon: Icons.settings_rounded,
            onPressed: () => ble.openSystemSettings(),
          ),
          const SizedBox(height: 10),
          demoButton,
        ];
      case BleSessionStatus.adapterOff:
        return <Widget>[
          GlowButton(
            label: strings.turnOnBluetooth,
            icon: Icons.bluetooth_rounded,
            onPressed: () => ble.enableBluetooth(),
          ),
          const SizedBox(height: 10),
          demoButton,
          const SizedBox(height: 10),
          retryButton,
        ];
      case BleSessionStatus.adapterUnsupported:
      case BleSessionStatus.unauthorized:
        return <Widget>[
          settingsButton,
          const SizedBox(height: 10),
          demoButton,
          const SizedBox(height: 10),
          retryButton,
        ];
      case BleSessionStatus.error:
        return <Widget>[
          retryButton,
          const SizedBox(height: 10),
          demoButton,
        ];
      case BleSessionStatus.initializing:
        return <Widget>[demoButton];
      case BleSessionStatus.scanning:
      case BleSessionStatus.paused:
      case BleSessionStatus.demoMode:
      case BleSessionStatus.idle:
        return <Widget>[];
    }
  }
}

class _GateHero extends StatefulWidget {
  const _GateHero({required this.accent, required this.icon, required this.busy});

  final Color accent;
  final IconData icon;
  final bool busy;

  @override
  State<_GateHero> createState() => _GateHeroState();
}

class _GateHeroState extends State<_GateHero> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 224,
      height: 224,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          ClipOval(
            child: SizedBox(
              width: 224,
              height: 224,
              child: CustomPaint(
                painter: RadarGridPainter(
                  ringCount: 3,
                  maxRangeMeters: 15,
                  accent: widget.accent,
                  showLabels: false,
                  radiusFactor: 0.96,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? _) {
              return Transform.rotate(
                angle: _controller.value * 6.28318530718,
                child: ClipOval(
                  child: Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: <Color>[
                          widget.accent.withValues(alpha: 0),
                          widget.accent.withValues(alpha: 0.02),
                          widget.accent.withValues(alpha: 0.22),
                        ],
                        stops: const <double>[0, 0.7, 1],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadarColors.cardGradient,
              border: Border.all(color: widget.accent.withValues(alpha: 0.45)),
              boxShadow: AppTheme.neon(widget.accent, blur: 30, alpha: 0.3),
            ),
            child: Icon(widget.icon, size: 38, color: widget.accent),
          ),
        ],
      ),
    );
  }
}

class _PermissionList extends StatelessWidget {
  const _PermissionList({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: <Widget>[
          _PermissionRow(
            icon: Icons.bluetooth_searching_rounded,
            title: strings.permissionScan,
            tag: null,
          ),
          const Divider(height: 1),
          _PermissionRow(
            icon: Icons.settings_bluetooth_rounded,
            title: strings.permissionConnect,
            tag: null,
          ),
          const Divider(height: 1),
          _PermissionRow(
            icon: Icons.location_on_outlined,
            title: strings.permissionLocation,
            tag: strings.permissionOptional,
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.icon, required this.title, required this.tag});

  final IconData icon;
  final String title;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: RadarColors.cyan.withValues(alpha: 0.1),
              border: Border.all(color: RadarColors.cyan.withValues(alpha: 0.24)),
            ),
            child: Icon(icon, size: 14, color: RadarColors.cyan),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 11, color: RadarColors.textSecondary, height: 1.4),
            ),
          ),
          if (tag != null) ...<Widget>[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: RadarColors.surfaceHigh,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: RadarColors.border),
              ),
              child: Text(
                tag!,
                style: AppTheme.monoLabel(size: 7.5, color: RadarColors.textMuted, letterSpacing: 0.3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.color, required this.icon, required this.text});

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 10.5, height: 1.55, color: color.withValues(alpha: 0.92)),
            ),
          ),
        ],
      ),
    );
  }
}
