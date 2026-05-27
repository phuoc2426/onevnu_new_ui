import 'package:dio/dio.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_core/services/services_url.dart';

import '../data/noitru_api.dart';
import '../data/noitru_response.dart';
import '../models/model.dart';

class NoiTruRepository {
  NoiTruRepository._internal() {
    _dio = DioOptions().createDio(ServicesUrl().baseUrl);
    _apiClient = NoiTruApiProvider(_dio);
  }

  static final NoiTruRepository _singleton = NoiTruRepository._internal();

  factory NoiTruRepository() {
    return _singleton;
  }

  ///dio safe http client
  late Dio _dio;

  ///eCabinet api client
  late NoiTruApiProvider _apiClient;

  void setDomain(String baseUrl) {
    _dio = DioOptions().createDio(ServicesUrl().baseUrl);
    _apiClient = NoiTruApiProvider(_dio);
  }

  void setToken(String token) {
    // Globals().token = token;
    NoiTruRepository._internal();
  }

  Future<NoiTruResponse<NtDanhSachTinTucModel>> getDanhSachTinTuc(
    String ID_ChuyenMuc,
    int PageNumber,
    int PageSize,
  ) {
    return _apiClient.getDanhSachTinTuc(ID_ChuyenMuc, PageNumber, PageSize);
  }

  Future<NoiTruResponse<NtThongBaoSoLuongChuaDocModel>>
      getThongBaoSoLuongChuaDoc() {
    return _apiClient.getThongBaoSoLuongChuaDoc();
  }

  Future<NoiTruResponse<Object>> danhDauDaDoc(int idD) {
    return _apiClient.danhDauDaDoc(idD);
  }

  Future<NoiTruResponse<NtDanhSachThongBaoModel>> getDanhSachThongBao(
    String TrangThai, //0: Chua doc, 1: DaDoc, Rong: tat ca
    int PageNumber,
    int PageSize,
  ) {
    return _apiClient.getDanhSachThongBao(TrangThai, PageNumber, PageSize);
  }

  Future<NoiTruResponse<NtDanhSachMenuModel>> getDanhSachMenu() {
    return _apiClient.getDanhSachMenu();
  }

  Future<NoiTruResponse<NtTinTucModel>> getChiTietTinTuc(int ID_TinTuc) {
    return _apiClient.getChiTietTinTuc(ID_TinTuc);
  }

  void dispose() {
    this.dispose();
  }
}
