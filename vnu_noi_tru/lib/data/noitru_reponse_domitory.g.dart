// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'noitru_reponse_domitory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoitruResponseDomitory<T> _$NoitruResponseDomitoryFromJson<T>(
  Map<String, dynamic> json,
) => NoitruResponseDomitory<T>(
  resultCode: (json['resultCode'] as num?)?.toInt(),
  resultMessage: json['resultMessage'] as String?,
  data: _Converter<T>().fromJson(json['data'] as Object),
);

Map<String, dynamic> _$NoitruResponseDomitoryToJson<T>(
  NoitruResponseDomitory<T> instance,
) => <String, dynamic>{
  'resultCode': instance.resultCode,
  'resultMessage': instance.resultMessage,
  'data': _Converter<T>().toJson(instance.data),
};
