import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vnu_core/data/api_reponse_domitory.dart';
import 'package:vnu_core/data_request/phan_anh_hien_truong_request.dart';
import 'package:vnu_core/data_request/tao_hoi_dap_request.dart';

import '../models/model.dart';
import 'api_response.dart';

part 'app_api.g.dart';

@RestApi()
abstract class AppApiProvider {
  factory AppApiProvider(Dio dio, {String baseUrl}) = _AppApiProvider;

  /// New API - R Team
  @POST("/api/auth/signin")
  Future<SigninResponse> signin(
    @Field('username') String username,
    @Field('password') String password,
    @Field('deviceToken') String deviceToken,
  );

  @POST("/api/auth/refreshtoken")
  Future<SigninResponse> refreshToken(
    @Field('refreshToken') String refreshToken,
  );

  @POST("/api/auth/devicetoken")
  Future<void> deviceToken(
    @Field('oldDeviceToken') String oldDeviceToken,
    @Field('newDeviceToken') String newDeviceToken,
    @Field('deviceInfo') String deviceInfo,
  );

  @POST("/api/auth/signout")
  Future<BaseResponse> signOut();

  @GET("/api/context/getCurrentNguoiDung")
  Future<CurrentUserModel> getCurrentUser();

  // -----> Sinh Vien Folder postman
  @GET("/api/sinhvien")
  Future<StudentInfoModel> getSinhVienInfo();

  @GET('/api/nguon-tin')
  Future<ApiResponse<List<NguonTinModel>>> getNguonTin(
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
  );

  @GET('/api/cam-nang')
  Future<ApiResponse<List<CamNangModel>>> getCamNang(
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
    @Query('tieuDe') String tieuDe,
  );

  @GET('/api/cam-nang/{guid}')
  Future<CamNangModel> getDetailCamNang(
    @Path('guid') String guid,
  );

  //Liên kết đánh dấu
  @GET('/api/lien-ket-danh-dau')
  Future<ApiResponse<List<LienKetDanhDauModel>>> getLienKetDanhDau(
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
    @Query('keyword') String keyword,
  );

  @POST('/api/lien-ket-danh-dau')
  Future<LienKetDanhDauModel> createLienKetDanhDau(
    @Field('tenLienKet') String tenLienKet,
    @Field('lienKet') String lienKet,
  );

  @PUT('/api/lien-ket-danh-dau/{guid}')
  Future<void> updateLienKetDanhDau(
    @Path('guid') String guid,
    @Field('tenLienKet') String tenLienKet,
    @Field('lienKet') String lienKet,
  );

  @DELETE('/api/lien-ket-danh-dau/{guid}')
  Future<void> deleteLienKetDanhDau(
    @Path('guid') String guid,
  );

  // Thu tuc 1 cua
  @GET('/api/linh-vuc/tat-ca-linh-vuc')
  Future<List<LinhVucModel>> getTatCaLinhVucTTMC();

  @GET('/api/thu-tuc-mot-cua')
  Future<ApiResponse<List<ThuTucMotCuaModel>>> getThuTucMotCua(
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
    @Query('tenThuTuc') String tieuDe,
    @Query('guidLinhVuc') String linhVuc,
  );

  @GET('/api/phong-tro')
  Future<ApiResponse<List<PhongTroModel>>> getPhongTro(
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
    @Query('guidKhuVuc') String guidKhuVucBanDo,
  );

  // Phong tro
  @GET('/api/anonymous/phong-tro')
  Future<ApiResponse<List<PhongTroModel>>> getPhongTroAnonymous(
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
    @Query('guidKhuVuc') String guidKhuVucBanDo,
  );

  @GET('/api/huong-dan-su-dung')
  Future<List<HdsdModel>> getHuongDanSuDung();

  // Mục hỏi đáp
  //api/chu-de/tat-ca-chu-de
  @GET('/api/chu-de/tat-ca-chu-de')
  Future<List<ChuDeModel>> getTatChuDeHoiDap();

  //HoiDapModel

  @POST('/api/cau-hoi-tra-loi/upload-file-dinh-kem')
  @MultiPart()
  Future<FileDinhKemModel> uploadFileDinhKem(
    @Part() File fileUpload, {
    @SendProgress() ProgressCallback? onSendProgress,
  });

