import 'package:vnu_core/modules/tuition/data/tuition_receivable_lifecycle.dart';

/// Reconciles the CP1 payable feed against the last known snapshot.
///
/// `payable=false` is a CREATE lock, NOT a reason to hide the receivable.
/// The gateway is authoritative for amounts and settlement WHEN it actually
/// supplies a valid row; an omitted row is not proof that a debt was paid.
/// Omitted rows are retained as unverified, and must NOT authorize new POSTs.
class TuitionPayableReconciliation {
  const TuitionPayableReconciliation({
    required this.states,
    required this.unverifiedIds,
    required this.serverRows,
    required this.invalidRows,
    required this.reusedAmounts,
  });

  final Map<String, TuitionReceivableState> states;
  final Set<String> unverifiedIds;
  final int serverRows;
  final int invalidRows;
  final int reusedAmounts;
  int get retainedCount => unverifiedIds.length;

  /// Render the reconciled receivables, NOT just rows in the last HTTP 200.
  /// When CP1 temporarily omits a known PENDING/locked invoice, it must
  /// remain visible as UNVERIFIED. UI must block any new CREATE/RECREATE
  /// action for IDs in [unverifiedIds] until the server verifies them again.
  Iterable<TuitionReceivableState> get visibleRows => states.values;

  bool get hasUnverifiedRows => unverifiedIds.isNotEmpty;

