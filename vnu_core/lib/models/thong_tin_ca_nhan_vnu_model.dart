// To parse this JSON data, do
//
//     final ntThongTinCaNhanVnuModel = ntThongTinCaNhanVnuModelFromJson(jsonString);

import 'dart:convert';

import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/models/thong_tin_sinh_vien_model.dart';

NtThongTinCaNhanVnuModel ntThongTinCaNhanVnuModelFromJson(String str) =>
    NtThongTinCaNhanVnuModel.fromJson(json.decode(str));

String ntThongTinCaNhanVnuModelToJson(NtThongTinCaNhanVnuModel data) =>
    json.encode(data.toJson());

class NtThongTinCaNhanVnuModel {
  NtThongTinCaNhanVnuModel({
    this.id,
    this.ntThongTinCaNhanVnuModelId,
    this.hoTen,
    this.ngaySinh,
    this.gioiTinh,
    this.danToc,
    this.tonGiao,
    this.quocTich,
    this.maSinhVien,
    this.loaiGiayTo,
    this.cmndCccd,
    this.ngayCap,
    this.noiCap,
    this.ngayVaoDoan,
    this.quocGia,
    this.tinhThanhPho,
    this.quanHuyen,
    this.phuongXa,
    this.donViDaoTao,
    this.khoa,
    this.nganh,
    this.ntThongTinCaNhanVnuModelKhoa,
    this.lop,
    this.email,
    this.soDienThoai,
    this.diaChiLienHe,
  });

  String? id;
  int? ntThongTinCaNhanVnuModelId;
  String? hoTen;
  String? ngaySinh;
  String? gioiTinh;
  String? danToc;
  String? tonGiao;
  String? quocTich;
  String? maSinhVien;
  String? loaiGiayTo;
  String? cmndCccd;
  String? ngayCap;
  String? noiCap;
  String? ngayVaoDoan;
  String? quocGia;
  String? tinhThanhPho;
  String? quanHuyen;
  String? phuongXa;
  String? donViDaoTao;
  String? khoa;
  String? nganh;
  String? ntThongTinCaNhanVnuModelKhoa;
  String? lop;
  String? email;
  String? soDienThoai;
  String? diaChiLienHe;

  factory NtThongTinCaNhanVnuModel.fromJson(Map<String, dynamic> json) =>
      NtThongTinCaNhanVnuModel(
        ntThongTinCaNhanVnuModelId: json["ID"],
        hoTen: json["HoTen"],
        ngaySinh: json["NgaySinh"],
        gioiTinh: json["GioiTinh"],
        danToc: json["DanToc"],
        tonGiao: json["TonGiao"],
        quocTich: json["QuocTich"],
        maSinhVien: json["MaSinhVien"],
        loaiGiayTo: json["LoaiGiayTo"],
        cmndCccd: json["CMND_CCCD"],
        ngayCap: json["NgayCap"],
        noiCap: json["NoiCap"],
        ngayVaoDoan: json["NgayVaoDoan"],
        quocGia: json["QuocGia"],
        tinhThanhPho: json["TinhThanhPho"],
        quanHuyen: json["QuanHuyen"],
        phuongXa: json["PhuongXa"],
        donViDaoTao: json["DonViDaoTao"],
        khoa: json["Khoa"],
        nganh: json["Nganh"],
        ntThongTinCaNhanVnuModelKhoa: json["Khoa_"],
        lop: json["Lop"],
        email: json["Email"],
        soDienThoai: json["SoDienThoai"],
        diaChiLienHe: json["DiaChiLienHe"],
      );

  Map<String, dynamic> toJson() => {
        "ID": ntThongTinCaNhanVnuModelId,
        "HoTen": hoTen,
        "NgaySinh": ngaySinh,
        "GioiTinh": gioiTinh,
        "DanToc": danToc,
        "TonGiao": tonGiao,
        "QuocTich": quocTich,
        "MaSinhVien": maSinhVien,
        "LoaiGiayTo": loaiGiayTo,
        "CMND_CCCD": cmndCccd,
        "NgayCap": ngayCap,
        "NoiCap": noiCap,
        "NgayVaoDoan": ngayVaoDoan,
        "QuocGia": quocGia,
        "TinhThanhPho": tinhThanhPho,
        "QuanHuyen": quanHuyen,
        "PhuongXa": phuongXa,
        "DonViDaoTao": donViDaoTao,
        "Khoa": khoa,
        "Nganh": nganh,
        "Khoa_": ntThongTinCaNhanVnuModelKhoa,
        "Lop": lop,
        "Email": email,
        "SoDienThoai": soDienThoai,
        "DiaChiLienHe": diaChiLienHe,
      };

  ThongTinSinhVienModel toThongTinSinhVien() {
    ThongTinSinhVienModel thongTin = ThongTinSinhVienModel();
    thongTin.id = ntThongTinCaNhanVnuModelId;
    thongTin.hoTen = hoTen;
    thongTin.ngaySinh = ngaySinh;
    thongTin.gioiTinh = gioiTinh;
    thongTin.danToc = danToc;
    thongTin.tonGiao = tonGiao;
    thongTin.quocTich = quocTich;

    thongTin.maSinhVien = maSinhVien;
    thongTin.loaiGiayTo = loaiGiayTo;
    thongTin.cmndCccd = cmndCccd;
    thongTin.ngayCap = ngayCap;
    thongTin.noiCap = noiCap;
    thongTin.ngayVaoDoan = ngayVaoDoan;

    ThongTinDiaChiThuongTruModel thuongTru = ThongTinDiaChiThuongTruModel();
    thuongTru.quocGia = quocGia;
    thuongTru.tinhThanhPho = tinhThanhPho;
    thuongTru.quanHuyen = quanHuyen;
    thuongTru.phuongXa = phuongXa;
    // thuongTru.diaChiChiTiet,
    thongTin.diaChiThuongTru = thuongTru;

    ThongTinNhapHocModel thongTinNhapHoc = ThongTinNhapHocModel();
    thongTinNhapHoc.donViDaoTao = donViDaoTao;
    thongTinNhapHoc.khoa = khoa;
    thongTinNhapHoc.nganh = nganh;
    thongTinNhapHoc.khoaHoc = ntThongTinCaNhanVnuModelKhoa;
    thongTinNhapHoc.lop = lop;
    thongTinNhapHoc.namBatDau = '';
    thongTinNhapHoc.namKetThuc = '';

    thongTin.thongTinNhapHoc = thongTinNhapHoc;

    ThongTinLienHeModel? thongTinLienHe = ThongTinLienHeModel();
    thongTinLienHe.email = email;
    thongTinLienHe.soDienThoai = soDienThoai;
    thongTinLienHe.diaChiLienHe = diaChiLienHe;
    thongTin.thongTinLienHe = thongTinLienHe;
    return thongTin;
  }
}
