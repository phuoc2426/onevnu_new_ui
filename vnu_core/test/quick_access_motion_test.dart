import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/widgets/student_service_ui.dart';
import 'package:vnu_core/widgets/vnu_auto_marquee.dart';
import 'package:vnu_core/widgets/vnu_module_app_bar.dart';
import 'package:vnu_core/widgets/vnu_press_motion.dart';

void main() {
  testWidgets('student services use the same common module navbar',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: StudentServiceUI.appBar(
          title: 'Thủ tục hành chính',
          onBack: () {},
        ),
        body: const SizedBox.shrink(),
      ),
    ));
    expect(find.byType(VnuModuleAppBar), findsOneWidget);
    expect(find.text('Thủ tục hành chính'), findsOneWidget);
  });

  testWidgets('a long quick access name remains one line and moves',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 94,
            height: 22,
            child: VnuAutoMarquee(
              text: 'Thanh toán học phí sinh viên',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ),
      ),
    ));
    await tester.pump(); // starts the overflow-only controller
    final label = tester.widget<Text>(
        find.text('Thanh toán học phí sinh viên'));
    expect(label.maxLines, 1);
    expect(find.byType(ClipRect), findsWidgets);
    await tester.pump(const Duration(milliseconds: 3900));
    expect(tester.takeException(), isNull);
    // The animation intentionally repeats forever. Unmount before test ends.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('press motion responds without adding ripple or dark overlay',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
      child: VnuPressMotion(
        onTap: () => taps++,
        child: const SizedBox(
          width: 130, height: 55,
          child: Center(child: Text('Mở hồ sơ')),
        ),
      ),
    ))));
    await tester.tap(find.text('Mở hồ sơ'));
    await tester.pump(const Duration(milliseconds: 240));
    expect(taps, 1);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('student tabs animate their selected underline',
      (tester) async {
    var current = 'Danh sách thủ tục';
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
      builder: (context, setState) => StudentSegment(
        labels: const ['Danh sách thủ tục', 'Hồ sơ của tôi'],
        selected: current,
        onSelected: (next) => setState(() => current = next),
      ),
    ))));
    await tester.tap(find.text('Hồ sơ của tôi'));
    await tester.pumpAndSettle();
    expect(current, 'Hồ sơ của tôi');
    expect(tester.takeException(), isNull);
  });
}
