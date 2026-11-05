import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_animation_demo_page.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_motion.dart';

void main() {
  test('mock lab keeps production print speed default', () {
    expect(TuitionReceiptMotionConfig.printPlaybackSpeed, 1.25);
  });

  testWidgets('mock lab has one-screen controls and no gateway action',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: TuitionAnimationDemoPage()));
    expect(find.byKey(const ValueKey('tuition_demo_success')), findsOneWidget);
    expect(find.byKey(const ValueKey('tuition_demo_failure')), findsOneWidget);
    expect(find.byKey(const ValueKey('tuition_demo_current_qr')), findsOneWidget);
    expect(find.text('KHÔNG GỌI API'), findsOneWidget);
    expect(find.byType(TuitionReceiptPrinterStage), findsNothing);
  });
}
