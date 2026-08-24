class QrResolvedAction {
  const QrResolvedAction({
    required this.sessionId,
    required this.type,
    required this.provider,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.requiresConfirmation,
    required this.status,
    this.expiresAt,
  });

  final String sessionId;
  final String type;
  final String provider;
  final String title;
  final String description;
  final String actionLabel;
  final bool requiresConfirmation;
  final String status;
  final DateTime? expiresAt;

  bool get isIdp => provider.toUpperCase() == 'VNU_IDP' ||
      type.toUpperCase().contains('IDP');

  factory QrResolvedAction.fromJson(Map<String, dynamic> json) {
    return QrResolvedAction(
      sessionId: json['sessionId']?.toString().trim() ?? '',
      type: json['type']?.toString().trim() ?? 'UNKNOWN',
      provider: json['provider']?.toString().trim() ?? 'UNKNOWN',
      title: json['title']?.toString().trim() ?? 'Mã QR',
      description: json['description']?.toString().trim() ?? '',
      actionLabel: json['actionLabel']?.toString().trim() ?? 'Xác nhận',
      requiresConfirmation: json['requiresConfirmation'] != false,
      status: json['status']?.toString().trim() ?? '',
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
    );
  }
}

class QrExecutionResult {
  const QrExecutionResult({
    required this.sessionId,
    required this.status,
    required this.message,
  });

  final String sessionId;
  final String status;
  final String message;

  factory QrExecutionResult.fromJson(Map<String, dynamic> json) {
    return QrExecutionResult(
      sessionId: json['sessionId']?.toString().trim() ?? '',
      status: json['status']?.toString().trim() ?? '',
      message: json['message']?.toString().trim() ??
          'Đã thực hiện yêu cầu QR thành công.',
    );
  }
}
