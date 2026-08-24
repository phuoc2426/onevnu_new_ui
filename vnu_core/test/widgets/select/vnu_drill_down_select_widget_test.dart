import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/widgets/select/vnu_select.dart';

void main() {
  testWidgets('drill-down keeps draft local until child is selected', (tester) async {
    VnuDrillDownSelection<String, String>? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return VnuDrillDownSelect<String, String>(
                label: 'Địa chỉ',
                hintText: 'Chọn địa chỉ',
                parentTitle: 'Chọn tỉnh',
                childTitle: 'Chọn quận/huyện',
                value: selected,
                groups: const [
                  VnuDrillDownGroup(
                    parent: VnuSelectItem(value: 'hn', label: 'Hà Nội'),
                    children: [
                      VnuSelectItem(value: 'cg', label: 'Cầu Giấy'),
                      VnuSelectItem(value: 'bd', label: 'Ba Đình'),
                    ],
                  ),
                ],
                onSelected: (value) => setState(() => selected = value),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(VnuSelectField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hà Nội'));
    await tester.pumpAndSettle();

    // Parent selection is only draft state; closing the sheet must not commit.
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(selected, isNull);

    await tester.tap(find.byType(VnuSelectField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hà Nội'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cầu Giấy'));
    await tester.pumpAndSettle();

    expect(selected?.parent, 'hn');
    expect(selected?.child, 'cg');
  });
}
