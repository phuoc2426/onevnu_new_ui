import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_noi_tru/models/model.dart';

class DormitoryRegistrationRepository {
  DormitoryRegistrationRepository._internal() {
    _dio = DioOptions().createDio(kBaseUrlNewDormitory);
    _studentDio = DioOptions().createDio(_studentApiBaseUrl);
  }

  static const String _studentApiBaseUrl = 'https://ktx.sohatech.vn/api/';

  static final DormitoryRegistrationRepository _singleton =
      DormitoryRegistrationRepository._internal();

  factory DormitoryRegistrationRepository() {
    return _singleton;
  }

  late Dio _dio;
  late Dio _studentDio;

  Future<RegistrationPeriodResponse> getRegistrationPeriods({
    required int dormitoryId,
  }) async {
    await _loadTokenIfNeeded();
    final response = await _dio.get<Map<String, dynamic>>(
      '$dormitoryId/registration-periods',
      options: _jsonOptions(),
    );
    return RegistrationPeriodResponse.fromJson(response.data ?? {});
  }

  Future<DormitoryListResponse> getDormitories() async {
    await _loadTokenIfNeeded();
    final response = await _dio.get<Map<String, dynamic>>(
      'list',
      options: _jsonOptions(),
    );
    return DormitoryListResponse.fromJson(response.data ?? {});
  }

  Future<RoomTypeListResponse> getRoomTypes() async {
    await _loadTokenIfNeeded();
    final response = await _dio.get<Map<String, dynamic>>(
      'room-types',
      options: _jsonOptions(),
    );
    return RoomTypeListResponse.fromJson(response.data ?? {});
  }

  Future<PriorityObjectListResponse> getPriorityObjects() async {
    await _loadTokenIfNeeded();
    final response = await _dio.get<Map<String, dynamic>>(
      'priority-objects',
      options: _jsonOptions(),
    );
    return PriorityObjectListResponse.fromJson(response.data ?? {});
  }

  /// Lấy toàn bộ hồ sơ sinh viên để hiển thị lịch sử nội trú.
  ///
  /// - Sinh viên chính quy có mã sinh viên: ưu tiên student.show vì API này
  ///   trả đầy đủ student, accommodations, roommates, receipts, issues và
  ///   histories.
  /// - Thí sinh hoặc tài khoản chưa có mã sinh viên: giữ API dormitory/me để
  ///   tra cứu theo identity_no.
  /// - Nếu student.show chưa có dữ liệu, tự động fallback về dormitory/me.
  Future<MyRegistrationResponse> getMyRegistrations({
    String? studentCode,
    String? identityNo,
  }) async {
    await _loadTokenIfNeeded();

    final String normalizedStudentCode = studentCode?.trim() ?? '';
    final String normalizedIdentityNo = identityNo?.trim() ?? '';

    if (normalizedStudentCode.isNotEmpty) {
      try {
        final String encodedStudentCode =
            Uri.encodeComponent(normalizedStudentCode);
        final Response<Map<String, dynamic>> response =
            await _studentDio.get<Map<String, dynamic>>(
          'students/$encodedStudentCode',
          options: _jsonOptions(),
        );

        return MyRegistrationResponse.fromJson(response.data ?? {});
      } on DioException catch (error) {
        final int? statusCode = error.response?.statusCode;
        if (statusCode != 404 && statusCode != 422) {
          rethrow;
        }
      }
    }

    final Map<String, dynamic> queryParams = <String, dynamic>{};
    if (normalizedStudentCode.isNotEmpty) {
      queryParams['student_code'] = normalizedStudentCode;
    }
    if (normalizedIdentityNo.isNotEmpty) {
      queryParams['identity_no'] = normalizedIdentityNo;
    }

    final Response<Map<String, dynamic>> response =
        await _studentDio.get<Map<String, dynamic>>(
      'dormitory/me',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      options: _jsonOptions(),
    );

    return MyRegistrationResponse.fromJson(response.data ?? {});
  }

  Future<SingleRegistrationResponse> getRegistrationDetail(Object id) async {
    await _loadTokenIfNeeded();
    final response = await _dio.get<Map<String, dynamic>>(
      'registrations/$id',
      options: _jsonOptions(),
    );
    return SingleRegistrationResponse.fromJson(response.data ?? {});
  }

