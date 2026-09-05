import 'dart:async';

import 'package:flutter/material.dart';

/// Nút Back dạng bong bóng dùng chung cho các WebView của ONEVNU.
///
/// Component này được tách nguyên từ behavior đang dùng ở chức năng Nhà trọ:
/// - Trạng thái thu nhỏ: 38px, mờ.
/// - Chạm lần đầu: phóng to 58px và "arm" nút Back.
/// - Chạm lần hai khi đang lớn: thực hiện [onBack].
/// - Có thể kéo tự do trong vùng an toàn của màn hình.
/// - Khi thả sẽ snap về mép trái/phải gần nhất.
/// - Sau [_autoCollapseDelay] không tương tác sẽ tự thu nhỏ.
class VcoreFloatingBackBubble extends StatefulWidget {
  const VcoreFloatingBackBubble({
    super.key,
    required this.onBack,
    this.isCloseAction = false,
  });

  /// Callback thực thi khi người dùng nhấn action của bubble.
  final Future<void> Function() onBack;

  /// false: hiển thị mũi tên Back như behavior Nhà trọ cũ.
  /// true: hiển thị dấu X đỏ để báo rõ thao tác sẽ đóng hẳn WebView.
  ///
  /// Việc quyết định khi nào là Back hay Close thuộc màn hình cha;
  /// component chỉ chịu trách nhiệm biểu diễn đúng trạng thái đó.
  final bool isCloseAction;

  @override
  State<VcoreFloatingBackBubble> createState() =>
      _VcoreFloatingBackBubbleState();
}

class _VcoreFloatingBackBubbleState extends State<VcoreFloatingBackBubble> {
  Offset? _floatingButtonPosition;
  bool _isDraggingFloatingButton = false;
  bool _isFloatingButtonExpanded = false;
  bool _isDockedRight = true;
  bool _isBackArmed = false;
  Timer? _autoCollapseTimer;

  /// Giữ đúng behavior runtime hiện tại của Nhà trọ: 1 giây.
  static const Duration _autoCollapseDelay = Duration(seconds: 1);

  static const double _collapsedButtonSize = 38;
  static const double _expandedButtonSize = 58;
  static const double _floatingButtonMargin = 10;

  double _lastScreenWidth = 0;
  double _lastScreenHeight = 0;
  EdgeInsets _lastSafePadding = EdgeInsets.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final EdgeInsets safePadding = MediaQuery.paddingOf(context);

        _lastScreenWidth = constraints.maxWidth;
        _lastScreenHeight = constraints.maxHeight;
        _lastSafePadding = safePadding;

        final double currentButtonSize = _isFloatingButtonExpanded
            ? _expandedButtonSize
            : _collapsedButtonSize;

        final double minX = _floatingButtonMargin;
        final double maxX =
            constraints.maxWidth - currentButtonSize - _floatingButtonMargin;
        final double minY = safePadding.top + _floatingButtonMargin;
        final double maxY =
            constraints.maxHeight -
            safePadding.bottom -
            currentButtonSize -
            _floatingButtonMargin;

