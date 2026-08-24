import 'dart:developer' as developer;

import 'package:flutter/material.dart';

final RegExp _bearerPattern = RegExp(
  r'(Bearer\s+)[A-Za-z0-9\-._~+/]+=*',
  caseSensitive: false,
);

final RegExp _jsonSecretPattern = RegExp(
  r'("(?:password|oldPassword|newPassword|reNewPassword|accessToken|access_token|refreshToken|refresh_token|authorization|token|otp|secret|cccd|identityNo|identity_no)"\s*:\s*")[^"]*(")',
  caseSensitive: false,
);

final RegExp _plainSecretPattern = RegExp(
  r'((?:password|oldPassword|newPassword|reNewPassword|accessToken|access_token|refreshToken|refresh_token|authorization|token|otp|secret|cccd|identityNo|identity_no)\s*[=:]\s*)[^\s,;}&]+',
  caseSensitive: false,
);

String sanitizeLogMessage(String value) {
  var sanitized = value.replaceAllMapped(
    _bearerPattern,
    (match) => '${match.group(1)}[REDACTED]',
  );
  sanitized = sanitized.replaceAllMapped(
    _jsonSecretPattern,
    (match) => '${match.group(1)}[REDACTED]${match.group(2)}',
  );
  sanitized = sanitized.replaceAllMapped(
    _plainSecretPattern,
    (match) => '${match.group(1)}[REDACTED]',
  );
  return sanitized;
}

void dlog(String? object, {int? wrapWidth}) {
  debugPrint(
    object == null ? null : sanitizeLogMessage(object),
    wrapWidth: wrapWidth,
  );
}

void logInfo(String msg) {
  developer.log('\x1B[36m${sanitizeLogMessage(msg)}\x1B[0m');
}

void logSuccess(String msg) {
  developer.log('\x1B[32m${sanitizeLogMessage(msg)}\x1B[0m');
}

void logWarning(String msg) {
  developer.log('\x1B[33m${sanitizeLogMessage(msg)}\x1B[0m');
}

void logError(String msg) {
  developer.log('\x1B[31m${sanitizeLogMessage(msg)}\x1B[0m');
}
