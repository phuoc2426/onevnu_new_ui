import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/app_update_local_assets.dart';
import 'package:lottie/lottie.dart';
import 'package:vnu_core/services/app_update_coordinator.dart';
import 'package:vnu_core/widgets/app_update_store_dialog.dart';

/// UI-only debug settings. No debug override can force an update in Release.
///
/// Debug: the floating Lottie always exists and tapping it always opens the
/// two-store chooser (even with an up-to-date build or a failed config check).
/// An automatic one-time chooser in Debug uses the EXACT production UI.
class AppUpdateFloatingConfig {
  const AppUpdateFloatingConfig._();

  static const bool debugAlwaysShow = bool.fromEnvironment(
    'ONEVNU_UPDATE_DEBUG_ALWAYS_SHOW', defaultValue: true);
  static const bool debugAutoDialog = bool.fromEnvironment(
    'ONEVNU_UPDATE_DEBUG_AUTO_DIALOG', defaultValue: true);
  static const bool debugPreviewPulse = bool.fromEnvironment(
    'ONEVNU_UPDATE_DEBUG_PREVIEW_PULSE', defaultValue: true);
  static const int pulseMilliseconds = int.fromEnvironment(
    'ONEVNU_UPDATE_PULSE_MS', defaultValue: 420);
}

/// Draggable, edge-docking FAB. Positioned.fill + inner Stack mean that it
/// never participates in the parent Column/ScrollView measurements. The inner
/// Stack only hit-tests the actual 54dp FAB; it does not block taps elsewhere.
/// Positions persist across OneVNU Home/Login/Applicant screens in memory.
class AppUpdateFloatingBadge extends StatefulWidget {
  const AppUpdateFloatingBadge({
    super.key,
    this.topOffset = 12,
    this.rightOffset = 14,
    this.active = true,
  });

  final double topOffset;
  final double rightOffset;
  final bool active;

  @override
  State<AppUpdateFloatingBadge> createState() => _AppUpdateFloatingBadgeState();
}

