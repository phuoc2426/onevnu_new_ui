import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controllers/vcore_browser_controller.dart';

class VcoreBrowserView extends StatefulWidget {
  final String title;
  final String? url;
  final String? html;

  /// false:
  /// Giữ nguyên giao diện WebView cũ có top navbar.
  ///
  /// true:
  /// Ẩn top navbar và sử dụng nút back dạng bong bóng kéo thả.
  final bool useFloatingBackButton;

  const VcoreBrowserView({
    super.key,
    required this.title,
    this.url,
    this.html,
    this.useFloatingBackButton = false,
  }) : assert(
         url != null || html != null,
         'Phải truyền url hoặc html cho VcoreBrowserView.',
       );

  @override
  State<VcoreBrowserView> createState() => _VcoreBrowserViewState();
}

class _VcoreBrowserViewState extends State<VcoreBrowserView> {
  late final String _controllerTag;

  /// Vị trí hiện tại của bong bóng.
  ///
  /// null: dùng vị trí mặc định ở góc trên bên phải.
  Offset? _floatingButtonPosition;

  /// Bong bóng đang được kéo.
  bool _isDraggingFloatingButton = false;

  /// Bong bóng đang ở trạng thái lớn và rõ.
  ///
  /// false:
  /// - Nhỏ.
  /// - Mờ.
  ///
  /// true:
  /// - Lớn.
  /// - Rõ.
  bool _isFloatingButtonExpanded = false;

  /// Bong bóng đang nằm ở mép phải hay mép trái.
  bool _isDockedRight = true;
  bool _isBackArmed = false;

  /// Bộ đếm tự động thu nhỏ bong bóng.
  Timer? _autoCollapseTimer;

  /// Sau 5 giây không tương tác, nút tự thu nhỏ.
  static const Duration _autoCollapseDelay = Duration(seconds: 1);

  /// Kích thước khi thu nhỏ.
  static const double _collapsedButtonSize = 38;

  /// Kích thước khi phóng to.
  static const double _expandedButtonSize = 58;

  /// Khoảng cách với mép màn hình.
  static const double _floatingButtonMargin = 10;

  /// Lưu thông tin màn hình gần nhất để Timer sử dụng.
  double _lastScreenWidth = 0;
  double _lastScreenHeight = 0;
  EdgeInsets _lastSafePadding = EdgeInsets.zero;

