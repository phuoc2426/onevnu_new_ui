import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:vnu_core/globals.dart';

import '../common/events.dart';
import 'services_url.dart';

/// Cho phép tắt body log khi chạy debug:
///
/// flutter run --dart-define=HTTP_BODY_LOG=false
const bool _enableHttpBodyLog = bool.fromEnvironment(
  'HTTP_BODY_LOG',
  defaultValue: true,
);

// ignore: camel_case_types
class DioOptions {
  Dio createDio(String baseUrl) {
    final Dio client = Dio()
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(seconds: 60)
      ..interceptors.add(ApiInterceptor());

    // Chỉ log HTTP trong Debug.
    // Profile/Release không gắn logger để tránh lộ dữ liệu người dùng.
    if (kDebugMode) {
      client.interceptors.add(
        TalkerDioLogger(
          talker: Globals().talker,
          settings: const TalkerDioLoggerSettings(
            // Không in headers vì có thể chứa Bearer token.
            printRequestHeaders: false,
            printResponseHeaders: false,

            // In request body của POST/PUT/PATCH.
            // GET thông thường không có request body.
            printRequestData: _enableHttpBodyLog,

            // In JSON response body trong Debug.
            printResponseData: _enableHttpBodyLog,
            printResponseMessage: true,
          ),
        ),
      );
    }

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
      return handler.next(err);
    }

    final connectivityResult =
        (await Connectivity().checkConnectivity()).firstOrNull;

    final customError = CustomDioError(
      requestOptions: err.requestOptions,
      type: err.type,
      response: err.response,
    );

    if (connectivityResult == ConnectivityResult.none) {
      customError.error =
      'Không có kết nối Internet. '
          'Vui lòng kiểm tra lại kết nối Internet.';
      customError.isNetworkConnected = false;
    } else if (err.response != null &&
        err.response?.data is Map) {
      final Map responseData =
      err.response!.data as Map;

      if (responseData.containsKey('message')) {
        customError.error =
            responseData['message'] ?? '';
      }
    } else {
      customError.error = '';

      if (customError.type ==
          DioExceptionType.receiveTimeout ||
          customError.type ==
              DioExceptionType.connectionTimeout) {
        customError.error =
        'Không thể kết nối tới máy chủ. '
            'Vui lòng kiểm tra lại kết nối Internet.';
      } else if (err.type ==
          DioExceptionType.badResponse) {
        switch (err.response?.statusCode) {
          case 401:
            customError.error =
            'Trang truy cập bị từ chối.';
            break;
          case 404:
            customError.error =
            'Trang truy cập không tồn tại.';
            break;
        }
      }
    }

    super.onError(customError, handler);
  }
}

class CustomDioError extends DioException {
  @override
  final RequestOptions requestOptions;

  @override
  final Response? response;

  @override
  final DioExceptionType type;

  @override
  dynamic error;

  bool isNetworkConnected;

  CustomDioError({
    required this.requestOptions,
    this.response,
    required this.type,
    this.error,
    this.isNetworkConnected = true,
  }) : super(
    requestOptions: requestOptions,
    response: response,
    type: type,
    error: error,
  );

  @override
  String toString() {
    return error.toString();
  }
}
