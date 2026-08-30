class DormitoryCountryOption {
  final String code;
  final String name;
  final String? isoAlpha3;
  final String? telephonePrefix;

  const DormitoryCountryOption({
    required this.code,
    required this.name,
    this.isoAlpha3,
    this.telephonePrefix,
  });

  factory DormitoryCountryOption.fromJson(Map<String, dynamic> json) {
    return DormitoryCountryOption(
      code: json['code']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      isoAlpha3: json['isoAlpha3']?.toString(),
      telephonePrefix: json['telephonePrefix']?.toString(),
    );
  }

  String get label => name.isEmpty ? code.toUpperCase() : name;
}

class DormitoryProvinceOption {
  final int id;
  final int? countryId;
  final String code;
  final String name;

  const DormitoryProvinceOption({
    required this.id,
    this.countryId,
    required this.code,
    required this.name,
  });

  factory DormitoryProvinceOption.fromJson(Map<String, dynamic> json) {
    return DormitoryProvinceOption(
      id: _asInt(json['id']) ?? 0,
      countryId: _asInt(json['country_id'] ?? json['countryId']),
      code: (json['province_code'] ?? json['provinceCode'])
              ?.toString()
              .trim() ??
          '',
      name: (json['province_name'] ?? json['provinceName'])
              ?.toString()
              .trim() ??
          '',
    );
  }

  String get label => name.isEmpty ? code : name;
}

class DormitoryWardOption {
  final int id;
  final int? countryId;
  final int? provinceId;
  final String code;
  final String name;

  const DormitoryWardOption({
    required this.id,
    this.countryId,
    this.provinceId,
    required this.code,
    required this.name,
  });

  factory DormitoryWardOption.fromJson(Map<String, dynamic> json) {
    return DormitoryWardOption(
      id: _asInt(json['id']) ?? 0,
      countryId: _asInt(json['country_id'] ?? json['countryId']),
      provinceId: _asInt(json['province_id'] ?? json['provinceId']),
      code: (json['ward_code'] ?? json['wardCode'])?.toString().trim() ?? '',
      name: (json['ward_name'] ?? json['wardName'])?.toString().trim() ?? '',
    );
  }

  String get label => name.isEmpty ? code : name;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
