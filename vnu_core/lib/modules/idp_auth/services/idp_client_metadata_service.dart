import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:vnu_core/modules/idp_auth/services/idp_device_binding_service.dart';

/// Privacy-preserving client metadata for auth/QR compatibility diagnostics.
/// No IMEI, hardware serial or advertising identifier is collected.
class IdpClientMetadataService {
  IdpClientMetadataService._internal();

  static final IdpClientMetadataService _instance =
      IdpClientMetadataService._internal();

  factory IdpClientMetadataService() => _instance;

  Future<Map<String, dynamic>> headers({
    String? requestId,
    String? flowId,
  }) async {
    final String deviceId =
        await IdpDeviceBindingService().currentDeviceId();
    final PackageInfo package = await PackageInfo.fromPlatform();

    return <String, dynamic>{
      if (requestId != null && requestId.trim().isNotEmpty)
        'X-Request-Id': requestId.trim(),
      if (flowId != null && flowId.trim().isNotEmpty)
        'X-OneVNU-Flow-Id': flowId.trim(),
      'X-OneVNU-Device-Id': deviceId,
      'X-OneVNU-App-Version': '${package.version}+${package.buildNumber}',
      'X-OneVNU-Platform': Platform.operatingSystem,
      'X-OneVNU-Auth-Protocol': '2',
    };
  }
}
