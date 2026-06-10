import 'registration_payload_model.dart';
import 'uploaded_attachment_model.dart';

class MyRegistrationResponse {
  final bool? success;
  final int? code;
  final String? message;
  final dynamic data;
  final String? timestamp;
  final String? traceId;

  MyRegistrationResponse({
    this.success,
    this.code,
    this.message,
    this.data,
    this.timestamp,
    this.traceId,
  });

  factory MyRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return MyRegistrationResponse(
      success: json['success'],
      code: json['code'],
      message: json['message'],
      data: json['data'],
      timestamp: json['timestamp'],
      traceId: json['traceId'],
    );
  }
}

class SingleRegistrationResponse {
  final bool? success;
  final MyRegistrationModel? data;

  SingleRegistrationResponse({this.success, this.data});

  factory SingleRegistrationResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return SingleRegistrationResponse(
      success: json['success'] as bool?,
      data: rawData is Map<String, dynamic>
          ? MyRegistrationModel.fromJson(rawData)
          : rawData is Map
          ? MyRegistrationModel.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }
}

class MyRegistrationModel {
  final Object? id;
  final int? registrationPeriodId;
  final int? priorityObjectId;
  final int? dormitoryId;
  final int? roomTypeId;
  final String? status;
  final String? statusLabel;
  final String? registrationPeriodName;
  final String? studentCode;
  final String? studentName;
  final String? assignedRoom;
  final bool? isDraft;
  final String? startDate;
  final String? endDate;
  final String? approvedAt;
  final String? assignedAt;
  final String? checkinAt;
  final String? checkoutAt;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RegistrationStudentPayload? student;
  final List<UploadedAttachmentModel>? documents;

  MyRegistrationModel({
    this.id,
    this.registrationPeriodId,
    this.priorityObjectId,
    this.dormitoryId,
    this.roomTypeId,
    this.status,
    this.statusLabel,
    this.registrationPeriodName,
    this.studentCode,
    this.studentName,
    this.assignedRoom,
    this.isDraft,
    this.startDate,
    this.endDate,
    this.approvedAt,
    this.assignedAt,
    this.checkinAt,
    this.checkoutAt,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.student,
    this.documents,
  });

  factory MyRegistrationModel.fromJson(Map<String, dynamic> json) {
    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return MyRegistrationModel(
      id: _normalizeRegistrationId(json['id']),
      registrationPeriodId: _parseInt(
        json['registration_period_id'] ?? json['registrationPeriodId'],
      ),
      priorityObjectId: _parseInt(
        json['priority_object_id'] ?? json['priorityObjectId'],
      ),
      dormitoryId: _parseInt(json['dormitory_id'] ?? json['dormitoryId']),
      roomTypeId: _parseInt(json['room_type_id'] ?? json['roomTypeId']),
      status: json['status'] as String?,
      statusLabel: (json['status_label'] ?? json['statusLabel']) as String?,
      registrationPeriodName:
          (json['registration_period_name'] ?? json['registrationPeriodName'])
              as String?,
      studentCode: (json['student_code'] ?? json['studentCode']) as String?,
      studentName: (json['student_name'] ?? json['studentName']) as String?,
      assignedRoom: (json['assigned_room'] ?? json['assignedRoom']) as String?,
      isDraft: json['is_draft'] as bool? ?? json['isDraft'] as bool?,
      startDate: (json['start_date'] ?? json['startDate']) as String?,
      endDate: (json['end_date'] ?? json['endDate']) as String?,
      approvedAt: (json['approved_at'] ?? json['approvedAt']) as String?,
      assignedAt: (json['assigned_at'] ?? json['assignedAt']) as String?,
      checkinAt: (json['checkin_at'] ?? json['checkinAt']) as String?,
      checkoutAt: (json['checkout_at'] ?? json['checkoutAt']) as String?,
      note: (json['note'] ?? json['reason']) as String?,
      createdAt: (json['created_at'] ?? json['createdAt']) != null
          ? DateTime.tryParse(
              (json['created_at'] ?? json['createdAt']).toString(),
            )
          : null,
      updatedAt: (json['updated_at'] ?? json['updatedAt']) != null
          ? DateTime.tryParse(
              (json['updated_at'] ?? json['updatedAt']).toString(),
            )
          : null,
      student: json['student'] != null
          ? RegistrationStudentPayload.fromJson(
              json['student'] as Map<String, dynamic>,
            )
          : null,
      documents: json['documents'] != null
          ? (json['documents'] as List)
                .map(
                  (e) => UploadedAttachmentModel.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'registration_period_id': registrationPeriodId,
    'priority_object_id': priorityObjectId,
    'dormitory_id': dormitoryId,
    'room_type_id': roomTypeId,
    'status': status,
    'status_label': statusLabel,
    'registration_period_name': registrationPeriodName,
    'student_code': studentCode,
    'student_name': studentName,
    'assigned_room': assignedRoom,
    'is_draft': isDraft,
    'start_date': startDate,
    'end_date': endDate,
    'approved_at': approvedAt,
    'assigned_at': assignedAt,
    'checkin_at': checkinAt,
    'checkout_at': checkoutAt,
    'note': note,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'student': student?.toJson(),
    'documents': documents?.map((e) => e.toJson()).toList(),
  };
}

Object? _normalizeRegistrationId(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  final text = value.toString();
  return int.tryParse(text) ?? text;
}
