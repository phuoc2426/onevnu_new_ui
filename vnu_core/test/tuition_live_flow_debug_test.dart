import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_api_diagnostics.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';

TuitionGatewaySession session({String token = 'fake-secret-token'}) =>
    TuitionGatewaySession(accessToken: token,
      canonicalStudentId: 'fake-student-id', universityId: 4);

Dio stubDio(void Function(RequestOptions, RequestInterceptorHandler) stub) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: stub));
  return dio;
}

Response<dynamic> reply(RequestOptions opt, dynamic body, [int code = 200]) =>
  Response<dynamic>(requestOptions: opt, data: body, statusCode: code);

void main() {
  test('Live payable always uses student-scoped Bearer, never X_API_KEY', () async {
    final paths = <String>[];
    final dio = stubDio((opt, handler) {
      paths.add(opt.path);
      expect(opt.headers['Authorization'], 'Bearer fake-secret-token');
      expect(opt.headers.containsKey('x-api-key'), isFalse);
      expect(opt.queryParameters['payableOnly'], false);
      handler.resolve(reply(opt, <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'receivableId': 'pay-1',
            'outstandingAmount': '1550000.00',
            'payable': true,
          },
        ],
        'nextCursor': null,
      }));
    });
    final api = TuitionGatewayApi(session(), dio: dio);
    final bills = await api.payableAll(payableOnly: false);
    expect(bills.single['receivableId'], 'pay-1');
    expect(paths.single, contains('/cp1/students/fake-student-id/payable'));
  });

  test('Debug trace keeps request status but no token or QR contents', () async {
    final trace = TuitionApiDiagnostics.instance;
    trace.clear();
    final dio = stubDio((opt, handler) {
      handler.resolve(reply(opt, <String, dynamic>{
        'paymentRequestId': 'secret-request-id',
        'status': 'PENDING',
        'qr': <String, dynamic>{'payload': 'secret-qr-contents'},
      }));
    });
    final api = TuitionGatewayApi(session(), dio: dio);
    await api.status('secret-request-id');
    final exported = trace.exportText;
    expect(exported, contains('CHECK_STATUS'));
    expect(exported, contains('HTTP 200'));
    expect(exported, isNot(contains('fake-secret-token')));
    expect(exported, isNot(contains('secret-request-id')));
    expect(exported, isNot(contains('secret-qr-contents')));
  });

  test('401 on safe GET renews session once and retries', () async {
    var calls = 0;
    var renewals = 0;
    final dio = stubDio((opt, handler) {
      calls++;
      if (calls == 1) {
        expect(opt.headers['Authorization'], 'Bearer old-token');
        handler.reject(DioException(requestOptions: opt,
          type: DioExceptionType.badResponse,
          response: reply(opt, <String, dynamic>{'error': 'expired'}, 401)));
      } else {
        expect(opt.headers['Authorization'], 'Bearer new-token');
        handler.resolve(reply(opt, <String, dynamic>{
          'paymentRequestId': 'req-1', 'status': 'PROCESSING',
        }));
      }
    });
    final api = TuitionGatewayApi(session(token: 'old-token'), dio: dio,
      renewSession: () async {
        renewals++;
        return session(token: 'new-token');
      });
    final result = await api.status('req-1');
    expect(result.status, 'PROCESSING');
    expect(calls, 2);
    expect(renewals, 1);
  });

  test('401 on payment CREATE must not automatically replay POST', () async {
    var posts = 0;
    var renewals = 0;
    final dio = stubDio((opt, handler) {
      posts++;
      handler.reject(DioException(requestOptions: opt,
        type: DioExceptionType.badResponse,
        response: reply(opt, <String, dynamic>{'error': 'expired'}, 401)));
    });
    final api = TuitionGatewayApi(session(), dio: dio,
      renewSession: () async {
        renewals++;
        return session(token: 'new-token');
      });
    await expectLater(api.create('bill-1'), throwsA(isA<DioException>()));
    expect(posts, 1);
    expect(renewals, 0);
  });

  test('PAID is terminal and cannot recreate a paid request', () async {
    final methods = <String>[];
    final dio = stubDio((opt, handler) {
      methods.add(opt.method);
      handler.resolve(reply(opt, <String, dynamic>{
        'paymentRequestId': 'paid-request', 'status': 'PAID',
      }));
    });
    final api = TuitionGatewayApi(session(), dio: dio);
    await expectLater(api.recreate('paid-request'), throwsStateError);
    expect(methods, <String>['GET']);
  });
}
