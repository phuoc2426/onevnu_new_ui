import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/auth_mode/student_training_access_guard.dart';
import 'package:vnu_core/modules/idp_auth/config/idp_auth_config.dart';
import 'package:vnu_core/modules/one_door/data/one_door_live_api.dart';
import 'package:vnu_core/modules/profile/views/vcore_cccd_qr_scanner_view.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';

void main() {
  test('CCCD separator preserves an empty old-card field', () {
    expect(splitCccdQrFields('123456789012||Nguyen Van A|01012001').length, 4);
    expect(splitCccdQrFields('123456789012||Nguyen Van A|01012001')[1], '');
    expect(parseCccdDateOfBirth('01012001'), DateTime(2001, 1, 1));
    expect(parseCccdDateOfBirth('31022001'), isNull);
  });

  test('only authoritative 404 indicates missing training record', () {
    final options = RequestOptions(path: '/api/sinhvien');
    final missing = DioException(
      requestOptions: options,
      response: Response<Object?>(requestOptions: options, statusCode: 404),
    );
    final offline = DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
    expect(StudentTrainingAccessGuard.isAuthoritativeMissing(missing), isTrue);
    expect(StudentTrainingAccessGuard.isAuthoritativeMissing(offline), isFalse);
  });

  test('debug login gate never runs in a production mode', () {
    if (kDebugMode) {
      expect(IdpAuthConfig.showAllLoginInDebug, isTrue);
      expect(IdpAuthConfig.debugAllLoginRuntimeConfig.cccdLoginEnabled, isTrue);
      expect(IdpAuthConfig.debugAllLoginRuntimeConfig.applicantLoginEnabled, isTrue);
    } else {
      expect(IdpAuthConfig.showAllLoginInDebug, isFalse);
    }
  });

  test('One Door sends ONEVNU token to /auth/onevnu', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://motcua-vnu.digitaledu.vn/mc-api'));
    String? observedAuth;
    String? observedPath;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      observedAuth = options.headers['Authorization']?.toString();
      observedPath = options.path;
      handler.resolve(Response<dynamic>(requestOptions: options,
        statusCode: 200, data: <String, dynamic>{'accessToken': 'one-door-test-token'}));
    }));
    final session = await OneDoorOneVnuAuthApi(dio: dio).exchange(
      oneVnuJwt: 'onevnu-test-token',
    );
    expect(observedAuth, 'Bearer onevnu-test-token');
    expect(observedPath, '/api/v1/auth/onevnu');
    expect(session.accessToken, 'one-door-test-token');
  });

  test('tuition gateway refuses wrong-university or missing-token session', () {
    expect(
      () => TuitionGatewayApi(const TuitionGatewaySession(
        accessToken: 'test', canonicalStudentId: 'student', universityId: 3,
      )), throwsStateError,
    );
    expect(
      () => TuitionGatewayApi(const TuitionGatewaySession(
        accessToken: '', canonicalStudentId: 'student', universityId: 4,
      )), throwsStateError,
    );
  });

  test('payment request QR is exactly a backend-provided payload', () {
    final data = TuitionPaymentRequest.fromJson(<String, dynamic>{
      'paymentRequestId': 'pr-1', 'status': 'PROCESSING',
      'qr': <String, dynamic>{'payload': 'SERVER_GENERATED_QR'},
    });
    expect(data.payload, 'SERVER_GENERATED_QR');
    expect(data.terminal, isFalse);
    expect(TuitionPaymentRequest.fromJson(<String, dynamic>{
      'paymentRequestId': 'pr-2', 'status': 'PAID',
    }).terminal, isTrue);
  });
}
