import 'dart:async';

import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/modules/sync/vneid_callback_parser.dart';

class VneidDeepLinkEvent {
  final Uri uri;
  final VneidCallbackData? data;

  const VneidDeepLinkEvent({required this.uri, required this.data});
}

class VneidDeepLinkService {
  VneidDeepLinkService._internal();

  static final VneidDeepLinkService _singleton =
      VneidDeepLinkService._internal();

  factory VneidDeepLinkService() => _singleton;

  final StreamController<VneidDeepLinkEvent> _callbackController =
      StreamController<VneidDeepLinkEvent>.broadcast();

  VneidDeepLinkEvent? _latestCallback;
  bool isSyncViewVisible = false;

  Stream<VneidDeepLinkEvent> get callbackStream => _callbackController.stream;

  bool get hasPendingCallback => _latestCallback != null;

  VneidDeepLinkEvent? consumeLatestCallback() {
    final data = _latestCallback;
    _latestCallback = null;
    return data;
  }

  bool handleUri(Uri uri) {
    logInfo('🔧 VneidDeepLinkService.handleUri called');
    logInfo('🔧 VneidDeepLinkService.handleUri - URI: $uri');
    logInfo(
      '🔧 VneidDeepLinkService.handleUri - queryParameters: ${uri.queryParameters}',
    );

    if (!isVneidCallbackUri(uri)) {
      logWarning(
        '🔧 VneidDeepLinkService.handleUri - NOT a VNeID callback URI',
      );
      return false;
    }

    logInfo(
      '🔧 VneidDeepLinkService.handleUri - IS a VNeID callback URI, parsing...',
    );
    final data = parseVneidCallback(uri);
    if (data == null) {
      logWarning('VNeID callback data is invalid.');
    } else {
      logInfo('VNeID parsed transactionCode: ${data.transactionCode}');
      logInfo('VNeID parsed result: ${data.result}');
    }

    final event = VneidDeepLinkEvent(uri: uri, data: data);
    _latestCallback = event;
    _callbackController.add(event);
    return true;
  }
}
