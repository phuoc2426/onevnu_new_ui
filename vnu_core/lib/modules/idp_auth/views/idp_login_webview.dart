import 'package:flutter/material.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/modules/browser/vcore_webview_support.dart';
import 'package:vnu_core/modules/browser/widgets/vcore_webview_surface.dart';
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
  final bool forceCloseWebViewOnBack;

  @override
  State<IdpLoginWebView> createState() => _IdpLoginWebViewState();
}

class _IdpLoginWebViewState extends State<IdpLoginWebView> {
  late final WebViewController _controller;
  final Stopwatch _lifetimeWatch = Stopwatch()..start();
  Stopwatch _pageWatch = Stopwatch();
  int _progress = 0;
  int _lastProgressBucket = -1;
  bool _finished = false;
  bool _canGoBack = false;
  bool _layoutLogged = false;

  @override
  void initState() {
    super.initState();
    _trace(
      'INIT',
      'startPage=${VcoreWebViewSupport.safePage(widget.startUri.toString())} '
      'forceClose=${widget.forceCloseWebViewOnBack}',
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            final int bucket = (progress ~/ 25).clamp(0, 4).toInt();
            if (bucket != _lastProgressBucket || progress == 100) {
              _lastProgressBucket = bucket;
              _trace(
                'PROGRESS',
                'progress=$progress pageElapsedMs=${_pageWatch.elapsedMilliseconds}',
              );
            }
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (String url) {
            _pageWatch = Stopwatch()..start();
            _lastProgressBucket = -1;
            _trace(
              'PAGE_STARTED',
              'page=${VcoreWebViewSupport.safePage(url)} '
              'lifetimeMs=${_lifetimeWatch.elapsedMilliseconds}',
            );
            _refreshBackState();
          },
          onPageFinished: (String url) async {
            _trace(
              'PAGE_FINISHED_RAW',
              'page=${VcoreWebViewSupport.safePage(url)} '
              'pageElapsedMs=${_pageWatch.elapsedMilliseconds}',
            );
            await VcoreWebViewSupport.normalizeResponsiveLayout(
              _controller,
              traceTag: 'IDP',
            );
            _trace(
              'PAGE_FINISHED_NORMALIZED',
              'page=${VcoreWebViewSupport.safePage(url)} '
              'pageElapsedMs=${_pageWatch.elapsedMilliseconds} '
              'lifetimeMs=${_lifetimeWatch.elapsedMilliseconds}',
            );
            await _refreshBackState();
          },
          onWebResourceError: (WebResourceError error) {
            _trace(
              'RESOURCE_ERROR',
              'code=${error.errorCode} '
              'isMainFrame=${error.isForMainFrame} '
              'description=${error.description}',
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            final Uri? uri = Uri.tryParse(request.url);
            final bool callback =
                uri != null && IdpAuthConfig.isAppCallback(uri);
            _trace(
              'NAVIGATION',
              'page=${VcoreWebViewSupport.safePage(request.url)} '
              'mainFrame=${request.isMainFrame} callback=$callback',
            );
            if (callback) {
              _trace('APP_CALLBACK', 'received=true');
              _finishFromCallback(uri!);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _layoutLogged) return;
      _layoutLogged = true;
      final MediaQueryData mq = MediaQuery.of(context);
      _trace(
        'FLUTTER_VIEWPORT',
        'logicalWidth=${mq.size.width.toStringAsFixed(2)} '
        'logicalHeight=${mq.size.height.toStringAsFixed(2)} '
        'devicePixelRatio=${mq.devicePixelRatio.toStringAsFixed(2)} '
        'padding=${mq.padding} viewInsets=${mq.viewInsets}',
      );
    });

    _loadStartUri();
  }

  Future<void> _loadStartUri() async {
    final Stopwatch watch = Stopwatch()..start();
    try {
      await VcoreWebViewSupport.configurePlatform(
        _controller,
        traceTag: 'IDP',
      );
      _trace('PLATFORM_READY', 'elapsedMs=${watch.elapsedMilliseconds}');
      _trace(
        'LOAD_START_URI',
        'page=${VcoreWebViewSupport.safePage(widget.startUri.toString())}',
      );
      await _controller.loadRequest(widget.startUri);
      _trace('LOAD_REQUEST_DISPATCHED', 'elapsedMs=${watch.elapsedMilliseconds}');
    } catch (error, stackTrace) {
      _trace(
        'LOAD_ERROR',
        'type=${error.runtimeType} message=$error '
        'elapsedMs=${watch.elapsedMilliseconds}',
      );
      _traceStack(stackTrace);
      rethrow;
    }
  }

  void _finishFromCallback(Uri uri) {
    if (_finished || !mounted) {
      _trace('CALLBACK_IGNORED', 'finished=$_finished mounted=$mounted');
      return;
    }
    _finished = true;

    final String ticket = uri.queryParameters['ticket']?.trim() ?? '';
    if (ticket.isNotEmpty) {
      _trace(
        'CALLBACK_RESULT',
        'success=true ticketLength=${ticket.length} '
        'lifetimeMs=${_lifetimeWatch.elapsedMilliseconds}',
      );
      Navigator.of(context).pop(IdpWebLoginResult.success(ticket));
      return;
    }

    final String error = uri.queryParameters['error_description']?.trim() ??
        uri.queryParameters['error']?.trim() ??
        'Đăng nhập IdP không thành công.';

    _trace(
      'CALLBACK_RESULT',
      'success=false errorLength=${error.length} '
      'lifetimeMs=${_lifetimeWatch.elapsedMilliseconds}',
    );
    Navigator.of(context).pop(IdpWebLoginResult.failure(error));
  }

  Future<void> _refreshBackState() async {
    try {
      final bool canGoBack = await _controller.canGoBack();
      _trace('BACK_STATE', 'canGoBack=$canGoBack previous=$_canGoBack');
      if (!mounted || canGoBack == _canGoBack) return;
      setState(() => _canGoBack = canGoBack);
    } catch (error, stackTrace) {
      _trace('BACK_STATE_ERROR', 'type=${error.runtimeType} message=$error');
      _traceStack(stackTrace);
    }
  }

  Future<void> _closeWebView() async {
    _trace('CLOSE', 'lifetimeMs=${_lifetimeWatch.elapsedMilliseconds}');
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _back() async {
    _trace(
      'BACK_ACTION',
      'forceClose=${widget.forceCloseWebViewOnBack} canGoBack=$_canGoBack',
    );
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
  void dispose() {
    _trace(
      'DISPOSE',
      'finished=$_finished lifetimeMs=${_lifetimeWatch.elapsedMilliseconds}',
    );
    super.dispose();
  }

  void _trace(String event, String details) {
    dlog('[WEBVIEW_DIAG][IDP][$event] $details', wrapWidth: 2000);
  }

  void _traceStack(StackTrace stackTrace) {
    final String compact = stackTrace
        .toString()
        .split('\n')
        .where((String line) => line.trim().isNotEmpty)
        .take(8)
        .join(' | ');
    dlog('[WEBVIEW_DIAG][IDP][STACK] $compact', wrapWidth: 2000);
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
            Positioned.fill(
              child: VcoreWebViewSurface(controller: _controller),
            ),
            if (_progress < 100)
              Positioned(
                top: MediaQuery.paddingOf(context).top,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress <= 0 ? null : _progress / 100.0,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                ),
              ),
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
