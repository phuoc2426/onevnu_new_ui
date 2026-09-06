import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
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
/// The raw login secret is kept only in memory and never persisted.
class IdpDeviceBindingService {
  IdpDeviceBindingService._internal();

  static final IdpDeviceBindingService _instance =
      IdpDeviceBindingService._internal();

  factory IdpDeviceBindingService() => _instance;

  static const String _deviceKey = 'kIdpAppInstanceId';
  final Random _random = Random.secure();

  /// Stable random app-install id used by P0 binding/P1 device context.
  /// It is not an IMEI, serial number or advertising identifier.
  Future<String> currentDeviceId() => _getOrCreateDeviceId();

  Future<IdpLoginBinding> createLoginBinding() async {
    final String deviceId = await _getOrCreateDeviceId();
    final String secret = _randomUrlSafe(32);
    final String challenge = base64Url
        .encode(sha256.convert(utf8.encode(secret)).bytes)
        .replaceAll('=', '');
    return IdpLoginBinding(
      deviceId: deviceId,
      secret: secret,
      challenge: challenge,
    );
  }

  Future<String> _getOrCreateDeviceId() async {
    final DataRepository repository = DataRepository();
    final String current =
        (await repository.getSecureSaveKey(_deviceKey))?.trim() ?? '';
    if (current.isNotEmpty) return current;

    final String created = 'onevnu_${_randomUrlSafe(24)}';
    await repository.saveSecureKey(_deviceKey, created);
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
}
