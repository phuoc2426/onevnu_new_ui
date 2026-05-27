// To parse this JSON data, do
//
//     final loginResponseModel = loginResponseModelFromJson(jsonString);

import 'dart:convert';

LoginResponseModel loginResponseModelFromJson(String str) =>
    LoginResponseModel.fromJson(json.decode(str));

String loginResponseModelToJson(LoginResponseModel data) =>
    json.encode(data.toJson());

class LoginResponseModel {
  LoginResponseModel({
    this.errorCode,
    this.message,
    this.data,
    this.isError,
    this.exception,
  });

  int? errorCode;
  String? message;
  String? data;
  bool? isError;
  dynamic exception;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        errorCode: json["ErrorCode"],
        message: json["Message"],
        data: json["Data"],
        isError: json["IsError"],
        exception: json["Exception"],
      );

  Map<String, dynamic> toJson() => {
        "ErrorCode": errorCode,
        "Message": message,
        "Data": data,
        "IsError": isError,
        "Exception": exception,
      };
}
