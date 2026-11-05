import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vnu_core/modules/tuition/data/tuition_api_diagnostics.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_premium_ui.dart';

/// Single artwork source for the small toolbar trigger and the full overlay.
class TuitionClearArtwork {
  static const String asset = 'assets/icons/animation_icons/clear.json';
  static const String package = 'vnu_core';
}

/// Change [TuitionClearMotionConfig.toolbarIconSize] to resize the AppBar
/// action, or [TuitionClearMotionConfig.overlayMaxSize] for the center Lottie.
abstract final class TuitionClearMotionConfig {
  static const double toolbarIconSize = 50;
  static const double overlayMaxSize = 360;
  static const double playbackSpeed = 1.75;

  static Duration faster(Duration original) => Duration(
    microseconds: math.max(1, (original.inMicroseconds / playbackSpeed).round()));
}

/// A tiny static FIRST FRAME of clear.json that acts as the AppBar button.
/// The full Lottie plays exactly once in [TuitionClearSessionOverlay] on tap
/// OR automatically after the third consecutive failed PAYABLE read.
class TuitionClearLottieIcon extends StatelessWidget {
  const TuitionClearLottieIcon({super.key, this.size = TuitionClearMotionConfig.toolbarIconSize});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: Transform.scale(
      scale: 1.12,
      child: Lottie.asset(
      TuitionClearArtwork.asset,
      key: const ValueKey<String>('tuition_clear_appbar_lottie'),
      package: TuitionClearArtwork.package,
      animate: false,
      repeat: false,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => Icon(
        Icons.cleaning_services_rounded,
        size: size,
        color: TuitionPalette.green,
      ),
      ),
    ),
  );
}

/// Full-screen visual for manual AND automatic ULIS session renewal.
///
/// The small broom flies from the app-bar corner to the center, where
/// assets/icons/animation_icons/clear.json plays EXACTLY ONCE. The scene
/// remains blurred until BOTH the network refresh and the Lottie playback
/// finish; then the artwork shrinks away. The overlay never creates QR or
/// payment requests. If clear.json is absent, a non-blocking icon animation
/// ensures the user is never trapped behind the overlay.
class TuitionClearSessionOverlay extends StatefulWidget {
  const TuitionClearSessionOverlay({super.key, required this.readyToDismiss,
    required this.onDismiss, this.maxVisualSize});

  final bool readyToDismiss;
  final VoidCallback onDismiss;
  /// Override only in the local animation lab; production uses config default.
  final double? maxVisualSize;

  @override
  State<TuitionClearSessionOverlay> createState() =>
      _TuitionClearSessionOverlayState();
}

class _TuitionClearSessionOverlayState extends State<TuitionClearSessionOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _arrival = AnimationController(
    vsync: this, duration: TuitionClearMotionConfig.faster(
      const Duration(milliseconds: 420)));
  late final AnimationController _oneLoop = AnimationController(vsync: this);
  late final AnimationController _departure = AnimationController(
    vsync: this, duration: TuitionClearMotionConfig.faster(
      const Duration(milliseconds: 340)));
  Timer? _fallbackTimer;
  bool _compositionReady = false;
  bool _compositionFailed = false;
  bool _started = false;
  bool _playedOnce = false;
  bool _departing = false;

  @override
  void initState() {
    super.initState();
    _oneLoop.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finishOneLoop();
    });
    _arrival.forward().whenComplete(() {
      if (!mounted) return;
      if (_compositionFailed) {
        _playFallback();
      } else {
        _beginOneLoopIfReady();
      }
      // In case clear.json was not copied into the bundle, let the user
      // recover rather than showing an infinite modal overlay.
      if (!_started) {
        _fallbackTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && !_started) _playFallback();
        });
      }
    });
  }

  void _beginOneLoopIfReady() {
    if (!mounted || !_arrival.isCompleted || !_compositionReady || _started) {
      return;
    }
    _fallbackTimer?.cancel();
    _started = true;
    _oneLoop.forward(from: 0);
  }

  void _playFallback() {
    if (_started || !mounted) return;
    _fallbackTimer?.cancel();
    _started = true;
    TuitionApiDiagnostics.instance.record('CLEAR_LOTTIE', 'FALLBACK');
    _fallbackTimer = Timer(TuitionClearMotionConfig.faster(
      const Duration(milliseconds: 1000)), () {
      if (mounted) _finishOneLoop();
    });
  }

  void _finishOneLoop() {
    if (_playedOnce || !mounted) return;
    _playedOnce = true;
    TuitionApiDiagnostics.instance.record('CLEAR_LOTTIE', 'ONE_LOOP_DONE');
    _tryDismiss();
  }

  void _tryDismiss() {
    if (!_playedOnce || !widget.readyToDismiss || _departing || !mounted) {
      return;
    }
    _departing = true;
    _departure.forward().whenComplete(() {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void didUpdateWidget(covariant TuitionClearSessionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.readyToDismiss && widget.readyToDismiss) {
      _tryDismiss();
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _arrival.dispose();
    _oneLoop.dispose();
    _departure.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final visualSize = math.min(screen.width * 0.92,
      widget.maxVisualSize ?? TuitionClearMotionConfig.overlayMaxSize);
    return Semantics(
      // Accessibility label only; the student sees NO session text/banner.
      label: 'Làm mới dữ liệu học phí',
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_arrival, _departure]),
        builder: (context, _) {
          final enter = Curves.easeOutCubic.transform(_arrival.value);
          final exit = Curves.easeInCubic.transform(_departure.value);
          final backdrop = (enter * (1 - exit)).clamp(0.0, 1.0);
          final start = Offset(screen.width - 35, top + 26);
          final center = Offset(screen.width / 2, screen.height * 0.45);
          final point = Offset.lerp(start, center, enter)!;
          final scale = lerpDouble(0.16, 1, enter)! * (1 - exit * 0.96);
          return Stack(children: <Widget>[
            Positioned.fill(child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.5 * backdrop,
                sigmaY: 5.5 * backdrop),
              child: ColoredBox(color: Colors.white.withValues(
                alpha: 0.55 * backdrop)),
            )),
            Positioned(
              left: point.dx - visualSize / 2,
              top: point.dy - visualSize / 2,
              width: visualSize,
              height: visualSize,
              child: Opacity(
                opacity: (1 - exit).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: RepaintBoundary(child: Lottie.asset(
                    TuitionClearArtwork.asset,
                    package: TuitionClearArtwork.package,
                    key: const ValueKey<String>('tuition_clear_json'),
                    controller: _oneLoop,
                    repeat: false,
                    animate: false,
                    fit: BoxFit.contain,
                    onLoaded: (composition) {
                      if (_compositionReady || !mounted || _started) return;
                      if (composition.duration <= Duration.zero) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _arrival.isCompleted) _playFallback();
                        });
                        return;
                      }
                      _compositionReady = true;
                      _oneLoop.duration = TuitionClearMotionConfig.faster(
                        composition.duration);
                      TuitionApiDiagnostics.instance.record(
                        'CLEAR_LOTTIE', 'LOADED');
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _beginOneLoopIfReady();
                      });
                    },
                    errorBuilder: (context, error, stack) {
                      if (!_compositionFailed) {
                        _compositionFailed = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _arrival.isCompleted) {
                            _playFallback();
                          }
                        });
                      }
                      return const Icon(Icons.cleaning_services_rounded,
                        size: 88, color: TuitionPalette.green);
                    },
                  )),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