  /// Upload file dùng chung của KTX.
  ///
  /// Backend yêu cầu student[...] cho mọi loại upload, kể cả AVATAR.
  /// Ảnh thẻ dùng:
  /// - type=AVATAR
  /// - files[]
  /// - student[full_name], student[dob], student[identity_no],
  ///   student[gender], student[phone_number], student[email], ...
  Future<UploadedAttachmentListResponse> uploadAttachment({
    required RegistrationStudentPayload student,
    required List<File> files,
    String type = 'student_registration',
  }) async {
    if (files.isEmpty) {
      return UploadedAttachmentListResponse(success: true, data: const []);
    }

    _validateUploadStudent(student);

    final List<File> uniqueFiles = _deduplicateFiles(files);
    final FormData formData = FormData();
    final String normalizedType = type.trim();
    final String effectiveType =
        normalizedType.isEmpty ? 'student_registration' : normalizedType;

    formData.fields.add(
      MapEntry<String, String>('type', effectiveType),
    );

    final Map<String, dynamic> studentJson = student.toJson();
    final dynamic familyMembers = studentJson.remove('family_members');

    studentJson.forEach((String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      formData.fields.add(
        MapEntry<String, String>('student[$key]', value.toString()),
      );
    });

    if (familyMembers is List) {
      for (int index = 0; index < familyMembers.length; index++) {
        final dynamic rawMember = familyMembers[index];
        if (rawMember is! Map) continue;

        rawMember.forEach((dynamic key, dynamic value) {
          if (value == null) return;
          if (value is String && value.trim().isEmpty) return;
          formData.fields.add(
            MapEntry<String, String>(
              'student[family_members][$index][${key.toString()}]',
              value.toString(),
            ),
          );
        });
      }
    }

    for (final File file in uniqueFiles) {
      formData.files.add(
        MapEntry<String, MultipartFile>(
          'files[]',
          await MultipartFile.fromFile(
            file.path,
            filename: path.basename(file.path),
          ),
        ),
      );
    }

    final List<String> studentFieldNames = formData.fields
        .where((MapEntry<String, String> entry) =>
            entry.key.startsWith('student['))
        .map((MapEntry<String, String> entry) => entry.key)
        .toList();

    debugPrint(
      '[DORMITORY-UPLOAD-REQUEST] '
      'type=$effectiveType, '
      'files=${uniqueFiles.length}, '
      'studentFields=$studentFieldNames',
    );

    await _loadTokenIfNeeded();

    final response = await _dio.post<Map<String, dynamic>>(
      'attachments/upload',
      data: formData,
      options: _multipartOptions(),
    );

    return UploadedAttachmentListResponse.fromJson(response.data ?? {});
  }

  Future<UploadedAttachmentListResponse> uploadAvatar({
    required RegistrationStudentPayload student,
    required File file,
  }) {
    return uploadAttachment(
      student: student,
      files: <File>[file],
      type: 'AVATAR',
    );
  }

  /// Upload giấy tờ ưu tiên bằng đúng API chung đang dùng cho CCCD.
  ///
  /// Không dùng type=AVATAR. Backend sẽ nhận:
  /// - type=student_registration
  /// - files[]
  /// - student[...]
  Future<UploadedAttachmentListResponse> uploadPriorityDocuments({
    required RegistrationStudentPayload student,
    required List<File> files,
  }) {
    return uploadAttachment(
      student: student,
      files: files,
      type: 'student_registration',
    );
  }

  void _validateUploadStudent(RegistrationStudentPayload student) {
    final List<String> missingFields = <String>[];

    if (student.fullName.trim().isEmpty) missingFields.add('Họ và tên');
    if (student.dob.trim().isEmpty) missingFields.add('Ngày sinh');
    if (student.cccd.trim().isEmpty) missingFields.add('Số CCCD/CMND');
    if (student.gender.trim().isEmpty) missingFields.add('Giới tính');
    if (student.phone.trim().isEmpty) missingFields.add('Số điện thoại');
    if (student.email.trim().isEmpty) missingFields.add('Email');

    if (missingFields.isNotEmpty) {
      throw ArgumentError(
        'Thiếu thông tin sinh viên khi upload: ${missingFields.join(', ')}',
      );
    }
  }

