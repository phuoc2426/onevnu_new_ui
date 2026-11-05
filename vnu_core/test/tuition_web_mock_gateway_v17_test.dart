import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_demo_repository.dart';
import 'package:vnu_core/modules/tuition/data/tuition_web_mock_gateway.dart';

void main() {
  test('Real-layout mock has 2 invoices and an outstanding total of 18.7m', () {
    final gateway = TuitionWebMockGateway();
    expect(gateway.bills.length, 2);
    expect(gateway.bills.fold<int>(0, (a, b) => a + b.amount), 18700000);
    expect(gateway.bills.first.status, TuitionPaymentStatus.expired);
    expect(gateway.requestFor(gateway.bills.first.code)?.status, 'EXPIRED');
  });

  test('Mock RECREATE success changes the QR only after completion', () async {
    final gateway = TuitionWebMockGateway();
    gateway.responseDelay = Duration.zero;
    final bill = gateway.bills.first;
    final old = gateway.requestFor(bill.code)!;
    final future = gateway.createOrRecreate(bill.code);
    expect(gateway.requestFor(bill.code)?.id, old.id);
    final next = await future;
    expect(next.id, isNot(old.id));
    expect(next.payload, contains('MOCK-NOT-FOR-PAYMENT'));
    expect(gateway.requestFor(bill.code)?.id, next.id);
    expect(bill.status, TuitionPaymentStatus.pending);
  });

  test('Mock RECREATE failure retains old QR, ready for a new tap', () async {
    final gateway = TuitionWebMockGateway();
    gateway.responseDelay = Duration.zero;
    final bill = gateway.bills.first;
    final previous = gateway.requestFor(bill.code)!;
    gateway.failNextCreate = true;
    await expectLater(gateway.createOrRecreate(bill.code), throwsStateError);
    expect(gateway.requestFor(bill.code)?.id, previous.id);
    expect(gateway.requestFor(bill.code)?.payload, previous.payload);
    expect(bill.status, TuitionPaymentStatus.expired);
    expect(gateway.failNextCreate, isFalse);
  });

  test('Cannot RECREATE while PENDING; can do so only after mock expiry', () async {
    final gateway = TuitionWebMockGateway();
    gateway.responseDelay = Duration.zero;
    final bill = gateway.bills.last;
    final pending = gateway.requestFor(bill.code)!;
    await expectLater(gateway.createOrRecreate(bill.code), throwsStateError);
    expect(gateway.requestFor(bill.code)?.id, pending.id);
    expect(gateway.expire(bill.code), isTrue);
    expect(gateway.requestFor(bill.code)?.status, 'EXPIRED');
    final newRequest = await gateway.createOrRecreate(bill.code);
    expect(newRequest.status, 'PENDING');
  });

  test('First-time CREATE is simulated without any real gateway call', () async {
    final gateway = TuitionWebMockGateway();
    gateway.responseDelay = Duration.zero;
    final bill = gateway.bills.first;
    expect(gateway.clearRequest(bill.code), isTrue);
    expect(gateway.requestFor(bill.code), isNull);
    final result = await gateway.createOrRecreate(bill.code);
    expect(result.status, 'PENDING');
    expect(result.payload, contains('NOT-FOR-PAYMENT'));
  });

}
