import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/one_door/views/vcore_one_door_view.dart';
import 'package:vnu_core/modules/tuition/views/vcore_tuition_view.dart';

void main() {
  testWidgets('system back from procedure detail returns to list',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VcoreOneDoorView()));
    await tester.pumpAndSettle();
    expect(find.text('Thủ tục hành chính'), findsOneWidget);
    await tester.tap(find.text('Giấy xác nhận sinh viên (Tiếng Anh)').first);
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết thủ tục'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Thủ tục hành chính'), findsOneWidget);
  });

  testWidgets('system back from first form step returns to procedure detail',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VcoreOneDoorView()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giấy xác nhận sinh viên (Tiếng Anh)').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bắt đầu nộp hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('Nộp hồ sơ'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết thủ tục'), findsOneWidget);
  });

  testWidgets('system back from tuition detail returns to bill list',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: VcoreTuitionView(universityId: 4),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Học phí học kỳ I').first);
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết khoản thu'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán học phí'), findsOneWidget);
  });

  testWidgets('tuition remains blocked for non-ULIS in non-preview mode',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: VcoreTuitionView(universityId: 5),
    ));
    expect(find.textContaining('dành cho sinh viên Trường Đại học Ngoại ngữ'),
      findsOneWidget);
    expect(find.text('Học phí học kỳ I'), findsNothing);
  });
}
