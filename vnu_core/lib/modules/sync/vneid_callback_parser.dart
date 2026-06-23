
class VneidCallbackData {
  final String transactionCode;
  final String? result;

  const VneidCallbackData({
    required this.transactionCode,
    this.result,
  });
}

VneidCallbackData? parseVneidCallback(Uri uri) {
  if (!isVneidCallbackUri(uri)) return null;

  final rawTransitionCode =
      uri.queryParameters['transitionCode'] ??
          uri.queryParameters['transition_code'] ??
          uri.queryParameters['transactionCode'];

  if (rawTransitionCode == null || rawTransitionCode.trim().isEmpty) {
    return null;
  }

  final decodedTransitionCode = Uri.decodeComponent(rawTransitionCode).trim();

  if (decodedTransitionCode.isEmpty) {
    return null;
  }

  final separatorIndex = decodedTransitionCode.indexOf('|');

  if (separatorIndex == -1) {
    return VneidCallbackData(
      transactionCode: decodedTransitionCode,
      result: null,
    );
  }

  final transactionCode =
  decodedTransitionCode.substring(0, separatorIndex).trim();

  final resultCode =
  decodedTransitionCode.substring(separatorIndex + 1).trim();

  if (transactionCode.isEmpty) {
    return null;
  }
  final String parseUriLog = 'VNeID parse uri: $uri';
  final String queryParametersLog =
      'VNeID queryParameters: ${uri.queryParameters}';
  final String rawTransitionCodeLog =
      'VNeID rawTransitionCode: $rawTransitionCode';
  final String decodedTransitionCodeLog =
      'VNeID decodedTransitionCode: $decodedTransitionCode';
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