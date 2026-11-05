import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_payable_reconciliation.dart';
import 'package:vnu_core/modules/tuition/data/tuition_receivable_lifecycle.dart';

Map<String, dynamic> bill(String id, int amount, {
    bool payable = true, String status = 'UNPAID',
    Map<String,dynamic>? active,
}) => <String, dynamic>{
  'receivableId': id,
  'outstandingAmount': amount,
  'totalAmount': amount,
  'paymentStatus': status,
  'payable': payable,
  'charges': <Map<String, dynamic>>[
    <String, dynamic>{'name': id == 'hp1' ? 'Học phí' : 'Học lại/cải thiện'},
  ],
  if (active != null) 'activePaymentRequest': active,
};

void main() {
  group('QR locked receivable never disappears', () {
    test('empty payable feed preserves an earlier PENDING QR and its debt', () {
      final locked = TuitionReceivableState.fromJson(bill(
        'hp1', 11550000, payable: false,
        active: <String,dynamic>{'paymentRequestId':'qr-1','status':'PENDING'},
      ));
      final result = TuitionPayableReconciliation.reconcile(
        incoming: const [], previous: <String,TuitionReceivableState>{'hp1':locked});
      expect(result.serverRows, 0);
      expect(result.states.keys, contains('hp1'));
      expect(result.unverifiedIds, contains('hp1'));
      expect(result.states['hp1']!.phase, TuitionReceivablePhase.waitingPayment);
      expect(result.states['hp1']!.canCreate, isFalse);
      expect(TuitionReceivableState.totalDebt(result.states.values), 11550000);
    });

    test('two active QR debts still total 18,700,000 after empty reload', () {
      final a = TuitionReceivableState.fromJson(bill(
        'hp1', 11550000, payable: false,
        active: <String,dynamic>{'paymentRequestId':'p1','status':'PENDING'}));
      final b = TuitionReceivableState.fromJson(bill(
        'hp2', 7150000, payable: false,
        active: <String,dynamic>{'paymentRequestId':'p2','status':'PROCESSING'}));
      final result = TuitionPayableReconciliation.reconcile(incoming: const [],
        previous: <String, TuitionReceivableState>{'hp1':a,'hp2':b});
      expect(result.states, hasLength(2));
      expect(TuitionReceivableState.totalDebt(result.states.values),18700000);
      expect(result.unverifiedIds, hasLength(2));
    });

    test('partial response retains omitted bill but honors confirmed paid item', () {
      final old = <String, TuitionReceivableState>{
        'hp1': TuitionReceivableState.fromJson(bill('hp1',11550000)),
        'hp2': TuitionReceivableState.fromJson(bill('hp2',7150000,
          payable:false,active:<String,dynamic>{'paymentRequestId':'p2','status':'PENDING'})),
      };
      final result = TuitionPayableReconciliation.reconcile(previous:old,
        incoming: <Map<String,dynamic>>[
          bill('hp1',0,payable:false,status:'PAID'),
        ]);
      expect(result.states, hasLength(2));
      expect(result.states['hp1']!.phase,TuitionReceivablePhase.paid);
      expect(result.states['hp2']!.phase,TuitionReceivablePhase.waitingPayment);
      expect(result.unverifiedIds, <String>{'hp2'});
      expect(TuitionReceivableState.totalDebt(result.states.values),7150000);
    });

    test('explicit last EXPIRED defeats an older PENDING snapshot', () {
      final old=TuitionReceivableState.fromJson(bill('hp1',11550000,
        payable:false,active:<String,dynamic>{
          'paymentRequestId':'old','status':'PENDING'}));
      final latest=bill('hp1',11550000,payable:false)
        ..['lastPaymentRequestStatus']='EXPIRED';
      final result=TuitionPayableReconciliation.reconcile(
        incoming:<Map<String,dynamic>>[latest],
        previous:<String,TuitionReceivableState>{'hp1':old});
      expect(result.states['hp1']!.phase,TuitionReceivablePhase.qrExpired);
      expect(result.states['hp1']!.activeRequestId,isNull);
      expect(result.states['hp1']!.canCreate,isFalse);
    });

    test('missing outstandingAmount retains previous, marks it unverified', () {
      final old = TuitionReceivableState.fromJson(bill('hp1',11550000));
      final incoming = bill('hp1',0,payable:false)..remove('outstandingAmount');
      final result = TuitionPayableReconciliation.reconcile(
        incoming:<Map<String,dynamic>>[incoming],
        previous:<String,TuitionReceivableState>{'hp1':old});
      expect(result.invalidRows,0);
      expect(result.reusedAmounts,1);
      expect(result.unverifiedIds,contains('hp1'));
      expect(result.states['hp1']!.outstandingAmount,11550000);
      expect(result.states['hp1']!.canCreate,isFalse);
    });

    test('status GET PROCESSING wins over stale list PENDING for same request', () {
      final previous = TuitionReceivableState.fromJson(bill('hp1',11550000,
        payable:false,active:<String,dynamic>{
          'paymentRequestId':'same','status':'PROCESSING'}));
      final next = TuitionPayableReconciliation.reconcile(
        previous:<String,TuitionReceivableState>{'hp1':previous},
        incoming:<Map<String,dynamic>>[bill('hp1',11550000,
          payable:false,active:<String,dynamic>{
          'paymentRequestId':'same','status':'PENDING'})]);
      expect(next.states['hp1']!.phase,TuitionReceivablePhase.processing);
    });

    test('fresh locked row with active QR remains visible without earlier memory', () {
      final next = TuitionPayableReconciliation.reconcile(
        incoming:<Map<String,dynamic>>[bill('hp1',11550000,
          payable:false,active:<String,dynamic>{
            'paymentRequestId':'qr-from-backend','status':'PENDING',
            'qr':<String,dynamic>{'payload':'gateway-value'},
          })]);
      expect(next.states,hasLength(1));
      expect(next.unverifiedIds,isEmpty);
      expect(next.states['hp1']!.activeRequestId,'qr-from-backend');
    });

    test('numeric strings with thousands separators are not discarded', () {
      final source = bill('hp1',11550000);
      source['outstandingAmount'] = '11.550.000 đ';
      final next=TuitionPayableReconciliation.reconcile(
        incoming:<Map<String,dynamic>>[source]);
      expect(next.invalidRows,0);
      expect(next.states['hp1']!.outstandingAmount,11550000);
    });

    test('inconsistent PAID but positive balance still counts towards debt', () {
      final item=TuitionReceivableState.fromJson(
        bill('hp1',11550000,payable:false,status:'PAID'));
      expect(item.inUnpaidTab,isTrue);
      expect(item.inPaidTab,isFalse);
      expect(item.phase,TuitionReceivablePhase.processing);
      expect(TuitionReceivableState.totalDebt([item]),11550000);
    });

    test('snapshot cache cannot mix different canonical student ids', () {
      final cache=TuitionReceivableMemoryCache.instance;
      cache.clear();
      cache.write('student-A',<String,TuitionReceivableState>{
        'hp1':TuitionReceivableState.fromJson(bill('hp1',11550000)),
      });
      expect(cache.read('student-A'),hasLength(1));
      expect(cache.read('student-B'),isEmpty);
      cache.clear();
      expect(cache.read('student-A'),isEmpty);
    });
  });
}
