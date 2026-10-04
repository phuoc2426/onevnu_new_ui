import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

class NetworkDiagnosticEvent {
  NetworkDiagnosticEvent({
    required this.timestamp,
    required this.scope,
    required this.stage,
    required this.level,
    required this.message,
    this.details,
  });

  final DateTime timestamp;
  final String scope;
  final String stage;
  final String level;
  final String message;
  final dynamic details;

  factory NetworkDiagnosticEvent.fromMap(Map<dynamic, dynamic> raw) {
    final int millis = (raw['timestamp'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    return NetworkDiagnosticEvent(
      timestamp: DateTime.fromMillisecondsSinceEpoch(millis),
      scope: '${raw['scope'] ?? 'UNKNOWN'}',
      stage: '${raw['stage'] ?? 'UNKNOWN'}',
      level: '${raw['level'] ?? 'INFO'}',
      message: '${raw['message'] ?? ''}',
      details: raw['details'],
    );
  }

  String toDisplayLine() {
    final String hh = timestamp.hour.toString().padLeft(2, '0');
    final String mm = timestamp.minute.toString().padLeft(2, '0');
    final String ss = timestamp.second.toString().padLeft(2, '0');
    final String ms = timestamp.millisecond.toString().padLeft(3, '0');
    final String head = '[$hh:$mm:$ss.$ms] [$level] $scope/$stage';
    if (details == null) return '$head\n$message';
    return '$head\n$message\n${_pretty(details)}';
  }

  static String _pretty(dynamic value) {
    try {
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(_normalize(value));
    } catch (_) {
      return '$value';
    }
  }

  static dynamic _normalize(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (dynamic key, dynamic item) =>
            MapEntry<String, dynamic>('$key', _normalize(item)),
      );
    }
    if (value is Iterable) {
      return value.map<dynamic>(_normalize).toList();
    }
    return value;
  }
}

class NetworkDiagnosticService {
  NetworkDiagnosticService._();

  static final NetworkDiagnosticService instance = NetworkDiagnosticService._();

  static const MethodChannel _method = MethodChannel('onevnu/network_diagnostic');
  static const EventChannel _events =
      EventChannel('onevnu/network_diagnostic_events');

  Stream<NetworkDiagnosticEvent>? _eventStream;

