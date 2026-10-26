import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/ble_controller.dart';
import '../../../controllers/settings_controller.dart';
import '../../../controllers/sweep_assistant_controller.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/radar_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/services/compass_service.dart';
import '../../../domain/models/ble_device.dart';
import '../../../domain/signal/azimuth_estimator.dart';
import '../common/glow_button.dart';
import 'sweep_dial.dart';

/// Opens the 360° direction finder for [deviceId].
Future<void> showSweepAssistant(BuildContext context, {required String deviceId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (BuildContext sheetContext) => SweepAssistantSheet(deviceId: deviceId),
  );
}

class SweepAssistantSheet extends StatefulWidget {
  const SweepAssistantSheet({super.key, required this.deviceId});

  final String deviceId;

  @override
  State<SweepAssistantSheet> createState() => _SweepAssistantSheetState();
}

class _SweepAssistantSheetState extends State<SweepAssistantSheet> {
  late final SweepAssistantController _controller;

  @override
  void initState() {
    super.initState();
    final CompassService compass = context.read<CompassService>();
    final bool simulate = context.read<SettingsController>().mockMode || !compass.isSupported;
    _controller = SweepAssistantController(
      bleController: context.read<BleController>(),
      compassService: compass,
      deviceId: widget.deviceId,
      simulateRotation: simulate,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.start();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double dialSize = math.min(MediaQuery.sizeOf(context).width - 88, 268);

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) {
        final BleDevice? device = _controller.device;
        final SweepResult? result = _controller.result;
        final Color accent = _controller.isComplete ? RadarColors.green : RadarColors.cyan;

        return Container(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
          decoration: BoxDecoration(
            color: RadarColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: accent.withValues(alpha: 0.35)),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 40, spreadRadius: 4),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RadarColors.borderBright,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: accent.withValues(alpha: 0.12),
                        border: Border.all(color: accent.withValues(alpha: 0.35)),
                      ),
                      child: Icon(Icons.explore_rounded, size: 20, color: accent),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            strings.sweepTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: RadarColors.textPrimary,
                            ),
                          ),
                          Text(
                            device != null && device.hasName ? device.name : strings.sweepAssistant,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.monoLabel(size: 9, color: RadarColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    NeonIconButton(
                      icon: Icons.close_rounded,
                      size: 36,
                      iconSize: 18,
                      color: RadarColors.textSecondary,
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: strings.close,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  strings.sweepIntro,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, height: 1.6, color: RadarColors.textSecondary),
                ),
                const SizedBox(height: 14),
                SweepDial(
                  size: dialSize,
                  heading: _controller.liveHeading,
                  progress: _controller.progress,
                  bestHeading: result?.peakHeadingDegrees,
                  accent: accent,
                  child: Padding(
                    padding: EdgeInsets.all(dialSize * 0.16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          Formatters.heading(_controller.liveHeading),
                          style: AppTheme.mono.copyWith(fontSize: 30, color: accent),
                        ),
                        Text(
                          Formatters.compassPoint(_controller.liveHeading),
                          style: AppTheme.monoLabel(size: 9, color: RadarColors.textSecondary, letterSpacing: 3),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _controller.isComplete
                              ? strings.sweepComplete
                              : strings.sweepDegreesLeft(_controller.degreesRemaining),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: _controller.isComplete ? RadarColors.green : RadarColors.textMuted,
                          ),
                        ),
                        if (device != null) ...<Widget>[
                          const SizedBox(height: 3),
                          Text(
                            Formatters.rssiWithUnit(device.smoothedRssi),
                            style: AppTheme.monoLabel(size: 8.5, color: device.zone.color),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Text(
                      strings.sweepProgress,
                      style: AppTheme.monoLabel(size: 8.5, color: RadarColors.textMuted, letterSpacing: 1.4),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: <Widget>[
                            Container(height: 6, color: RadarColors.surfaceHigh),
                            FractionallySizedBox(
                              widthFactor: _controller.progress.clamp(0.0, 1.0),
                              child: Container(
                                height: 6,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: <Color>[RadarColors.cyan, RadarColors.purple],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      Formatters.percent(_controller.progress),
                      style: AppTheme.monoLabel(size: 9, color: accent, letterSpacing: 0.5),
                    ),
                  ],
                ),
                if (_controller.usingSimulation) ...<Widget>[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.science_rounded, size: 13, color: RadarColors.purple),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          context.read<SettingsController>().mockMode
                              ? strings.sweepSimulated
                              : strings.sweepNoCompass,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 9.5, color: RadarColors.purple),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                if (result != null) _SweepResultCard(result: result),
                const SizedBox(height: 14),
                if (_controller.isComplete)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: GlowButton(
                          label: strings.sweepLock,
                          icon: Icons.gps_fixed_rounded,
                          variant: GlowButtonVariant.success,
                          onPressed: () {
                            _controller.lockBearing();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(strings.bearingLocked)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      NeonIconButton(
                        icon: Icons.replay_rounded,
                        size: 52,
                        iconSize: 22,
                        color: RadarColors.cyan,
                        tooltip: strings.sweepAgain,
                        onPressed: _controller.restart,
                      ),
                    ],
                  )
                else
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: GlowButton(
                          label: strings.close,
                          variant: GlowButtonVariant.ghost,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ],
                  ),
                if (_controller.isComplete) ...<Widget>[
                  const SizedBox(height: 10),
                  GlowButton(
                    label: strings.done,
                    variant: GlowButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SweepResultCard extends StatelessWidget {
  const _SweepResultCard({required this.result});

  final SweepResult result;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: RadarColors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RadarColors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.sweepPeakHeading,
                  style: AppTheme.monoLabel(size: 8, color: RadarColors.textMuted, letterSpacing: 1.6),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Text(
                      Formatters.heading(result.headingDegrees),
                      style: AppTheme.mono.copyWith(fontSize: 26, color: RadarColors.green),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      result.compassPoint,
                      style: AppTheme.monoLabel(
                        size: 11,
                        color: RadarColors.green.withValues(alpha: 0.85),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                strings.sweepConfidence,
                style: AppTheme.monoLabel(size: 8, color: RadarColors.textMuted, letterSpacing: 1.6),
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.percent(result.confidence),
                style: AppTheme.mono.copyWith(fontSize: 18, color: RadarColors.textPrimary),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 84,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    children: <Widget>[
                      Container(height: 4, color: RadarColors.surfaceHigh),
                      FractionallySizedBox(
                        widthFactor: result.confidence.clamp(0.0, 1.0),
                        child: Container(height: 4, color: RadarColors.green),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${result.sampleCount} · ${Formatters.rssiWithUnit(result.bestRssi)}',
                style: AppTheme.monoLabel(size: 8, color: RadarColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
