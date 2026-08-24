import 'package:vnu_core/common/error/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../common/log.dart';

class VcoreBrowserController extends GetxController {
  BuildContext? context;

  final RxInt loadingProgess = 0.obs;
  final RxBool canGoBack = false.obs;
  final RxBool canGoForward = false.obs;
  final RxBool isBookmarked = false.obs;

  WebViewController webController = WebViewController();

  /// Ngăn WebView tải lại URL mỗi khi widget rebuild.
  bool _hasLoadedInitialContent = false;

  @override
  void onInit() {
    super.onInit();
    initWebview();
  }

  void initWebview() {
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColor.bgColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            loadingProgess.value = progress;

            logSuccess('WebView progress: $progress');

            _updateStatusBackForward();
          },
          onPageStarted: (String url) {
            loadingProgess.value = 0;

            logSuccess('Start load -> $url');

            _checkBookmark();
          },
          onPageFinished: (String url) {
            loadingProgess.value = 100;

            logSuccess('Finished load -> $url');

            _updateStatusBackForward();
          },
          onWebResourceError: (WebResourceError error) {
            logSuccess(
              'WebView error: '
              '${error.errorCode} - ${error.description}',
            );
          },

          // Có thể mở lại nếu cần chặn một số đường dẫn.
          // onNavigationRequest: (NavigationRequest request) {
          //   if (request.url.startsWith('https://www.youtube.com/')) {
          //     return NavigationDecision.prevent;
          //   }
          //
          //   return NavigationDecision.navigate;
          // },
        ),
      );
  }

  /// Chỉ tải URL hoặc HTML ban đầu một lần.
  void loadInitialContent({String? url, String? html}) {
    if (_hasLoadedInitialContent) {
      return;
    }

    final bool hasUrl = url != null && url.trim().isNotEmpty;

    final bool hasHtml = html != null && html.trim().isNotEmpty;

    if (!hasUrl && !hasHtml) {
      return;
    }

    _hasLoadedInitialContent = true;

    if (hasUrl) {
      loadUrl(url!);
      return;
    }

    loadHtml(html!);
  }

  /// Giữ nguyên hàm load URL cũ.
  void loadUrl(String url) {
    webController.loadRequest(Uri.parse(url));
  }

  /// Giữ nguyên hàm load HTML cũ.
  void loadHtml(String html) {
    webController.loadHtmlString(html);
  }

  /// Quay lại trang trước trong WebView.
  Future<void> goBack() async {
    final bool canBack = await webController.canGoBack();

    if (!canBack) {
      return;
    }

    await webController.goBack();
    await _updateStatusBackForward();
  }

  /// Đi tới trang tiếp theo trong WebView.
  Future<void> goForward() async {
    final bool canForward = await webController.canGoForward();

    if (!canForward) {
      return;
    }

    await webController.goForward();
    await _updateStatusBackForward();
  }

  /// Dùng cho nút back dạng bong bóng.
  ///
  /// WebView có lịch sử:
  /// - Quay lại trang trước.
  ///
  /// WebView không có lịch sử:
  /// - Đóng màn hình WebView.
  Future<void> goBackOrClose() async {
    final bool canBack = await webController.canGoBack();

    if (canBack) {
      await webController.goBack();
      await _updateStatusBackForward();
      return;
    }

    Get.back();
  }

  Future<void> createBookMark() async {
    final String title = await webController.getTitle() ?? '';

    final String url = await webController.currentUrl() ?? '';

    logSuccess(title);
    logSuccess(url);

    if (title.isEmpty || url.isEmpty) {
      snackBarWarning('Không tìm thấy thông tin liên kết.');
      return;
    }

    try {
      Utils.showProgress(context);

      await ApiRepository().createLienKetDanhDau(title, url);

      Utils.dismissProgress(context);

      snackBarSuccess('Tạo liên kết đánh dấu thành công');
    } catch (e) {
      Utils.dismissProgress(context);
      AppFeedback.showError(e);
    }
  }

  Future<void> _updateStatusBackForward() async {
    canGoBack.value = await webController.canGoBack();

    canGoForward.value = await webController.canGoForward();
  }

  void _checkBookmark() {
    // Kiểm tra trạng thái bookmark tại đây.
  }

  @override
  void onClose() {
    context = null;
    super.onClose();
  }
}

