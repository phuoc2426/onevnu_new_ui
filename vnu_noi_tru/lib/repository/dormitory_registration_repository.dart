import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vnu_core/common/log.dart';
import 'package:path/path.dart' as path;
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/app_config_service.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_noi_tru/domain/registration/dormitory_date_codec.dart';
import 'package:vnu_noi_tru/models/model.dart';

class DormitoryRegistrationRepository {
  static const Set<String> supportedStudentUpdateFields = <String>{
    'full_name',
    'gender',
    'dob',
    'phone_number',
    'email',
    'identity_type',
    'identity_name',
    'identity_no',
    'identity_issue_date',
    'identity_issue_place',
    'country',
    'country_code',
    'national',
    'permanent_address',
    'vneid_permanent_address',
    'permanent_province_code',
    'permanent_ward_code',
    'temporary_address',
    'vneid_temporary_address',
    'temporary_province_code',
    'temporary_ward_code',
    'contact_address',
    'ethnicity',
    'religion',
    'priority_object_id',
    'faculty',
    'system',
    'level',
    'reason_stay',
    'note',
    'student_type',
    'family_members',
  };

  DormitoryRegistrationRepository._internal();

  static final DormitoryRegistrationRepository _singleton =
  DormitoryRegistrationRepository._internal();

  factory DormitoryRegistrationRepository() {
    return _singleton;
  }

  Dio? _dio;
  Dio? _studentDio;
  String _dormitoryBaseUrl = '';
  String _studentBaseUrl = '';

  Dio get _dormitoryClient {
    final Dio? client = _dio;
    if (client == null) {
      throw StateError('Dormitory API client has not been initialized');
    }
    return client;
  }

  Dio get _studentClient {
    final Dio? client = _studentDio;
    if (client == null) {
      throw StateError('KTX student API client has not been initialized');
    }
    return client;
  }

  Future<RegistrationPeriodResponse> getRegistrationPeriods({
    required int dormitoryId,
  }) async {
    await _loadTokenIfNeeded();
    final response = await _dormitoryClient.get<Map<String, dynamic>>(
      '$dormitoryId/registration-periods',
      options: _jsonOptions(),
    );
    return RegistrationPeriodResponse.fromJson(response.data ?? {});
  }

  Future<DormitoryListResponse> getDormitories() async {
    await _loadTokenIfNeeded();
    final response = await _dormitoryClient.get<Map<String, dynamic>>(
      'list',
      options: _jsonOptions(),
    );
    return DormitoryListResponse.fromJson(response.data ?? {});
  }

  Future<RoomTypeListResponse> getRoomTypes({int? dormitoryId}) async {
    await _loadTokenIfNeeded();
    final response = await _dormitoryClient.get<Map<String, dynamic>>(
      'room-types',
      queryParameters: dormitoryId != null && dormitoryId > 0
          ? <String, dynamic>{'dormitory_id': dormitoryId}
          : null,
      options: _jsonOptions(),
    );
    return RoomTypeListResponse.fromJson(response.data ?? {});
  }

  Future<PriorityObjectListResponse> getPriorityObjects() async {
    await _loadTokenIfNeeded();
    final response = await _dormitoryClient.get<Map<String, dynamic>>(
      'priority-objects',
      options: _jsonOptions(),
    );
    return PriorityObjectListResponse.fromJson(response.data ?? {});
  }

  Future<List<DormitoryCountryOption>> getCountries() async {
    await _loadTokenIfNeeded();
    final Response<Map<String, dynamic>> response = await _studentClient
        .get<Map<String, dynamic>>(
      'countries',
      options: _jsonOptions(),
    );
    final dynamic raw = response.data?['data'];
    if (raw is! List) return <DormitoryCountryOption>[];
    return raw
        .whereType<Map>()
        .map((Map<dynamic, dynamic> item) =>
        DormitoryCountryOption.fromJson(
          Map<String, dynamic>.from(item),
        ))
        .where((DormitoryCountryOption item) => item.code.isNotEmpty)
        .toList();
  }

