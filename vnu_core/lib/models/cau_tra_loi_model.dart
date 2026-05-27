// To parse this JSON data, do
//
//     final cauTraLoiModel = cauTraLoiModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'cau_tra_loi_model.g.dart';

CauTraLoiModel cauTraLoiModelFromJson(String str) =>
    CauTraLoiModel.fromJson(json.decode(str));

String cauTraLoiModelToJson(CauTraLoiModel data) => json.encode(data.toJson());

@JsonSerializable()
class CauTraLoiModel {
  @JsonKey(name: "guid")
  String? guid;
  @JsonKey(name: "cauHoi")
  String? cauHoi;
  @JsonKey(name: "guidChuDe")
  String? guidChuDe;
  @JsonKey(name: "tenChuDe")
  String? tenChuDe;
  @JsonKey(name: "tenFileDinhKem")
  String? tenFileDinhKem;
  @JsonKey(name: "guidFileDinhKems")
  List<String>? guidFileDinhKems;
  @JsonKey(name: "thoiGianGui")
  DateTime? thoiGianGui;
  @JsonKey(name: "tenNguoiTraLoi")
  String? tenNguoiTraLoi;
  @JsonKey(name: "thoiGianTraLoi")
  DateTime? thoiGianTraLoi;
  @JsonKey(name: "tenFileDinhKemTraLoi")
  String? tenFileDinhKemTraLoi;
  @JsonKey(name: "guidFileDinhKemsTraLoi")
  List<String>? guidFileDinhKemsTraLoi;
  @JsonKey(name: "traLoi")
  String? traLoi;

  CauTraLoiModel({
    this.guid,
    this.cauHoi,
    this.guidChuDe,
    this.tenChuDe,
    this.tenFileDinhKem,
    this.guidFileDinhKems,
    this.thoiGianGui,
    this.tenNguoiTraLoi,
    this.thoiGianTraLoi,
    this.tenFileDinhKemTraLoi,
    this.guidFileDinhKemsTraLoi,
    this.traLoi,
  });

  CauTraLoiModel copyWith({
    String? guid,
    String? cauHoi,
    String? guidChuDe,
    String? tenChuDe,
    String? tenFileDinhKem,
    List<String>? guidFileDinhKems,
    DateTime? thoiGianGui,
    String? tenNguoiTraLoi,
    DateTime? thoiGianTraLoi,
    String? tenFileDinhKemTraLoi,
    List<String>? guidFileDinhKemsTraLoi,
    String? traLoi,
  }) =>
      CauTraLoiModel(
        guid: guid ?? this.guid,
        cauHoi: cauHoi ?? this.cauHoi,
        guidChuDe: guidChuDe ?? this.guidChuDe,
        tenChuDe: tenChuDe ?? this.tenChuDe,
        tenFileDinhKem: tenFileDinhKem ?? this.tenFileDinhKem,
        guidFileDinhKems: guidFileDinhKems ?? this.guidFileDinhKems,
        thoiGianGui: thoiGianGui ?? this.thoiGianGui,
        tenNguoiTraLoi: tenNguoiTraLoi ?? this.tenNguoiTraLoi,
        thoiGianTraLoi: thoiGianTraLoi ?? this.thoiGianTraLoi,
        tenFileDinhKemTraLoi: tenFileDinhKemTraLoi ?? this.tenFileDinhKemTraLoi,
        guidFileDinhKemsTraLoi:
            guidFileDinhKemsTraLoi ?? this.guidFileDinhKemsTraLoi,
        traLoi: traLoi ?? this.traLoi,
      );

  factory CauTraLoiModel.fromJson(Map<String, dynamic> json) =>
      _$CauTraLoiModelFromJson(json);

  Map<String, dynamic> toJson() => _$CauTraLoiModelToJson(this);
}
