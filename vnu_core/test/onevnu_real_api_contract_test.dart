import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/one_door/data/one_door_live_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';

Dio fakeHttp(Future<void> Function(RequestOptions, RequestInterceptorHandler) fn) {
  final dio=Dio(BaseOptions(baseUrl:'https://test.invalid'));
  dio.interceptors.add(InterceptorsWrapper(onRequest:(opt,handler) {
    fn(opt,handler);
  }));
  return dio;
}

Response<dynamic> response(RequestOptions opt,Object? body,{int status=200}) =>
    Response<dynamic>(requestOptions:opt,statusCode:status,data:body);

void main() {
  test('One Door auth uses ONEVNU JWT but case API uses One Door JWT',() async {
    final paths=<String>[];
    final headers=<String>[];
    final dio=fakeHttp((opt,handler) async {
      paths.add(opt.path);
      headers.add(opt.headers['Authorization']?.toString()??'');
      handler.resolve(response(opt,opt.path.endsWith('/auth/onevnu')
        ? <String,dynamic>{'accessToken':'one-door-token'}
        : <String,dynamic>{'userName':'student'}));
    });
    final session=await OneDoorOneVnuAuthApi(dio:dio)
        .exchange(oneVnuJwt:'onevnu-jwt');
    final api=OneDoorLiveApi(session,dio:dio);
    await api.currentUser();
    expect(paths, <String>['/api/v1/auth/onevnu','/api/v1/auth/me']);
    expect(headers, <String>['Bearer onevnu-jwt','Bearer one-door-token']);
  });

  test('One Door multipart uses paper IDs and required numeric fields',() async {
    FormData? sent;
    final dio=fakeHttp((opt,handler) async {
      sent=opt.data as FormData;
      handler.resolve(response(opt,<String,dynamic>{'idDangKy':'hs-1'}));
    });
    final api=OneDoorLiveApi(const OneDoorSession(accessToken:'session'),dio:dio);
    await api.submit(procedureId:'tt-1',request:'purpose',
      deliveryMethodId:'ht-1',quantity:2,reasonId:7,
      filesByPaperId:<String,String>{});
    final fields=Map<String,String>.fromEntries(sent!.fields);
    expect(fields['IdThuTuc'],'tt-1');
    expect(fields['IdHinhThucNhanKetQua'],'ht-1');
    expect(fields['SoLuongBan'],'2');
    expect(fields['IdLyDo'],'7');
    expect(fields.containsKey('files'),isFalse);
  });

  test('One Door never auto-replays POST after 401',() async {
    var calls=0;
    final dio=fakeHttp((opt,handler) async {
      calls++;
      handler.reject(DioException(requestOptions:opt,
        response:response(opt,<String,dynamic>{'error':'unauthorized'},status:401),
        type:DioExceptionType.badResponse));
    });
    final api=OneDoorLiveApi(const OneDoorSession(accessToken:'old'),dio:dio,
      refreshSession:() async => const OneDoorSession(accessToken:'new'));
    await expectLater(api.cancel('case-1'),throwsA(isA<DioException>()));
    expect(calls,1);
  });

  test('Payment 409 resumes active request without POSTing twice',() async {
    var postCount=0;
    final dio=fakeHttp((opt,handler) async {
      if(opt.method=='POST') {
        postCount++;
        handler.reject(DioException(requestOptions:opt,
          response:response(opt,<String,dynamic>{
            'error':'PAYMENT_REQUEST_ACTIVE',
            'details':<String,dynamic>{'activePaymentRequestId':'pr-existing'},
          },status:409),type:DioExceptionType.badResponse));
      } else {
        handler.resolve(response(opt,<String,dynamic>{
          'paymentRequestId':'pr-existing','status':'PROCESSING',
          'qr':<String,dynamic>{'payload':'BACKEND_QR'},
        }));
      }
    });
    final api=TuitionGatewayApi(const TuitionGatewaySession(
      accessToken:'student-jwt',canonicalStudentId:'student-1',universityId:4),
      dio:dio);
    final result=await api.create('receivable-1');
    expect(postCount,1);
    expect(result.id,'pr-existing');
    expect(result.payload,'BACKEND_QR');
  });

  test('Create reuses idempotencyKey after ambiguous network failure',() async {
    final keys=<String>[];
    var attempt=0;
    final dio=fakeHttp((opt,handler) async {
      final fields=Map<String,dynamic>.from(opt.data as Map);
      keys.add(fields['idempotencyKey'].toString());
      attempt++;
      if(attempt==1) {
        handler.reject(DioException(requestOptions:opt,
          type:DioExceptionType.connectionError,error:'network unavailable'));
      } else {
        handler.resolve(response(opt,<String,dynamic>{
          'paymentRequestId':'pr-1','status':'PENDING'}));
      }
    });
    final api=TuitionGatewayApi(const TuitionGatewaySession(
      accessToken:'student-jwt',canonicalStudentId:'student-1',universityId:4),
      dio:dio);
    await expectLater(api.create('receivable-1'),throwsA(isA<DioException>()));
    await api.create('receivable-1');
    expect(keys.length,2);
    expect(keys[0],keys[1]);
  });

  test('Status response without QR retains provider QR from create',() async {
    final dio=fakeHttp((opt,handler) async {
      handler.resolve(response(opt,opt.method=='POST'
        ? <String,dynamic>{'paymentRequestId':'pr-1','status':'PENDING',
            'qr':<String,dynamic>{'payload':'REAL_GATEWAY_PAYLOAD'}}
        : <String,dynamic>{'paymentRequestId':'pr-1','status':'PROCESSING'}));
    });
    final api=TuitionGatewayApi(const TuitionGatewaySession(
      accessToken:'student-jwt',canonicalStudentId:'student-1',universityId:4),
      dio:dio);
    await api.create('receivable-1');
    final updated=await api.status('pr-1');
    expect(updated.payload,'REAL_GATEWAY_PAYLOAD');
    expect(updated.status,'PROCESSING');
  });
}
