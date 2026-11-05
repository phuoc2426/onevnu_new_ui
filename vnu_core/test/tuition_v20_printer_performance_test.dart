import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('short PNG head always bleeds 20dp per side', () {
    for (final width in <double>[320, 360, 393, 440, 975]) {
      expect(TuitionReceiptMotionConfig.printerWidth(width), width + 40);
      expect(TuitionReceiptMotionConfig.printerHeight(width), inInclusiveRange(46.0, 64.0));
    }
    expect(TuitionReceiptMotionConfig.printPlaybackSpeed, 1.25);
  });

  test('animation target only fits the viewport; original bill may be taller', () {
    const screen = Size(440, 890); // 440x956 minus AppBar/body chrome.
    const raw = Rect.fromLTWH(9, 180, 422, 1600);
    final preview = TuitionReceiptMotionConfig.visiblePreviewRect(raw, screen);
    expect(preview.top, 180);
    expect(preview.width, 422);
    expect(preview.bottom, lessThanOrEqualTo(screen.height));
    expect(preview.height, lessThan(raw.height));

    const narrow = Size(320, 504);
    final compact = TuitionReceiptMotionConfig.visiblePreviewRect(
      const Rect.fromLTWH(9, 175, 302, 1800), narrow);
    expect(compact.bottom, lessThanOrEqualTo(narrow.height));
  });

  testWidgets('long original QR does not force a RenderFlex overflow in the foreground',
      (tester) async {
    var finished = 0;
    Widget receipt(String tag) => SizedBox(width: 422, child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(tag),
        for (var n = 0; n < 25; n++)
          const Text('Truong Dai hoc Ngoai ngu - noi dung rat dai, '
              'du lieu thong tin hoc phi va ma giao dich 123456789'),
      ],
    ));
    Widget stage(TuitionPrintOutcome outcome) => MaterialApp(home: Scaffold(
      body: SizedBox(width: 440, height: 890, child: Stack(children: [
        TuitionReceiptPrinterStage(
          attemptSerial: 42,
          outcome: outcome,
          targetRect: () => const Rect.fromLTWH(9, 180, 422, 1600),
          outgoingReceipt: receipt('OLD'),
          receipt: receipt('NEW'),
          title: 'Hoc phi',
          amount: '7.150.000 d',
          onFinished: () => finished++,
        ),
      ])),
    ));
    await tester.pumpWidget(stage(TuitionPrintOutcome.waitingForGateway));
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);
    expect(finished, 0);
    await tester.pumpWidget(stage(TuitionPrintOutcome.succeeded));
    for (var i = 0; i < 120 && finished == 0; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(finished, 1);
  });

  testWidgets('failed CREATE/RECREATE does not switch to success',
      (tester) async {
    var completed = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      SizedBox(width: 393, height: 740, child: Stack(children: [
        TuitionReceiptPrinterStage(
          attemptSerial: 18,
          outcome: TuitionPrintOutcome.failed,
          targetRect: () => const Rect.fromLTWH(9, 130, 375, 690),
          outgoingReceipt: const SizedBox(height: 690),
          receipt: const SizedBox(height: 690),
          title: 'Mock', amount: '7.150.000 d',
          onFinished: () => completed++,
        ),
      ])),
    )));
    for (var i = 0; i < 90 && completed == 0; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(completed, 1);
  });

  test('source retains one moving paper, five particle clusters and zero API posts', () {
    final motion = File('lib/modules/tuition/widgets/tuition_receipt_motion.dart')
        .readAsStringSync();
    final view = File('lib/modules/tuition/views/vcore_tuition_view.dart')
        .readAsStringSync();
    final particles = File('lib/modules/tuition/widgets/tuition_receipt_particles.dart')
        .readAsStringSync();
    expect(motion, contains('_TuitionPaperFeedClipper'));
    expect(motion, contains('ValueKey(\'tuition_physical_paper\')'));
    expect(motion, contains('Transform.translate('));
    expect(motion, contains('RepaintBoundary('));
    expect(motion, isNot(contains('ImageFiltered(')));
    expect(motion, isNot(contains('api.create(')));
    expect(motion, isNot(contains('api.recreate(')));
    expect(particles, contains('cluster < 5'));
    expect(view, isNot(contains('position.pixels + overflow')));
  });
}
