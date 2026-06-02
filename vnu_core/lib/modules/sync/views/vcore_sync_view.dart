import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VcoreSyncView extends StatefulWidget {
  const VcoreSyncView({super.key});

  static const String syncUrl =
      'https://residence.sohatech.vn/residence/ktx/sync';

  @override
  State<VcoreSyncView> createState() => _VcoreSyncViewState();
}

class _VcoreSyncViewState extends State<VcoreSyncView> {
  late final WebViewController _webController;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'SyncBridge',
        onMessageReceived: (message) {
          _appendResult('SyncBridge', message.message);
        },
      )
      ..addJavaScriptChannel(
        'SyncResult',
        onMessageReceived: (message) {
          _appendResult('SyncResult', message.message);
        },
      )
      ..addJavaScriptChannel(
        'ResidenceSync',
        onMessageReceived: (message) {
          _appendResult('ResidenceSync', message.message);
        },
      )
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: (message) {
          _appendResult('Flutter', message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _loadingProgress = progress);
          },
          onPageStarted: (url) {
            _appendResult('Đang tải', url);
          },
          onPageFinished: (url) async {
            _appendResult('Đã tải xong', url);
            await _installBridgeScript();
            await _readBodyText();
          },
          onNavigationRequest: (request) {
            _appendResult('Điều hướng', request.url);

            if (_isCallbackUrl(request.url)) {
              _appendResult('Callback URL', request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            _appendResult(
              'Lỗi WebView',
              '${error.errorCode}: ${error.description}',
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(VcoreSyncView.syncUrl));
  }

  Future<void> _installBridgeScript() async {
    await _webController.runJavaScript('''
      (function () {
        if (window.__oneVnuSyncBridgeInstalled) return;
        window.__oneVnuSyncBridgeInstalled = true;

        function send(source, data) {
          try {
            var payload = JSON.stringify({
              source: source,
              data: data
            });
            SyncBridge.postMessage(payload);
          } catch (error) {
            try {
              SyncBridge.postMessage(String(data));
            } catch (_) {}
          }
        }

        window.oneVnuSyncResult = function (data) {
          send('oneVnuSyncResult', data);
        };

        window.syncResult = window.oneVnuSyncResult;
        window.sendSyncResult = window.oneVnuSyncResult;

        window.addEventListener('message', function (event) {
          send('window.message', event.data);
        });
      })();
    ''');
  }

  Future<void> _readBodyText() async {
    try {
      final result = await _webController.runJavaScriptReturningResult(
        'document.body ? document.body.innerText : ""',
      );

      final text = _normalizeJavaScriptResult(result).trim();

      if (text.isNotEmpty) {
        _appendResult('Nội dung trang', text);
      }
    } catch (error) {
      _appendResult(
        'Không đọc được nội dung trang',
        error.toString(),
      );
    }
  }

  String _normalizeJavaScriptResult(Object? result) {
    if (result == null) return '';

    final value = result.toString();

    if (value == 'null' || value == 'undefined') {
      return '';
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is String) {
        return decoded;
      }

      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return value;
    }
  }

  bool _isCallbackUrl(String url) {
    final uri = Uri.tryParse(url);

    if (uri == null || !uri.hasScheme) {
      return false;
    }

    return !const {'http', 'https', 'about', 'data'}.contains(uri.scheme);
  }

  void _appendResult(String source, String value) {
    debugPrint('[$source] ${value.trim()}');
  }

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Đồng bộ',
      showBackButton: true,
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          onPressed: () => _webController.reload(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: Column(
        children: [
          if (_loadingProgress < 100)
            LinearProgressIndicator(
              value: _loadingProgress / 100,
              minHeight: 2,
              color: AppColors.brandGreen,
              backgroundColor: AppColors.homeSeparator,
            ),
          Expanded(
            child: WebViewWidget(
              controller: _webController,
            ),
          ),
        ],
      ),
    );
  }
}