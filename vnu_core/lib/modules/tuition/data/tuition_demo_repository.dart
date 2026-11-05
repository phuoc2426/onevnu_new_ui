import 'package:vnu_core/modules/tuition/data/tuition_charge_category.dart';

/// The tuition module is a UI-only simulator in this delivery. No real QR,
/// money transfer, bank callback, or student data is used.
enum TuitionPaymentStatus { pending, processing, paid, expired, cancelled }

extension TuitionPaymentStatusDetails on TuitionPaymentStatus {
  String get code => name.toUpperCase();
  String get label => switch (this) {
    TuitionPaymentStatus.pending => 'Đang chờ thanh toán',
    TuitionPaymentStatus.processing => 'Ngân hàng đang xử lý',
    TuitionPaymentStatus.paid => 'Đã thanh toán',
    TuitionPaymentStatus.expired => 'Đã hết hạn',
    TuitionPaymentStatus.cancelled => 'Đã hủy',
  };
  bool get terminal => this == TuitionPaymentStatus.paid ||
      this == TuitionPaymentStatus.expired || this == TuitionPaymentStatus.cancelled;
}

class TuitionDemoBill {
  TuitionDemoBill({
    required this.code,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.processedAt,
    this.channel = 'Ngân hàng liên kết',
    this.isPayable = true,
    this.periodName,
    this.termId,
    this.collectionPeriodCode,
    this.chargeCategory,
  });

  final String code;
  final String title;
  final int amount;
  DateTime? dueDate;
  TuitionPaymentStatus status;
  DateTime? processedAt;
  String channel;
  final bool isPayable;
  final String? periodName;
  final String? termId;
  final String? collectionPeriodCode;
  /// Explicit gateway category, or null when the category is not confirmed.
  final TuitionChargeCategory? chargeCategory;
}

class TuitionDemoRepository {
  TuitionDemoRepository._();
  static final TuitionDemoRepository instance = TuitionDemoRepository._();
  final List<TuitionDemoBill> bills = <TuitionDemoBill>[
    TuitionDemoBill(code: 'HP-2026-01', title: 'Học phí học kỳ I', amount: 6500000,
      dueDate: DateTime.now().add(const Duration(days: 6)), status: TuitionPaymentStatus.pending),
    TuitionDemoBill(code: 'HP-2026-02', title: 'Học phí học kỳ II', amount: 4200000,
      dueDate: DateTime.now().add(const Duration(days: 3)), status: TuitionPaymentStatus.processing,
      processedAt: DateTime.now().subtract(const Duration(minutes: 2))),
    TuitionDemoBill(code: 'HP-2026-03', title: 'Học phí bổ sung', amount: 1200000,
      dueDate: DateTime.now().subtract(const Duration(days: 15)), status: TuitionPaymentStatus.paid,
      processedAt: DateTime.now().subtract(const Duration(days: 20))),
    TuitionDemoBill(code: 'HP-2026-04', title: 'Phí cấp giấy tờ', amount: 30000,
      dueDate: DateTime.now().subtract(const Duration(days: 2)), status: TuitionPaymentStatus.expired),
    TuitionDemoBill(code: 'HP-2026-05', title: 'Khoản thanh toán đã hủy', amount: 350000,
      dueDate: DateTime.now().subtract(const Duration(days: 1)), status: TuitionPaymentStatus.cancelled),
  ];

  void changeStatus(TuitionDemoBill bill, TuitionPaymentStatus status) {
    bill.status = status;
    bill.processedAt = status == TuitionPaymentStatus.processing || status == TuitionPaymentStatus.paid
        ? DateTime.now() : null;
  }

  void recreate(TuitionDemoBill bill) {
    if (bill.status != TuitionPaymentStatus.expired && bill.status != TuitionPaymentStatus.cancelled) return;
    bill.status = TuitionPaymentStatus.pending;
    bill.processedAt = null;
    bill.dueDate = DateTime.now().add(const Duration(hours: 24));
  }
}

/// Future live integration contract (not implemented in Phase 1).
class TuitionLiveApiPaths {
  static const base = '/ulis-tuition/api/v1';
  static const studentToken = '$base/portal/student-tokens';
  static String payable(String studentId) => '$base/cp1/students/${Uri.encodeComponent(studentId)}/payable';
  static const requests = '$base/cp1/payment-requests';
  static String status(String id) => '$requests/${Uri.encodeComponent(id)}';
  static String recreate(String id) => '${status(id)}/recreate';
  static String cancel(String id) => '${status(id)}/cancel';
  // x-api-key and BIDV integrations remain strictly in the trusted backend.
}


