enum AppErrorType {
  offline,
  timeout,
  authentication,
  authorization,
  validation,
  notFound,
  conflict,
  business,
  server,
  data,
  platform,
  cancelled,
  unknown,
}

class AppError implements Exception {
  const AppError({
    required this.code,
    required this.type,
    required this.userMessage,
    this.requestId,
    this.canRetry = false,
    this.isSilent = false,
    this.cause,
    this.details,
  });

  final String code;
  final AppErrorType type;
  final String userMessage;
  final String? requestId;
  final bool canRetry;
  final bool isSilent;
  final Object? cause;
  final Object? details;

  bool get shouldReport => switch (type) {
        AppErrorType.server ||
        AppErrorType.data ||
        AppErrorType.platform ||
        AppErrorType.unknown => true,
        _ => false,
      };

  String get displayMessage {
    final supportCode = requestId?.trim() ?? '';
    if (supportCode.isEmpty) return userMessage;
    return '$userMessage\nMã hỗ trợ: $supportCode';
  }

  @override
  String toString() => userMessage;
}