class _AppUpdateFloatingBadgeState extends State<AppUpdateFloatingBadge>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const double _diameter = 54;
  static const double _edge = 8;

  static Offset? _savedNormalizedPosition;
  static bool _autoDialogShown = false;
  static bool _autoDialogScheduled = false;

  late final AnimationController _pulse;
  Offset? _localOffset;
  bool _dragging = false;
  bool _foreground = true;
  bool _reduceMotion = false;

  AppUpdateGateSnapshot get _snapshot =>
      AppUpdateCoordinator.instance.notifier.value;

  bool get _hasUpdate {
    final s = _snapshot;
    return s.mode != AppUpdateGateMode.checking &&
        (s.evaluation?.isOptional == true || s.evaluation?.isForce == true);
  }

  bool get _debugPreviewOnly =>
      kDebugMode && AppUpdateFloatingConfig.debugAlwaysShow && !_hasUpdate;
  bool get _visible => widget.active && (_hasUpdate || _debugPreviewOnly);
  bool get _animate => _visible && _foreground && !_reduceMotion &&
      (_hasUpdate || (kDebugMode && AppUpdateFloatingConfig.debugPreviewPulse));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final ms = AppUpdateFloatingConfig.pulseMilliseconds.clamp(260, 2000).toInt();
    _pulse = AnimationController(vsync: this,
        duration: Duration(milliseconds: ms));
    AppUpdateCoordinator.instance.notifier.addListener(_onUpdateState);
    _syncAnimation();
    _tryAutoDialog();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _syncAnimation();
    _tryAutoDialog();
  }

  @override
  void didUpdateWidget(covariant AppUpdateFloatingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      _syncAnimation();
      _tryAutoDialog();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncAnimation();
    if (_foreground) _tryAutoDialog();
  }

  void _onUpdateState() {
    if (!mounted) return;
    setState(() {});
    _syncAnimation();
    _tryAutoDialog();
  }

  void _syncAnimation() {
    if (_animate) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  /// Optional one-time Debug display, visually identical to Release, never duplicated over the global
  /// mandatory/optional update gate and never shown in production builds.
  void _tryAutoDialog() {
    if (!kDebugMode || !AppUpdateFloatingConfig.debugAutoDialog ||
        !widget.active || !_foreground || !_debugPreviewOnly ||
        _autoDialogShown || _autoDialogScheduled) return;
    final s = _snapshot;
    if (!s.postSplashReady || s.mode != AppUpdateGateMode.allowed) return;
    _autoDialogScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDialogScheduled = false;
      if (!mounted || !widget.active || !_foreground || !_debugPreviewOnly ||
          _autoDialogShown || _snapshot.mode != AppUpdateGateMode.allowed ||
          !_snapshot.postSplashReady) return;
      _autoDialogShown = true;
      AppUpdateStoreChooser.show(context);
    });
  }

  @override
  void dispose() {
    AppUpdateCoordinator.instance.notifier.removeListener(_onUpdateState);
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    super.dispose();
  }

  void _openDialog() {
    if (!widget.active) return;
    // In Debug, even if there is no server update, BOTH store cards work.
    // In Release the badge cannot exist without a confirmed update.
    AppUpdateStoreChooser.show(context);
  }

  Offset _bounded(Offset p, Size size, double minY, double maxY) {
    final maxX = math.max(_edge, size.width - _diameter - _edge);
    return Offset(p.dx.clamp(_edge, maxX).toDouble(),
        p.dy.clamp(minY, maxY).toDouble());
  }

  Offset _resolvePosition(Size size, double minY, double maxY) {
    if (_localOffset != null) {
      return _bounded(_localOffset!, size, minY, maxY);
    }
    final remembered = _savedNormalizedPosition;
    if (remembered != null) {
      return _bounded(Offset(
        remembered.dx * math.max(0.0, size.width - _diameter),
        remembered.dy * math.max(0.0, size.height - _diameter),
      ), size, minY, maxY);
    }
    final top = minY + widget.topOffset;
    return _bounded(Offset(size.width - _diameter - widget.rightOffset, top),
        size, minY, maxY);
  }

  void _endDrag(Size size, double minY, double maxY) {
    if (!_dragging) return;
    final p = _bounded(_localOffset ?? Offset.zero, size, minY, maxY);
    final snapToLeft = p.dx + _diameter / 2 < size.width / 2;
    final snapped = Offset(
        snapToLeft ? _edge : math.max(_edge, size.width - _diameter - _edge),
        p.dy);
    setState(() {
      _dragging = false;
      _localOffset = snapped;
      _savedNormalizedPosition = Offset(
        snapped.dx / math.max(1.0, size.width - _diameter),
        snapped.dy / math.max(1.0, size.height - _diameter),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      // Absolutely no tappable region or spacing while hidden in Release.
      return const Positioned(top: 0, left: 0, child: SizedBox.shrink());
    }

    final insets = MediaQuery.paddingOf(context);
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          // The parent may already be under SafeArea; clamp against its real
          // render size instead of relying on screen-wide coordinates.
          final minY = math.min(insets.top + 4.0,
              math.max(0.0, size.height - _diameter - _edge));
          final maxY = math.max(minY,
              size.height - _diameter - insets.bottom - _edge);
          final position = _resolvePosition(size, minY, maxY);

          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              AnimatedPositioned(
                duration: _dragging || _reduceMotion
                    ? Duration.zero : const Duration(milliseconds: 190),
                curve: Curves.easeOutCubic,
                left: position.dx,
                top: position.dy,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openDialog,
                  onPanStart: (_) => setState(() {
                    _dragging = true;
                    _localOffset = position;
                  }),
                  onPanUpdate: (details) => setState(() {
                    _localOffset = _bounded(
                      (_localOffset ?? position) + details.delta,
                      size, minY, maxY);
                  }),
                  onPanEnd: (_) => _endDrag(size, minY, maxY),
                  onPanCancel: () => _endDrag(size, minY, maxY),
                  child: Semantics(
                    button: true,
                    label: 'Mở liên kết cập nhật Android và iOS',
                    child: Tooltip(
                      message: 'Chạm để cập nhật · Giữ và kéo để di chuyển',
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final t = _reduceMotion ? 1.0 : _pulse.value;
                          return Transform.scale(
                            scale: 0.97 + 0.045 * t,
                            // No card, solid background, border, or halo around
                            // the Lottie. The full 54dp hit box is retained by
                            // the outer GestureDetector for taps and dragging.
                            child: SizedBox(
                              width: _diameter,
                              height: _diameter,
                              child: FutureBuilder<Uint8List>(
                                future: AppUpdateLocalAssets.animation,
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Center(child: Text(
                                      'Lỗi file', textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 9,
                                          color: Color(0xFFAD332A)),
                                    ));
                                  }
                                  final bytes = snapshot.data;
                                  if (bytes == null) {
                                    return const SizedBox.shrink();
                                  }
                                  // Rotate just the animation, not its hit area
                                  // or the error messages, exactly 180 degrees.
                                  return Transform.rotate(
                                    angle: math.pi,
                                    child: Lottie.memory(
                                      bytes,
                                      fit: BoxFit.contain,
                                      animate: _animate,
                                      repeat: _animate,
                                      errorBuilder: (context, error, trace) {
                                        if (kDebugMode) {
                                          debugPrint('[OneVNU Update] '
                                              'Lottie parse/render failed: $error');
                                        }
                                        // Never replace a missing user animation
                                        // with a stock Flutter update icon.
                                        return const Center(child: Text(
                                          'Lỗi Lottie', textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 8.5,
                                              color: Color(0xFFAD332A)),
                                        ));
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
