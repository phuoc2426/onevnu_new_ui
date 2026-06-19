class VneidShareInfoResponseModel {
  final int? responseCode;
  final String? description;
  final String? responseTime;

  const VneidShareInfoResponseModel({
    this.responseCode,
    this.description,
    this.responseTime,
  });

  factory VneidShareInfoResponseModel.fromJson(Map<String, dynamic> json) {
    return VneidShareInfoResponseModel(
      responseCode: json['responseCode'] is int
          ? json['responseCode'] as int
          : int.tryParse(json['responseCode']?.toString() ?? ''),
      description: json['description']?.toString(),
      responseTime: json['responseTime']?.toString(),
    );
  }
}
