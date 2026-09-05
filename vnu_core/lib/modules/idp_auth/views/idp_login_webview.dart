import 'package:flutter/material.dart';
import 'package:vnu_core/modules/idp_auth/config/idp_auth_config.dart';
import 'package:vnu_core/widgets/vcore_floating_back_bubble.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IdpWebLoginResult {
  const IdpWebLoginResult._({this.ticket, this.error});

  final String? ticket;
  final String? error;

  bool get isSuccess => ticket != null && ticket!.isNotEmpty;

  factory IdpWebLoginResult.success(String ticket) {
    return IdpWebLoginResult._(ticket: ticket);
  }

  factory IdpWebLoginResult.failure(String error) {
    return IdpWebLoginResult._(error: error);
  }
}

class IdpLoginWebView extends StatefulWidget {
  const IdpLoginWebView({
    super.key,
    required this.startUri,
    this.forceCloseWebViewOnBack = false,
  });

  final Uri startUri;

  /// true: nút bubble luôn đóng hẳn màn IDP WebView, không đi history.
  /// false: còn history thì Back; hết history thì đổi X đỏ và đóng màn.
  final bool forceCloseWebViewOnBack;

  @override
  State<IdpLoginWebView> createState() => _IdpLoginWebViewState();
}

class _IdpLoginWebViewState extends State<IdpLoginWebView> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _finished = false;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            _refreshBackState();
          },
          onPageFinished: (_) {
            _refreshBackState();
          },
          onNavigationRequest: (NavigationRequest request) {
            final Uri? uri = Uri.tryParse(request.url);
            if (uri != null && IdpAuthConfig.isAppCallback(uri)) {
              _finishFromCallback(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(widget.startUri);
  }

  void _finishFromCallback(Uri uri) {
    if (_finished || !mounted) return;
    _finished = true;

    final String ticket = uri.queryParameters['ticket']?.trim() ?? '';
    if (ticket.isNotEmpty) {
      Navigator.of(context).pop(IdpWebLoginResult.success(ticket));
      return;
    }

    final String error = uri.queryParameters['error_description']?.trim() ??
        uri.queryParameters['error']?.trim() ??
        'Đăng nhập IdP không thành công.';

    Navigator.of(context).pop(IdpWebLoginResult.failure(error));
  }

  Future<void> _refreshBackState() async {
    final bool canGoBack = await _controller.canGoBack();
    if (!mounted || canGoBack == _canGoBack) return;

    setState(() {
      _canGoBack = canGoBack;
    });
  }

  Future<void> _closeWebView() async {
    if (!mounted) return;

    /// Pop route IDP WebView. Sau khi route bị pop, State.dispose() giải phóng
    /// WebView; không tiếp tục lần ngược history nội bộ nữa.
    Navigator.of(context).pop();
  }

  Future<void> _back() async {
    if (widget.forceCloseWebViewOnBack) {
      await _closeWebView();
      return;
    }

    if (await _controller.canGoBack()) {
      await _controller.goBack();
      await _refreshBackState();
      return;
    }

    await _closeWebView();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _back();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: <Widget>[
            /// Bỏ hoàn toàn AppBar/navbar cũ. Chỉ giữ SafeArea hệ thống.
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: <Widget>[
                    if (_progress < 100)
                      LinearProgressIndicator(value: _progress / 100.0),
                    Expanded(
                      child: WebViewWidget(controller: _controller),
                    ),
                  ],
                ),
              ),
            ),

            /// Dùng đúng component bubble đã tách từ chức năng Nhà trọ.
            Positioned.fill(
              child: VcoreFloatingBackBubble(
                isCloseAction:
                    widget.forceCloseWebViewOnBack || !_canGoBack,
                onBack: _back,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
