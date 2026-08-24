import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'app_error.dart';

class AppErrorMapper {
  AppErrorMapper._();

  static const String _genericMessage =
      'Hệ thống đang gặp sự cố. Vui lòng thử lại sau.';

  static AppError map(
    Object error, {
    StackTrace? stackTrace,
    String? fallbackMessage,
  }) {
    if (error is AppError) return error;

    if (error is DioException) {
      return fromDio(error);
    }

    if (error is SocketException) {
      return AppError(
        code: 'NETWORK_CONNECTION_ERROR',
        type: AppErrorType.offline,
        userMessage:
            'Không thể kết nối tới hệ thống. Vui lòng kiểm tra kết nối Internet.',
        canRetry: true,
        cause: error,
      );
    }

    if (error is TimeoutException) {
      return AppError(
        code: 'NETWORK_TIMEOUT',
        type: AppErrorType.timeout,
        userMessage:
            'Kết nối mất quá nhiều thời gian. Vui lòng thử lại.',
        canRetry: true,
        cause: error,
      );
    }

    if (error is PlatformException) {
      return AppError(
        code: 'PLATFORM_ERROR',
        type: AppErrorType.platform,
        userMessage: fallbackMessage ??
            'Không thể thực hiện thao tác này lúc này. Vui lòng thử lại.',
        canRetry: true,
        cause: error,
      );
    }

    if (error is FormatException || error is TypeError) {
      return AppError(
        code: 'DATA_FORMAT_ERROR',
        type: AppErrorType.data,
        userMessage: fallbackMessage ??
            'Dữ liệu nhận được chưa đúng định dạng. Vui lòng thử lại sau.',
        canRetry: true,
        cause: error,
      );
    }

    if (error is StateError || error is ArgumentError) {
      return AppError(
        code: 'APP_STATE_ERROR',
        type: AppErrorType.data,
        userMessage: fallbackMessage ??
            'Không thể xử lý dữ liệu lúc này. Vui lòng thử lại.',
        canRetry: true,
        cause: error,
      );
    }

    if (error is String) {
      final normalized = error.trim();
      if (normalized.isNotEmpty && _isSafeServerMessage(normalized)) {
        return AppError(
          code: 'BUSINESS_ERROR',
          type: AppErrorType.business,
          userMessage: normalized,
          cause: error,
        );
      }
    }

    return AppError(
      code: 'UNKNOWN_ERROR',
      type: AppErrorType.unknown,
      userMessage: fallbackMessage ?? _genericMessage,
      canRetry: true,
      cause: error,
    );
  }

