import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_demo_repository.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_ticket_paper.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_status_motion.dart';

void main() {
  test('all gateway states map to the user Lottie filenames', () {
    expect(TuitionStatusMotion.assetFor(TuitionPaymentStatus.pending), 'waiting.json');
    expect(TuitionStatusMotion.assetFor(TuitionPaymentStatus.processing), 'processing.json');
    expect(TuitionStatusMotion.assetFor(TuitionPaymentStatus.paid), 'success.json');
    expect(TuitionStatusMotion.assetFor(TuitionPaymentStatus.expired), 'expire.json');
    expect(TuitionStatusMotion.assetFor(TuitionPaymentStatus.cancelled), 'cancel.json');
    expect(TuitionStatusMotion.assetFor(null, wallet: true), 'wallet.json');
  });

  testWidgets('responsive ticket reserves safe content and separate dashed border',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: TuitionTicketPaper(
        kind: TuitionTicketKind.detail,
        child: Column(children: [
          Padding(padding: EdgeInsets.all(25), child: Text('Khoản thu mẫu')),
          TuitionTicketDashedDivider(sideInset: 10),
          Padding(padding: EdgeInsets.all(25), child: Text('Thông tin khoản thu')),
        ]),
      )),
    )));
    expect(find.text('Khoản thu mẫu'), findsOneWidget);
    expect(find.text('Thông tin khoản thu'), findsOneWidget);
    expect(find.byType(TuitionTicketDashedDivider), findsOneWidget);
    final frame = tester.getSize(find.byType(TuitionTicketPaper));
    expect(frame.width, greaterThan(240));
  });
}
