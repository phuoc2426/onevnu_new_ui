/// Business state of a *receivable*, independent from whether the gateway
/// currently permits the creation of another payment request.
///
/// Invariant: payable=false NEVER means that this receivable is hidden.
/// All three overview tabs are derived from outstandingAmount/paymentStatus.
enum TuitionReceivablePhase {
  unpaid,
  waitingPayment,
  processing,
  qrExpired,
  cancelled,
  paid,
  blocked,
}

enum TuitionReceivableAction {
  pay,
  continuePayment,
  viewStatus,
  createNewQr,
  payAgain,
  viewDetails,
  none,
}

extension TuitionReceivablePhaseText on TuitionReceivablePhase {
  String get label => switch (this) {
    TuitionReceivablePhase.unpaid => 'Chưa thanh toán',
    TuitionReceivablePhase.waitingPayment => 'Chờ thanh toán',
    TuitionReceivablePhase.processing => 'Đang giao dịch',
    TuitionReceivablePhase.qrExpired => 'Mã hết hạn',
    TuitionReceivablePhase.cancelled => 'Đã hủy',
    TuitionReceivablePhase.paid => 'Đã thanh toán',
    TuitionReceivablePhase.blocked => 'Chưa thể thanh toán',
  };
}

extension TuitionReceivableActionText on TuitionReceivableAction {
  String get label => switch (this) {
    TuitionReceivableAction.pay => 'Thanh toán',
    TuitionReceivableAction.continuePayment => 'Tiếp tục thanh toán',
    TuitionReceivableAction.viewStatus => 'Xem trạng thái',
    TuitionReceivableAction.createNewQr => 'Tạo mã mới',
    TuitionReceivableAction.payAgain => 'Thanh toán lại',
    TuitionReceivableAction.viewDetails => 'Xem chi tiết',
    TuitionReceivableAction.none => '',
  };
}

class TuitionReceivableState {
  TuitionReceivableState._(this.source, {
    required this.id,
    required this.outstandingAmount,
    required this.displayAmount,
    required this.payable,
    required this.paymentStatus,
    required this.blockingReason,
    required this.activePaymentRequest,
    required this.lastPaymentRequest,
    required this.recentRequestStatus,
  });

  final Map<String, dynamic> source;
  final String id;
  final int outstandingAmount;
  final int displayAmount;
  final bool payable;
  final String paymentStatus;
  final String? blockingReason;
  final Map<String, dynamic>? activePaymentRequest;
  final Map<String, dynamic>? lastPaymentRequest;
  final String? recentRequestStatus;

  static int? _money(dynamic value) {
    if (value is num) return value.round();
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    final simple = num.tryParse(text);
    if (simple != null) return simple.round();
    // Accept commonly observed localized amount strings without treating
    // a locked/blocked receivable as an invalid, invisible row.
    final cleaned = text.replaceAll(RegExp(r'\s|₫|đ|VND', caseSensitive: false), '');
    if (RegExp(r'^\d{1,3}([.,]\d{3})+$').hasMatch(cleaned)) {
      return int.tryParse(cleaned.replaceAll(RegExp(r'[.,]'), ''));
    }
    if (RegExp(r'^\d+[,\.]\d{1,2}$').hasMatch(cleaned)) {
      return num.tryParse(cleaned.replaceAll(',', '.'))?.round();
    }
    return null;
  }

  static Map<String, dynamic>? _object(dynamic data) =>
    data is Map ? Map<String, dynamic>.from(data) : null;

