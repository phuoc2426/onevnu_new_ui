import 'package:flutter/material.dart';

/// Floating, non-interactive, horizontally scrolling login eligibility notice.
/// It should ONLY be used as a Positioned child of the login page's Stack.
class OneVnuLoginNoticeMarquee extends StatefulWidget {
  const OneVnuLoginNoticeMarquee({super.key});

  static const String message =
      'Ứng dụng hiện chỉ dành cho sinh viên đại học và chưa hỗ trợ Trường Quốc tế.';

  @override
  State<OneVnuLoginNoticeMarquee> createState() =>
      _OneVnuLoginNoticeMarqueeState();
}

class _OneVnuLoginNoticeMarqueeState extends State<OneVnuLoginNoticeMarquee>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  bool _foreground = true;
  bool _reduceMotion = false;
  static const TextStyle _style = TextStyle(
    color: Color(0xFF86540F), fontSize: 12.3,
    fontWeight: FontWeight.w700, height: 1.15,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this, duration: const Duration(seconds: 12));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    if (_foreground && !_reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xF0FFF7E7),
          border: Border.symmetric(
            horizontal: BorderSide(color: const Color(0xFFEFD9A7)
                .withValues(alpha: 0.72)),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final painter = TextPainter(
              text: const TextSpan(
                text: OneVnuLoginNoticeMarquee.message, style: _style),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();
            final textWidth = painter.width;
            painter.dispose();
            if (_reduceMotion) {
              return Center(child: Text(
                OneVnuLoginNoticeMarquee.message,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: _style,
              ));
            }
            return ClipRect(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final x = width - (width + textWidth + 28) * _controller.value;
                  return Stack(children: <Widget>[
                    Positioned(
                      top: 7, left: x,
                      child: Text(
                        OneVnuLoginNoticeMarquee.message,
                        maxLines: 1, softWrap: false,
                        style: _style,
                      ),
                    ),
                  ]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
