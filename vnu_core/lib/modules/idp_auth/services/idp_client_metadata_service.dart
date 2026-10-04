import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:vnu_core/common/log.dart';
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
    final Stopwatch watch = Stopwatch()..start();
    _trace(
      'BEGIN',
      'requestIdPresent=${(requestId ?? '').trim().isNotEmpty} '
          'flowIdPresent=${(flowId ?? '').trim().isNotEmpty}',
    );

    try {
      _trace('DEVICE_ID_BEGIN', '');
      final String deviceId =
          await IdpDeviceBindingService().currentDeviceId();
      _trace(
        'DEVICE_ID_DONE',
        'elapsedMs=${watch.elapsedMilliseconds} length=${deviceId.length}',
      );

      _trace('PACKAGE_INFO_BEGIN', '');
      final PackageInfo package = await PackageInfo.fromPlatform();
      _trace(
        'PACKAGE_INFO_DONE',
        'elapsedMs=${watch.elapsedMilliseconds} '
            'versionPresent=${package.version.trim().isNotEmpty} '
            'buildPresent=${package.buildNumber.trim().isNotEmpty}',
      );

      final Map<String, dynamic> result = <String, dynamic>{
        if (requestId != null && requestId.trim().isNotEmpty)
          'X-Request-Id': requestId.trim(),
        if (flowId != null && flowId.trim().isNotEmpty)
          'X-OneVNU-Flow-Id': flowId.trim(),
        'X-OneVNU-Device-Id': deviceId,
        'X-OneVNU-App-Version': '${package.version}+${package.buildNumber}',
        'X-OneVNU-Platform': Platform.operatingSystem,
        'X-OneVNU-Auth-Protocol': '2',
      };

      _trace(
        'DONE',
        'elapsedMs=${watch.elapsedMilliseconds} headerCount=${result.length} '
            'platform=${Platform.operatingSystem}',
      );
      return result;
    } catch (error, stackTrace) {
      _trace(
        'ERROR',
        'elapsedMs=${watch.elapsedMilliseconds} type=${error.runtimeType} '
            'message=$error',
      );
      _traceStack(stackTrace);
      rethrow;
    }
  }

  void _trace(String event, String details) {
    final String suffix = details.trim().isEmpty ? '' : ' $details';
    dlog(
      '[P0_DIAG][IDP_METADATA][$event]$suffix',
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
    dlog('[P0_DIAG][IDP_METADATA][STACK] $compact', wrapWidth: 1000);
  }
}
