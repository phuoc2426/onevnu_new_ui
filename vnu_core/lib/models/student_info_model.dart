// To parse this JSON data, do
//
//     final studentInfoModel = studentInfoModelFromJson(jsonString);

import 'dart:convert';

StudentInfoModel studentInfoModelFromJson(String str) =>
    StudentInfoModel.fromJson(json.decode(str));

String studentInfoModelToJson(StudentInfoModel data) =>
    json.encode(data.toJson());

class StudentInfoModel {
  String? maSinhVien;
  String? hoVaTen;
  String? gioiTinh;
  String? soCmtCccd;
  String? idNoiCapCmtCccdTinhThanhPho;
  DateTime? ngayCapCmtCccd;
  String? soBaoDanh;
  String? maHoSo;
  DateTime? ngaySinh;
  String? guidDonVi;
  String? idNganhDaoTao;
  String? idChuongTrinhDaoTao;
  String? idNienKhoaDaoTao;
  String? idBacDaoTao;
  String? idHeDaoTao;
  String? idKhuVucUuTien;
  String? idLopDaoTao;
  String? idDanToc;
  String? idQuocGia;
  String? idDoiTuongUuTien;
  String? nangKhieu;
  String? tenKhac;
  String? nhomMau;
  double? chieuCao;
  double? canNang;
  String? tel;
  String? mobile;
  String? email;
  String? emailKhac;
  String? idTonGiao;
  String? idTinhThanhPho;
  String? idQuanHuyen;
  bool? isDoan;
  bool? isBoDoi;
  bool? isDang;
  DateTime? ngayVaoDoan;
  String? noiVaoDoan;
  String? viTriCaoNhatDoan;
  DateTime? ngayVaoDang;
  DateTime? ngayVaoDangChinhThuc;
  String? noiVaoDang;
  String? viTriCaoNhatDang;
  String? bienChe;
  DateTime? nhapNgu;
  DateTime? xuatNgu;
  String? idQueQuanQuocGia;
  String? idQueQuanTinhThanhPho;
  String? idQueQuanQuanHuyen;
  String? queQuanPhuongXa;
  String? idNoiSinhQuocGia;
  String? idNoiSinhTinhThanhPho;
  String? idNoiSinhQuanHuyen;
  String? noiSinhPhuongXa;
  String? idHoKhauThuongTruTinhThanhPho;
  String? idHoKhauThuongTruQuanHuyen;
  String? hoKhauThuongTruPhuongXa;
  String? hoKhauThuongTruDuongThon;
  String? hoKhauThuongTruSoNha;
  String? idNoiOHienNayQuocGia;
  String? idNoiOHienNayTinhThanhPho;
  String? idNoiOHienNayQuanHuyen;
  String? noiOHienNayPhuongXa;
  String? noiOHienNayDuongThon;
  String? noiOHienNaySoNha;
  String? idDiaChiLienLacQuocGia;
  String? idDiaChiLienLacTinhThanhPho;
  String? idDiaChiLienLacQuanHuyen;
  String? diaChiLienLacPhuongXa;
  String? diaChiLienLacDuongThon;
  String? diaChiLienLacSoNha;
  String? hoVaTenCha;
  String? ngaySinhCha;
  String? ngheNghiepCha;
  String? diaChiCha;
  String? nguyenQuanCha;
  String? diaChiCoQuanCha;
  String? lyLichCha;
  String? dienThoaiCha;
  String? emailCha;
  String? hoVaTenMe;
  String? ngaySinhMe;
  String? ngheNghiepMe;
  String? diaChiMe;
  String? nguyenQuanMe;
  String? diaChiCoQuanMe;
  String? lyLichMe;
  String? dienThoaiMe;
  String? emailMe;
  String? anhEm;
  DateTime? ngaySinhAnhEm;
  String? ngheNghiepAnhEm;
  String? conCai;
  String? hoVaTenVoChong;
  DateTime? ngaySinhVoChong;
  String? ngheNghiepVoChong;
  String? diaChiVoChong;
  String? thanhPhanGiaDinh;

