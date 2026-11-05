import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// DEBUG-ONLY collector for the VNU SSO login flow.
///
/// IMPORTANT:
/// - This intentionally shows/copies RAW callback tickets and ONEVNU tokens.
/// - It is enabled only in Flutter debug builds (`kDebugMode`).
/// - VNU IDP access/id/refresh tokens are backend-owned and never reach Flutter
///   in the current architecture, so this screen can only show what Flutter
///   actually receives: authorization URL, app callback, one-time ticket, and
///   the ONEVNU `/api/auth/idp/redeem` response.
class IdpVisibleDebugService {
  IdpVisibleDebugService._internal();

  static final IdpVisibleDebugService _instance =
      IdpVisibleDebugService._internal();

  factory IdpVisibleDebugService() => _instance;

  static const bool _visibleDebugFlag = bool.fromEnvironment(
    'ONEVNU_IDP_VISIBLE_DEBUG',
    defaultValue: true,
  );

  final List<_IdpDebugEntry> _entries = <_IdpDebugEntry>[];

  bool _shown = false;
  String _flowId = 'none';

  bool get enabled => kDebugMode && _visibleDebugFlag;

  void start({
    required String flowId,
    required bool forceLogin,
    required String browserMode,
  }) {
    if (!enabled) return;
    _entries.clear();
    _shown = false;
    _flowId = flowId;

    record(
      'FLOW START',
      <String, dynamic>{
        'flowId': flowId,
        'forceLogin': forceLogin,
        'browserMode': browserMode,
        'startedAt': DateTime.now().toIso8601String(),
      },
    );

    record(
      'VNU IDP TOKEN NOTE',
      <String, dynamic>{
        'idpAccessTokenOnFlutter': false,
        'idpIdTokenOnFlutter': false,
        'idpRefreshTokenOnFlutter': false,
        'reason':
            'PKCE verifier + VNU IDP tokens remain on backend. Flutter receives a one-time callback ticket, then ONEVNU access/refresh tokens from /api/auth/idp/redeem.',
      },
    );
  }

  void recordAuthorizationUri(Uri uri) {
    record(
      'AUTHORIZATION URL (RAW - SENSITIVE)',
      <String, dynamic>{
        'uri': uri.toString(),
        'scheme': uri.scheme,
        'host': uri.host,
        'path': uri.path,
        'queryParameters': uri.queryParameters,
      },
    );
  }

  void recordCallback(Uri uri) {
    final String ticket = uri.queryParameters['ticket']?.trim() ?? '';
    final String error = uri.queryParameters['error']?.trim() ?? '';
    final String errorDescription =
        uri.queryParameters['error_description']?.trim() ?? '';

    record(
      'APP CALLBACK (RAW - SENSITIVE)',
      <String, dynamic>{
        'uri': uri.toString(),
        'scheme': uri.scheme,
        'host': uri.host,
        'path': uri.path,
        'queryKeys': uri.queryParameters.keys.toList(),
        'queryParameters': uri.queryParameters,
        'ticketPresent': ticket.isNotEmpty,
        'ticketLength': ticket.length,
        'ticket': ticket,
        'error': error,
        'errorDescription': errorDescription,
      },
    );
  }

  void recordRedeemResponse({
    required int? statusCode,
    required Map<String, dynamic> body,
    String? requestId,
  }) {
    record(
      'REDEEM RESPONSE BODY (RAW - SENSITIVE)',
      <String, dynamic>{
        'statusCode': statusCode,
        'requestId': requestId,
        'body': body,
      },
    );

    final String? accessToken = _extractToken(body, const <String>[
      'access_token',
      'accessToken',
      'token',
      'data.access_token',
      'data.accessToken',
      'data.token',
      'result.access_token',
      'result.token',
    ]);
    final String? refreshToken = _extractToken(body, const <String>[
      'refresh_token',
      'refreshToken',
      'data.refresh_token',
      'data.refreshToken',
      'result.refresh_token',
      'result.refreshToken',
    ]);

    recordToken('ONEVNU ACCESS TOKEN', accessToken);
    recordToken('ONEVNU REFRESH TOKEN', refreshToken);
  }

