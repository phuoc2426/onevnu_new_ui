// To parse this JSON data, do
//
//     final chuongTrinhDaoTaoModel = chuongTrinhDaoTaoModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'chuong_trinh_dao_tao_model.g.dart';

ChuongTrinhDaoTaoModel chuongTrinhDaoTaoModelFromJson(String str) =>
    ChuongTrinhDaoTaoModel.fromJson(json.decode(str));

String chuongTrinhDaoTaoModelToJson(ChuongTrinhDaoTaoModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class ChuongTrinhDaoTaoModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "ma")
  String? ma;
  @JsonKey(name: "ten")
  String? ten;
  @JsonKey(name: "idHeDaoTao")
  String? idHeDaoTao;
  @JsonKey(name: "idNganhDaoTao")
  String? idNganhDaoTao;
  @JsonKey(name: "idNienKhoaDaoTao")
  String? idNienKhoaDaoTao;
  @JsonKey(name: "idBacDaoTao")
  String? idBacDaoTao;
  @JsonKey(name: "guidDonVi")
  String? guidDonVi;

  ChuongTrinhDaoTaoModel({
    this.id,
    this.ma,
    this.ten,
    this.idHeDaoTao,
    this.idNganhDaoTao,
    this.idNienKhoaDaoTao,
    this.idBacDaoTao,
    this.guidDonVi,
  });

  ChuongTrinhDaoTaoModel copyWith({
    String? id,
    String? ma,
    String? ten,
    String? idHeDaoTao,
    String? idNganhDaoTao,
    String? idNienKhoaDaoTao,
    String? idBacDaoTao,
    String? guidDonVi,
  }) =>
      ChuongTrinhDaoTaoModel(
        id: id ?? this.id,
        ma: ma ?? this.ma,
        ten: ten ?? this.ten,
        idHeDaoTao: idHeDaoTao ?? this.idHeDaoTao,
        idNganhDaoTao: idNganhDaoTao ?? this.idNganhDaoTao,
        idNienKhoaDaoTao: idNienKhoaDaoTao ?? this.idNienKhoaDaoTao,
        idBacDaoTao: idBacDaoTao ?? this.idBacDaoTao,
        guidDonVi: guidDonVi ?? this.guidDonVi,
      );

  factory ChuongTrinhDaoTaoModel.fromJson(Map<String, dynamic> json) =>
      _$ChuongTrinhDaoTaoModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChuongTrinhDaoTaoModelToJson(this);
}
