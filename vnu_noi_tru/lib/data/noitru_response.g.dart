// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'noitru_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoiTruResponse<T> _$NoiTruResponseFromJson<T>(Map<String, dynamic> json) =>
    NoiTruResponse<T>(
      resultCode: json['resultCode'] as String?,
      resultMessage: json['resultMessage'] as String?,
      data: _Converter<T>().fromJson(json['data'] as Object),
    );

Map<String, dynamic> _$NoiTruResponseToJson<T>(NoiTruResponse<T> instance) =>
    <String, dynamic>{
      'resultCode': instance.resultCode,
      'resultMessage': instance.resultMessage,
      'data': _Converter<T>().toJson(instance.data),
    };
