class RegistrationHistoryResponse {
  final bool? success;
  final List<RegistrationHistoryModel>? data;

  RegistrationHistoryResponse({this.success, this.data});

  factory RegistrationHistoryResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationHistoryResponse(
      success: json['success'] as bool?,
      data: json['data'] != null
          ? (json['data'] as List)
                .map(
                  (e) => RegistrationHistoryModel.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : null,
    );
  }
}

class RegistrationHistoryModel {
  final int? id;
  final String? action;
  final String? note;
  final DateTime? createdAt;

  RegistrationHistoryModel({this.id, this.action, this.note, this.createdAt});

  factory RegistrationHistoryModel.fromJson(Map<String, dynamic> json) {
    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return RegistrationHistoryModel(
      id: _parseInt(json['id']),
      action: json['action'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'note': note,
    'created_at': createdAt?.toIso8601String(),
  };
}
