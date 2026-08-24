import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/common/hoc_ky_date_helper.dart';

void main() {
  group('HocKyDateHelper P0 calendar invariant', () {
    final range = HocKyDateRange(
      start: DateTime(2023, 2, 1),
      end: DateTime(2023, 6, 30),
    );

    test('clamps a date before firstDay to firstDay', () {
      expect(
        HocKyDateHelper.clampToRange(DateTime(2023, 1, 5), range),
        DateTime(2023, 2, 1),
      );
    });

    test('keeps a date inside range unchanged', () {
      expect(
        HocKyDateHelper.clampToRange(DateTime(2023, 3, 15), range),
        DateTime(2023, 3, 15),
      );
    });

    test('clamps a date after lastDay to lastDay', () {
      expect(
        HocKyDateHelper.clampToRange(DateTime(2023, 7, 12), range),
        DateTime(2023, 6, 30),
      );
    });

    test('expands range to include real event dates outside semester metadata', () {
      final expanded = HocKyDateHelper.expandRangeToInclude(
        range,
        <DateTime>[
          DateTime(2023, 1, 5),
          DateTime(2023, 2, 6),
        ],
      );

      expect(expanded.start, DateTime(2023, 1, 5));
      expect(expanded.end, DateTime(2023, 6, 30));
    });
  });
}
