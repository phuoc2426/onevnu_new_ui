import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_ticket_paper.dart';

void main() {
  test('A/B tooth displacement is +/-0.3 and follows mask width', () {
    expect(TuitionTicketDefaults.listABWaveAmplitude, 0.3);
    final narrow = TuitionTicketDefaults.listABSeamForWidth(320);
    final wide = TuitionTicketDefaults.listABSeamForWidth(410);
    expect(wide, greaterThan(narrow));
    expect(narrow, greaterThanOrEqualTo(49));
  });

  testWidgets('QR uses a white scanner panel without mint rounded border',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(
      child: TuitionQrBackdrop(child: SizedBox(width: 220, height: 220)),
    ))));
    final decorations = tester.widgetList<DecoratedBox>(
      find.descendant(of: find.byType(TuitionQrBackdrop),
        matching: find.byType(DecoratedBox)),
    );
    expect(decorations.any((box) => box.decoration is BoxDecoration &&
        (box.decoration as BoxDecoration).color == const Color(0xFFF3F8F3)),
      isFalse);
    expect(find.byType(TuitionQrBackdrop), findsOneWidget);
  });

  testWidgets('Detail QR background widget remains independent of frame',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Stack(
      children: [
        TuitionDetailPageBackground(),
        const Center(child: TuitionQrBackdrop(
          child: SizedBox(width: 160, height: 160))),
      ],
    ))));
    expect(TuitionDetailPageBackground.asset,
      'assets/tinktalk/background_qr.png');
    expect(find.byType(TuitionDetailPageBackground), findsOneWidget);
  });
}
