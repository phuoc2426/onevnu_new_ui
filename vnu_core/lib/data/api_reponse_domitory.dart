import 'dart:convert';
import 'dart:core';
import 'package:vnu_core/models/login_reponse_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vnu_core/models/token_model.dart';

import '../models/model.dart';
part 'api_reponse_domitory.g.dart';

@JsonSerializable()
class APIResponseDomitory<T> {
  final int? resultCode;
  final String? resultMessage;
  @_Converter()
  final T data;

  APIResponseDomitory(
      {this.resultCode, this.resultMessage, required this.data});

  factory APIResponseDomitory.fromJson(Map<String, dynamic> json) =>
      _$APIResponseDomitoryFromJson(json);
  Map<String, dynamic> toJson() => _$APIResponseDomitoryToJson(this);
}

class _Converter<T> implements JsonConverter<T, Object> {
  const _Converter();

  @override
  fromJson(Object? json) {
    if (T == LoginResponseModel) {
      return LoginResponseModel.fromJson(json as Map<String, dynamic>) as T;
    }
    if (T == TokenModel) {
      return TokenModel.fromJson(json as Map<String, dynamic>) as T;
    }
    if (T == ThongTinSinhVienModel) {
      return ThongTinSinhVienModel.fromJson(json as Map<String, dynamic>) as T;
    }

    if (T == bool) {
      return json as T;
    }
    if (T == dynamic) {
      return json as dynamic;
    }
    if (T == String) {
      return json as T;
    }
    return {} as T;
  }

  @override
  Object toJson(T? object) {
    return json.encode(object);
  }
}
