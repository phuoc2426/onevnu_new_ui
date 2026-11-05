import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_session_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_session_cache.dart';

void main() {
  test('ONEVNU bridge receives JWT but not studentCode or x-api-key', () async {
    var calls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://onevnu.test/'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (opt, handler) {
      calls++;
      expect(opt.method, 'POST');
      expect(opt.path, contains('/api/ulis-tuition/session'));
      expect(opt.headers['Authorization'], 'Bearer onevnu-jwt-a');
      expect(opt.headers.keys.map((x) => x.toLowerCase()),
          isNot(contains('x-api-key')));
      expect(opt.data, isNull);
      handler.resolve(Response<dynamic>(requestOptions: opt,
        statusCode: 200, data: <String, dynamic>{
          'accessToken': 'gateway-session-1',
          'canonicalStudentId': 'canonical-1',
          'universityId': 4,
          'expiresIn': 900,
        }));
    }));
    final sessionApi = TuitionGatewaySessionApi(dio: dio,
      cache: TuitionGatewaySessionCache(),
      oneVnuTokenProvider: () => 'onevnu-jwt-a');
    final first = await sessionApi.issueForCurrentStudent();
    final next = await sessionApi.issueForCurrentStudent();
    expect(first.accessToken, 'gateway-session-1');
    expect(next.canonicalStudentId, 'canonical-1');
    expect(calls, 1);
  });

  test('CP1 GET renews token via ONEVNU bridge after gateway 401', () async {
    var issued = 0;
    final bridgeDio = Dio(BaseOptions(baseUrl: 'https://onevnu.test/'));
    bridgeDio.interceptors.add(InterceptorsWrapper(onRequest: (opt, handler) {
      issued++;
      handler.resolve(Response<dynamic>(requestOptions: opt,
        statusCode: 200, data: <String, dynamic>{
          'accessToken': issued == 1 ? 'old' : 'fresh',
          'canonicalStudentId': 'canonical-1',
          'universityId': 4,
          'expiresIn': 900,
        }));
    }));
    final sessionApi = TuitionGatewaySessionApi(dio: bridgeDio,
      cache: TuitionGatewaySessionCache(),
      oneVnuTokenProvider: () => 'onevnu-jwt-a');
    final first = await sessionApi.issueForCurrentStudent();

    var gatewayCalls = 0;
    final gatewayDio = Dio(BaseOptions(baseUrl: 'https://gateway.test/'));
    gatewayDio.interceptors.add(InterceptorsWrapper(onRequest: (opt, handler) {
      gatewayCalls++;
      expect(opt.method, 'GET');
      expect(opt.headers.containsKey('x-api-key'), isFalse);
      if (gatewayCalls == 1) {
        expect(opt.headers['Authorization'], 'Bearer old');
        handler.reject(DioException(requestOptions: opt,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(requestOptions: opt,
            statusCode: 401, data: <String,dynamic>{'error':'expired'})));
      } else {
        expect(opt.headers['Authorization'], 'Bearer fresh');
        handler.resolve(Response<dynamic>(requestOptions: opt,
          statusCode: 200,
          data: <String,dynamic>{'items': <dynamic>[], 'nextCursor': null}));
      }
    }));

    final gateway = TuitionGatewayApi(first, dio: gatewayDio,
      renewSession: () => sessionApi.issueForCurrentStudent(
        forceRefresh: true));
    expect(await gateway.payable(), isEmpty);
    expect(gatewayCalls, 2);
    expect(issued, 2);
  });
}
