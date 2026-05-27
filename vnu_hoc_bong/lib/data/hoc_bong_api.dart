import 'dart:io';

import 'package:dio/dio.dart';
import '../models/hoc_bong_models.dart';
import 'hoc_bong_endpoints.dart';

class HocBongApiProvider {
  final Dio dio;

  HocBongApiProvider(this.dio);

  Future<List<HocBongModel>> getHocBongList() async {
    final res = await dio.get(HocBongEndpoints.list);
    final data = _payload(res.data);
    return _asList(data).map((e) => HocBongModel.fromJson(_asMap(e))).toList();
  }

  Future<HocBongDetailModel> getHocBongDetail(int id) async {
    final res = await dio.get(HocBongEndpoints.detail(id));
    return HocBongDetailModel.fromJson(_asMap(_payload(res.data)));
  }

  Future<HocBongValidateResultModel> validateHocBong(int id) async {
    final res = await dio.get(HocBongEndpoints.validate(id));
    return HocBongValidateResultModel.fromJson(_asMap(_payload(res.data)));
  }

  Future<HocBongHoSoModel?> getDraft(int hocBongId) async {
    try {
      final res = await dio.get(HocBongEndpoints.hoSoList);
      final data = _payload(res.data);
      if (data is List) {
        final list = data.map((e) => HocBongHoSoModel.fromJson(_asMap(e))).toList();
        for (final hs in list) {
          if (hs.hocBongId == hocBongId && hs.canEdit) {
            return hs;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<HocBongHoSoModel> saveDraft(
    int hocBongId,
    Map<String, dynamic> data, {
    double? gpa,
    int? tongTinChi,
    String? ketQuaValidate,
  }) async {
    final Map<String, dynamic> extra = {
      if (gpa != null) ...{
        'gpaHe4TuTinh': gpa,
        'gpa_tu_tinh': gpa,
        'gpaTuTinh': gpa,
        'gpa': gpa,
      },
      if (tongTinChi != null) ...{
        'tongTinChiTinhGpa': tongTinChi,
        'tong_tin_chi_tinh_gpa': tongTinChi,
        'tongTinChi': tongTinChi,
        'soTinChi': tongTinChi,
      },
      if (ketQuaValidate != null) ...{
        'ketQuaValidate': ketQuaValidate,
        'ket_qua_validate': ketQuaValidate,
      },
    };

    try {
      final body = <String, dynamic>{
        'idHocBong': hocBongId,
        'duLieuDangKy': {
          ...data,
          ...extra,
        },
        ...extra,
      };
      final res = await dio.post(HocBongEndpoints.hoSoList, data: body);
      return HocBongHoSoModel.fromJson(_asMap(_payload(res.data)));
    } catch (e) {
      final body = <String, dynamic>{
        'hocBongId': hocBongId,
        'duLieuDangKy': {
          ...data,
          ...extra,
        },
        ...extra,
      };
      final res = await dio.post(HocBongEndpoints.hoSoList, data: body);
      return HocBongHoSoModel.fromJson(_asMap(_payload(res.data)));
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
    final Map<String, dynamic> extra = {
      if (gpa != null) ...{
        'gpaHe4TuTinh': gpa,
        'gpa_tu_tinh': gpa,
        'gpaTuTinh': gpa,
        'gpa': gpa,
      },
      if (tongTinChi != null) ...{
        'tongTinChiTinhGpa': tongTinChi,
        'tong_tin_chi_tinh_gpa': tongTinChi,
        'tongTinChi': tongTinChi,
        'soTinChi': tongTinChi,
      },
      if (ketQuaValidate != null) ...{
        'ketQuaValidate': ketQuaValidate,
        'ket_qua_validate': ketQuaValidate,
      },
    };

    try {
      final body = <String, dynamic>{
        'idHocBong': hocBongId,
        'duLieuDangKy': {
          ...data,
          ...extra,
        },
        ...extra,
      };
      final res = await dio.put(HocBongEndpoints.hoSoDetail(hoSoId), data: body);
      return HocBongHoSoModel.fromJson(_asMap(_payload(res.data)));
    } catch (e) {
      final body = <String, dynamic>{
        'hocBongId': hocBongId,
        'duLieuDangKy': {
          ...data,
          ...extra,
        },
        ...extra,
      };
      final res = await dio.put(HocBongEndpoints.hoSoDetail(hoSoId), data: body);
      return HocBongHoSoModel.fromJson(_asMap(_payload(res.data)));
    }
  }

  Future<HocBongFileModel> uploadMinhChung({
    required int hoSoId,
    required File file,
    int? formFieldId,
    String? tenMinhChung,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last),
      if (formFieldId != null) 'idFormField': formFieldId,
      if (tenMinhChung != null) 'tenMinhChung': tenMinhChung,
    });
    final res = await dio.post(HocBongEndpoints.uploadMinhChung(hoSoId), data: form);
    return HocBongFileModel.fromJson(_asMap(_payload(res.data)));
  }

  Future<HocBongHoSoModel> submitHoSo(int hoSoId) async {
    final res = await dio.post(HocBongEndpoints.submitHoSo(hoSoId));
    return HocBongHoSoModel.fromJson(_asMap(_payload(res.data)));
  }

  Future<List<HocBongHoSoModel>> getHoSoCuaToi() async {
    final res = await dio.get(HocBongEndpoints.hoSoList);
    return _asList(_payload(res.data)).map((e) => HocBongHoSoModel.fromJson(_asMap(e))).toList();
  }

  Future<HocBongHoSoModel> getHoSoDetail(int id) async {
    final res = await dio.get(HocBongEndpoints.hoSoDetail(id));
    return HocBongHoSoModel.fromJson(_asMap(_payload(res.data)));
  }

  Future<List<HocBongLoaiModel>> getLoaiHocBongList() async {
    final res = await dio.get(HocBongEndpoints.loaiList);
    return _asList(_payload(res.data)).map((e) => HocBongLoaiModel.fromJson(_asMap(e))).toList();
  }

  String previewFileUrl(int fileId) => HocBongEndpoints.filePreview(fileId);

  Future<String> downloadPreviewFile(int fileId, String savePath) async {
    await dio.download(previewFileUrl(fileId), savePath);
    return savePath;
  }
}

dynamic _payload(dynamic body) {
  if (body is Map) {
    if (body.containsKey('data')) return body['data'];
    if (body.containsKey('content')) return body['content'];
  }
  return body;
}

List<dynamic> _asList(dynamic v) => v is List ? v : const [];
Map<String, dynamic> _asMap(dynamic v) => v is Map ? v.map((key, value) => MapEntry(key.toString(), value)) : <String, dynamic>{};
