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
    return SingleRegistrationResponse(
      success: json['success'] as bool?,
      data: json['data'] != null
          ? MyRegistrationModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MyRegistrationModel {
  final int? id;
  final int? registrationPeriodId;
  final int? priorityObjectId;
  final int? dormitoryId;
  final int? roomTypeId;
  final String? status;
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
      id: _parseInt(json['id']),
      registrationPeriodId: _parseInt(json['registration_period_id']),
      priorityObjectId: _parseInt(json['priority_object_id']),
      dormitoryId: _parseInt(json['dormitory_id']),
      roomTypeId: _parseInt(json['room_type_id']),
      status: json['status'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      approvedAt: json['approved_at'] as String?,
      assignedAt: json['assigned_at'] as String?,
      checkinAt: json['checkin_at'] as String?,
      checkoutAt: json['checkout_at'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
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
