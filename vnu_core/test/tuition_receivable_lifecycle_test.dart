import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_receivable_lifecycle.dart';

Map<String, dynamic> row({
  int balance = 7150000,
  bool payable = true,
  Map<String,dynamic>? active,
  String paymentStatus = 'UNPAID',
  String? reason,
  String? latestStatus,
}) => <String, dynamic>{
  'receivableId': 'bill-reexam',
  'outstandingAmount': balance,
  'totalAmount': 7150000,
  'paymentStatus': paymentStatus,
  'payable': payable,
  'collectionPeriodName': 'Hoc ky 1',
  if (active != null) 'activePaymentRequest': active,
  if (reason != null) 'blockingReason': reason,
  if (latestStatus != null) 'lastPaymentRequest': <String,dynamic>{
    'status': latestStatus,
  },
};

void main() {
  group('Receivable lifecycle from gateway', () {
    test('payable=false with active PENDING keeps item, debt and resume action', () {
      final item = TuitionReceivableState.fromJson(row(payable: false,
        active: <String,dynamic>{
          'paymentRequestId': 'request-1',
          'status': 'PENDING',
          'expiresAt': '2026-10-19T11:55:00Z',
          'qr': <String,dynamic>{'payload':'provider-qr-payload'},
        }));
      expect(item.phase, TuitionReceivablePhase.waitingPayment);
      expect(item.action, TuitionReceivableAction.continuePayment);
      expect(item.activeRequestId, 'request-1');
      expect(item.canCreate, isFalse);
      expect(item.canResume, isTrue);
      expect(item.inUnpaidTab, isTrue);
      expect(item.inPaidTab, isFalse);
      expect(TuitionReceivableState.totalDebt(<TuitionReceivableState>[item]), 7150000);
    });

    test('PROCESSING takes priority even when receivable.paymentStatus=UNPAID', () {
      final item = TuitionReceivableState.fromJson(row(payable: false,
        active: <String,dynamic>{
          'paymentRequestId':'p-processing','status':'PROCESSING',
        }));
      expect(item.phase, TuitionReceivablePhase.processing);
      expect(item.action, TuitionReceivableAction.viewStatus);
      expect(item.canCreate, isFalse);
      expect(item.inUnpaidTab, isTrue);
    });

    test('two locked QR bills still total 18.700.000', () {
      final a = TuitionReceivableState.fromJson(row(
        balance:11550000, payable:false,
        active: <String,dynamic>{'paymentRequestId':'p-a','status':'PENDING'}));
      final b = TuitionReceivableState.fromJson(row(
        balance:7150000, payable:false,
        active: <String,dynamic>{'paymentRequestId':'p-b','status':'PROCESSING'}));
      expect(TuitionReceivableState.totalDebt(<TuitionReceivableState>[a,b]),
        18700000);
      expect(<TuitionReceivableState>[a,b].where((x)=>x.inUnpaidTab).length, 2);
    });

    test('payable=true without active request permits POST', () {
      final item = TuitionReceivableState.fromJson(row());
      expect(item.phase, TuitionReceivablePhase.unpaid);
      expect(item.action, TuitionReceivableAction.pay);
      expect(item.canCreate, isTrue);
    });

    test('a newly created PENDING QR does not zero the receivable', () {
      final before = TuitionReceivableState.fromJson(row());
      final after = before.withGatewayRequest(
        requestId:'p1',status:'PENDING',qrPayload:'PROVIDER_QR');
      expect(after.payable, isFalse);
      expect(after.phase, TuitionReceivablePhase.waitingPayment);
      expect(after.outstandingAmount, 7150000);
      expect(TuitionReceivableState.totalDebt(<TuitionReceivableState>[after]),
        7150000);
    });

    test('paid receivable is paid even if an old request was pending', () {
      final item = TuitionReceivableState.fromJson(row(balance: 0,
        payable:false,paymentStatus:'PAID',active:<String,dynamic>{
          'paymentRequestId':'stale','status':'PENDING'}));
      expect(item.phase, TuitionReceivablePhase.paid);
      expect(item.action, TuitionReceivableAction.viewDetails);
      expect(item.inPaidTab, isTrue);
      expect(item.inUnpaidTab, isFalse);
    });

    test('expired QR is not recreated automatically while locked', () {
      final item = TuitionReceivableState.fromJson(row(payable:false,
        active:<String,dynamic>{'paymentRequestId':'old','status':'EXPIRED'}));
      expect(item.phase, TuitionReceivablePhase.qrExpired);
      expect(item.action, TuitionReceivableAction.createNewQr);
      expect(item.canCreate, isFalse); // requires /recreate for known ID
    });

    test('cancelled QR can be retried only via gateway rules', () {
      final item = TuitionReceivableState.fromJson(row(payable:false,
        active:<String,dynamic>{'paymentRequestId':'old','status':'CANCELLED'}));
      expect(item.phase, TuitionReceivablePhase.cancelled);
      expect(item.action, TuitionReceivableAction.payAgain);
      expect(item.canCreate, isFalse);
    });

    test('historical expired status without active request allows a new POST only when payable', () {
      final allowed = TuitionReceivableState.fromJson(row(
        latestStatus:'EXPIRED',payable:true));
      final blocked = TuitionReceivableState.fromJson(row(
        latestStatus:'EXPIRED',payable:false));
      expect(allowed.phase, TuitionReceivablePhase.qrExpired);
      expect(allowed.canCreate, isTrue);
      expect(blocked.action, TuitionReceivableAction.none);
      expect(blocked.canCreate, isFalse);
    });

    test('blocked charge still displays with backend blockingReason', () {
      final item = TuitionReceivableState.fromJson(row(
        payable:false,reason:'Khoan thu dang duoc doi soat'));
      expect(item.phase, TuitionReceivablePhase.blocked);
      expect(item.action, TuitionReceivableAction.none);
      expect(item.blockingReason, contains('doi soat'));
      expect(item.inUnpaidTab, isTrue);
    });

    test('partially paid stays in unpaid tab with only outstandingAmount', () {
      final item = TuitionReceivableState.fromJson(row(
        balance:2400000,paymentStatus:'PARTIALLY_PAID'));
      expect(item.phase, TuitionReceivablePhase.unpaid);
      expect(TuitionReceivableState.totalDebt(<TuitionReceivableState>[item]),
        2400000);
    });
  });
}