  static AppError fromDio(
    DioException error, {
    bool isOffline = false,
  }) {
    final embedded = error.error;
    if (embedded is AppError) return embedded;

    if (isOffline) {
      return AppError(
        code: 'NETWORK_OFFLINE',
        type: AppErrorType.offline,
        userMessage:
            'Không có kết nối Internet. Vui lòng kiểm tra lại kết nối Internet.',
        canRetry: true,
        cause: error,
      );
    }

    switch (error.type) {
      case DioExceptionType.cancel:
        return AppError(
          code: 'REQUEST_CANCELLED',
          type: AppErrorType.cancelled,
          userMessage: 'Yêu cầu đã được hủy.',
          isSilent: true,
          cause: error,
        );
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError(
          code: 'NETWORK_TIMEOUT',
          type: AppErrorType.timeout,
          userMessage:
              'Kết nối mất quá nhiều thời gian. Vui lòng thử lại.',
          canRetry: true,
          cause: error,
        );
      case DioExceptionType.connectionError:
        return AppError(
          code: 'NETWORK_CONNECTION_ERROR',
          type: AppErrorType.offline,
          userMessage:
              'Không thể kết nối tới hệ thống. Vui lòng kiểm tra kết nối Internet.',
          canRetry: true,
          cause: error,
        );
      case DioExceptionType.badCertificate:
        return AppError(
          code: 'SECURE_CONNECTION_ERROR',
          type: AppErrorType.platform,
          userMessage:
              'Không thể xác minh kết nối an toàn tới hệ thống.',
          canRetry: true,
          cause: error,
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final response = error.response;
    final status = response?.statusCode;
    final data = response?.data;
    final serverCode = _extractServerCode(data);
    final serverMessage = _extractServerMessage(data);
    final requestId = _extractRequestId(response, data);
    final details = _extractDetails(data);
    final safeServerMessage = _safeMessageOrNull(serverMessage);

    switch (status) {
      case 400:
      case 412:
      case 422:
        return AppError(
          code: serverCode ?? 'VALIDATION_ERROR',
          type: AppErrorType.validation,
          userMessage: safeServerMessage ??
              'Thông tin gửi lên chưa hợp lệ. Vui lòng kiểm tra lại.',
          requestId: requestId,
          details: details,
          cause: error,
        );
      case 401:
        return AppError(
          code: serverCode ?? 'UNAUTHORIZED',
          type: AppErrorType.authentication,
          userMessage:
              'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.',
          requestId: requestId,
          cause: error,
        );
      case 403:
        return AppError(
          code: serverCode ?? 'FORBIDDEN',
          type: AppErrorType.authorization,
          userMessage: 'Bạn không có quyền thực hiện thao tác này.',
          requestId: requestId,
          cause: error,
        );
      case 404:
        return AppError(
          code: serverCode ?? 'NOT_FOUND',
          type: AppErrorType.notFound,
          userMessage: safeServerMessage ??
              'Nội dung không còn tồn tại hoặc chưa được cập nhật.',
          requestId: requestId,
          cause: error,
        );
      case 408:
      case 504:
        return AppError(
          code: serverCode ?? 'NETWORK_TIMEOUT',
          type: AppErrorType.timeout,
          userMessage:
              'Kết nối mất quá nhiều thời gian. Vui lòng thử lại.',
          requestId: requestId,
          canRetry: true,
          cause: error,
        );
      case 409:
        return AppError(
          code: serverCode ?? 'CONFLICT',
          type: AppErrorType.conflict,
          userMessage: safeServerMessage ??
              'Dữ liệu đã thay đổi. Vui lòng tải lại và thử lại.',
          requestId: requestId,
          details: details,
          cause: error,
        );
      case 429:
        return AppError(
          code: serverCode ?? 'TOO_MANY_REQUESTS',
          type: AppErrorType.business,
          userMessage:
              'Bạn thao tác quá nhanh. Vui lòng chờ một lúc rồi thử lại.',
          requestId: requestId,
          canRetry: true,
          cause: error,
        );
      case 500:
      case 501:
      case 502:
      case 503:
      case 505:
        return AppError(
          code: serverCode ?? 'INTERNAL_ERROR',
          type: AppErrorType.server,
          userMessage: _genericMessage,
          requestId: requestId,
          canRetry: true,
          cause: error,
        );
      default:
        if (status != null && status >= 500) {
          return AppError(
            code: serverCode ?? 'SERVER_ERROR',
            type: AppErrorType.server,
            userMessage: _genericMessage,
            requestId: requestId,
            canRetry: true,
            cause: error,
          );
        }

        if (status != null && status >= 400 && status < 500) {
          return AppError(
            code: serverCode ?? 'BUSINESS_ERROR',
            type: AppErrorType.business,
            userMessage: safeServerMessage ??
                'Không thể thực hiện yêu cầu. Vui lòng kiểm tra lại thông tin.',
            requestId: requestId,
            details: details,
            cause: error,
          );
        }
    }

    return AppError(
      code: serverCode ?? 'NETWORK_UNKNOWN_ERROR',
      type: AppErrorType.unknown,
      userMessage: _genericMessage,
      requestId: requestId,
      canRetry: true,
      cause: error,
    );
  }

  static String? _extractServerCode(dynamic data) {
    if (data is! Map) return null;
    final raw = data['code'] ?? data['errorCode'];
    final value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static String? _extractServerMessage(dynamic data) {
    if (data is! Map) return null;

    final raw = data['message'] ?? data['detail'];
    final value = raw?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;

    final nested = data['data'];
    if (nested is Map) {
      final nestedRaw = nested['message'] ?? nested['detail'];
      final nestedValue = nestedRaw?.toString().trim() ?? '';
      if (nestedValue.isNotEmpty) return nestedValue;
    }

    return null;
  }

  static Object? _extractDetails(dynamic data) {
    if (data is! Map) return null;
    return data['details'] ?? data['error'];
  }

  static String? _extractRequestId(Response<dynamic>? response, dynamic data) {
    if (data is Map) {
      final raw = data['requestId'] ?? data['request_id'];
      final value = raw?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    final headerValue = response?.headers.value('X-Request-Id') ??
        response?.headers.value('x-request-id');
    final normalized = headerValue?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  static String? _safeMessageOrNull(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || !_isSafeServerMessage(value)) return null;
    return value;
  }

  static bool _isSafeServerMessage(String value) {
    if (value.length > 400) return false;

    final normalized = value.toLowerCase();
    const technicalMarkers = <String>[
      'exception',
      'stacktrace',
      'stack trace',
      'nullpointer',
      'null pointer',
      'could not execute',
      'hibernate',
      'jdbc',
      'sqlstate',
      'constraint violation',
      'package:',
      'java.lang.',
      'org.springframework',
      'vn.iworkspace.',
      "type 'null'",
      'bad state:',
      'formatexception',
      '<!doctype html',
      '<html',
    ];

    for (final marker in technicalMarkers) {
      if (normalized.contains(marker.toLowerCase())) return false;
    }
    return true;
  }
}