  /// Đăng ký nội trú theo contract multipart/form-data.
  /// Ảnh thẻ không gửi trong request này; ảnh được upload riêng bằng type=AVATAR.
  Future<SingleRegistrationResponse> registerDormitory(
    RegistrationPayloadModel payload,
  ) async {
    await _loadTokenIfNeeded();

    final FormData formData = FormData();

    _addFormField(
      formData,
      'registration_period_id',
      payload.registrationPeriodId,
    );
    _addFormField(formData, 'dormitory_id', payload.dormitoryId);
    _addFormField(formData, 'room_type_id', payload.roomTypeId);
    _addFormField(formData, 'status', payload.status);
    _addFormField(formData, 'reason', payload.reason);
    _addFormField(formData, 'term_type', payload.termType);
    _addFormField(formData, 'start_date', payload.startDate);
    _addFormField(formData, 'end_date', payload.endDate);

    for (final int id in payload.priorityObjectIds) {
      _addFormField(formData, 'priority_object_ids[]', id);
    }

    for (final Object id in payload.attachmentFileIds) {
      _addFormField(formData, 'attachment_file_ids[]', id);
    }

    final Map<String, dynamic> studentJson = payload.student.toJson();
    final dynamic familyMembers = studentJson.remove('family_members');

    studentJson.forEach((String key, dynamic value) {
      _addFormField(formData, 'student[$key]', value);
    });

    if (familyMembers is List) {
      for (int index = 0; index < familyMembers.length; index++) {
        final dynamic rawMember = familyMembers[index];
        if (rawMember is! Map) continue;

        rawMember.forEach((dynamic key, dynamic value) {
          _addFormField(
            formData,
            'student[family_members][$index][${key.toString()}]',
            value,
          );
        });
      }
    }

    final response = await _dio.post<Map<String, dynamic>>(
      'registrations',
      data: formData,
      options: _multipartOptions(),
    );

    return SingleRegistrationResponse.fromJson(response.data ?? {});
  }

  /// SV tự cập nhật thông tin cá nhân khi hồ sơ chưa được duyệt/xếp phòng/lưu trú.
  Future<Map<String, dynamic>> updateStudent({
    required String identityNo,
    required Map<String, dynamic> data,
  }) async {
    final String normalizedIdentityNo = identityNo.trim();
    if (normalizedIdentityNo.isEmpty) {
      throw ArgumentError('Không tìm thấy CCCD hoặc mã sinh viên');
    }

    await _loadTokenIfNeeded();

    final String encodedIdentityNo = Uri.encodeComponent(normalizedIdentityNo);

    final response = await _studentDio.patch<Map<String, dynamic>>(
      'students/$encodedIdentityNo',
      data: data,
      options: _jsonOptions(),
    );

    return response.data ?? <String, dynamic>{};
  }


