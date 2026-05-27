// To parse this JSON data, do
//
//     final banDoSoModel = banDoSoModelFromJson(jsonString);

import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';

BanDoSoModel banDoSoModelFromJson(String str) =>
    BanDoSoModel.fromJson(json.decode(str));

String banDoSoModelToJson(BanDoSoModel data) => json.encode(data.toJson());

class BanDoSoModel {
  BanDoSoModel({this.dsCacLoaiBanDoSo, this.trangThai});

  List<DsCacLoaiBanDoSo>? dsCacLoaiBanDoSo;
  String? trangThai;

  factory BanDoSoModel.fromJson(Map<String, dynamic> json) => BanDoSoModel(
        trangThai: json["TrangThai"],
        dsCacLoaiBanDoSo: List<DsCacLoaiBanDoSo>.from(
            (json["DSCacLoaiBanDoSo"] ?? [])
                .map((x) => DsCacLoaiBanDoSo.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "TrangThai": trangThai,
        "DSCacLoaiBanDoSo":
            List<dynamic>.from((dsCacLoaiBanDoSo ?? []).map((x) => x.toJson())),
      };
  LatLng defaultLocation() {
    String diaDiem = dsCacLoaiBanDoSo?.first.diaDiem?.first.toaDo ?? '';
    if (diaDiem.isEmpty) return LatLng(21.0388688, 105.783268);
    List<String> latlongList = diaDiem.split(',');
    LatLng _latLng = LatLng(double.parse(latlongList.first.trim()),
        double.parse(latlongList.last.trim()));
    return _latLng;
  }

  bool isActive() {
    return trangThai?.toLowerCase() == 'Active'.toLowerCase();
  }

  resetSelected() {
    for (DsCacLoaiBanDoSo element in (dsCacLoaiBanDoSo ?? [])) {
      element.isSelected = false;
    }
  }
}

class DsCacLoaiBanDoSo {
  DsCacLoaiBanDoSo({
    this.id,
    this.tieuDe,
    this.maIcon,
    this.diaDiem,
    this.toaDo,
  });

  int? id;
  String? tieuDe;
  String? maIcon;
  List<DiaDiemBanDoSo>? diaDiem;
  String? toaDo;

  //Local
  bool isSelected = false;

  factory DsCacLoaiBanDoSo.fromJson(Map<String, dynamic> json) =>
      DsCacLoaiBanDoSo(
        id: json["ID"],
        tieuDe: json["TieuDe"],
        maIcon: json["Ma_Icon"],
        diaDiem: json["DiaDiem"] == null
            ? []
            : List<DiaDiemBanDoSo>.from(
                json["DiaDiem"].map((x) => DiaDiemBanDoSo.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "ID": id,
        "TieuDe": tieuDe,
        "Ma_Icon": maIcon,
        "DiaDiem": diaDiem == null
            ? []
            : List<dynamic>.from((diaDiem ?? []).map((x) => x.toJson())),
        "ToaDo": toaDo,
      };
}

class DiaDiemBanDoSo {
  DiaDiemBanDoSo({this.id, this.tieuDe, this.maIcon, this.toaDo, this.moTa});

  int? id;
  String? tieuDe;
  String? maIcon;
  String? toaDo;
  String? moTa;

  factory DiaDiemBanDoSo.fromJson(Map<String, dynamic> json) => DiaDiemBanDoSo(
      id: json["ID"],
      tieuDe: json["TieuDe"],
      maIcon: json["Ma_Icon"],
      toaDo: json["ToaDo"],
      moTa: json["MoTa"]);

  Map<String, dynamic> toJson() => {
        "ID": id,
        "TieuDe": tieuDe,
        "Ma_Icon": maIcon,
        "ToaDo": toaDo,
        "MoTa": moTa,
      };
}
