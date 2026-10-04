import 'dart:async';

import 'package:flutter/material.dart';

enum VcoreNoticeTone { success, warning, error, info }

OverlayEntry? _activeVcoreNotice;

void showVcoreNotice({
  required BuildContext context,
  required String title,
  required String message,
  VcoreNoticeTone tone = VcoreNoticeTone.info,
  Duration duration = const Duration(milliseconds: 2600),
}) {
  final OverlayState? overlay = Overlay.of(context, rootOverlay: true);
  if (overlay == null) return;

  final OverlayEntry? previous = _activeVcoreNotice;
  if (previous != null && previous.mounted) {
    previous.remove();
  }

  late OverlayEntry entry;
  bool removed = false;
  void removeEntry() {
    if (removed) return;
    removed = true;
    if (entry.mounted) entry.remove();
    if (identical(_activeVcoreNotice, entry)) _activeVcoreNotice = null;
  }

  entry = OverlayEntry(
    builder: (BuildContext overlayContext) => _VcoreNoticeOverlay(
      title: title,
      message: message,
      tone: tone,
      duration: duration,
      onDismissed: removeEntry,
    ),
  );
  _activeVcoreNotice = entry;
  overlay.insert(entry);
}

class _VcoreNoticeOverlay extends StatefulWidget {
  final String title;
  final String message;
  final VcoreNoticeTone tone;
  final Duration duration;
  final VoidCallback onDismissed;

  const _VcoreNoticeOverlay({
    required this.title,
    required this.message,
    required this.tone,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_VcoreNoticeOverlay> createState() => _VcoreNoticeOverlayState();
}

class _VcoreNoticeOverlayState extends State<_VcoreNoticeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 210),
    );
    final CurvedAnimation curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _scale = Tween<double>(begin: .965, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, -.16),
      end: Offset.zero,
    ).animate(curved);
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    try {
      await _controller.reverse();
    } finally {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _NoticePalette palette = _palette(context, widget.tone);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 14,
      right: 14,
      child: SafeArea(
        top: false,
        bottom: false,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: ScaleTransition(
              scale: _scale,
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _dismiss,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.border),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withOpacity(.12),
                          blurRadius: 22,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: palette.iconBackground,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            palette.icon,
                            size: 19,
                            color: palette.foreground,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: palette.foreground,
                                  fontSize: 13.2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.message,
                                style: TextStyle(
                                  color: palette.text,
                                  fontSize: 11.8,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkResponse(
                          onTap: _dismiss,
                          radius: 18,
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              Icons.close_rounded,
                              size: 17,
                              color: palette.text.withOpacity(.72),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _NoticePalette _palette(BuildContext context, VcoreNoticeTone tone) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    switch (tone) {
      case VcoreNoticeTone.success:
        return const _NoticePalette(
          background: Color(0xFFF2FAF5),
          border: Color(0xFFCFE8D7),
          iconBackground: Color(0xFFDDF3E4),
          foreground: Color(0xFF247A45),
          text: Color(0xFF365B43),
          icon: Icons.check_rounded,
        );
      case VcoreNoticeTone.warning:
        return const _NoticePalette(
          background: Color(0xFFFFF8EB),
          border: Color(0xFFF0D8A5),
          iconBackground: Color(0xFFFFEDC3),
          foreground: Color(0xFF9A6812),
          text: Color(0xFF6F5628),
          icon: Icons.priority_high_rounded,
        );
      case VcoreNoticeTone.error:
        return _NoticePalette(
          background: const Color(0xFFFFF3F3),
          border: const Color(0xFFF0CDCD),
          iconBackground: const Color(0xFFFFDEDE),
          foreground: scheme.error,
          text: const Color(0xFF714242),
          icon: Icons.close_rounded,
        );
      case VcoreNoticeTone.info:
        return _NoticePalette(
          background: const Color(0xFFF3F7FC),
          border: const Color(0xFFD4E0EE),
          iconBackground: const Color(0xFFE1ECF8),
          foreground: scheme.primary,
          text: const Color(0xFF445B70),
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _NoticePalette {
  final Color background;
  final Color border;
  final Color iconBackground;
  final Color foreground;
  final Color text;
  final IconData icon;

  const _NoticePalette({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.foreground,
    required this.text,
    required this.icon,
  });
}