        final Offset defaultPosition = Offset(maxX, minY);
        final Offset rawPosition = _floatingButtonPosition ?? defaultPosition;
        final Offset currentPosition = Offset(
          rawPosition.dx.clamp(minX, maxX).toDouble(),
          rawPosition.dy.clamp(minY, maxY).toDouble(),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            AnimatedPositioned(
              left: currentPosition.dx,
              top: currentPosition.dy,
              duration: _isDraggingFloatingButton
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  if (!_isFloatingButtonExpanded) {
                    _cancelAutoCollapseTimer();

                    final bool isRight =
                        currentPosition.dx >= constraints.maxWidth / 2;
                    final double expandedX = isRight
                        ? constraints.maxWidth -
                              _expandedButtonSize -
                              _floatingButtonMargin
                        : _floatingButtonMargin;

                    setState(() {
                      _isDockedRight = isRight;
                      _isFloatingButtonExpanded = true;
                      _isBackArmed = true;
                      _floatingButtonPosition = Offset(
                        expandedX,
                        currentPosition.dy,
                      );
                    });

                    _restartAutoCollapseTimer();
                    return;
                  }

                  if (!_isBackArmed) {
                    setState(() {
                      _isBackArmed = true;
                    });
                    _restartAutoCollapseTimer();
                    return;
                  }

                  _cancelAutoCollapseTimer();
                  setState(() {
                    _isBackArmed = false;
                  });

                  await widget.onBack();

                  if (mounted) {
                    _collapseFloatingButton();
                  }
                },
                onPanStart: (_) {
                  _cancelAutoCollapseTimer();

                  setState(() {
                    _isDraggingFloatingButton = true;
                    _isFloatingButtonExpanded = true;
                    _isBackArmed = true;
                    _floatingButtonPosition = currentPosition;
                  });
                },
                onPanUpdate: (DragUpdateDetails details) {
                  final double dragMaxX =
                      constraints.maxWidth -
                      _expandedButtonSize -
                      _floatingButtonMargin;
                  final double dragMaxY =
                      constraints.maxHeight -
                      safePadding.bottom -
                      _expandedButtonSize -
                      _floatingButtonMargin;

                  final Offset oldPosition =
                      _floatingButtonPosition ?? currentPosition;
                  final Offset newPosition = oldPosition + details.delta;

                  setState(() {
                    _floatingButtonPosition = Offset(
                      newPosition.dx.clamp(minX, dragMaxX).toDouble(),
                      newPosition.dy.clamp(minY, dragMaxY).toDouble(),
                    );
                  });
                },
                onPanEnd: (_) {
                  _snapFloatingButtonToEdge(
                    screenWidth: constraints.maxWidth,
                    screenHeight: constraints.maxHeight,
                    safePadding: safePadding,
                  );
                },
                onPanCancel: () {
                  _snapFloatingButtonToEdge(
                    screenWidth: constraints.maxWidth,
                    screenHeight: constraints.maxHeight,
                    safePadding: safePadding,
                  );
                },
                child: _buildMessengerBackBubble(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _snapFloatingButtonToEdge({
    required double screenWidth,
    required double screenHeight,
    required EdgeInsets safePadding,
  }) {
    final double minX = _floatingButtonMargin;
    final double maxX =
        screenWidth - _expandedButtonSize - _floatingButtonMargin;
    final double minY = safePadding.top + _floatingButtonMargin;
    final double maxY =
        screenHeight -
        safePadding.bottom -
        _expandedButtonSize -
        _floatingButtonMargin;

    final Offset oldPosition = _floatingButtonPosition ?? Offset(maxX, minY);
    final double buttonCenterX = oldPosition.dx + (_expandedButtonSize / 2);
    final double screenCenterX = screenWidth / 2;

    _isDockedRight = buttonCenterX >= screenCenterX;
    final double snappedX = _isDockedRight ? maxX : minX;

    setState(() {
      _isDraggingFloatingButton = false;
      _isFloatingButtonExpanded = true;
      _floatingButtonPosition = Offset(
        snappedX,
        oldPosition.dy.clamp(minY, maxY).toDouble(),
      );
    });

    _restartAutoCollapseTimer();
  }

  void _cancelAutoCollapseTimer() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = null;
  }

  void _restartAutoCollapseTimer() {
    _cancelAutoCollapseTimer();

    if (!_isFloatingButtonExpanded || _isDraggingFloatingButton) {
      return;
    }

    _autoCollapseTimer = Timer(_autoCollapseDelay, _collapseFloatingButton);
  }

  void _collapseFloatingButton() {
    if (!mounted || _isDraggingFloatingButton || !_isFloatingButtonExpanded) {
      return;
    }

    if (_lastScreenWidth <= 0 || _lastScreenHeight <= 0) {
      return;
    }

    final double minY = _lastSafePadding.top + _floatingButtonMargin;
    final double maxY =
        _lastScreenHeight -
        _lastSafePadding.bottom -
        _collapsedButtonSize -
        _floatingButtonMargin;

    final Offset oldPosition =
        _floatingButtonPosition ??
        Offset(
          _lastScreenWidth - _expandedButtonSize - _floatingButtonMargin,
          minY,
        );

    final double collapsedX = _isDockedRight
        ? _lastScreenWidth - _collapsedButtonSize - _floatingButtonMargin
        : _floatingButtonMargin;

    setState(() {
      _isFloatingButtonExpanded = false;
      _isBackArmed = false;
      _floatingButtonPosition = Offset(
        collapsedX,
        oldPosition.dy.clamp(minY, maxY).toDouble(),
      );
    });

    _cancelAutoCollapseTimer();
  }

  Widget _buildMessengerBackBubble() {
    final bool isExpanded = _isFloatingButtonExpanded;
    final bool isCloseAction = widget.isCloseAction;
    final double currentSize = isExpanded
        ? _expandedButtonSize
        : _collapsedButtonSize;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: isExpanded ? 1 : (isCloseAction ? 0.72 : 0.42),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        width: currentSize,
        height: currentSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCloseAction ? Colors.white : null,
          gradient: isCloseAction
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isExpanded
                      ? const <Color>[
                          Color(0xFF00C6FF),
                          Color(0xFF0068FF),
                        ]
                      : const <Color>[
                          Color(0xFF64748B),
                          Color(0xFF334155),
                        ],
                ),
          border: Border.all(
            color: isCloseAction
                ? const Color(0xFFDC2626).withOpacity(isExpanded ? 1 : 0.78)
                : Colors.white.withOpacity(isExpanded ? 0.95 : 0.55),
            width: isExpanded ? 2.4 : 1.2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isCloseAction
                  ? const Color(0xFFDC2626).withOpacity(
                      isExpanded ? 0.20 : 0.10,
                    )
                  : Colors.black.withOpacity(isExpanded ? 0.26 : 0.10),
              blurRadius: isExpanded ? 15 : 5,
              spreadRadius: _isDraggingFloatingButton ? 2 : 0,
              offset: Offset(0, isExpanded ? 6 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                isCloseAction ? Icons.close_rounded : Icons.arrow_back_rounded,
                key: ValueKey<String>(
                  '${isCloseAction ? 'close' : 'back'}-$isExpanded',
                ),
                color: isCloseAction
                    ? const Color(0xFFDC2626)
                    : Colors.white,
                size: isExpanded ? 27 : 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cancelAutoCollapseTimer();
    super.dispose();
  }
}
