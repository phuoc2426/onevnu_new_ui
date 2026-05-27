import '../common/hoc_bong_field_labels.dart';

class HocBongModel {
  final int id;
  final String? maHocBong;
  final String? tenHocBong;
  final String? tenLoaiHocBong;
  final String? doiTuongApDungText;
  final String? namHoc;
  final String? hocKy;
  final String? moTaNgan;
  final String? noiDung;
  final DateTime? ngayBatDauDangKy;
  final DateTime? ngayKetThucDangKy;
  final int? soSuat;
  final int? giaTri;
  final String? trangThai;
  final String? trangThaiText;
  final String? trangThaiHoSo;
  final String? ketQuaValidate;

  const HocBongModel({
    required this.id,
    this.maHocBong,
    this.tenHocBong,
    this.tenLoaiHocBong,
    this.doiTuongApDungText,
    this.namHoc,
    this.hocKy,
    this.moTaNgan,
    this.noiDung,
    this.ngayBatDauDangKy,
    this.ngayKetThucDangKy,
    this.soSuat,
    this.giaTri,
    this.trangThai,
    this.trangThaiText,
    this.trangThaiHoSo,
    this.ketQuaValidate,
  });

  factory HocBongModel.fromJson(Map<String, dynamic> json) {
    final loai = json['loaiHocBong'];
    return HocBongModel(
      id: _asInt(json['id']),
      maHocBong: _asString(json['maHocBong'] ?? json['ma_hoc_bong']),
      tenHocBong: _asString(json['tenHocBong'] ?? json['ten_hoc_bong']),
      tenLoaiHocBong: _asString(json['tenLoaiHocBong'] ?? (loai is Map ? loai['tenLoai'] : null)),
      doiTuongApDungText: _asString(json['doiTuongApDungText']),
      namHoc: _asString(json['namHoc'] ?? json['nam_hoc']),
      hocKy: _asString(json['hocKy'] ?? json['hoc_ky']),
      moTaNgan: _asString(json['moTaNgan'] ?? json['mo_ta_ngan']),
      noiDung: _asString(json['noiDung'] ?? json['noi_dung']),
      ngayBatDauDangKy: _asDate(json['ngayBatDauDangKy'] ?? json['ngay_bat_dau_dang_ky']),
      ngayKetThucDangKy: _asDate(json['ngayKetThucDangKy'] ?? json['ngay_ket_thuc_dang_ky']),
      soSuat: _asNullableInt(json['soSuat'] ?? json['so_suat']),
      giaTri: _asNullableInt(json['giaTri'] ?? json['gia_tri']),
      trangThai: _asString(json['trangThaiHocBong'] ?? json['trangThai'] ?? json['trang_thai']),
      trangThaiText: _asString(json['trangThaiText']),
      trangThaiHoSo: _asString(json['trangThaiDangKy'] ?? json['trangThaiHoSo']),
      ketQuaValidate: _asString(json['ketQuaValidate']),
    );
  }
}

class HocBongDetailModel {
  final HocBongModel hocBong;
  final List<HocBongFormFieldModel> formFields;
  final List<HocBongFileModel> files;
  final HocBongHoSoModel? hoSo;

  const HocBongDetailModel({
    required this.hocBong,
    this.formFields = const [],
    this.files = const [],
    this.hoSo,
  });

  factory HocBongDetailModel.fromJson(Map<String, dynamic> json) {
    final hbJson = (json['hocBong'] is Map<String, dynamic>) ? json['hocBong'] as Map<String, dynamic> : json;
    return HocBongDetailModel(
      hocBong: HocBongModel.fromJson(hbJson),
      formFields: _parseFormFields(json),
      files: _asList(json['files'] ?? json['danhSachFile'] ?? json['danh_sach_file'])
          .map((e) => HocBongFileModel.fromJson(_asMap(e)))
          .toList(),
      hoSo: json['hoSo'] == null ? null : HocBongHoSoModel.fromJson(_asMap(json['hoSo'])),
    );
  }

