import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_animation_demo_page.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_motion.dart';

void main() {
  for (final size in const <Size>[
    Size(320, 568),
    Size(360, 720),
    Size(393, 852),
    Size(430, 932),
  ]) {
    testWidgets('preview + controls do not overflow at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
          const MaterialApp(home: TuitionAnimationDemoPage()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('tuition_demo_static_receipt')),
          findsOneWidget);

      final ticket = tester.getRect(find.byKey(
          const ValueKey('tuition_demo_static_receipt')));
      final viewport = tester.getRect(find.byType(TuitionAnimationDemoPage));
      expect(ticket.left, greaterThanOrEqualTo(viewport.left));
      expect(ticket.right, lessThanOrEqualTo(viewport.right));
      expect(ticket.bottom, lessThan(viewport.bottom));
    });
  }

  testWidgets('a print mock does not change QR id before the API finishes',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: TuitionAnimationDemoPage()));
    expect(find.textContaining('QR mẫu #001'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tuition_demo_success')));
    await tester.pump();
    expect(find.byType(TuitionReceiptPrinterStage), findsOneWidget);
    expect(find.textContaining('QR mẫu #001'), findsOneWidget);
  });
}
