import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_motion.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_animation_demo_page.dart';

void main() {
  test('printer is 40dp wider than its Flutter viewport', () {
    expect(TuitionReceiptMotionConfig.printerWidth(393), 433);
    expect(TuitionReceiptMotionConfig.printerBleedPerSide, 20);
    expect(TuitionReceiptMotionConfig.printPlaybackSpeed, 1.25);
  });

  testWidgets('isolated demo triggers the SAME real physical printer stage',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: TuitionAnimationDemoPage()));
    expect(find.byType(TuitionReceiptPrinterStage), findsNothing);
    await tester.tap(find.byKey(const ValueKey('tuition_demo_success')));
    await tester.pump();
    expect(find.byType(TuitionReceiptPrinterStage), findsOneWidget);
    expect(find.byKey(const ValueKey('tuition_demo_current_qr')), findsOneWidget);
  });
}