  static List<HocBongFormFieldModel> _parseFormFields(Map<String, dynamic> json) {
    final raw = json['formFields'] ??
        json['form_fields'] ??
        json['form'] ??
        json['truongThongTin'] ??
        json['truong_thong_tin'];
    final fields = _asList(raw).map((e) => HocBongFormFieldModel.fromJson(_asMap(e))).where((f) => f.isActive).toList();
    fields.sort((a, b) => a.thuTu.compareTo(b.thuTu));
    return fields;
  }
}

class HocBongLoaiModel {
  final int id;
  final String? maLoai;
  final String? tenLoai;
  final String? moTa;

  const HocBongLoaiModel({
    required this.id,
    this.maLoai,
    this.tenLoai,
    this.moTa,
  });

  factory HocBongLoaiModel.fromJson(Map<String, dynamic> json) {
    return HocBongLoaiModel(
      id: _asInt(json['id']),
      maLoai: _asString(json['maLoai'] ?? json['ma_loai']),
      tenLoai: _asString(json['tenLoai'] ?? json['ten_loai']),
      moTa: _asString(json['moTa'] ?? json['mo_ta']),
    );
  }
}

class HocBongFormFieldModel {
  final int id;
  final String maTruong;
  final String tenTruong;
  final String kieuDuLieu;
  final bool batBuoc;
  final bool yeuCauCongChung;
  final bool canXacMinh;
  final String? goiY;
  final Map<String, dynamic> cauHinh;
  final int thuTu;
  final String? trangThai;

  const HocBongFormFieldModel({
    required this.id,
    required this.maTruong,
    required this.tenTruong,
    required this.kieuDuLieu,
    required this.batBuoc,
    required this.yeuCauCongChung,
    required this.canXacMinh,
    this.goiY,
    this.cauHinh = const {},
    this.thuTu = 0,
    this.trangThai,
  });

  factory HocBongFormFieldModel.fromJson(Map<String, dynamic> json) {
    return HocBongFormFieldModel(
      id: _asInt(json['id']),
      maTruong: _asString(json['maTruong'] ?? json['ma_truong']) ?? '',
      tenTruong: _asString(json['tenTruong'] ?? json['ten_truong']) ?? '',
      kieuDuLieu: (_asString(json['kieuDuLieu'] ?? json['kieu_du_lieu']) ?? 'TEXT').toUpperCase(),
      batBuoc: _asBool(json['batBuoc'] ?? json['bat_buoc']),
      yeuCauCongChung: _asBool(json['yeuCauCongChung'] ?? json['yeu_cau_cong_chung']),
      canXacMinh: _asBool(json['canXacMinh'] ?? json['can_xac_minh']),
      goiY: _asString(json['goiY'] ?? json['goi_y']),
      cauHinh: _asMap(json['cauHinh'] ?? json['cau_hinh']),
      thuTu: _asInt(json['thuTu'] ?? json['thu_tu']),
      trangThai: _asString(json['trangThai'] ?? json['trangthai'] ?? json['trang_thai']),
    );
  }

  bool get isActive {
    final t = trangThai?.toLowerCase();
    return t == null || t == 'hoatdong' || t == 'active';
  }

  /// DB/API thường để `tenTruong` null — dùng map tiếng Việt hoặc `maTruong`.
  String get displayLabel {
    final name = tenTruong.trim();
    if (name.isNotEmpty && name.toLowerCase() != 'null') return name;
    return hocBongLabelFromMaTruong(maTruong);
  }

  List<String> get options {
    final raw = cauHinh['options'] ?? cauHinh['luaChon'] ?? cauHinh['lua_chon'] ?? cauHinh['items'];
    if (raw is List) return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    if (raw is Map) return raw.values.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    return const [];
  }
}

