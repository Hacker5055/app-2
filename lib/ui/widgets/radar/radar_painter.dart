import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/radar_colors.dart';

void _paintMonoText(
  Canvas canvas,
  String text,
  Offset position, {
  required Color color,
  double fontSize = 9,
  bool centered = true,
  FontWeight weight = FontWeight.w600,
  double letterSpacing = 1.2,
  List<Shadow>? shadows,
}) {
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
        shadows: shadows,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final Offset offset = centered ? position - Offset(painter.width / 2, painter.height / 2) : position;
  painter.paint(canvas, offset);
}

void _drawDashedLine(
  Canvas canvas,
  Offset start,
  Offset end,
  Paint paint, {
  double dash = 5,
  double gap = 6,
}) {
  final double total = (end - start).distance;
  if (total <= 0 || !total.isFinite) return;
  final Offset direction = (end - start) / total;
  double covered = 0;
  while (covered < total) {
    final double segment = math.min(dash, total - covered);
    canvas.drawLine(start + direction * covered, start + direction * (covered + segment), paint);
    covered += dash + gap;
  }
}

/// Static radar face: gradient disc, cross-hairs, concentric ranges, ticks,
/// cardinal markers and HUD corner brackets.
class RadarGridPainter extends CustomPainter {
  const RadarGridPainter({
    this.ringCount = 4,
    this.maxRangeMeters = 20,
    this.accent = RadarColors.cyan,
    this.showLabels = true,
    this.radiusFactor = 0.94,
  });

  final int ringCount;
  final double maxRangeMeters;
  final Color accent;
  final bool showLabels;
  final double radiusFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2 * radiusFactor;

    // Disc backdrop -----------------------------------------------------------
    final Rect disc = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFF0C1728), Color(0xFF080C15), Color(0xFF05070C)],
          stops: <double>[0, 0.65, 1],
        ).createShader(disc),
    );

    // Cross-hairs -------------------------------------------------------------
    final Paint hair = Paint()
      ..color = RadarColors.radarGrid.withValues(alpha: 0.75)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), hair);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), hair);

    final Paint diagonal = Paint()
      ..color = RadarColors.radarGrid.withValues(alpha: 0.35)
      ..strokeWidth = 0.7;
    for (final double angle in <double>[math.pi / 4, -math.pi / 4]) {
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * -radius,
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        diagonal,
      );
    }

    // Spokes ------------------------------------------------------------------
    final Paint spoke = Paint()
      ..color = RadarColors.radarGrid.withValues(alpha: 0.5)
      ..strokeWidth = 0.7;
    for (int i = 0; i < 12; i++) {
      final double angle = i * math.pi / 6;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.26),
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        spoke,
      );
    }

    // Range rings -------------------------------------------------------------
    for (int i = 1; i <= ringCount; i++) {
      final double ringRadius = radius * i / ringCount;
      final bool outer = i == ringCount;
      final Paint ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outer ? 1.6 : 1.0
        ..color = outer
            ? accent.withValues(alpha: 0.42)
            : RadarColors.radarGrid.withValues(alpha: 0.85);
      canvas.drawCircle(center, ringRadius, ringPaint);

      if (outer) {
        canvas.drawCircle(
          center,
          ringRadius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = accent.withValues(alpha: 0.10)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }

      if (showLabels) {
        final double meters = maxRangeMeters * i / ringCount;
        final Offset labelPosition =
            center + Offset(math.cos(-math.pi / 4), math.sin(-math.pi / 4)) * ringRadius;
        _paintMonoText(
          canvas,
          '${meters.round()} m',
          labelPosition,
          color: RadarColors.textMuted.withValues(alpha: 0.9),
          fontSize: 8.5,
          shadows: const <Shadow>[Shadow(color: Color(0xFF05070C), blurRadius: 4)],
        );
      }
    }

    // Ticks -------------------------------------------------------------------
    for (int i = 0; i < 72; i++) {
      final double angle = i * math.pi / 36;
      final bool major = i % 6 == 0;
      final Offset direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius + 3),
        center + direction * (radius + (major ? 11 : 6)),
        Paint()
          ..color = accent.withValues(alpha: major ? 0.55 : 0.22)
          ..strokeWidth = major ? 1.4 : 0.8,
      );
    }

    // Cardinal markers --------------------------------------------------------
    const List<String> cardinals = <String>['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final double angle = -math.pi / 2 + i * math.pi / 2;
      final Offset position = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 17);
      _paintMonoText(
        canvas,
        cardinals[i],
        position,
        color: i == 0 ? accent.withValues(alpha: 0.9) : RadarColors.textMuted.withValues(alpha: 0.65),
        fontSize: 10,
        weight: FontWeight.w700,
        shadows: const <Shadow>[Shadow(color: Color(0xFF05070C), blurRadius: 4)],
      );
    }

    // Centre reticle ----------------------------------------------------------
    final Paint centre = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    canvas.drawLine(center - const Offset(7, 0), center + const Offset(7, 0), centre);
    canvas.drawLine(center - const Offset(0, 7), center + const Offset(0, 7), centre);

    // HUD corner brackets -----------------------------------------------------
    final Paint bracket = Paint()
      ..color = accent.withValues(alpha: 0.30)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const double inset = 6;
    const double arm = 16;
    final Rect box = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
    final Path corners = Path()
      ..moveTo(box.left, box.top + arm)
      ..lineTo(box.left, box.top)
      ..lineTo(box.left + arm, box.top)
      ..moveTo(box.right - arm, box.top)
      ..lineTo(box.right, box.top)
      ..lineTo(box.right, box.top + arm)
      ..moveTo(box.right, box.bottom - arm)
      ..lineTo(box.right, box.bottom)
      ..lineTo(box.right - arm, box.bottom)
      ..moveTo(box.left + arm, box.bottom)
      ..lineTo(box.left, box.bottom)
      ..lineTo(box.left, box.bottom - arm);
    canvas.drawPath(corners, bracket);
  }

  @override
  bool shouldRepaint(covariant RadarGridPainter oldDelegate) =>
      oldDelegate.ringCount != ringCount ||
      oldDelegate.maxRangeMeters != maxRangeMeters ||
      oldDelegate.accent != accent ||
      oldDelegate.showLabels != showLabels ||
      oldDelegate.radiusFactor != radiusFactor;
}

