import 'package:flutter/material.dart';

/// A live indicator: a solid dot wrapped in an expanding halo.
class PulseDot extends StatefulWidget {
  const PulseDot({
    super.key,
    this.color = const Color(0xFF2BFFB0),
    this.size = 7,
    this.active = true,
    this.haloScale = 2.4,
  });

  final Color color;
  final double size;
  final bool active;
  final double haloScale;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * widget.haloScale,
      height: widget.size * widget.haloScale,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double t = widget.active ? _controller.value : 0;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Opacity(
                opacity: widget.active ? (1 - t) * 0.55 : 0.2,
                child: Container(
                  width: widget.size * (1 + t * (widget.haloScale - 1)),
                  height: widget.size * (1 + t * (widget.haloScale - 1)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.28),
                  ),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: widget.color.withValues(alpha: 0.7), blurRadius: 8),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