  StudentInfoModel({
    this.maSinhVien,
    this.hoVaTen,
    this.gioiTinh,
    this.soCmtCccd,
    this.idNoiCapCmtCccdTinhThanhPho,
    this.ngayCapCmtCccd,
    this.soBaoDanh,
    this.maHoSo,
    this.ngaySinh,
    this.guidDonVi,
    this.idNganhDaoTao,
    this.idChuongTrinhDaoTao,
    this.idNienKhoaDaoTao,
    this.idBacDaoTao,
    this.idHeDaoTao,
    this.idKhuVucUuTien,
    this.idLopDaoTao,
    this.idDanToc,
    this.idQuocGia,
    this.idDoiTuongUuTien,
    this.nangKhieu,
    this.tenKhac,
    this.nhomMau,
    this.chieuCao,
    this.canNang,
    this.tel,
    this.mobile,
    this.email,
    this.emailKhac,
    this.idTonGiao,
    this.idTinhThanhPho,
    this.idQuanHuyen,
    this.isDoan,
    this.isBoDoi,
    this.isDang,
    this.ngayVaoDoan,
    this.noiVaoDoan,
    this.viTriCaoNhatDoan,
    this.ngayVaoDang,
    this.ngayVaoDangChinhThuc,
    this.noiVaoDang,
    this.viTriCaoNhatDang,
    this.bienChe,
    this.nhapNgu,
    this.xuatNgu,
    this.idQueQuanQuocGia,
    this.idQueQuanTinhThanhPho,
    this.idQueQuanQuanHuyen,
    this.queQuanPhuongXa,
    this.idNoiSinhQuocGia,
    this.idNoiSinhTinhThanhPho,
    this.idNoiSinhQuanHuyen,
    this.noiSinhPhuongXa,
    this.idHoKhauThuongTruTinhThanhPho,
    this.idHoKhauThuongTruQuanHuyen,
    this.hoKhauThuongTruPhuongXa,
    this.hoKhauThuongTruDuongThon,
    this.hoKhauThuongTruSoNha,
    this.idNoiOHienNayQuocGia,
    this.idNoiOHienNayTinhThanhPho,
    this.idNoiOHienNayQuanHuyen,
    this.noiOHienNayPhuongXa,
    this.noiOHienNayDuongThon,
    this.noiOHienNaySoNha,
    this.idDiaChiLienLacQuocGia,
    this.idDiaChiLienLacTinhThanhPho,
    this.idDiaChiLienLacQuanHuyen,
    this.diaChiLienLacPhuongXa,
    this.diaChiLienLacDuongThon,
    this.diaChiLienLacSoNha,
    this.hoVaTenCha,
    this.ngaySinhCha,
    this.ngheNghiepCha,
    this.diaChiCha,
    this.nguyenQuanCha,
    this.diaChiCoQuanCha,
    this.lyLichCha,
    this.dienThoaiCha,
    this.emailCha,
    this.hoVaTenMe,
    this.ngaySinhMe,
    this.ngheNghiepMe,
    this.diaChiMe,
    this.nguyenQuanMe,
    this.diaChiCoQuanMe,
    this.lyLichMe,
    this.dienThoaiMe,
    this.emailMe,
    this.anhEm,
    this.ngaySinhAnhEm,
    this.ngheNghiepAnhEm,
    this.conCai,
    this.hoVaTenVoChong,
    this.ngaySinhVoChong,
    this.ngheNghiepVoChong,
    this.diaChiVoChong,
    this.thanhPhanGiaDinh,
  });

