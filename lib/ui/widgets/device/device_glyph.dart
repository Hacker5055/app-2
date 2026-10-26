import 'package:flutter/material.dart';

import '../../../domain/models/device_kind.dart';

IconData iconForKind(DeviceKind kind) => switch (kind) {
      DeviceKind.earbuds => Icons.headphones_rounded,
      DeviceKind.watch => Icons.watch_rounded,
      DeviceKind.tracker => Icons.sensors_rounded,
      DeviceKind.unknown => Icons.bluetooth_rounded,
    };

/// Rounded, glowing tile holding the device category icon.
class DeviceGlyph extends StatelessWidget {
  const DeviceGlyph({
    super.key,
    required this.kind,
    required this.color,
    this.size = 46,
    this.selected = false,
  });

  final DeviceKind kind;
  final Color color;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            color.withValues(alpha: selected ? 0.28 : 0.16),
            color.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: selected ? 0.6 : 0.3)),
        boxShadow: selected
            ? <BoxShadow>[BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 16)]
            : null,
      ),
      child: Icon(iconForKind(kind), size: size * 0.46, color: color),
    );
  }
}
