// To parse this JSON data, do
//
//     final taoLienKetDanhDauRequest = taoLienKetDanhDauRequestFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'tao_lien_ket_danh_dau_request.g.dart';

TaoLienKetDanhDauRequest taoLienKetDanhDauRequestFromJson(String str) =>
    TaoLienKetDanhDauRequest.fromJson(json.decode(str));

String taoLienKetDanhDauRequestToJson(TaoLienKetDanhDauRequest data) =>
    json.encode(data.toJson());

@JsonSerializable()
class TaoLienKetDanhDauRequest {
  @JsonKey(name: "lienKet")
  String? lienKet;
  @JsonKey(name: "tenLienKet")
  String? tenLienKet;

  TaoLienKetDanhDauRequest({
    this.lienKet,
    this.tenLienKet,
  });

  TaoLienKetDanhDauRequest copyWith({
    String? lienKet,
    String? tenLienKet,
  }) =>
      TaoLienKetDanhDauRequest(
        lienKet: lienKet ?? this.lienKet,
        tenLienKet: tenLienKet ?? this.tenLienKet,
      );

  factory TaoLienKetDanhDauRequest.fromJson(Map<String, dynamic> json) =>
      _$TaoLienKetDanhDauRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TaoLienKetDanhDauRequestToJson(this);
}
