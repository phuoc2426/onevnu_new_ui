import 'package:vnu_core/common/error/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../common/log.dart';
import '../vcore_webview_support.dart';

class VcoreBrowserController extends GetxController {
  BuildContext? context;

  final RxInt loadingProgess = 0.obs;
  final RxBool canGoBack = false.obs;
  final RxBool canGoForward = false.obs;
  final RxBool isBookmarked = false.obs;

  WebViewController webController = WebViewController();
  Future<void> _platformReady = Future<void>.value();

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
            _updateStatusBackForward();
          },
          onPageStarted: (String url) {
            loadingProgess.value = 0;
            dlog(
              '[WEBVIEW_DIAG][COMMON][PAGE_STARTED] '
              'page=${VcoreWebViewSupport.safePage(url)}',
            );
            _checkBookmark();
          },
          onPageFinished: (String url) async {
            await VcoreWebViewSupport.normalizeResponsiveLayout(
              webController,
              traceTag: 'COMMON',
            );

            loadingProgess.value = 100;
            dlog(
              '[WEBVIEW_DIAG][COMMON][PAGE_FINISHED] '
              'page=${VcoreWebViewSupport.safePage(url)}',
            );
            await _updateStatusBackForward();
          },
          onWebResourceError: (WebResourceError error) {
            dlog(
              '[WEBVIEW_DIAG][COMMON][RESOURCE_ERROR] '
              'code=${error.errorCode} description=${error.description}',
            );
          },
        ),
      );

    _platformReady = VcoreWebViewSupport.configurePlatform(
      webController,
      traceTag: 'COMMON',
    );
  }

  /// Chỉ tải URL hoặc HTML ban đầu một lần.
  Future<void> loadInitialContent({String? url, String? html}) async {
    if (_hasLoadedInitialContent) return;

    final bool hasUrl = url != null && url.trim().isNotEmpty;
    final bool hasHtml = html != null && html.trim().isNotEmpty;
    if (!hasUrl && !hasHtml) return;

    _hasLoadedInitialContent = true;
    await _platformReady;

    if (hasUrl) {
      loadUrl(url!);
      return;
    }
    loadHtml(html!);
  }

  void loadUrl(String url) {
    webController.loadRequest(Uri.parse(url));
  }

  void loadHtml(String html) {
    webController.loadHtmlString(html);
  }

  Future<void> goBack() async {
    final bool canBack = await webController.canGoBack();
    if (!canBack) return;
    await webController.goBack();
    await _updateStatusBackForward();
  }

  Future<void> goForward() async {
    final bool canForward = await webController.canGoForward();
    if (!canForward) return;
    await webController.goForward();
    await _updateStatusBackForward();
  }

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

    dlog('[WEBVIEW_DIAG][BOOKMARK] titleLength=${title.length} page=${VcoreWebViewSupport.safePage(url)}');

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