/// The rotating sweep: a fading wedge plus a bright leading edge.
class RadarSweepPainter extends CustomPainter {
  const RadarSweepPainter({
    required this.angle,
    required this.color,
    this.radiusFactor = 0.94,
    this.tailDegrees = 78,
  });

  final double angle;
  final Color color;
  final double radiusFactor;
  final double tailDegrees;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2 * radiusFactor;
    final double tail = tailDegrees * math.pi / 180;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final Paint wedge = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2 - tail,
        endAngle: -math.pi / 2,
        colors: <Color>[
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.02),
          color.withValues(alpha: 0.11),
          color.withValues(alpha: 0.30),
        ],
        stops: const <double>[0, 0.4, 0.78, 1],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    canvas.drawCircle(Offset.zero, radius, wedge);

    // Leading edge.
    final Paint leading = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: <Color>[color.withValues(alpha: 0.05), color.withValues(alpha: 0.85)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius))
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset.zero, Offset(0, -radius), leading);

    // Tip flare.
    canvas.drawCircle(
      Offset(0, -radius),
      6,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RadarSweepPainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.color != color;
}

/// Expanding sonar rings.
class RadarPulsePainter extends CustomPainter {
  const RadarPulsePainter({
    required this.progress,
    required this.color,
    required this.intensity,
    this.radiusFactor = 0.94,
    this.ringCount = 3,
  });

  final double progress;
  final Color color;
  final double intensity;
  final double radiusFactor;
  final int ringCount;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2 * radiusFactor;
    final double strength = intensity.clamp(0.0, 1.0).toDouble();

    for (int i = 0; i < ringCount; i++) {
      final double t = (progress + i / ringCount) % 1.0;
      final double ringRadius = radius * (0.12 + 0.88 * t);
      final double alpha = (1 - t) * (1 - t) * (0.10 + 0.24 * strength);
      if (alpha <= 0.002) continue;
      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color.withValues(alpha: alpha),
      );
    }

    // Central bloom.
    canvas.drawCircle(
      center,
      radius * 0.24,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[color.withValues(alpha: 0.10 + 0.12 * strength), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.24)),
    );
  }

  @override
  bool shouldRepaint(covariant RadarPulsePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.color != color;
}

/// Dashed bearing ray + arc highlight for the device being tracked.
class RadarBearingPainter extends CustomPainter {
  const RadarBearingPainter({
    required this.bearing,
    required this.color,
    required this.radiusFraction,
    required this.radiusFactor,
  });

  final double bearing;
  final Color color;
  final double radiusFraction;
  final double radiusFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2 * radiusFactor;
    final double nodeRadius = radius * radiusFraction.clamp(0.0, 1.0);
    final Offset direction = Offset(math.cos(bearing), math.sin(bearing));

    final Paint ray = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    _drawDashedLine(canvas, center + direction * 22, center + direction * (nodeRadius - 14), ray, dash: 4, gap: 7);

    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: nodeRadius),
      bearing - 0.16,
      0.32,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant RadarBearingPainter oldDelegate) =>
      oldDelegate.bearing != bearing ||
      oldDelegate.radiusFraction != radiusFraction ||
      oldDelegate.color != color;
}

/// Targeting brackets drawn around the selected node.
class ReticlePainter extends CustomPainter {
  const ReticlePainter({required this.color, this.size = 44, this.progress = 0});

  final Color color;
  final double size;
  final double progress;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final Offset center = canvasSize.center(Offset.zero);
    final double half = size / 2;
    final double arm = size * 0.24;
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..moveTo(center.dx - half, center.dy - half + arm)
      ..lineTo(center.dx - half, center.dy - half)
      ..lineTo(center.dx - half + arm, center.dy - half)
      ..moveTo(center.dx + half - arm, center.dy - half)
      ..lineTo(center.dx + half, center.dy - half)
      ..lineTo(center.dx + half, center.dy - half + arm)
      ..moveTo(center.dx + half, center.dy + half - arm)
      ..lineTo(center.dx + half, center.dy + half)
      ..lineTo(center.dx + half - arm, center.dy + half)
      ..moveTo(center.dx - half + arm, center.dy + half)
      ..lineTo(center.dx - half, center.dy + half)
      ..lineTo(center.dx - half, center.dy + half - arm);
    canvas.drawPath(path, paint);

    canvas.drawCircle(
      center,
      half - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = color.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant ReticlePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.size != size;
}
