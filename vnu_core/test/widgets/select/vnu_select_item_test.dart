import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/widgets/select/vnu_select.dart';

void main() {
  test('VnuSelectItem builds effective search text from label and subtitle', () {
    const item = VnuSelectItem<int>(
      value: 1,
      label: 'Đại học Quốc gia Hà Nội',
      subtitle: 'Hà Nội',
    );

    expect(item.effectiveSearchText, contains('Đại học Quốc gia Hà Nội'));
    expect(item.effectiveSearchText, contains('Hà Nội'));
  });

  test('explicit searchText has priority', () {
    const item = VnuSelectItem<int>(
      value: 1,
      label: 'ĐHQGHN',
      searchText: 'VNU Vietnam National University',
    );

    expect(item.effectiveSearchText, 'VNU Vietnam National University');
  });
}