  static String? _string(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  factory TuitionReceivableState.fromJson(Map<String, dynamic> input) {
    final raw = Map<String, dynamic>.from(input);
    final outstanding = _money(raw['outstandingAmount']);
    if (outstanding == null || outstanding < 0) {
      throw const FormatException('Invalid outstandingAmount from gateway');
    }
    // A new installation starts with no known paymentRequestId. A valid
    // student-scoped response may expose an active ID at the root even if an
    // intermediary has not expanded `activePaymentRequest` yet. Recover the
    // ID for a safe GET status; do NOT assume the QR or status values.
    final rootActiveId = _string(raw['activePaymentRequestId']);
    var active = _object(raw['activePaymentRequest']) ??
        (raw['hasActiveLock'] == true && rootActiveId != null
            ? <String, dynamic>{
                'paymentRequestId': rootActiveId,
                if (_string(raw['activePaymentRequestStatus']) != null)
                  'status': raw['activePaymentRequestStatus'],
              }
            : null);
    var last = _object(raw['lastPaymentRequest']) ??
        _object(raw['latestPaymentRequest']);
    final providedActiveStatus =
        _string(active?['status'])?.toUpperCase();
    if (const <String>{'EXPIRED', 'CANCELLED', 'PAID'}
        .contains(providedActiveStatus)) {
      // Normalize a terminal provider snapshot wrongly exposed under
      // activePaymentRequest into immutable history; do not keep an EXPIRED
      // request as an active lock or lose its ID when upstream drops it.
      last = active; // The freshly reported terminal request wins.
      raw['lastPaymentRequest'] = last;
      raw['lastPaymentRequestStatus'] = providedActiveStatus;
      raw['activePaymentRequest'] = null;
      active = null;
    } else if (raw['activePaymentRequest'] == null && active != null) {
      raw['activePaymentRequest'] = active;
    }
    final total = _money(raw['totalAmount'] ?? raw['receivableAmount'] ?? raw['amount']);
    final status = _string(raw['paymentStatus'])?.toUpperCase() ?? 'UNKNOWN';
    // Missing `payable` must not be assumed true (no speculative POST).
    return TuitionReceivableState._(raw,
      id: _string(raw['receivableId']) ?? '',
      outstandingAmount: outstanding,
      displayAmount: outstanding == 0 ? (total ?? 0) : outstanding,
      payable: raw['payable'] == true,
      paymentStatus: status,
      blockingReason: _string(raw['blockingReason']) ??
        _string(raw['payabilityReasonCode']) ??
        _string(raw['payabilityReason']),
      activePaymentRequest: active,
      lastPaymentRequest: last,
      recentRequestStatus: _string(last?['status'] ?? raw['lastPaymentRequestStatus'])?.toUpperCase(),
    );
  }

  String? get activeRequestId => _string(activePaymentRequest?['paymentRequestId'] ??
        activePaymentRequest?['activePaymentRequestId'] ?? activePaymentRequest?['id']);
  String? get activeStatus =>
      _string(activePaymentRequest?['status'])?.toUpperCase();
  DateTime? get activeExpiresAt => DateTime.tryParse(
    _string(activePaymentRequest?['expiresAt']) ?? '');

  /// Latest known terminal request. It is NOT an active lock; keep its ID/QR
  /// so a student can open the expired ticket and explicitly tap Recreate.
  String? get lastRequestId => _string(lastPaymentRequest?['paymentRequestId'] ??
    lastPaymentRequest?['id'] ?? source['lastPaymentRequestId'] ??
    source['latestPaymentRequestId']) ??
    (const <String>{'EXPIRED', 'CANCELLED', 'PAID'}.contains(activeStatus)
        ? activeRequestId : null);

  bool get hasActiveLock => source['hasActiveLock'] == true ||
      const <String>{'PENDING', 'PROCESSING'}.contains(activeStatus);

  bool get hasExpiredHistory =>
      const <String>{'EXPIRED', 'CANCELLED'}.contains(recentRequestStatus) ||
      const <String>{'EXPIRED', 'CANCELLED'}.contains(activeStatus);

  /// The bill can be payable again while the PREVIOUS QR stays EXPIRED.
  /// Only the server may confirm that its lock was actually released.
  bool get releasedAfterExpiry => hasDebt && hasExpiredHistory &&
      payable && !hasActiveLock;

  // An unpaid balance must never disappear just because an upstream status
  // says PAID before accounting has reconciled that receivable.
  bool get isSettled => outstandingAmount == 0;
  bool get hasDebt => outstandingAmount > 0;

  TuitionReceivablePhase get phase {
    if (isSettled) return TuitionReceivablePhase.paid;
    if (const <String>{'PAID', 'OVERPAID'}.contains(paymentStatus)) {
      return TuitionReceivablePhase.processing; // awaiting accounting balance
    }
    final status = activeStatus;
    // The active payment request wins over payable=false and paymentStatus.
    switch (status) {
      case 'PROCESSING': return TuitionReceivablePhase.processing;
      case 'PENDING': return TuitionReceivablePhase.waitingPayment;
      case 'EXPIRED': return releasedAfterExpiry
          ? TuitionReceivablePhase.unpaid : TuitionReceivablePhase.qrExpired;
      case 'CANCELLED': return releasedAfterExpiry
          ? TuitionReceivablePhase.unpaid : TuitionReceivablePhase.cancelled;
      case 'PAID':
        // Bank reports paid, but the receivable has not yet been reconciled.
        return TuitionReceivablePhase.processing;
    }
    // Historical status is informational only; it never grants POST permission.
    switch (recentRequestStatus) {
      case 'EXPIRED': return releasedAfterExpiry
          ? TuitionReceivablePhase.unpaid : TuitionReceivablePhase.qrExpired;
      case 'CANCELLED': return releasedAfterExpiry
          ? TuitionReceivablePhase.unpaid : TuitionReceivablePhase.cancelled;
      case 'PAID': return TuitionReceivablePhase.processing;
        // Payment request settled, receivable ledger still updating.
    }
    return payable ? TuitionReceivablePhase.unpaid
        : TuitionReceivablePhase.blocked;
  }

  TuitionReceivableAction get action {
    switch (phase) {
      case TuitionReceivablePhase.paid:
        return TuitionReceivableAction.viewDetails;
      case TuitionReceivablePhase.waitingPayment:
        return TuitionReceivableAction.continuePayment;
      case TuitionReceivablePhase.processing:
        return TuitionReceivableAction.viewStatus;
      case TuitionReceivablePhase.qrExpired:
        return lastRequestId != null || payable
          ? TuitionReceivableAction.createNewQr : TuitionReceivableAction.none;
      case TuitionReceivablePhase.cancelled:
        return lastRequestId != null || payable
          ? TuitionReceivableAction.payAgain : TuitionReceivableAction.none;
      case TuitionReceivablePhase.unpaid:
        return !payable ? TuitionReceivableAction.none
          : hasExpiredHistory ? TuitionReceivableAction.createNewQr
          : TuitionReceivableAction.pay;
      case TuitionReceivablePhase.blocked:
        return TuitionReceivableAction.none;
    }
  }

  bool get canCreate => hasDebt && payable && !hasActiveLock &&
    source['payability']?.toString().toUpperCase() != 'BLOCKED' &&
    activeRequestId == null && lastRequestId == null &&
    const <TuitionReceivablePhase>{
      TuitionReceivablePhase.unpaid,
      TuitionReceivablePhase.qrExpired,
      TuitionReceivablePhase.cancelled,
    }.contains(phase);

  bool get canResume => activeRequestId != null &&
      const <TuitionReceivablePhase>{
        TuitionReceivablePhase.waitingPayment, TuitionReceivablePhase.processing,
      }.contains(phase);

  bool get inUnpaidTab => outstandingAmount > 0;
  bool get inPaidTab => outstandingAmount == 0;

  TuitionReceivableState withGatewayRequest({required String requestId,
      required String status, DateTime? expiresAt, String? qrPayload,
      String? qrImageBase64}) {
    final normalized = status.trim().toUpperCase();
    final candidate = activePaymentRequest?['paymentRequestId'] == requestId
        ? activePaymentRequest
        : lastPaymentRequest?['paymentRequestId'] == requestId
          ? lastPaymentRequest : null;
    final historic = candidate;
    final request = <String, dynamic>{
      // A detail GET may omit QR; preserve the provider-issued last snapshot.
      if (historic != null) ...historic,
      'paymentRequestId': requestId,
      'status': normalized,
      if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
      if (qrPayload != null || qrImageBase64 != null)
        'qr': <String, dynamic>{
          if (historic?['qr'] is Map)
            ...Map<String, dynamic>.from(historic!['qr'] as Map),
          if (qrPayload != null) 'payload': qrPayload,
          if (qrImageBase64 != null) 'imageBase64': qrImageBase64,
        },
    };
    final terminal = const <String>{'EXPIRED','CANCELLED','PAID'}
        .contains(normalized);
    return TuitionReceivableState.fromJson(<String, dynamic>{
      ...source,
      if (terminal) ...{
        'activePaymentRequest': null,
        'lastPaymentRequest': request,
        'lastPaymentRequestStatus': normalized,
        // Do NOT flip payable to true merely because GET status expired.
        // The subsequent payable GET must confirm lock release.
      } else ...{
        'activePaymentRequest': request,
        'payable': false,
      },
    });
  }

  static int totalDebt(Iterable<TuitionReceivableState> states) => states
    .fold<int>(0, (sum, item) => sum + (item.hasDebt ? item.outstandingAmount : 0));
}