class HocBongValidateResultModel {
  final bool passed;
  final String? result;
  final String? message;
  final double? gpaHe4TuTinh;
  final int? tongTinChiTinhGpa;
  final List<String> checks;
  final List<String> warnings;

  const HocBongValidateResultModel({
    this.passed = false,
    this.result,
    this.message,
    this.gpaHe4TuTinh,
    this.tongTinChiTinhGpa,
    this.checks = const [],
    this.warnings = const [],
  });

  factory HocBongValidateResultModel.fromJson(Map<String, dynamic> json) {
    return HocBongValidateResultModel(
      passed: _asBool(json['passed']),
      result: _asString(json['result'] ?? json['ketQuaValidate']),
      message: _asString(json['message']),
      gpaHe4TuTinh: _asNullableDouble(json['gpaHe4TuTinh'] ?? json['gpa_tu_tinh']),
      tongTinChiTinhGpa: _asNullableInt(json['tongTinChiTinhGpa'] ?? json['tong_tin_chi_tinh_gpa']),
      checks: _asList(json['checks']).map((e) => e.toString()).toList(),
      warnings: _asList(json['warnings'] ?? json['canhBao']).map((e) => e.toString()).toList(),
    );
  }
}

class HocBongHoSoModel {
  final int id;
  final int? hocBongId;
  final String? tenHocBong;
  final String? maSinhVien;
  final String? hoTen;
  final String? tenDonVi;
  final String? trangThai;
  final String? trangThaiText;
  final String? ketQuaValidate;
  final String? phanHoiAdmin;
  final String? lyDoTuChoi;
  final DateTime? ngayLuuNhap;
  final DateTime? ngayGui;
  final DateTime? ngayDuyet;
  final Map<String, dynamic> duLieuDangKy;
  final List<HocBongFileModel> files;
  final List<HocBongHistoryModel> history;

  const HocBongHoSoModel({
    required this.id,
    this.hocBongId,
    this.tenHocBong,
    this.maSinhVien,
    this.hoTen,
    this.tenDonVi,
    this.trangThai,
    this.trangThaiText,
    this.ketQuaValidate,
    this.phanHoiAdmin,
    this.lyDoTuChoi,
    this.ngayLuuNhap,
    this.ngayGui,
    this.ngayDuyet,
    this.duLieuDangKy = const {},
    this.files = const [],
    this.history = const [],
  });

  factory HocBongHoSoModel.fromJson(Map<String, dynamic> json) {
    final hb = json['hocBong'];
    return HocBongHoSoModel(
      id: _asInt(json['id']),
      hocBongId: _asNullableInt(json['hocBongId'] ?? json['idHocBong'] ?? json['id_hoc_bong'] ?? (hb is Map ? hb['id'] : null)),
      tenHocBong: _asString(json['tenHocBong'] ?? (hb is Map ? hb['tenHocBong'] : null)),
      maSinhVien: _asString(json['maSinhVien'] ?? json['maSinhVienSnapshot'] ?? json['ma_sinh_vien_snapshot']),
      hoTen: _asString(json['hoTen'] ?? json['hoTenSnapshot'] ?? json['ho_ten_snapshot']),
      tenDonVi: _asString(json['tenDonVi'] ?? json['donViSnapshot'] ?? json['don_vi_snapshot']),
      trangThai: _asString(json['trangThaiHoSo'] ?? json['trangThai'] ?? json['trang_thai']),
      trangThaiText: _asString(json['trangThaiText']),
      ketQuaValidate: _asString(json['ketQuaValidate'] ?? json['ket_qua_validate']),
      phanHoiAdmin: _asString(json['phanHoiAdmin'] ?? json['phan_hoi_admin'] ?? json['phanHoi']),
      lyDoTuChoi: _asString(json['lyDoTuChoi'] ?? json['ly_do_tu_choi']),
      ngayLuuNhap: _asDate(json['ngayLuuNhap'] ?? json['ngay_luu_nhap']),
      ngayGui: _asDate(json['ngayGui'] ?? json['ngay_gui']),
      ngayDuyet: _asDate(json['ngayDuyet'] ?? json['ngay_duyet']),
      duLieuDangKy: _asMap(json['duLieuDangKy'] ?? json['du_lieu_dang_ky']),
      files: _asList(json['files'] ?? json['danhSachFile'] ?? json['minhChung'])
          .map((e) => HocBongFileModel.fromJson(_asMap(e)))
          .toList(),
      history: _asList(json['history'] ?? json['lichSu'])
          .map((e) => HocBongHistoryModel.fromJson(_asMap(e)))
          .toList(),
    );
  }

