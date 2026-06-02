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
  final String? name;
  final String? status;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? description;

  RegistrationPeriodModel({
    this.id,
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
      name: json['name'] as String?,
      status: json['status'] as String?,
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'] as String)
          : null,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'status': status,
    'start_time': startTime?.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'description': description,
  };
}
