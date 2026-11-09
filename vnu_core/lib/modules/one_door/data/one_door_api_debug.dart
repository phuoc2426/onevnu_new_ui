import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Local-only, bounded network trace for the One Door module.
/// The icon is available with flutter run (debug) or with an explicit
/// --dart-define=ONEVNU_ONE_DOOR_API_DEBUG=true in a test build.
/// It never persists logs, passwords, JWTs, cookies or other auth secrets.
class OneDoorApiDebug {
  OneDoorApiDebug._();
  static final OneDoorApiDebug instance = OneDoorApiDebug._();
  static const bool _optIn = bool.fromEnvironment(
    'ONEVNU_ONE_DOOR_API_DEBUG', defaultValue: false);
  static bool get available => false; // V29.2: API Debug disabled

  final ValueNotifier<int> revision = ValueNotifier<int>(0);
  final List<OneDoorApiTrace> _entries = <OneDoorApiTrace>[];
  int _nextId = 0;
  bool enabled = false;

  List<OneDoorApiTrace> get entries => List<OneDoorApiTrace>.unmodifiable(
    _entries.reversed);

  void setEnabled(bool value) {
    if (!available) return;
    enabled = value;
    revision.value++;
  }

  void clear() {
    _entries.clear();
    revision.value++;
  }

  void attach(Dio dio, String client) {
    if (!available) return;
    if (dio.interceptors.any((it) => it is _OneDoorApiTraceInterceptor)) {
      return;
    }
    dio.interceptors.add(_OneDoorApiTraceInterceptor(this, client));
  }

  void note(String title, Map<String, dynamic> details) {
    if (!available || !enabled) return;
    _entries.add(OneDoorApiTrace(
      id: ++_nextId,
      time: DateTime.now(),
      client: 'ONEVNU',
      method: 'INFO',
      path: title,
      request: _pretty(details),
      started: DateTime.now(),
    )..status = 'LOCAL');
    _trim();
    revision.value++;
  }

  int start(String client, RequestOptions options) {
    if (!available || !enabled) return -1;
    final id = ++_nextId;
    final query = options.queryParameters.isEmpty ? '' :
      '?${_pretty(options.queryParameters).replaceAll('\n', ' ')}';
    _entries.add(OneDoorApiTrace(
      id: id,
      time: DateTime.now(),
      started: DateTime.now(),
      client: client,
      method: options.method.toUpperCase(),
      path: '${options.uri.path}$query',
      request: _pretty(options.data),
    ));
    _trim();
    revision.value++;
    return id;
  }

  void finish(int id, {int? status, dynamic data, String? error,
      bool binary = false, String? contentType}) {
    if (id < 0) return;
    for (var i = _entries.length - 1; i >= 0; i--) {
      final entry = _entries[i];
      if (entry.id != id) continue;
      entry.status = status == null ? 'ERROR' : '$status';
      entry.durationMs = DateTime.now().difference(entry.started).inMilliseconds;
      entry.response = binary ? _binarySummary(data, contentType) : _pretty(data);
      entry.error = error == null ? '' : _cleanString(error);
      revision.value++;
      return;
    }
  }

  String _binarySummary(dynamic data, String? type) {
    if (data is List<int> && (type ?? '').toLowerCase().contains('json')) {
      try { return _pretty(jsonDecode(utf8.decode(data))); } catch (_) {}
    }
    final length = data is List<int> ? data.length :
      (data is List ? data.length : 0);
    final head = data is List && data.length >= 4 ?
      data.take(4).map((e) => (e is int ? e : 0)
        .toRadixString(16).padLeft(2, '0')).join(' ') : 'unknown';
    return 'Binary response: $length bytes\nContent-Type: '
      '${type ?? '(not specified)'}\nSignature: $head';
  }

  void _trim() {
    while (_entries.length > 80) {
      _entries.removeAt(0);
    }
  }

  static bool _secret(String name) {
    final key = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    return key.contains('token') || key.contains('password') ||
      key.contains('matkhau') || key.contains('authorization') ||
      key.contains('cookie') || key.contains('secret') ||
      key.contains('apikey') || key == 'jwt' || key == 'refresh' ||
      key == 'accesshash' || key == 'devicetoken';
  }