  bool get canEdit => trangThai == 'DRAFT' || trangThai == 'NEED_MORE_INFO';
}

class HocBongFileModel {
  final int id;
  final int? fileId;
  final int? formFieldId;
  final String? tenMinhChung;
  final String? tenFileHienThi;
  final String? loaiMinhChung;
  final String? trangThaiKiemTra;
  final String? ghiChuKiemTra;

  const HocBongFileModel({
    required this.id,
    this.fileId,
    this.formFieldId,
    this.tenMinhChung,
    this.tenFileHienThi,
    this.loaiMinhChung,
    this.trangThaiKiemTra,
    this.ghiChuKiemTra,
  });

  factory HocBongFileModel.fromJson(Map<String, dynamic> json) {
    final file = json['file'];
    return HocBongFileModel(
      id: _asInt(json['id']),
      fileId: _asNullableInt(json['fileId'] ?? json['idFile'] ?? json['id_file'] ?? (file is Map ? file['id'] : null)),
      formFieldId: _asNullableInt(json['formFieldId'] ?? json['idFormField'] ?? json['id_form_field']),
      tenMinhChung: _asString(json['tenMinhChung'] ?? json['ten_minh_chung']),
      tenFileHienThi: _asString(json['tenFileHienThi'] ?? json['ten_file_hien_thi'] ?? json['tenFile'] ?? json['fileName'] ?? json['ghiChu'] ?? (file is Map ? file['name'] : null)),
      loaiMinhChung: _asString(json['loaiMinhChung'] ?? json['loai_minh_chung'] ?? json['loaiFile'] ?? json['loai_file']),
      trangThaiKiemTra: _asString(json['trangThaiKiemTra'] ?? json['trang_thai_kiem_tra']),
      ghiChuKiemTra: _asString(json['ghiChuKiemTra'] ?? json['ghi_chu_kiem_tra']),
    );
  }
}

class HocBongHistoryModel {
  final int id;
  final String? trangThaiCu;
  final String? trangThaiMoi;
  final String? hanhDong;
  final String? noiDung;
  final DateTime? created;

  const HocBongHistoryModel({required this.id, this.trangThaiCu, this.trangThaiMoi, this.hanhDong, this.noiDung, this.created});

  factory HocBongHistoryModel.fromJson(Map<String, dynamic> json) {
    return HocBongHistoryModel(
      id: _asInt(json['id']),
      trangThaiCu: _asString(json['trangThaiCu'] ?? json['trang_thai_cu']),
      trangThaiMoi: _asString(json['trangThaiMoi'] ?? json['trang_thai_moi']),
      hanhDong: _asString(json['hanhDong'] ?? json['hanh_dong']),
      noiDung: _asString(json['noiDung'] ?? json['noi_dung']),
      created: _asDate(json['created']),
    );
  }
}

int _asInt(dynamic v) => _asNullableInt(v) ?? 0;
int? _asNullableInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? _asNullableDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

bool _asBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  return v.toString().toLowerCase() == 'true';
}

String? _asString(dynamic v) => v == null ? null : v.toString();
DateTime? _asDate(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
List<dynamic> _asList(dynamic v) => v is List ? v : const [];
Map<String, dynamic> _asMap(dynamic v) => v is Map ? v.map((key, value) => MapEntry(key.toString(), value)) : <String, dynamic>{};
