import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/vcore_floating_back_bubble.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controllers/vcore_browser_controller.dart';
import '../widgets/vcore_webview_surface.dart';

class VcoreBrowserView extends StatefulWidget {
  final String title;
  final String? url;
  final String? html;

  /// true (mặc định):
  /// Không có header/navbar mặc định; WebView chạy toàn màn hình và dùng
  /// nút back/close dạng bong bóng.
  ///
  /// false:
  /// Chỉ dùng khi một màn hình cũ thực sự cần VcoreModuleScaffold + navbar.
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

  /// Tuỳ chỉnh chrome/header cho WebView đặc biệt (hiện dùng bởi Phòng trọ).
  final double webViewHeaderExtent;
  final Color webViewHeaderColor;
  final Color webViewBackgroundColor;
  final EdgeInsets webViewHeaderMargin;
  final EdgeInsets webViewContentMargin;
  final Color webViewHeaderDividerColor;

  const VcoreBrowserView({
    super.key,
    required this.title,
    this.url,
    this.html,
    this.useFloatingBackButton = true,
    this.isMotel = false,
    this.forceCloseWebViewOnBack = false,
    this.webViewHeaderExtent = 15,
    this.webViewHeaderColor = Colors.white,
    this.webViewBackgroundColor = Colors.white,
    this.webViewHeaderMargin = EdgeInsets.zero,
    this.webViewContentMargin = const EdgeInsets.all(8),
    this.webViewHeaderDividerColor = const Color(0xFFE5E7EB),
  }) : assert(
         url != null || html != null,
         'Phải truyền url hoặc html cho VcoreBrowserView.',
       );

  @override
  State<VcoreBrowserView> createState() => _VcoreBrowserViewState();
}

class _VcoreBrowserViewState extends State<VcoreBrowserView> {
  late final String _controllerTag;

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

  /// Giao diện tương thích cũ có top navbar.
  ///
  /// Chỉ xuất hiện khi caller chủ động truyền:
  /// useFloatingBackButton: false.
  Widget _buildDefaultBrowser(VcoreBrowserController controller) {
    return VcoreModuleScaffold(
      title: widget.title,
      showBackButton: true,
      body: Column(
        children: [
          if (widget.isMotel)
            SizedBox(
              height: widget.webViewHeaderExtent,
              child: ColoredBox(color: widget.webViewHeaderColor),
            ),
          Expanded(
            child: ColoredBox(
              color: widget.isMotel
                  ? widget.webViewBackgroundColor
                  : Colors.white,
              child: Padding(
                padding: widget.isMotel
                    ? widget.webViewContentMargin
                    : EdgeInsets.zero,
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
        body: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: VcoreWebViewSurface(
                controller: controller.webController,
                isMotel: widget.isMotel,
                headerExtent: widget.webViewHeaderExtent,
                headerColor: widget.webViewHeaderColor,
                backgroundColor: widget.webViewBackgroundColor,
                headerMargin: widget.webViewHeaderMargin,
                webViewMargin: widget.webViewContentMargin,
                dividerColor: widget.webViewHeaderDividerColor,
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

