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

  factory DormitoryInvoiceResponse.fromJson(
    Map<String, dynamic> json,
  ) {
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
            (Map<dynamic, dynamic> item) =>
                DormitoryInvoiceModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

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

  /// Khoảng thời gian mà biên lai áp dụng.
  /// Hỗ trợ cả snake_case/camelCase và nhiều tên field backend thường dùng.
  final DateTime? periodStartDate;
  final DateTime? periodEndDate;

  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String? status;
  final String? statusLabel;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final DateTime? createdAt;
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
    this.periodStartDate,
    this.periodEndDate,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.status,
    this.statusLabel,
    this.dueDate,
    this.paidAt,
    this.createdAt,
    this.paymentCode,
    this.bankTransferQrUrl,
    this.payments = const <DormitoryPaymentModel>[],
  });

  factory DormitoryInvoiceModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawPayments = json['payments'];
    final String? status = json['status']?.toString();
    final double totalAmount = _toDouble(
      json['total_amount'] ?? json['totalAmount'] ?? json['amount'],
    );

    final bool paidByStatus = _isPaidStatus(status);

    final dynamic rawPaidAmount =
        json['paid_amount'] ?? json['paidAmount'];
    final double paidAmount = rawPaidAmount != null
        ? _toDouble(rawPaidAmount)
        : paidByStatus
            ? totalAmount
            : 0;

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
      code: json['code']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      kind: json['kind']?.toString(),
      kindLabel:
          json['kind_label']?.toString() ??
          json['kindLabel']?.toString(),
      direction: json['direction']?.toString(),
      billingPeriodName:
          json['billing_period_name']?.toString() ??
          json['billingPeriodName']?.toString(),
      periodStartDate: _readPeriodDate(
        json,
        const <String>[
          'billing_period_start_date',
          'billingPeriodStartDate',
          'billing_start_date',
          'billingStartDate',
          'period_start_date',
          'periodStartDate',
          'start_date',
          'startDate',
          'from_date',
          'fromDate',
        ],
      ),
      periodEndDate: _readPeriodDate(
        json,
        const <String>[
          'billing_period_end_date',
          'billingPeriodEndDate',
          'billing_end_date',
          'billingEndDate',
          'period_end_date',
          'periodEndDate',
          'end_date',
          'endDate',
          'to_date',
          'toDate',
        ],
      ),
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      status: status,
      statusLabel:
          json['status_label']?.toString() ??
          json['statusLabel']?.toString(),
      dueDate: _toDateTime(json['due_date'] ?? json['dueDate']),
      paidAt: _toDateTime(json['paid_at'] ?? json['paidAt']),
      createdAt: _toDateTime(json['created_at'] ?? json['createdAt']),
      paymentCode:
          json['payment_code']?.toString() ??
          json['paymentCode']?.toString(),
      bankTransferQrUrl:
          json['bank_transfer_qr_url']?.toString() ??
          json['bankTransferQrUrl']?.toString() ??
          json['qr_url']?.toString(),
      payments: rawPayments is List
          ? rawPayments
              .whereType<Map>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    DormitoryPaymentModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const <DormitoryPaymentModel>[],
    );
  }

  bool get isPaid => _isPaidStatus(status);

  DormitoryPaymentModel? get latestPayment {
    if (payments.isEmpty) {
      return null;
    }

    final List<DormitoryPaymentModel> sorted =
        List<DormitoryPaymentModel>.from(payments);

    sorted.sort(
      (DormitoryPaymentModel first, DormitoryPaymentModel second) {
        final DateTime firstDate = first.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime secondDate = second.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final int dateCompare = secondDate.compareTo(firstDate);
        if (dateCompare != 0) {
          return dateCompare;
        }

        final int firstId = int.tryParse(first.id?.toString() ?? '') ?? 0;
        final int secondId = int.tryParse(second.id?.toString() ?? '') ?? 0;

        return secondId.compareTo(firstId);
      },
    );

    return sorted.first;
  }

  bool get hasPendingPayment {
    final String normalized =
        latestPayment?.status?.trim().toLowerCase() ?? '';

    return normalized == 'pending' ||
        normalized == 'waiting' ||
        normalized == 'submitted';
  }

  bool get hasRejectedPayment {
    return latestPayment?.status?.trim().toLowerCase() == 'rejected';
  }

  bool get canUploadProof => !isPaid && !hasPendingPayment;

  String get displayTitle {
    final List<String?> values = <String?>[
      kindLabel,
      title,
      billingPeriodName,
      code,
    ];

    for (final String? value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }

    return 'Biên lai ký túc xá';
  }

  /// Ngày bắt đầu kỳ thu. Nếu API chưa trả field riêng thì thử đọc
  /// hai ngày nằm trong billingPeriodName, ví dụ:
  /// "10/08/2026 - 10/09/2026".
  DateTime? get resolvedPeriodStartDate {
    if (periodStartDate != null) {
      return periodStartDate;
    }

    final List<DateTime> dates = _extractDatesFromText(billingPeriodName);
    return dates.isNotEmpty ? dates.first : null;
  }

  /// Ngày kết thúc kỳ thu. Nếu API chưa trả field riêng thì thử đọc
  /// ngày thứ hai trong billingPeriodName.
  DateTime? get resolvedPeriodEndDate {
    if (periodEndDate != null) {
      return periodEndDate;
    }

    final List<DateTime> dates = _extractDatesFromText(billingPeriodName);
    return dates.length >= 2 ? dates[1] : null;
  }

  static DateTime? _readPeriodDate(
    Map<String, dynamic> json,
    List<String> aliases,
  ) {
    for (final String key in aliases) {
      final DateTime? value = _toDateTime(json[key]);
      if (value != null) {
        return value;
      }
    }

    final dynamic nested =
        json['billing_period'] ?? json['billingPeriod'] ?? json['period'];

    if (nested is Map) {
      final Map<String, dynamic> nestedMap =
          Map<String, dynamic>.from(nested);

      for (final String key in aliases) {
        final DateTime? value = _toDateTime(nestedMap[key]);
        if (value != null) {
          return value;
        }
      }
    }

    return null;
  }

  static List<DateTime> _extractDatesFromText(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return <DateTime>[];
    }

    final List<DateTime> result = <DateTime>[];

    final RegExp vietnameseDate = RegExp(
      r'\b(\d{1,2})[\/-](\d{1,2})[\/-](\d{2}|\d{4})\b',
    );

    for (final RegExpMatch match in vietnameseDate.allMatches(text)) {
      final int? day = int.tryParse(match.group(1) ?? '');
      final int? month = int.tryParse(match.group(2) ?? '');
      int? year = int.tryParse(match.group(3) ?? '');

      if (day == null || month == null || year == null) {
        continue;
      }

      if (year < 100) {
        year += 2000;
      }

      final DateTime? parsed = _safeDate(year, month, day);
      if (parsed != null) {
        result.add(parsed);
      }
    }

    final RegExp isoDate = RegExp(
      r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b',
    );

    for (final RegExpMatch match in isoDate.allMatches(text)) {
      final int? year = int.tryParse(match.group(1) ?? '');
      final int? month = int.tryParse(match.group(2) ?? '');
      final int? day = int.tryParse(match.group(3) ?? '');

      if (day == null || month == null || year == null) {
        continue;
      }

      final DateTime? parsed = _safeDate(year, month, day);
      if (parsed != null &&
          !result.any((DateTime item) =>
              item.year == parsed.year &&
              item.month == parsed.month &&
              item.day == parsed.day)) {
        result.add(parsed);
      }
    }

    return result;
  }

  static DateTime? _safeDate(int year, int month, int day) {
    try {
      final DateTime value = DateTime(year, month, day);
      if (value.year == year && value.month == month && value.day == day) {
        return value;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static bool _isPaidStatus(String? value) {
    final String normalized = value?.trim().toLowerCase() ?? '';

    return normalized == 'paid' ||
        normalized == 'completed' ||
        normalized == 'success';
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0;
    }

    return 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

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
    this.note,
    this.rejectionReason,
    this.createdAt,
    this.confirmedAt,
  });

  factory DormitoryPaymentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DormitoryPaymentModel(
      id: json['id'],
      method: json['method']?.toString(),
      methodLabel:
          json['method_label']?.toString() ??
          json['methodLabel']?.toString(),
      status: json['status']?.toString(),
      statusLabel:
          json['status_label']?.toString() ??
          json['statusLabel']?.toString(),
      amount: _toDouble(json['amount']),
      proofImageUrl:
          json['proof_image_url']?.toString() ??
          json['proofImageUrl']?.toString(),
      note: json['note']?.toString(),
      rejectionReason:
          json['rejection_reason']?.toString() ??
          json['rejectionReason']?.toString(),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      confirmedAt: _parseDate(
        json['confirmed_at'] ?? json['confirmedAt'],
      ),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString().replaceAll(',', '') ?? '',
        ) ??
        0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }
}