  @POST('/api/cau-hoi-tra-loi/tao-cau-hoi')
  Future<HoiDapModel> guiCauHoiDap(@Body() TaoHoiDapRequest request);

  @GET('/api/cau-hoi-tra-loi')
  Future<ApiResponse<List<HoiDapModel>>> getCauHoiDap(
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
    @Query('guidChuDe') String guidChuDe,
    @Query('trangThaiTraLoi') String trangThaiTraLoi,
    @Query('thoiGianGuiStart', encoded: false) String thoiGianGuiStart,
    @Query('thoiGianGuiEnd', encoded: false) String thoiGianGuiEnd,
  );

  @GET('/api/cau-hoi-tra-loi/{guid}')
  Future<HoiDapModel> getDetailCauHoiDap(@Path('guid') String guid);

  @GET('/api/cau-hoi-tra-loi/get-cau-tra-loi/{guid}')
  Future<CauTraLoiModel> getCauTraLoi(@Path('guid') String guid);

  @DELETE('/api/cau-hoi-tra-loi/{guid}')
  Future<void> deleteCauTraLoi(@Path('guid') String guid);

  //Map
  @GET('/api/khu-vuc-ban-do/tat-ca-khu-vuc-ban-do')
  Future<List<KhuVucBanDoModel>> getTatKhuVucBanDo();

  @GET('/api/anonymous/khu-vuc-ban-do/tat-ca-khu-vuc-ban-do')
  Future<List<KhuVucBanDoModel>> getAnonymousTatKhuVucBanDo();

  @GET('/api/loai-dia-diem-ban-do/tat-ca-loai-dia-diem-ban-do')
  Future<List<LoaiDiaDiemBanDoModel>> getTatLoaiDiaDiemBanDo();

  @GET('/api/anonymous/loai-dia-diem-ban-do/tat-ca-loai-dia-diem-ban-do')
  Future<List<LoaiDiaDiemBanDoModel>> getAnonymousTatLoaiDiaDiemBanDo();

  @GET('/api/dia-diem-ban-do')
  Future<ApiResponse<List<DiaDiemBanDoModel>>> getDiaDiemBanDo(
    @Queries() Map<String, dynamic> queries,
  );

  @GET('/api/anonymous/dia-diem-ban-do')
  Future<ApiResponse<List<DiaDiemBanDoModel>>> getAnonymousDiaDiemBanDo(
    @Queries() Map<String, dynamic> queries,
  );

  // Tin Tức
  @GET('/api/tin-tuc')
  Future<ApiResponse<List<TinTucModel>>> getTinTuc(
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
    @Query('tieuDe') String tieuDe,
    @Query('guidDonViPhatHanh') String guidDonViPhatHanh,
    @Query('thoiGianStart', encoded: false) String thoiGianStart,
    @Query('thoiGianEnd', encoded: false) String thoiGianEnd,
    @Query('guidChuyenMuc') String guidChuyenMuc,
  );

  @GET('/api/tin-tuc/{guid}')
  Future<TinTucModel> getDetailTinTuc(@Path('guid') String guid);

  @GET('/api/tin-tuc/tin-cung-chuyen-muc')
  Future<ApiResponse<List<TinTucModel>>> getTinTucCungChuyenMuc(
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
    @Query('guidChuyenMuc') String guidChuyenMuc,
  );

  // Tin He Thong
  @GET('/api/tin-he-thong')
  Future<ApiResponse<List<TinHeThongModel>>> getTinHeThong(
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
    @Query('tieuDe') String tieuDe,
    @Query('thoiGianStart', encoded: false) String thoiGianStart,
    @Query('thoiGianEnd', encoded: false) String thoiGianEnd,
  );

  @GET('/api/tin-he-thong/{guid}')
  Future<TinHeThongModel> getChiTietTinHeThong(
    @Path('guid') String guid,
    @Query('loaiTinHeThong') String loaiTinHeThong,
  );

  // Don vi
  @GET('/api/donvi/tat-ca-don-vi')
  Future<List<DonViModel>> getTatCaDonVi();

  @GET('/api/donvi/{guid}')
  Future<DonViModel> getDonVi(
    @Path('guid') String guid,
  );

  //Thong tin sinh vien

