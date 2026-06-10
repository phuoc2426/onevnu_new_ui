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
  final int? studentId;
  final int? accommodationId;
  final String? type;
  final String? action;
  final dynamic data;
  final int? performedBy;
  final String? note;
  final DateTime? createdAt;

  RegistrationHistoryModel({
    this.id,
    this.studentId,
    this.accommodationId,
    this.type,
    this.action,
    this.data,
    this.performedBy,
    this.note,
    this.createdAt,
  });

  factory RegistrationHistoryModel.fromJson(Map<String, dynamic> json) {
    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return RegistrationHistoryModel(
      id: _parseInt(json['id']),
      studentId: _parseInt(json['student_id'] ?? json['studentId']),
      accommodationId: _parseInt(
        json['accommodation_id'] ?? json['accommodationId'],
      ),
      type: json['type'] as String?,
      action: json['action'] as String?,
      data: json['data'],
      performedBy: _parseInt(json['performed_by'] ?? json['performedBy']),
      note: json['note'] as String?,
      createdAt: (json['created_at'] ?? json['createdAt']) != null
          ? DateTime.tryParse(
              (json['created_at'] ?? json['createdAt']).toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'accommodation_id': accommodationId,
    'type': type,
    'action': action,
    'data': data,
    'performed_by': performedBy,
    'note': note,
    'created_at': createdAt?.toIso8601String(),
  };
}
