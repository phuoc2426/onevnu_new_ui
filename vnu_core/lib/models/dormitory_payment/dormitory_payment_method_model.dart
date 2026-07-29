class DormitoryPaymentMethodResponse {
  final bool success;
  final String? message;
  final List<DormitoryPaymentMethodModel> methods;

  const DormitoryPaymentMethodResponse({
    required this.success,
    this.message,
    this.methods = const [],
  });

  factory DormitoryPaymentMethodResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];

    List<dynamic> rawMethods = [];

    if (rawData is List) {
      rawMethods = rawData;
    } else if (rawData is Map) {
      final dynamic nested =
          rawData['payment_methods'] ??
          rawData['paymentMethods'] ??
          rawData['items'];

      if (nested is List) {
        rawMethods = nested;
      } else {
        rawMethods = [rawData];
      }
    }

    return DormitoryPaymentMethodResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      methods: rawMethods
          .whereType<Map>()
          .map(
            (item) => DormitoryPaymentMethodModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class DormitoryPaymentMethodModel {
  final Object? id;

  final String? name;
  final String? method;

  final String? bankName;
  final String? bankCode;

  final String? accountNumber;
  final String? accountName;

  final String? branchName;
  final String? qrImageUrl;

  final bool active;

  const DormitoryPaymentMethodModel({
    this.id,
    this.name,
    this.method,
    this.bankName,
    this.bankCode,
    this.accountNumber,
    this.accountName,
    this.branchName,
    this.qrImageUrl,
    this.active = true,
  });

  factory DormitoryPaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return DormitoryPaymentMethodModel(
      id: json['id'],
      name: json['name']?.toString(),
      method: json['method']?.toString(),
      bankName: json['bank_name']?.toString() ?? json['bankName']?.toString(),
      bankCode: json['bank_code']?.toString() ?? json['bankCode']?.toString(),
      accountNumber:
          json['account_number']?.toString() ??
          json['accountNumber']?.toString(),
      accountName:
          json['account_name']?.toString() ?? json['accountName']?.toString(),
      branchName:
          json['branch_name']?.toString() ?? json['branchName']?.toString(),
      qrImageUrl:
          json['qr_image_url']?.toString() ??
          json['qrImageUrl']?.toString() ??
          json['qr_url']?.toString(),
      active: json['active'] != false,
    );
  }

  bool get hasQr {
    return qrImageUrl != null && qrImageUrl!.trim().isNotEmpty;
  }
}
