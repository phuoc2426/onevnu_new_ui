class QrResolution {
  const QrResolution({
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

  factory QrResolution.fromJson(Map<String, dynamic> json) {
    return QrResolution(
      sessionId: json['sessionId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'UNKNOWN',
      provider: json['provider']?.toString() ?? 'UNKNOWN',
      title: json['title']?.toString() ?? 'Mã QR',
      description: json['description']?.toString() ?? '',
      actionLabel: json['actionLabel']?.toString() ?? 'Xác nhận',
      requiresConfirmation: json['requiresConfirmation'] == true,
      status: json['status']?.toString() ?? '',
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
      sessionId: json['sessionId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}
