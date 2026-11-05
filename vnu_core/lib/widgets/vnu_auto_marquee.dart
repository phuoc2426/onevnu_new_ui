import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Label mot dong; chi chuyen dong neu thuc su dai hon vung hien thi.
/// Di chuyen trai, dung, chuyen ve phai, dung va lap lai.
/// Khong dung marquee khi he dieu hanh yeu cau giam animation.
class VnuAutoMarquee extends StatefulWidget {
  const VnuAutoMarquee({
    super.key,
    required this.text,
    required this.style,
    this.alignment = Alignment.center,
    this.edgePadding = 12.0,
  });

  final String text;
  final TextStyle style;
  final Alignment alignment;
  final double edgePadding;
  @override
  State<VnuAutoMarquee> createState() => _VnuAutoMarqueeState();
}

class _VnuAutoMarqueeState extends State<VnuAutoMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _motion;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    );
    _motion = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 16),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 34,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 16),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 34,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncMotion(bool shouldAnimate) {
    if (_running == shouldAnimate) return;
    _running = shouldAnimate;
    if (shouldAnimate) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: LayoutBuilder(builder: (context, box) {
          if (!box.hasBoundedWidth || box.maxWidth <= 0) {
            return Text(widget.text, maxLines: 1,
                overflow: TextOverflow.ellipsis, style: widget.style);
          }

          final direction = Directionality.of(context);
          final painter = TextPainter(
            text: TextSpan(text: widget.text, style: widget.style),
            maxLines: 1,
            textDirection: direction,
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: double.infinity);
          final textWidth = painter.width;
          final textHeight = painter.height;
          painter.dispose();
          final contentWidth = textWidth + widget.edgePadding * 2;

          final overflow = math.max(
            0.0,
            contentWidth - box.maxWidth,
          );
          final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
          final moving = overflow > 1.0 && !reduceMotion;
          if (moving != _running) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _syncMotion(moving);
            });
          }

          if (overflow <= 1) {
            return Align(
              alignment: widget.alignment,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.edgePadding,
                ),
                child: Text(
                  widget.text,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: widget.style,
                ),
              ),
            );
          }

          final text = Text(widget.text, maxLines: 1, softWrap: false,
              overflow: TextOverflow.visible, style: widget.style);
          return ClipRect(
            child: SizedBox(
              width: box.maxWidth,
              height: textHeight + 2,
              child: AnimatedBuilder(
                animation: _motion,
                builder: (context, _) => Stack(children: [
                  Positioned(
                    top: 0,
                    left: moving ? -overflow * _motion.value : 0,
                    width: contentWidth + 1,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.edgePadding,
                      ),
                      child: text,
                    ),
                  ),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }
}
