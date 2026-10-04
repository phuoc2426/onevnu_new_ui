import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vnu_core/modules/browser/models/vcore_browser_mode.dart';
import 'package:vnu_core/modules/browser/views/vcore_browser_view.dart';

/// Điểm mở URL/HTML dùng chung của OneVNU.
///
/// Mặc định giữ nguyên hành vi cũ: mở [VcoreBrowserView].
/// Các luồng xác thực như IDP có thể chọn [VcoreBrowserMode.customTab]
/// để không phụ thuộc Android System WebView.
class VcoreBrowserLauncher {
  const VcoreBrowserLauncher._();

  static Future<bool> open({
    required String title,
    String? url,
    String? html,
    VcoreBrowserMode mode = VcoreBrowserMode.inAppWebView,
    bool fallbackToExternalBrowser = true,
    bool showBrowserTitle = true,
    bool useFloatingBackButton = true,
    bool isMotel = false,
    bool forceCloseWebViewOnBack = false,
    double webViewHeaderExtent = 15,
    Color webViewHeaderColor = Colors.white,
    Color webViewBackgroundColor = Colors.white,
    EdgeInsets webViewHeaderMargin = EdgeInsets.zero,
    EdgeInsets webViewContentMargin = const EdgeInsets.all(8),
    Color webViewHeaderDividerColor = const Color(0xFFE5E7EB),
  }) async {
    final String rawUrl = url?.trim() ?? '';

    if (mode == VcoreBrowserMode.inAppWebView) {
      if (rawUrl.isEmpty && (html == null || html.trim().isEmpty)) {
        throw ArgumentError('Phải truyền url hoặc html khi mở WebView.');
      }

      await Get.to(
        () => VcoreBrowserView(
          title: title,
          url: rawUrl.isEmpty ? null : rawUrl,
          html: html,
          useFloatingBackButton: useFloatingBackButton,
          isMotel: isMotel,
          forceCloseWebViewOnBack: forceCloseWebViewOnBack,
          webViewHeaderExtent: webViewHeaderExtent,
          webViewHeaderColor: webViewHeaderColor,
          webViewBackgroundColor: webViewBackgroundColor,
          webViewHeaderMargin: webViewHeaderMargin,
          webViewContentMargin: webViewContentMargin,
          webViewHeaderDividerColor: webViewHeaderDividerColor,
        ),
      );
      return true;
    }

    if (rawUrl.isEmpty) {
      throw ArgumentError('Phải truyền url khi mở Custom Tab/trình duyệt ngoài.');
    }

    final Uri? uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        (uri.scheme.toLowerCase() != 'https' &&
            uri.scheme.toLowerCase() != 'http')) {
      throw ArgumentError('URL không hợp lệ hoặc không phải HTTP/HTTPS.');
    }

    switch (mode) {
      case VcoreBrowserMode.inAppWebView:
        return true;
      case VcoreBrowserMode.customTab:
        return _openCustomTab(
          uri,
          fallbackToExternalBrowser: fallbackToExternalBrowser,
          showBrowserTitle: showBrowserTitle,
        );
      case VcoreBrowserMode.externalBrowser:
        return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<bool> _openCustomTab(
    Uri uri, {
    required bool fallbackToExternalBrowser,
    required bool showBrowserTitle,
  }) async {
    try {
      final bool supported =
          await supportsLaunchMode(LaunchMode.inAppBrowserView);

      if (supported) {
        final bool opened = await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
          browserConfiguration: BrowserConfiguration(
            showTitle: showBrowserTitle,
          ),
        );
        if (opened) return true;
      }
    } catch (_) {
      if (!fallbackToExternalBrowser) rethrow;
    }

    if (!fallbackToExternalBrowser) return false;

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
