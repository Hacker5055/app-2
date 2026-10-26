import 'package:flutter/material.dart';

import '../../../core/theme/radar_colors.dart';

/// Smoothed RSSI history rendered as a neon sparkline.
class RssiSparkline extends StatelessWidget {
  const RssiSparkline({
    super.key,
    required this.samples,
    this.color = RadarColors.cyan,
    this.height = 64,
    this.minRssi = -100,
    this.maxRssi = -32,
  });

  final List<double> samples;
  final Color color;
  final double height;
  final double minRssi;
  final double maxRssi;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SparklinePainter(
            samples: samples,
            color: color,
            minRssi: minRssi,
            maxRssi: maxRssi,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.samples,
    required this.color,
    required this.minRssi,
    required this.maxRssi,
  });

  final List<double> samples;
  final Color color;
  final double minRssi;
  final double maxRssi;

  double _normalize(double rssi) {
    final double span = maxRssi - minRssi;
    if (span <= 0) return 0.5;
    return ((rssi - minRssi) / span).clamp(0.0, 1.0).toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Grid.
    final Paint grid = Paint()
      ..color = RadarColors.border.withValues(alpha: 0.55)
      ..strokeWidth = 0.7;
    for (int i = 0; i <= 2; i++) {
      final double y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (samples.isEmpty) {
      final Paint dashed = Paint()
        ..color = RadarColors.textMuted.withValues(alpha: 0.35)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        dashed,
      );
      return;
    }

    final List<double> points = samples.length == 1
        ? <double>[samples.first, samples.first]
        : samples;

    final Path line = Path();
    final double stepX = size.width / (points.length - 1);
    for (int i = 0; i < points.length; i++) {
      final double x = i * stepX;
      final double y = size.height - _normalize(points[i]) * (size.height - 4) - 2;
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }

    // Area fill.
    final Path area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );

    // Glow + stroke.
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    // Latest sample dot.
    final double lastY = size.height - _normalize(points.last) * (size.height - 4) - 2;
    canvas.drawCircle(
      Offset(size.width - 1, lastY),
      6,
      Paint()..color = color.withValues(alpha: 0.28),
    );
    canvas.drawCircle(Offset(size.width - 1, lastY), 2.4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.samples.length != samples.length ||
      (samples.isNotEmpty &&
          (oldDelegate.samples.isEmpty || oldDelegate.samples.last != samples.last)) ||
      oldDelegate.color != color;
}
