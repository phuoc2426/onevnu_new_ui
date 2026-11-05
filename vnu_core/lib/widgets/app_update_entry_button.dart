import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vnu_core/services/app_update_coordinator.dart';
import 'package:vnu_core/widgets/vnu_press_motion.dart';

/// A compact icon, or a horizontal call-to-action for the public admission page.
/// The existing AppUpdateGate continues to handle mandatory updates globally.
enum AppUpdateEntryLayout { icon, banner }

class AppUpdateEntryButton extends StatefulWidget {
  const AppUpdateEntryButton({
    super.key,
    this.alwaysShow = false,
    this.showLabel = false,
    this.layout = AppUpdateEntryLayout.icon,
  });

  /// Only intended for diagnostics. Product placements should hide when current.
  final bool alwaysShow;
  final bool showLabel;
  final AppUpdateEntryLayout layout;

  @override
  State<AppUpdateEntryButton> createState() => _AppUpdateEntryButtonState();
}

class _AppUpdateEntryButtonState extends State<AppUpdateEntryButton>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _attention;
  bool _hasUpdate = false;
  bool _inForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attention = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    );
    AppUpdateCoordinator.instance.notifier.addListener(_syncPolicy);
    _syncPolicy();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    _syncAnimation();
  }

  void _syncPolicy() {
    final evaluation = AppUpdateCoordinator.instance.notifier.value.evaluation;
    final found = evaluation?.isOptional == true || evaluation?.isForce == true;
    if (_hasUpdate != found) {
      _hasUpdate = found;
      if (mounted) setState(() {});
    }
    _syncAnimation();
  }

  void _syncAnimation() {
    if (_hasUpdate && _inForeground) {
      if (!_attention.isAnimating) _attention.repeat();
    } else {
      _attention.stop();
      _attention.value = 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppUpdateCoordinator.instance.notifier.removeListener(_syncPolicy);
    _attention.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    final coordinator = AppUpdateCoordinator.instance;
    if (_hasUpdate) {
      final opened = await coordinator.openStore();
      if (!opened && mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
          content: Text('Không thể mở liên kết cập nhật từ cấu hình hệ thống.'),
        ));
      }
    } else if (widget.alwaysShow) {
      await coordinator.refresh(reason: 'manual_update_check', forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasUpdate && !widget.alwaysShow) return const SizedBox.shrink();
    final reduced = MediaQuery.of(context).disableAnimations;
    final banner = widget.layout == AppUpdateEntryLayout.banner;

    return Semantics(
      button: true,
      label: _hasUpdate ? 'Có bản cập nhật ONEVNU mới, nhấn để tải' : 'Kiểm tra cập nhật',
      child: Tooltip(
        message: _hasUpdate ? 'Cập nhật ONEVNU ngay' : 'Kiểm tra cập nhật',
        child: AnimatedBuilder(
          animation: _attention,
          builder: (context, _) {
            final t = reduced ? 0.0 : _attention.value;
            // Glow oscillates gradually; small shake continually attracts attention.
            final glow = _hasUpdate ? .5 + .5 * math.sin(2 * math.pi * t) : 0.0;
            final shake = _hasUpdate && !reduced
                ? math.sin(2 * math.pi * 5 * t) * (1.3 + .7 * glow)
                : 0.0;
            return Transform.translate(
              offset: Offset(shake, 0),
              child: Transform.rotate(
                angle: shake * .012,
                child: Material(
                  color: Colors.transparent,
                  child: VnuPressMotion(
                    onTap: _handleTap,
                    child: Container(
                      width: banner ? 148 : 43,
                      height: banner ? 36 : (widget.showLabel ? 62 : 43),
                      padding: EdgeInsets.symmetric(
                        horizontal: banner ? 10 : 0,
                        vertical: banner ? 4 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF9F1),
                        borderRadius: BorderRadius.circular(banner ? 12 : 14),
                        border: Border.all(color: const Color(0xFF7BC9A4), width: 1),
                        boxShadow: _hasUpdate
                            ? [BoxShadow(
                                color: const Color(0xFF11BE69)
                                    .withValues(alpha: .20 + .28 * glow),
                                blurRadius: 7 + glow * 15,
                                spreadRadius: .4 + glow * 2.2,
                              )]
                            : null,
                      ),
                      child: banner
                          ? Row(children: [
                              Image.asset('assets/icons/quick_access/update.png',
                                  package: 'vnu_core', height: 23, width: 23),
                              const SizedBox(width: 6),
                              const Expanded(child: Text('Có bản mới',
                                  maxLines: 1,
                                  style: TextStyle(fontSize: 11.5,
                                      color: Color(0xFF077C48), fontWeight: FontWeight.w800))),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 12, color: Color(0xFF077C48)),
                            ])
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/icons/quick_access/update.png',
                                    package: 'vnu_core', height: 29, width: 29,
                                    fit: BoxFit.contain),
                                if (widget.showLabel) ...[
                                  const SizedBox(height: 2),
                                  const Text('Cập nhật',
                                      maxLines: 1,
                                      style: TextStyle(fontSize: 9.5,
                                          color: Color(0xFF087C4B),
                                          fontWeight: FontWeight.w700)),
                                ],
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

