import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';

TuitionGatewayApi gateway(void Function(RequestOptions,RequestInterceptorHandler) stub) {
  final dio = Dio(BaseOptions(baseUrl:'https://test.invalid'));
  dio.interceptors.add(InterceptorsWrapper(onRequest:stub));
  return TuitionGatewayApi(const TuitionGatewaySession(
    accessToken:'dummy-student-jwt', canonicalStudentId:'student-a',
    universityId:4),dio:dio);
}

Response<dynamic> ok(RequestOptions o,dynamic body) =>
    Response<dynamic>(requestOptions:o,statusCode:200,data:body);

void main() {
  test('overview includes locked/paid rows using payableOnly=false', () async {
    final paths=<String>[];
    final api=gateway((options,handler) {
      paths.add(options.path);
      expect(options.method,'GET');
      expect(options.queryParameters['payableOnly'], false);
      expect(options.headers['Authorization'], 'Bearer dummy-student-jwt');
      handler.resolve(ok(options,<String,dynamic>{'items':<Map<String,dynamic>>[
        <String,dynamic>{'receivableId':'unpaid','outstandingAmount':100,
          'payable':false,'activePaymentRequest':<String,dynamic>{
            'paymentRequestId':'qr-1','status':'PENDING'}},
        <String,dynamic>{'receivableId':'paid','outstandingAmount':0,
          'payable':false,'paymentStatus':'PAID'},
      ],'nextCursor':null}));
    });
    final rows=await api.payableAll();
    expect(rows.length,2);
    expect(paths.single, contains('/cp1/students/student-a/payable'));
  });

  test('seeded active QR survives status GET response without QR', () async {
    final methods=<String>[];
    final api=gateway((options,handler) {
      methods.add(options.method);
      expect(options.path, contains('/cp1/payment-requests/existing-request'));
      handler.resolve(ok(options,<String,dynamic>{
        'paymentRequestId':'existing-request','status':'PROCESSING',
        'updatedAt':'2026-10-19T10:40:00Z',
      }));
    });
    final seeded=api.rememberActiveRequest(<String,dynamic>{
      'paymentRequestId':'existing-request','status':'PENDING',
      'expiresAt':'2026-10-19T11:00:00Z',
      'qr':<String,dynamic>{'payload':'EXACT_GATEWAY_PAYLOAD',
        'provider':'BIDV'},
    });
    expect(seeded.payload,'EXACT_GATEWAY_PAYLOAD');
    final latest=await api.status('existing-request');
    expect(latest.status,'PROCESSING');
    expect(latest.payload,'EXACT_GATEWAY_PAYLOAD');
    expect(latest.provider,'BIDV');
    expect(methods,<String>['GET']); // absolutely NO create POST
  });

  test('active-request conflict recovers with GET, never repeats POST', () async {
    var postCount=0;
    var getCount=0;
    final api=gateway((opt,handler) {
      if(opt.method=='POST') {
        postCount++;
        handler.reject(DioException(requestOptions:opt,
          type:DioExceptionType.badResponse,
          response:Response<dynamic>(requestOptions:opt,statusCode:409,
            data:<String,dynamic>{'error':'PAYMENT_REQUEST_ACTIVE',
              'details':<String,dynamic>{
                'activePaymentRequestId':'already-active'}})));
      } else {
        getCount++;
        handler.resolve(ok(opt,<String,dynamic>{
          'paymentRequestId':'already-active','status':'PENDING',
          'qr':<String,dynamic>{'payload':'GATEWAY_ONLY'},
        }));
      }
    });
    final result=await api.create('locked-receivable');
    expect(postCount,1);
    expect(getCount,1);
    expect(result.id,'already-active');
    expect(result.payload,'GATEWAY_ONLY');
  });

  test('cannot recreate a still-processing request', () async {
    var posts=0;
    final api=gateway((opt,handler) {
      if(opt.method=='POST') posts++;
      handler.resolve(ok(opt,<String,dynamic>{
        'paymentRequestId':'processing','status':'PROCESSING'}));
    });
    await expectLater(api.recreate('processing'),throwsStateError);
    expect(posts,0);
  });
}
