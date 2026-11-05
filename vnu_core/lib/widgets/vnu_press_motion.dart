import 'dart:async';

import 'package:flutter/material.dart';

/// Hieu ung nhan nhe chi scale, khong ripple/tap highlight/doi mau.
/// [onTap] la tuy chon: khi null, widget con tu xu ly su kien nhan.
class VnuPressMotion extends StatefulWidget {
  const VnuPressMotion({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.pressedScale = 0.975,
    this.pressDuration = const Duration(milliseconds: 100),
    this.releaseDuration = const Duration(milliseconds: 240),
    this.releaseDelay = const Duration(milliseconds: 55),
    this.releaseCurve = Curves.easeOutBack,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double pressedScale;
  /// Faster downward feedback, then a gentle spring-like release.
  final Duration pressDuration;
  final Duration releaseDuration;
  final Duration releaseDelay;
  final Curve releaseCurve;

  @override
  State<VnuPressMotion> createState() => _VnuPressMotionState();
}

class _VnuPressMotionState extends State<VnuPressMotion> {
  bool _pressed = false;
  Timer? _releaseTimer;

  @override
  void dispose() {
    _releaseTimer?.cancel();
    super.dispose();
  }

  void _press() {
    _releaseTimer?.cancel();
    if (widget.enabled && !_pressed) setState(() => _pressed = true);
  }

  void _release() {
    _releaseTimer?.cancel();
    _releaseTimer = Timer(widget.releaseDelay, () {
      if (mounted && _pressed) setState(() => _pressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final targetScale = _pressed && widget.enabled && !reduceMotion
        ? widget.pressedScale
        : 1.0;
    final surface = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.enabled ? (_) => _press() : null,
      onPointerUp: widget.enabled ? (_) => _release() : null,
      onPointerCancel: widget.enabled ? (_) => _release() : null,
      child: AnimatedScale(
        scale: targetScale,
        duration: reduceMotion ? Duration.zero
            : _pressed ? widget.pressDuration : widget.releaseDuration,
        curve: _pressed ? Curves.easeOutCubic : widget.releaseCurve,
        child: widget.child,
      ),
    );

    if (widget.onTap == null) return surface;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        child: surface,
      ),
    );
  }
}
