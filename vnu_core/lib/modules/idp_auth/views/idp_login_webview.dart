import 'package:flutter/material.dart';
import 'package:vnu_core/modules/idp_auth/config/idp_auth_config.dart';
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
  const IdpLoginWebView({super.key, required this.startUri});

  final Uri startUri;

  @override
  State<IdpLoginWebView> createState() => _IdpLoginWebViewState();
}

class _IdpLoginWebViewState extends State<IdpLoginWebView> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _finished = false;

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

  Future<void> _back() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (mounted) Navigator.of(context).pop();
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
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF101936),
          elevation: 0,
          leading: IconButton(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          titleSpacing: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Đăng nhập VNU IDP',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 2),
              Text(
                'idp-test.vnu.edu.vn',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            if (_progress < 100)
              LinearProgressIndicator(value: _progress / 100.0),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
    );
  }
}
