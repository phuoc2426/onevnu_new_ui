import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/common/error/app_error.dart';
import 'package:vnu_core/common/error/app_error_mapper.dart';

void main() {
  DioException dioError({
    required int status,
    required Object? data,
  }) {
    final options = RequestOptions(path: '/test');
    return DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: status,
        data: data,
      ),
    );
  }

  test('500 never exposes technical server message', () {
    final error = AppErrorMapper.fromDio(
      dioError(
        status: 500,
        data: <String, dynamic>{
          'code': 'INTERNAL_ERROR',
          'message': 'could not execute statement SQLSTATE 23505',
          'requestId': 'req-12345678',
        },
      ),
    );

    expect(error.type, AppErrorType.server);
    expect(error.code, 'INTERNAL_ERROR');
    expect(error.requestId, 'req-12345678');
    expect(error.userMessage, contains('Hệ thống đang gặp sự cố'));
    expect(error.userMessage, isNot(contains('SQLSTATE')));
  });

  test('safe 409 business message is preserved', () {
    final error = AppErrorMapper.fromDio(
      dioError(
        status: 409,
        data: <String, dynamic>{
          'code': 'REGISTRATION_ALREADY_SUBMITTED',
          'message': 'Bạn đã gửi đăng ký cho đợt này.',
        },
      ),
    );

    expect(error.type, AppErrorType.conflict);
    expect(error.code, 'REGISTRATION_ALREADY_SUBMITTED');
    expect(error.userMessage, 'Bạn đã gửi đăng ký cho đợt này.');
  });

  test('technical string is not shown to user', () {
    final error = AppErrorMapper.map(
      "type 'Null' is not a subtype of type 'String' in package:flutter/x.dart",
    );

    expect(error.type, AppErrorType.unknown);
    expect(error.userMessage, contains('Hệ thống đang gặp sự cố'));
    expect(error.userMessage, isNot(contains('package:flutter')));
  });

  test('format exception becomes safe data error', () {
    final error = AppErrorMapper.map(const FormatException('broken json'));

    expect(error.type, AppErrorType.data);
    expect(error.code, 'DATA_FORMAT_ERROR');
    expect(error.userMessage, contains('Dữ liệu nhận được'));
  });
}
