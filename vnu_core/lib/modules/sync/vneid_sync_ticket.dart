class VneidSyncTicket {
  final String transactionCode;
  final String? status;
  final String? studentCode;
  final String? fullName;
  final String? identityNo;
  final String? message;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const VneidSyncTicket({
    required this.transactionCode,
    required this.createdAt,
    this.status,
    this.studentCode,
    this.fullName,
    this.identityNo,
    this.message,
    this.updatedAt,
  });

  VneidSyncTicket copyWith({
    String? status,
    String? studentCode,
    String? fullName,
    String? identityNo,
    String? message,
    DateTime? updatedAt,
  }) {
    return VneidSyncTicket(
      transactionCode: transactionCode,
      createdAt: createdAt,
      status: status ?? this.status,
      studentCode: studentCode ?? this.studentCode,
      fullName: fullName ?? this.fullName,
      identityNo: identityNo ?? this.identityNo,
      message: message ?? this.message,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionCode': transactionCode,
      'status': status,
      'studentCode': studentCode,
      'fullName': fullName,
      'identityNo': identityNo,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory VneidSyncTicket.fromJson(Map<String, dynamic> json) {
    return VneidSyncTicket(
      transactionCode: json['transactionCode']?.toString() ?? '',
      status: json['status']?.toString(),
      studentCode: json['studentCode']?.toString(),
      fullName: json['fullName']?.toString(),
      identityNo: json['identityNo']?.toString(),
      message: json['message']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}