  Stream<NetworkDiagnosticEvent> get events {
    return _eventStream ??= _events
        .receiveBroadcastStream()
        .map<NetworkDiagnosticEvent>((dynamic raw) {
      if (raw is Map) return NetworkDiagnosticEvent.fromMap(raw);
      return NetworkDiagnosticEvent(
        timestamp: DateTime.now(),
        scope: 'NATIVE',
        stage: 'RAW',
        level: 'INFO',
        message: '$raw',
      );
    });
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final dynamic raw = await _method.invokeMethod<dynamic>('getDeviceInfo');
      return _map(raw);
    } on PlatformException catch (e) {
      return <String, dynamic>{
        'error': '${e.code}: ${e.message ?? ''}',
      };
    }
  }

  Future<Map<String, dynamic>> inspectTrustStore() async {
    try {
      final dynamic raw =
          await _method.invokeMethod<dynamic>('inspectTrustStore');
      return _map(raw);
    } on PlatformException catch (e) {
      return <String, dynamic>{
        'success': false,
        'error': '${e.code}: ${e.message ?? ''}',
      };
    }
  }

  Future<Map<String, dynamic>> runNativeDiagnostics(List<String> urls) async {
    try {
      final dynamic raw = await _method.invokeMethod<dynamic>(
        'runDiagnostics',
        <String, dynamic>{'urls': urls},
      );
      return _map(raw);
    } on PlatformException catch (e) {
      return <String, dynamic>{
        'started': false,
        'error': '${e.code}: ${e.message ?? ''}',
      };
    }
  }

  Future<void> stopNativeDiagnostics() async {
    try {
      await _method.invokeMethod<dynamic>('stopDiagnostics');
    } catch (_) {}
  }

  Future<List<NetworkDiagnosticEvent>> runDartHttpClientDiagnostics(
    List<String> urls,
  ) async {
    final List<NetworkDiagnosticEvent> result = <NetworkDiagnosticEvent>[];

    for (final String rawUrl in urls) {
      final Uri? uri = Uri.tryParse(rawUrl);
      if (uri == null || uri.scheme.toLowerCase() != 'https' || uri.host.isEmpty) {
        result.add(_dartEvent(
          'DART_HTTP',
          'INVALID_URL',
          'ERROR',
          'URL không hợp lệ hoặc không phải HTTPS: ${_safeUrlText(rawUrl)}',
        ));
        continue;
      }

      result.add(_dartEvent(
        'DART_HTTP',
        'BEGIN',
        'INFO',
        _safeUri(uri),
      ));

      final HttpClient client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..idleTimeout = const Duration(seconds: 5);
      final Stopwatch stopwatch = Stopwatch()..start();

      try {
        final HttpClientRequest request = await client.getUrl(uri);
        request.headers.set(HttpHeaders.acceptHeader, '*/*');
        request.headers.set(
          HttpHeaders.userAgentHeader,
          'OneVNU-DartNetworkDiagnostic/1.0',
        );
        final HttpClientResponse response =
            await request.close().timeout(const Duration(seconds: 12));

        final X509Certificate? certificate = response.certificate;
        final String certInfo = certificate == null
            ? 'peerCertificate=null'
            : 'subject=${certificate.subject}; issuer=${certificate.issuer}; '
                'notBefore=${certificate.startValidity.toUtc().toIso8601String()}; '
                'notAfter=${certificate.endValidity.toUtc().toIso8601String()}';

        result.add(_dartEvent(
          'DART_HTTP',
          'HTTP_REACHED',
          'OK',
          'HTTP ${response.statusCode}; elapsedMs=${stopwatch.elapsedMilliseconds}; $certInfo',
        ));
        await response.drain<void>();
      } on HandshakeException catch (e) {
        result.add(_dartEvent(
          'DART_HTTP',
          'HANDSHAKE_FAILED',
          'ERROR',
          _errorWithCause(e),
        ));
      } on TlsException catch (e) {
        result.add(_dartEvent(
          'DART_HTTP',
          'TLS_FAILED',
          'ERROR',
          _errorWithCause(e),
        ));
      } on SocketException catch (e) {
        result.add(_dartEvent(
          'DART_HTTP',
          'SOCKET_FAILED',
          'ERROR',
          '${e.runtimeType}: ${_safeText(e.message)}; '
              'osError=${e.osError?.errorCode}:${_safeText(e.osError?.message)}',
        ));
      } on TimeoutException catch (e) {
        result.add(_dartEvent(
          'DART_HTTP',
          'TIMEOUT',
          'ERROR',
          '${e.runtimeType}: ${_safeText(e.message)}',
        ));
      } catch (e) {
        result.add(_dartEvent(
          'DART_HTTP',
          'FAILED',
          'ERROR',
          '${e.runtimeType}: ${_safeText('$e')}',
        ));
      } finally {
        stopwatch.stop();
        client.close(force: true);
      }
    }

    return result;
  }

  static Map<String, dynamic> _map(dynamic raw) {
    if (raw is! Map) return <String, dynamic>{};
    return raw.map<String, dynamic>(
      (dynamic key, dynamic value) => MapEntry<String, dynamic>('$key', value),
    );
  }

  static NetworkDiagnosticEvent _dartEvent(
    String scope,
    String stage,
    String level,
    String message,
  ) {
    return NetworkDiagnosticEvent(
      timestamp: DateTime.now(),
      scope: scope,
      stage: stage,
      level: level,
      message: _safeText(message),
    );
  }

  static String _errorWithCause(Object error) {
    return '${error.runtimeType}: ${_safeText('$error')}';
  }

  static String _safeUri(Uri uri) {
    final String port = uri.hasPort && uri.port != 443 ? ':${uri.port}' : '';
    final String path = uri.path.isEmpty ? '/' : uri.path;
    return '${uri.scheme}://${uri.host}$port$path';
  }

  static String _safeUrlText(String value) {
    final Uri? uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return _safeText(value);
    return _safeUri(uri);
  }
  static String _safeText(String? value) {
    String output = value ?? '';
    output = output.replaceAllMapped(
      RegExp(
        r'(access_token|refresh_token|authorization|password|ticket|code|state|nonce|bindingsecret)=?[^\s&]*',
        caseSensitive: false,
      ),
          (Match match) => '${match.group(1)}=<redacted>',
    );
    if (output.length > 4000) return output.substring(0, 4000);
    return output;
  }
}
