import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fast printer timeline is under one second after quick API success', () {
    final total = TuitionReceiptMotionConfig.printIntroDuration +
        TuitionReceiptMotionConfig.printFinishDuration;
    expect(total.inMilliseconds, lessThan(950));
    expect(TuitionReceiptMotionConfig.acceleratedPullDuration.inMilliseconds,
      lessThan(150));
    expect(TuitionReceiptMotionConfig.oldReceiptExitFraction,
      lessThan(TuitionReceiptMotionConfig.printerArrivalFraction));
  });

  test('printer width bleeds both edges and printed paper stays smaller', () {
    for (final width in <double>[320, 360, 393, 430]) {
      expect(TuitionReceiptMotionConfig.printerWidth(width), width + 40);
    }
    expect(TuitionReceiptMotionConfig.printedPaperScale, lessThan(1));
    expect(TuitionReceiptMotionConfig.printerAsset,
      'assets/tinktalk/printer_bill.png');
  });

  test('V13 physical feed no longer uses fixed 12-step motor motion', () {
    final widgetCode = File('lib/modules/tuition/widgets/tuition_receipt_motion.dart').readAsStringSync();
    expect(widgetCode, isNot(contains('steppedFeed(')));
    expect(TuitionReceiptMotionConfig.printPlaybackSpeed, 1.25);
  });

  test('API is still authoritative, UI never auto-POSTs on animation', () {
    final motion = File('lib/modules/tuition/widgets/tuition_receipt_motion.dart')
        .readAsStringSync();
    final view = File('lib/modules/tuition/views/vcore_tuition_view.dart')
        .readAsStringSync();
    expect(motion, isNot(contains('api.recreate(')));
    expect(motion, isNot(contains('api.create(')));
    final begin = view.indexOf('_beginQrPrinter(bill);');
    final get = view.indexOf('await api.status(old.id);', begin);
    final recreate = view.indexOf('await api.recreate(latest.id);', get);
    final complete = view.indexOf('_resolveQrPrinter(true);', recreate);
    expect(begin, greaterThan(0));
    expect(get, greaterThan(begin));
    expect(recreate, greaterThan(get));
    expect(complete, greaterThan(recreate));
  });

  testWidgets('outgoing sheet starts printing immediately, waits for API',
    (tester) async {
    var finished = 0;
    Widget harness(TuitionPrintOutcome outcome) => MaterialApp(
      home: Scaffold(body: Stack(children: [
        const SizedBox.expand(),
        TuitionReceiptPrinterStage(
          attemptSerial: 1,
          outcome: outcome,
          targetRect: () => const Rect.fromLTWH(9, 240, 375, 510),
          outgoingReceipt: const SizedBox(height: 510,
            child: Text('OLD_QR_RECEIPT')),
          receipt: const SizedBox(height: 510,
            child: Text('NEW_QR_RECEIPT')),
          title: 'Học phí',
          amount: '7.150.000 đ',
          onFinished: () => finished++,
        ),
      ])),
    );

    await tester.pumpWidget(harness(TuitionPrintOutcome.waitingForGateway));
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(finished, 0); // Still waiting: NEVER invent a new QR.
    await tester.pumpWidget(harness(TuitionPrintOutcome.succeeded));
    for (var i = 0; i < 120 && finished == 0; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    expect(finished, 1);
  });
}
