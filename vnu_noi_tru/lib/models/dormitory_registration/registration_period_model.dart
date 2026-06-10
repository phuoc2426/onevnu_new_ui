class RegistrationPeriodResponse {
  final bool? success;
  final RegistrationPeriodData? data;

  RegistrationPeriodResponse({this.success, this.data});

  factory RegistrationPeriodResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationPeriodResponse(
      success: json['success'] as bool?,
      data: json['data'] != null
          ? RegistrationPeriodData.fromJson(json['data'])
          : null,
    );
  }
}

class RegistrationPeriodData {
  final List<RegistrationPeriodModel>? items;

  RegistrationPeriodData({this.items});

  factory RegistrationPeriodData.fromJson(Map<String, dynamic> json) {
    if (json['items'] == null && json['id'] != null) {
      return RegistrationPeriodData(
        items: [RegistrationPeriodModel.fromJson(json)],
      );
    }

    return RegistrationPeriodData(
      items: json['items'] != null
          ? (json['items'] as List)
                .map(
                  (e) => RegistrationPeriodModel.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : null,
    );
  }
}

class RegistrationPeriodModel {
  final int? id;
  final int? dormitoryId;
  final String? name;
  final String? status;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? description;

  RegistrationPeriodModel({
    this.id,
    this.dormitoryId,
    this.name,
    this.status,
    this.startTime,
    this.endTime,
    this.description,
  });

  factory RegistrationPeriodModel.fromJson(Map<String, dynamic> json) {
    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return RegistrationPeriodModel(
      id: _parseInt(json['id']),
      dormitoryId: _parseInt(json['dormitory_id'] ?? json['dormitoryId']),
      name: json['name'] as String?,
      status: json['status']?.toString(),
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'].toString())
          : null,
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'].toString())
          : null,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dormitory_id': dormitoryId,
    'name': name,
    'status': status,
    'start_time': startTime?.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'description': description,
  };
}