  @override
  void initState() {
    super.initState();

    /// Mỗi màn hình WebView có một controller riêng.
    _controllerTag = const Uuid().v4();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcoreBrowserController>(
      init: VcoreBrowserController(),
      tag: _controllerTag,
      builder: (controller) {
        /// Controller tự kiểm tra để chỉ tải URL/HTML một lần.
        controller.loadInitialContent(url: widget.url, html: widget.html);

        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: widget.useFloatingBackButton
              ? _buildFloatingBrowser(controller)
              : _buildDefaultBrowser(controller),
        );
      },
    );
  }

  /// Giao diện WebView cũ có top navbar.
  ///
  /// Những màn hình không truyền:
  ///
  /// useFloatingBackButton: true
  ///
  /// sẽ tiếp tục sử dụng giao diện này.
  Widget _buildDefaultBrowser(VcoreBrowserController controller) {
    return VcoreModuleScaffold(
      title: widget.title,
      showBackButton: true,
      body: Column(
        children: [
          Expanded(child: WebViewWidget(controller: controller.webController)),
        ],
      ),
    );
  }

  /// WebView toàn màn hình với bong bóng back kéo thả.
  Widget _buildFloatingBrowser(VcoreBrowserController controller) {
    return WillPopScope(
      onWillPop: () async {
        await controller.goBackOrClose();

        /// Không để hệ thống tự pop thêm lần nữa.
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColor.bgColor,
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final EdgeInsets safePadding = MediaQuery.paddingOf(context);

            /// Lưu lại thông tin màn hình để Timer sử dụng.
            _lastScreenWidth = constraints.maxWidth;
            _lastScreenHeight = constraints.maxHeight;
            _lastSafePadding = safePadding;

            final double currentButtonSize = _isFloatingButtonExpanded
                ? _expandedButtonSize
                : _collapsedButtonSize;

            final double minX = _floatingButtonMargin;

            final double maxX =
                constraints.maxWidth -
                currentButtonSize -
                _floatingButtonMargin;

            final double minY = safePadding.top + _floatingButtonMargin;

            final double maxY =
                constraints.maxHeight -
                safePadding.bottom -
                currentButtonSize -
                _floatingButtonMargin;

            /// Mặc định nằm ở góc trên bên phải.
            final Offset defaultPosition = Offset(maxX, minY);

            final Offset rawPosition =
                _floatingButtonPosition ?? defaultPosition;

            /// Không cho bong bóng nằm ngoài màn hình.
            final Offset currentPosition = Offset(
              rawPosition.dx.clamp(minX, maxX).toDouble(),
              rawPosition.dy.clamp(minY, maxY).toDouble(),
            );

            return Stack(
              clipBehavior: Clip.none,
              children: [
                /// WebView chiếm toàn bộ màn hình.
                Positioned.fill(
                  child: WebViewWidget(controller: controller.webController),
                ),

                /// Bong bóng back.
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

                          /// Sau lần chạm đầu tiên, lần tiếp theo mới được back.
                          _isBackArmed = true;

                          _floatingButtonPosition = Offset(
                            expandedX,
                            currentPosition.dy,
                          );
                        });

                        _restartAutoCollapseTimer();
                        return;
                      }

                      /// Trường hợp nút đang lớn nhưng chưa được phép back.
                      if (!_isBackArmed) {
                        setState(() {
                          _isBackArmed = true;
                        });

                        _restartAutoCollapseTimer();
                        return;
                      }

                      /// LẦN NHẤN THỨ HAI:
                      /// Lúc này mới thực hiện back.
                      _cancelAutoCollapseTimer();

                      setState(() {
                        _isBackArmed = false;
                      });

                      await controller.goBackOrClose();

                      /// Nếu chỉ quay lại trang trước trong WebView,
                      /// nút sẽ tự thu nhỏ lại.
                      if (mounted) {
                        _collapseFloatingButton();
                      }
                    },

                    /// Khi bắt đầu kéo:
                    /// - Dừng Timer.
                    /// - Phóng to bong bóng.
                    onPanStart: (_) {
                      _cancelAutoCollapseTimer();

                      setState(() {
                        _isDraggingFloatingButton = true;
                        _isFloatingButtonExpanded = true;

                        /// Kéo là một thao tác mở nút.
                        /// Lần chạm tiếp theo mới thực hiện back.
                        _isBackArmed = true;

                        _floatingButtonPosition = currentPosition;
                      });
                    },

                    /// Di chuyển bong bóng theo ngón tay.
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

                    /// Khi thả tay:
                    /// - Tự bám mép trái hoặc phải.
                    /// - Sau 5 giây không tương tác sẽ tự thu nhỏ.
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
        ),
      ),
    );
  }

  /// Phóng to bong bóng.
  void _expandFloatingButton({
    required Offset currentPosition,
    required double screenWidth,
  }) {
    _cancelAutoCollapseTimer();

    /// Xác định bong bóng đang ở mép phải hay trái.
    _isDockedRight = currentPosition.dx >= screenWidth / 2;

    final double expandedX = _isDockedRight
        ? screenWidth - _expandedButtonSize - _floatingButtonMargin
        : _floatingButtonMargin;

    setState(() {
      _isFloatingButtonExpanded = true;

      _floatingButtonPosition = Offset(expandedX, currentPosition.dy);
    });

    /// Sau khi phóng to, bắt đầu đếm 5 giây.
    _restartAutoCollapseTimer();
  }

  /// Đưa bong bóng về mép trái hoặc phải gần nhất.
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

    /// Tâm nút nằm bên phải màn hình thì bám mép phải.
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

    /// Sau khi thả tay, đếm lại 5 giây.
    _restartAutoCollapseTimer();
  }

  /// Hủy bộ đếm hiện tại.
  void _cancelAutoCollapseTimer() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = null;
  }

  /// Khởi động lại bộ đếm 5 giây.
  void _restartAutoCollapseTimer() {
    _cancelAutoCollapseTimer();

    if (!_isFloatingButtonExpanded || _isDraggingFloatingButton) {
      return;
    }

    _autoCollapseTimer = Timer(_autoCollapseDelay, _collapseFloatingButton);
  }

  /// Tự động thu nhỏ và làm mờ bong bóng.
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

    /// Khi thu nhỏ vẫn giữ nguyên bên trái hoặc bên phải.
    final double collapsedX = _isDockedRight
        ? _lastScreenWidth - _collapsedButtonSize - _floatingButtonMargin
        : _floatingButtonMargin;

    setState(() {
      _isFloatingButtonExpanded = false;

      /// Khi đã thu nhỏ, lần nhấn sau phải phóng to trước.
      _isBackArmed = false;

      _floatingButtonPosition = Offset(
        collapsedX,
        oldPosition.dy.clamp(minY, maxY).toDouble(),
      );
    });

    _cancelAutoCollapseTimer();
  }

  /// Giao diện bong bóng ở trạng thái nhỏ/lớn.
  Widget _buildMessengerBackBubble() {
    final bool isExpanded = _isFloatingButtonExpanded;

    final double currentSize = isExpanded
        ? _expandedButtonSize
        : _collapsedButtonSize;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),

      /// Khi thu nhỏ sẽ mờ hơn.
      opacity: isExpanded ? 1 : 0.42,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        width: currentSize,
        height: currentSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,

          /// Khi lớn sử dụng màu xanh Messenger.
          ///
          /// Khi nhỏ sử dụng màu xám xanh để bớt nổi.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isExpanded
                ? const [Color(0xFF00C6FF), Color(0xFF0068FF)]
                : const [Color(0xFF64748B), Color(0xFF334155)],
          ),

          border: Border.all(
            color: Colors.white.withOpacity(isExpanded ? 0.95 : 0.55),
            width: isExpanded ? 2.4 : 1.2,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isExpanded ? 0.26 : 0.10),
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
                Icons.arrow_back_rounded,
                key: ValueKey<bool>(isExpanded),
                color: Colors.white,
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

    if (Get.isRegistered<VcoreBrowserController>(tag: _controllerTag)) {
      Get.delete<VcoreBrowserController>(tag: _controllerTag);
    }

    super.dispose();
  }
}
