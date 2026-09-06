import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Lớp hiển thị WebView dùng chung.
///
/// Mặc định WebView chiếm toàn bộ màn hình, không tự thêm SafeArea/header.
/// Riêng [isMotel] giữ header/safe-area riêng cho Phòng trọ. Các thông số
/// header và margin đều được truyền từ [VcoreBrowserView], nên từng màn có thể
/// chỉnh mà không phải copy/paste lại layout WebView.
class VcoreWebViewSurface extends StatelessWidget {
  const VcoreWebViewSurface({
    super.key,
    required this.controller,
    this.isMotel = false,
    this.headerExtent = 15,
    this.headerColor = Colors.white,
    this.backgroundColor = Colors.white,
    this.headerMargin = EdgeInsets.zero,
    this.webViewMargin = const EdgeInsets.all(8),
    this.dividerColor = const Color(0xFFE5E7EB),
  });

  final WebViewController controller;
  final bool isMotel;

  /// Chiều cao phần header, không bao gồm status-bar SafeArea.
  final double headerExtent;

  /// Màu nền status-bar/header khi [isMotel] = true.
  final Color headerColor;

  /// Màu nền vùng bao quanh WebView/margin bên dưới header.
  final Color backgroundColor;

  /// Margin bên ngoài chính phần header.
  final EdgeInsets headerMargin;

  /// Margin bao quanh vùng WebView phía dưới header.
  final EdgeInsets webViewMargin;

  /// Màu đường phân cách header/WebView. Dùng transparent để ẩn.
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    if (!isMotel) {
      return SizedBox.expand(
        child: WebViewWidget(controller: controller),
      );
    }

    final EdgeInsets safePadding = MediaQuery.paddingOf(context);
    final double headerTop = safePadding.top + headerMargin.top;
    final double headerBottom = headerTop + headerExtent + headerMargin.bottom;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ColoredBox(color: backgroundColor),

        // Status-bar SafeArea dùng cùng màu header.
        if (safePadding.top > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: safePadding.top,
            child: ColoredBox(color: headerColor),
          ),

        // Header riêng của Phòng trọ.
        Positioned(
          top: headerTop,
          left: headerMargin.left,
          right: headerMargin.right,
          height: headerExtent,
          child: ColoredBox(color: headerColor),
        ),

        Positioned(
          top: headerBottom - 1,
          left: 0,
          right: 0,
          height: 1,
          child: ColoredBox(color: dividerColor),
        ),

        Positioned(
          top: headerBottom + webViewMargin.top,
          left: webViewMargin.left,
          right: webViewMargin.right,
          bottom: webViewMargin.bottom,
          child: WebViewWidget(controller: controller),
        ),
      ],
    );
  }
}
