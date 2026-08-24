import 'dart:async';

import 'package:dio/dio.dart';

import '../log.dart';
import 'app_error.dart';

typedef AppErrorReportCallback = Future<void> Function(
  Object error,
  StackTrace stackTrace, {
  required bool fatal,
  Map<String, Object?>? context,
});

class AppErrorReporter {
  AppErrorReporter._();

  static AppErrorReportCallback? _callback;

  static void configure(AppErrorReportCallback? callback) {
    _callback = callback;
  }

  static Future<void> report(
    AppError error, {
    StackTrace? stackTrace,
    bool fatal = false,
    Map<String, Object?>? context,
  }) async {
    final mergedContext = <String, Object?>{
      'code': error.code,
      'type': error.type.name,
      'requestId': error.requestId,
      'canRetry': error.canRetry,
      ...?context,
    };

    final cause = error.cause;
    if (cause is DioException) {
      mergedContext.addAll(<String, Object?>{
        'httpMethod': cause.requestOptions.method,
        'httpPath': cause.requestOptions.uri.path,
        'httpStatus': cause.response?.statusCode,
      });
    }

    logError(
      '[APP_ERROR] code=${error.code} type=${error.type.name} '
      'requestId=${error.requestId ?? '-'} retry=${error.canRetry}',
    );

    if (!fatal && !error.shouldReport) return;

    final callback = _callback;
    if (callback == null) return;

    final reportObject = cause is DioException
        ? _SafeReportedException(
            '${error.code}: ${error.userMessage} '
            'status=${cause.response?.statusCode ?? '-'} '
            'path=${cause.requestOptions.uri.path}',
          )
        : (cause ?? _SafeReportedException(error.code));

    try {
      await callback(
        reportObject,
        stackTrace ?? StackTrace.current,
        fatal: fatal,
        context: mergedContext,
      );
    } catch (reportError) {
      logError('[APP_ERROR_REPORTER] report failed: $reportError');
    }
  }
}

class _SafeReportedException implements Exception {
  const _SafeReportedException(this.message);

  final String message;

  @override
  String toString() => message;
}
