import 'package:flutter/material.dart';

import '../../../core/theme/radar_colors.dart';

/// Deep-space backdrop: vertical gradient, a cyan bloom at the top and a very
/// faint dot grid that reads as a radar plotting table.
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.showGrid = true,
    this.glowColor = RadarColors.cyan,
  });

  final Widget child;
  final bool showGrid;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF0A0D17), RadarColors.background, Color(0xFF05060A)],
          stops: <double>[0, 0.45, 1],
        ),
      ),
      child: Stack(
        children: <Widget>[
          if (showGrid)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _DotGridPainter(glowColor: glowColor)),
              ),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.glowColor});

  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Top bloom.
    final Paint bloom = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -1.05),
        radius: 1.1,
        colors: <Color>[glowColor.withValues(alpha: 0.12), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bloom);

    final Paint dot = Paint()..color = RadarColors.cyan.withValues(alpha: 0.045);
    const double spacing = 30;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, dot);
      }
    }

    // Corner vignette lines.
    final Paint line = Paint()
      ..color = RadarColors.border.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height * 0.18), Offset(size.width * 0.18, 0), line);
    canvas.drawLine(
      Offset(size.width, size.height * 0.82),
      Offset(size.width * 0.82, size.height),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => oldDelegate.glowColor != glowColor;
}
