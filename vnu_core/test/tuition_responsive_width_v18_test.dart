import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_motion.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_responsive_width.dart';

void main() {
  test('Mobile keeps near-edge tickets, wide Chrome stays phone-sized', () {
    for (final width in <double>[320, 360, 393, 430]) {
      expect(TuitionResponsiveWidth.content(width), width);
      expect(TuitionResponsiveWidth.listPaper(width), width - 8);
      expect(TuitionResponsiveWidth.detailPaper(width), width - 18);
    }
    expect(TuitionResponsiveWidth.content(975), 460);
    expect(TuitionResponsiveWidth.listPaper(975), 452);
    expect(TuitionResponsiveWidth.detailPaper(975), 442);
  });

  for (final width in <double>[320, 393, 430, 975]) {
    testWidgets('Centered rail at viewport width $width', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body:
        SizedBox(width: width, height: 750,
          child: Column(children: [
            TuitionResponsiveFrame(child: Container(
              key: const ValueKey<String>('actual_content'),
              height: 130, color: Colors.white,
            )),
          ]),
        ),
      )));
      final rect = tester.getRect(find.byKey(
          const ValueKey<String>('actual_content')));
      expect(rect.width,
        closeTo(TuitionResponsiveWidth.content(width), 0.1));
      expect(rect.left, closeTo((width - rect.width) / 2, 0.1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Skeleton keeps all below-QR marks bounded, no Flex overflow',
      (tester) async {
    for (final size in <Size>[
      const Size(290, 340),
      const Size(320, 460),
      const Size(442, 560),
    ]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
        child: TuitionPrintingTicketSkeleton(fullSize: size),
      ))));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  test('Payment page has no bank-launch CTA and uses the capped rail', () {
    final text = File('lib/modules/tuition/views/vcore_tuition_view.dart')
        .readAsStringSync();
    expect(text, isNot(contains('Mở ứng dụng ngân hàng để quét mã thanh toán')));
    expect(text, contains('TuitionResponsiveFrame(child: _detailAmount'));
    expect(text, contains('TuitionResponsiveFrame(child: TuitionTicketWaveEntrance'));
  });
}
