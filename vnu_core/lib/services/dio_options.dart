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
    var customError =
        CustomDioError(requestOptions: err.requestOptions, type: err.type);

    if (connectivityResult == ConnectivityResult.none) {
      customError.error =
          "Không có kết nối Internet. Vui lòng kiểm tra lại kết nối Internet.";
      customError.isNetworkConnected = false;
    } else if (err.response != null && err.response?.data is Map) {
      if ((err.response?.data as Map).containsKey("message")) {
        customError.error = (err.response?.data as Map)['message'] ?? '';
      }
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
