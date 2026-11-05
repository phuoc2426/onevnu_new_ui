import 'package:vnu_core/modules/tuition/data/tuition_receivable_lifecycle.dart';

/// Presentation-only summary. NEVER authorizes a new payment request.
/// Receivables are counted by ID; a false `payable` is NOT zero debt.
class TuitionOverviewTotal {
  const TuitionOverviewTotal({required this.amount, required this.count,
      required this.isPartiallyUnverified});

  final int amount;
  final int count;
  final bool isPartiallyUnverified;
  bool get hasRows => count > 0;

  static TuitionOverviewTotal fromStates(
    Iterable<TuitionReceivableState> rows, {
    Set<String> unverifiedIds = const <String>{},
  }) {
    final unique = <String, TuitionReceivableState>{};
    for (final row in rows) {
      if (row.id.trim().isNotEmpty) unique[row.id] = row;
    }
    var total = 0;
    for (final row in unique.values) {
      if (row.outstandingAmount > 0) total += row.outstandingAmount;
    }
    return TuitionOverviewTotal(
      amount: total,
      count: unique.length,
      isPartiallyUnverified:
          unique.keys.any((id) => unverifiedIds.contains(id)),
    );
  }
}