  @GET('/api/sinhvien/getThongBaoDaoTao')
  Future<ThongBaoDaoTaoModel> getThongBaoDaoTao(
    @Query('kieuTruong') String kieuTruong,
  );

  @PUT('api/sinhvien')
  Future<void> updateSinhVienInfo(@Body() StudentInfoModel sinhvien);

  @GET('api/sinhvien/getDanhSachKieuTruong')
  Future<List<String>> getDanhSachKieuTruong();

  @GET('/api/sinhvien/getDanhSachHocKyTheoThoiKhoaBieu')
  Future<List<HocKyModel>> getDanhSachHocKyTheoThoiKhoaBieu(
    @Query('isTheoChuongTrinhDaoTao') bool isTheoChuongTrinhDaoTao,
    @Query('kieuTruong') String kieuTruong,
  );

  @GET('/api/sinhvien/getDanhSachHocKyTheoLichThi')
  Future<List<HocKyModel>> getDanhSachHocKyTheoLichThi(
    @Query('isTheoChuongTrinhDaoTao') bool isTheoChuongTrinhDaoTao,
    @Query('kieuTruong') String kieuTruong,
  );

  @GET('/api/sinhvien/getDanhSachHocKyTheoDiem')
  Future<List<HocKyModel>> getDanhSachHocKyTheoDiem(
    @Query('isTheoChuongTrinhDaoTao') bool isTheoChuongTrinhDaoTao,
    @Query('kieuTruong') String kieuTruong,
  );

  @GET('/api/sinhvien/getThoiKhoaBieuHocKy')
  Future<List<ThoiKhoaBieuModel>> getThoiKhoaBieuHocKy(
    @Query('idHocKy') String idHocKy,
    @Query('kieuTruong') String kieuTruong,
  );

  @GET('/api/sinhvien/getLichThiHocKy')
  Future<List<LichThiHocKyModel>> getLichThiHocKy(
    @Query('idHocKy') String idHocKy,
    @Query('kieuTruong') String kieuTruong,
  );

  @GET('/api/sinhvien/getDiemThiHocKy')
  Future<List<DiemThiHocKyModel>> getDiemThiHocKy(
    @Query('idHocKy') String idHocKy,
    @Query('kieuTruong') String kieuTruong,
    @Query('isTheoChuongTrinhDaoTao') bool isTheoChuongTrinhDaoTao,
  );

  @GET('/api/sinhvien/getDiemHocPhanHocKy')
  Future<List<DiemHocPhanModel>> getDiemHocPhanHocKy(
    @Query('idHocKy') String idHocKy,
    @Query('kieuTruong') String kieuTruong,
    @Query('idHocPhan') String idHocPhan,
  );

  @GET('/api/sinhvien/getDiemTrungBinhHocKy')
  Future<List<DiemTrungBinhModel>> getDiemTrungBinhHocKy(
    @Query('idHocKy') String idHocKy,
    @Query('kieuTruong') String kieuTruong,
    @Query('isTheoChuongTrinhDaoTao') bool isTheoChuongTrinhDaoTao,
  );

  @GET('/api/sinhvien/getDataLopDaoTao')
  Future<List<LopDaoTaoModel>> getDataLopDaoTao(
    @Query('id') String? id,
    @Query('guidDonVi') String? guidDonVi,
    @Query('idBacDaoTao') String? idBacDaoTao,
    @Query('idHeDaoTao') String? idHeDaoTao,
    @Query('idNganhDaoTao') String? idNganhDaoTao,
    @Query('idNienKhoaDaoTao') String? idNienKhoaDaoTao,
    @Query('idChuongTrinhDaoTao') String? idChuongTrinhDaoTao,
  );

  @GET('/api/sinhvien/getTongKetDenHienTai')
  Future<List<TongKetDenHienTaiModel>> getTongKetDenHienTai();

  //-- Update thong tin sinh vien
  @GET('/api/sinhvien/getDataQuocGia')
  Future<List<QuocGiaModel>> getDataQuocGia(
    @Query('id') String? id,
    @Query('guidDonVi') String? guidDonVi,
  );

  @GET('/api/sinhvien/getDataDanToc')
  Future<List<DanTocModel>> getDataDanToc(
    @Query('id') String? id,
    @Query('guidDonVi') String? guidDonVi,
  );

