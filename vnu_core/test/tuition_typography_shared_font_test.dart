import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_premium_ui.dart';

void main() {
  test('The tuition module uses the shared ONEVNU font declaration', () {
    expect(TextStyles.fontName, 'OpenSans');
  });

  testWidgets('Invoice section heading uses compact shared typography', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: TuitionSectionHeading('Danh sách khoản thu')),
    ));
    final text = tester.widget<Text>(find.text('Danh sách khoản thu'));
    expect(text.style?.fontFamily, TextStyles.fontName);
    expect(text.style?.fontSize, lessThanOrEqualTo(16));
  });

  testWidgets('Invoice detail uses shared font and compact row sizes', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: TuitionDetailInfoLine(
        label: 'Hạn thanh toán', value: '15/01/2027',
      )),
    ));
    final label = tester.widget<Text>(find.text('Hạn thanh toán'));
    final value = tester.widget<Text>(find.text('15/01/2027'));
    expect(label.style?.fontFamily, TextStyles.fontName);
    expect(value.style?.fontFamily, TextStyles.fontName);
    expect(label.style?.fontSize, lessThanOrEqualTo(12));
    expect(value.style?.fontSize, lessThanOrEqualTo(12));
  });
}
