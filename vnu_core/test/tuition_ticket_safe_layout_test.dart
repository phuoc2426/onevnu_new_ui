import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_ticket_paper.dart';

void main() {
  testWidgets('Ticket fills phone width but both content areas stay inset',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
      child: SizedBox(width: 390, child: TuitionListTicketAB(
        indexLabel: '01', tint: TuitionTicketDefaults.mint,
        mainContent: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Học phí học lại/cải thiện'), Text('7.150.000 đ')],
        ),
        deadline: const Text('15/11/2026'),
        onTap: () {},
      )),
    ))));
    await tester.pump();

    final ticket = tester.widget<TuitionListTicketAB>(find.byType(TuitionListTicketAB));
    expect(ticket.margin, 4);
    expect(ticket.height, 159);

    final sectionB = tester.getRect(find.byType(TuitionTicketSectionB));
    final title = tester.getRect(find.text('Học phí học lại/cải thiện'));
    final index = tester.getRect(find.text('01'));
    final divider = tester.getRect(find.descendant(
      of: find.byType(TuitionTicketSectionB),
      matching: find.byType(TuitionTicketDashedDivider)));
    final arrow = tester.getRect(find.byIcon(Icons.chevron_right_rounded));
    final deadline = tester.getRect(find.text('15/11/2026'));
    expect(title.left, greaterThanOrEqualTo(sectionB.left + 10));
    expect(index.right, lessThan(title.left));
    expect(divider.width, lessThanOrEqualTo(170));
    expect(divider.right, lessThan(arrow.left));
    expect(deadline.right, lessThan(arrow.left));
    expect(title.right, lessThanOrEqualTo(sectionB.right));
  });

  testWidgets('Detail mask wraps all text in one shared safe area',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(
      child: SizedBox(width: 390, child: TuitionTicketPaper(
        kind: TuitionTicketKind.detail,
        margin: 12,
        minHeight: 435,
        child: Text('Thông tin khoản thu'),
      )),
    ))));
    await tester.pump();
    final outer = tester.getRect(find.byType(TuitionTicketPaper));
    final content = tester.getRect(find.text('Thông tin khoản thu'));
    expect(content.left, greaterThanOrEqualTo(outer.left + 12 + 17));
    expect(content.top, greaterThanOrEqualTo(outer.top + 24));
  });
}