  StudentInfoModel copyWith({
    String? maSinhVien,
    String? hoVaTen,
    String? gioiTinh,
    String? soCmtCccd,
    String? idNoiCapCmtCccdTinhThanhPho,
    DateTime? ngayCapCmtCccd,
    dynamic soBaoDanh,
    String? maHoSo,
    DateTime? ngaySinh,
    String? guidDonVi,
    String? idNganhDaoTao,
    String? idChuongTrinhDaoTao,
    String? idNienKhoaDaoTao,
    String? idBacDaoTao,
    String? idHeDaoTao,
    String? idKhuVucUuTien,
    String? idLopDaoTao,
    String? idDanToc,
    String? idQuocGia,
    String? idDoiTuongUuTien,
    String? nangKhieu,
    String? tenKhac,
    String? nhomMau,
    double? chieuCao,
    double? canNang,
    String? tel,
    String? mobile,
    String? email,
    String? emailKhac,
    String? idTonGiao,
    String? idTinhThanhPho,
    String? idQuanHuyen,
    bool? isDoan,
    bool? isBoDoi,
    bool? isDang,
    DateTime? ngayVaoDoan,
    String? noiVaoDoan,
    String? viTriCaoNhatDoan,
    DateTime? ngayVaoDang,
    DateTime? ngayVaoDangChinhThuc,
    String? noiVaoDang,
    String? viTriCaoNhatDang,
    String? bienChe,
    DateTime? nhapNgu,
    DateTime? xuatNgu,
    String? idQueQuanQuocGia,
    String? idQueQuanTinhThanhPho,
    String? idQueQuanQuanHuyen,
    String? queQuanPhuongXa,
    String? idNoiSinhQuocGia,
    String? idNoiSinhTinhThanhPho,
    String? idNoiSinhQuanHuyen,
    String? noiSinhPhuongXa,
    String? idHoKhauThuongTruTinhThanhPho,
    String? idHoKhauThuongTruQuanHuyen,
    String? hoKhauThuongTruPhuongXa,
    String? hoKhauThuongTruDuongThon,
    String? hoKhauThuongTruSoNha,
    String? idNoiOHienNayQuocGia,
    String? idNoiOHienNayTinhThanhPho,
    String? idNoiOHienNayQuanHuyen,
    String? noiOHienNayPhuongXa,
    String? noiOHienNayDuongThon,
    String? noiOHienNaySoNha,
    String? idDiaChiLienLacQuocGia,
    String? idDiaChiLienLacTinhThanhPho,
    String? idDiaChiLienLacQuanHuyen,
    String? diaChiLienLacPhuongXa,
    String? diaChiLienLacDuongThon,
    String? diaChiLienLacSoNha,
    String? hoVaTenCha,
    String? ngaySinhCha,
    String? ngheNghiepCha,
    String? diaChiCha,
    String? nguyenQuanCha,
    String? diaChiCoQuanCha,
    String? lyLichCha,
    String? dienThoaiCha,
    String? emailCha,
    String? hoVaTenMe,
    String? ngaySinhMe,
    String? ngheNghiepMe,
    String? diaChiMe,
    String? nguyenQuanMe,
    String? diaChiCoQuanMe,
    String? lyLichMe,
    String? dienThoaiMe,
    String? emailMe,
    String? anhEm,
    DateTime? ngaySinhAnhEm,
    String? ngheNghiepAnhEm,
    String? conCai,
    String? hoVaTenVoChong,
    DateTime? ngaySinhVoChong,
    String? ngheNghiepVoChong,
    String? diaChiVoChong,
    String? thanhPhanGiaDinh,
  }) =>
      StudentInfoModel(
        maSinhVien: maSinhVien ?? this.maSinhVien,
        hoVaTen: hoVaTen ?? this.hoVaTen,
        gioiTinh: gioiTinh ?? this.gioiTinh,
        soCmtCccd: soCmtCccd ?? this.soCmtCccd,
        idNoiCapCmtCccdTinhThanhPho:
            idNoiCapCmtCccdTinhThanhPho ?? this.idNoiCapCmtCccdTinhThanhPho,
        ngayCapCmtCccd: ngayCapCmtCccd ?? this.ngayCapCmtCccd,
        soBaoDanh: soBaoDanh ?? this.soBaoDanh,
        maHoSo: maHoSo ?? this.maHoSo,
        ngaySinh: ngaySinh ?? this.ngaySinh,
        guidDonVi: guidDonVi ?? this.guidDonVi,
        idNganhDaoTao: idNganhDaoTao ?? this.idNganhDaoTao,
        idChuongTrinhDaoTao: idChuongTrinhDaoTao ?? this.idChuongTrinhDaoTao,
        idNienKhoaDaoTao: idNienKhoaDaoTao ?? this.idNienKhoaDaoTao,
        idBacDaoTao: idBacDaoTao ?? this.idBacDaoTao,
        idHeDaoTao: idHeDaoTao ?? this.idHeDaoTao,
        idKhuVucUuTien: idKhuVucUuTien ?? this.idKhuVucUuTien,
        idLopDaoTao: idLopDaoTao ?? this.idLopDaoTao,
        idDanToc: idDanToc ?? this.idDanToc,
        idQuocGia: idQuocGia ?? this.idQuocGia,
        idDoiTuongUuTien: idDoiTuongUuTien ?? this.idDoiTuongUuTien,
        nangKhieu: nangKhieu ?? this.nangKhieu,
        tenKhac: tenKhac ?? this.tenKhac,
        nhomMau: nhomMau ?? this.nhomMau,
        chieuCao: chieuCao ?? this.chieuCao,
        canNang: canNang ?? this.canNang,
        tel: tel ?? this.tel,
        mobile: mobile ?? this.mobile,
        email: email ?? this.email,
        emailKhac: emailKhac ?? this.emailKhac,
        idTonGiao: idTonGiao ?? this.idTonGiao,
        idTinhThanhPho: idTinhThanhPho ?? this.idTinhThanhPho,
        idQuanHuyen: idQuanHuyen ?? this.idQuanHuyen,
        isDoan: isDoan ?? this.isDoan,
        isBoDoi: isBoDoi ?? this.isBoDoi,
        isDang: isDang ?? this.isDang,
        ngayVaoDoan: ngayVaoDoan ?? this.ngayVaoDoan,
        noiVaoDoan: noiVaoDoan ?? this.noiVaoDoan,
        viTriCaoNhatDoan: viTriCaoNhatDoan ?? this.viTriCaoNhatDoan,
        ngayVaoDang: ngayVaoDang ?? this.ngayVaoDang,
        ngayVaoDangChinhThuc: ngayVaoDangChinhThuc ?? this.ngayVaoDangChinhThuc,
        noiVaoDang: noiVaoDang ?? this.noiVaoDang,
        viTriCaoNhatDang: viTriCaoNhatDang ?? this.viTriCaoNhatDang,
        bienChe: bienChe ?? this.bienChe,
        nhapNgu: nhapNgu ?? this.nhapNgu,
        xuatNgu: xuatNgu ?? this.xuatNgu,
        idQueQuanQuocGia: idQueQuanQuocGia ?? this.idQueQuanQuocGia,
        idQueQuanTinhThanhPho:
            idQueQuanTinhThanhPho ?? this.idQueQuanTinhThanhPho,
        idQueQuanQuanHuyen: idQueQuanQuanHuyen ?? this.idQueQuanQuanHuyen,
        queQuanPhuongXa: queQuanPhuongXa ?? this.queQuanPhuongXa,
        idNoiSinhQuocGia: idNoiSinhQuocGia ?? this.idNoiSinhQuocGia,
        idNoiSinhTinhThanhPho:
            idNoiSinhTinhThanhPho ?? this.idNoiSinhTinhThanhPho,
        idNoiSinhQuanHuyen: idNoiSinhQuanHuyen ?? this.idNoiSinhQuanHuyen,
        noiSinhPhuongXa: noiSinhPhuongXa ?? this.noiSinhPhuongXa,
        idHoKhauThuongTruTinhThanhPho:
            idHoKhauThuongTruTinhThanhPho ?? this.idHoKhauThuongTruTinhThanhPho,
        idHoKhauThuongTruQuanHuyen:
            idHoKhauThuongTruQuanHuyen ?? this.idHoKhauThuongTruQuanHuyen,
        hoKhauThuongTruPhuongXa:
            hoKhauThuongTruPhuongXa ?? this.hoKhauThuongTruPhuongXa,
        hoKhauThuongTruDuongThon:
            hoKhauThuongTruDuongThon ?? this.hoKhauThuongTruDuongThon,
        hoKhauThuongTruSoNha: hoKhauThuongTruSoNha ?? this.hoKhauThuongTruSoNha,
        idNoiOHienNayQuocGia: idNoiOHienNayQuocGia ?? this.idNoiOHienNayQuocGia,
        idNoiOHienNayTinhThanhPho:
            idNoiOHienNayTinhThanhPho ?? this.idNoiOHienNayTinhThanhPho,
        idNoiOHienNayQuanHuyen:
            idNoiOHienNayQuanHuyen ?? this.idNoiOHienNayQuanHuyen,
        noiOHienNayPhuongXa: noiOHienNayPhuongXa ?? this.noiOHienNayPhuongXa,
        noiOHienNayDuongThon: noiOHienNayDuongThon ?? this.noiOHienNayDuongThon,
        noiOHienNaySoNha: noiOHienNaySoNha ?? this.noiOHienNaySoNha,
        idDiaChiLienLacQuocGia:
            idDiaChiLienLacQuocGia ?? this.idDiaChiLienLacQuocGia,
        idDiaChiLienLacTinhThanhPho:
            idDiaChiLienLacTinhThanhPho ?? this.idDiaChiLienLacTinhThanhPho,
        idDiaChiLienLacQuanHuyen:
            idDiaChiLienLacQuanHuyen ?? this.idDiaChiLienLacQuanHuyen,
        diaChiLienLacPhuongXa:
            diaChiLienLacPhuongXa ?? this.diaChiLienLacPhuongXa,
        diaChiLienLacDuongThon:
            diaChiLienLacDuongThon ?? this.diaChiLienLacDuongThon,
        diaChiLienLacSoNha: diaChiLienLacSoNha ?? this.diaChiLienLacSoNha,
        hoVaTenCha: hoVaTenCha ?? this.hoVaTenCha,
        ngaySinhCha: ngaySinhCha ?? this.ngaySinhCha,
        ngheNghiepCha: ngheNghiepCha ?? this.ngheNghiepCha,
        diaChiCha: diaChiCha ?? this.diaChiCha,
        nguyenQuanCha: nguyenQuanCha ?? this.nguyenQuanCha,
        diaChiCoQuanCha: diaChiCoQuanCha ?? this.diaChiCoQuanCha,
        lyLichCha: lyLichCha ?? this.lyLichCha,
        dienThoaiCha: dienThoaiCha ?? this.dienThoaiCha,
        emailCha: emailCha ?? this.emailCha,
        hoVaTenMe: hoVaTenMe ?? this.hoVaTenMe,
        ngaySinhMe: ngaySinhMe ?? this.ngaySinhMe,
        ngheNghiepMe: ngheNghiepMe ?? this.ngheNghiepMe,
        diaChiMe: diaChiMe ?? this.diaChiMe,
        nguyenQuanMe: nguyenQuanMe ?? this.nguyenQuanMe,
        diaChiCoQuanMe: diaChiCoQuanMe ?? this.diaChiCoQuanMe,
        lyLichMe: lyLichMe ?? this.lyLichMe,
        dienThoaiMe: dienThoaiMe ?? this.dienThoaiMe,
        emailMe: emailMe ?? this.emailMe,
        anhEm: anhEm ?? this.anhEm,
        ngaySinhAnhEm: ngaySinhAnhEm ?? this.ngaySinhAnhEm,
        ngheNghiepAnhEm: ngheNghiepAnhEm ?? this.ngheNghiepAnhEm,
        conCai: conCai ?? this.conCai,
        hoVaTenVoChong: hoVaTenVoChong ?? this.hoVaTenVoChong,
        ngaySinhVoChong: ngaySinhVoChong ?? this.ngaySinhVoChong,
        ngheNghiepVoChong: ngheNghiepVoChong ?? this.ngheNghiepVoChong,
        diaChiVoChong: diaChiVoChong ?? this.diaChiVoChong,
        thanhPhanGiaDinh: thanhPhanGiaDinh ?? this.thanhPhanGiaDinh,
      );

