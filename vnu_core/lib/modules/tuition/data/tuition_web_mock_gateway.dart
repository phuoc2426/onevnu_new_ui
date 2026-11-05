import 'package:vnu_core/modules/tuition/data/tuition_charge_category.dart';
import 'package:vnu_core/modules/tuition/data/tuition_demo_repository.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';

/// In-memory payment simulation for the ORIGINAL VcoreTuitionView.
/// Constructed only by Flutter Debug mock mode. It has NO HTTP client,
/// token, student identity, backend URL, bank key, or payment capability.
/// Its QR payload is explicitly marked NON-PAYMENT so it cannot be mistaken
/// for a Vietnamese bank-transfer QR.
class TuitionWebMockGateway {
  TuitionWebMockGateway() { reset(); }

  final List<TuitionDemoBill> _bills = <TuitionDemoBill>[];
  final Map<String, TuitionPaymentRequest> _requests =
      <String, TuitionPaymentRequest>{};
  int _sequence = 0;

  List<TuitionDemoBill> get bills => List<TuitionDemoBill>.unmodifiable(_bills);
  bool failNextCreate = false;
  Duration responseDelay = const Duration(milliseconds: 1400);

  void reset() {
    _requests.clear();
    _bills.clear();
    _sequence = 0;
    failNextCreate = false;
    responseDelay = const Duration(milliseconds: 1400);
    _bills.addAll(<TuitionDemoBill>[
      TuitionDemoBill(
        code: 'MOCK-ULIS-RETAKE-01',
        title: 'Học phí học lại/cải thiện',
        amount: 7150000,
        dueDate: DateTime(2026, 11, 15),
        status: TuitionPaymentStatus.expired,
        periodName: 'Học phí · Học kỳ 1 · 2026–2027 · Đợt 2',
        termId: '11111111-1111-4111-8111-111111111111',
        collectionPeriodCode: 'ULIS-HK1-D2',
        chargeCategory: TuitionChargeCategory.retake,
      ),
      TuitionDemoBill(
        code: 'MOCK-ULIS-FIRST-02',
        title: 'Học phí',
        amount: 11550000,
        dueDate: DateTime(2027, 1, 15),
        status: TuitionPaymentStatus.pending,
        periodName: 'Học phí · Học kỳ 1 · 2026–2027 · Đợt 1',
        termId: '11111111-1111-4111-8111-111111111111',
        collectionPeriodCode: 'ULIS-HK1-D1',
        chargeCategory: TuitionChargeCategory.firstTime,
      ),
    ]);
    // First ticket already has an EXPIRED QR, permitting immediate testing
    // of the green on-QR reload button in the actual detail layout.
    _requests[_bills.first.code] = _makeRequest(status: 'EXPIRED');
    _requests[_bills.last.code] = _makeRequest(status: 'PENDING');
  }

  TuitionPaymentRequest? requestFor(String billCode) => _requests[billCode];

  /// Remove a QR only in the mock dataset to test FIRST-TIME CREATE.
  bool clearRequest(String billCode) {
    final bill = _findBill(billCode);
    if (bill == null || bill.status == TuitionPaymentStatus.paid) return false;
    _requests.remove(billCode);
    bill.status = TuitionPaymentStatus.pending;
    return true;
  }

  /// Simulates payment-request expiry without touching data on any server.
  bool expire(String billCode) {
    final bill = _findBill(billCode);
    final previous = _requests[billCode];
    if (bill == null || previous == null ||
        bill.status == TuitionPaymentStatus.paid) return false;
    _requests[billCode] = TuitionPaymentRequest(
      id: previous.id,
      status: 'EXPIRED',
      payload: previous.payload,
      imageBase64: previous.imageBase64,
      expiresAt: DateTime.now().subtract(const Duration(seconds: 3)),
      provider: previous.provider,
      updatedAt: DateTime.now(),
    );
    bill.status = TuitionPaymentStatus.expired;
    return true;
  }

  /// Mark a bill settled for exercising PAID tab and local financial filter.
  /// This does NOT post or alter real accounting data.
  bool markPaid(String billCode) {
    final bill=_findBill(billCode);
    final request=_requests[billCode];
    if (bill==null) return false;
    bill.status=TuitionPaymentStatus.paid;
    if (request!=null) {
      _requests[billCode]=TuitionPaymentRequest(
        id:request.id,status:'PAID',payload:request.payload,
        imageBase64:request.imageBase64,provider:request.provider,
        expiresAt:request.expiresAt,updatedAt:DateTime.now(),
      );
    }
    return true;
  }

  /// Simulates the real CP1 cancel endpoint; only effective PENDING may cancel.
  Future<TuitionPaymentCancellation> cancel(String billCode) async {
    final bill=_findBill(billCode);
    final request=_requests[billCode];
    if (bill==null || request==null) throw StateError('No mock request');
    if (request.status=='CANCELLED') {
      return TuitionPaymentCancellation(request:request,lockReleased:true,
        lockAttention:false,replayed:true);
    }
    if (request.status!='PENDING' ||
        (request.expiresAt!=null &&
         !request.expiresAt!.isAfter(DateTime.now()))) {
      throw StateError('Only effective PENDING request may be cancelled');
    }
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final cancelled=TuitionPaymentRequest(
      id:request.id,status:'CANCELLED',payload:request.payload,
      imageBase64:request.imageBase64,expiresAt:request.expiresAt,
      provider:request.provider,updatedAt:DateTime.now());
    _requests[billCode]=cancelled;
    bill.status=TuitionPaymentStatus.cancelled;
    return TuitionPaymentCancellation(request:cancelled,lockReleased:true,
      lockAttention:false,replayed:false);
  }

  /// The previous QR remains unchanged for any simulated failure.
  /// A PENDING / PROCESSING QR can never produce another request.
  Future<TuitionPaymentRequest> createOrRecreate(String billCode) async {
    final bill = _findBill(billCode);
    if (bill == null) throw StateError('Unknown mock receivable');
    final previous = _requests[billCode];
    if (previous != null && !const <String>{'EXPIRED','CANCELLED'}
        .contains(previous.status.toUpperCase())) {
      throw StateError('Existing mock QR still active');
    }
    await Future<void>.delayed(responseDelay);
    if (failNextCreate) {
      failNextCreate = false;
      throw StateError('SIMULATED_API_FAILURE');
    }
    final created = _makeRequest(status: 'PENDING');
    _requests[billCode] = created;
    bill.status = TuitionPaymentStatus.pending;
    return created;
  }

  TuitionDemoBill? _findBill(String id) {
    for (final bill in _bills) {
      if (bill.code == id) return bill;
    }
    return null;
  }

  TuitionPaymentRequest _makeRequest({required String status}) {
    final number = ++_sequence;
    return TuitionPaymentRequest(
      id: 'MOCK-QR-${number.toString().padLeft(4, '0')}',
      status: status,
      payload: 'ONEVNU-MOCK-NOT-FOR-PAYMENT-$number',
      expiresAt: status == 'EXPIRED'
          ? DateTime.now().subtract(const Duration(minutes: 2))
          : DateTime.now().add(const Duration(minutes: 15)),
      provider: 'MOCK — KHÔNG CHUYỂN KHOẢN',
      updatedAt: DateTime.now(),
    );
  }
}
