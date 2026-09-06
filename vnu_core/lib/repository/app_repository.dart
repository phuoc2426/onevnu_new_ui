import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/session_logout_gate.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/data_request/phan_anh_hien_truong_request.dart';
import 'package:vnu_core/data_request/tao_hoi_dap_request.dart';
import 'package:vnu_core/models/box_service_model.dart';
import 'package:vnu_core/modules/idp_auth/services/idp_client_metadata_service.dart';
import 'package:vnu_core/services/app_config_service.dart';
import 'package:vnu_core/services/services_url.dart';

import '../data/api_response.dart';
import '../data/app_api.dart';
import '../globals.dart';
import '../models/model.dart';
import '../models/admitted_student.dart';
import '../models/applicant_signin_response.dart';
import '../services/dio_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_core/modules/sync/vneid_sync_ticket.dart';

class ApiRepository {
  static const String _vneidSyncTicketsCacheKey = 'vneid_sync_tickets';
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
    if (token.trim().isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer ${token.trim()}';
    }
  }

  /// Kept for compatibility with the old domain dialog. The core API is fixed
  /// and the supplied value is intentionally ignored.
  void setDomain(String _) {
    final String token = Globals().token;

    _dio.close(force: true);
    _dio = DioOptions().createDio(ServicesUrl().baseUrl);
    _apiClient = AppApiProvider(_dio);

    if (token.isNotEmpty) {
      setToken(token);
    }

    logInfo('Core API reset to fixed URL: ${ServicesUrl().baseUrl}');
  }

  // --  New API
  Future<SigninResponse> signin(
    String username,
    String password,
    String deviceToken,
  ) async {
    await SessionLogoutGate.waitForCriticalLogout();

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/signin',
      data: {
        'username': username,
        'password': password,
        if (deviceToken.isNotEmpty) 'deviceToken': deviceToken,
      },
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    final result = SigninResponse.fromJson(response.data ?? {});
    if ((result.accessToken ?? '').isEmpty) {
      logError(
        'Signin response does not contain access token: ${response.data}',
      );
    }
    return result;
  }

  Future<SigninResponse> refreshToken(String refreshToken) {
    return _apiClient.refreshToken(refreshToken);
  }

  Future<List<VneidSyncTicket>> getCachedVneidSyncTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_vneidSyncTicketsCacheKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];

      return list
          .whereType<Map>()
          .map((e) => VneidSyncTicket.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.transactionCode.isNotEmpty)
          .toList();
    } catch (e) {
      logError('Read VNeID sync tickets cache error: $e');
      return [];
    }
  }

  Future<void> saveCachedVneidSyncTickets(List<VneidSyncTicket> tickets) async {
    final prefs = await SharedPreferences.getInstance();

    final unique = <String, VneidSyncTicket>{};

    for (final ticket in tickets) {
      unique[ticket.transactionCode] = ticket;
    }

    final data = unique.values.map((e) => e.toJson()).toList();

    await prefs.setString(_vneidSyncTicketsCacheKey, jsonEncode(data));
  }

  Future<void> upsertVneidSyncTicket(VneidSyncTicket ticket) async {
    final tickets = await getCachedVneidSyncTickets();

    final index = tickets.indexWhere(
      (e) => e.transactionCode == ticket.transactionCode,
    );

    if (index >= 0) {
      tickets[index] = ticket;
    } else {
      tickets.insert(0, ticket);
    }

    await saveCachedVneidSyncTickets(tickets);
  }

  Future<void> deviceToken(
    String oldDeviceToken,
    String newDeviceToken,
    String deviceInfo,
  ) async {
    await _dio.post<void>(
      '/api/auth/devicetoken',
      data: {
        'oldDeviceToken': oldDeviceToken,
        'newDeviceToken': newDeviceToken,
        'deviceInfo': deviceInfo,
        'accessToken': Globals().token,
      },
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (Globals().token.isNotEmpty)
            'Authorization': 'Bearer ${Globals().token}',
        },
      ),
    );
  }

  /// Đăng xuất server-side bằng token hiện tại.
  Future<void> signOut() {
    return signOutWithAccessToken(Globals().token);
  }

  /// Đăng xuất server-side bằng snapshot access token truyền vào.
  ///
  /// User-triggered fast logout clears Globals().token before the background
  /// HTTP request actually runs, therefore this method MUST NOT re-read the
  /// global token. Request-specific Authorization also survives setToken('').
  /// Backend returns HTTP 204 No Content, so the response body is ignored.
  Future<void> signOutWithAccessToken(String tokenSnapshot) async {
    final String accessToken = tokenSnapshot.trim();
    if (accessToken.isEmpty) {
      dlog('[P0_DIAG][LOGOUT_FLUTTER][SKIP] reason=no_access_token');
      return;
    }

    final String traceId = const Uuid().v4();
    final String flowId = const Uuid().v4();
    final Map<String, dynamic> clientHeaders =
        await IdpClientMetadataService().headers(
      requestId: traceId,
      flowId: flowId,
    );
    final Stopwatch stopwatch = Stopwatch()..start();
    dlog(
      '[P1A_DIAG][LOGOUT_FLUTTER][REQUEST] flowId=$flowId rid=$traceId '
      'endpoint=/api/auth/signout accessTokenLength=${accessToken.length}',
      wrapWidth: 1000,
    );

    try {
      final Response<void> response = await _dio.post<void>(
        '/api/auth/signout',
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
          headers: <String, dynamic>{
            ...clientHeaders,
            'Accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      final String backendRid =
          response.headers.value('X-Request-Id')?.trim() ?? traceId;
      dlog(
        '[P1A_DIAG][LOGOUT_FLUTTER][RESPONSE] flowId=$flowId rid=$backendRid '
        'status=${response.statusCode} elapsedMs=${stopwatch.elapsedMilliseconds}',
        wrapWidth: 1000,
      );
    } on DioException catch (error, stackTrace) {
      final String backendRid = _diagRequestId(error.response, traceId);
      dlog(
        '[P1A_DIAG][LOGOUT_FLUTTER][ERROR] flowId=$flowId rid=$backendRid '
        'status=${error.response?.statusCode} dioType=${error.type} '
        'elapsedMs=${stopwatch.elapsedMilliseconds} '
        'body=${_diagSafeBody(error.response?.data)}',
        wrapWidth: 1000,
      );
      _diagStack('[P0_DIAG][LOGOUT_FLUTTER][STACK]', stackTrace);
      rethrow;
    }
  }

  Future<CurrentUserModel> getCurrentUser() {
    return _apiClient.getCurrentUser();
  }

  // -----------------------------------------------------------------
  /// Lấy danh sách sinh viên trúng tuyển từ backend.
  ///
  /// Backend cung cấp endpoint GET /api/applicant/admitted trả về danh sách
  /// `AdmittedStudent` dưới dạng JSON. Phương thức này gọi endpoint và
  /// chuyển đổi dữ liệu thành danh sách các model Flutter.
  /// -----------------------------------------------------------------
  Future<List<AdmittedStudent>> getAdmittedStudents() async {
    // Đảm bảo token đã được thiết lập trong header của Dio (được thực hiện
    // trong ApiRepository.setToken).
    final response = await _dio.get<List<dynamic>>('/api/applicant/admitted');
    final List<dynamic> rawList = response.data ?? [];
    return rawList
        .map((e) => AdmittedStudent.fromJson(e as Map<String, dynamic>))
        .toList();
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
        l.map((model) => BoxServiceModel.fromJson(model)),
      );
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

  Future<CamNangModel> getDetailCamNang(String guid) {
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

  Future<void> deleteLienKetDanhDau(String guid) {
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
      pageIndex,
      pageSize,
      sort,
      tieuDe,
      linhVuc,
    );
  }

  // Phong tro
  Future<ApiResponse<List<PhongTroModel>>> getPhongTro(
    int pageIndex,
    int pageSize,
    String sort,
    String guidKhuVucBanDo,
  ) {
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

  Future<FileDinhKemModel> uploadFileDinhKem(
    File fileUpload, {
    ProgressCallback? onSendProgress,
  }) {
    return _apiClient.uploadFileDinhKem(
      fileUpload,
      onSendProgress: onSendProgress,
    );
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
    return _apiClient.getCauHoiDap(
      pageIndex,
      pageSize,
      sort,
      guidChuDe,
      trangThaiTraLoi,
      thoiGianGuiStart,
      thoiGianGuiEnd,
    );
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
    Map<String, dynamic> queries,
  ) {
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
    return _apiClient.getTinTuc(
      pageIndex,
      pageSize,
      sort,
      tieuDe,
      guidDonViPhatHanh,
      thoiGianStart,
      thoiGianEnd,
      guidChuyenMuc,
    );
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
      pageIndex,
      pageSize,
      sort,
      guidChuyenMuc,
    );
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
      pageIndex,
      pageSize,
      sort,
      tieuDe,
      thoiGianStart,
      thoiGianEnd,
    );
  }

  Future<TinHeThongModel> getChiTietTinHeThong(String guid) {
    return _apiClient.getChiTietTinHeThong(guid, "HeThong");
  }

  Future<List<DonViModel>> getTatCaDonVi() {
    return _apiClient.getTatCaDonVi();
  }

  Future<DonViModel> getDonVi(String guid) {
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
      isTheoChuongTrinhDaoTao,
      kieuTruong,
    );
  }

  Future<List<HocKyModel>> getDanhSachHocKyTheoLichThi(
    bool isTheoChuongTrinhDaoTao,
    String kieuTruong,
  ) {
    return _apiClient.getDanhSachHocKyTheoLichThi(
      isTheoChuongTrinhDaoTao,
      kieuTruong,
    );
  }

  Future<List<HocKyModel>> getDanhSachHocKyTheoDiem(
    bool isTheoChuongTrinhDaoTao,
    String kieuTruong,
  ) {
    return _apiClient.getDanhSachHocKyTheoDiem(
      isTheoChuongTrinhDaoTao,
      kieuTruong,
    );
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
      idHocKy,
      kieuTruong,
      isTheoChuongTrinhDaoTao,
    );
  }

  Future<List<DiemHocPhanModel>> getDiemHocPhanHocKy(
    String idHocKy,
    String kieuTruong,
    String idHocPhan,
  ) {
    return _apiClient.getDiemHocPhanHocKy(idHocKy, kieuTruong, idHocPhan);
  }

  // ---------------------------------------------------------------------------
  // Mobile API xem điểm mới: /api/mobile/diem-sinh-vien/brc1|brc2|brc3
  // ---------------------------------------------------------------------------

  String _toMobileBrcKey(String kieuTruong) {
    switch (kieuTruong) {
      case 'BangKep':
      case 'BRC2':
      case 'brc2':
        return 'brc2';
      case 'TruongGui':
      case 'BRC3':
      case 'brc3':
        return 'brc3';
      case 'TruongChinh':
      case 'BRC1':
      case 'brc1':
      default:
        return 'brc1';
    }
  }

  Future<Map<String, dynamic>> getDiemSinhVienMobileFull(
    String kieuTruong,
    bool xemCaMonNgoaiCtdt,
  ) async {
    final brc = _toMobileBrcKey(kieuTruong);

    String path;
    if (brc == 'brc1') {
      path =
          '/api/mobile/diem-sinh-vien/brc1/full?xemCaMonNgoaiCtdt=$xemCaMonNgoaiCtdt';
    } else if (brc == 'brc2') {
      path = '/api/mobile/diem-sinh-vien/brc2/full';
    } else {
      path =
          '/api/mobile/diem-sinh-vien/brc3/full?xemCaMonNgoaiCtdt=$xemCaMonNgoaiCtdt&includeChungChi=true&includeMonThieuDiem=true';
    }

    final response = await _dio.get<Map<String, dynamic>>(path);
    return response.data ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getChungChiMobile(
    String kieuTruong,
  ) async {
    final brc = _toMobileBrcKey(kieuTruong);

    if (brc == 'brc2') {
      return <Map<String, dynamic>>[];
    }

    final response = await _dio.get<List<dynamic>>(
      '/api/mobile/diem-sinh-vien/$brc/chung-chi',
    );

    return (response.data ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<DiemHocPhanModel>> getDiemHocPhanHocKyMobile(
    String idHocKy,
    String kieuTruong,
    String idHocPhan,
  ) async {
    final brc = _toMobileBrcKey(kieuTruong);

    final response = await _dio.get<List<dynamic>>(
      '/api/mobile/diem-sinh-vien/$brc/hoc-ky/$idHocKy/hoc-phan/$idHocPhan/diem-chi-tiet',
    );

    return (response.data ?? []).whereType<Map>().map((e) {
      final map = Map<String, dynamic>.from(e);

      return DiemHocPhanModel.fromJson({
        ...map,
        'loaiDiemHocPhan':
            map['banChatKyThi'] ?? map['loaiDiemHocPhan'] ?? map['RES_NATURE'],
        'trongSo': (map['trongSo'] ?? map['coeffi'] ?? map['COEFFI'])
            ?.toString(),
        'diemHe10': (map['diem'] ?? map['resPnt'] ?? map['RES_PNT'])
            ?.toString(),
      });
    }).toList();
  }

  Future<List<DiemTrungBinhModel>> getDiemTrungBinhHocKy(
    String idHocKy,
    String kieuTruong,
    bool isTheoChuongTrinhDaoTao,
  ) {
    return _apiClient.getDiemTrungBinhHocKy(
      idHocKy,
      kieuTruong,
      isTheoChuongTrinhDaoTao,
    );
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
    return _apiClient.getDataLopDaoTao(
      id,
      guidDonVi,
      idBacDaoTao,
      idHeDaoTao,
      idNganhDaoTao,
      idNienKhoaDaoTao,
      idChuongTrinhDaoTao,
    );
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

  Future<void> updateDiaChiTamTru(StudentInfoModel sinhvien) {
    final body = {
      "diaChiTamTru": sinhvien.diaChiTamTru,
      "idDiaChiTamTruQuocGia": sinhvien.diaChiTamTruQuocGia,
      "idDiaChiTamTruTinhThanhPho": sinhvien.diaChiTamTruTinhThanhPho,
      "idDiaChiTamTruQuanHuyen": sinhvien.diaChiTamTruQuanHuyen,
      "diaChiTamTruPhuongXa": sinhvien.diaChiTamTruPhuongXa,
      "diaChiTamTruDuongThon": sinhvien.diaChiTamTruDuongThon,
      "diaChiTamTruSoNha": sinhvien.diaChiTamTruSoNha,
    };
    body.removeWhere((key, value) => value == null);
    return _apiClient.updateDiaChiTamTru(body);
  }

  // Future<VneidShareInfoResponseModel> shareVneidInfo() async {
  // test
  Future<VneidShareInfoResponseModel> shareVneidInfo({
    String? configName,
  }) async {
    final sinhvien =
        Globals().thongTinSinhVienModel.value ??
        await _apiClient.getSinhVienInfo();

    if (Globals().thongTinSinhVienModel.value == null) {
      Globals().thongTinSinhVienModel.value = sinhvien;
    }

    final guidDonVi = sinhvien.guidDonVi;

    final classInfo = await _firstOrNullWhen(
      sinhvien.idLopDaoTao,
      () => getDataLopDaoTao(
        sinhvien.idLopDaoTao,
        guidDonVi,
        sinhvien.idBacDaoTao,
        sinhvien.idHeDaoTao,
        sinhvien.idNganhDaoTao,
        sinhvien.idNienKhoaDaoTao,
        sinhvien.idChuongTrinhDaoTao,
      ),
    );

    final major = await _firstOrNullWhen(
      sinhvien.idNganhDaoTao,
      () => getDataNganhDaoTao(
        sinhvien.idNganhDaoTao,
        guidDonVi,
        sinhvien.idBacDaoTao,
      ),
    );

    final academicYear = await _firstOrNullWhen(
      sinhvien.idNienKhoaDaoTao,
      () => getDataNienKhoaDaoTao(
        sinhvien.idNienKhoaDaoTao,
        guidDonVi,
        sinhvien.idBacDaoTao,
      ),
    );

    final system = await _firstOrNullWhen(
      sinhvien.idHeDaoTao,
      () =>
          getDataHeDaoTao(sinhvien.idHeDaoTao, guidDonVi, sinhvien.idBacDaoTao),
    );

    final level = await _firstOrNullWhen(
      sinhvien.idBacDaoTao,
      () => getDataBacDaoTao(sinhvien.idBacDaoTao, guidDonVi),
    );

    final priorityObject = await _firstOrNullWhen(
      sinhvien.idDoiTuongUuTien,
      () => getDataDoiTuongUuTien(sinhvien.idDoiTuongUuTien, guidDonVi),
    );

    final country = await _firstOrNullWhen(
      sinhvien.idQuocGia,
      () => getDataQuocGia(sinhvien.idQuocGia, guidDonVi),
    );

    final national = await _firstOrNullWhen(
      sinhvien.idDanToc,
      () => getDataDanToc(sinhvien.idDanToc, guidDonVi),
    );

    final university = guidDonVi == null || guidDonVi.trim().isEmpty
        ? null
        : await _nullable(() => getDonVi(guidDonVi));

    final permanentProvince = await _firstOrNullWhen(
      sinhvien.idHoKhauThuongTruTinhThanhPho,
      () => getDataTinhThanhPho(
        sinhvien.idHoKhauThuongTruTinhThanhPho,
        guidDonVi,
      ),
    );

    final permanentDistrict = await _firstOrNullWhen(
      sinhvien.idHoKhauThuongTruQuanHuyen,
      () => getDataQuanHuyen(
        sinhvien.idHoKhauThuongTruQuanHuyen,
        guidDonVi,
        sinhvien.idHoKhauThuongTruTinhThanhPho,
      ),
    );

    final temporaryProvince = await _firstOrNullWhen(
      sinhvien.diaChiTamTruTinhThanhPho,
      () => getDataTinhThanhPho(sinhvien.diaChiTamTruTinhThanhPho, guidDonVi),
    );

    final temporaryDistrict = await _firstOrNullWhen(
      sinhvien.diaChiTamTruQuanHuyen,
      () => getDataQuanHuyen(
        sinhvien.diaChiTamTruQuanHuyen,
        guidDonVi,
        sinhvien.diaChiTamTruTinhThanhPho,
      ),
    );

    final temporaryAddress =
        _joinAddress([
          sinhvien.diaChiTamTruSoNha,
          sinhvien.diaChiTamTruDuongThon,
          sinhvien.diaChiTamTruPhuongXa,
          temporaryDistrict?.ten ?? sinhvien.diaChiTamTruQuanHuyen,
          temporaryProvince?.ten ?? sinhvien.diaChiTamTruTinhThanhPho,
        ]) ??
        sinhvien.diaChiTamTru;

    final body = <String, dynamic>{
      "studentCode": sinhvien.maSinhVien,
      "fullName": sinhvien.hoVaTen,
      "birthDate": _dateOnly(sinhvien.ngaySinh),
      "gender": sinhvien.gioiTinh,
      "identityType": "CCCD",
      "identityName": "Can cuoc cong dan",
      "identityNo": sinhvien.soCmtCccd,
      "phoneNumber": sinhvien.mobile ?? sinhvien.tel,
      "country": country?.ten ?? "VN",
      "national": national?.ten ?? sinhvien.idDanToc,
      "email": sinhvien.email ?? sinhvien.emailKhac,
      "status": "ACTIVE",

      // Theo curl test của anh: residenceType = 1
      "residenceType": 1,

      "permanentAddress": _joinAddress([
        sinhvien.hoKhauThuongTruSoNha,
        sinhvien.hoKhauThuongTruDuongThon,
        sinhvien.hoKhauThuongTruPhuongXa,
        permanentDistrict?.ten ?? sinhvien.idHoKhauThuongTruQuanHuyen,
        permanentProvince?.ten ?? sinhvien.idHoKhauThuongTruTinhThanhPho,
      ]),

      "temporaryAddress": temporaryAddress,
      "className": classInfo?.ten ?? classInfo?.tenVietTat,
      "major": major?.ten,
      "academicYear":
          academicYear?.ten ??
          _joinAddress([academicYear?.namBatDau, academicYear?.namKetThuc]),
      "system": system?.ten,
      "level": level?.ten,
      "universityName": university?.tenDonVi,
      "priorityObjectName": priorityObject?.ten,
    };

    body.removeWhere((key, value) => value == null || value == '');
    // body['studentCode'] = '9';
    // body['fullName'] = 'Trần Quốc Anh';
    // body['birthDate'] = '2003-11-03';
    // body['gender'] = 'Nam';
    // body['identityNo'] = '036203012339';
    // body['phoneNumber'] = '0979345835';
    // body['email'] = 'anhtq@vnu.edu.vn';
    // body['temporaryAddress'] = 'Xóm 4 Hải Hậu Ninh Bình';
    // body['permanentAddress'] = 'Xóm 4 Hải Hậu Ninh Bình';
    // body['universityName'] = 'Trung tâm Quản trị đại học số';
    // body['residenceType'] = 1;
    final normalizedConfigName = configName?.trim();

    if (normalizedConfigName != null && normalizedConfigName.isNotEmpty) {
      try {
        final String cccdConfigBaseUrl =
            await _getRequiredCccdConfigBaseUrl();
        final configResponse = await Dio().get<Map<String, dynamic>>(
          '${cccdConfigBaseUrl}configs/'
          '${Uri.encodeComponent(normalizedConfigName)}',
          options: Options(headers: {'Accept': 'application/json'}),
        );

        final rawConfigData = configResponse.data?['data'];

        if (rawConfigData is Map) {
          final configData = Map<String, dynamic>.from(rawConfigData);

          configData.removeWhere(
            (key, value) => value == null || value.toString().trim().isEmpty,
          );

          body.addAll(configData);

          logInfo('VNeID test config applied: $normalizedConfigName');
        }
      } catch (e) {
        logError('Load VNeID test config error: $e');
        rethrow;
      }
    }
    final String vneidBaseUrl = await _getRequiredVneidBaseUrl();

    final token = Globals().token;
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    logInfo('shareVneidInfo request headers: $headers');

    final response = await Dio().post<Map<String, dynamic>>(
      '${vneidBaseUrl}api/vneid/share-info',
      data: body,
      options: Options(contentType: Headers.jsonContentType, headers: headers),
    );

    return VneidShareInfoResponseModel.fromJson(
      response.data ?? <String, dynamic>{},
    );
  }

  Future<VneidShareInfoStatusModel> getVneidShareInfoStatus(
    String transactionCode,
  ) async {
    final encodedTransactionCode = Uri.encodeComponent(transactionCode);
    final String vneidBaseUrl = await _getRequiredVneidBaseUrl();

    final token = Globals().token;
    final headers = <String, dynamic>{'Accept': 'application/json'};
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    final response = await Dio().get<Map<String, dynamic>>(
      '${vneidBaseUrl}api/vneid/share-info/status/$encodedTransactionCode',
      options: Options(headers: headers),
    );

    final data = response.data ?? <String, dynamic>{};

    logInfo('VNeID share-info/status response: $data');

    return VneidShareInfoStatusModel.fromJson(data);
  }

  Future<String> _getRequiredCccdConfigBaseUrl() async {
    await AppConfigService().ensureLoaded();

    final String baseUrl = ServicesUrl().effectiveCccdConfigApiUrl;
    if (baseUrl.isEmpty) {
      throw StateError(
        'CCCD config API URL is unavailable. Add cccdConfigApiUrl to '
        '/api/config on ${ServicesUrl.defaultBaseUrl}.',
      );
    }

    logInfo('Using CCCD config API from config: $baseUrl');
    return baseUrl;
  }

  Future<String> _getRequiredVneidBaseUrl() async {
    await AppConfigService().ensureLoaded();

    final String baseUrl = ServicesUrl().effectiveVneidApiUrl;
    if (baseUrl.isEmpty) {
      throw StateError(
        'VNeID API URL is unavailable. Check /api/config on '
        '${ServicesUrl.defaultBaseUrl}.',
      );
    }

    logInfo('Using VNeID API from config: $baseUrl');
    return baseUrl;
  }

  Future<T?> _firstOrNull<T>(Future<List<T>> future) async {
    try {
      final data = await future;
      return data.isEmpty ? null : data.first;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<T?> _firstOrNullWhen<T>(
    String? key,
    Future<List<T>> Function() futureBuilder,
  ) {
    if (key == null || key.trim().isEmpty) {
      return Future.value(null);
    }
    return _firstOrNull(futureBuilder());
  }

  Future<T?> _nullable<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  String? _dateOnly(DateTime? value) {
    if (value == null) {
      return null;
    }
    return value.toIso8601String().split('T').first;
  }

  String? _joinAddress(List<Object?> parts) {
    final text = parts
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .join(', ');
    return text.isEmpty ? null : text;
  }

  Future<List<QuocGiaModel>> getDataQuocGia(String? id, String? guidDonVi) {
    return _apiClient.getDataQuocGia(id, guidDonVi);
  }

  Future<List<DanTocModel>> getDataDanToc(String? id, String? guidDonVi) {
    return _apiClient.getDataDanToc(id, guidDonVi);
  }

  Future<List<DoiTuongUuTienModel>> getDataDoiTuongUuTien(
    String? id,
    String? guidDonVi,
  ) {
    return _apiClient.getDataDoiTuongUuTien(id, guidDonVi);
  }

  Future<List<TonGiaoModel>> getDataTonGiao(String? id, String? guidDonVi) {
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

  Future<List<BacDaoTaoModel>> getDataBacDaoTao(String? id, String? guidDonVi) {
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
    return _apiClient.getDataChuongTrinhDaoTao(
      id,
      guidDonVi,
      idBacDaoTao,
      idHeDaoTao,
      idNganhDaoTao,
      idNienKhoaDaoTao,
    );
  }

  // - End update thong tin

  //Ảnh cá nhân
  Future<List<AnhCaNhanModel>> getAllAnhCanNhan() {
    return _apiClient.getAllAnhCanNhan();
  }

  Future<AnhCaNhanModel> uploadAnhCanNhan(
    File fileUpload, {
    ProgressCallback? onSendProgress,
  }) {
    return _apiClient.uploadAnhCanNhan(
      fileUpload,
      onSendProgress: onSendProgress,
    );
  }

  Future<void> deleteAnhCanNhan(String guid) {
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
      keyLoaiMatKhau,
      oldPassword,
      newPassword,
    );
  }

  Future<List<TopTinTucModel>> getTop10TinTuc(
    int? width,
    int? height, [
    int? limit,
  ]) {
    return _apiClient.getTop10TinTuc(width, height, limit);
  }

  Future<TopTinTucDetailModel> getChiTietCmsTinTuc(
    String idTinTuc,
    int width,
    int height,
  ) {
    return _apiClient.getChiTietCmsTinTuc(idTinTuc, width);
  }

  Future<List<TopThongBaoModel>> getTop10ThongBao() {
    return _apiClient.getTop10ThongBao();
  }

  Future<TopTinTucDetailModel> getChiTietThongBao(String idThongBao) {
    return _apiClient.getChiTietThongBao(idThongBao);
  }

  Future<Map<String, dynamic>> getConfig() async {
    // Always request config through the fixed ONEVNU mobile API and bypass any
    // intermediary HTTP cache that could return obsolete endpoint values.
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/config',
      queryParameters: <String, dynamic>{
        '_ts': DateTime.now().millisecondsSinceEpoch,
      },
      options: Options(
        headers: const <String, dynamic>{
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      ),
    );

    final dynamic raw = response.data;
    final Map<String, dynamic> rMap;

    if (raw is Map) {
      rMap = Map<String, dynamic>.from(raw);
    } else if (raw is String && raw.trim().isNotEmpty) {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('/api/config must return a JSON object');
      }
      rMap = Map<String, dynamic>.from(decoded);
    } else {
      throw const FormatException('/api/config returned an empty response');
    }

    return <String, dynamic>{
      'domainDownload': rMap['domainDownload'],
      'ktxApiUrl': rMap['ktxApiUrl'],
      'vneidApiUrl': rMap['vneidApiUrl'],
      'cccdConfigApiUrl': rMap['cccdConfigApiUrl'],
      'zaloGroupUrl': rMap['zaloGroupUrl'],
    };
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

  Future<PhanAnhHienTruongModel> getPaht(String guid) {
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
      guidChuDe,
      guidKhuVuc,
      pageIndex,
      pageSize,
      sort,
    );
  }

  Future<ApiResponse<List<PhanAnhHienTruongModel>>> getPahtCaNhan(
    String guidChuDe,
    String trangThaiXuLy,
    int pageIndex,
    int pageSize,
    String sort,
  ) {
    return _apiClient.getPahtCaNhan(
      guidChuDe,
      trangThaiXuLy,
      pageIndex,
      pageSize,
      sort,
    );
  }

  Future<void> deletePaht(String guid) {
    return _apiClient.deletePaht(guid);
  }

  // -- File
  Future<FileDinhKemModel> uploadFile(
    File fileUpload, {
    ProgressCallback? onSendProgress,
  }) {
    return _apiClient.uploadFile(fileUpload, onSendProgress: onSendProgress);
  }

  // --- ---

  // ========== APPLICANT ==========
  Future<ApplicantSigninResponse> applicantLogin({
    required String cccd,
    required String phoneNumber,
    String? deviceToken,
    String? deviceInfo,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/applicant/auth/login',
      data: {
        'cccd': cccd,
        'phoneNumber': phoneNumber,
        if ((deviceToken ?? '').isNotEmpty) 'deviceToken': deviceToken,
        if ((deviceInfo ?? '').isNotEmpty) 'deviceInfo': deviceInfo,
      },
      options: Options(
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    return ApplicantSigninResponse.fromJson(
      response.data ?? <String, dynamic>{},
    );
  }

  Future<ApplicantSigninResponse> applicantRefreshToken(
    String refreshToken,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/applicant/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    return ApplicantSigninResponse.fromJson(
      response.data ?? <String, dynamic>{},
    );
  }

  Future<void> applicantSignout() async {
    final String traceId = const Uuid().v4();
    final Stopwatch stopwatch = Stopwatch()..start();
    dlog(
      '[P0_DIAG][APPLICANT_LOGOUT_FLUTTER][REQUEST] rid=$traceId '
      'endpoint=/api/applicant/auth/signout tokenPresent=${Globals().token.isNotEmpty}',
      wrapWidth: 1000,
    );
    try {
      final Response<void> response = await _dio.post<void>(
        '/api/applicant/auth/signout',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'X-Request-Id': traceId,
            if (Globals().token.isNotEmpty)
              'Authorization': 'Bearer ${Globals().token}',
          },
        ),
      );
      dlog(
        '[P0_DIAG][APPLICANT_LOGOUT_FLUTTER][RESPONSE] '
        'rid=${response.headers.value('X-Request-Id')?.trim() ?? traceId} '
        'status=${response.statusCode} elapsedMs=${stopwatch.elapsedMilliseconds}',
        wrapWidth: 1000,
      );
    } on DioException catch (error, stackTrace) {
      dlog(
        '[P0_DIAG][APPLICANT_LOGOUT_FLUTTER][ERROR] '
        'rid=${_diagRequestId(error.response, traceId)} '
        'status=${error.response?.statusCode} dioType=${error.type} '
        'elapsedMs=${stopwatch.elapsedMilliseconds} '
        'body=${_diagSafeBody(error.response?.data)}',
        wrapWidth: 1000,
      );
      _diagStack('[P0_DIAG][APPLICANT_LOGOUT_FLUTTER][STACK]', stackTrace);
      rethrow;
    }
  }

  String _diagRequestId(Response<dynamic>? response, String fallback) {
    if (response == null) return fallback;
    final dynamic data = response.data;
    if (data is Map) {
      final String value =
          (data['requestId'] ?? data['request_id'])?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    final String header = response.headers.value('X-Request-Id')?.trim() ?? '';
    return header.isEmpty ? fallback : header;
  }

  String _diagSafeBody(dynamic data) {
    if (data == null) return 'null';
    String raw;
    try {
      raw = data is String ? data : jsonEncode(data);
    } catch (_) {
      raw = data.toString();
    }
    final String safe = sanitizeLogMessage(raw).replaceAll(RegExp(r'\s+'), ' ');
    return safe.length <= 600 ? safe : '${safe.substring(0, 600)}...[truncated]';
  }

  void _diagStack(String tag, StackTrace stackTrace) {
    final String compact = stackTrace
        .toString()
        .split('\n')
        .where((String line) => line.trim().isNotEmpty)
        .take(8)
        .join(' | ');
    dlog('$tag $compact', wrapWidth: 1000);
  }

  void dispose() {
    _dio.close(force: true);
  }
}
