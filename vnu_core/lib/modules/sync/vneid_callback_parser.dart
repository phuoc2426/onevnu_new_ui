import 'package:vnu_core/common/log.dart';

class VneidCallbackData {
  final String transactionCode;
  final String? result;

  const VneidCallbackData({required this.transactionCode, this.result});
}

VneidCallbackData? parseVneidCallback(Uri uri) {
  if (!isVneidCallbackUri(uri)) return null;

  final rawTransitionCode =
      uri.queryParameters['transitionCode'] ??
      uri.queryParameters['transition_code'] ??
      uri.queryParameters['transactionCode'];

  if (rawTransitionCode == null || rawTransitionCode.trim().isEmpty) {
    logWarning('VNeID rawTransitionCode is missing or empty.');
    return null;
  }

  logInfo('VNeID rawTransitionCode: $rawTransitionCode');

  // First decode
  var decoded = Uri.decodeComponent(rawTransitionCode).trim();
  logInfo('VNeID first decodedTransitionCode: $decoded');

  // If still contains percent-encoded pipe, decode again
  if (decoded.contains('%7C')) {
    decoded = Uri.decodeComponent(decoded).trim();
    logInfo('VNeID second decodedTransitionCode (double decode): $decoded');
  }

  if (decoded.isEmpty) {
    logWarning('VNeID decoded transition code is empty after decoding.');
    return null;
  }

  final separatorIndex = decoded.indexOf('|');

  if (separatorIndex == -1) {
    return VneidCallbackData(transactionCode: decoded, result: null);
  }

  final transactionCode = decoded.substring(0, separatorIndex).trim();
  final resultCode = decoded.substring(separatorIndex + 1).trim();

  if (transactionCode.isEmpty) {
    logWarning('VNeID transactionCode is empty after parsing.');
    return null;
  }

  logInfo('VNeID parsed transactionCode: $transactionCode');
  logInfo('VNeID parsed resultCode: $resultCode');

  return VneidCallbackData(
    transactionCode: transactionCode,
    result: resultCode.isEmpty ? null : resultCode,
  );
}

bool isVneidCallbackUri(Uri uri) {
  return uri.scheme == 'https' &&
      uri.host == 'onevnu-admin.vnu.edu.vn' &&
      uri.path.startsWith('/vneid/callback');
}
