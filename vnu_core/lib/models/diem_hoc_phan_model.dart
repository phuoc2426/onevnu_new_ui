// To parse this JSON data, do
//
//     final diemHocPhanModel = diemHocPhanModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'diem_hoc_phan_model.g.dart';

DiemHocPhanModel diemHocPhanModelFromJson(String str) =>
    DiemHocPhanModel.fromJson(json.decode(str));

String diemHocPhanModelToJson(DiemHocPhanModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class DiemHocPhanModel {
  @JsonKey(name: "trongSo")
  String? trongSo;
  @JsonKey(name: "diemHe10")
  String? diemHe10;
  @JsonKey(name: "loaiDiemHocPhan")
  String? loaiDiemHocPhan;

  DiemHocPhanModel({
    this.trongSo,
    this.diemHe10,
    this.loaiDiemHocPhan,
  });

  DiemHocPhanModel copyWith({
    String? trongSo,
    String? diemHe10,
    String? loaiDiemHocPhan,
  }) =>
      DiemHocPhanModel(
        trongSo: trongSo ?? this.trongSo,
        diemHe10: diemHe10 ?? this.diemHe10,
        loaiDiemHocPhan: loaiDiemHocPhan ?? this.loaiDiemHocPhan,
      );

  factory DiemHocPhanModel.fromJson(Map<String, dynamic> json) =>
      _$DiemHocPhanModelFromJson(json);

  Map<String, dynamic> toJson() => _$DiemHocPhanModelToJson(this);
}
