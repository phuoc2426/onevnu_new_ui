import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_charge_category.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_stable_qr.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_ticket_paper.dart';

const _png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1Pe'
    'AAAADElEQVR4nGP4//8/AAX+Av4N70a4AAAAAElFTkSuQmCC';

Widget _screen(Widget child) => MaterialApp(home: Scaffold(body: Center(
  child: SizedBox(width: 390, child: child))));

void main() {
  test('four exact types get distinct tints; unknown is mint/sand even', () {
    final tint = TuitionTicketDefaults.tintForCategory;
    expect(tint(TuitionChargeCategory.firstTime, 1), TuitionTicketDefaults.mint);
    expect(tint(TuitionChargeCategory.retake, 0), TuitionTicketDefaults.sand);
    expect(tint(TuitionChargeCategory.improvement, 1), TuitionTicketDefaults.lavender);
    expect(tint(TuitionChargeCategory.outOfProgram, 0), TuitionTicketDefaults.sky);
    expect(tint(null, 0), TuitionTicketDefaults.mint);
    expect(tint(null, 1), TuitionTicketDefaults.sand);
    expect(tint(null, 2), TuitionTicketDefaults.mint);
    expect({for (final c in TuitionChargeCategory.values) tint(c, 0)}.length, 4);
  });

  testWidgets('A1 plus arrow B sit ABOVE deadline A2', (tester) async {
    await tester.pumpWidget(_screen(TuitionListTicketAB(
      indexLabel: '01',
      tint: TuitionTicketDefaults.sand,
      leadingIcon: const Icon(Icons.school, key: ValueKey('tuition_icon_A')),
      mainContent: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Học phí học lại/cải thiện'),
          Text('7.150.000 đ'),
          Text('Chờ thanh toán  12:45'),
        ],
      ),
      deadline: const Text('Hạn nộp 15/11/2026'),
      onTap: () {},
    )));
    await tester.pump();

    final icon = tester.getRect(find.byKey(const ValueKey('tuition_icon_A')));
    final title = tester.getRect(find.text('Học phí học lại/cải thiện'));
    final arrow = tester.getRect(find.byKey(
      const ValueKey('tuition_ticket_arrow_B')));
    final due = tester.getRect(find.text('Hạn nộp 15/11/2026'));
    final dash = tester.getRect(find.descendant(
      of: find.byType(TuitionTicketSectionB),
      matching: find.byType(TuitionTicketDashedDivider)));

    expect(icon.right, lessThan(title.left));
    expect(title.right, lessThan(arrow.left));
    expect(arrow.bottom, lessThan(due.top));
    expect(dash.width, lessThanOrEqualTo(170));
    expect(dash.bottom, lessThan(due.top));
    expect(dash.right, lessThan(arrow.right));
  });

  testWidgets('same QR payload survives status GET without new image bytes',
      (tester) async {
    Widget qr(TuitionPaymentRequest request) => _screen(TuitionStableQr(
      request: request, size: 210,
      placeholderBuilder: (message) => Text(message),
    ));
    await tester.pumpWidget(qr(const TuitionPaymentRequest(
      id: 'request-A', status: 'PENDING', imageBase64: _png)));
    final before = tester.widget<Image>(find.byKey(
      const ValueKey('tuition_stable_qr_image')));
    final bytesBefore = (before.image as MemoryImage).bytes;

    await tester.pumpWidget(qr(const TuitionPaymentRequest(
      id: 'request-A', status: 'PROCESSING', imageBase64: _png)));
    final after = tester.widget<Image>(find.byKey(
      const ValueKey('tuition_stable_qr_image')));
    expect(identical(bytesBefore, (after.image as MemoryImage).bytes), isTrue);

    // Only a NEW payment request is allowed to replace the cached QR source.
    await tester.pumpWidget(qr(const TuitionPaymentRequest(
      id: 'request-B', status: 'PENDING', imageBase64: _png)));
    final changed = tester.widget<Image>(find.byKey(
      const ValueKey('tuition_stable_qr_image')));
    expect(identical(bytesBefore, (changed.image as MemoryImage).bytes), isFalse);
  });

  testWidgets('expired QR reload control is green and independently tappable',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_screen(TuitionQrReloadOverlay(
      onPressed: () => taps++,
    )));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Tạo lại mã QR'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tuition_qr_reload_overlay')));
    expect(taps, 1);

    await tester.pumpWidget(_screen(const TuitionQrReloadOverlay(
      onPressed: null, busy: true)));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Đang tạo mã...'), findsOneWidget);
  });
}