  static TuitionPayableReconciliation reconcile({
    required List<Map<String, dynamic>> incoming,
    Map<String, TuitionReceivableState> previous = const {},
  }) {
    final states = <String, TuitionReceivableState>{};
    final unverified = <String>{};
    var invalid = 0;
    var recovered = 0;

    for (final source in incoming) {
      final raw = Map<String, dynamic>.from(source);
      final id = (raw['receivableId'] ?? '').toString().trim();
      if (id.isEmpty) {
        invalid++;
        continue;
      }
      final old = previous[id];
      // Some intermediary versions may omit outstandingAmount on a locked
      // payment. Use last confirmed amount ONLY to keep the row visible.
      if ((raw['outstandingAmount'] == null ||
              raw['outstandingAmount'].toString().trim().isEmpty) && old != null) {
        raw['outstandingAmount'] = old.outstandingAmount;
        recovered++;
        unverified.add(id);
      }
      if (old != null) {
        for (final key in <String>[
          'charges', 'collectionPeriodName', 'dueDate', 'totalAmount',
          'receivableAmount', 'amount',
          // Preserve explicit type when a partial payable response omits it.
          // The latest non-null value always remains authoritative.
          'chargeType', 'chargeTypeCode', 'chargeCategory', 'feeType',
          'tuitionType', 'tuitionFeeType', 'tuitionChargeType',
          'receivableType', 'feeCategory', 'category', 'categoryCode', 'type', 'charge_type', 'charge_type_code', 'fee_type',
        ]) {
          if (raw[key] == null && old.source[key] != null) {
            raw[key] = old.source[key];
          }
        }
        // Preserve a known terminal QR as HISTORY, even if the gateway
        // removes activePaymentRequest when its lock is released.
        // A new ACTIVE request still wins the screen/state below.
        final oldLast = old.lastPaymentRequest;
        final freshLast = raw['lastPaymentRequest'] ?? raw['latestPaymentRequest'];
        if (oldLast != null && freshLast == null) {
          raw['lastPaymentRequest'] = oldLast;
          raw.putIfAbsent('lastPaymentRequestStatus',
            () => old.recentRequestStatus);
        } else if (oldLast != null && freshLast is Map) {
          final newest = Map<String,dynamic>.from(freshLast);
          final oldId = (oldLast['paymentRequestId'] ?? oldLast['id'])?.toString();
          final newId = (newest['paymentRequestId'] ?? newest['id'])?.toString();
          if (oldId != null && oldId == newId) {
            raw['lastPaymentRequest'] = <String, dynamic>{...oldLast, ...newest};
          }
        }
        final oldActive = old.activePaymentRequest;
        final freshActive = raw['activePaymentRequest'];
        // The payable feed can lag behind POST create or GET status. Preserve
        // a known PENDING/PROCESSING request even if a stale page incorrectly
        // reports payable=true and omits activePaymentRequest. Only an
        // explicit terminal request state or settlement may release the
        // local guard that prevents a duplicate CREATE request.
        final freshPaymentStatus = (raw['paymentStatus'] ?? '').toString().toUpperCase();
        final settled = raw['outstandingAmount'] == 0 ||
            freshPaymentStatus == 'PAID' || freshPaymentStatus == 'OVERPAID';
        final last = raw['lastPaymentRequest'] ?? raw['latestPaymentRequest'];
        final lastStatus = (raw['lastPaymentRequestStatus'] ??
            (last is Map ? last['status'] : null) ?? '').toString().toUpperCase();
        final ended = const <String>{'PAID', 'EXPIRED', 'CANCELLED'}
            .contains(lastStatus);
        if (!settled && !ended && oldActive != null &&
            freshActive == null &&
            (old.activeStatus == 'PENDING' ||
             old.activeStatus == 'PROCESSING')) {
          raw['activePaymentRequest'] = oldActive;
          raw['payable'] = false; // A known live request always blocks CREATE.
          unverified.add(id);
        }
        // When detail GET has confirmed EXPIRED, ignore an older PAYABLE
        // snapshot still reporting that SAME request as PENDING. The request
        // stays in history, never reactivated by a lagging read-model.
        final recentId = old.lastRequestId;
        final currentActive = raw['activePaymentRequest'];
        if (old.hasExpiredHistory && recentId != null &&
            currentActive is Map) {
          final currentId = (currentActive['paymentRequestId'] ??
              currentActive['activePaymentRequestId'] ??
              currentActive['id'])?.toString();
          if (currentId == recentId &&
              const <String>{'PENDING', 'PROCESSING'}.contains(
                (currentActive['status'] ?? '').toString().toUpperCase())) {
            raw['activePaymentRequest'] = null;
            unverified.add(id);
          }
        }
        // The detail status GET may already know PROCESSING while the list
        // still says PENDING for that SAME paymentRequestId.
        if (!settled && freshActive is Map && oldActive != null &&
            old.activeStatus == 'PROCESSING' &&
            (freshActive['status'] ?? '').toString().toUpperCase() == 'PENDING') {
          final activeId = (freshActive['paymentRequestId'] ??
              freshActive['activePaymentRequestId'] ?? freshActive['id']).toString();
          if (activeId == old.activeRequestId) {
            raw['activePaymentRequest'] = <String, dynamic>{
              ...Map<String, dynamic>.from(freshActive),
              ...oldActive,
              'status': 'PROCESSING',
            };
          }
        }
      }
      try {
        final item = TuitionReceivableState.fromJson(raw);
        if (item.id.isEmpty) {
          invalid++;
          continue;
        }
        states[item.id] = item;
      } catch (_) {
        invalid++;
        // Never turn a temporarily malformed row into a false zero-balance.
        if (old != null) {
          states[id] = old;
          unverified.add(id);
        }
      }
    }

    // Most important case: CP1 returns [] / omits a locked receivable during
    // QR creation, due to gateway lag, a bad cache or a partial response.
    // Retain the last known invoice; don't convert absence into 'PAID'.
    // Such stale rows must not permit a new payment request.
    for (final entry in previous.entries) {
      if (!states.containsKey(entry.key)) {
        states[entry.key] = entry.value;
        unverified.add(entry.key);
      }
    }
    return TuitionPayableReconciliation(
      states: states,
      unverifiedIds: unverified,
      serverRows: incoming.length,
      invalidRows: invalid,
      reusedAmounts: recovered,
    );
  }
}

/// RAM-only, per canonicalStudentId. Never shares a snapshot between students.
/// Does not persist QR data or access tokens to device storage.
/// Call clear() on ONEVNU logout; identity also guards re-entry.
class TuitionReceivableMemoryCache {
  TuitionReceivableMemoryCache._();
  static final TuitionReceivableMemoryCache instance =
      TuitionReceivableMemoryCache._();

  final Map<String, Map<String, TuitionReceivableState>> _byStudent = {};

  Map<String, TuitionReceivableState> read(String canonicalStudentId) =>
      Map<String, TuitionReceivableState>.from(
        _byStudent[canonicalStudentId] ?? const {});

  void write(String canonicalStudentId,
      Map<String, TuitionReceivableState> entries) {
    if (canonicalStudentId.trim().isEmpty) return;
    _byStudent[canonicalStudentId] =
        Map<String, TuitionReceivableState>.from(entries);
  }

  void clear() => _byStudent.clear();
}

