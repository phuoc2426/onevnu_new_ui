import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Toggle quan tam dung cung semantics voi nut like cua web demo:
/// - bat: tim do + burst/bubble/sparkles;
/// - tat: tim thu nho + ripple/sparkles thu vao;
/// Ca hai chieu deu co animation, khong doi thanh nut "Dang theo doi".
class PahtHeartToggle extends StatefulWidget {
  final bool active;
  final int count;
  final bool busy;
  final VoidCallback? onTap;
  final double iconSize;

  const PahtHeartToggle({
    super.key,
    required this.active,
    required this.count,
    required this.busy,
    this.onTap,
    this.iconSize = 19,
  });

  @override
  State<PahtHeartToggle> createState() => _PahtHeartToggleState();
}

class _PahtHeartToggleState extends State<PahtHeartToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _turningOn = false;

  @override
  void initState() {
    super.initState();
    _turningOn = widget.active;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
  }

  @override
  void didUpdateWidget(covariant PahtHeartToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _turningOn = widget.active;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color liked = Color(0xFFE2264D);
    const Color idle = Color(0xFF8B9690);
    final Color heartColor = widget.active ? liked : idle;
    final double box = widget.iconSize + 6;

    return Semantics(
      button: true,
      toggled: widget.active,
      label: widget.active ? 'Bỏ quan tâm' : 'Quan tâm phản ánh',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: widget.busy ? null : widget.onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double t = Curves.easeOutCubic.transform(_controller.value);
                final double wave = math.sin(math.pi * t);
                final double scale = _turningOn ? 1 + .34 * wave : 1 - .22 * wave;
                final double rotation = _turningOn ? 0 : .11 * wave;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: box,
                      height: box,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          IgnorePointer(
                            child: CustomPaint(
                              size: Size.square(box),
                              painter: _HeartBurstPainter(
                                progress: t,
                                color: _turningOn ? liked : const Color(0xFF93A19A),
                                outward: _turningOn,
                              ),
                            ),
                          ),
                          Transform.rotate(
                            angle: rotation,
                            child: Transform.scale(
                              scale: scale,
                              child: Icon(
                                widget.active
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: widget.iconSize,
                                color: heartColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Text(
                        '${widget.count}',
                        key: ValueKey<int>(widget.count),
                        style: TextStyle(
                          fontSize: widget.iconSize <= 17 ? 10.4 : (widget.iconSize <= 19 ? 11.0 : 12.3),
                          color: widget.active ? liked : const Color(0xFF7A867F),
                          fontWeight: widget.active ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.busy) ...<Widget>[
                      const SizedBox(width: 4),
                      const SizedBox(
                        width: 9,
                        height: 9,
                        child: CircularProgressIndicator(strokeWidth: 1.6),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HeartBurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool outward;

  const _HeartBurstPainter({
    required this.progress,
    required this.color,
    required this.outward,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double p = Curves.easeOut.transform(progress);
    final double opacity = (1 - progress).clamp(0.0, 1.0).toDouble();
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * (1 - progress) + .5
      ..color = color.withOpacity(.48 * opacity);
    final double ringRadius = outward ? 4 + 10 * p : 13 - 8 * p;
    canvas.drawCircle(center, ringRadius, ring);

    const List<Color> sparkleColors = <Color>[
      Color(0xFFFF8080),
      Color(0xFFFFD95A),
      Color(0xFFA4E56D),
      Color(0xFF5DDDBA),
      Color(0xFF62B5F6),
      Color(0xFF9B7CF6),
      Color(0xFFE779D5),
      Color(0xFFFF8A65),
    ];
    for (int i = 0; i < sparkleColors.length; i++) {
      final double angle = (math.pi * 2 * i / sparkleColors.length) - math.pi / 2;
      final double radius = outward ? 6 + 11 * p : 17 - 10 * p;
      final Offset point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final Paint dot = Paint()
        ..color = (outward ? sparkleColors[i] : color).withOpacity(.78 * opacity);
      canvas.drawCircle(point, 1.25 + .55 * (1 - progress), dot);
    }
  }

  @override
  bool shouldRepaint(covariant _HeartBurstPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.outward != outward;
  }
}
