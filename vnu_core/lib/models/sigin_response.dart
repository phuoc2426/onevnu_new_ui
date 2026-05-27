// To parse this JSON data, do
//
//     final signinResponse = signinResponseFromJson(jsonString);

import 'dart:convert';

SigninResponse signinResponseFromJson(String str) =>
    SigninResponse.fromJson(json.decode(str));

String signinResponseToJson(SigninResponse data) => json.encode(data.toJson());

class SigninResponse {
  final String? accessToken;
  final String? refreshToken;

  SigninResponse({
    this.accessToken,
    this.refreshToken,
  });

  SigninResponse copyWith({
    String? accessToken,
    String? refreshToken,
  }) =>
      SigninResponse(
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
      );

  factory SigninResponse.fromJson(Map<String, dynamic> json) => SigninResponse(
        accessToken: json["accessToken"],
        refreshToken: json["refreshToken"],
      );

  Map<String, dynamic> toJson() => {
        "accessToken": accessToken,
        "refreshToken": refreshToken,
      };
}