  @GET('/api/sinhvien/getDataDoiTuongUuTien')
  Future<List<DoiTuongUuTienModel>> getDataDoiTuongUuTien(
    @Query('id') String? id,
    @Query('guidDonVi') String? guidDonVi,
  );

  @GET('/api/sinhvien/getDataTonGiao')
  Future<List<TonGiaoModel>> getDataTonGiao(
    @Query('id') String? id,
    @Query('guidDonVi') String? guidDonVi,
  );

  @GET('/api/sinhvien/getDataQuanHuyen')
  Future<List<QuanHuyenModel>> getDataQuanHuyen(
    @Query('id') String? id,
    @Query('guidDonVi') String? guidDonVi,
    @Query('idTinhThanhPho') String? idTinhThanhPho,
  );

  @GET('/api/sinhvien/getDataTinhThanhPho')
  Future<List<TinhThanhModel>> getDataTinhThanhPho(
    @Query('id') String? id,
    @Query('guidDonVi') String? guidDonVi,
  );

  @GET('/api/sinhvien/getDataKhuVucUuTien')
  Future<List<KhuVucUuTienModel>> getDataKhuVucUuTien(
    @Query('id') String? id,
    @Query('guidDonVi') String? guidDonVi,
  );

  @GET('/api/sinhvien/getDataHeDaoTao')
  Future<List<HeDaoTaoModel>> getDataHeDaoTao(
    @Query('id') String? id,
    @Query('guidDonVi') String? guidDonVi,
    @Query('idBacDaoTao') String? idBacDaoTao,
  );

  @GET('/api/sinhvien/getDataBacDaoTao')
  Future<List<BacDaoTaoModel>> getDataBacDaoTao(
    @Query('id') String? id,
    @Query('guidDonVi') String? guidDonVi,
  );

  @GET('/api/sinhvien/getDataNienKhoaDaoTao')
  Future<List<NienKhoaDaoTaoModel>> getDataNienKhoaDaoTao(
    @Query('id') String? id,
    @Query('guidDonVi') String? guidDonVi,
    @Query('idBacDaoTao') String? idBacDaoTao,
  );

  @GET('/api/sinhvien/getDataNganhDaoTao')
  Future<List<NganhDaoTaoModel>> getDataNganhDaoTao(
    @Query('id') String? id,
    @Query('guidDonVi') String? guidDonVi,
    @Query('idBacDaoTao') String? idBacDaoTao,
  );

  @GET('/api/sinhvien/getDataChuyenNganhDaoTao')
  Future<List<ChuyenNganhDaoTaoModel>> getDataChuyenNganhDaoTao(
    @Query('id') String? id,
    @Query('guidDonVi') String? guidDonVi,
    @Query('idBacDaoTao') String? idBacDaoTao,
  );

  @GET('/api/sinhvien/getDataChuongTrinhDaoTao')
  Future<List<ChuongTrinhDaoTaoModel>> getDataChuongTrinhDaoTao(
    @Query('id') String? id,
    @Query('guidDonVi') String? guidDonVi,
    @Query('idBacDaoTao') String? idBacDaoTao,
    @Query('idHeDaoTao') String? idHeDaoTao,
    @Query('idNganhDaoTao') String? idNganhDaoTao,
    @Query('idNienKhoaDaoTao') String? idNienKhoaDaoTao,
  );

  // - End update thong tin

  //Ảnh cá nhân
  @GET('/api/anh-ca-nhan/all')
  Future<List<AnhCaNhanModel>> getAllAnhCanNhan();

  @POST('/api/anh-ca-nhan/upload-anh-ca-nhan')
  @MultiPart()
  Future<AnhCaNhanModel> uploadAnhCanNhan(@Part() File fileUpload,
      {@SendProgress() ProgressCallback? onSendProgress});

  @DELETE('/api/anh-ca-nhan/{guid}')
  Future<void> deleteAnhCanNhan(
    @Path('guid') String guid,
  );

  //Thong Bao
  @GET('/api/notification')
  Future<ApiResponse<List<ThongBaoModel>>> getThongBao(
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
    @Query('isRead') bool isRead,
  );

  @GET('/api/notification')
  Future<ApiResponse<List<ThongBaoModel>>> getAllThongBao(
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
  );

