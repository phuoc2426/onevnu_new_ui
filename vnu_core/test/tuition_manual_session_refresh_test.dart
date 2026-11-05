import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_session_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_session_cache.dart';

void main() {
  test('forceRefresh=true bypasses cached ULIS session and calls backend',
      () async {
    var calls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid/'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      expect(request.method, 'POST');
      expect(request.path, contains('api/ulis-tuition/session'));
      expect(request.headers['Authorization'], 'Bearer onevnu-jwt-test');
      calls++;
      handler.resolve(Response<dynamic>(
        requestOptions: request,
        statusCode: 200,
        data: <String, dynamic>{
          'accessToken': 'ulis-token-$calls',
          'canonicalStudentId': 's-01',
          'universityId': 4,
          'expiresIn': 3600,
        },
      ));
    }));
    final provider = TuitionGatewaySessionApi(
      dio: dio,
      cache: TuitionGatewaySessionCache(),
      oneVnuTokenProvider: () => 'onevnu-jwt-test',
    );
    final first = await provider.issueForCurrentStudent();
    final cached = await provider.issueForCurrentStudent();
    final renewed = await provider.issueForCurrentStudent(forceRefresh: true);
    expect(first.accessToken, 'ulis-token-1');
    expect(cached.accessToken, 'ulis-token-1');
    expect(renewed.accessToken, 'ulis-token-2');
    expect(calls, 2);
  });

  test('manual ULIS session renewal precedes new payable GET and no CREATE',
      () async {
    const initial = TuitionGatewaySession(
      accessToken: 'ulis-old',
      canonicalStudentId: 's-01',
      universityId: 4,
    );
    var renewals = 0;
    final methods = <String>[];
    final bearers = <String?>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid/'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      methods.add(request.method);
      bearers.add(request.headers['Authorization']?.toString());
      expect(request.queryParameters['payableOnly'], false);
      expect(request.headers['Cache-Control'], 'no-store');
      handler.resolve(Response<dynamic>(
        requestOptions: request,
        statusCode: 200,
        data: <String, dynamic>{'items': <dynamic>[]},
      ));
    }));
    final api = TuitionGatewayApi(initial, dio: dio, renewSession: () async {
      renewals++;
      return const TuitionGatewaySession(
        accessToken: 'ulis-fresh',
        canonicalStudentId: 's-01',
        universityId: 4,
      );
    });
    await api.payableAll(payableOnly: false);
    await api.refreshSession();
    await api.payableAll(payableOnly: false);
    expect(renewals, 1);
    expect(methods, <String>['GET', 'GET']);
    expect(bearers, <String?>['Bearer ulis-old', 'Bearer ulis-fresh']);
  });

  test('session renewal cannot change the student identity', () async {
    const initial = TuitionGatewaySession(
      accessToken: 'ulis-old',
      canonicalStudentId: 's-01',
      universityId: 4,
    );
    final api = TuitionGatewayApi(initial, renewSession: () async {
      return const TuitionGatewaySession(
        accessToken: 'some-token',
        canonicalStudentId: 'different-student',
        universityId: 4,
      );
    });
    await expectLater(api.refreshSession(), throwsA(isA<TuitionGatewayIdentityMismatchException>()));
  });
}
