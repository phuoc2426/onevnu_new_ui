import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'package:flutter/foundation.dart';

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

  Future<MyRegistrationResponse> getMyRegistrations({
    String? studentCode,
    String? identityNo,
  }) async {
    final queryParams = <String, dynamic>{};
    if (studentCode != null && studentCode.isNotEmpty) {
      queryParams['student_code'] = studentCode;
    }
    if (identityNo != null && identityNo.isNotEmpty) {
      queryParams['identity_no'] = identityNo;
    }
    await _loadTokenIfNeeded();
    final response = await _studentDio.get<Map<String, dynamic>>(
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

  Future<UploadedAttachmentListResponse> uploadAttachment({
    required RegistrationStudentPayload student,
    required List<File> files,
    String type = 'student_registration',
  }) async {
    if (files.isEmpty) {
      return UploadedAttachmentListResponse(success: true, data: const []);
    }

    final uniqueFiles = _deduplicateFiles(files);
    final formData = FormData();
    formData.fields.add(MapEntry('type', type));

    final studentJson = student.toJson();
    studentJson.forEach((key, value) {
      formData.fields.add(MapEntry('student[$key]', value?.toString() ?? ''));
    });

    for (final file in uniqueFiles) {
      formData.files.add(
        MapEntry(
          'files[]',
          await MultipartFile.fromFile(
            file.path,
            filename: path.basename(file.path),
          ),
        ),
      );
    }

    // Include Authorization token for the upload request if available.
    final uploadHeaders = <String, String>{'Accept': 'application/json'};
    final token = Globals().token;
    if (token.isNotEmpty) {
      uploadHeaders['Authorization'] = 'Bearer $token';
    }

    final response = await _dio.post<Map<String, dynamic>>(
      'attachments/upload',
      data: formData,
      options: Options(
        headers: uploadHeaders,
        contentType: 'multipart/form-data',
      ),
    );

    return UploadedAttachmentListResponse.fromJson(response.data ?? {});
  }

  Future<SingleRegistrationResponse> registerDormitory(
    RegistrationPayloadModel payload,
  ) async {
    await _loadTokenIfNeeded();
    final response = await _dio.post<Map<String, dynamic>>(
      'registrations',
      data: payload.toJson(),
      options: _jsonOptions(),
    );
    return SingleRegistrationResponse.fromJson(response.data ?? {});
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

  Options _jsonOptions() {
    // Base headers for JSON requests. Include Authorization token if available.
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    // Add Bearer token when user is authenticated.
    final token = Globals().token;
    // -------------------------------------------------
    // LOG: Kiểm tra token hiện tại của repository
    // -------------------------------------------------
    logInfo(
      '🔎 DormitoryRepo _jsonOptions – token '
      '${token.isNotEmpty ? "present (${token.substring(0, 8)}…)" : "EMPTY"}',
    );
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return Options(headers: headers);
  }

  // Ensure token is loaded from secure storage if not already in Globals.
  Future<void> _loadTokenIfNeeded() async {
    if (Globals().token.isEmpty) {
      final stored = await DataRepository().getSecureSaveKey(kLoginToken);
      if (stored != null && stored.isNotEmpty) {
        Globals().token = stored;
        // Also set token for ApiRepository if needed.
        ApiRepository().setToken(stored);
        // -------------------------------------------------
        // LOG: Token được tải từ secure storage
        // -------------------------------------------------
        logInfo(
          '🔐 _loadTokenIfNeeded – token loaded from secure storage: '
          '${stored.substring(0, 8)}…',
        );
      } else {
        // -------------------------------------------------
        // LOG: Không tìm thấy token trong secure storage
        // -------------------------------------------------
        logWarning('_loadTokenIfNeeded – secure storage token NOT found');
      }
    } else {
      // -------------------------------------------------
      // LOG: Token đã có trong Globals, không cần load lại
      // -------------------------------------------------
      logInfo(
        '✅ _loadTokenIfNeeded – token already present in Globals: '
        '${Globals().token.substring(0, 8)}…',
      );
    }
  }

  List<File> _deduplicateFiles(List<File> files) {
    final seen = <String>{};
    final result = <File>[];

    for (final file in files) {
      final key = file.absolute.path;
      if (seen.add(key)) {
        result.add(file);
      }
    }

    return result;
  }
}