  Future<List<DormitoryProvinceOption>> getProvinces() async {
    await _loadTokenIfNeeded();
    final Response<Map<String, dynamic>> response = await _studentClient
        .get<Map<String, dynamic>>(
      'provinces',
      options: _jsonOptions(),
    );
    final dynamic raw = response.data?['data'];
    if (raw is! List) return <DormitoryProvinceOption>[];
    return raw
        .whereType<Map>()
        .map((Map<dynamic, dynamic> item) =>
        DormitoryProvinceOption.fromJson(
          Map<String, dynamic>.from(item),
        ))
        .where((DormitoryProvinceOption item) => item.id > 0)
        .toList();
  }

  Future<List<DormitoryWardOption>> getWardsByProvince(int provinceId) async {
    if (provinceId <= 0) return <DormitoryWardOption>[];
    await _loadTokenIfNeeded();
    final Response<Map<String, dynamic>> response = await _studentClient
        .get<Map<String, dynamic>>(
      'provinces/$provinceId/wards',
      options: _jsonOptions(),
    );
    final dynamic raw = response.data?['data'];
    if (raw is! List) return <DormitoryWardOption>[];
    return raw
        .whereType<Map>()
        .map((Map<dynamic, dynamic> item) =>
        DormitoryWardOption.fromJson(
          Map<String, dynamic>.from(item),
        ))
        .where((DormitoryWardOption item) => item.id > 0)
        .toList();
  }

