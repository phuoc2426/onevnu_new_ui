import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/widgets/field/vnu_horizontal_readable_value.dart';
import 'package:vnu_core/widgets/vnu_module_app_bar.dart';

void main() {
  testWidgets('module app bar keeps long title horizontally readable',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: VnuModuleAppBar(
            title:
                'Thông tin đăng ký chương trình trao đổi sinh viên quốc tế rất dài',
          ),
          body: SizedBox.shrink(),
        ),
      ),
    );

    expect(find.byType(VnuHorizontalReadableValue), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
