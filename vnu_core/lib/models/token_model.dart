// To parse this JSON data, do
//
//     final tokenModel = tokenModelFromJson(jsonString);

import 'dart:convert';

TokenModel tokenModelFromJson(String str) =>
    TokenModel.fromJson(json.decode(str));

String tokenModelToJson(TokenModel data) => json.encode(data.toJson());

class TokenModel {
  TokenModel({
    this.token,
    this.danhSachQuyen,
  });

  String? token;
  String? danhSachQuyen;

  factory TokenModel.fromJson(Map<String, dynamic> json) => TokenModel(
        token: json["Token"],
        danhSachQuyen: json["DanhSachQuyen"],
      );

  Map<String, dynamic> toJson() => {
        "Token": token,
        "DanhSachQuyen": danhSachQuyen,
      };
}
