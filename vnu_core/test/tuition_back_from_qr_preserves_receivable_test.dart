import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_payable_reconciliation.dart';
import 'package:vnu_core/modules/tuition/data/tuition_receivable_lifecycle.dart';

/// Regression: V5 discarded every card when serverRows == 0 after a QR POST.
/// These tests exercise the SAME [result.visibleRows] projection as the view.
/// An omitted receivable must not magically turn into paid or disappear.
void main() {
  const student = TuitionGatewaySession(
    accessToken: 'ulis-before',
    canonicalStudentId: 'student-v6',
    universityId: 4,
  );

  Map<String, dynamic> invoice({bool payable = true,
      Map<String, dynamic>? active}) => <String, dynamic>{
    'receivableId': 'receivable-1',
    'outstandingAmount': '7150000',
    'paymentStatus': 'UNPAID',
    'payable': payable,
    'hasActiveLock': !payable,
    'collectionPeriodName': 'Học kỳ 1 - 2026/2027',
    if (active != null) 'activePaymentRequest': active,
  };

  test('GET empty AFTER CREATE 201 still displays prior QR-locked card', () async {
    var listReads = 0;
    var creates = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid/'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (req, handler) {
      if (req.method == 'POST') {
        creates++;
        expect(req.path, endsWith('/cp1/payment-requests'));
        handler.resolve(Response<dynamic>(requestOptions: req,
          statusCode: 201, data: <String, dynamic>{
            'paymentRequestId': 'request-1', 'status': 'PENDING',
            'expiresAt': '2099-01-01T00:00:00Z',
            'qr': <String, dynamic>{'payload': 'QR_FROM_BANK'},
          }));
        return;
      }
      expect(req.method, 'GET');
      expect(req.queryParameters['payableOnly'], false);
      listReads++;
      handler.resolve(Response<dynamic>(requestOptions: req, statusCode: 200,
        data: <String, dynamic>{'items': listReads == 1
          ? <Map<String, dynamic>>[invoice()]
          : <Map<String, dynamic>>[]}));
    }));
    final api = TuitionGatewayApi(student, dio: dio);
    final initial = await api.payableAll(payableOnly: false);
    final before = TuitionPayableReconciliation.reconcile(incoming: initial);
    expect(before.visibleRows, hasLength(1));
    final bill = before.states['receivable-1']!;
    expect(bill.canCreate, isTrue);
    expect(bill.inUnpaidTab, isTrue);

    final request = await api.create(bill.id);
    expect(request.status, 'PENDING');
    final locked = bill.withGatewayRequest(requestId: request.id,
        status: request.status, qrPayload: request.payload,
        expiresAt: request.expiresAt);
    expect(locked.activeRequestId, 'request-1');
    expect(locked.payable, isFalse);
    expect(locked.action, TuitionReceivableAction.continuePayment);

    // This matches Back -> _loadLive() while CP1/gateway incorrectly sends [].
    final empty = await api.payableAll(payableOnly: false);
    final after = TuitionPayableReconciliation.reconcile(incoming: empty,
      previous: <String, TuitionReceivableState>{bill.id: locked});
    expect(after.serverRows, 0);
    expect(after.visibleRows, hasLength(1));
    expect(after.retainedCount, 1);
    expect(after.unverifiedIds, contains(bill.id));
    final stillShown = after.visibleRows.single;
    expect(stillShown.id, bill.id);
    expect(stillShown.outstandingAmount, 7150000);
    expect(stillShown.inUnpaidTab, isTrue);
    expect(stillShown.activeRequestId, 'request-1');
    expect(stillShown.action, TuitionReceivableAction.continuePayment);
    expect(stillShown.canCreate, isFalse);
    expect(creates, 1); // GET on Back must never POST again.
  });

  test('backend locked row payable=false is visible and verified', () {
    final current = TuitionPayableReconciliation.reconcile(incoming: [
      invoice(payable: false, active: <String, dynamic>{
        'paymentRequestId': 'request-1', 'status': 'PROCESSING',
      }),
    ]);
    expect(current.serverRows, 1);
    expect(current.unverifiedIds, isEmpty);
    expect(current.visibleRows, hasLength(1));
    expect(current.visibleRows.single.inUnpaidTab, isTrue);
    expect(current.visibleRows.single.phase, TuitionReceivablePhase.processing);
    expect(current.visibleRows.single.action, TuitionReceivableAction.viewStatus);
  });

  test('manual new-session GET empty carries old confirmed debt, never POSTs', () async {
    var rotations = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid/'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (req, handler) {
      expect(req.method, 'GET');
      expect(req.queryParameters['payableOnly'], false);
      expect(req.headers['Authorization'], 'Bearer ulis-new');
      handler.resolve(Response<dynamic>(requestOptions: req,
        statusCode: 200, data: <String, dynamic>{'items': <dynamic>[]}));
    }));
    final api = TuitionGatewayApi(student, dio: dio, renewSession: () async {
      rotations++;
      return const TuitionGatewaySession(
        accessToken: 'ulis-new', canonicalStudentId: 'student-v6',
        universityId: 4);
    });
    final known = TuitionReceivableState.fromJson(invoice(payable: false,
      active: <String, dynamic>{
        'paymentRequestId': 'pending-r1', 'status': 'PENDING',
      }));
    await api.refreshSession();
    final incoming = await api.payableAll(payableOnly: false);
    final result = TuitionPayableReconciliation.reconcile(
      incoming: incoming, previous: {known.id: known});
    expect(rotations, 1);
    expect(result.serverRows, 0);
    expect(result.visibleRows, hasLength(1));
    expect(result.unverifiedIds, contains('receivable-1'));
    expect(result.visibleRows.single.canCreate, isFalse);
  });

  test('stale payable=true row cannot discard known PENDING request', () {
    final prior = TuitionReceivableState.fromJson(invoice(payable: false,
      active: <String, dynamic>{
        'paymentRequestId': 'pending-pr', 'status': 'PENDING',
      }));
    // A lagging upstream page still says payable=true, but POST 201 has
    // already succeeded and the previous request remains authoritative.
    final stale = TuitionPayableReconciliation.reconcile(
      incoming: [invoice(payable: true)], previous: {prior.id: prior});
    expect(stale.serverRows, 1);
    expect(stale.visibleRows, hasLength(1));
    expect(stale.unverifiedIds, contains(prior.id));
    final recovered = stale.visibleRows.single;
    expect(recovered.payable, isFalse);
    expect(recovered.activeRequestId, 'pending-pr');
    expect(recovered.canCreate, isFalse);
    expect(recovered.action, TuitionReceivableAction.continuePayment);
  });

  test('fresh install with empty feed has no invented cards or QR', () {
    final result = TuitionPayableReconciliation.reconcile(
      incoming: const <Map<String, dynamic>>[],
    );
    expect(result.visibleRows, isEmpty);
    expect(result.serverRows, 0);
    expect(result.states, isEmpty);
    // A fresh install needs a backend endpoint capable of returning
    // pending/locked receivables. There is no local memory to recover from.
  });

  test('once gateway returns rows again, provisional card is verified', () {
    final old = TuitionReceivableState.fromJson(invoice(payable: false,
      active: <String, dynamic>{
        'paymentRequestId': 'pending-r1', 'status': 'PENDING',
      }));
    final missing = TuitionPayableReconciliation.reconcile(
      incoming: const <Map<String, dynamic>>[], previous: {old.id: old});
    expect(missing.unverifiedIds, contains(old.id));
    final recovered = TuitionPayableReconciliation.reconcile(
      incoming: [invoice(payable: false, active: <String, dynamic>{
        'paymentRequestId': 'pending-r1', 'status': 'PENDING',
      })], previous: missing.states);
    expect(recovered.unverifiedIds, isEmpty);
    expect(recovered.visibleRows, hasLength(1));
    expect(recovered.visibleRows.single.canCreate, isFalse);
  });

  test('confirmed paid balance remains in All/Paid but not Unpaid tab', () {
    final settled = TuitionPayableReconciliation.reconcile(incoming: [
      <String, dynamic>{...invoice(payable: false),
        'outstandingAmount': '0', 'paidAmount': '7150000',
        'paymentStatus': 'PAID'},
    ]);
    expect(settled.visibleRows, hasLength(1));
    expect(settled.visibleRows.single.inPaidTab, isTrue);
    expect(settled.visibleRows.single.inUnpaidTab, isFalse);
    expect(TuitionReceivableState.totalDebt(settled.visibleRows), 0);
  });
}
