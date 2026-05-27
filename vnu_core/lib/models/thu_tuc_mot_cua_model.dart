// To parse this JSON data, do
//
//     final thuTucMotCuaModel = thuTucMotCuaModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'thu_tuc_mot_cua_model.g.dart';

ThuTucMotCuaModel thuTucMotCuaModelFromJson(String str) =>
    ThuTucMotCuaModel.fromJson(json.decode(str));

String thuTucMotCuaModelToJson(ThuTucMotCuaModel data) =>
    json.encode(data.toJson());

@JsonSerializable()
class ThuTucMotCuaModel {
  @JsonKey(name: "guidLinhVuc")
  String? guidLinhVuc;
  @JsonKey(name: "tenThuTuc")
  String? tenThuTuc;
  @JsonKey(name: "htmlNoiDung")
  String? htmlNoiDung;
  @JsonKey(name: "tenLinhVuc")
  String? tenLinhVuc;
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "thanhPhanHoSo")
  List<ThanhPhanHoSo>? thanhPhanHoSo;

  ThuTucMotCuaModel({
    this.guidLinhVuc,
    this.tenThuTuc,
    this.htmlNoiDung,
    this.tenLinhVuc,
    this.guid,
    this.thanhPhanHoSo,
  });

  ThuTucMotCuaModel copyWith({
    String? guidLinhVuc,
    String? tenThuTuc,
    String? htmlNoiDung,
    String? tenLinhVuc,
    String? guid,
    List<ThanhPhanHoSo>? thanhPhanHoSo,
  }) =>
      ThuTucMotCuaModel(
        guidLinhVuc: guidLinhVuc ?? this.guidLinhVuc,
        tenThuTuc: tenThuTuc ?? this.tenThuTuc,
        htmlNoiDung: htmlNoiDung ?? this.htmlNoiDung,
        tenLinhVuc: tenLinhVuc ?? this.tenLinhVuc,
        guid: guid ?? this.guid,
        thanhPhanHoSo: thanhPhanHoSo ?? this.thanhPhanHoSo,
      );

  factory ThuTucMotCuaModel.fromJson(Map<String, dynamic> json) =>
      _$ThuTucMotCuaModelFromJson(json);

  Map<String, dynamic> toJson() => _$ThuTucMotCuaModelToJson(this);
}

@JsonSerializable()
class ThanhPhanHoSo {
  @JsonKey(name: "tenHoSo")
  String? tenHoSo;
  @JsonKey(name: "tenFileDinhKem")
  String? tenFileDinhKem;
  @JsonKey(name: "guidFileDinhKems")
  List<String>? guidFileDinhKems;

  ThanhPhanHoSo({
    this.tenHoSo,
    this.tenFileDinhKem,
    this.guidFileDinhKems,
  });

  ThanhPhanHoSo copyWith({
    String? tenHoSo,
    String? tenFileDinhKem,
    List<String>? guidFileDinhKems,
  }) =>
      ThanhPhanHoSo(
        tenHoSo: tenHoSo ?? this.tenHoSo,
        tenFileDinhKem: tenFileDinhKem ?? this.tenFileDinhKem,
        guidFileDinhKems: guidFileDinhKems ?? this.guidFileDinhKems,
      );

  factory ThanhPhanHoSo.fromJson(Map<String, dynamic> json) =>
      _$ThanhPhanHoSoFromJson(json);

  Map<String, dynamic> toJson() => _$ThanhPhanHoSoToJson(this);
}
