import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/radar_colors.dart';
import '../../../domain/models/ble_device.dart';
import 'radar_painter.dart';

/// The animated, interactive radar.
///
/// Node placement is intentional: the **radius** is the estimated distance and
/// the **angle** is either the placeholder bearing or the result of the 360°
/// sweep. Tapping a node calls [onDeviceTap].
class RadarViewport extends StatefulWidget {
  const RadarViewport({
    super.key,
    required this.devices,
    this.maxRangeMeters = AppConstants.defaultRadarRangeMeters,
    this.selectedId,
    this.onDeviceTap,
    this.accent = RadarColors.cyan,
    this.isScanning = true,
    this.isMock = false,
    this.showHud = true,
    this.showRangeLabels = true,
    this.centerLabel,
    this.padding = 10,
  });

  final List<BleDevice> devices;
  final double maxRangeMeters;
  final String? selectedId;
  final ValueChanged<BleDevice>? onDeviceTap;
  final Color accent;
  final bool isScanning;
  final bool isMock;
  final bool showHud;
  final bool showRangeLabels;
  final String? centerLabel;
  final double padding;

  static const double nodeRadiusFactor = 0.86;

  @override
  State<RadarViewport> createState() => _RadarViewportState();
}

class _RadarViewportState extends State<RadarViewport> with TickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: AppConstants.radarSweepPeriod,
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppConstants.radarPulsePeriod,
  )..repeat();

  late final AnimationController _nodePulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _sweep.dispose();
    _pulse.dispose();
    _nodePulse.dispose();
    super.dispose();
  }

  BleDevice? get _selected {
    for (final BleDevice device in widget.devices) {
      if (device.id == widget.selectedId) return device;
    }
    return null;
  }

  void _handleTap(Offset localPosition, Size size) {
    final ValueChanged<BleDevice>? onTap = widget.onDeviceTap;
    if (onTap == null) return;
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2 * RadarViewport.nodeRadiusFactor;
    BleDevice? hit;
    double bestDistance = 30;
    for (final BleDevice device in widget.devices) {
      final double fraction = device.radarRadiusFraction(widget.maxRangeMeters);
      final Offset position = center +
          Offset(math.cos(device.bearingRadians), math.sin(device.bearingRadians)) * (fraction * radius);
      final double distance = (position - localPosition).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        hit = device;
      }
    }
    if (hit != null) {
      HapticFeedback.selectionClick();
      onTap(hit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    final BleDevice? selected = _selected;
    final List<BleDevice> ordered = widget.devices.reversed.toList(growable: false);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side = math.min(
          constraints.maxWidth,
          constraints.maxHeight.isFinite ? constraints.maxHeight : constraints.maxWidth,
        );
        final Size size = Size.square(side);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // Static face -------------------------------------------------
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: RadarGridPainter(
                        ringCount: AppConstants.radarRingCount,
                        maxRangeMeters: widget.maxRangeMeters,
                        accent: widget.accent,
                        showLabels: widget.showRangeLabels,
                      ),
                    ),
                  ),
                ),

                // Pulses ------------------------------------------------------
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (BuildContext context, Widget? _) => CustomPaint(
                        painter: RadarPulsePainter(
                          progress: _pulse.value,
                          color: widget.accent,
                          intensity: selected?.zone.intensity ?? 0.35,
                        ),
                      ),
                    ),
                  ),
                ),

                // Sweep -------------------------------------------------------
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _sweep,
                      builder: (BuildContext context, Widget? _) => CustomPaint(
                        painter: RadarSweepPainter(
                          angle: _sweep.value * 2 * math.pi,
                          color: widget.accent,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bearing ray of the tracked device ---------------------------
                if (selected != null && selected.bearingFromSweep)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: RadarBearingPainter(
                          bearing: selected.bearingRadians,
                          color: selected.zone.color,
                          radiusFraction: selected.radarRadiusFraction(widget.maxRangeMeters),
                          radiusFactor: 0.94,
                        ),
                      ),
                    ),
                  ),

                // Device nodes ------------------------------------------------
                for (int index = 0; index < ordered.length; index++)
                  _buildNode(ordered[index], index, side),

                // User marker -------------------------------------------------
                Align(
                  alignment: Alignment.center,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _nodePulse,
                      builder: (BuildContext context, Widget? _) {
                        final double t = _nodePulse.value;
                        return SizedBox(
                          width: 46,
                          height: 46,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              Container(
                                width: 18 + 24 * t,
                                height: 18 + 24 * t,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.accent.withValues(alpha: (1 - t) * 0.35),
                                  ),
                                ),
                              ),
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.accent,
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: widget.accent.withValues(alpha: 0.85),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // HUD ---------------------------------------------------------
                if (widget.showHud)
                  PositionedDirectional(
                    top: 10,
                    start: 16,
                    child: Text(
                      '${strings.rangeLabel} ${widget.maxRangeMeters.round()}M',
                      style: AppTheme.monoLabel(size: 9, color: RadarColors.textMuted, letterSpacing: 1.6),
                    ),
                  ),
                if (widget.showHud)
                  PositionedDirectional(
                    top: 10,
                    end: 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.isMock ? RadarColors.purple : RadarColors.green,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.isMock ? strings.demoBadge : strings.liveBadge,
                          style: AppTheme.monoLabel(
                            size: 9,
                            color: widget.isMock ? RadarColors.purple : RadarColors.green,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.centerLabel != null)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        widget.centerLabel!,
                        style: AppTheme.monoLabel(size: 8.5, color: RadarColors.textMuted, letterSpacing: 2),
                      ),
                    ),
                  ),

                // Tap layer ---------------------------------------------------
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: (TapUpDetails details) => _handleTap(details.localPosition, size),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNode(BleDevice device, int index, double side) {
    final double fraction = device.radarRadiusFraction(widget.maxRangeMeters);
    final double radiusPx = fraction * RadarViewport.nodeRadiusFactor * side / 2;
    final Offset center = Offset(side / 2, side / 2);
    final Offset position = center +
        Offset(math.cos(device.bearingRadians), math.sin(device.bearingRadians)) * radiusPx;
    final bool selected = device.id == widget.selectedId;
    final bool showLabel = selected || (index < 3 && fraction < 0.74);

    return AnimatedPositioned(
      key: ValueKey<String>('radar-node-${device.id}'),
      left: position.dx - _RadarNode.boxWidth / 2,
      top: position.dy - _RadarNode.boxHeight / 2,
      width: _RadarNode.boxWidth,
      height: _RadarNode.boxHeight,
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      child: _RadarNode(
        device: device,
        selected: selected,
        showLabel: showLabel,
        pulse: _nodePulse,
      ),
    );
  }
}