  factory StudentInfoModel.fromJson(Map<String, dynamic> json) =>
      StudentInfoModel(
        maSinhVien: json["maSinhVien"],
        hoVaTen: json["hoVaTen"],
        gioiTinh: json["gioiTinh"],
        soCmtCccd: json["soCMT_CCCD"],
        idNoiCapCmtCccdTinhThanhPho: json["idNoiCapCMT_CCCD_TinhThanhPho"],
        ngayCapCmtCccd: json["ngayCapCMT_CCCD"] == null
            ? null
            : DateTime.parse(json["ngayCapCMT_CCCD"]),
        soBaoDanh: json["soBaoDanh"],
        maHoSo: json["maHoSo"],
        ngaySinh:
            json["ngaySinh"] == null ? null : DateTime.parse(json["ngaySinh"]),
        guidDonVi: json["guidDonVi"],
        idNganhDaoTao: json["idNganhDaoTao"],
        idChuongTrinhDaoTao: json["idChuongTrinhDaoTao"],
        idNienKhoaDaoTao: json["idNienKhoaDaoTao"],
        idBacDaoTao: json["idBacDaoTao"],
        idHeDaoTao: json["idHeDaoTao"],
        idKhuVucUuTien: json["idKhuVucUuTien"],
        idLopDaoTao: json["idLopDaoTao"],
        idDanToc: json["idDanToc"],
        idQuocGia: json["idQuocGia"],
        idDoiTuongUuTien: json["idDoiTuongUuTien"],
        nangKhieu: json["nangKhieu"],
        tenKhac: json["tenKhac"],
        nhomMau: json["nhomMau"],
        chieuCao: json["chieuCao"],
        canNang: json["canNang"],
        tel: json["tel"],
        mobile: json["mobile"],
        email: json["email"],
        emailKhac: json["emailKhac"],
        idTonGiao: json["idTonGiao"],
        idTinhThanhPho: json["idTinhThanhPho"],
        idQuanHuyen: json["idQuanHuyen"],
        isDoan: json["isDoan"],
        isBoDoi: json["isBoDoi"],
        isDang: json["isDang"],
        ngayVaoDoan: json["ngayVaoDoan"] == null
            ? null
            : DateTime.parse(json["ngayVaoDoan"]),
        noiVaoDoan: json["noiVaoDoan"],
        viTriCaoNhatDoan: json["viTriCaoNhatDoan"],
        ngayVaoDang: json["ngayVaoDang"] == null
            ? null
            : DateTime.parse(json["ngayVaoDang"]),
        ngayVaoDangChinhThuc: json["ngayVaoDangChinhThuc"] == null
            ? null
            : DateTime.parse(json["ngayVaoDangChinhThuc"]),
        noiVaoDang: json["noiVaoDang"],
        viTriCaoNhatDang: json["viTriCaoNhatDang"],
        bienChe: json["bienChe"],
        nhapNgu:
            json["nhapNgu"] == null ? null : DateTime.parse(json["nhapNgu"]),
        xuatNgu:
            json["xuatNgu"] == null ? null : DateTime.parse(json["xuatNgu"]),
        idQueQuanQuocGia: json["idQueQuan_QuocGia"],
        idQueQuanTinhThanhPho: json["idQueQuan_TinhThanhPho"],
        idQueQuanQuanHuyen: json["idQueQuan_QuanHuyen"],
        queQuanPhuongXa: json["queQuan_PhuongXa"],
        idNoiSinhQuocGia: json["idNoiSinh_QuocGia"],
        idNoiSinhTinhThanhPho: json["idNoiSinh_TinhThanhPho"],
        idNoiSinhQuanHuyen: json["idNoiSinh_QuanHuyen"],
        noiSinhPhuongXa: json["noiSinh_PhuongXa"],
        idHoKhauThuongTruTinhThanhPho: json["idHoKhauThuongTru_TinhThanhPho"],
        idHoKhauThuongTruQuanHuyen: json["idHoKhauThuongTru_QuanHuyen"],
        hoKhauThuongTruPhuongXa: json["hoKhauThuongTru_PhuongXa"],
        hoKhauThuongTruDuongThon: json["hoKhauThuongTru_DuongThon"],
        hoKhauThuongTruSoNha: json["hoKhauThuongTru_SoNha"],
        idNoiOHienNayQuocGia: json["idNoiOHienNay_QuocGia"],
        idNoiOHienNayTinhThanhPho: json["idNoiOHienNay_TinhThanhPho"],
        idNoiOHienNayQuanHuyen: json["idNoiOHienNay_QuanHuyen"],
        noiOHienNayPhuongXa: json["noiOHienNay_PhuongXa"],
        noiOHienNayDuongThon: json["noiOHienNay_DuongThon"],
        noiOHienNaySoNha: json["noiOHienNay_SoNha"],
        idDiaChiLienLacQuocGia: json["idDiaChiLienLac_QuocGia"],
        idDiaChiLienLacTinhThanhPho: json["idDiaChiLienLac_TinhThanhPho"],
        idDiaChiLienLacQuanHuyen: json["idDiaChiLienLac_QuanHuyen"],
        diaChiLienLacPhuongXa: json["diaChiLienLac_PhuongXa"],
        diaChiLienLacDuongThon: json["diaChiLienLac_DuongThon"],
        diaChiLienLacSoNha: json["diaChiLienLac_SoNha"],
        hoVaTenCha: json["hoVaTenCha"],
        ngaySinhCha: json["ngaySinhCha"],
        ngheNghiepCha: json["ngheNghiepCha"],
        diaChiCha: json["diaChiCha"],
        nguyenQuanCha: json['nguyenQuanCha'],
        diaChiCoQuanCha: json["diaChiCoQuanCha"],
        lyLichCha: json["lyLichCha"],
        dienThoaiCha: json["dienThoaiCha"],
        emailCha: json["emailCha"],
        hoVaTenMe: json["hoVaTenMe"],
        ngaySinhMe: json["ngaySinhMe"],
        ngheNghiepMe: json["ngheNghiepMe"],
        diaChiMe: json["diaChiMe"],
        nguyenQuanMe: json["nguyenQuanMe"],
        diaChiCoQuanMe: json["diaChiCoQuanMe"],
        lyLichMe: json["lyLichMe"],
        dienThoaiMe: json["dienThoaiMe"],
        emailMe: json["emailMe"],
        anhEm: json["anhEm"],
        ngaySinhAnhEm: json["ngaySinhAnhEm"] == null
            ? null
            : DateTime.parse(json["ngaySinhAnhEm"]),
        ngheNghiepAnhEm: json["ngheNghiepAnhEm"],
        conCai: json["conCai"],
        hoVaTenVoChong: json["hoVaTenVoChong"],
        ngaySinhVoChong: json["ngaySinhVoChong"] == null
            ? null
            : DateTime.parse(json["ngaySinhVoChong"]),
        ngheNghiepVoChong: json["ngheNghiepVoChong"],
        diaChiVoChong: json["diaChiVoChong"],
        thanhPhanGiaDinh: json["thanhPhanGiaDinh"],
      );

