import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_core/services/services_url.dart';

import '../data/hoc_bong_api.dart';
import '../models/hoc_bong_models.dart';

class HocBongRepository {
  final HocBongApiProvider api;

  HocBongRepository({required this.api});

  factory HocBongRepository.createDefault() {
    final Dio dio = DioOptions().createDio(ServicesUrl().baseUrl);
    return HocBongRepository(api: HocBongApiProvider(dio));
  }

  Future<List<HocBongModel>> getHocBongList() async {
    try {
      final data = await api.getHocBongList();
      return data;
    } catch (e) {
      logError('HocBongRepository.getHocBongList: $e');
      rethrow;
    }
  }

  Future<HocBongDetailModel> getHocBongDetail(int id) => api.getHocBongDetail(id);
  Future<HocBongValidateResultModel> validateHocBong(int id) => api.validateHocBong(id);
  Future<HocBongHoSoModel?> getDraft(int hocBongId) => api.getDraft(hocBongId);

  Future<HocBongHoSoModel> saveDraft(
    int hocBongId,
    Map<String, dynamic> data, {
    double? gpa,
    int? tongTinChi,
    String? ketQuaValidate,
  }) async {
    try {
      final draft = await api.saveDraft(
        hocBongId,
        data,
        gpa: gpa,
        tongTinChi: tongTinChi,
        ketQuaValidate: ketQuaValidate,
      );
      await clearLocalDraft(hocBongId);
      return draft;
    } catch (e) {
      await saveLocalDraft(hocBongId, data);
      logWarning('Không lưu được nháp lên server, đã lưu local: $e');
      rethrow;
    }
  }

  Future<HocBongHoSoModel> updateDraft(
    int hoSoId,
    int hocBongId,
    Map<String, dynamic> data, {
    double? gpa,
    int? tongTinChi,
    String? ketQuaValidate,
  }) async {
    try {
      final draft = await api.updateDraft(
        hoSoId,
        hocBongId,
        data,
        gpa: gpa,
        tongTinChi: tongTinChi,
        ketQuaValidate: ketQuaValidate,
      );
      await clearLocalDraft(hocBongId);
      return draft;
    } catch (e) {
      await saveLocalDraft(hocBongId, data);
      logWarning('Không cập nhật được nháp lên server, đã lưu local: $e');
      rethrow;
    }
  }

  Future<HocBongFileModel> uploadMinhChung({
    required int hoSoId,
    required File file,
    int? formFieldId,
    String? tenMinhChung,
  }) {
    return api.uploadMinhChung(
      hoSoId: hoSoId,
      file: file,
      formFieldId: formFieldId,
      tenMinhChung: tenMinhChung,
    );
  }

  Future<HocBongHoSoModel> submitHoSo(int hoSoId) => api.submitHoSo(hoSoId);
  Future<List<HocBongHoSoModel>> getHoSoCuaToi() => api.getHoSoCuaToi();
  Future<HocBongHoSoModel> getHoSoDetail(int id) => api.getHoSoDetail(id);
  Future<List<HocBongLoaiModel>> getLoaiHocBongList() => api.getLoaiHocBongList();

  String getPreviewFileUrl(int fileId) {
    final base = ServicesUrl().baseUrl;
    final path = api.previewFileUrl(fileId);
    if (base.endsWith('/') && path.startsWith('/')) {
      return '$base${path.substring(1)}';
    }
    return '$base$path';
  }

  Map<String, String> get previewAuthHeaders {
    final token = Globals().token;
    if (token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }
  Future<String> downloadPreviewFile(int fileId, String savePath) => api.downloadPreviewFile(fileId, savePath);

  Future<void> saveLocalDraft(int hocBongId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hoc_bong_draft_$hocBongId', jsonEncode(data));
  }

  Future<Map<String, dynamic>?> readLocalDraft(int hocBongId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('hoc_bong_draft_$hocBongId');
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map ? decoded.map((k, v) => MapEntry(k.toString(), v)) : null;
  }

  Future<void> clearLocalDraft(int hocBongId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hoc_bong_draft_$hocBongId');
  }

  Future<void> saveLocalPendingFiles(int hocBongId, Map<String, String> pendingFiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hoc_bong_pending_files_$hocBongId', jsonEncode(pendingFiles));
  }

  Future<Map<String, String>?> readLocalPendingFiles(int hocBongId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('hoc_bong_pending_files_$hocBongId');
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map ? decoded.map((k, v) => MapEntry(k.toString(), v.toString())) : null;
  }

  Future<void> clearLocalPendingFiles(int hocBongId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hoc_bong_pending_files_$hocBongId');
  }
}
