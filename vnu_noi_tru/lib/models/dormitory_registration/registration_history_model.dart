class RegistrationHistoryResponse {
  final bool? success;
  final int? code;
  final String? message;
  final List<RegistrationHistoryModel> data;

  const RegistrationHistoryResponse({
    this.success,
    this.code,
    this.message,
    this.data = const <RegistrationHistoryModel>[],
  });

  factory RegistrationHistoryResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];
    List<dynamic> rawHistories = <dynamic>[];

    if (rawData is List) {
      rawHistories = rawData;
    } else if (rawData is Map) {
      final dynamic nested =
          rawData['histories'] ?? rawData['items'] ?? rawData['data'];
      if (nested is List) {
        rawHistories = nested;
      }
    } else if (json['histories'] is List) {
      rawHistories = json['histories'] as List<dynamic>;
    }

    return RegistrationHistoryResponse(
      success: _parseBool(json['success']),
      code: _parseInt(json['code']),
      message: json['message']?.toString(),
      data: rawHistories
          .whereType<Map>()
          .map(
            (Map item) => RegistrationHistoryModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final String normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class RegistrationHistoryModel {
  final int? id;
  final int? studentId;
  final int? accommodationId;
  final String? type;
  final String? action;
  final Map<String, dynamic> data;
  final int? performedBy;
  final String? note;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final RegistrationHistoryPerformerModel? performer;
  final RegistrationHistoryAccommodationModel? accommodation;

  const RegistrationHistoryModel({
    this.id,
    this.studentId,
    this.accommodationId,
    this.type,
    this.action,
    this.data = const <String, dynamic>{},
    this.performedBy,
    this.note,
    this.createdAt,
    this.deletedAt,
    this.performer,
    this.accommodation,
  });

  factory RegistrationHistoryModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];
    final dynamic rawPerformer = json['performer'];
    final dynamic rawAccommodation = json['accommodation'];

    return RegistrationHistoryModel(
      id: _parseInt(json['id']),
      studentId: _parseInt(json['student_id'] ?? json['studentId']),
      accommodationId: _parseInt(
        json['accommodation_id'] ?? json['accommodationId'],
      ),
      type: json['type']?.toString(),
      action: json['action']?.toString(),
      data: rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : const <String, dynamic>{},
      performedBy: _parseInt(json['performed_by'] ?? json['performedBy']),
      note: json['note']?.toString(),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      deletedAt: _parseDate(json['deleted_at'] ?? json['deletedAt']),
      performer: rawPerformer is Map
          ? RegistrationHistoryPerformerModel.fromJson(
              Map<String, dynamic>.from(rawPerformer),
            )
          : null,
      accommodation: rawAccommodation is Map
          ? RegistrationHistoryAccommodationModel.fromJson(
              Map<String, dynamic>.from(rawAccommodation),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'student_id': studentId,
        'accommodation_id': accommodationId,
        'type': type,
        'action': action,
        'data': data,
        'performed_by': performedBy,
        'note': note,
        'created_at': createdAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'performer': performer?.toJson(),
        'accommodation': accommodation?.toJson(),
      };

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class RegistrationHistoryPerformerModel {
  final Object? id;
  final String? name;
  final String? fullName;
  final String? username;
  final String? email;
  final String? role;
  final String? position;
  final String? unitName;

  const RegistrationHistoryPerformerModel({
    this.id,
    this.name,
    this.fullName,
    this.username,
    this.email,
    this.role,
    this.position,
    this.unitName,
  });

  factory RegistrationHistoryPerformerModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return RegistrationHistoryPerformerModel(
      id: json['id'],
      name: json['name']?.toString(),
      fullName: (json['full_name'] ?? json['fullName'])?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      role: (json['role_name'] ?? json['roleName'] ?? json['role'])?.toString(),
      position:
          (json['position_name'] ?? json['positionName'] ?? json['position'])
              ?.toString(),
      unitName:
          (json['unit_name'] ?? json['unitName'] ?? json['department_name'])
              ?.toString(),
    );
  }

  String get displayName {
    for (final String? value in <String?>[
      fullName,
      name,
      username,
      email,
    ]) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return 'Không có thông tin';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'full_name': fullName,
        'username': username,
        'email': email,
        'role': role,
        'position': position,
        'unit_name': unitName,
      };
}

class RegistrationHistoryAccommodationModel {
  final int? id;
  final int? studentId;
  final int? registrationPeriodId;
  final int? priorityObjectId;
  final int? dormitoryId;
  final int? roomTypeId;
  final int? roomId;
  final dynamic status;
  final dynamic asmStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? approvedAt;
  final int? approvedBy;
  final DateTime? assignedAt;
  final DateTime? checkinAt;
  final DateTime? checkoutAt;
  final String? note;
  final String? reasonStay;
  final dynamic requestStatus;
  final bool? isRoomLeader;
  final dynamic submissionLogId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const RegistrationHistoryAccommodationModel({
    this.id,
    this.studentId,
    this.registrationPeriodId,
    this.priorityObjectId,
    this.dormitoryId,
    this.roomTypeId,
    this.roomId,
    this.status,
    this.asmStatus,
    this.startDate,
    this.endDate,
    this.approvedAt,
    this.approvedBy,
    this.assignedAt,
    this.checkinAt,
    this.checkoutAt,
    this.note,
    this.reasonStay,
    this.requestStatus,
    this.isRoomLeader,
    this.submissionLogId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory RegistrationHistoryAccommodationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return RegistrationHistoryAccommodationModel(
      id: _parseInt(json['id']),
      studentId: _parseInt(json['student_id'] ?? json['studentId']),
      registrationPeriodId: _parseInt(
        json['registration_period_id'] ?? json['registrationPeriodId'],
      ),
      priorityObjectId: _parseInt(
        json['priority_object_id'] ?? json['priorityObjectId'],
      ),
      dormitoryId: _parseInt(json['dormitory_id'] ?? json['dormitoryId']),
      roomTypeId: _parseInt(json['room_type_id'] ?? json['roomTypeId']),
      roomId: _parseInt(json['room_id'] ?? json['roomId']),
      status: json['status'],
      asmStatus: json['asm_status'] ?? json['asmStatus'],
      startDate: _parseDate(json['start_date'] ?? json['startDate']),
      endDate: _parseDate(json['end_date'] ?? json['endDate']),
      approvedAt: _parseDate(json['approved_at'] ?? json['approvedAt']),
      approvedBy: _parseInt(json['approved_by'] ?? json['approvedBy']),
      assignedAt: _parseDate(json['assigned_at'] ?? json['assignedAt']),
      checkinAt: _parseDate(json['checkin_at'] ?? json['checkinAt']),
      checkoutAt: _parseDate(json['checkout_at'] ?? json['checkoutAt']),
      note: json['note']?.toString(),
      reasonStay: (json['reason_stay'] ?? json['reasonStay'])?.toString(),
      requestStatus: json['request_status'] ?? json['requestStatus'],
      isRoomLeader: _parseBool(
        json['is_room_leader'] ?? json['isRoomLeader'],
      ),
      submissionLogId: json['submission_log_id'] ?? json['submissionLogId'],
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
      deletedAt: _parseDate(json['deleted_at'] ?? json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'student_id': studentId,
        'registration_period_id': registrationPeriodId,
        'priority_object_id': priorityObjectId,
        'dormitory_id': dormitoryId,
        'room_type_id': roomTypeId,
        'room_id': roomId,
        'status': status,
        'asm_status': asmStatus,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'approved_at': approvedAt?.toIso8601String(),
        'approved_by': approvedBy,
        'assigned_at': assignedAt?.toIso8601String(),
        'checkin_at': checkinAt?.toIso8601String(),
        'checkout_at': checkoutAt?.toIso8601String(),
        'note': note,
        'reason_stay': reasonStay,
        'request_status': requestStatus,
        'is_room_leader': isRoomLeader,
        'submission_log_id': submissionLogId,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final String normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }
}
