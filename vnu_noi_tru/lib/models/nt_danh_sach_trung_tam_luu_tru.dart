// To parse this JSON data, do
//
//     final ntDanhSachTrungTamLuuTruModel = ntDanhSachTrungTamLuuTruModelFromJson(jsonString);

import 'dart:convert';

NtDanhSachTrungTamLuuTruModel ntDanhSachTrungTamLuuTruModelFromJson(
        String str) =>
    NtDanhSachTrungTamLuuTruModel.fromJson(json.decode(str));

String ntDanhSachTrungTamLuuTruModelToJson(
        NtDanhSachTrungTamLuuTruModel data) =>
    json.encode(data.toJson());

class NtDanhSachTrungTamLuuTruModel {
  NtDanhSachTrungTamLuuTruModel({
    this.danhSachTrungTamLuuTru,
  });

  List<DanhSachTrungTamLuuTru>? danhSachTrungTamLuuTru;

  factory NtDanhSachTrungTamLuuTruModel.fromJson(Map<String, dynamic> json) =>
      NtDanhSachTrungTamLuuTruModel(
        danhSachTrungTamLuuTru: List<DanhSachTrungTamLuuTru>.from(
            json["DanhSachTrungTamLuuTru"]
                .map((x) => DanhSachTrungTamLuuTru.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "DanhSachTrungTamLuuTru": List<dynamic>.from(
            (danhSachTrungTamLuuTru ?? []).map((x) => x.toJson())),
      };
}

class DanhSachTrungTamLuuTru {
  DanhSachTrungTamLuuTru({
    this.id,
    this.ID_TrungTamLuuTru,
    this.tenTrungTamLuuTru,
  });

  int? id;
  int? ID_TrungTamLuuTru;
  String? tenTrungTamLuuTru;

  factory DanhSachTrungTamLuuTru.fromJson(Map<String, dynamic> json) =>
      DanhSachTrungTamLuuTru(
        id: json["Id"],
        ID_TrungTamLuuTru: json["ID_TrungTamLuuTru"],
        tenTrungTamLuuTru: json["TenTrungTamLuuTru"],
      );

  Map<String, dynamic> toJson() => {
        "Id": id,
        "ID_TrungTamLuuTru": ID_TrungTamLuuTru,
        "TenTrungTamLuuTru": tenTrungTamLuuTru,
      };
}
