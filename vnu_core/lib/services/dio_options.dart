import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:vnu_core/common/error/app_error.dart';
import 'package:vnu_core/common/error/app_error_mapper.dart';
import 'package:vnu_core/globals.dart';

import '../common/events.dart';
import 'services_url.dart';

/// Request/response bodies can contain personal data and credentials.
/// Keep them OFF by default, even in Debug. Enable only for a controlled
/// local session with:
/// flutter run --dart-define=HTTP_BODY_LOG=true
const bool _enableHttpBodyLog = bool.fromEnvironment(
  'HTTP_BODY_LOG',
  defaultValue: false,
);

// ignore: camel_case_types
class DioOptions {
  Dio createDio(String baseUrl) {
    final Dio client = Dio()
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(seconds: 60)
      ..interceptors.add(ApiInterceptor());

    if (kDebugMode) {
      client.interceptors.add(
        TalkerDioLogger(
          talker: Globals().talker,
          settings: TalkerDioLoggerSettings(
            printRequestHeaders: false,
            printResponseHeaders: false,
            printRequestData: _enableHttpBodyLog,
            printResponseData: _enableHttpBodyLog,
            printResponseMessage: true,
          ),
        ),
      );
    }

    // P0 security invariant: do not install badCertificateCallback here.
    return client;
  }
}

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final String token = Globals().token;

    if (token.isNotEmpty) {
      options.headers.addAll({
        'Authorization': 'Bearer $token',
      });
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.uri
            .toString()
            .contains(ServicesUrl().authenticate)) {
      globalEvent.fire(TokenExpiredEvent());
    }

    var isOffline = false;
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      isOffline = connectivityResults.contains(ConnectivityResult.none);
    } catch (_) {
      // Connectivity is only an additional signal. Dio error mapping must
      // still work if the plugin itself cannot answer.
    }

    final appError = AppErrorMapper.fromDio(
      err,
      isOffline: isOffline,
    );

    handler.next(
      AppDioException(
        original: err,
        appError: appError,
      ),
    );
  }
}

class AppDioException extends DioException {
  AppDioException({
    required DioException original,
    required this.appError,
  }) : super(
          requestOptions: original.requestOptions,
          response: original.response,
          type: original.type,
          error: appError,
          stackTrace: original.stackTrace,
          message: appError.userMessage,
        );

  final AppError appError;

  bool get isNetworkConnected => appError.type != AppErrorType.offline;

  @override
  String toString() => appError.userMessage;
}
