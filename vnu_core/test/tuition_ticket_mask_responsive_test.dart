import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_ticket_paper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Safe margins use the furthest visible contour and an 8dp gap', () {
    const metrics = TuitionTicketMaskMetrics(
      sourceRect: Rect.fromLTWH(12, 8, 300, 400),
      cutFraction: EdgeInsets.fromLTRB(0.025, 0.04, 0.04, 0.03),
    );
    final inset = metrics.contentInsets(
      const Size(360, 540),
      minimum: const EdgeInsets.fromLTRB(17, 24, 17, 18),
    );
    expect(inset.left, closeTo(17, 0.01));
    expect(inset.top, closeTo(29.6, 0.01));
    expect(inset.right, closeTo(22.4, 0.01));
    expect(inset.bottom, closeTo(24.2, 0.01));
  });

  testWidgets('Alpha crop removes PNG whitespace and notch changes inset',
      (tester) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const Rect.fromLTRB(12, 8, 112, 78),
      ui.Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(const Offset(111, 43), 8,
      ui.Paint()..blendMode = ui.BlendMode.clear);
    final image = await recorder.endRecording().toImage(130, 90);
    try {
      final metrics = await TuitionTicketMaskMetrics.fromImage(image);
      expect(metrics.sourceRect.left, closeTo(12, 2));
      expect(metrics.sourceRect.top, closeTo(8, 2));
      expect(metrics.sourceRect.right, closeTo(112, 2));
      expect(metrics.sourceRect.bottom, closeTo(78, 2));
      expect(metrics.cutFraction.right, greaterThan(0.02));
      final safe = metrics.contentInsets(const Size(390, 160));
      expect(safe.right, greaterThan(8));
    } finally {
      image.dispose();
    }
  });

  for (final width in <double>[320, 360, 390, 430]) {
    testWidgets('Ticket list at $width dp respects outer margin and footer',
        (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
        child: SizedBox(width: width, child: TuitionListTicketAB(
          indexLabel: '01',
          tint: TuitionTicketDefaults.mint,
          mainContent: const Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Học phí học lại/cải thiện', maxLines: 1,
                overflow: TextOverflow.ellipsis),
              Text('Học kỳ 1 · 2026–2027 · Đợt 2', maxLines: 1,
                overflow: TextOverflow.ellipsis),
              Text('7.150.000 đ'),
              Text('Chờ thanh toán'),
            ]),
          deadline: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.event_outlined, size: 12),
            SizedBox(width: 3),
            Text('15/11/2026'),
          ]),
          onTap: () {},
        )),
      ))));
      await tester.pump();
      final paper = tester.getRect(find.byType(TuitionListTicketAB));
      final b = tester.getRect(find.byType(TuitionTicketSectionB));
      final line = tester.getRect(find.descendant(
        of: find.byType(TuitionTicketSectionB),
        matching: find.byType(TuitionTicketDashedDivider)));
      final arrow = tester.getRect(find.byIcon(Icons.chevron_right_rounded));
      expect(paper.width, closeTo(width, 0.01));
      expect(b.width, lessThan(width - 4));
      expect(line.right, lessThan(arrow.left));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Large text grows the ticket instead of forcing a fixed height',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
      child: SizedBox(width: 320, child: TuitionListTicketAB(
        indexLabel: '02', tint: TuitionTicketDefaults.sand,
        mainContent: const Text('Học phí học lại/cải thiện'),
        deadline: const Text('15/11/2026'),
        onTap: () {},
      )),
    ))));
    expect(tester.getSize(find.byType(TuitionListTicketAB)).height,
      greaterThan(159));
    expect(tester.takeException(), isNull);
  });
}
