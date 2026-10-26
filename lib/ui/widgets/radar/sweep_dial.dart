import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/radar_colors.dart';

/// Compass rose used by the 360° sweep assistant.
///
/// The tick ring is fixed, the cardinal rose rotates against the live heading
/// and the arc on the outside fills as the user covers the circle.
class SweepDial extends StatelessWidget {
  const SweepDial({
    super.key,
    required this.heading,
    required this.progress,
    this.bestHeading,
    this.accent = RadarColors.cyan,
    this.size = 260,
    this.child,
  });

  final double heading;
  final double progress;
  final double? bestHeading;
  final Color accent;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: Size.square(size),
            painter: SweepDialPainter(
              heading: heading,
              progress: progress,
              bestHeading: bestHeading,
              accent: accent,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class SweepDialPainter extends CustomPainter {
  const SweepDialPainter({
    required this.heading,
    required this.progress,
    this.bestHeading,
    this.accent = RadarColors.cyan,
  });

  final double heading;
  final double progress;
  final double? bestHeading;
  final Color accent;

  void _text(
    Canvas canvas,
    String value,
    Offset position, {
    required Color color,
    double fontSize = 10,
    FontWeight weight = FontWeight.w600,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2 - 14;
    final double headingRadians = heading * math.pi / 180;
    final double progressClamped = progress.clamp(0.0, 1.0).toDouble();

    // Face --------------------------------------------------------------------
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFF0E1A2C), Color(0xFF070B13)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = RadarColors.radarGrid,
    );

    // Ticks -------------------------------------------------------------------
    for (int i = 0; i < 72; i++) {
      final double angle = i * 5 * math.pi / 180;
      final bool major = i % 6 == 0;
      final Offset direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius - (major ? 12 : 6)),
        center + direction * (radius - 1),
        Paint()
          ..color = major
              ? accent.withValues(alpha: 0.45)
              : RadarColors.textMuted.withValues(alpha: 0.22)
          ..strokeWidth = major ? 1.4 : 0.8,
      );
    }

    // Cardinal rose (rotates opposite to the phone heading) ---------------------
    const List<String> labels = <String>['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final double angle = -math.pi / 2 + i * math.pi / 2 - headingRadians;
      final Offset position = center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.74);
      _text(
        canvas,
        labels[i],
        position,
        color: i == 0 ? accent : RadarColors.textSecondary.withValues(alpha: 0.75),
        fontSize: i == 0 ? 14 : 12,
        weight: FontWeight.w700,
      );
    }

    // Inter-cardinal dots ------------------------------------------------------
    for (int i = 0; i < 4; i++) {
      final double angle = -math.pi / 2 + math.pi / 4 + i * math.pi / 2 - headingRadians;
      final Offset position = center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.74);
      canvas.drawCircle(position, 2, Paint()..color = RadarColors.textMuted.withValues(alpha: 0.5));
    }

    // Progress arc -------------------------------------------------------------
    if (progressClamped > 0.001) {
      final Rect arcRect = Rect.fromCircle(center: center, radius: radius + 6);
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        progressClamped * 2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: -math.pi / 2 + 2 * math.pi,
            colors: <Color>[accent, RadarColors.purple, accent],
          ).createShader(arcRect),
      );
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        progressClamped * 2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..color = accent.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }

    // Best heading marker ------------------------------------------------------
    final double? best = bestHeading;
    if (best != null) {
      final double angle = -math.pi / 2 + best * math.pi / 180;
      final Offset direction = Offset(math.cos(angle), math.sin(angle));
      final Offset marker = center + direction * (radius * 0.52);
      canvas.drawLine(
        center + direction * (radius * 0.2),
        marker,
        Paint()
          ..color = RadarColors.green.withValues(alpha: 0.55)
          ..strokeWidth = 1.4,
      );
      canvas.drawCircle(
        marker,
        5,
        Paint()
          ..color = RadarColors.green
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(marker, 3, Paint()..color = RadarColors.green);
      _text(
        canvas,
        '${best.round()}°',
        center + direction * (radius * 0.42),
        color: RadarColors.green,
        fontSize: 9,
      );
    }

    // Fixed pointer at the top ------------------------------------------------
    final Path pointer = Path()
      ..moveTo(center.dx, center.dy - radius - 12)
      ..lineTo(center.dx - 6, center.dy - radius + 2)
      ..lineTo(center.dx + 6, center.dy - radius + 2)
      ..close();
    canvas.drawPath(
      pointer,
      Paint()
        ..color = accent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(pointer, Paint()..color = accent);

    // Centre plate ------------------------------------------------------------
    canvas.drawCircle(center, radius * 0.42, Paint()..color = RadarColors.background.withValues(alpha: 0.82));
    canvas.drawCircle(
      center,
      radius * 0.42,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = accent.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant SweepDialPainter oldDelegate) =>
      oldDelegate.heading != heading ||
      oldDelegate.progress != progress ||
      oldDelegate.bestHeading != bestHeading ||
      oldDelegate.accent != accent;
}

/// Small helper used by the sheet to show a labelled figure.
class DialFigure extends StatelessWidget {
  const DialFigure({super.key, required this.value, required this.label, this.color = RadarColors.textPrimary});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(value, style: AppTheme.mono.copyWith(fontSize: 20, color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.monoLabel(size: 8, color: RadarColors.textMuted, letterSpacing: 1.4)),
      ],
    );
  }
}
