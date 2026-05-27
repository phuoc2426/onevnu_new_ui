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

  @override
  void onInit() {
    super.onInit();

    initWebview();
  }

  initWebview() {
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColor.bgColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
            logSuccess(progress.toString());
            loadingProgess.value = progress;
            _updateStatusBackForward();
          },
          onPageStarted: (String url) {
            logSuccess('Start load -> $url');
            _checkBookmark();
          },
          onPageFinished: (String url) {
            logSuccess('Finished load -> $url');
          },
          onWebResourceError: (WebResourceError error) {},
          // onNavigationRequest: (NavigationRequest request) {
          //   if (request.url.startsWith('https://www.youtube.com/')) {
          //     return NavigationDecision.prevent;
          //   }
          //   return NavigationDecision.navigate;
          // },
        ),
      );
  }

  loadUrl(String url) {
    webController.loadRequest(Uri.parse(url));
  }

  loadHtml(String html) {
    webController.loadHtmlString(html);
  }

  //
  goBack() async {
    if (await webController.canGoBack()) {
      webController.goBack();
    }
  }

  goForward() async {
    if (await webController.canGoForward()) {
      webController.goForward();
    }
  }

  createBookMark() async {
    String title = await webController.getTitle() ?? '';
    String url = await webController.currentUrl() ?? '';
    logSuccess(title);
    logSuccess(url);
    if (title.isEmpty || url.isEmpty) {
      snackBarWarning('Không tìm thấy thông tin liên kết.');
      return;
    }

    try {
      Utils.showProgress(context);
      var response = await ApiRepository().createLienKetDanhDau(title, url);

      Utils.dismissProgress(context);
      snackBarSuccess('Tạo liên kết đánh dấu thành công');
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }

  //Private
  _updateStatusBackForward() async {
    canGoBack.value = await webController.canGoBack();
    canGoForward.value = await webController.canGoForward();
  }

  _checkBookmark() {
    //
  }
}
