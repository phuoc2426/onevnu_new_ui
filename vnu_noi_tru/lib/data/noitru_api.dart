import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vnu_noi_tru/data/noitru_reponse_domitory.dart';
import 'package:vnu_noi_tru/data/requests/luu_noi_tru_request.dart';
import 'package:vnu_noi_tru/models/nt_danh_sach_menu_model.dart';
import '../models/model.dart';
import 'noitru_response.dart';

part 'noitru_api.g.dart';

@RestApi()
abstract class NoiTruApiProvider {
  factory NoiTruApiProvider(Dio dio) = _NoiTruApiProvider;

  @POST('css/thongTinQuaTrinhXuLy')
  Future<NoitruResponseDomitory<NtDanhSachQtxlModel>> getThongTinQuaTrinhXuLy(
    @Query('MA_Yeu_Cau') int MA_Yeu_Cau,
  );
  @GET('css/danhSachTrungTamLuuTru')
  Future<NoitruResponseDomitory<NtDanhSachTrungTamLuuTruModel>>
      getDanhSachTrungTamLuuTru();

  @GET('css/danhSachDoiTuongUuTien')
  Future<NoitruResponseDomitory<NtDanhSachDoiTuongUuTienModel>>
      getDanhSachDoiTuongUuTien();

  @GET('css/danhSachLoaiPhong')
  Future<NoitruResponseDomitory<NtDanhSachPhongModel>> getDanhSachPhong(
    @Query('ID_TrungTamLuuTru') int ID_TrungTamLuuTru,
  );

  @GET('css/danhSachDotDangKyLuuTru')
  Future<NoitruResponseDomitory<NtDanhSachDotDangKyLuuTruModel>>
      getDanhSachDotDangKy();

/*
    "CMND_CCCD":"027207001054",
    "ID_DoiTuongUuTien":"[97]",
    "TrangThai":0,
    "ID_DotDangKy":2,
    "ID_TrungTamLuuTru":1,
    "ID_LoaiPhong":40,
    "FilesDinhKem":"13682"
*/
  @POST('css/luuDangKyNoiTru')
  Future<NoitruResponseDomitory<Object>> luuThongTinDangKy(
    @Body() LuuNoiTruRequest request,
  );

  @POST('css/thongTinPhieuDangKyNoiTru')
  Future<NoitruResponseDomitory<ListPhieuDangKyNoiTruResponse>>
      getDanhSachPhieuDangKy(
    @Query('CMND_CCCD') String CMND_CCCD,
  );

  @GET('css/layURLPresigned')
  Future<NoitruResponseDomitory<NtUrlPresignedModel>> getUrlPresigned(
    @Query('fileName') String fileName,
    @Query('fileExtension') String fileExtension,
    @Query('fileSize') int fileSize,
  );

  //Tin tuc
  @POST('api/mobile/tintuc/xemDanhSachTinTuc')
  @FormUrlEncoded()
  Future<NoiTruResponse<NtDanhSachTinTucModel>> getDanhSachTinTuc(
    @Field() String ID_ChuyenMuc,
    @Field() int PageNumber,
    @Field() int PageSize,
  );

  @POST('api/mobile/tintuc/chiTietTinTuc')
  @FormUrlEncoded()
  Future<NoiTruResponse<NtTinTucModel>> getChiTietTinTuc(
      @Field() int ID_TinTuc);

  @GET('api/mobile/thongbao/soLuongChuaDoc')
  Future<NoiTruResponse<NtThongBaoSoLuongChuaDocModel>>
      getThongBaoSoLuongChuaDoc();

  @POST('api/mobile/thongbao/danhDauDaDoc')
  Future<NoiTruResponse<Object>> danhDauDaDoc(@Field('ID') int idD);

  @POST('api/mobile/thongbao/xemDanhSach')
  @FormUrlEncoded()
  Future<NoiTruResponse<NtDanhSachThongBaoModel>> getDanhSachThongBao(
    @Field() String TrangThai, //0: Chua doc, 1: DaDoc, Rong: tat ca
    @Field() int PageNumber,
    @Field() int PageSize,
  );

  @POST('api/mobile/menu/xemDanhSachMenu')
  @FormUrlEncoded()
  Future<NoiTruResponse<NtDanhSachMenuModel>> getDanhSachMenu();
}
