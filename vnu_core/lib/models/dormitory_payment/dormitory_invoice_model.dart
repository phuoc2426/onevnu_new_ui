class DormitoryInvoiceResponse {
  final bool success;
  final int? code;
  final String? message;
  final List<DormitoryInvoiceModel> invoices;

  const DormitoryInvoiceResponse({
    required this.success,
    this.code,
    this.message,
    this.invoices = const [],
  });

  factory DormitoryInvoiceResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];

    List<dynamic> rawInvoices = [];

    if (rawData is List) {
      rawInvoices = rawData;
    } else if (rawData is Map) {
      final dynamic nestedInvoices =
          rawData['invoices'] ?? rawData['items'] ?? rawData['data'];

      if (nestedInvoices is List) {
        rawInvoices = nestedInvoices;
      }
    }

    return DormitoryInvoiceResponse(
      success: json['success'] == true,
      code: (json['code'] as num?)?.toInt(),
      message: json['message']?.toString(),
      invoices: rawInvoices
          .whereType<Map>()
          .map(
            (item) =>
                DormitoryInvoiceModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class DormitoryInvoiceModel {
  final Object? id;

  final String? code;
  final String? title;
  final String? description;

  final String? kind;
  final String? kindLabel;

  final String? billingPeriodName;

  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;

  final String? status;
  final String? statusLabel;

  final DateTime? dueDate;

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
    this.billingPeriodName,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.status,
    this.statusLabel,
    this.dueDate,
    this.paymentCode,
    this.bankTransferQrUrl,
    this.payments = const [],
  });

  factory DormitoryInvoiceModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawPayments = json['payments'];

    return DormitoryInvoiceModel(
      id: json['id'],
      code: json['code']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      kind: json['kind']?.toString(),
      kindLabel:
          json['kind_label']?.toString() ?? json['kindLabel']?.toString(),
      billingPeriodName:
          json['billing_period_name']?.toString() ??
          json['billingPeriodName']?.toString(),
      totalAmount: _toDouble(
        json['total_amount'] ?? json['totalAmount'] ?? json['amount'],
      ),
      paidAmount: _toDouble(json['paid_amount'] ?? json['paidAmount']),
      remainingAmount: _toDouble(
        json['remaining_amount'] ?? json['remainingAmount'],
      ),
      status: json['status']?.toString(),
      statusLabel:
          json['status_label']?.toString() ?? json['statusLabel']?.toString(),
      dueDate: _toDateTime(json['due_date'] ?? json['dueDate']),
      paymentCode:
          json['payment_code']?.toString() ?? json['paymentCode']?.toString(),
      bankTransferQrUrl:
          json['bank_transfer_qr_url']?.toString() ??
          json['bankTransferQrUrl']?.toString() ??
          json['qr_url']?.toString(),
      payments: rawPayments is List
          ? rawPayments
                .whereType<Map>()
                .map(
                  (item) => DormitoryPaymentModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  bool get isPaid {
    final normalized = status?.trim().toLowerCase();

    return normalized == 'paid' ||
        normalized == 'completed' ||
        normalized == 'success';
  }

  bool get hasPendingPayment {
    return payments.any((payment) {
      final normalized = payment.status?.trim().toLowerCase();

      return normalized == 'pending' ||
          normalized == 'waiting' ||
          normalized == 'submitted';
    });
  }

  bool get hasRejectedPayment {
    return payments.any((payment) {
      return payment.status?.trim().toLowerCase() == 'rejected';
    });
  }

  bool get canUploadProof {
    return !isPaid && !hasPendingPayment;
  }

  String get displayTitle {
    final values = [kindLabel, title, billingPeriodName, code];

    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }

    return 'Hóa đơn ký túc xá';
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
  final String? status;
  final String? statusLabel;

  final String? proofImageUrl;
  final String? note;
  final String? rejectionReason;

  final DateTime? createdAt;
  final DateTime? confirmedAt;

  const DormitoryPaymentModel({
    this.id,
    this.status,
    this.statusLabel,
    this.proofImageUrl,
    this.note,
    this.rejectionReason,
    this.createdAt,
    this.confirmedAt,
  });

  factory DormitoryPaymentModel.fromJson(Map<String, dynamic> json) {
    return DormitoryPaymentModel(
      id: json['id'],
      status: json['status']?.toString(),
      statusLabel:
          json['status_label']?.toString() ?? json['statusLabel']?.toString(),
      proofImageUrl:
          json['proof_image_url']?.toString() ??
          json['proofImageUrl']?.toString(),
      note: json['note']?.toString(),
      rejectionReason:
          json['rejection_reason']?.toString() ??
          json['rejectionReason']?.toString(),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      confirmedAt: _parseDate(json['confirmed_at'] ?? json['confirmedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
