// To parse this JSON data, do
//
//     final danhSachTinTucModel = danhSachTinTucModelFromJson(jsonString);

import 'dart:convert';

import 'package:vnu_noi_tru/models/nt_tin_tuc_model.dart';

NtDanhSachTinTucModel danhSachTinTucModelFromJson(String str) =>
    NtDanhSachTinTucModel.fromJson(json.decode(str));

String danhSachTinTucModelToJson(NtDanhSachTinTucModel data) =>
    json.encode(data.toJson());

class NtDanhSachTinTucModel {
  NtDanhSachTinTucModel({
    this.id,
    this.danhSachTinTuc,
  });

  String? id;
  List<NtTinTucModel>? danhSachTinTuc;

  factory NtDanhSachTinTucModel.fromJson(Map<String, dynamic> json) =>
      NtDanhSachTinTucModel(
        id: json["\$id"],
        danhSachTinTuc: List<NtTinTucModel>.from((json["DanhSachTinTuc"] ?? [])
            .map((x) => NtTinTucModel.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "\$id": id,
        "DanhSachTinTuc": List<NtTinTucModel>.from(
            (danhSachTinTuc ?? []).map((x) => x.toJson())),
      };
}
