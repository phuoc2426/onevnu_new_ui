class VneidCallbackData {
  final String transactionCode;
  final String result;

  const VneidCallbackData({
    required this.transactionCode,
    required this.result,
  });
}

VneidCallbackData? parseVneidCallback(Uri uri) {
  if (!isVneidCallbackUri(uri)) return null;

  final rawTransitionCode =
      uri.queryParameters['transition_code'] ??
          uri.queryParameters['transitionCode'] ??
          uri.queryParameters['transactionCode'] ??
          uri.queryParameters['transitionCode'];

  if (rawTransitionCode == null || rawTransitionCode.trim().isEmpty) {
    return null;
  }

  final decodedTransitionCode = Uri.decodeComponent(rawTransitionCode).trim();

  final separatorIndex = decodedTransitionCode.indexOf('|');

  if (separatorIndex == -1) {
    return null;
  }

  final transactionCode =
  decodedTransitionCode.substring(0, separatorIndex).trim();

  final resultCode =
  decodedTransitionCode.substring(separatorIndex + 1).trim();

  if (transactionCode.isEmpty || resultCode.isEmpty) {
    return null;
  }

  return VneidCallbackData(
    transactionCode: transactionCode,
    result: resultCode,
  );
}

bool isVneidCallbackUri(Uri uri) {
  return uri.scheme == 'https' &&
      uri.host == 'onevnu-admin.vnu.edu.vn' &&
      uri.path.startsWith('/vneid/callback');
}