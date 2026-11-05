import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_ticket_paper.dart';

void main() {
  testWidgets('A and B are structurally separate sections; deadline and arrow',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(
      width: 390,
      child: TuitionListTicketAB(
        indexLabel: '01',
        tint: TuitionTicketDefaults.mint,
        mainContent: const Text('Học phí học lại/cải thiện'),
        deadline: const Text('15/11/2026'),
        onTap: () {},
      ),
    ))));
    await tester.pump();
    expect(find.byType(TuitionTicketSectionA), findsOneWidget);
    expect(find.byType(TuitionTicketSectionB), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('Học phí học lại/cải thiện'), findsOneWidget);
    expect(find.text('15/11/2026'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    // The old full-width dashed overlay must not be used in the new A/B card.
    expect(find.byType(TuitionTicketStitchOverlays), findsNothing);
    // Exactly one short rule: child of B's independent deadline box.
    final b = find.byType(TuitionTicketSectionB);
    expect(find.descendant(of: b,
      matching: find.byType(TuitionTicketDashedDivider)), findsOneWidget);
    final divider = tester.widget<TuitionTicketDashedDivider>(
      find.descendant(of: b,
        matching: find.byType(TuitionTicketDashedDivider)));
    expect(divider.sideInset, 0);
    final ticket = tester.widget<TuitionListTicketAB>(
      find.byType(TuitionListTicketAB));
    expect(ticket.margin, 4);
    expect(ticket.height, greaterThanOrEqualTo(155));
  });

  testWidgets('Detail page background is separate from white QR frame',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Stack(
      children: [
        TuitionDetailPageBackground(),
        Center(child: TuitionQrBackdrop(
          child: SizedBox(width: 150, height: 150))),
      ],
    ))));
    await tester.pump();
    expect(find.byType(TuitionDetailPageBackground), findsOneWidget);
    expect(find.byType(TuitionQrBackdrop), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
