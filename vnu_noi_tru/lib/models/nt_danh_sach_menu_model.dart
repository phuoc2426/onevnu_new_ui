// To parse this JSON data, do
//
//     final ntDanhSachMenuModel = ntDanhSachMenuModelFromJson(jsonString);

import 'dart:convert';

NtDanhSachMenuModel ntDanhSachMenuModelFromJson(String str) =>
    NtDanhSachMenuModel.fromJson(json.decode(str));

String ntDanhSachMenuModelToJson(NtDanhSachMenuModel data) =>
    json.encode(data.toJson());

class NtDanhSachMenuModel {
  NtDanhSachMenuModel({
    this.danhSachMenu,
  });

  List<DanhSachMenu>? danhSachMenu;

  factory NtDanhSachMenuModel.fromJson(Map<String, dynamic> json) =>
      NtDanhSachMenuModel(
        danhSachMenu: List<DanhSachMenu>.from(
            json["DanhSachMenu"].map((x) => DanhSachMenu.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "DanhSachMenu":
            List<dynamic>.from((danhSachMenu ?? []).map((x) => x.toJson())),
      };
}

class DanhSachMenu {
  DanhSachMenu({
    this.id,
    this.tenMenu,
    this.screenName,
    this.danhSachMenuCon,
  });

  int? id;
  String? tenMenu;
  String? screenName;
  List<DanhSachMenu>? danhSachMenuCon;

  factory DanhSachMenu.fromJson(Map<String, dynamic> json) => DanhSachMenu(
        id: json["ID"],
        tenMenu: json["TenMenu"],
        screenName: json["ScreenName"],
        danhSachMenuCon: json["DanhSachMenuCon"] == null
            ? null
            : List<DanhSachMenu>.from(
                json["DanhSachMenuCon"].map((x) => DanhSachMenu.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "ID": id,
        "TenMenu": tenMenu,
        "ScreenName": screenName,
        "DanhSachMenuCon": danhSachMenuCon == null
            ? null
            : List<dynamic>.from(
                (danhSachMenuCon ?? []).map((x) => x.toJson())),
      };
}
