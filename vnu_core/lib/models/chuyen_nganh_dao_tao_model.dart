// To parse this JSON data, do
//
//     final chuyenNganhDaoTaoModel = chuyenNganhDaoTaoModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'chuyen_nganh_dao_tao_model.g.dart';

ChuyenNganhDaoTaoModel chuyenNganhDaoTaoModelFromJson(String str) =>
    ChuyenNganhDaoTaoModel.fromJson(json.decode(str));

String chuyenNganhDaoTaoModelToJson(ChuyenNganhDaoTaoModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class ChuyenNganhDaoTaoModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ma")
  String? ma;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "idNganhDaoTao")
  String? idNganhDaoTao;
  @JsonKey(name: "guidDonVi")
  String? guidDonVi;

  ChuyenNganhDaoTaoModel({
    this.id,
    this.ma,
    this.ten,
    this.idNganhDaoTao,
    this.guidDonVi,
  });

  ChuyenNganhDaoTaoModel copyWith({
    String? id,
    String? ma,
    String? ten,
    String? idNganhDaoTao,
    String? guidDonVi,
  }) =>
      ChuyenNganhDaoTaoModel(
        id: id ?? this.id,
        ma: ma ?? this.ma,
        ten: ten ?? this.ten,
        idNganhDaoTao: idNganhDaoTao ?? this.idNganhDaoTao,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory ChuyenNganhDaoTaoModel.fromJson(Map<String, dynamic> json) =>
      _$ChuyenNganhDaoTaoModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChuyenNganhDaoTaoModelToJson(this);
}
