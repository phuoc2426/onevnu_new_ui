import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/widgets/select/vnu_select.dart';

void main() {
  testWidgets('single select commits only the picked option', (tester) async {
    String? selected = 'male';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return VnuSingleSelect<String>(
                label: 'Giới tính',
                value: selected,
                hintText: 'Chọn giới tính',
                items: const [
                  VnuSelectItem(value: 'male', label: 'Nam'),
                  VnuSelectItem(value: 'female', label: 'Nữ'),
                ],
                onChanged: (value) => setState(() => selected = value),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Nam'), findsOneWidget);
    await tester.tap(find.byType(VnuSelectField));
    await tester.pumpAndSettle();

    expect(find.text('Nữ'), findsOneWidget);
    await tester.tap(find.text('Nữ'));
    await tester.pumpAndSettle();

    expect(selected, 'female');
    expect(find.text('Nữ'), findsOneWidget);
  });
}
