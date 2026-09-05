import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/vcore_floating_back_bubble.dart';
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

  /// Khi true, đây là WebView dùng cho chức năng "Nhà trọ" (motel).
  /// WebView sẽ nằm dưới một header trắng, bao gồm cả vùng SafeArea.
  final bool isMotel;

  /// false (mặc định):
  /// - Còn history WebView -> bubble là mũi tên và goBack().
  /// - Hết history/đang ở entry đầu tiên -> bubble đổi thành X đỏ và đóng route.
  ///
  /// true:
  /// - Không quan tâm history WebView.
  /// - Bubble luôn là X đỏ.
  /// - Nhấn action sẽ đóng hẳn màn WebView ngay lập tức.
  final bool forceCloseWebViewOnBack;

  const VcoreBrowserView({
    super.key,
    required this.title,
    this.url,
    this.html,
    this.useFloatingBackButton = false,
    this.isMotel = false,
    this.forceCloseWebViewOnBack = false,
  }) : assert(
         url != null || html != null,
         'Phải truyền url hoặc html cho VcoreBrowserView.',
       );

  @override
  State<VcoreBrowserView> createState() => _VcoreBrowserViewState();
}

class _VcoreBrowserViewState extends State<VcoreBrowserView> {
  late final String _controllerTag;

  /// Phần header trắng dành riêng cho WebView phòng trọ.
  ///
  /// Chiều cao này không bao gồm phần status bar/SafeArea.
  static const double _motelHeaderExtent = 15;

  /// Khoảng trắng bao quanh WebView phòng trọ.
  static const double _motelWebViewMargin = 8;

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
          if (widget.isMotel)
            const SizedBox(
              height: _motelHeaderExtent,
              child: ColoredBox(color: Colors.white),
            ),
          Expanded(
            child: ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(
                  widget.isMotel ? _motelWebViewMargin : 0,
                ),
                child: WebViewWidget(
                  controller: controller.webController,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// WebView toàn màn hình với bong bóng Back dùng chung.
  ///
  /// Behavior bubble (phóng/thu, drag, snap cạnh, timer, 2 lần chạm)
  /// nằm hoàn toàn trong [VcoreFloatingBackBubble].
  Widget _buildFloatingBrowser(VcoreBrowserController controller) {
    return WillPopScope(
      onWillPop: () async {
        await _handleFloatingBack(controller);

        /// Không để hệ thống tự pop thêm lần nữa.
        return false;
      },
      child: Scaffold(
        backgroundColor: widget.isMotel ? Colors.white : AppColor.bgColor,
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final EdgeInsets safePadding = MediaQuery.paddingOf(context);
            final double motelWebViewTop =
                safePadding.top + _motelHeaderExtent;

            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                if (widget.isMotel) ...<Widget>[
                  const Positioned.fill(
                    child: ColoredBox(color: Colors.white),
                  ),
                  Positioned(
                    top: motelWebViewTop - 1,
                    left: 0,
                    right: 0,
                    height: 1,
                    child: const ColoredBox(color: Color(0xFFE5E7EB)),
                  ),
                  Positioned(
                    top: motelWebViewTop,
                    left: _motelWebViewMargin,
                    right: _motelWebViewMargin,
                    bottom: _motelWebViewMargin,
                    child: WebViewWidget(
                      controller: controller.webController,
                    ),
                  ),
                ] else
                  Positioned.fill(
                    child: WebViewWidget(
                      controller: controller.webController,
                    ),
                  ),
                Positioned.fill(
                  child: Obx(() {
                    final bool isCloseAction =
                        widget.forceCloseWebViewOnBack ||
                        !controller.canGoBack.value;

                    return VcoreFloatingBackBubble(
                      isCloseAction: isCloseAction,
                      onBack: () => _handleFloatingBack(controller),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleFloatingBack(
    VcoreBrowserController controller,
  ) async {
    if (widget.forceCloseWebViewOnBack) {
      /// Pop route hiện tại -> State.dispose() chạy -> controller WebView bị xóa.
      /// Đây là chế độ "kill WebView" theo yêu cầu.
      if (mounted) {
        Get.back();
      }
      return;
    }

    /// Chế độ mặc định:
    /// - canGoBack = true: quay lịch sử WebView.
    /// - canGoBack = false: controller.goBackOrClose() sẽ Get.back().
    await controller.goBackOrClose();
  }

  @override
  void dispose() {
    if (Get.isRegistered<VcoreBrowserController>(tag: _controllerTag)) {
      Get.delete<VcoreBrowserController>(tag: _controllerTag);
    }

    super.dispose();
  }
}
