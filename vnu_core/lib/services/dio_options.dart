import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:vnu_core/globals.dart';

import '../common/events.dart';
import 'services_url.dart';

// ignore: camel_case_types
class DioOptions {
  Dio createDio(String baseUrl) {
    Dio client = Dio()
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(seconds: 60) //60000
      ..interceptors.addAll([
        ApiInterceptor(),
        TalkerDioLogger(
          talker: Globals().talker,
          settings: const TalkerDioLoggerSettings(
            printRequestHeaders: true,
            printResponseMessage: true,
          ),
        ),
      ]);
    //TODO: - Migrade data
    if (client.httpClientAdapter is IOHttpClientAdapter) {
      (client.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
          (clients) {
        clients.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return clients;
      };
    }

    return client;
  }
}

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    String token = Globals().token;
    if (token.isNotEmpty) {
      options.headers.addAll({'Authorization': 'Bearer $token'});
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !(err.requestOptions.uri
            .toString()
            .contains(ServicesUrl().authenticate))) {
      globalEvent.fire(TokenExpiredEvent());
      return handler.next(err);
    }

    var connectivityResult =
        (await Connectivity().checkConnectivity()).firstOrNull;
    var customError = CustomDioError(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
    );

    if (connectivityResult == ConnectivityResult.none) {
      customError.error =
          "Không có kết nối Internet. Vui lòng kiểm tra lại kết nối Internet.";
      customError.isNetworkConnected = false;
    } else if (err.response?.statusCode == 413) {
      customError.error =
          "Tệp tải lên quá lớn. Vui lòng chọn file nhỏ hơn hoặc nén ảnh trước khi tải lên.";
    } else if (err.response != null && err.response?.data is Map) {
      customError.error = _formatApiError(err.response?.data as Map);
    } else {
      customError.error = "";
      if (customError.type == DioExceptionType.receiveTimeout ||
          customError.type == DioExceptionType.connectionTimeout) {
        customError.error =
            "Không thể kết nối tới máy chủ. Vui lòng kiểm tra lại kết nối Internet.";
      } else if (err.type == DioExceptionType.badResponse) {
        switch (err.response?.statusCode) {
          case 401:
            customError.error = "Trang truy cập bị từ chối.";
            break;
          case 404:
            customError.error = "Trang truy cập không tồn tại.";
            break;
        }
      }
    }
    super.onError(customError, handler);
  }

  String _formatApiError(Map data) {
    final parts = <String>[];
    final message = data['message']?.toString();
    if (message != null && message.trim().isNotEmpty) {
      parts.add(message.trim());
    }

    final errors = data['errors'];
    if (errors is Map) {
      errors.forEach((key, value) {
        if (value is Iterable) {
          for (final item in value) {
            final text = item?.toString().trim() ?? '';
            if (text.isNotEmpty) {
              parts.add('$key: $text');
            }
          }
        } else {
          final text = value?.toString().trim() ?? '';
          if (text.isNotEmpty) {
            parts.add('$key: $text');
          }
        }
      });
    } else if (errors is Iterable) {
      for (final item in errors) {
        if (item is Map) {
          final field = item['field']?.toString();
          final errorMessage = item['message']?.toString();
          if ((errorMessage ?? '').trim().isNotEmpty) {
            parts.add(
              (field ?? '').trim().isNotEmpty
                  ? '$field: ${errorMessage!.trim()}'
                  : errorMessage!.trim(),
            );
          }
        } else {
          final text = item?.toString().trim() ?? '';
          if (text.isNotEmpty) {
            parts.add(text);
          }
        }
      }
    }

    final traceId = data['traceId']?.toString();
    if (traceId != null && traceId.trim().isNotEmpty) {
      parts.add('traceId: ${traceId.trim()}');
    }

    return parts.isEmpty ? '' : parts.join('\n');
  }
}

class CustomDioError extends DioException {
  RequestOptions requestOptions;
  Response? response;
  DioExceptionType type;
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
            error: error);

  @override
  String toString() {
    //return (message ?? "") + (stackTrace ?? "").toString();
    return this.error.toString();
  }
}
