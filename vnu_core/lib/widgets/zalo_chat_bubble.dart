import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vnu_core/common/guide/core/app_showcase_scope.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/services/app_config_service.dart';
import 'package:vnu_core/widgets/draggable_speech_bubble.dart';
import 'package:vnu_core/widgets/speech_bubble.dart';

class ZaloChatBubble extends StatefulWidget {
  const ZaloChatBubble({
    super.key,
    this.groupInviteUrl = '',
    this.edgeInsets = const EdgeInsets.fromLTRB(12, 12, 16, 24),
    this.showSpeechMessages = true,
    this.initialMessageDelay = const Duration(milliseconds: 900),
    this.messageVisibleDuration = const Duration(seconds: 4),
    this.messageGap = const Duration(milliseconds: 1200),
    this.messages = const <String>[
      'Bạn cần hỗ trợ về chỗ ở sinh viên?',
      'Giải đáp nội trú, ngoại trú nhanh chóng',
      'Hướng dẫn đăng ký ký túc xá',
      'Cần tư vấn? Tham gia nhóm Zalo ngay',
      'Nhấn vào đây để được hỗ trợ nhé!',
    ],
  });

  final String groupInviteUrl;
  final EdgeInsets edgeInsets;
  final bool showSpeechMessages;
  final Duration initialMessageDelay;
  final Duration messageVisibleDuration;
  final Duration messageGap;
  final List<String> messages;

  @override
  State<ZaloChatBubble> createState() => _ZaloChatBubbleState();
}

class _ZaloChatBubbleState extends State<ZaloChatBubble>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulseController;
  final SpeechBubbleController _speechController = SpeechBubbleController();

  Timer? _messageTimer;
  int _messageIndex = 0;
  bool _refreshScheduled = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    AppConfigService().ensureLoaded();
    AppConfigService().zaloGroupUrlNotifier.addListener(_onConfigChanged);
    AppGuideOverlayVisibility.notifier.addListener(_onGuideVisibilityChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleNextMessage(widget.initialMessageDelay);
    });
  }

  @override
  void didUpdateWidget(covariant ZaloChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.showSpeechMessages != widget.showSpeechMessages ||
        oldWidget.messages != widget.messages) {
      _messageTimer?.cancel();
      _speechController.hide();
      _messageIndex = 0;
      _scheduleNextMessage(widget.initialMessageDelay);
    }
  }

  void _onConfigChanged() {
    logInfo(
      'ZaloChatBubble URL: ${AppConfigService().effectiveZaloGroupUrl}',
    );
  }

  void _onGuideVisibilityChanged() {
    if (AppGuideOverlayVisibility.isActive) {
      _messageTimer?.cancel();
      _speechController.hide();
      return;
    }

    _scheduleNextMessage(const Duration(milliseconds: 500));
  }

  bool get _isRouteCurrent {
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    return route == null || route.isCurrent;
  }

  bool get _canShowMessage {
    return mounted &&
        widget.showSpeechMessages &&
        widget.messages.isNotEmpty &&
        _lifecycleState == AppLifecycleState.resumed &&
        !AppGuideOverlayVisibility.isActive &&
        _isRouteCurrent &&
        TickerMode.of(context);
  }

  void _scheduleNextMessage(Duration delay) {
    _messageTimer?.cancel();
    if (!mounted ||
        !widget.showSpeechMessages ||
        widget.messages.isEmpty ||
        AppGuideOverlayVisibility.isActive) {
      return;
    }

    _messageTimer = Timer(delay, _showNextMessage);
  }

  Future<void> _showNextMessage() async {
    if (!_canShowMessage) {
      await _speechController.hide();
      _scheduleNextMessage(const Duration(seconds: 1));
      return;
    }

    final String message =
        widget.messages[_messageIndex % widget.messages.length];
    _messageIndex = (_messageIndex + 1) % widget.messages.length;

    await _speechController.show(
      text: message,
      preferredPlacement: SpeechBubblePlacement.auto,
      autoHideAfter: widget.messageVisibleDuration,
      maxWidth: 280,
      maxHeightFactor: 0.3,
      gap: 10,
      screenMargin: 12,
      backgroundColor: const Color(0xFF0068FF),
      borderColor: Colors.white.withOpacity(0.35),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      dismissOnTapOutside: false,
      onTap: _handleBubbleTap,
      canShow: () => _canShowMessage,
    );

    _scheduleNextMessage(widget.messageVisibleDuration + widget.messageGap);
  }

  void _handleBubbleTap() {
    _speechController.hide();
    _openZaloGroup();
  }

  void _onPositionChanged(Offset _) {
    if (_refreshScheduled) return;

    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (mounted) {
        _speechController.refresh();
      }
    });
  }

  String get _effectiveInviteUrl {
    final String explicitUrl = widget.groupInviteUrl.trim();
    if (explicitUrl.isNotEmpty) {
      return explicitUrl;
    }

    return AppConfigService().effectiveZaloGroupUrl;
  }

  Future<void> _openZaloGroup() async {
    final String url = _effectiveInviteUrl;
    final Uri? uri = Uri.tryParse(url);

    if (uri == null || uri.scheme != 'https' || uri.host != 'zalo.me') {
      _showMessage('Link nhóm Zalo không hợp lệ');
      return;
    }

    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      _showMessage('Không thể mở Zalo, vui lòng thử lại');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;

    if (state == AppLifecycleState.resumed) {
      _scheduleNextMessage(const Duration(milliseconds: 500));
    } else {
      _messageTimer?.cancel();
      _speechController.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRouteCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _speechController.hide();
        }
      });
      return const SizedBox.shrink();
    }

    return DraggableSpeechBubble(
      bubbleSize: const Size(64, 64),
      edgeInsets: widget.edgeInsets,
      onTap: _handleBubbleTap,
      onPositionChanged: _onPositionChanged,
      child: SpeechBubbleAnchor(
        controller: _speechController,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.95,
            end: 1.05,
          ).animate(
            CurvedAnimation(
              parent: _pulseController,
              curve: Curves.easeInOut,
            ),
          ),
          child: Semantics(
            button: true,
            label: 'Mở nhóm Zalo hỗ trợ sinh viên',
            child: Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF0068FF).withOpacity(0.42),
                    blurRadius: 18,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/zalo_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return const Icon(
                    Icons.chat_rounded,
                    color: Color(0xFF0068FF),
                    size: 36,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppConfigService().zaloGroupUrlNotifier.removeListener(_onConfigChanged);
    AppGuideOverlayVisibility.notifier.removeListener(
      _onGuideVisibilityChanged,
    );
    _messageTimer?.cancel();
    _speechController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
