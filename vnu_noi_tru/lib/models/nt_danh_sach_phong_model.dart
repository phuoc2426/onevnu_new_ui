// To parse this JSON data, do
//
//     final ntDanhSachPhongModel = ntDanhSachPhongModelFromJson(jsonString);

import 'dart:convert';

NtDanhSachPhongModel ntDanhSachPhongModelFromJson(String str) =>
    NtDanhSachPhongModel.fromJson(json.decode(str));

String ntDanhSachPhongModelToJson(NtDanhSachPhongModel data) =>
    json.encode(data.toJson());

class NtDanhSachPhongModel {
  NtDanhSachPhongModel({
    this.danhSachLoaiPhong,
  });

  List<DanhSachLoaiPhong>? danhSachLoaiPhong;

  factory NtDanhSachPhongModel.fromJson(Map<String, dynamic> json) =>
      NtDanhSachPhongModel(
        danhSachLoaiPhong: List<DanhSachLoaiPhong>.from(
            (json["DanhSachLoaiPhong"] ?? [])
                .map((x) => DanhSachLoaiPhong.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "DanhSachLoaiPhong": List<dynamic>.from(
            (danhSachLoaiPhong ?? []).map((x) => x.toJson())),
      };
}

class DanhSachLoaiPhong {
  DanhSachLoaiPhong({
    this.id,
    this.ID_LoaiPhong,
    this.tenLoaiPhong,
    this.danhSachLoaiPhi,
    this.danhSachLoaiCoSoVatChat,
  });

  int? id;
  int? ID_LoaiPhong;
  String? tenLoaiPhong;
  List<DanhSachLoaiPhi>? danhSachLoaiPhi;
  List<DanhSachLoaiCoSoVatChat>? danhSachLoaiCoSoVatChat;

  factory DanhSachLoaiPhong.fromJson(Map<String, dynamic> json) =>
      DanhSachLoaiPhong(
        id: json["Id"],
        ID_LoaiPhong: json['ID_LoaiPhong'],
        tenLoaiPhong: json["TenLoaiPhong"],
        danhSachLoaiPhi: List<DanhSachLoaiPhi>.from(
            (json["DanhSachLoaiPhi"] ?? [])
                .map((x) => DanhSachLoaiPhi.fromJson(x))),
        danhSachLoaiCoSoVatChat: List<DanhSachLoaiCoSoVatChat>.from(
            (json["DanhSachLoaiCoSoVatChat"] ?? [])
                .map((x) => DanhSachLoaiCoSoVatChat.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "Id": id,
        "ID_LoaiPhong": ID_LoaiPhong,
        "TenLoaiPhong": tenLoaiPhong,
        "DanhSachLoaiPhi": List<dynamic>.from(
            (danhSachLoaiCoSoVatChat ?? []).map((x) => x.toJson())),
        "DanhSachLoaiCoSoVatChat": List<dynamic>.from(
            (danhSachLoaiCoSoVatChat ?? []).map((x) => x.toJson())),
      };
}

class DanhSachLoaiCoSoVatChat {
  DanhSachLoaiCoSoVatChat({
    this.tenLoaiCsvc,
    this.soLuong,
  });

  String? tenLoaiCsvc;
  String? soLuong;

  factory DanhSachLoaiCoSoVatChat.fromJson(Map<String, dynamic> json) =>
      DanhSachLoaiCoSoVatChat(
        tenLoaiCsvc: json["TenLoaiCSVC"],
        soLuong: json["SoLuong"],
      );

  Map<String, dynamic> toJson() => {
        "TenLoaiCSVC": tenLoaiCsvc,
        "SoLuong": soLuong,
      };
}

class DanhSachLoaiPhi {
  DanhSachLoaiPhi({
    this.tenLoaiPhi,
    this.soTien,
  });

  String? tenLoaiPhi;
  String? soTien;

  factory DanhSachLoaiPhi.fromJson(Map<String, dynamic> json) =>
      DanhSachLoaiPhi(
        tenLoaiPhi: json["TenLoaiPhi"],
        soTien: json["SoTien"],
      );

  Map<String, dynamic> toJson() => {
        "TenLoaiPhi": tenLoaiPhi,
        "SoTien": soTien,
      };
}
