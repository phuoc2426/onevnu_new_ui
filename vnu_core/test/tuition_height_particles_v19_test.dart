import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_motion.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_particles.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_tail.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_ticket_paper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('V19 increases BOTH defaults by exactly 30dp', () {
    final page = File('lib/modules/tuition/views/vcore_tuition_view.dart')
        .readAsStringSync();
    expect(page, contains('height: 189,')); // was 159
    expect(page, contains('minHeight: 490,')); // was 460
    expect(TuitionReceiptMotionConfig.paperTailPeek, 52);
    expect(TuitionReceiptMotionConfig.printPlaybackSpeed, 1.25);
  });

  testWidgets('long list content increases paper height and moves next row',
      (tester) async {
    const longTitle = 'Học phí học lại và cải thiện cho sinh viên tham gia '
        'chương trình bổ sung theo quy định của trường, gồm nhiều học phần '
        'ở học kỳ hiện tại và các đợt trước, nội dung cần hiển thị đầy đủ. '
        'Khoản thu dài hơn thông thường và không được tràn khỏi mask.';
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      SingleChildScrollView(child: SizedBox(width: 320, child: Column(
        children: [
          TuitionListTicketAB(
            indexLabel: '01', tint: TuitionTicketDefaults.mint,
            mainContent: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(longTitle, softWrap: true),
                SizedBox(height: 8),
                Text('Học kỳ 1 · 2026–2027 · Đợt bổ sung'),
                Text('7.150.000 đ'),
                Text('Chờ thanh toán'),
              ],
            ),
            deadline: const Text('15/11/2026'),
            onTap: () {},
          ),
          const SizedBox(key: ValueKey('next_card'), height: 40),
        ],
      ))),
    )));
    await tester.pump();
    await tester.pump();
    final ticketRect = tester.getRect(find.byType(TuitionListTicketAB));
    final nextRect = tester.getRect(find.byKey(const ValueKey('next_card')));
    expect(ticketRect.height, greaterThan(189));
    expect(nextRect.top, greaterThanOrEqualTo(ticketRect.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail ticket grows beyond minHeight for very long fields',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      SingleChildScrollView(child: SizedBox(width: 310,
        child: TuitionTicketPaper(
          kind: TuitionTicketKind.detail,
          margin: 0,
          minHeight: 490,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 270),
            const Text('Thông tin chi tiết khoản thu'),
            Text(List.filled(12, 'Nội dung dài theo ngành đào tạo').join(' '),
              softWrap: true),
          ]),
        ),
      )),
    )));
    await tester.pump();
    await tester.pump();
    expect(tester.getSize(find.byType(TuitionTicketPaper)).height,
      greaterThan(490));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hand-drawn tear particles and paper tail paint safely',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body:
      SizedBox(width: 360, height: 520, child: Stack(children: [
        Positioned(top: 10, left: 30, width: 300, height: 110,
          child: TuitionReceiptTail(torn: true)),
        Positioned.fill(child: CustomPaint(
          painter: TuitionReceiptTearParticlePainter(
            progress: .44, left: 30, width: 300, top: 120, seed: 3,
          ),
        )),
      ])),
    )));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('no fixed-step animation or API posting in presentation layer', () {
    final motion = File('lib/modules/tuition/widgets/tuition_receipt_motion.dart')
        .readAsStringSync();
    expect(motion, contains('TuitionReceiptTearParticlePainter'));
    expect(motion, contains('TuitionReceiptTail'));
    expect(motion, contains('paperTailPeek'));
    expect(motion, isNot(contains('steppedFeed(')));
    expect(motion, isNot(contains('api.recreate(')));
    expect(motion, isNot(contains('api.create(')));
  });
}
