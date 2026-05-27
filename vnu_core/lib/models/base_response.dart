// To parse this JSON data, do
//
//     final baseResponse = baseResponseFromJson(jsonString);

import 'dart:convert';

BaseResponse baseResponseFromJson(String str) =>
    BaseResponse.fromJson(json.decode(str));

String baseResponseToJson(BaseResponse data) => json.encode(data.toJson());

class BaseResponse {
  BaseResponse();

  BaseResponse copyWith() => BaseResponse();

  factory BaseResponse.fromJson(Map<String, dynamic> json) => BaseResponse();

  Map<String, dynamic> toJson() => {};
}
