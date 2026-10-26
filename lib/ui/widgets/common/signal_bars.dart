import 'package:flutter/material.dart';

import '../../../core/theme/radar_colors.dart';

/// Four-bar signal meter that animates between readings.
class SignalBars extends StatelessWidget {
  const SignalBars({
    super.key,
    required this.rssi,
    this.color = RadarColors.cyan,
    this.height = 18,
    this.barWidth = 3.5,
    this.gap = 2.5,
    this.minBars = 1,
  });

  final double rssi;
  final Color color;
  final double height;
  final double barWidth;
  final double gap;
  final int minBars;

  static int barsForRssi(double rssi) {
    if (rssi >= -55) return 4;
    if (rssi >= -67) return 3;
    if (rssi >= -78) return 2;
    if (rssi >= -88) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final int active = barsForRssi(rssi).clamp(minBars, 4);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(4, (int index) {
          final bool on = index < active;
          final double barHeight = height * (0.42 + index * 0.19);
          return Padding(
            padding: EdgeInsetsDirectional.only(end: index == 3 ? 0 : gap),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: on ? color : RadarColors.border,
                borderRadius: BorderRadius.circular(2),
                boxShadow: on
                    ? <BoxShadow>[BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 6)]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
