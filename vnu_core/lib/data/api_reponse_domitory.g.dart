// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_reponse_domitory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIResponseDomitory<T> _$APIResponseDomitoryFromJson<T>(
        Map<String, dynamic> json) =>
    APIResponseDomitory<T>(
      resultCode: (json['resultCode'] as num?)?.toInt(),
      resultMessage: json['resultMessage'] as String?,
      data: _Converter<T>().fromJson(json['data'] as Object),
    );

Map<String, dynamic> _$APIResponseDomitoryToJson<T>(
        APIResponseDomitory<T> instance) =>
    <String, dynamic>{
      'resultCode': instance.resultCode,
      'resultMessage': instance.resultMessage,
      'data': _Converter<T>().toJson(instance.data),
    };