  /// Lấy danh sách phòng để sinh viên có thể chọn phòng mong muốn khi gửi
  /// yêu cầu chuyển phòng.
  ///
  /// API dùng base /api/dormitory/: GET /rooms.
  /// Response được đọc linh hoạt vì backend có thể trả data.items, data.rooms
  /// hoặc trực tiếp một danh sách trong data.
  Future<List<Map<String, dynamic>>> getRooms({
    int? dormitoryId,
  }) async {
    await _loadTokenIfNeeded();

    final Map<String, dynamic> queryParameters = <String, dynamic>{
      'size': 1000,
      if (dormitoryId != null && dormitoryId > 0)
        'dormitory_id': dormitoryId,
    };

    final Response<Map<String, dynamic>> response =
        await _dio.get<Map<String, dynamic>>(
      'rooms',
      queryParameters: queryParameters,
      options: _jsonOptions(),
    );

    final dynamic rawResponse = response.data;
    final dynamic rawData = rawResponse is Map
        ? rawResponse['data']
        : null;

    dynamic rawItems;
    if (rawData is List) {
      rawItems = rawData;
    } else if (rawData is Map) {
      rawItems = rawData['items'] ??
          rawData['rooms'] ??
          rawData['data'];
    }

    if (rawItems is! List) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> rooms = rawItems
        .whereType<Map>()
        .map((Map<dynamic, dynamic> item) =>
            Map<String, dynamic>.from(item))
        .toList();

    if (dormitoryId == null || dormitoryId <= 0) {
      return rooms;
    }

    int? readInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '');
    }

    return rooms.where((Map<String, dynamic> room) {
      final dynamic nestedDormitory = room['dormitory'];
      final int? roomDormitoryId = readInt(
        room['dormitory_id'] ??
            room['dormitoryId'] ??
            (nestedDormitory is Map ? nestedDormitory['id'] : null),
      );

      // Khi backend đã lọc nhưng không lặp lại dormitory_id trong từng phần tử,
      // vẫn giữ phần tử đó thay vì làm rỗng danh sách.
      return roomDormitoryId == null || roomDormitoryId == dormitoryId;
    }).toList();
  }

  Future<dynamic> submitDraft(Object id) async {
    await _loadTokenIfNeeded();
    final response = await _dio.post<Map<String, dynamic>>(
      'registrations/$id/submit',
      data: <String, dynamic>{},
      options: _jsonOptions(),
    );
    return response.data;
  }

  Future<RegistrationHistoryResponse> getRegistrationHistories(
    Object id,
  ) async {
    await _loadTokenIfNeeded();
    final response = await _dio.get<Map<String, dynamic>>(
      'registrations/$id/histories',
      options: _jsonOptions(),
    );
    return RegistrationHistoryResponse.fromJson(response.data ?? {});
  }

  /// Ghi nhận hoặc hủy cờ yêu cầu đổi phòng/trả phòng.
  /// API chỉ cập nhật accommodations.request_status, không tự đổi/trả phòng.
  Future<Map<String, dynamic>> updateAccommodationRequestStatus({
    required Object registrationId,
    required String type,
    int? desiredRoomId,
    String? note,
  }) async {
    const Set<String> allowedTypes = <String>{
      'change_room',
      'checkout',
      'none',
    };

    if (!allowedTypes.contains(type)) {
      throw ArgumentError.value(type, 'type', 'Loại yêu cầu không hợp lệ');
    }

    final String normalizedNote = note?.trim() ?? '';
    if (normalizedNote.length > 500) {
      throw ArgumentError('Lý do không được vượt quá 500 ký tự');
    }

    await _loadTokenIfNeeded();

    final Map<String, dynamic> body = <String, dynamic>{
      'type': type,
    };

    if (type == 'change_room' && desiredRoomId != null) {
      body['desired_room_id'] = desiredRoomId;
    }

    if (normalizedNote.isNotEmpty) {
      body['note'] = normalizedNote;
    }

    debugPrint(
      '[DORMITORY-REQUEST-STATUS] '
      'registrationId=$registrationId, type=$type, '
      'desiredRoomId=${body['desired_room_id']}, '
      'hasNote=${body.containsKey('note')}',
    );

    final response = await _studentDio.post<Map<String, dynamic>>(
      'dormitory/registrations/${Uri.encodeComponent(registrationId.toString())}/request-status',
      data: body,
      options: _jsonOptions(),
    );

    return response.data ?? <String, dynamic>{};
  }

  void _addFormField(
    FormData formData,
    String key,
    dynamic value,
  ) {
    if (value == null) return;
    if (value is String && value.trim().isEmpty) return;

    formData.fields.add(
      MapEntry<String, String>(key, value.toString()),
    );
  }

  Options _multipartOptions() {
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
    };

    final String token = Globals().token;
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return Options(
      headers: headers,
      contentType: Headers.multipartFormDataContentType,
    );
  }

  Options _jsonOptions() {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final token = Globals().token;
    logInfo(
      '🔎 DormitoryRepo _jsonOptions – token '
      '${token.isNotEmpty ? "present (${token.substring(0, 8)}…)" : "EMPTY"}',
    );
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return Options(headers: headers);
  }

  Future<void> _loadTokenIfNeeded() async {
    if (Globals().token.isEmpty) {
      final stored = await DataRepository().getSecureSaveKey(kLoginToken);
      if (stored != null && stored.isNotEmpty) {
        Globals().token = stored;
        ApiRepository().setToken(stored);
        logInfo(
          '🔐 _loadTokenIfNeeded – token loaded from secure storage: '
          '${stored.substring(0, 8)}…',
        );
      } else {
        logWarning('_loadTokenIfNeeded – secure storage token NOT found');
      }
    } else {
      logInfo(
        '✅ _loadTokenIfNeeded – token already present in Globals: '
        '${Globals().token.substring(0, 8)}…',
      );
    }
  }

  List<File> _deduplicateFiles(List<File> files) {
    final Set<String> seen = <String>{};
    final List<File> result = <File>[];

    for (final File file in files) {
      final String key = file.absolute.path;
      if (seen.add(key)) {
        result.add(file);
      }
    }

    return result;
  }
}
