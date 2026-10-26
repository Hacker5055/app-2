import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/ble_controller.dart';
import '../../controllers/device_tracking_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/radar_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/display_service.dart';
import '../../data/services/gatt_alert_service.dart';
import '../../data/services/haptics_service.dart';
import '../../domain/models/ble_device.dart';
import '../../domain/models/distance_unit.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/glow_button.dart';
import '../widgets/common/labels.dart';
import '../widgets/common/neon_card.dart';
import '../widgets/common/pulse_dot.dart';
import '../widgets/common/signal_bars.dart';
import '../widgets/radar/radar_viewport.dart';
import '../widgets/radar/rssi_sparkline.dart';
import '../widgets/radar/sweep_assistant_sheet.dart';

/// Dedicated tracking screen: giant radar, live distance, Geiger feedback,
/// GATT alert trigger, 360° sweep and the "found it" celebration.
class DeviceRadarScreen extends StatefulWidget {
  const DeviceRadarScreen({super.key, required this.deviceId, this.initialDevice});

  final String deviceId;
  final BleDevice? initialDevice;

  @override
  State<DeviceRadarScreen> createState() => _DeviceRadarScreenState();
}

class _DeviceRadarScreenState extends State<DeviceRadarScreen> with WidgetsBindingObserver {
  late final DeviceTrackingController _tracking;
  late final ConfettiController _confetti;
  final GattAlertService _alerts = const GattAlertService();
  static const DisplayService _display = DisplayService();

