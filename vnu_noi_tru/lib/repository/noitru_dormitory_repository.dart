import 'package:dio/dio.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_noi_tru/data/noitru_api.dart';
import 'package:vnu_noi_tru/data/noitru_reponse_domitory.dart';
import 'package:vnu_noi_tru/data/requests/luu_noi_tru_request.dart';
import 'package:vnu_noi_tru/models/model.dart';

class NoitruDormitoryRepository {
  NoitruDormitoryRepository._internal() {
    _dio = DioOptions().createDio(kBaseUrlDormitory);
    _apiClient = NoiTruApiProvider(_dio);
  }

  static final NoitruDormitoryRepository _singleton =
      NoitruDormitoryRepository._internal();

  factory NoitruDormitoryRepository() {
    return _singleton;
  }

  ///dio safe http client
  late Dio _dio;

  ///eCabinet api client
  late NoiTruApiProvider _apiClient;

  void setToken(String token) {
    // Globals().token = token;
    NoitruDormitoryRepository._internal();
  }

  Future<NoitruResponseDomitory<NtDanhSachQtxlModel>> getThongTinQuaTrinhXuLy(
    int MA_Yeu_Cau,
  ) {
    return _apiClient.getThongTinQuaTrinhXuLy(MA_Yeu_Cau);
  }

  Future<NoitruResponseDomitory<NtDanhSachTrungTamLuuTruModel>>
      getDanhSachTrungTamLuuTru() {
    return _apiClient.getDanhSachTrungTamLuuTru();
  }

  Future<NoitruResponseDomitory<NtDanhSachDoiTuongUuTienModel>>
      getDanhSachDoiTuongUuTien() {
    return _apiClient.getDanhSachDoiTuongUuTien();
  }

  Future<NoitruResponseDomitory<NtDanhSachPhongModel>> getDanhSachPhong(
    int ID_TrungTamLuuTru,
  ) {
    return _apiClient.getDanhSachPhong(ID_TrungTamLuuTru);
  }

  Future<NoitruResponseDomitory<NtDanhSachDotDangKyLuuTruModel>>
      getDanhSachDotDangKy() {
    return _apiClient.getDanhSachDotDangKy();
  }

  Future<NoitruResponseDomitory<Object>> luuThongTinDangKy(
    LuuNoiTruRequest request,
  ) {
    return _apiClient.luuThongTinDangKy(request);
  }

  Future<NoitruResponseDomitory<ListPhieuDangKyNoiTruResponse>>
      getDanhSachPhieuDangKy(
    String CMND_CCCD,
  ) {
    return _apiClient.getDanhSachPhieuDangKy(CMND_CCCD);
  }

  Future<NoitruResponseDomitory<NtUrlPresignedModel>> getUrlPresigned(
    String fileName,
    String fileExtension,
    int fileSize,
  ) {
    return _apiClient.getUrlPresigned(fileName, fileExtension, fileSize);
  }

  void dispose() {
    this.dispose();
  }
}
