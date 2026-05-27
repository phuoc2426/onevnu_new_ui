import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/data_request/phan_anh_hien_truong_request.dart';
import 'package:vnu_core/data_request/tao_hoi_dap_request.dart';
import 'package:vnu_core/models/box_service_model.dart';
import 'package:vnu_core/services/services_url.dart';

import '../data/api_response.dart';
import '../data/app_api.dart';
import '../globals.dart';
import '../models/model.dart';
import '../services/dio_options.dart';

class ApiRepository {
  ApiRepository._internal() {
    _dio = DioOptions().createDio(ServicesUrl().baseUrl);
    _apiClient = AppApiProvider(_dio);
  }

  static final ApiRepository _singleton = ApiRepository._internal();

  factory ApiRepository() {
    return _singleton;
  }

  ///dio safe http client
  late Dio _dio;

  ///eCabinet api client
  late AppApiProvider _apiClient;

  void setToken(String token) {
    Globals().token = token;
    ApiRepository._internal();
  }

  void setDomain(String baseUrl) {
    _dio = DioOptions().createDio(baseUrl);
    _apiClient = AppApiProvider(_dio);
  }

  // --  New API
  Future<SigninResponse> signin(
      String username, String password, String deviceToken) {
    return _apiClient.signin(username, password, deviceToken);
  }

  Future<SigninResponse> refreshToken(
    String refreshToken,
  ) {
    return _apiClient.refreshToken(refreshToken);
  }

  Future<void> deviceToken(
    String oldDeviceToken,
    String newDeviceToken,
    String deviceInfo,
  ) {
    return _apiClient.deviceToken(oldDeviceToken, newDeviceToken, deviceInfo);
  }

  Future<BaseResponse> signOut() {
    return _apiClient.signOut();
  }

  Future<CurrentUserModel> getCurrentUser() {
    return _apiClient.getCurrentUser();
  }

  Future<StudentInfoModel> getSinhVienInfo() {
    return _apiClient.getSinhVienInfo();
  }

