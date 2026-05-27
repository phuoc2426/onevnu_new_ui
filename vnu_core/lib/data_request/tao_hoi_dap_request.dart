// To parse this JSON data, do
//
//     final taoThuTucMotCuaRequest = taoThuTucMotCuaRequestFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'tao_hoi_dap_request.g.dart';

TaoHoiDapRequest taoThuTucMotCuaRequestFromJson(String str) =>
    TaoHoiDapRequest.fromJson(json.decode(str));

String taoThuTucMotCuaRequestToJson(TaoHoiDapRequest data) =>
    json.encode(data.toJson());

@JsonSerializable()
class TaoHoiDapRequest {
  @JsonKey(name: "guidChuDe")
  String? guidChuDe;
  @JsonKey(name: "guidFileDinhKems")
  List<String>? guidFileDinhKems;
  @JsonKey(name: "cauHoi")
  String? cauHoi;

  TaoHoiDapRequest({
    this.guidChuDe,
    this.guidFileDinhKems,
    this.cauHoi,
  });

  TaoHoiDapRequest copyWith({
    String? guidChuDe,
    List<String>? guidFileDinhKems,
    String? cauHoi,
  }) =>
      TaoHoiDapRequest(
        guidChuDe: guidChuDe ?? this.guidChuDe,
        guidFileDinhKems: guidFileDinhKems ?? this.guidFileDinhKems,
        cauHoi: cauHoi ?? this.cauHoi,
      );

  factory TaoHoiDapRequest.fromJson(Map<String, dynamic> json) =>
      _$TaoHoiDapRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TaoHoiDapRequestToJson(this);
}
