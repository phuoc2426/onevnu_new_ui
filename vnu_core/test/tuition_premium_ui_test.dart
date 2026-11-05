import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_demo_repository.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_premium_ui.dart';

void main() {
  group('Tuition UI state contract', () {
    test('pending is scannable, actively watched and not recreatable', () {
      final state = TuitionStatusPresentation.from(TuitionPaymentStatus.pending);
      expect(state.label, 'Chờ thanh toán');
      expect(state.dimQr, isFalse);
      expect(state.watch, isTrue);
      expect(state.allowRecreate, isFalse);
    });

    test('processing dims QR but continues watching', () {
      final state = TuitionStatusPresentation.from(TuitionPaymentStatus.processing);
      expect(state.label, 'Đang giao dịch');
      expect(state.dimQr, isTrue);
      expect(state.watch, isTrue);
      expect(state.allowRecreate, isFalse);
    });

    test('paid dims QR and terminates polling', () {
      final state = TuitionStatusPresentation.from(TuitionPaymentStatus.paid);
      expect(state.label, 'Đã thanh toán');
      expect(state.dimQr, isTrue);
      expect(state.watch, isFalse);
      expect(state.allowRecreate, isFalse);
    });

    test('expired and cancelled require explicit recreation', () {
      for (final status in <TuitionPaymentStatus>[
        TuitionPaymentStatus.expired, TuitionPaymentStatus.cancelled,
      ]) {
        final state = TuitionStatusPresentation.from(status);
        expect(state.dimQr, isTrue);
        expect(state.watch, isFalse);
        expect(state.allowRecreate, isTrue);
      }
    });
  });

  test('gateway provider and QR survive a status response without QR', () {
    final created = TuitionPaymentRequest.fromJson(<String, dynamic>{
      'paymentRequestId': 'request-a',
      'status': 'PENDING',
      'qr': <String, dynamic>{'payload': 'PROVIDER-QR', 'provider': 'BIDV'},
      'expiresAt': '2026-10-18T12:00:00Z',
    });
    final status = TuitionPaymentRequest.fromJson(<String, dynamic>{
      'paymentRequestId': 'request-a', 'status': 'PROCESSING',
      'updatedAt': '2026-10-18T11:59:00Z',
    }).merge(created);

    expect(status.status, 'PROCESSING');
    expect(status.payload, 'PROVIDER-QR');
    expect(status.provider, 'BIDV');
    expect(status.expiresAt, isNotNull);
  });

  testWidgets('processing status presents bank processing and its update time',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TuitionStatusCard(
      status: TuitionPaymentStatus.processing,
      provider: 'BIDV',
      lastUpdated: DateTime(2026, 10, 18, 16, 45),
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Đang giao dịch'), findsOneWidget);
    expect(find.textContaining('Cập nhật 16:45'), findsOneWidget);
  });
}