class _RadarNode extends StatelessWidget {
  const _RadarNode({
    required this.device,
    required this.selected,
    required this.showLabel,
    required this.pulse,
  });

  static const double boxWidth = 148;
  static const double boxHeight = 64;

  final BleDevice device;
  final bool selected;
  final bool showLabel;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final Color color = device.zone.color;
    final double size = switch (device.zone) {
      _ when selected => 16,
      _ when device.zone.isHot => 14,
      _ => 10,
    };

    return SizedBox(
      width: boxWidth,
      height: boxHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          if (selected)
            SizedBox(
              width: 48,
              height: 48,
              child: CustomPaint(painter: ReticlePainter(color: color)),
            ),
          AnimatedBuilder(
            animation: pulse,
            builder: (BuildContext context, Widget? _) {
              final double glow = selected ? 0.35 + 0.25 * pulse.value : 0.16;
              return Container(
                width: size + 10 + (selected ? 10 * pulse.value : 0),
                height: size + 10 + (selected ? 10 * pulse.value : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: glow * 0.35),
                ),
              );
            },
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 0.8),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: selected ? 0.95 : 0.6),
                  blurRadius: selected ? 18 : 10,
                  spreadRadius: selected ? 2 : 0,
                ),
              ],
            ),
          ),
          if (showLabel)
            Positioned(
              top: 34,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 132),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: RadarColors.background.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: color.withValues(alpha: selected ? 0.6 : 0.3)),
                ),
                child: Text(
                  device.hasName ? device.name : device.shortId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? color : RadarColors.textSecondary,
                    fontSize: 9,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
