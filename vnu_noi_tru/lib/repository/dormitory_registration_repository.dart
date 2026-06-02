import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_noi_tru/data/dormitory_registration_api.dart';
import 'package:vnu_noi_tru/models/model.dart';

class DormitoryRegistrationRepository {
  DormitoryRegistrationRepository._internal() {
    _dio = DioOptions().createDio(kBaseUrlNewDormitory);
    _apiClient = DormitoryRegistrationApi(_dio);
  }

  static final DormitoryRegistrationRepository _singleton =
  DormitoryRegistrationRepository._internal();

  factory DormitoryRegistrationRepository() {
    return _singleton;
  }

  late Dio _dio;
  late DormitoryRegistrationApi _apiClient;

  Future<RegistrationPeriodResponse> getRegistrationPeriods() async {
    final response = await _dio.get<Map<String, dynamic>>(
      'registration-periods',
      queryParameters: {'size': 100},
      options: _jsonOptions(),
    );
    return RegistrationPeriodResponse.fromJson(response.data ?? {});
  }

  Future<DormitoryListResponse> getDormitories() async {
    final response = await _dio.get<Map<String, dynamic>>(
      'list',
      options: _jsonOptions(),
    );
    return DormitoryListResponse.fromJson(response.data ?? {});
  }

  Future<RoomTypeListResponse> getRoomTypes() async {
    final response = await _dio.get<Map<String, dynamic>>(
      'room-types',
      options: _jsonOptions(),
    );
    return RoomTypeListResponse.fromJson(response.data ?? {});
  }

  Future<PriorityObjectListResponse> getPriorityObjects() async {
    final response = await _dio.get<Map<String, dynamic>>(
      'priority-objects',
      options: _jsonOptions(),
    );
    return PriorityObjectListResponse.fromJson(response.data ?? {});
  }

  Future<MyRegistrationResponse> getMyRegistrations({
    required String studentCode,
  }) async {
    _ensureToken();

    final response = await _dio.get<Map<String, dynamic>>(
      'registrations/me',
      queryParameters: {
        'student_code': studentCode,
      },
      options: _jsonOptions(),
    );

    return MyRegistrationResponse.fromJson(response.data ?? {});
  }

  Future<SingleRegistrationResponse> getRegistrationDetail(int id) async {
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

    final response = await _dio.post<Map<String, dynamic>>(
      'attachments/upload',
      data: formData,
      options: Options(
        headers: {'Accept': 'application/json'},
        contentType: 'multipart/form-data',
      ),
    );

    return UploadedAttachmentListResponse.fromJson(response.data ?? {});
  }

  Future<SingleRegistrationResponse> registerDormitory(
      RegistrationPayloadModel payload,
      ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'registrations',
      data: payload.toJson(),
      options: _jsonOptions(),
    );
    return SingleRegistrationResponse.fromJson(response.data ?? {});
  }

  Future<dynamic> submitDraft(int id) {
    return _apiClient.submitDraft(id);
  }

  Future<RegistrationHistoryResponse> getRegistrationHistories(int id) {
    return _apiClient.getRegistrationHistories(id);
  }

  Options _jsonOptions() {
    return Options(
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
  }

  void _ensureToken() {
    if (Globals().token.isEmpty) {
      throw Exception('Chưa có token đăng nhập. Vui lòng đăng nhập lại.');
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