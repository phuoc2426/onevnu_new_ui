import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/widgets/field/vnu_field.dart';
import 'package:vnu_core/widgets/select/vnu_select.dart';

void main() {
  const longValue =
      'Trường Đại học Khoa học Xã hội và Nhân văn, Đại học Quốc gia Hà Nội';

  Widget testHost(Widget child, {double textScale = 1}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 640),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('long select value stays one line and exposes horizontal scroll',
      (tester) async {
    await tester.pumpWidget(
      testHost(
        const VnuSelectField(
          label: 'Đơn vị đào tạo',
          displayText: longValue,
          placeholder: 'Chọn đơn vị',
        ),
        textScale: 2,
      ),
    );

    expect(find.byType(VnuHorizontalReadableValue), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single-line text field remains single line at large text scale',
      (tester) async {
    final controller = TextEditingController(text: longValue);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      testHost(
        VnuTextField(
          label: 'Họ và tên',
          controller: controller,
          maxLines: 1,
        ),
        textScale: 2,
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.maxLines, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiline text field keeps vertical wrapping behavior',
      (tester) async {
    final controller = TextEditingController(text: longValue);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      testHost(
        VnuTextField(
          label: 'Nội dung',
          controller: controller,
          minLines: 2,
          maxLines: 4,
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.maxLines, 4);
    expect(tester.takeException(), isNull);
  });
}
