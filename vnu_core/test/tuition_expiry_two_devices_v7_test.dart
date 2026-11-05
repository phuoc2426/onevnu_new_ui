import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_receivable_lifecycle.dart';
import 'package:vnu_core/modules/tuition/data/tuition_payable_reconciliation.dart';

// State-machine tests, not mock-payment flows. Both devices below have their
// OWN ULIS student tokens but the SAME canonicalStudentId/server records.
void main() {
  Map<String, dynamic> receivable({required bool payable,
    bool locked = false, Map<String, dynamic>? active,
    Map<String, dynamic>? last}) => <String, dynamic>{
      'receivableId': 'receivable-A',
      'outstandingAmount': '7150000',
      'paymentStatus': 'UNPAID',
      'payable': payable,
      'hasActiveLock': locked,
      if (active != null) 'activePaymentRequest': active,
      if (last != null) 'lastPaymentRequest': last,
    };

  test('GET EXPIRED: preserve previous QR and block generic CREATE', () {
    final pending = TuitionReceivableState.fromJson(receivable(
      payable: false, locked: true, active: <String,dynamic>{
      'paymentRequestId': 'pr-1', 'status': 'PENDING',
      'qr': <String,dynamic>{'payload': 'SERVER_QR_OLD'},
    }));
    final expired = pending.withGatewayRequest(
      requestId: 'pr-1', status: 'EXPIRED');
    expect(expired.phase, TuitionReceivablePhase.qrExpired);
    expect(expired.activeRequestId, isNull);
    expect(expired.lastRequestId, 'pr-1');
    expect(expired.lastPaymentRequest?['status'], 'EXPIRED');
    expect((expired.lastPaymentRequest?['qr'] as Map)['payload'], 'SERVER_QR_OLD');
    expect(expired.inUnpaidTab, isTrue);
    expect(expired.canCreate, isFalse);
  });

  test('after lock release, card becomes unpaid/waiting; old expired QR survives', () {
    final pending = TuitionReceivableState.fromJson(receivable(
      payable: false, locked: true, active: <String,dynamic>{
        'paymentRequestId': 'pr-1', 'status': 'PENDING',
        'qr': <String,dynamic>{'payload': 'SERVER_QR_OLD'},
      }));
    final expired = pending.withGatewayRequest(requestId: 'pr-1',
        status: 'EXPIRED');
    final refreshed = TuitionPayableReconciliation.reconcile(
      incoming: [receivable(payable: true)],
      previous: {'receivable-A': expired});
    final row = refreshed.visibleRows.single;
    expect(row.phase, TuitionReceivablePhase.unpaid);
    expect(row.releasedAfterExpiry, isTrue);
    expect(row.lastRequestId, 'pr-1');
    expect(row.hasExpiredHistory, isTrue);
    expect(row.action, TuitionReceivableAction.createNewQr);
    // Explicit RECREATE must use pr-1, not generic CREATE on opening detail.
    expect(row.canCreate, isFalse);
    expect((row.lastPaymentRequest?['qr'] as Map)['payload'], 'SERVER_QR_OLD');
    expect(row.outstandingAmount, 7150000);
  });

  test('empty gateway after expiry retains old ticket unverified', () {
    final prior = TuitionReceivableState.fromJson(receivable(
      payable: false, locked: true, active: {
        'paymentRequestId':'pr-1', 'status':'PENDING',
      })).withGatewayRequest(requestId: 'pr-1', status: 'EXPIRED');
    final result = TuitionPayableReconciliation.reconcile(
      incoming: const [], previous: {'receivable-A': prior});
    expect(result.visibleRows, hasLength(1));
    expect(result.unverifiedIds, contains('receivable-A'));
    expect(result.visibleRows.single.lastRequestId, 'pr-1');
    expect(result.visibleRows.single.phase, TuitionReceivablePhase.qrExpired);
  });

  test('lagged PENDING feed cannot resurrect SAME already expired request', () {
    final expired = TuitionReceivableState.fromJson(receivable(
      payable: false, locked: true, active: {
        'paymentRequestId':'pr-1', 'status':'PENDING',
      })).withGatewayRequest(requestId: 'pr-1', status: 'EXPIRED');
    final incoming = TuitionPayableReconciliation.reconcile(
      incoming: [receivable(payable: false, locked: true, active: {
        'paymentRequestId':'pr-1', 'status':'PENDING',
      })], previous: {expired.id: expired});
    expect(incoming.visibleRows.single.activeRequestId, isNull);
    expect(incoming.visibleRows.single.lastRequestId, 'pr-1');
    expect(incoming.visibleRows.single.phase, TuitionReceivablePhase.qrExpired);
    expect(incoming.unverifiedIds, contains(expired.id));
  });

  test('PAID request awaiting accounting does not become freely payable', () {
    final original = TuitionReceivableState.fromJson(receivable(
      payable:false, locked:true, active: <String,dynamic>{
        'paymentRequestId':'pr-paid', 'status':'PROCESSING',
      }));
    final paidRequest = original.withGatewayRequest(
      requestId:'pr-paid', status:'PAID');
    expect(paidRequest.inUnpaidTab, isTrue);
    expect(paidRequest.phase, TuitionReceivablePhase.processing);
    expect(paidRequest.canCreate, isFalse);
    expect(paidRequest.lastRequestId, 'pr-paid');
  });

  test('reinstall can recover historical ID ONLY when server returns it', () {
    final fresh = TuitionPayableReconciliation.reconcile(incoming: [
      receivable(payable: true, last: <String,dynamic>{
        'paymentRequestId': 'pr-1', 'status': 'EXPIRED',
        'qr': <String,dynamic>{'payload': 'SERVER_QR_OLD'},
      }),
    ]);
    expect(fresh.unverifiedIds, isEmpty);
    expect(fresh.visibleRows.single.lastRequestId, 'pr-1');
    expect(fresh.visibleRows.single.phase, TuitionReceivablePhase.unpaid);
    expect(fresh.visibleRows.single.canCreate, isFalse);
    expect(TuitionPayableReconciliation.reconcile(incoming: const []).states,
      isEmpty); // No server data, no invented past bill.
  });

  test('2 different tokens, same student: existing PENDING comes from server', () async {
    var createPosts = 0;
    final shared = <String,dynamic>{
      'items': [receivable(payable: false, locked: true, active: {
        'paymentRequestId': 'pr-1', 'status': 'PENDING',
        'expiresAt': '2099-01-01T00:00:00Z',
        'qr': <String,dynamic>{'payload': 'SERVER_QR'},
      })],
    };
    Dio makeDio() {
      final dio = Dio(BaseOptions(baseUrl: 'https://mock.invalid/'));
      dio.interceptors.add(InterceptorsWrapper(onRequest: (req, handler) {
        if (req.method == 'POST') {
          createPosts++;
          handler.reject(DioException(requestOptions: req));
          return;
        }
        expect(req.queryParameters['payableOnly'], isFalse);
        handler.resolve(Response<dynamic>(requestOptions: req,
          statusCode: 200, data: shared));
      }));
      return dio;
    }
    final one = TuitionGatewayApi(const TuitionGatewaySession(
      accessToken:'device-one-token', canonicalStudentId:'student-A',
      universityId:4), dio:makeDio());
    final two = TuitionGatewayApi(const TuitionGatewaySession(
      accessToken:'device-two-token', canonicalStudentId:'student-A',
      universityId:4), dio:makeDio());
    final first = TuitionPayableReconciliation.reconcile(
      incoming: await one.payableAll(payableOnly: false));
    final second = TuitionPayableReconciliation.reconcile(
      incoming: await two.payableAll(payableOnly: false));
    expect(first.visibleRows.single.activeRequestId, 'pr-1');
    expect(second.visibleRows.single.activeRequestId, 'pr-1');
    expect(second.visibleRows.single.action,
      TuitionReceivableAction.continuePayment);
    expect(createPosts, 0);
  });

  test('another device already recreated: 409 resolves its ACTIVE request', () async {
    var posts = 0;
    var gets = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://mock.invalid/'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (req, handler) {
      if (req.method == 'POST') {
        posts++;
        handler.reject(DioException(requestOptions: req,
          response: Response<dynamic>(requestOptions: req,
            statusCode: 409, data: <String,dynamic>{
              'error': 'ACTIVE_REQUEST_EXISTS',
              'details': <String,dynamic>{
                'activePaymentRequestId': 'pr-new-from-phone2',
              },
            })));
        return;
      }
      gets++;
      final newRequest = req.path.contains('pr-new-from-phone2');
      handler.resolve(Response<dynamic>(requestOptions:req,
        statusCode:200, data:<String,dynamic>{
          'paymentRequestId': newRequest ? 'pr-new-from-phone2' : 'pr-old',
          'status': newRequest ? 'PENDING' : 'EXPIRED',
          if (newRequest) 'qr': <String,dynamic>{'payload':'BANK_SHARED_QR'},
        }));
    }));
    final api = TuitionGatewayApi(const TuitionGatewaySession(
      accessToken:'token', canonicalStudentId:'student-A', universityId:4),
      dio:dio);
    final payment = await api.recreate('pr-old');
    expect(payment.id, 'pr-new-from-phone2');
    expect(payment.status, 'PENDING');
    expect(payment.payload, 'BANK_SHARED_QR');
    expect(gets, 2); // GET old then GET other device's active request
    expect(posts, 1); // no retry POST storm
  });

  test('server-confirmed EXPIRED uses RECREATE, never generic CREATE', () async {
    var statusGets = 0;
    var recreates = 0;
    var creates = 0;
    final dio = Dio(BaseOptions(baseUrl:'https://mock.invalid/'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (req, handler) {
      if (req.method == 'POST') {
        if (req.path.endsWith('/recreate')) {
          recreates++;
          handler.resolve(Response<dynamic>(requestOptions:req,
            statusCode:201, data: <String,dynamic>{
              'paymentRequestId':'pr-2', 'status':'PENDING',
              'qr': <String,dynamic>{'payload':'NEW_FROM_PROVIDER'},
            }));
        } else {
          creates++;
          handler.reject(DioException(requestOptions:req));
        }
        return;
      }
      statusGets++;
      handler.resolve(Response<dynamic>(requestOptions:req,
        statusCode:200, data: <String,dynamic>{
          'paymentRequestId':'pr-1', 'status':'EXPIRED',
        }));
    }));
    final api = TuitionGatewayApi(const TuitionGatewaySession(
      accessToken:'token', canonicalStudentId:'student-A',universityId:4),
      dio:dio);
    final result = await api.recreate('pr-1');
    expect(result.id, 'pr-2');
    expect(result.payload, 'NEW_FROM_PROVIDER');
    expect(statusGets, 1);
    expect(recreates, 1);
    expect(creates, 0);
  });
}
