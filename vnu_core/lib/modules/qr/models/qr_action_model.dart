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
    this.requestingService,
    this.requestingHost,
    this.requestingClientId,
    this.requestedAt,
    this.requestingContextVerified = false,
    this.localAuthenticationRequired = false,
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

  final String? requestingService;
  final String? requestingHost;
  final String? requestingClientId;
  final DateTime? requestedAt;
  final bool requestingContextVerified;
  final bool localAuthenticationRequired;

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
      requestingService: _optional(json['requestingService']),
      requestingHost: _optional(json['requestingHost']),
      requestingClientId: _optional(json['requestingClientId']),
      requestedAt: DateTime.tryParse(json['requestedAt']?.toString() ?? ''),
      requestingContextVerified: json['requestingContextVerified'] == true,
      localAuthenticationRequired:
          json['localAuthenticationRequired'] == true,
    );
  }

  static String? _optional(Object? value) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
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