  static bool _personal(String name) {
    final key = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    return key == 'email' || key == 'hoten' || key == 'masv' ||
      key == 'manguoidung' || key == 'masinhvien' || key == 'cccd' ||
      key == 'sodienthoai' || key == 'phonenumber' ||
      key == 'ngaysinh' || key == 'hktt' || key == 'diachi' ||
      key == 'userName'.toLowerCase();
  }

  String _cleanString(String value) {
    return value
      .replaceAll(RegExp(r'Bearer\s+\S+', caseSensitive: false),
        'Bearer [REDACTED]')
      .replaceAll(RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
        '[JWT REDACTED]');
  }

  dynamic _clean(dynamic data, [int depth = 0]) {
    if (depth >= 7) return '[MAX DEPTH]';
    if (data == null) return null;
    if (data is FormData) {
      final values = <String, dynamic>{};
      for (final item in data.fields) {
        if (_secret(item.key)) {
          values[item.key] = '[REDACTED]';
          continue;
        }
        if (item.key == 'GiaTriBieuMau') {
          try {
            values[item.key] = _clean(jsonDecode(item.value), depth + 1);
          } catch (_) {
            values[item.key] = '[INVALID JSON; ${item.value.length} chars]';
          }
        } else {
          values[item.key] = _clean(<String, dynamic>{item.key: item.value},
            depth + 1)[item.key];
        }
      }
      values['__files'] = data.files.map((e) => <String, dynamic>{
        'paperId': e.key,
        'length': e.value.length,
        'filename': '[file]'
      }).toList();
      return values;
    }
    if (data is Map) {
      final map = <String, dynamic>{};
      var count = 0;
      for (final item in data.entries) {
        if (++count > 90) {
          map['...'] = '[MORE FIELDS]';
          break;
        }
        final key = item.key.toString();
        if (_secret(key) || _personal(key)) {
          map[key] = '[REDACTED]';
        } else if (key.toLowerCase() == 'yeucau') {
          final raw = item.value?.toString() ?? '';
          map[key] = <String, dynamic>{
            'present': raw.trim().isNotEmpty,
            'characters': raw.length,
            // The actual request string is intentionally NOT retained in logs.
          };
        } else {
          map[key] = _clean(item.value, depth + 1);
        }
      }
      return map;
    }
    if (data is List<int>) return '[BINARY ${data.length} bytes]';
    if (data is List) {
      return data.take(25).map((e) => _clean(e, depth + 1)).toList();
    }
    if (data is String) {
      final output = _cleanString(data);
      return output.length > 1200 ? '${output.substring(0, 1200)}…' : output;
    }
    if (data is num || data is bool) return data;
    if (data is MultipartFile) return '[file ${data.length} bytes]';
    return '[${data.runtimeType}]';
  }

  String _pretty(dynamic data) {
    if (data == null) return '(none)';
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final raw = encoder.convert(_clean(data));
      return raw.length <= 10000 ? raw :
        '${raw.substring(0, 10000)}\n[TRUNCATED]';
    } catch (_) {
      return '[UNSUPPORTED ${data.runtimeType}]';
    }
  }

  String export() => entries.map((e) => e.export()).join('\n\n');
}

class OneDoorApiTrace {
  OneDoorApiTrace({
    required this.id, required this.time, required this.started,
    required this.client, required this.method, required this.path,
    required this.request,
  });
  final int id;
  final DateTime time;
  final DateTime started;
  final String client;
  final String method;
  final String path;
  final String request;
  String response = '';
  String error = '';
  String status = '...';
  int? durationMs;

  String export() {
    final ts = '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:'
      '${time.second.toString().padLeft(2, '0')}';
    return '$ts [$client] $method $path\nHTTP: $status'
      '${durationMs == null ? '' : ' - ${durationMs} ms'}'
      '\nREQUEST:\n$request\nRESPONSE:\n$response'
      '${error.isEmpty ? '' : '\nERROR: $error'}';
  }
}