  void recordToken(String label, String? token) {
    final String value = token?.trim() ?? '';
    if (value.isEmpty) {
      record(label, <String, dynamic>{'present': false});
      return;
    }

    final Map<String, dynamic> decoded = <String, dynamic>{
      'present': true,
      'length': value.length,
      'raw': value,
    };

    final List<String> parts = value.split('.');
    if (parts.length == 3) {
      decoded['jwtLike'] = true;
      decoded['header'] = _decodeJwtPart(parts[0]);
      decoded['payload'] = _decodeJwtPart(parts[1]);
      decoded['signatureLength'] = parts[2].length;
    } else {
      decoded['jwtLike'] = false;
      decoded['note'] = 'Token is opaque/non-JWT; no local payload to decode.';
    }

    record('$label (RAW - SENSITIVE)', decoded);
  }

  void recordError(
    String stage,
    Object error, {
    StackTrace? stackTrace,
    dynamic responseBody,
    int? statusCode,
  }) {
    record(
      'ERROR: $stage',
      <String, dynamic>{
        'type': error.runtimeType.toString(),
        'message': error.toString(),
        'statusCode': statusCode,
        if (responseBody != null) 'responseBody': responseBody,
        if (stackTrace != null)
          'stack': stackTrace
              .toString()
              .split('\n')
              .where((String line) => line.trim().isNotEmpty)
              .take(12)
              .toList(),
      },
    );
  }

  void record(String title, dynamic value) {
    if (!enabled) return;
    final _IdpDebugEntry entry = _IdpDebugEntry(
      time: DateTime.now(),
      title: title,
      value: _pretty(value),
    );
    _entries.add(entry);
    _rawDebugPrint(entry.asText());
  }

  Future<void> show(
    BuildContext context, {
    required String title,
    bool force = false,
  }) async {
    if (!enabled || (_shown && !force)) return;
    _shown = true;

    final String dump = dumpText();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          final Size size = MediaQuery.sizeOf(dialogContext);
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: size.width * 0.92,
              height: size.height * 0.68,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'DEBUG BUILD ONLY - dữ liệu bên dưới có thể chứa ticket và token đầy đủ. Không chụp/gửi log này ra ngoài môi trường kiểm thử.',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          dump,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: dump));
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Đã copy toàn bộ SSO debug.')),
                  );
                },
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy tất cả'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
    } catch (error, stackTrace) {
      _rawDebugPrint(
        'VISIBLE DEBUG DIALOG ERROR: $error\n$stackTrace',
      );
    }
  }

  String dumpText() {
    final StringBuffer buffer = StringBuffer()
      ..writeln('ONEVNU VNU SSO DEBUG')
      ..writeln('flowId=$_flowId')
      ..writeln('generatedAt=${DateTime.now().toIso8601String()}')
      ..writeln('entries=${_entries.length}')
      ..writeln('============================================================');

    for (final _IdpDebugEntry entry in _entries) {
      buffer
        ..writeln(entry.asText())
        ..writeln('------------------------------------------------------------');
    }
    return buffer.toString();
  }

  dynamic _decodeJwtPart(String value) {
    try {
      final String normalized = base64Url.normalize(value);
      final String decoded = utf8.decode(base64Url.decode(normalized));
      final dynamic json = jsonDecode(decoded);
      return json;
    } catch (error) {
      return <String, dynamic>{
        'decodeError': error.toString(),
      };
    }
  }

  String? _extractToken(Map<String, dynamic> json, List<String> paths) {
    for (final String path in paths) {
      dynamic current = json;
      for (final String part in path.split('.')) {
        if (current is Map && current.containsKey(part)) {
          current = current[part];
        } else {
          current = null;
          break;
        }
      }
      if (current is String && current.trim().isNotEmpty) {
        return current.trim();
      }
    }
    return null;
  }

  String _pretty(dynamic value) {
    if (value is String) return value;
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  void _rawDebugPrint(String value) {
    if (!enabled) return;
    const int chunkSize = 3000;
    final String prefix = '[IDP_VISIBLE_DEBUG] ';
    for (int offset = 0; offset < value.length; offset += chunkSize) {
      final int end = (offset + chunkSize < value.length)
          ? offset + chunkSize
          : value.length;
      // Intentionally bypasses the normal log sanitizer in DEBUG builds so the
      // developer can inspect the exact callback/tokens requested for diagnosis.
      debugPrint('$prefix${value.substring(offset, end)}', wrapWidth: 4000);
    }
  }
}

class _IdpDebugEntry {
  const _IdpDebugEntry({
    required this.time,
    required this.title,
    required this.value,
  });

  final DateTime time;
  final String title;
  final String value;

  String asText() {
    return '[${time.toIso8601String()}] $title\n$value';
  }
}
