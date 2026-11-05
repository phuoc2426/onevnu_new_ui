import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_overview_total.dart';
import 'package:vnu_core/modules/tuition/data/tuition_receivable_lifecycle.dart';

TuitionReceivableState row(String id, int amount, {bool payable = true}) =>
    TuitionReceivableState.fromJson({
      'receivableId': id,
      'outstandingAmount': amount,
      'payable': payable,
      'paymentStatus': 'UNPAID',
    });

void main() {
  test('sum due amounts including locked payable=false and excluding paid', () {
    final total = TuitionOverviewTotal.fromStates([
      row('a', 7150000, payable: false),
      row('b', 11550000),
      row('c', 0),
    ]);
    expect(total.amount, 18700000);
    expect(total.count, 3);
    expect(total.hasRows, true);
    expect(total.isPartiallyUnverified, false);
  });

  test('duplicate receivableId never duplicates total', () {
    final total = TuitionOverviewTotal.fromStates([
      row('a', 7150000), row('a', 7150000)
    ], unverifiedIds: {'a'});
    expect(total.amount, 7150000);
    expect(total.isPartiallyUnverified, true);
  });

  test('empty feed has no certified zero balance', () {
    final total = TuitionOverviewTotal.fromStates([]);
    expect(total.hasRows, false);
    expect(total.amount, 0);
  });
}
