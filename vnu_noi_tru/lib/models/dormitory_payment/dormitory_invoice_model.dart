class DormitoryInvoiceResponse {
  final bool success;
  final int? code;
  final String? message;

  /// Giữ tên invoices để tương thích với giao diện cũ.
  /// Nguồn dữ liệu thực tế là data.receipts của API mới.
  final List<DormitoryInvoiceModel> invoices;

  const DormitoryInvoiceResponse({
    required this.success,
    this.code,
    this.message,
    this.invoices = const <DormitoryInvoiceModel>[],
  });

  factory DormitoryInvoiceResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];
    List<dynamic> rawReceipts = <dynamic>[];

    if (rawData is List) {
      rawReceipts = rawData;
    } else if (rawData is Map) {
      final dynamic nestedReceipts =
          rawData['receipts'] ??
          rawData['invoices'] ??
          rawData['items'] ??
          rawData['data'];

      if (nestedReceipts is List) {
        rawReceipts = nestedReceipts;
      }
    }

    return DormitoryInvoiceResponse(
      success: json['success'] == true,
      code: _toInt(json['code']),
      message: json['message']?.toString(),
      invoices: rawReceipts
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) => DormitoryInvoiceModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class DormitoryInvoiceModel {
  final Object? id;
  final String? code;
  final String? title;
  final String? description;
  final String? kind;
  final String? kindLabel;
  final String? direction;
  final String? billingPeriodName;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String? status;
  final String? statusLabel;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final DateTime? createdAt;

  final Object? accommodationId;
  final int? dormitoryId;
  final int? roomTypeId;
  final String? roomTypeName;
  final double? roomTypePrice;
  final String? roomNumber;
  final String? buildingName;
  final String? studentName;
  final String? studentIdentityNo;

  /// API mới dùng một biên lai cho cả phần điều chỉnh khi đổi phòng/loại phòng.
  final int adjustedCount;
  final bool hasRoomChange;

  final DateTime? periodStartDate;
  final DateTime? periodEndDate;
  final String? paymentCode;
  final String? bankTransferQrUrl;
  final List<DormitoryPaymentModel> payments;

  const DormitoryInvoiceModel({
    this.id,
    this.code,
    this.title,
    this.description,
    this.kind,
    this.kindLabel,
    this.direction,
    this.billingPeriodName,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.status,
    this.statusLabel,
    this.dueDate,
    this.paidAt,
    this.createdAt,
    this.accommodationId,
    this.dormitoryId,
    this.roomTypeId,
    this.roomTypeName,
    this.roomTypePrice,
    this.roomNumber,
    this.buildingName,
    this.studentName,
    this.studentIdentityNo,
    this.adjustedCount = 0,
    this.hasRoomChange = false,
    this.periodStartDate,
    this.periodEndDate,
    this.paymentCode,
    this.bankTransferQrUrl,
    this.payments = const <DormitoryPaymentModel>[],
  });

  factory DormitoryInvoiceModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawPayments = json['payments'];
    final List<DormitoryPaymentModel> payments = rawPayments is List
        ? rawPayments
            .whereType<Map>()
            .map(
              (Map<dynamic, dynamic> item) => DormitoryPaymentModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : const <DormitoryPaymentModel>[];

    final String? status = json['status']?.toString();
    final double totalAmount = _toDouble(
      json['total_amount'] ?? json['totalAmount'] ?? json['amount'],
    );
    final bool paidByStatus = _isPaidStatus(status);

    final dynamic rawPaidAmount = json['paid_amount'] ?? json['paidAmount'];
    final double confirmedPaymentAmount = payments
        .where((DormitoryPaymentModel item) => item.isConfirmed)
        .fold<double>(0, (double sum, DormitoryPaymentModel item) {
          return sum + item.amount;
        });

    final double paidAmount = rawPaidAmount != null
        ? _toDouble(rawPaidAmount)
        : paidByStatus
            ? totalAmount
            : confirmedPaymentAmount;

    final dynamic rawRemainingAmount =
        json['remaining_amount'] ?? json['remainingAmount'];
    final double calculatedRemaining = totalAmount - paidAmount;
    final double remainingAmount = rawRemainingAmount != null
        ? _toDouble(rawRemainingAmount)
        : paidByStatus
            ? 0
            : calculatedRemaining > 0
                ? calculatedRemaining
                : 0;

    return DormitoryInvoiceModel(
      id: json['id'],
      code:
          json['receipt_code']?.toString() ??
          json['receiptCode']?.toString() ??
          json['code']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      kind: json['kind']?.toString(),
      kindLabel:
          json['kind_label']?.toString() ?? json['kindLabel']?.toString(),
      direction: json['direction']?.toString(),
      billingPeriodName:
          json['billing_period_name']?.toString() ??
          json['billingPeriodName']?.toString(),
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      status: status,
      statusLabel:
          json['status_label']?.toString() ?? json['statusLabel']?.toString(),
      dueDate: _toDateTime(json['due_date'] ?? json['dueDate']),
      paidAt: _toDateTime(json['paid_at'] ?? json['paidAt']),
      createdAt: _toDateTime(json['created_at'] ?? json['createdAt']),
      accommodationId: json['accommodation_id'] ?? json['accommodationId'],
      dormitoryId: _toInt(json['dormitory_id'] ?? json['dormitoryId']),
      roomTypeId: _toInt(json['room_type_id'] ?? json['roomTypeId']),
      roomTypeName:
          json['room_type_name']?.toString() ?? json['roomTypeName']?.toString(),
      roomTypePrice: _toNullableDouble(
        json['room_type_price'] ?? json['roomTypePrice'],
      ),
      roomNumber:
          json['room_number']?.toString() ?? json['roomNumber']?.toString(),
      buildingName:
          json['building_name']?.toString() ?? json['buildingName']?.toString(),
      studentName:
          json['student_name']?.toString() ?? json['studentName']?.toString(),
      studentIdentityNo:
          json['student_identity_no']?.toString() ??
          json['studentIdentityNo']?.toString(),
      adjustedCount: _toInt(json['adjusted_count'] ?? json['adjustedCount']) ?? 0,
      hasRoomChange: _toBool(
            json['has_room_change'] ?? json['hasRoomChange'],
          ) ||
          (_toInt(json['adjusted_count'] ?? json['adjustedCount']) ?? 0) > 0 ||
          _looksLikeRoomChange(json),
      periodStartDate: _toDateTime(
        json['period_start_date'] ??
            json['periodStartDate'] ??
            json['start_date'] ??
            json['startDate'] ??
            json['from_date'] ??
            json['fromDate'],
      ),
      periodEndDate: _toDateTime(
        json['period_end_date'] ??
            json['periodEndDate'] ??
            json['end_date'] ??
            json['endDate'] ??
            json['to_date'] ??
            json['toDate'],
      ),
      paymentCode:
          json['payment_code']?.toString() ?? json['paymentCode']?.toString(),
      bankTransferQrUrl:
          json['bank_transfer_qr_url']?.toString() ??
          json['bankTransferQrUrl']?.toString() ??
          json['qr_url']?.toString(),
      payments: payments,
    );
  }

  bool get isPaid => _isPaidStatus(status);

  DateTime? get resolvedPeriodStartDate =>
      periodStartDate ?? _extractPeriodDates(billingPeriodName).$1;

  DateTime? get resolvedPeriodEndDate =>
      periodEndDate ?? _extractPeriodDates(billingPeriodName).$2;

  DormitoryPaymentModel? get latestPayment {
    if (payments.isEmpty) return null;

    final List<DormitoryPaymentModel> sorted =
        List<DormitoryPaymentModel>.from(payments);

    sorted.sort((DormitoryPaymentModel first, DormitoryPaymentModel second) {
      final DateTime firstDate =
          first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime secondDate =
          second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final int dateCompare = secondDate.compareTo(firstDate);
      if (dateCompare != 0) return dateCompare;

      final int firstId = int.tryParse(first.id?.toString() ?? '') ?? 0;
      final int secondId = int.tryParse(second.id?.toString() ?? '') ?? 0;
      return secondId.compareTo(firstId);
    });

    return sorted.first;
  }

  bool get hasPendingPayment => payments.any(
        (DormitoryPaymentModel item) => item.isPending,
      );

  bool get hasRejectedPayment => payments.any(
        (DormitoryPaymentModel item) => item.isRejected,
      );

  /// API mới cho phép bổ sung thêm proof vào cùng Payment đang pending.
  /// Vì vậy không khóa upload chỉ vì đã có một lần gửi trước đó.
  bool get canUploadProof => !isPaid;

  int get proofCount => latestPayment?.allProofImages.length ?? 0;

  String get displayTitle {
    if (hasRoomChange || adjustedCount > 0) {
      return 'Hóa đơn điều chỉnh nội trú';
    }

    final List<String?> values = <String?>[
      kindLabel,
      title,
      billingPeriodName,
      code,
    ];

    for (final String? value in values) {
      if (value != null && value.trim().isNotEmpty) return value;
    }

    return 'Hóa đơn ký túc xá';
  }

  static (DateTime?, DateTime?) _extractPeriodDates(String? value) {
    final String source = value?.trim() ?? '';
    if (source.isEmpty) return (null, null);

    final List<DateTime> dates = <DateTime>[];
    final RegExp vietnameseDate = RegExp(
      r'\b(\d{1,2})[\/-](\d{1,2})[\/-](\d{2}|\d{4})\b',
    );

    for (final RegExpMatch match in vietnameseDate.allMatches(source)) {
      final int? day = int.tryParse(match.group(1) ?? '');
      final int? month = int.tryParse(match.group(2) ?? '');
      int? year = int.tryParse(match.group(3) ?? '');
      if (day == null || month == null || year == null) continue;
      if (year < 100) year += 2000;
      final DateTime? parsed = _safeDate(year, month, day);
      if (parsed != null) dates.add(parsed);
    }

    if (dates.length < 2) {
      final RegExp isoDate = RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b');
      for (final RegExpMatch match in isoDate.allMatches(source)) {
        final int? year = int.tryParse(match.group(1) ?? '');
        final int? month = int.tryParse(match.group(2) ?? '');
        final int? day = int.tryParse(match.group(3) ?? '');
        if (year == null || month == null || day == null) continue;
        final DateTime? parsed = _safeDate(year, month, day);
        if (parsed != null && !dates.contains(parsed)) dates.add(parsed);
      }
    }

    return (
      dates.isNotEmpty ? dates.first : null,
      dates.length > 1 ? dates[1] : null,
    );
  }

  static DateTime? _safeDate(int year, int month, int day) {
    if (year < 1900 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    final DateTime value = DateTime(year, month, day);
    if (value.year != year || value.month != month || value.day != day) {
      return null;
    }
    return value;
  }

  static bool _isPaidStatus(String? value) {
    final String normalized = value?.trim().toLowerCase() ?? '';
    return normalized == 'paid' ||
        normalized == 'completed' ||
        normalized == 'success';
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final String normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }

  static bool _looksLikeRoomChange(Map<String, dynamic> json) {
    final String source = <dynamic>[
      json['kind'],
      json['kind_label'],
      json['kindLabel'],
      json['title'],
      json['description'],
    ].where((dynamic value) => value != null).join(' ').toLowerCase();

    return source.contains('room_change') ||
        source.contains('change_room') ||
        source.contains('đổi phòng') ||
        source.contains('chuyển phòng') ||
        source.contains('điều chỉnh phòng') ||
        source.contains('điều chỉnh nội trú');
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0;
    }
    return 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', ''));
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class DormitoryPaymentModel {
  final Object? id;
  final String? method;
  final String? methodLabel;
  final String? status;
  final String? statusLabel;
  final double amount;
  final String? proofImageUrl;
  final List<DormitoryPaymentProofModel> proofImages;
  final String? note;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? confirmedAt;

  const DormitoryPaymentModel({
    this.id,
    this.method,
    this.methodLabel,
    this.status,
    this.statusLabel,
    this.amount = 0,
    this.proofImageUrl,
    this.proofImages = const <DormitoryPaymentProofModel>[],
    this.note,
    this.rejectionReason,
    this.createdAt,
    this.confirmedAt,
  });

  factory DormitoryPaymentModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawProofImages = json['proof_images'] ?? json['proofImages'];

    return DormitoryPaymentModel(
      id: json['id'],
      method: json['method']?.toString(),
      methodLabel:
          json['method_label']?.toString() ?? json['methodLabel']?.toString(),
      status: json['status']?.toString(),
      statusLabel:
          json['status_label']?.toString() ?? json['statusLabel']?.toString(),
      amount: _toDouble(json['amount']),
      proofImageUrl:
          json['proof_image_url']?.toString() ?? json['proofImageUrl']?.toString(),
      proofImages: rawProofImages is List
          ? rawProofImages
              .whereType<Map>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    DormitoryPaymentProofModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const <DormitoryPaymentProofModel>[],
      note: json['note']?.toString(),
      rejectionReason:
          json['rejection_reason']?.toString() ??
          json['rejectionReason']?.toString(),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      confirmedAt: _parseDate(json['confirmed_at'] ?? json['confirmedAt']),
    );
  }

  bool get isPending {
    final String normalized = status?.trim().toLowerCase() ?? '';
    return normalized == 'pending' ||
        normalized == 'waiting' ||
        normalized == 'submitted';
  }

  bool get isRejected => status?.trim().toLowerCase() == 'rejected';

  bool get isConfirmed {
    final String normalized = status?.trim().toLowerCase() ?? '';
    return normalized == 'approved' ||
        normalized == 'confirmed' ||
        normalized == 'paid' ||
        normalized == 'completed' ||
        normalized == 'success';
  }

  /// proofImageUrl là field legacy. proofImages là collection mới.
  /// Getter này gộp hai nguồn nhưng không lặp URL.
  List<DormitoryPaymentProofModel> get allProofImages {
    final List<DormitoryPaymentProofModel> values =
        List<DormitoryPaymentProofModel>.from(proofImages);
    final String legacyUrl = proofImageUrl?.trim() ?? '';
    if (legacyUrl.isNotEmpty &&
        !values.any((DormitoryPaymentProofModel item) => item.url == legacyUrl)) {
      values.insert(
        0,
        DormitoryPaymentProofModel(id: null, url: legacyUrl, note: note),
      );
    }
    return values;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class DormitoryPaymentProofModel {
  final Object? id;
  final String url;
  final String? note;

  const DormitoryPaymentProofModel({
    required this.id,
    required this.url,
    this.note,
  });

  factory DormitoryPaymentProofModel.fromJson(Map<String, dynamic> json) {
    return DormitoryPaymentProofModel(
      id: json['id'],
      url: (json['url'] ?? json['path'] ?? json['proofImageUrl'])?.toString() ?? '',
      note: json['note']?.toString(),
    );
  }

  bool get canDelete => id != null && id.toString().trim().isNotEmpty;
}
