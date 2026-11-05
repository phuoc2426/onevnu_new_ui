import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/views/vcore_tuition_view.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_ticket_paper.dart';

void main() {
  testWidgets('List ticket stitches are separate masked overlay widgets',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: TuitionTicketPaper(
        kind: TuitionTicketKind.list,
        showListStitches: true,
        minHeight: 153,
        child: Text('Học phí'),
      ),
    )));
    expect(find.text('Học phí'), findsOneWidget);
    expect(find.byType(TuitionTicketStitchOverlays), findsOneWidget);
  });

  testWidgets('Compact overview hides sync/security marketing and has tabs',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home:
      VcoreTuitionView(universityId: 0, developerPreview: true)));
    await tester.pump();
    expect(find.text('Khoản thu của bạn'), findsOneWidget);
    expect(find.text('Cần thanh toán'), findsOneWidget);
    expect(find.text('Đã thanh toán'), findsWidgets);
    expect(find.textContaining('Đồng bộ lúc'), findsNothing);
    expect(find.textContaining('Bảo vệ dữ liệu thanh toán'), findsNothing);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.toolbarHeight, 49);
  });

  testWidgets('Detail QR has compact green background and four outer corners',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home:
      VcoreTuitionView(universityId: 0, developerPreview: true)));
    await tester.pump();
    // The first ticket is fully clickable; no external API call in preview.
    await tester.tap(find.text('Học phí học kỳ I').first);
    await tester.pump();
    expect(find.byType(TuitionQrBackdrop), findsOneWidget);
    expect(find.text('Quét mã để thanh toán'), findsOneWidget);
    expect(find.textContaining('Tự đồng bộ trạng thái sau mỗi 5 giây'), findsNothing);
    expect(find.textContaining('Thanh toán an toàn qua ULIS'), findsNothing);
  });
}