  Map<String, dynamic> toJson() {
    final dict = {
      "maSinhVien": maSinhVien,
      "hoVaTen": hoVaTen,
      "gioiTinh": gioiTinh,
      "soCMT_CCCD": soCmtCccd,
      "idNoiCapCMT_CCCD_TinhThanhPho": idNoiCapCmtCccdTinhThanhPho,
      "ngayCapCMT_CCCD": ngayCapCmtCccd?.toUtc().toIso8601String(),
      "soBaoDanh": soBaoDanh,
      "maHoSo": maHoSo,
      "ngaySinh": ngaySinh?.toUtc().toIso8601String(),
      "guidDonVi": guidDonVi,
      "idNganhDaoTao": idNganhDaoTao,
      "idChuongTrinhDaoTao": idChuongTrinhDaoTao,
      "idNienKhoaDaoTao": idNienKhoaDaoTao,
      "idBacDaoTao": idBacDaoTao,
      "idHeDaoTao": idHeDaoTao,
      "idKhuVucUuTien": idKhuVucUuTien,
      "idLopDaoTao": idLopDaoTao,
      "idDanToc": idDanToc,
      "idQuocGia": idQuocGia,
      "idDoiTuongUuTien": idDoiTuongUuTien,
      "nangKhieu": nangKhieu,
      "tenKhac": tenKhac,
      "nhomMau": nhomMau,
      "chieuCao": chieuCao,
      "canNang": canNang,
      "tel": tel,
      "mobile": mobile,
      "email": email,
      "emailKhac": emailKhac,
      "idTonGiao": idTonGiao,
      "idTinhThanhPho": idTinhThanhPho,
      "idQuanHuyen": idQuanHuyen,
      "isDoan": isDoan,
      "isBoDoi": isBoDoi,
      "isDang": isDang,
      "ngayVaoDoan": ngayVaoDoan?.toUtc().toIso8601String(),
      "noiVaoDoan": noiVaoDoan,
      "viTriCaoNhatDoan": viTriCaoNhatDoan,
      "ngayVaoDang": ngayVaoDang?.toUtc().toIso8601String(),
      "ngayVaoDangChinhThuc": ngayVaoDangChinhThuc?.toUtc().toIso8601String(),
      "noiVaoDang": noiVaoDang,
      "viTriCaoNhatDang": viTriCaoNhatDang,
      "bienChe": bienChe,
      "nhapNgu": nhapNgu?.toUtc().toIso8601String(),
      "xuatNgu": xuatNgu?.toUtc().toIso8601String(),
      "idQueQuan_QuocGia": idQueQuanQuocGia,
      "idQueQuan_TinhThanhPho": idQueQuanTinhThanhPho,
      "idQueQuan_QuanHuyen": idQueQuanQuanHuyen,
      "queQuan_PhuongXa": queQuanPhuongXa,
      "idNoiSinh_QuocGia": idNoiSinhQuocGia,
      "idNoiSinh_TinhThanhPho": idNoiSinhTinhThanhPho,
      "idNoiSinh_QuanHuyen": idNoiSinhQuanHuyen,
      "noiSinh_PhuongXa": noiSinhPhuongXa,
      "idHoKhauThuongTru_TinhThanhPho": idHoKhauThuongTruTinhThanhPho,
      "idHoKhauThuongTru_QuanHuyen": idHoKhauThuongTruQuanHuyen,
      "hoKhauThuongTru_PhuongXa": hoKhauThuongTruPhuongXa,
      "hoKhauThuongTru_DuongThon": hoKhauThuongTruDuongThon,
      "hoKhauThuongTru_SoNha": hoKhauThuongTruSoNha,
      "idNoiOHienNay_QuocGia": idNoiOHienNayQuocGia,
      "idNoiOHienNay_TinhThanhPho": idNoiOHienNayTinhThanhPho,
      "idNoiOHienNay_QuanHuyen": idNoiOHienNayQuanHuyen,
      "noiOHienNay_PhuongXa": noiOHienNayPhuongXa,
      "noiOHienNay_DuongThon": noiOHienNayDuongThon,
      "noiOHienNay_SoNha": noiOHienNaySoNha,
      "idDiaChiLienLac_QuocGia": idDiaChiLienLacQuocGia,
      "idDiaChiLienLac_TinhThanhPho": idDiaChiLienLacTinhThanhPho,
      "idDiaChiLienLac_QuanHuyen": idDiaChiLienLacQuanHuyen,
      "diaChiLienLac_PhuongXa": diaChiLienLacPhuongXa,
      "diaChiLienLac_DuongThon": diaChiLienLacDuongThon,
      "diaChiLienLac_SoNha": diaChiLienLacSoNha,
      "hoVaTenCha": hoVaTenCha,
      "ngaySinhCha": ngaySinhCha,
      "ngheNghiepCha": ngheNghiepCha,
      "diaChiCha": diaChiCha,
      "nguyenQuanCha": nguyenQuanCha,
      "diaChiCoQuanCha": diaChiCoQuanCha,
      "lyLichCha": lyLichCha,
      "dienThoaiCha": dienThoaiCha,
      "emailCha": emailCha,
      "hoVaTenMe": hoVaTenMe,
      "ngaySinhMe": ngaySinhMe,
      "ngheNghiepMe": ngheNghiepMe,
      "diaChiMe": diaChiMe,
      "nguyenQuanMe": nguyenQuanMe,
      "diaChiCoQuanMe": diaChiCoQuanMe,
      "lyLichMe": lyLichMe,
      "dienThoaiMe": dienThoaiMe,
      "emailMe": emailMe,
      "anhEm": anhEm,
      "ngaySinhAnhEm": ngaySinhAnhEm,
      "ngheNghiepAnhEm": ngheNghiepAnhEm,
      "conCai": conCai,
      "hoVaTenVoChong": hoVaTenVoChong,
      "ngaySinhVoChong": ngaySinhVoChong?.toUtc().toIso8601String(),
      "ngheNghiepVoChong": ngheNghiepVoChong,
      "diaChiVoChong": diaChiVoChong,
      "thanhPhanGiaDinh": thanhPhanGiaDinh,
    };
    dict.removeWhere((key, value) => value == null);
    return dict;
  }
}
