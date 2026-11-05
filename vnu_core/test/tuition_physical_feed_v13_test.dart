import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_physical_feed.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seeded stochastic feed is deterministic, variable and monotonic', () {
    List<double> simulate(int seed) {
      final f = TuitionPhysicalFeed(seed: seed);
      final trace = <double>[];
      for (var i = 0; i < 400; i++) {
        final before = f.progress;
        f.step(1 / 120, speed: 1.25);
        expect(f.progress, greaterThanOrEqualTo(before));
        expect(f.progress, inInclusiveRange(0, 1));
        trace.add(f.progress);
      }
      return trace;
    }
    expect(simulate(12345), simulate(12345));
    expect(simulate(12345), isNot(simulate(12346)));
  });

  test('feed holds at 91 percent before result, then can finish', () {
    final paper = TuitionPhysicalFeed(seed: 2026);
    for (var i = 0; i < 500; i++) {
      paper.step(1 / 120, cap: .91, speed: 1.25);
    }
    expect(paper.progress, closeTo(.91, .001));
    for (var i = 0; i < 350; i++) {
      paper.step(1 / 120, cap: 1, speed: 1.25);
    }
    expect(paper.progress, closeTo(1, .001));
  });

  test('paper uses the real mask, grey QR skeleton and 1.25x by default', () {
    expect(TuitionReceiptMotionConfig.printPlaybackSpeed, 1.25);
    expect(TuitionReceiptMotionConfig.printInkBlur, greaterThan(0));
    expect(TuitionReceiptMotionConfig.printedPaperScale, .76);
    for (final width in [320.0, 360.0, 393.0, 430.0]) {
      expect(TuitionReceiptMotionConfig.printerWidth(width), width + 40);
    }
    final widgetCode = File('lib/modules/tuition/widgets/tuition_receipt_motion.dart')
        .readAsStringSync();
    expect(widgetCode, contains('TuitionTicketKind.detail'));
    expect(widgetCode, contains('TuitionTicketDashedDivider'));
    expect(widgetCode, contains("Icons.qr_code_2_rounded"));
    expect(widgetCode, contains('top: sheetTop'));
    expect(widgetCode, contains('_initialTarget ??= measuredTarget'));
    expect(widgetCode, contains('final finalTarget'));
    expect(widgetCode, contains('imageFilter: ImageFilter.blur('));
    expect(widgetCode, isNot(contains('steppedFeed(')));
    expect(widgetCode, isNot(contains('api.create(')));
    expect(widgetCode, isNot(contains('api.recreate(')));
  });

  test('CREATE and RECREATE each animate, but polling does not', () {
    final code = File('lib/modules/tuition/views/vcore_tuition_view.dart')
        .readAsStringSync();
    final create = code.substring(
      code.indexOf('Future<void> _createOrRecreate() async'),
      code.indexOf('void _beginQrPrinter'));
    final recreate = code.substring(
      code.indexOf('Future<void> _reloadExpiredQr() async'),
      code.indexOf('Future<void> _restoreExistingRequest'));
    expect(create.indexOf('_beginQrPrinter(bill);'),
      lessThan(create.indexOf('await api.create(bill.code)')));
    expect(recreate.indexOf('_beginQrPrinter(bill);'),
      lessThan(recreate.indexOf('await api.status(old.id)')));
    expect(create.indexOf('_resolveQrPrinter(true);'),
      greaterThan(create.indexOf('await api.create(bill.code)')));
    expect(recreate.indexOf('_resolveQrPrinter(true);'),
      greaterThan(recreate.indexOf('await api.recreate(latest.id)')));
    expect(code, contains('TUITION_PHYSICAL_FEED_V13_20261021'));
    final polling = code.substring(
      code.indexOf('void _startPolling('),
      code.indexOf('Future<void> _createOrRecreate() async'));
    expect(polling, isNot(contains('_beginQrPrinter(bill);')));
  });

  testWidgets('visual stage never confirms QR while API pending', (tester) async {
    var done = 0;
    Widget harness(TuitionPrintOutcome outcome) => MaterialApp(
      home: Scaffold(body: Stack(children: [
        const SizedBox.expand(),
        TuitionReceiptPrinterStage(
          key: const ValueKey('printer_stage'),
          attemptSerial: 1,
          outcome: outcome,
          targetRect: () => const Rect.fromLTWH(9, 220, 360, 510),
          outgoingReceipt: const SizedBox(height: 510,
            child: Text('OLD_REQUEST')),
          receipt: const SizedBox(height: 510,
            child: Text('SERVER_CONFIRMED_NEW_REQUEST')),
          title: 'Học phí',
          amount: '7.150.000 đ',
          onFinished: () => done++,
        ),
      ])),
    );
    await tester.pumpWidget(harness(TuitionPrintOutcome.waitingForGateway));
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(done, 0);
    await tester.pumpWidget(harness(TuitionPrintOutcome.succeeded));
    for (var i = 0; i < 120 && done == 0; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    expect(done, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed gateway request restores original receipt', (tester) async {
    var done = 0;
    Widget harness(TuitionPrintOutcome outcome) => MaterialApp(
      home: Scaffold(body: Stack(children: [
        const SizedBox.expand(),
        TuitionReceiptPrinterStage(
          key: const ValueKey('printer_stage'),
          attemptSerial: 2,
          outcome: outcome,
          targetRect: () => const Rect.fromLTWH(9, 220, 360, 510),
          outgoingReceipt: const SizedBox(child: Text('OLD_QR')),
          receipt: const SizedBox(child: Text('NEW_QR')),
          title: 'Học phí', amount: '7.150.000 đ',
          onFinished: () => done++,
        ),
      ])),
    );
    await tester.pumpWidget(harness(TuitionPrintOutcome.waitingForGateway));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(harness(TuitionPrintOutcome.failed));
    for (var i = 0; i < 80 && done == 0; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    expect(done, 1);
    expect(tester.takeException(), isNull);
  });
}