class _OneDoorApiTraceInterceptor extends Interceptor {
  _OneDoorApiTraceInterceptor(this.store, this.client);
  final OneDoorApiDebug store;
  final String client;
  static const String _traceKey = '_oneDoorTraceId';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final id = store.start(client, options);
    if (id >= 0) options.extra[_traceKey] = id;
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response,
      ResponseInterceptorHandler handler) {
    final id = response.requestOptions.extra[_traceKey];
    if (id is int) {
      store.finish(id, status: response.statusCode,
        data: response.data,
        binary: response.requestOptions.responseType == ResponseType.bytes,
        contentType: response.headers.value(Headers.contentTypeHeader));
    }
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    final id = error.requestOptions.extra[_traceKey];
    if (id is int) {
      store.finish(id,
        status: error.response?.statusCode,
        data: error.response?.data,
        binary: error.requestOptions.responseType == ResponseType.bytes,
        contentType: error.response?.headers.value(Headers.contentTypeHeader),
        error: '${error.type}: ${error.message ?? ''}');
    }
    handler.next(error);
  }
}

/// A regular full-screen diagnostics page, not an AlertDialog or debug overlay.
class OneDoorApiDebugPage extends StatelessWidget {
  const OneDoorApiDebugPage({super.key});

  static const Color _green = Color(0xFF038141);

  @override
  Widget build(BuildContext context) {
    final store = OneDoorApiDebug.instance;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('API Debug · Một cửa',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sao chép log đã che dữ liệu nhạy cảm',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: store.export()));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép log an toàn.')));
              }
            },
            icon: const Icon(Icons.copy_all_outlined)),
          IconButton(
            tooltip: 'Xóa log',
            onPressed: store.clear,
            icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: store.revision,
        builder: (context, _, child) {
          final records = store.entries;
          return Column(children: <Widget>[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE6EBE8)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Chẩn đoán request/response của API Một cửa',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  const Text('Log chỉ lưu trong bộ nhớ ứng dụng. Token, mật khẩu '
                    'và mã định danh được che; YeuCau hiển thị độ dài '
                    'thay vì toàn bộ nội dung.',
                    style: TextStyle(fontSize: 12, height: 1.4)),
                  SwitchListTile.adaptive(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ghi log API',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${records.length} sự kiện gần nhất'),
                    activeColor: _green,
                    value: store.enabled,
                    onChanged: store.setEnabled,
                  ),
                  const Text('Để kiểm tra {YeuCau}: xem POST /da-dien, '
                    'trường YeuCau.present và YeuCau.characters; '
                    'so sánh với nội dung đã nhập ở Bước 1.',
                    style: TextStyle(fontSize: 12, color: _green)),
                ],
              ),
            ),
            Expanded(child: records.isEmpty
              ? const Center(child: Text('Chưa có request. Hãy mở một thủ tục '
                  'hoặc tải lại trang.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final item = records[index];
                    final failed = item.status == 'ERROR' ||
                      (int.tryParse(item.status) ?? 200) >= 400;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFE6EBE8))),
                      child: ExpansionTile(
                        key: ValueKey<int>(item.id),
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                        title: Text('${item.method}   ${item.status}',
                          style: TextStyle(fontWeight: FontWeight.w700,
                            color: failed ? const Color(0xFFBB3E34) : _green)),
                        subtitle: Text('${item.path}\n'
                          '${item.client}${item.durationMs == null ? '' :
                             ' · ${item.durationMs} ms'}',
                          maxLines: 3, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                        childrenPadding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                        children: <Widget>[
                          Row(mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              TextButton.icon(
                                onPressed: () => Clipboard.setData(
                                  ClipboardData(text: item.export())),
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy request')),
                            ]),
                          const Align(alignment: Alignment.centerLeft,
                            child: Text('REQUEST',
                              style: TextStyle(fontWeight: FontWeight.w700,
                                fontSize: 12))),
                          _payload(item.request),
                          const SizedBox(height: 10),
                          const Align(alignment: Alignment.centerLeft,
                            child: Text('RESPONSE',
                              style: TextStyle(fontWeight: FontWeight.w700,
                                fontSize: 12))),
                          _payload(item.response.isEmpty ? '(pending)' : item.response),
                          if (item.error.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(item.error, style: const TextStyle(
                              color: Color(0xFFBB3E34), fontSize: 12)),
                          ],
                        ],
                      ),
                    );
                  },
                )),
          ]);
        },
      ),
    );
  }

  static Widget _payload(String value) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: const Color(0xFFF0F4F2),
      borderRadius: BorderRadius.circular(8)),
    child: SelectableText(value,
      style: const TextStyle(fontSize: 11.5, height: 1.4,
        fontFamily: 'monospace')),
  );
}