  Future<List<String>> getTopics() async {
    try {
      final String json = await _apiClient.getListTopics();
      final Iterable l = jsonDecode(json);
      return l.map((e) => e.toString()).toList();
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<ApiResponse<List<NguonTinModel>>> getNguonTin(
    int pageIndex,
    int pageSize,
    String sort,
  ) {
    return _apiClient.getNguonTin(pageIndex, pageSize, sort);
  }

  Future<List<BoxServiceModel>> getBoxServices() async {
    try {
      final String json = await _apiClient.getBoxServices();
      final Iterable l = jsonDecode(json);
      final List<BoxServiceModel> services = List<BoxServiceModel>.from(
          l.map((model) => BoxServiceModel.fromJson(model)));
      services.sort((a, b) => a.thuTu.compareTo(b.thuTu));
      return services;
    } catch (e) {
      return HomeService.values
          .map((e) => BoxServiceModel(loaiBoxDichVuEnum: e.ordinal))
          .toList();
    }
  }

  Future<ApiResponse<List<CamNangModel>>> getCamNang(
    int pageIndex,
    int pageSize,
    String sort,
    String tieuDe,
  ) {
    return _apiClient.getCamNang(pageIndex, pageSize, sort, tieuDe);
  }

  Future<CamNangModel> getDetailCamNang(
    String guid,
  ) {
    return _apiClient.getDetailCamNang(guid);
  }

  Future<void> setIsRead(String guid, String loaiNotification) {
    return _apiClient.setIsRead(guid, loaiNotification);
  }

  //Liên kết đánh dấu
  Future<ApiResponse<List<LienKetDanhDauModel>>> getLienKetDanhDau(
    int pageIndex,
    int pageSize,
    String sort,
    String keyword,
  ) {
    return _apiClient.getLienKetDanhDau(pageIndex, pageSize, sort, keyword);
  }

  Future<LienKetDanhDauModel> createLienKetDanhDau(
    String tenLienKet,
    String lienKet,
  ) {
    return _apiClient.createLienKetDanhDau(tenLienKet, lienKet);
  }

  Future<void> updateLienKetDanhDau(
    String guid,
    String tenLienKet,
    String lienKet,
  ) {
    return _apiClient.updateLienKetDanhDau(guid, tenLienKet, lienKet);
  }

  Future<void> deleteLienKetDanhDau(
    String guid,
  ) {
    return _apiClient.deleteLienKetDanhDau(guid);
  }

  // Thu tuc 1 cua
  Future<List<LinhVucModel>> getTatCaLinhVucTTMC() {
    return _apiClient.getTatCaLinhVucTTMC();
  }

  Future<ApiResponse<List<ThuTucMotCuaModel>>> getThuTucMotCua(
    int pageIndex,
    int pageSize,
    String sort,
    String tieuDe,
    String linhVuc,
  ) {
    return _apiClient.getThuTucMotCua(
        pageIndex, pageSize, sort, tieuDe, linhVuc);
  }

  // Phong tro
  Future<ApiResponse<List<PhongTroModel>>> getPhongTro(
      int pageIndex, int pageSize, String sort, String guidKhuVucBanDo) {
    if (Globals().token.isNotEmpty) {
      return _apiClient.getPhongTro(
        pageIndex,
        pageSize,
        'created,desc',
        guidKhuVucBanDo,
      );
    }
    return _apiClient.getPhongTroAnonymous(
      pageIndex,
      pageSize,
      'created,desc',
      guidKhuVucBanDo,
    );
  }

  Future<List<HdsdModel>> getHuongDanSuDung() {
    return _apiClient.getHuongDanSuDung();
  }

  //Hoi dap
  Future<List<ChuDeModel>> getTatChuDeHoiDap() {
    return _apiClient.getTatChuDeHoiDap();
  }

  Future<FileDinhKemModel> uploadFileDinhKem(File fileUpload,
      {ProgressCallback? onSendProgress}) {
    return _apiClient.uploadFileDinhKem(fileUpload,
        onSendProgress: onSendProgress);
  }

  Future<HoiDapModel> guiCauHoiDap(TaoHoiDapRequest request) {
    return _apiClient.guiCauHoiDap(request);
  }

  Future<ApiResponse<List<HoiDapModel>>> getCauHoiDap(
    int pageIndex,
    int pageSize,
    String sort,
    String guidChuDe,
    String trangThaiTraLoi,
    String thoiGianGuiStart,
    String thoiGianGuiEnd,
  ) {
    return _apiClient.getCauHoiDap(pageIndex, pageSize, sort, guidChuDe,
        trangThaiTraLoi, thoiGianGuiStart, thoiGianGuiEnd);
  }

  Future<HoiDapModel> getDetailCauHoiDap(String guid) {
    return _apiClient.getDetailCauHoiDap(guid);
  }

  Future<CauTraLoiModel> getCauTraLoi(String guid) {
    return _apiClient.getCauTraLoi(guid);
  }

  Future<void> deleteCauTraLoi(String guid) {
    return _apiClient.deleteCauTraLoi(guid);
  }

  //Map
  Future<List<KhuVucBanDoModel>> getTatKhuVucBanDo() {
    if (Globals().token.isNotEmpty) {
      return _apiClient.getTatKhuVucBanDo();
    }
    return _apiClient.getAnonymousTatKhuVucBanDo();
  }

  Future<List<LoaiDiaDiemBanDoModel>> getTatLoaiDiaDiemBanDo() {
    if (Globals().token.isNotEmpty) {
      return _apiClient.getTatLoaiDiaDiemBanDo();
    }

    return _apiClient.getAnonymousTatLoaiDiaDiemBanDo();
  }

  Future<ApiResponse<List<DiaDiemBanDoModel>>> getDiaDiemBanDo(
      Map<String, dynamic> queries) {
    if (Globals().token.isNotEmpty) {
      return _apiClient.getDiaDiemBanDo(queries);
    }

    return _apiClient.getAnonymousDiaDiemBanDo(queries);
  }

  // Tin tuc
  Future<ApiResponse<List<TinTucModel>>> getTinTuc(
    int pageIndex,
    int pageSize,
    String sort,
    String tieuDe,
    String guidDonViPhatHanh,
    String thoiGianStart,
    String thoiGianEnd,
    String guidChuyenMuc,
  ) {
    return _apiClient.getTinTuc(pageIndex, pageSize, sort, tieuDe,
        guidDonViPhatHanh, thoiGianStart, thoiGianEnd, guidChuyenMuc);
  }

  Future<TinTucModel> getDetailTinTuc(String guid) {
    return _apiClient.getDetailTinTuc(guid);
  }

  Future<ApiResponse<List<TinTucModel>>> getTinTucCungChuyenMuc(
    int pageIndex,
    int pageSize,
    String sort,
    String guidChuyenMuc,
  ) {
    return _apiClient.getTinTucCungChuyenMuc(
        pageIndex, pageSize, sort, guidChuyenMuc);
  }

  Future<ApiResponse<List<TinHeThongModel>>> getTinHeThong(
    int pageIndex,
    int pageSize,
    String sort,
    String tieuDe,
    String thoiGianStart,
    String thoiGianEnd,
  ) {
    return _apiClient.getTinHeThong(
        pageIndex, pageSize, sort, tieuDe, thoiGianStart, thoiGianEnd);
  }

  Future<TinHeThongModel> getChiTietTinHeThong(
    String guid,
  ) {
    return _apiClient.getChiTietTinHeThong(guid, "HeThong");
  }

  Future<List<DonViModel>> getTatCaDonVi() {
    return _apiClient.getTatCaDonVi();
  }

  Future<DonViModel> getDonVi(
    String guid,
  ) {
    return _apiClient.getDonVi(guid);
  }

  //Thong tin sinh vien
  Future<List<String>> getDanhSachKieuTruong() {
    return _apiClient.getDanhSachKieuTruong();
  }

  Future<List<HocKyModel>> getDanhSachHocKyTheoThoiKhoaBieu(
    bool isTheoChuongTrinhDaoTao,
    String kieuTruong,
  ) {
    return _apiClient.getDanhSachHocKyTheoThoiKhoaBieu(
        isTheoChuongTrinhDaoTao, kieuTruong);
  }

  Future<List<HocKyModel>> getDanhSachHocKyTheoLichThi(
    bool isTheoChuongTrinhDaoTao,
    String kieuTruong,
  ) {
    return _apiClient.getDanhSachHocKyTheoLichThi(
        isTheoChuongTrinhDaoTao, kieuTruong);
  }

  Future<List<HocKyModel>> getDanhSachHocKyTheoDiem(
    bool isTheoChuongTrinhDaoTao,
    String kieuTruong,
  ) {
    return _apiClient.getDanhSachHocKyTheoDiem(
        isTheoChuongTrinhDaoTao, kieuTruong);
  }

  Future<List<ThoiKhoaBieuModel>> getThoiKhoaBieuHocKy(
    String idHocKy,
    String kieuTruong,
  ) {
    return _apiClient.getThoiKhoaBieuHocKy(idHocKy, kieuTruong);
  }

  Future<List<LichThiHocKyModel>> getLichThiHocKy(
    String idHocKy,
    String kieuTruong,
  ) {
    return _apiClient.getLichThiHocKy(idHocKy, kieuTruong);
  }

  Future<List<DiemThiHocKyModel>> getDiemThiHocKy(
    String idHocKy,
    String kieuTruong,
    bool isTheoChuongTrinhDaoTao,
  ) {
    return _apiClient.getDiemThiHocKy(
        idHocKy, kieuTruong, isTheoChuongTrinhDaoTao);
  }

  Future<List<DiemHocPhanModel>> getDiemHocPhanHocKy(
    String idHocKy,
    String kieuTruong,
    String idHocPhan,
  ) {
    return _apiClient.getDiemHocPhanHocKy(idHocKy, kieuTruong, idHocPhan);
  }

  Future<List<DiemTrungBinhModel>> getDiemTrungBinhHocKy(
    String idHocKy,
    String kieuTruong,
    bool isTheoChuongTrinhDaoTao,
  ) {
    return _apiClient.getDiemTrungBinhHocKy(
        idHocKy, kieuTruong, isTheoChuongTrinhDaoTao);
  }

  Future<List<LopDaoTaoModel>> getDataLopDaoTao(
    String? id,
    String? guidDonVi,
    String? idBacDaoTao,
    String? idHeDaoTao,
    String? idNganhDaoTao,
    String? idNienKhoaDaoTao,
    String? idChuongTrinhDaoTao,
  ) {
    return _apiClient.getDataLopDaoTao(id, guidDonVi, idBacDaoTao, idHeDaoTao,
        idNganhDaoTao, idNienKhoaDaoTao, idChuongTrinhDaoTao);
  }

  Future<List<TongKetDenHienTaiModel>> getTongKetDenHienTai() {
    return _apiClient.getTongKetDenHienTai();
  }

  Future<ThongBaoDaoTaoModel> getThongBaoDaoTao(String kieuTruong) {
    return _apiClient.getThongBaoDaoTao(kieuTruong);
  }

  //-- Update thong tin sinh vien
  Future<void> updateSinhVienInfo(StudentInfoModel sinhvien) {
    return _apiClient.updateSinhVienInfo(sinhvien);
  }

  Future<List<QuocGiaModel>> getDataQuocGia(
    String? id,
    String? guidDonVi,
  ) {
    return _apiClient.getDataQuocGia(id, guidDonVi);
  }

  Future<List<DanTocModel>> getDataDanToc(
    String? id,
    String? guidDonVi,
  ) {
    return _apiClient.getDataDanToc(id, guidDonVi);
  }

  Future<List<DoiTuongUuTienModel>> getDataDoiTuongUuTien(
    String? id,
    String? guidDonVi,
  ) {
    return _apiClient.getDataDoiTuongUuTien(id, guidDonVi);
  }

  Future<List<TonGiaoModel>> getDataTonGiao(
    String? id,
    String? guidDonVi,
  ) {
    return _apiClient.getDataTonGiao(id, guidDonVi);
  }

  Future<List<QuanHuyenModel>> getDataQuanHuyen(
    String? id,
    String? guidDonVi,
    String? idTinhThanhPho,
  ) {
    return _apiClient.getDataQuanHuyen(id, guidDonVi, idTinhThanhPho);
  }

  Future<List<TinhThanhModel>> getDataTinhThanhPho(
    String? id,
    String? guidDonVi,
  ) {
    return _apiClient.getDataTinhThanhPho(id, guidDonVi);
  }

  Future<List<KhuVucUuTienModel>> getDataKhuVucUuTien(
    String? id,
    String? guidDonVi,
  ) {
    return _apiClient.getDataKhuVucUuTien(id, guidDonVi);
  }

  Future<List<BacDaoTaoModel>> getDataBacDaoTao(
    String? id,
    String? guidDonVi,
  ) {
    return _apiClient.getDataBacDaoTao(id, guidDonVi);
  }

  Future<List<HeDaoTaoModel>> getDataHeDaoTao(
    String? id,
    String? guidDonVi,
    String? idBacDaoTao,
  ) {
    return _apiClient.getDataHeDaoTao(id, guidDonVi, idBacDaoTao);
  }

  Future<List<NienKhoaDaoTaoModel>> getDataNienKhoaDaoTao(
    String? id,
    String? guidDonVi,
    String? idBacDaoTao,
  ) {
    return _apiClient.getDataNienKhoaDaoTao(id, guidDonVi, idBacDaoTao);
  }

  Future<List<NganhDaoTaoModel>> getDataNganhDaoTao(
    String? id,
    String? guidDonVi,
    String? idBacDaoTao,
  ) {
    return _apiClient.getDataNganhDaoTao(id, guidDonVi, idBacDaoTao);
  }

  Future<List<ChuyenNganhDaoTaoModel>> getDataChuyenNganhDaoTao(
    String? id,
    String? guidDonVi,
    String? idBacDaoTao,
  ) {
    return _apiClient.getDataChuyenNganhDaoTao(id, guidDonVi, idBacDaoTao);
  }

  Future<List<ChuongTrinhDaoTaoModel>> getDataChuongTrinhDaoTao(
    String? id,
    String? guidDonVi,
    String? idBacDaoTao,
    String? idHeDaoTao,
    String? idNganhDaoTao,
    String? idNienKhoaDaoTao,
  ) {
    return _apiClient.getDataChuongTrinhDaoTao(id, guidDonVi, idBacDaoTao,
        idHeDaoTao, idNganhDaoTao, idNienKhoaDaoTao);
  }

  // - End update thong tin

  //Ảnh cá nhân
  Future<List<AnhCaNhanModel>> getAllAnhCanNhan() {
    return _apiClient.getAllAnhCanNhan();
  }

  Future<AnhCaNhanModel> uploadAnhCanNhan(File fileUpload,
      {ProgressCallback? onSendProgress}) {
    return _apiClient.uploadAnhCanNhan(fileUpload,
        onSendProgress: onSendProgress);
  }

  Future<void> deleteAnhCanNhan(
    String guid,
  ) {
    return _apiClient.deleteAnhCanNhan(guid);
  }

  //Thong bao
  Future<ApiResponse<List<ThongBaoModel>>> getThongBao(
    int pageIndex,
    int pageSize,
    String sort,
    bool isRead,
  ) {
    return _apiClient.getThongBao(pageIndex, pageSize, sort, isRead);
  }

  Future<ApiResponse<List<ThongBaoModel>>> getAllThongBao(
    int pageIndex,
    int pageSize,
    String sort,
  ) {
    return _apiClient.getAllThongBao(pageIndex, pageSize, sort);
  }

  //Mat Khau
  Future<List<LoaiMatKhauModel>> getDanhSachLoaiMatKhau() {
    return _apiClient.getDanhSachLoaiMatKhau();
  }

  Future<void> putQuenMatKhau(String keyLoaiMatKhau) {
    return _apiClient.putQuenMatKhau(keyLoaiMatKhau);
  }

  Future<void> putCapNhatMatKhau(
    String keyLoaiMatKhau,
    String oldPassword,
    String newPassword,
  ) {
    return _apiClient.putCapNhatMatKhau(
        keyLoaiMatKhau, oldPassword, newPassword);
  }

  Future<List<TopTinTucModel>> getTop10TinTuc(
    int? width,
    int? height, [
    int? limit,
  ]) {
    return _apiClient.getTop10TinTuc(width, height, limit);
  }

  Future<TopTinTucDetailModel> getChiTietCmsTinTuc(
      String idTinTuc, int width, int height) {
    return _apiClient.getChiTietCmsTinTuc(
      idTinTuc,
      width,
    );
  }

  Future<List<TopThongBaoModel>> getTop10ThongBao() {
    return _apiClient.getTop10ThongBao();
  }

  Future<TopTinTucDetailModel> getChiTietThongBao(String idThongBao) {
    return _apiClient.getChiTietThongBao(idThongBao);
  }

  Future<String?> getConfig() async {
    final String response = await _apiClient.getConfig();
    final Map<String, dynamic> rMap = jsonDecode(response);
    if (rMap.containsKey("domainDownload")) {
      return rMap["domainDownload"];
    }

    return null;
  }

  Future<int> getNotificationCount({bool isRead = false}) async {
    return _apiClient.getNotificationCount(isRead);
  }

  Future<List<PhanAnhHienTruongChuDeModel>> getPahtTatCaChuDe() {
    return _apiClient.getPahtTatCaChuDe();
  }

  Future<PhanAnhHienTruongModel> createPaht(PhanAnhHienTruongRequest request) {
    return _apiClient.createPaht(request);
  }

  Future<PhanAnhHienTruongModel> getPaht(
    String guid,
  ) {
    return _apiClient.getPaht(guid);
  }

  Future<ApiResponse<List<PhanAnhHienTruongModel>>> searchPaht(
    String keyword,
    int pageIndex,
    int pageSize,
    String sort,
  ) {
    return _apiClient.searchPaht(keyword, pageIndex, pageSize, sort);
  }

  Future<PhanAnhHienTruongXuLyModel> getPahtThongTinXuLy(String guid) {
    return _apiClient.getPahtThongTinXuLy(guid);
  }

  Future<ApiResponse<List<PhanAnhHienTruongModel>>> getPahtCongDong(
    String guidChuDe,
    String guidKhuVuc,
    int pageIndex,
    int pageSize,
    String sort,
  ) {
    return _apiClient.getPahtCongDong(
        guidChuDe, guidKhuVuc, pageIndex, pageSize, sort);
  }

  Future<ApiResponse<List<PhanAnhHienTruongModel>>> getPahtCaNhan(
    String guidChuDe,
    String trangThaiXuLy,
    int pageIndex,
    int pageSize,
    String sort,
  ) {
    return _apiClient.getPahtCaNhan(
        guidChuDe, trangThaiXuLy, pageIndex, pageSize, sort);
  }

  Future<void> deletePaht(String guid) {
    return _apiClient.deletePaht(guid);
  }

  // -- File
  Future<FileDinhKemModel> uploadFile(File fileUpload,
      {ProgressCallback? onSendProgress}) {
    return _apiClient.uploadFile(fileUpload, onSendProgress: onSendProgress);
  }

  // --- ---

  void dispose() {
    this.dispose();
  }
}
