import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/repository/data_repository.dart';

class IdpLoginBinding {
  const IdpLoginBinding({
    required this.deviceId,
    required this.secret,
    required this.challenge,
  });

  final String deviceId;
  final String secret;
  final String challenge;
}

/// Stable random install identifier + per-login possession secret.
/// The raw login secret is kept only in memory and never persisted/logged.
class IdpDeviceBindingService {
  IdpDeviceBindingService._internal();

  static final IdpDeviceBindingService _instance =
      IdpDeviceBindingService._internal();

  factory IdpDeviceBindingService() => _instance;

  static const String _deviceKey = 'kIdpAppInstanceId';
  final Random _random = Random.secure();

  /// Stable random app-install id used by P0 binding/P1 device context.
  /// It is not an IMEI, serial number or advertising identifier.
  Future<String> currentDeviceId() async {
    final Stopwatch watch = Stopwatch()..start();
    _trace('CURRENT_DEVICE_ID_BEGIN', '');
    try {
      final String value = await _getOrCreateDeviceId();
      _trace(
        'CURRENT_DEVICE_ID_DONE',
        'elapsedMs=${watch.elapsedMilliseconds} length=${value.length}',
      );
      return value;
    } catch (error, stackTrace) {
      _trace(
        'CURRENT_DEVICE_ID_ERROR',
        'elapsedMs=${watch.elapsedMilliseconds} type=${error.runtimeType} '
            'message=$error',
      );
      _traceStack(stackTrace);
      rethrow;
    }
  }

  Future<IdpLoginBinding> createLoginBinding() async {
    final Stopwatch watch = Stopwatch()..start();
    _trace('CREATE_BINDING_BEGIN', '');
    try {
      final String deviceId = await _getOrCreateDeviceId();
      _trace(
        'DEVICE_ID_READY',
        'elapsedMs=${watch.elapsedMilliseconds} length=${deviceId.length}',
      );

      // Do not log the secret or challenge contents.
      final String secret = _randomUrlSafe(32);
      final String challenge = base64Url
          .encode(sha256.convert(utf8.encode(secret)).bytes)
          .replaceAll('=', '');

      _trace(
        'CREATE_BINDING_DONE',
        'elapsedMs=${watch.elapsedMilliseconds} '
            'deviceIdLength=${deviceId.length} '
            'challengeLength=${challenge.length}',
      );
      return IdpLoginBinding(
        deviceId: deviceId,
        secret: secret,
        challenge: challenge,
      );
    } catch (error, stackTrace) {
      _trace(
        'CREATE_BINDING_ERROR',
        'elapsedMs=${watch.elapsedMilliseconds} type=${error.runtimeType} '
            'message=$error',
      );
      _traceStack(stackTrace);
      rethrow;
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    final DataRepository repository = DataRepository();

    _trace('SECURE_STORAGE_READ_BEGIN', 'key=$_deviceKey');
    final String current =
        (await repository.getSecureSaveKey(_deviceKey))?.trim() ?? '';
    if (current.isNotEmpty) {
      _trace(
        'SECURE_STORAGE_READ_DONE',
        'existing=true length=${current.length}',
      );
      return current;
    }

    _trace('SECURE_STORAGE_READ_DONE', 'existing=false');
    final String created = 'onevnu_${_randomUrlSafe(24)}';
    _trace(
      'SECURE_STORAGE_WRITE_BEGIN',
      'key=$_deviceKey length=${created.length}',
    );
    await repository.saveSecureKey(_deviceKey, created);
    _trace('SECURE_STORAGE_WRITE_DONE', 'key=$_deviceKey');
    return created;
  }

  String _randomUrlSafe(int byteLength) {
    final List<int> bytes = List<int>.generate(
      byteLength,
      (_) => _random.nextInt(256),
      growable: false,
    );
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  void _trace(String event, String details) {
    final String suffix = details.trim().isEmpty ? '' : ' $details';
    dlog(
      '[P0_DIAG][IDP_BINDING][$event]$suffix',
      wrapWidth: 1000,
    );
  }

  void _traceStack(StackTrace stackTrace) {
    final String compact = stackTrace
        .toString()
        .split('\n')
        .where((String line) => line.trim().isNotEmpty)
        .take(8)
        .join(' | ');
    dlog('[P0_DIAG][IDP_BINDING][STACK] $compact', wrapWidth: 1000);
  }
}