  //Mat Khau
  @GET('/api/context/getDanhSachLoaiMatKhau')
  Future<List<LoaiMatKhauModel>> getDanhSachLoaiMatKhau();

  @PUT('/api/context/quenMatKhau')
  Future<void> putQuenMatKhau(
    @Field('keyLoaiMatKhau') String keyLoaiMatKhau,
  );

  @PUT('/api/context/capNhatMatKhau')
  Future<void> putCapNhatMatKhau(
    @Field('keyLoaiMatKhau') String keyLoaiMatKhau,
    @Field('oldPassword') String oldPassword,
    @Field('newPassword') String newPassword,
  );

  //Cms
  @GET('/api/cmsvnu/getTop10TinTuc')
  Future<List<TopTinTucModel>> getTop10TinTuc(
    @Query('width') int? width,
    @Query('height') int? height,
    @Query('limit') int? limit,
  );

  @GET('/api/cmsvnu/getChiTietTinTuc')
  Future<TopTinTucDetailModel> getChiTietCmsTinTuc(
    @Query('id') String idTinTuc,
    @Query('width') int width,
    // @Query('height') int height,
  );

  @GET('/api/cmsvnu/getTop10ThongBao')
  Future<List<TopThongBaoModel>> getTop10ThongBao();

  @GET('/api/cmsvnu/getChiTietThongBao')
  Future<TopTinTucDetailModel> getChiTietThongBao(
    @Query('id') String idThongBao,
  );

  //PAHT
  @GET('/api/chu-de-phan-anh-hien-truong/tat-ca-chu-de')
  Future<List<PhanAnhHienTruongChuDeModel>> getPahtTatCaChuDe();

  @POST('/api/phan-anh-hien-truong/tao-phan-anh-hien-truong')
  Future<PhanAnhHienTruongModel> createPaht(
      @Body() PhanAnhHienTruongRequest request);

  @GET('/api/phan-anh-hien-truong/{guid}')
  Future<PhanAnhHienTruongModel> getPaht(
    @Path('guid') String guid,
  );

  @GET('/api/phan-anh-hien-truong/search')
  Future<ApiResponse<List<PhanAnhHienTruongModel>>> searchPaht(
    @Query('keyword') String keyword,
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
  );

  @GET('/api/phan-anh-hien-truong/get-thong-tin-xu-ly/{guid}')
  Future<PhanAnhHienTruongXuLyModel> getPahtThongTinXuLy(
    @Path('guid') String guid,
  );

  @GET('/api/phan-anh-hien-truong/cong-dong')
  Future<ApiResponse<List<PhanAnhHienTruongModel>>> getPahtCongDong(
    @Query('guidChuDe') String guidChuDe,
    @Query('guidKhuVuc') String guidKhuVuc,
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
  );

  @GET('/api/phan-anh-hien-truong/ca-nhan')
  Future<ApiResponse<List<PhanAnhHienTruongModel>>> getPahtCaNhan(
    @Query('guidChuDe') String guidChuDe,
    @Query('trangThaiXuLy') String trangThaiXuLy,
    @Query('pageIndex') int pageIndex,
    @Query('pageSize') int pageSize,
    @Query('sort') String sort,
  );

  @DELETE('/api/phan-anh-hien-truong/{guid}')
  Future<void> deletePaht(
    @Path('guid') String guid,
  );

  // File Controller
  @POST('/api/file/upload')
  @MultiPart()
  Future<FileDinhKemModel> uploadFile(
    @Part() File fileUpload, {
    @SendProgress() ProgressCallback? onSendProgress,
  });

  /// ENd new api

  /// Đăng nhập
  @GET('css/layThongTinCaNhan')
  Future<APIResponseDomitory<ThongTinSinhVienModel>> getUserInfo(
    @Query('CMND_CCCD') String CMND_CCCD,
  );

  @GET('/api/config')
  Future<String> getConfig();

  @GET('/api/notification/count')
  Future<int> getNotificationCount(@Query('isRead') bool isRead);

  @GET('/api/context/getDanhSachBoxDichVu')
  Future<String> getBoxServices();

  @GET('/api/context/getDanhSachTopicNotification')
  Future<String> getListTopics();

  @POST('/api/notification/setIsRead')
  Future<void> setIsRead(
    @Field('guidItem') String guidItem,
    @Field('loaiNotification') String loaiNotification,
  );
}