  Future<List<
      DormitoryAccommodationStatusModel>> getAccommodationStatuses() async {
    await _loadTokenIfNeeded();
    final Response<Map<String, dynamic>> response = await _dormitoryClient
        .get<Map<String, dynamic>>(
      'registrations/statuses',
      options: _jsonOptions(),
    );

    final dynamic rawData = response.data?['data'];
    if (rawData is! List) {
      return <DormitoryAccommodationStatusModel>[];
    }

    return rawData
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) =>
          DormitoryAccommodationStatusModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
    )
        .where(
          (DormitoryAccommodationStatusModel item) =>
      item.code.isNotEmpty || item.slug.isNotEmpty,
    )
        .toList();
  }

  /// Lấy toàn bộ hồ sơ sinh viên để hiển thị lịch sử nội trú.
  ///
  /// Nguồn chính là GET /dormitory/me đúng contract mobile KTX.
  /// Ưu tiên identity_no (CCCD), sau đó mới fallback student_code; student.show
  /// chỉ là fallback tương thích nếu backend /me chưa nhận diện được hồ sơ.
  Future<MyRegistrationResponse> getMyRegistrations({
    String? studentCode,
    String? identityNo,
  }) async {
    await _loadTokenIfNeeded();

    final String normalizedStudentCode = studentCode?.trim() ?? '';
    final String normalizedIdentityNo = identityNo?.trim() ?? '';

    DioException? lastLookupError;
    MyRegistrationResponse? emptyResponse;

    Future<MyRegistrationResponse?> lookup(
      Map<String, dynamic> query, {
      required String source,
    }) async {
      try {
        final Response<Map<String, dynamic>> response = await _studentClient
            .get<Map<String, dynamic>>(
          'dormitory/me',
          queryParameters: query,
          options: _jsonOptions(),
        );
        final MyRegistrationResponse parsed =
            MyRegistrationResponse.fromJson(response.data ?? {});
        final bool hasCurrentRegistration =
            _hasCurrentKtxRegistrationData(parsed.data);
        logInfo(
          '[DORMITORY_LOOKUP] source=$source '
              'status=${response.statusCode} '
              'hasCurrentRegistration=$hasCurrentRegistration',
        );
        if (hasCurrentRegistration) {
          return parsed;
        }
        emptyResponse ??= parsed;
        return null;
      } on DioException catch (error) {
        final int? statusCode = error.response?.statusCode;
        logWarning(
          '[DORMITORY_LOOKUP] source=$source status=$statusCode',
        );
        if (statusCode != 404 && statusCode != 422) rethrow;
        lastLookupError = error;
        return null;
      }
    }

    // Priority 1: CCCD. KTX applications can be created before an MSSV is
    // assigned, so an official identity number must win over MSSV lookup.
    if (normalizedIdentityNo.isNotEmpty) {
      final MyRegistrationResponse? byIdentity = await lookup(
        <String, dynamic>{'identity_no': normalizedIdentityNo},
        source: 'identity_no',
      );
      if (byIdentity != null) return byIdentity;
    }

    // Priority 2: MSSV compatibility fallback. Historical data, receipts or
    // issues alone must not stop the CCCD lookup above from finding the actual
    // current registration.
    if (normalizedStudentCode.isNotEmpty) {
      final MyRegistrationResponse? byStudentCode = await lookup(
        <String, dynamic>{'student_code': normalizedStudentCode},
        source: 'student_code',
      );
      if (byStudentCode != null) return byStudentCode;
    }

    // Compatibility fallback only. Do not call /students/{...} with CCCD: the
    // documented path parameter is studentCode.
    if (normalizedStudentCode.isNotEmpty) {
      try {
        final String encodedStudentCode =
            Uri.encodeComponent(normalizedStudentCode);
        final Response<Map<String, dynamic>> response = await _studentClient
            .get<Map<String, dynamic>>(
          'students/$encodedStudentCode',
          options: _jsonOptions(),
        );
        return MyRegistrationResponse.fromJson(response.data ?? {});
      } on DioException catch (error) {
        final int? statusCode = error.response?.statusCode;
        if (statusCode != 404 && statusCode != 422) rethrow;
        lastLookupError ??= error;
      }
    }

    if (emptyResponse != null) return emptyResponse!;
    if (lastLookupError != null) throw lastLookupError!;

    return MyRegistrationResponse.fromJson(<String, dynamic>{
      'success': true,
      'code': 200,
      'message': 'Success',
      'data': <String, dynamic>{
        'student': null,
        'accommodations': <dynamic>[],
        'histories': <dynamic>[],
      },
    });
  }

  bool _hasCurrentKtxRegistrationData(dynamic data) {
    if (data is! Map) return false;

    bool hasCollection(
      Map<dynamic, dynamic> source,
      String key,
    ) {
      final dynamic value = source[key];
      return value is Iterable && value is! String && value.isNotEmpty;
    }

    // Only an actual registration/accommodation is allowed to stop identity
    // fallback. histories/receipts/issues/pendingChanges can exist without a
    // current KTX application and previously caused CCCD lookup to be skipped.
    if (hasCollection(data, 'accommodations') ||
        hasCollection(data, 'registrations')) {
      return true;
    }

    final dynamic student = data['student'];
    if (student is Map) {
      return hasCollection(student, 'accommodations') ||
          hasCollection(student, 'registrations');
    }

    return false;
  }

  Future<SingleRegistrationResponse> getRegistrationDetail(Object id) async {
    await _loadTokenIfNeeded();
    final response = await _dormitoryClient.get<Map<String, dynamic>>(
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
    final String effectiveType = normalizedType.isEmpty
        ? 'student_registration'
        : normalizedType;

    formData.fields.add(MapEntry<String, String>('type', effectiveType));

    final Map<String, dynamic> studentJson = student.toUploadJson();
    _normalizeDateOnlyField(studentJson, 'dob');
    _normalizeDateOnlyField(studentJson, 'identity_issue_date');
    final dynamic familyMembers = studentJson.remove('family_members');

    studentJson.forEach((String key, dynamic value) {
      if (value == null) return;
      if (value is String && value
          .trim()
          .isEmpty) return;
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
          if (value is String && value
              .trim()
              .isEmpty) return;
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
        .where(
          (MapEntry<String, String> entry) => entry.key.startsWith('student['),
    )
        .map((MapEntry<String, String> entry) => entry.key)
        .toList();

    debugPrint(
      '[DORMITORY-UPLOAD-REQUEST] '
          'type=$effectiveType, '
          'files=${uniqueFiles.length}, '
          'studentFields=$studentFieldNames',
    );

    await _loadTokenIfNeeded();

    final response = await _dormitoryClient.post<Map<String, dynamic>>(
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

    if (student.fullName
        .trim()
        .isEmpty) missingFields.add('Họ và tên');
    if (student.dob
        .trim()
        .isEmpty) missingFields.add('Ngày sinh');
    if (student.cccd
        .trim()
        .isEmpty) missingFields.add('Số CCCD/CMND');
    if (student.gender
        .trim()
        .isEmpty) missingFields.add('Giới tính');
    if (student.phone
        .trim()
        .isEmpty) missingFields.add('Số điện thoại');
    if (student.email
        .trim()
        .isEmpty) missingFields.add('Email');

    if (missingFields.isNotEmpty) {
      throw ArgumentError(
        'Thiếu thông tin sinh viên khi upload: ${missingFields.join(', ')}',
      );
    }
  }

  /// Đăng ký nội trú theo contract multipart/form-data.
  /// Ảnh thẻ không gửi trong request này; ảnh được upload riêng bằng type=AVATAR.
  Future<SingleRegistrationResponse> registerDormitory(
      RegistrationPayloadModel payload,) async {
// Load authentication token if needed
    await _loadTokenIfNeeded();

    logInfo(
      '[DORMITORY_REGISTER] started '
          'period=${payload.registrationPeriodId} '
          'dormitory=${payload.dormitoryId} '
          'roomType=${payload.roomTypeId} '
          'attachments=${payload.attachmentFileIds.length} '
          'familyMembers=${payload.student.familyMembers.length}',
    );

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

    final Map<String, dynamic> studentJson = payload.student
        .toRegistrationJson();
    _normalizeDateOnlyField(studentJson, 'dob');
    _normalizeDateOnlyField(studentJson, 'identity_issue_date');
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
    final List<String> registrationStudentFields = formData.fields
        .where((MapEntry<String, String> entry) =>
        entry.key.startsWith('student['))
        .map((MapEntry<String, String> entry) => entry.key)
        .toList();
    logInfo(
      '[DORMITORY_REGISTER] request prepared '
          'fieldCount=${formData.fields.length} fileCount=${formData.files
          .length} '
          'studentFields=$registrationStudentFields',
    );

    final response = await _dormitoryClient.post<Map<String, dynamic>>(
      'registrations',
      data: formData,
      options: _multipartOptions(),
    );

    logInfo(
      '[DORMITORY_REGISTER] response status=${response.statusCode} '
          'hasData=${response.data != null}',
    );

    return SingleRegistrationResponse.fromJson(response.data ?? {});
  }

  /// Lấy hồ sơ đầy đủ để hiển thị theo contract KTX mới.
  ///
  /// GET /students/{studentCode} chỉ nhận MSSV theo OpenAPI. Không gọi path
  /// này bằng CCCD. Hồ sơ KTX ưu tiên GET /dormitory/me?identity_no=...,
  /// sau đó mới dùng student.show theo MSSV để bổ sung dữ liệu tương thích.
  Future<Map<String, dynamic>?> getStudentFullProfile({
    String? studentCode,
    String? identityNo,
  }) async {
    await _loadTokenIfNeeded();

    final String normalizedStudentCode = studentCode?.trim() ?? '';
    final String normalizedIdentityNo = identityNo?.trim() ?? '';

    // Prefer CCCD here as well so the profile used by the KTX dashboard is
    // hydrated from the same record as the registration lookup.
    if (normalizedIdentityNo.isNotEmpty) {
      try {
        final Response<Map<String, dynamic>> response =
            await _studentClient.get<Map<String, dynamic>>(
          'dormitory/me',
          queryParameters: <String, dynamic>{
            'identity_no': normalizedIdentityNo,
          },
          options: _jsonOptions(),
        );
        final dynamic data = response.data?['data'];
        if (data is Map) {
          final Map<String, dynamic> mapped =
              Map<String, dynamic>.from(data);
          if (mapped['student'] is Map ||
              _hasCurrentKtxRegistrationData(mapped)) {
            return mapped;
          }
        }
      } on DioException catch (error) {
        final int? statusCode = error.response?.statusCode;
        if (statusCode != 404 && statusCode != 422) rethrow;
      }
    }

    if (normalizedStudentCode.isNotEmpty) {
      try {
        final String encodedStudentCode =
            Uri.encodeComponent(normalizedStudentCode);
        final Response<Map<String, dynamic>> response =
            await _studentClient.get<Map<String, dynamic>>(
          'students/$encodedStudentCode',
          options: _jsonOptions(),
        );
        final dynamic data = response.data?['data'];
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      } on DioException catch (error) {
        final int? statusCode = error.response?.statusCode;
        if (statusCode != 404 && statusCode != 422) rethrow;
      }
    }

    return null;
  }

  /// Bổ sung label/chi tiết cho dữ liệu nhúng khi OpenAPI student.show chỉ trả
  /// Issue dạng rút gọn. GET /issues/{id} trả type_label, priority_label,
  /// status_label, images và comments; lỗi enrichment không làm hỏng màn hình.
  Future<Map<String, dynamic>> enrichStudentDataForDisplay(
    Map<String, dynamic> source,
  ) async {
    await _loadTokenIfNeeded();

    final Map<String, dynamic> result = Map<String, dynamic>.from(source);
    final dynamic rawIssues = result['issues'];
    if (rawIssues is! Iterable || rawIssues is String) return result;

    final List<dynamic> issues = List<dynamic>.from(rawIssues);
    if (issues.isEmpty) return result;

    final List<Future<dynamic>> futures = issues.map((dynamic rawIssue) async {
      if (rawIssue is! Map) return rawIssue;
      final Map<String, dynamic> issue = Map<String, dynamic>.from(rawIssue);
      final bool alreadyEnriched =
          (issue['type_label'] ?? issue['typeLabel']) != null &&
          (issue['priority_label'] ?? issue['priorityLabel']) != null &&
          (issue['status_label'] ?? issue['statusLabel']) != null;
      if (alreadyEnriched) return issue;

      final dynamic id = issue['id'];
      if (id == null || id.toString().trim().isEmpty) return issue;

      try {
        final String encodedId = Uri.encodeComponent(id.toString());
        final Response<Map<String, dynamic>> response =
            await _studentClient.get<Map<String, dynamic>>(
          'issues/$encodedId',
          options: _jsonOptions(),
        );
        final dynamic detail = response.data?['data'];
        if (detail is Map) {
          return <String, dynamic>{
            ...issue,
            ...Map<String, dynamic>.from(detail),
          };
        }
      } on DioException catch (error) {
        final int? statusCode = error.response?.statusCode;
        if (statusCode != 404 && statusCode != 422) {
          logWarning(
            '[DORMITORY_ISSUE_ENRICH] id=$id status=$statusCode',
          );
        }
      } catch (error) {
        logWarning('[DORMITORY_ISSUE_ENRICH] id=$id error=$error');
      }
      return issue;
    }).toList();

    result['issues'] = await Future.wait<dynamic>(futures);
    return result;
  }

  /// Lấy phần student của hồ sơ đầy đủ để hydrate màn cập nhật.
  /// /dormitory/me không trả family_members; /students/{key} trả familyMembers.
  Future<Map<String, dynamic>?> getStudentProfile({
    String? studentCode,
    String? identityNo,
  }) async {
    final Map<String, dynamic>? full = await getStudentFullProfile(
      studentCode: studentCode,
      identityNo: identityNo,
    );
    final dynamic student = full?['student'];
    return student is Map ? Map<String, dynamic>.from(student) : null;
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

    final List<String> unsupportedKeys = data.keys
        .where((String key) => !supportedStudentUpdateFields.contains(key))
        .toList();
    if (unsupportedKeys.isNotEmpty) {
      throw ArgumentError(
        'KTX UpdateStudentRequest chưa hỗ trợ: ${unsupportedKeys.join(', ')}',
      );
    }

    await _loadTokenIfNeeded();

    final String encodedIdentityNo = Uri.encodeComponent(normalizedIdentityNo);
    logInfo(
      '[DORMITORY_STUDENT_UPDATE] identityPresent=true '
          'keys=${data.keys.toList()}',
    );

    final response = await _studentClient.patch<Map<String, dynamic>>(
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
  Future<List<Map<String, dynamic>>> getRooms({int? dormitoryId}) async {
    await _loadTokenIfNeeded();

    final Map<String, dynamic> queryParameters = <String, dynamic>{
      'size': 1000,
      if (dormitoryId != null && dormitoryId > 0) 'dormitory_id': dormitoryId,
    };

    final Response<Map<String, dynamic>> response = await _dormitoryClient
        .get<Map<String, dynamic>>(
      'rooms',
      queryParameters: queryParameters,
      options: _jsonOptions(),
    );

    final dynamic rawResponse = response.data;
    final dynamic rawData = rawResponse is Map ? rawResponse['data'] : null;

    dynamic rawItems;
    if (rawData is List) {
      rawItems = rawData;
    } else if (rawData is Map) {
      rawItems = rawData['items'] ?? rawData['rooms'] ?? rawData['data'];
    }

    if (rawItems is! List) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> rooms = rawItems
        .whereType<Map>()
        .map((Map<dynamic, dynamic> item) => Map<String, dynamic>.from(item))
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
    final response = await _dormitoryClient.post<Map<String, dynamic>>(
      'registrations/$id/submit',
      data: <String, dynamic>{},
      options: _jsonOptions(),
    );
    return response.data;
  }

  Future<RegistrationHistoryResponse> getRegistrationHistories(
      Object id,) async {
    await _loadTokenIfNeeded();
    final response = await _dormitoryClient.get<Map<String, dynamic>>(
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

    final Map<String, dynamic> body = <String, dynamic>{'type': type};

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

    final response = await _studentClient.post<Map<String, dynamic>>(
      'dormitory/registrations/${Uri.encodeComponent(
          registrationId.toString())}/request-status',
      data: body,
      options: _jsonOptions(),
    );

    return response.data ?? <String, dynamic>{};
  }


  void _normalizeDateOnlyField(Map<String, dynamic> json, String key) {
    if (!json.containsKey(key)) return;
    final String? normalized = DormitoryDateCodec.normalizeNullable(json[key]);
    if (normalized == null || normalized.isEmpty) {
      json.remove(key);
      return;
    }
    json[key] = normalized;
  }

  void _addFormField(FormData formData, String key, dynamic value) {
    if (value == null) return;
    if (value is String && value
        .trim()
        .isEmpty) return;

    formData.fields.add(MapEntry<String, String>(key, value.toString()));
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
      '[DORMITORY_AUTH] tokenPresent=${token.isNotEmpty}',
    );
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return Options(headers: headers);
  }

  Future<void> _ensureApiClients() async {
    await AppConfigService().ensureLoaded();

    final String studentBaseUrl = ServicesUrl().effectiveKtxApiUrl;
    final String dormitoryBaseUrl = ServicesUrl().effectiveKtxDormitoryApiUrl;

    if (studentBaseUrl.isEmpty || dormitoryBaseUrl.isEmpty) {
      throw StateError(
        'KTX API URL is unavailable. Check /api/config on '
            '${ServicesUrl.defaultBaseUrl}.',
      );
    }

    if (_studentDio == null || _studentBaseUrl != studentBaseUrl) {
      _studentDio?.close(force: true);
      _studentDio = DioOptions().createDio(studentBaseUrl);
      _studentBaseUrl = studentBaseUrl;
      debugPrint('Dormitory student API from config: $studentBaseUrl');
    }

    if (_dio == null || _dormitoryBaseUrl != dormitoryBaseUrl) {
      _dio?.close(force: true);
      _dio = DioOptions().createDio(dormitoryBaseUrl);
      _dormitoryBaseUrl = dormitoryBaseUrl;
      debugPrint('Dormitory API from config: $dormitoryBaseUrl');
    }
  }

  Future<void> _loadTokenIfNeeded() async {
    await _ensureApiClients();

    if (Globals().token.isEmpty) {
      final stored = await DataRepository().getSecureSaveKey(kLoginToken);
      if (stored != null && stored.isNotEmpty) {
        Globals().token = stored;
        ApiRepository().setToken(stored);
        logInfo('[DORMITORY_AUTH] token loaded from secure storage');
      } else {
        logWarning('[DORMITORY_AUTH] token not found in secure storage');
      }
    } else {
      logInfo('[DORMITORY_AUTH] token already available');
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
