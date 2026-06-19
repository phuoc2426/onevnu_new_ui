class VneidShareInfoStatusModel {
  final String? txnId;
  final String? status;
  final String? studentCode;
  final String? fullName;
  final String? identityNo;
  final String? message;

  const VneidShareInfoStatusModel({
    this.txnId,
    this.status,
    this.studentCode,
    this.fullName,
    this.identityNo,
    this.message,
  });

  factory VneidShareInfoStatusModel.fromJson(Map<String, dynamic> json) {
    return VneidShareInfoStatusModel(
      txnId: json['txnId']?.toString(),
      status: json['status']?.toString(),
      studentCode: json['studentCode']?.toString(),
      fullName: json['fullName']?.toString(),
      identityNo: json['identityNo']?.toString(),
      message: json['message']?.toString(),
    );
  }
}
