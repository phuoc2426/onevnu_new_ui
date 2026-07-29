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
  final String? typeLabel;

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
    this.typeLabel,
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
      method:
          json['method']?.toString() ??
          json['type']?.toString(),
      typeLabel:
          json['type_label']?.toString() ??
          json['typeLabel']?.toString(),
      bankName:
          json['bank_name']?.toString() ??
          json['bankName']?.toString(),
      bankCode:
          json['bank_code']?.toString() ??
          json['bankCode']?.toString(),
      accountNumber:
          json['bank_account_number']?.toString() ??
          json['bankAccountNumber']?.toString() ??
          json['account_number']?.toString() ??
          json['accountNumber']?.toString(),
      accountName:
          json['bank_account_name']?.toString() ??
          json['bankAccountName']?.toString() ??
          json['account_name']?.toString() ??
          json['accountName']?.toString(),
      branchName:
          json['bank_branch']?.toString() ??
          json['bankBranch']?.toString() ??
          json['branch_name']?.toString() ??
          json['branchName']?.toString(),
      qrImageUrl:
          json['qr_image_url']?.toString() ??
          json['qrImageUrl']?.toString() ??
          json['qr_url']?.toString(),
      active: _toBool(json['active']),
    );
  }

  static bool _toBool(dynamic value) {
    if (value == null) {
      return true;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String normalized =
        value.toString().trim().toLowerCase();

    return normalized != 'false' &&
        normalized != '0' &&
        normalized != 'no';
  }

  bool get hasQr {
    return qrImageUrl != null && qrImageUrl!.trim().isNotEmpty;
  }
}
