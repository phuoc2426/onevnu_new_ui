import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_student_payable_query.dart';
import 'package:vnu_core/modules/tuition/data/tuition_receivable_lifecycle.dart';
import 'package:vnu_core/modules/tuition/data/tuition_web_mock_gateway.dart';

const _session = TuitionGatewaySession(
  accessToken: 'test-student-token',
  canonicalStudentId: '11111111-1111-4111-8111-111111111111',
  universityId: 4,
);

TuitionGatewayApi _fake(
    void Function(RequestOptions, RequestInterceptorHandler) respond) {
  final dio = Dio(BaseOptions(baseUrl:'https://unit.test/api/v1'));
  dio.interceptors.add(InterceptorsWrapper(onRequest:respond));
  return TuitionGatewayApi(_session,dio:dio);
}

void _deliver(RequestOptions req, RequestInterceptorHandler handler,
    Map<String,dynamic> value) => handler.resolve(Response<dynamic>(
      requestOptions:req,statusCode:200,data:value));

void main() {
  test('CP1 full feed never sends false as an HTTP query string', () {
    final params=const TuitionStudentPayableQuery()
        .asQueryParameters(limit:50);
    expect(params, <String,dynamic>{'limit':50});
    expect(params.containsKey('payableOnly'),isFalse);
  });

  test('server query includes exact term, period, true flag and cursor', () {
    final params=const TuitionStudentPayableQuery(
      termId:'11111111-1111-4111-8111-111111111111',
      collectionPeriodCode:'ULIS-HK1-D2',payableOnly:true,
    ).asQueryParameters(limit:200,cursor:'c2');
    expect(params['termId'],'11111111-1111-4111-8111-111111111111');
    expect(params['collectionPeriodCode'],'ULIS-HK1-D2');
    expect(params['payableOnly'],true);
    expect(params['cursor'],'c2');
    expect(params['limit'],200);
  });

  test('invalid termId/period/limit are rejected before calling API', () {
    expect(()=>const TuitionStudentPayableQuery(termId:'not-a-uuid')
      .asQueryParameters(limit:50),throwsFormatException);
    expect(()=>const TuitionStudentPayableQuery()
      .asQueryParameters(limit:201),throwsRangeError);
    expect(()=>TuitionStudentPayableQuery(
      collectionPeriodCode:List<String>.filled(101,'x').join()).asQueryParameters(limit:50),
      throwsFormatException);
  });

  test('filtered pagination uses CP1 server parameters for EVERY page',
      () async {
    final visited=<String?>[];
    final api=_fake((req,handler){
      expect(req.method,'GET');
      expect(req.path,contains('/cp1/students/'));
      expect(req.queryParameters['termId'],_session.canonicalStudentId);
      expect(req.queryParameters['collectionPeriodCode'],'ULIS-HK1-D2');
      expect(req.queryParameters.containsKey('payableOnly'),isFalse);
      final cursor=req.queryParameters['cursor']?.toString();
      visited.add(cursor);
      _deliver(req,handler, <String,dynamic>{
        'items':<Map<String,dynamic>>[
          {'receivableId':cursor==null?'receivable-a':'receivable-b',
           'outstandingAmount':'50000','payable':false},
        ],
        'nextCursor':cursor==null?'next-page':null,
      });
    });
    final rows=await api.payableAll(
      termId:_session.canonicalStudentId,collectionPeriodCode:'ULIS-HK1-D2');
    expect(visited,<String?>[null,'next-page']);
    expect(rows,hasLength(2));
  });

  test('cancel uses student Bearer token and returns lock-release truth',
      () async {
    var posts=0;
    final api=_fake((req,handler){
      posts++;
      expect(req.method,'POST');
      expect(req.path,'/cp1/payment-requests/request-1/cancel');
      expect(req.headers['Authorization'],'Bearer test-student-token');
      expect(req.headers.containsKey('x-api-key'),isFalse);
      expect(req.data, <String,dynamic>{'reason':'Sinh viên hủy'});
      _deliver(req,handler,<String,dynamic>{
        'paymentRequestId':'request-1',
        'status':'CANCELLED', 'previousStatus':'PENDING',
        'lockReleased':false,'lockAttention':true,
        'replayed':false,
      });
    });
    final result=await api.cancel('request-1',reason:'Sinh viên hủy');
    expect(result.request.status,'CANCELLED');
    expect(result.lockReleased,isFalse);
    expect(result.lockAttention,isTrue);
    expect(posts,1);
  });

  test('mock: only active PENDING can be cancelled, then recreated',
      () async {
    final mock=TuitionWebMockGateway();
    mock.responseDelay=Duration.zero;
    final waiting=mock.bills.last;
    final original=mock.requestFor(waiting.code)!;
    final cancelled=await mock.cancel(waiting.code);
    expect(cancelled.request.status,'CANCELLED');
    expect(cancelled.lockReleased,true);
    expect(mock.requestFor(waiting.code)!.id,original.id);
    final next=await mock.createOrRecreate(waiting.code);
    expect(next.status,'PENDING');
    expect(next.id,isNot(original.id));
    await expectLater(mock.cancel(waiting.code),completes);
  });

  test('mock: EXPIRED cannot be cancelled', () async {
    final mock=TuitionWebMockGateway();
    await expectLater(mock.cancel(mock.bills.first.code),throwsStateError);
  });

  test('CP1 financial blocking reason wins over payable=true', () {
    final life=TuitionReceivableState.fromJson(<String,dynamic>{
      'receivableId':'r-blocked','outstandingAmount':'7150000',
      'payable':true,'payability':'BLOCKED','hasActiveLock':false,
      'paymentStatus':'UNPAID',
    });
    expect(life.canCreate,isFalse);
    expect(life.inUnpaidTab,isTrue);
  });

  test('mock PAID financial state is testable without bank API', () {
    final mock=TuitionWebMockGateway();
    final bill=mock.bills.last;
    expect(mock.markPaid(bill.code),isTrue);
    expect(mock.requestFor(bill.code)!.status,'PAID');
    expect(bill.status.name,'paid');
  });
}
