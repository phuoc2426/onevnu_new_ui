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
        accessToken: _extractToken(json, const [
          'access_token',
          'accessToken',
          'token',
          'data.access_token',
          'data.accessToken',
          'data.token',
          'result.access_token',
          'result.token',
        ]),
        refreshToken: _extractToken(json, const [
          'refresh_token',
          'refreshToken',
          'data.refresh_token',
          'data.refreshToken',
          'result.refresh_token',
          'result.refreshToken',
        ]),
      );

  Map<String, dynamic> toJson() => {
        "accessToken": accessToken,
        "refreshToken": refreshToken,
      };
}

String? _extractToken(Map<String, dynamic> json, List<String> paths) {
  for (final path in paths) {
    dynamic current = json;
    for (final part in path.split('.')) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        current = null;
        break;
      }
    }

    if (current is String && current.trim().isNotEmpty) {
      return current.trim();
    }
  }

  return null;
}
