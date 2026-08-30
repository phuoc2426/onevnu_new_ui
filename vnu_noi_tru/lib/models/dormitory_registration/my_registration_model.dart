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
  final List<int> priorityObjectIds;
  final String? priorityObjectName;
  final int? dormitoryId;
  final int? roomTypeId;
  final int? roomId;
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
    this.priorityObjectIds = const <int>[],
    this.priorityObjectName,
    this.dormitoryId,
    this.roomTypeId,
    this.roomId,
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
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString().trim());
    }

    Map<String, dynamic>? _map(dynamic value) {
      return value is Map ? Map<String, dynamic>.from(value) : null;
    }

    final List<int> priorityIds = <int>[];
    void collectPriorityIds(dynamic raw) {
      if (raw == null) return;
      if (raw is Iterable && raw is! String) {
        for (final dynamic item in raw) {
          collectPriorityIds(item);
        }
        return;
      }
      if (raw is Map) {
        final int? id = _parseInt(
          raw['id'] ?? raw['priority_object_id'] ?? raw['priorityObjectId'],
        );
        if (id != null && !priorityIds.contains(id)) priorityIds.add(id);
        collectPriorityIds(
          raw['priority_objects'] ??
              raw['priorityObjects'] ??
              raw['priority_object_ids'] ??
              raw['priorityObjectIds'],
        );
        return;
      }
      final String text = raw.toString().trim();
      final int? direct = _parseInt(text);
      if (direct != null) {
        if (!priorityIds.contains(direct)) priorityIds.add(direct);
        return;
      }
      for (final String part in text.split(RegExp(r'[,;|]'))) {
        final int? id = _parseInt(part);
        if (id != null && !priorityIds.contains(id)) priorityIds.add(id);
      }
    }

    collectPriorityIds(
      json['priority_object_ids'] ??
          json['priorityObjectIds'] ??
          json['priority_objects'] ??
          json['priorityObjects'],
    );
    final int? singlePriorityId = _parseInt(
      json['priority_object_id'] ?? json['priorityObjectId'],
    );
    if (singlePriorityId != null && !priorityIds.contains(singlePriorityId)) {
      priorityIds.add(singlePriorityId);
    }

    final Map<String, dynamic>? room = _map(
      json['room'] ?? json['assigned_room'] ?? json['assignedRoom'],
    );
    final int? roomId = _parseInt(
      json['room_id'] ?? json['roomId'] ?? room?['id'],
    );

    String? assignedRoomText(dynamic raw) {
      if (raw == null) return null;
      if (raw is Map) {
        return (raw['room_number'] ??
                raw['roomNumber'] ??
                raw['name'] ??
                raw['code'])
            ?.toString();
      }
      return raw.toString();
    }

    final dynamic rawDocuments =
        json['documents'] ??
        json['attachments'] ??
        json['attachment_files'] ??
        json['attachmentFiles'];
    final List<UploadedAttachmentModel>? documents = rawDocuments is Iterable
        ? rawDocuments
            .whereType<Map>()
            .map(
              (Map e) => UploadedAttachmentModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : null;

    return MyRegistrationModel(
      id: _normalizeRegistrationId(json['id']),
      registrationPeriodId: _parseInt(
        json['registration_period_id'] ?? json['registrationPeriodId'],
      ),
      priorityObjectId: singlePriorityId,
      priorityObjectIds: priorityIds,
      priorityObjectName: (json['priority_object_name'] ??
              json['priorityObjectName'] ??
              json['priorityObject'])
          ?.toString(),
      dormitoryId: _parseInt(
        json['dormitory_id'] ??
            json['dormitoryId'] ??
            room?['dormitory_id'] ??
            room?['dormitoryId'],
      ),
      roomTypeId: _parseInt(json['room_type_id'] ?? json['roomTypeId']),
      roomId: roomId,
      status: json['status'] as String?,
      statusLabel: (json['status_label'] ?? json['statusLabel']) as String?,
      registrationPeriodName:
          (json['registration_period_name'] ?? json['registrationPeriodName'])
              as String?,
      studentCode: (json['student_code'] ?? json['studentCode']) as String?,
      studentName: (json['student_name'] ?? json['studentName']) as String?,
      assignedRoom: assignedRoomText(
        json['assigned_room'] ?? json['assignedRoom'] ?? json['room'],
      ),
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
      documents: documents,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'registration_period_id': registrationPeriodId,
    'priority_object_id': priorityObjectId,
    'priority_object_ids': priorityObjectIds,
    'priority_object_name': priorityObjectName,
    'dormitory_id': dormitoryId,
    'room_type_id': roomTypeId,
    'room_id': roomId,
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
