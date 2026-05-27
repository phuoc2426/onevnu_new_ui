// To parse this JSON data, do
//
//     final currentUserModel = currentUserModelFromJson(jsonString);

import 'dart:convert';

CurrentUserModel currentUserModelFromJson(String str) =>
    CurrentUserModel.fromJson(json.decode(str));

String currentUserModelToJson(CurrentUserModel data) =>
    json.encode(data.toJson());

class CurrentUserModel {
  dynamic guidFileAnhDaiDien;
  String? tenDangNhap;
  dynamic matKhau;
  String? hoVaTen;
  String? guidDonVi;
  String? email;
  String? soDienThoai;
  DateTime? ngaySinh;
  String? guid;
  String? gioiTinh;
  String? trangThai;

  CurrentUserModel({
    this.guidFileAnhDaiDien,
    this.tenDangNhap,
    this.matKhau,
    this.hoVaTen,
    this.guidDonVi,
    this.email,
    this.soDienThoai,
    this.ngaySinh,
    this.guid,
    this.gioiTinh,
    this.trangThai,
  });

  CurrentUserModel copyWith({
    dynamic guidFileAnhDaiDien,
    String? tenDangNhap,
    dynamic matKhau,
    String? hoVaTen,
    String? guidDonVi,
    String? email,
    String? soDienThoai,
    DateTime? ngaySinh,
    String? guid,
    String? gioiTinh,
    String? trangThai,
  }) =>
      CurrentUserModel(
        guidFileAnhDaiDien: guidFileAnhDaiDien ?? this.guidFileAnhDaiDien,
        tenDangNhap: tenDangNhap ?? this.tenDangNhap,
        matKhau: matKhau ?? this.matKhau,
        hoVaTen: hoVaTen ?? this.hoVaTen,
        guidDonVi: guidDonVi ?? this.guidDonVi,
        email: email ?? this.email,
        soDienThoai: soDienThoai ?? this.soDienThoai,
        ngaySinh: ngaySinh ?? this.ngaySinh,
        guid: guid ?? this.guid,
        gioiTinh: gioiTinh ?? this.gioiTinh,
        trangThai: trangThai ?? this.trangThai,
      );

  factory CurrentUserModel.fromJson(Map<String, dynamic> json) =>
      CurrentUserModel(
        guidFileAnhDaiDien: json["guidFileAnhDaiDien"],
        tenDangNhap: json["tenDangNhap"],
        matKhau: json["matKhau"],
        hoVaTen: json["hoVaTen"],
        guidDonVi: json["guidDonVi"],
        email: json["email"],
        soDienThoai: json["soDienThoai"],
        ngaySinh:
            json["ngaySinh"] == null ? null : DateTime.parse(json["ngaySinh"]),
        guid: json["guid"],
        gioiTinh: json["gioiTinh"],
        trangThai: json["trangThai"],
      );

  Map<String, dynamic> toJson() => {
        "guidFileAnhDaiDien": guidFileAnhDaiDien,
        "tenDangNhap": tenDangNhap,
        "matKhau": matKhau,
        "hoVaTen": hoVaTen,
        "guidDonVi": guidDonVi,
        "email": email,
        "soDienThoai": soDienThoai,
        "ngaySinh": ngaySinh?.toIso8601String(),
        "guid": guid,
        "gioiTinh": gioiTinh,
        "trangThai": trangThai,
      };
}
