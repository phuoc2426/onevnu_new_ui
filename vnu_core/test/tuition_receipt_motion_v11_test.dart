// Retained under its V11 filename so an existing test checkout compiles after
// applying the V12 change-only pack. V12 intentionally replaces V11's
// after-POST print stage with a pre-GET/POST viewport animation.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_clear_session_overlay.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Lottie clear stays fast at 1.75x', () {
    expect(TuitionClearMotionConfig.playbackSpeed, 1.75);
    expect(TuitionClearMotionConfig.toolbarIconSize, 50);
  });

  test('printer is 20dp larger on EACH side', () {
    expect(TuitionReceiptMotionConfig.printerWidth(393), 433);
    expect(TuitionReceiptMotionConfig.printerBleedPerSide, 20);
    expect(TuitionReceiptMotionConfig.detailMargin, 9);
  });

  testWidgets('tickets enter from right, detail rises from below', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Column(children: [
      TuitionTicketWaveEntrance(index: 0, generation: 1,
        child: SizedBox(width: 210, height: 40,
          child: Text('Ticket', key: ValueKey('wave')))),
      TuitionDetailRiseEntrance(child: SizedBox(width: 210, height: 150,
        child: Text('Details', key: ValueKey('rise')))),
    ]))));
    final waveStart = tester.getTopLeft(find.byKey(const ValueKey('wave')));
    final detailStart = tester.getTopLeft(find.byKey(const ValueKey('rise')));
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.getTopLeft(find.byKey(const ValueKey('wave'))).dx,
      lessThan(waveStart.dx));
    expect(tester.getTopLeft(find.byKey(const ValueKey('rise'))).dy,
      lessThan(detailStart.dy));
    expect(tester.takeException(), isNull);
  });

  test('only explicit expired QR reload starts the printer', () {
    final view = File('lib/modules/tuition/views/vcore_tuition_view.dart')
        .readAsStringSync();
    final methodStart = view.indexOf('Future<void> _reloadExpiredQr() async');
    final nextMethod = view.indexOf('Future<void> _restoreExistingRequest',
      methodStart);
    final method = view.substring(methodStart, nextMethod);
    expect(method.indexOf('_beginQrPrinter(bill)'),
      lessThan(method.indexOf('await api.status(old.id)')));
    expect(method.indexOf('_resolveQrPrinter(true)'),
      greaterThan(method.indexOf('await api.recreate(latest.id)')));
    expect(view, contains('TUITION_PHYSICAL_FEED_V13_20261021'));
  });
}