  bool _alertBusy = false;
  bool _markedFound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _tracking = DeviceTrackingController(
      bleController: context.read<BleController>(),
      settings: context.read<SettingsController>(),
      audio: context.read<AudioService>(),
      haptics: context.read<HapticsService>(),
    )..attach(widget.deviceId);
    // The radar is meant to be watched while walking: hold the screen on.
    unawaited(_display.setKeepScreenOn(enabled: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_display.setKeepScreenOn(enabled: false));
    _tracking.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _tracking.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    final BleController ble = context.watch<BleController>();
    final SettingsController settings = context.watch<SettingsController>();
    final AppStrings strings = context.strings;
    final BleDevice? live = ble.deviceById(widget.deviceId);
    final BleDevice? device = live ?? widget.initialDevice;
    final bool signalLost = live == null;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            if (device == null)
              _buildLost(context, strings)
            else
              SafeArea(
                bottom: false,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: _buildTopBar(context, device, strings, signalLost),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
                        physics: const BouncingScrollPhysics(),
                        children: <Widget>[
                          if (signalLost) ...<Widget>[
                            _SignalLostBanner(
                              message: strings.signalLostBody,
                              actionLabel: strings.scanAgain,
                              onAction: ble.rescan,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _DistanceHero(
                            device: device,
                            settings: settings,
                            pulseBadge: _PulseBadge(tracking: _tracking, device: device),
                            found: _markedFound,
                          ),
                          const SizedBox(height: 12),
                          AspectRatio(
                            aspectRatio: 1,
                            child: RadarViewport(
                              devices: <BleDevice>[device],
                              selectedId: device.id,
                              maxRangeMeters: settings.radarRange,
                              accent: device.zone.color,
                              isScanning: ble.isScanning,
                              isMock: device.isMock,
                              centerLabel: strings.radarCenter,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: GlowButton(
                                  label: strings.playSound,
                                  icon: Icons.campaign_rounded,
                                  variant: GlowButtonVariant.secondary,
                                  busy: _alertBusy,
                                  onPressed: _alertBusy ? null : () => _triggerAlert(device),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GlowButton(
                                  label: strings.sweepAssistant,
                                  icon: Icons.explore_rounded,
                                  variant: GlowButtonVariant.ghost,
                                  onPressed: () => _openSweep(device),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GlowButton(
                            label: _markedFound ? strings.foundBadge : strings.markFound,
                            icon: Icons.check_circle_rounded,
                            variant: GlowButtonVariant.success,
                            onPressed: () => _markFound(device),
                          ),
                          const SizedBox(height: 16),
                          _SignalCard(device: device, tracking: _tracking),
                          const SizedBox(height: 12),
                          _DiagnosticsCard(device: device),
                          const SizedBox(height: 12),
                          _IdentityCard(device: device),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 22,
                  gravity: 0.16,
                  emissionFrequency: 0.02,
                  shouldLoop: false,
                  colors: const <Color>[
                    RadarColors.cyan,
                    RadarColors.purple,
                    RadarColors.orange,
                    RadarColors.green,
                    RadarColors.red,
                    Colors.white,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    BleDevice device,
    AppStrings strings,
    bool signalLost,
  ) {
    final Color zone = device.zone.color;
    return Row(
      children: <Widget>[
        NeonIconButton(
          icon: Icons.arrow_back_rounded,
          matchTextDirection: true,
          size: 40,
          iconSize: 19,
          color: RadarColors.textPrimary,
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: strings.close,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                device.hasName ? device.name : strings.unknownDevice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: RadarColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: <Widget>[
                  PulseDot(
                    color: signalLost ? RadarColors.amber : zone,
                    size: 4,
                    haloScale: 2,
                    active: !signalLost,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    signalLost
                        ? strings.signalLostTitle
                        : '${strings.trackingLabel} · ${device.shortId}',
                    style: AppTheme.monoLabel(
                      size: 8.5,
                      color: signalLost ? RadarColors.amber : RadarColors.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _tracking,
          builder: (BuildContext context, Widget? _) => NeonIconButton(
            icon: _tracking.isGeigerEnabled ? Icons.graphic_eq_rounded : Icons.volume_off_rounded,
            size: 40,
            iconSize: 19,
            color: zone,
            filled: _tracking.isGeigerEnabled,
            tooltip: _tracking.isGeigerEnabled ? strings.geigerActive : strings.geigerMuted,
            onPressed: _tracking.toggleGeiger,
          ),
        ),
      ],
    );
  }

  Widget _buildLost(BuildContext context, AppStrings strings) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.portable_wifi_off_rounded, size: 46, color: RadarColors.amber),
            const SizedBox(height: 16),
            Text(
              strings.signalLostTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RadarColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              strings.signalLostBody,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, height: 1.6, color: RadarColors.textSecondary),
            ),
            const SizedBox(height: 24),
            GlowButton(
              label: strings.close,
              variant: GlowButtonVariant.ghost,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerAlert(BleDevice device) async {
    setState(() => _alertBusy = true);
    final AudioService audio = context.read<AudioService>();
    final HapticsService haptics = context.read<HapticsService>();
    final BleController ble = context.read<BleController>();

    GattAlertResult result;
    if (device.isMock) {
      await Future<void>.delayed(const Duration(milliseconds: 550));
      result = device.supportsAlertService ? GattAlertResult.sent : GattAlertResult.unsupported;
      if (result == GattAlertResult.sent) unawaited(audio.ping(volume: 0.7, tone: PingTone.hot));
    } else {
      result = await _alerts.triggerAlert(device.id);
      if (result == GattAlertResult.sent) {
        ble.updateAlertSupport(device.id, true);
      } else if (result == GattAlertResult.unsupported) {
        ble.updateAlertSupport(device.id, false);
      }
    }

    if (!mounted) return;
    setState(() => _alertBusy = false);
    if (result == GattAlertResult.sent) unawaited(haptics.alert());

    final String message = switch (result) {
      GattAlertResult.sent => context.strings.alertSent,
      GattAlertResult.unsupported => context.strings.alertUnsupported,
      GattAlertResult.failed => context.strings.alertFailed,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: RadarColors.surfaceHigh,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openSweep(BleDevice device) async {
    await showSweepAssistant(context, deviceId: device.id);
  }

  Future<void> _markFound(BleDevice device) async {
    final AppStrings strings = context.strings;
    final AudioService audio = context.read<AudioService>();
    final HapticsService haptics = context.read<HapticsService>();
    setState(() => _markedFound = true);
    _confetti.play();
    unawaited(audio.playSuccess());
    unawaited(haptics.success());
    context.read<BleController>().markFound(device.id);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext dialogContext) => _FoundDialog(
        device: device,
        strings: strings,
        onBackToDevices: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).maybePop();
        },
        onKeepTracking: () => Navigator.of(dialogContext).pop(),
      ),
    );
    if (mounted) _confetti.stop();
  }
}

class _PulseBadge extends StatelessWidget {
  const _PulseBadge({required this.tracking, required this.device});

  final DeviceTrackingController tracking;
  final BleDevice device;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tracking,
      builder: (BuildContext context, Widget? _) {
        final Color color = device.zone.color;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PulseDot(color: color, size: 5, haloScale: 2.4, active: tracking.isGeigerEnabled),
            const SizedBox(width: 6),
            Text(
              '${context.strings.pulseInterval} ${tracking.currentIntervalMs}ms',
              style: AppTheme.monoLabel(size: 8, color: color.withValues(alpha: 0.85), letterSpacing: 0.4),
            ),
          ],
        );
      },
    );
  }
}

class _DistanceHero extends StatelessWidget {
  const _DistanceHero({
    required this.device,
    required this.settings,
    required this.pulseBadge,
    required this.found,
  });

  final BleDevice device;
  final SettingsController settings;
  final Widget pulseBadge;
  final bool found;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    final Color zone = device.zone.color;
    final String value = Formatters.distanceValue(device.distanceMeters, settings.units);
    final String unitWord =
        settings.units == DistanceUnit.meters ? strings.metersAway : strings.feetAway;

    return NeonCard(
      glowColor: zone,
      borderColor: zone.withValues(alpha: 0.38),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      innerGradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: <Color>[zone.withValues(alpha: 0.12), Colors.transparent],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ZoneChip(zone: device.zone),
              const Spacer(),
              if (device.isMock) ...<Widget>[
                CodeBadge(label: strings.demoBadge, color: RadarColors.purple),
                const SizedBox(width: 6),
              ],
              if (found) CodeBadge(label: strings.foundBadge, color: RadarColors.green),
              if (!found) pulseBadge,
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 58,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                    color: zone,
                    shadows: <Shadow>[
                      Shadow(color: zone.withValues(alpha: 0.55), blurRadius: 26),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    settings.units.symbolFor(settings.isArabic),
                    style: AppTheme.monoLabel(size: 14, color: RadarColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    Formatters.rssiWithUnit(device.smoothedRssi),
                    style: AppTheme.monoLabel(size: 10, color: zone.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.distanceReadout(value, unitWord),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: RadarColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.zoneHint(device.zone),
            style: const TextStyle(fontSize: 11, height: 1.55, color: RadarColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.device, required this.tracking});

  final BleDevice device;
  final DeviceTrackingController tracking;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    final Color zone = device.zone.color;
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionLabel(label: strings.signalStrength, accent: zone),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              SignalBars(rssi: device.smoothedRssi, color: zone, height: 34, barWidth: 6.5, gap: 4),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    Formatters.rssiWithUnit(device.smoothedRssi),
                    style: AppTheme.mono.copyWith(fontSize: 22, color: zone),
                  ),
                  Text(
                    strings.smoothedRssi,
                    style: AppTheme.monoLabel(size: 8, color: RadarColors.textMuted, letterSpacing: 1.6),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    Formatters.percent(device.signalFraction),
                    style: AppTheme.mono.copyWith(fontSize: 16, color: RadarColors.textSecondary),
                  ),
                  Text(
                    strings.signalLabel,
                    style: AppTheme.monoLabel(size: 8, color: RadarColors.textMuted, letterSpacing: 1.6),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          RssiSparkline(samples: device.signalHistory, color: zone),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: strings.rawRssi,
                  value: Formatters.rssi(device.rssi),
                  unit: 'dBm',
                  color: RadarColors.textSecondary,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: strings.smoothedRssi,
                  value: Formatters.rssi(device.smoothedRssi),
                  unit: 'dBm',
                  color: zone,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: strings.pulseInterval,
                  value: '${tracking.currentIntervalMs}',
                  unit: 'ms',
                  color: RadarColors.cyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({required this.device});

  final BleDevice device;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    final String age = Formatters.relativeAge(
      device.age(DateTime.now()),
      now: strings.now,
      secondsAgo: strings.secondsAgo,
      minutesAgo: strings.minutesAgo,
    );
    final double headingDegrees = device.bearingRadians * 180 / math.pi;

    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionLabel(label: strings.deviceDetails),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: strings.txPower,
                  value: '${device.txPowerUsed.round()}',
                  unit: 'dBm',
                  icon: Icons.cell_tower_rounded,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: 'n',
                  value: device.pathLossExponentUsed.toStringAsFixed(1),
                  icon: Icons.timeline_rounded,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: strings.lastSeenLabel,
                  value: age,
                  icon: Icons.schedule_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: strings.alertService,
                  value: device.supportsAlertService ? strings.yes : strings.notAvailable,
                  color: device.supportsAlertService ? RadarColors.green : RadarColors.textSecondary,
                  icon: Icons.campaign_rounded,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: strings.connectable,
                  value: device.isConnectable ? strings.yes : strings.no,
                  icon: Icons.usb_rounded,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: strings.radarCenter,
                  value: device.shortId,
                  icon: Icons.memory_rounded,
                ),
              ),
            ],
          ),
          if (device.bearingFromSweep) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: RadarColors.green.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: RadarColors.green.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.explore_rounded, size: 14, color: RadarColors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.bearingLocked,
                      style: const TextStyle(fontSize: 10, color: RadarColors.textSecondary),
                    ),
                  ),
                  Text(
                    Formatters.heading(headingDegrees),
                    style: AppTheme.mono.copyWith(fontSize: 13, color: RadarColors.green),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            strings.bearingsNote,
            style: const TextStyle(fontSize: 9.5, height: 1.5, color: RadarColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.device});

  final BleDevice device;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionLabel(label: strings.deviceIdLabel),
          const SizedBox(height: 12),
          SelectableText(
            Formatters.macLike(device.id),
            style: AppTheme.mono.copyWith(fontSize: 12, color: RadarColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: <Widget>[
              CodeBadge(label: device.kind.code, color: device.zone.color),
              CodeBadge(
                label: device.isMock ? strings.demoBadge : strings.liveBadge,
                color: device.isMock ? RadarColors.purple : RadarColors.green,
              ),
              if (device.txPower != null)
                CodeBadge(label: 'TX ${device.txPower} dBm', color: RadarColors.cyan),
              CodeBadge(
                label: device.bearingFromSweep ? 'BEARING LOCKED' : 'BEARING EST.',
                color: device.bearingFromSweep ? RadarColors.green : RadarColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalLostBanner extends StatelessWidget {
  const _SignalLostBanner({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: RadarColors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RadarColors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.wifi_tethering_error_rounded, size: 16, color: RadarColors.amber),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 10, height: 1.5, color: RadarColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              onAction();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel, style: const TextStyle(fontSize: 10, color: RadarColors.amber)),
          ),
        ],
      ),
    );
  }
}

class _FoundDialog extends StatelessWidget {
  const _FoundDialog({
    required this.device,
    required this.strings,
    required this.onBackToDevices,
    required this.onKeepTracking,
  });

  final BleDevice device;
  final AppStrings strings;
  final VoidCallback onBackToDevices;
  final VoidCallback onKeepTracking;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          gradient: RadarColors.cardGradient,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: RadarColors.green.withValues(alpha: 0.38)),
          boxShadow: AppTheme.neon(RadarColors.green, blur: 34, alpha: 0.22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF66FFC9), Color(0xFF00C98A)],
                ),
                boxShadow: AppTheme.neon(RadarColors.green, blur: 26, alpha: 0.4),
              ),
              child: const Icon(Icons.check_rounded, size: 36, color: Color(0xFF00231A)),
            ),
            const SizedBox(height: 16),
            Text(
              strings.foundTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: RadarColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.foundBody(device.hasName ? device.name : strings.unknownDevice),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, height: 1.6, color: RadarColors.textSecondary),
            ),
            const SizedBox(height: 20),
            GlowButton(
              label: strings.backToDevices,
              variant: GlowButtonVariant.success,
              icon: Icons.arrow_back_rounded,
              onPressed: onBackToDevices,
            ),
            const SizedBox(height: 8),
            GlowButton(
              label: strings.keepTracking,
              variant: GlowButtonVariant.ghost,
              onPressed: onKeepTracking,
            ),
          ],
        ),
      ),
    );
  }
}
