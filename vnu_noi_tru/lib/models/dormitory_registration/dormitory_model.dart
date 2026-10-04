class DormitoryListResponse {
  final bool? success;
  final DormitoryListData? data;

  const DormitoryListResponse({this.success, this.data});

  factory DormitoryListResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];

    return DormitoryListResponse(
      success: json['success'] as bool?,
      data: rawData is Map
          ? DormitoryListData.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }
}

class DormitoryListData {
  final List<DormitoryModel> items;
  final int? page;
  final int? size;
  final int? totalElements;
  final int? totalPages;

  const DormitoryListData({
    this.items = const <DormitoryModel>[],
    this.page,
    this.size,
    this.totalElements,
    this.totalPages,
  });

  factory DormitoryListData.fromJson(Map<String, dynamic> json) {
    final dynamic rawItems = json['items'];

    return DormitoryListData(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (Map<dynamic, dynamic> item) => DormitoryModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
          : const <DormitoryModel>[],
      page: _parseInt(json['page']),
      size: _parseInt(json['size']),
      totalElements: _parseInt(
        json['totalElements'] ?? json['total_elements'],
      ),
      totalPages: _parseInt(json['totalPages'] ?? json['total_pages']),
    );
  }
}

class DormitoryUniversityModel {
  final int? univId;
  final String? name;
  final String? englishName;
  final String? abbreviation;

  const DormitoryUniversityModel({
    this.univId,
    this.name,
    this.englishName,
    this.abbreviation,
  });

  factory DormitoryUniversityModel.fromJson(Map<String, dynamic> json) {
    return DormitoryUniversityModel(
      univId: _parseInt(
        json['univ_id'] ??
            json['univId'] ??
            json['university_id'] ??
            json['universityId'] ??
            json['id'],
      ),
      name: _cleanString(
        json['name'] ??
            json['university_name'] ??
            json['universityName'] ??
            json['ten_don_vi'] ??
            json['tenDonVi'],
      ),
      englishName: _cleanString(
        json['english_name'] ?? json['englishName'] ?? json['name_en'],
      ),
      abbreviation: _cleanString(
        json['abbreviation'] ??
            json['short_name'] ??
            json['shortName'] ??
            json['code'],
      ),
    );
  }

  List<String> get comparableNames => <String>[
        if ((name ?? '').trim().isNotEmpty) name!.trim(),
        if ((englishName ?? '').trim().isNotEmpty) englishName!.trim(),
        if ((abbreviation ?? '').trim().isNotEmpty) abbreviation!.trim(),
      ];

  Map<String, dynamic> toJson() => <String, dynamic>{
        'univ_id': univId,
        'name': name,
        'english_name': englishName,
        'abbreviation': abbreviation,
      };
}

class DormitoryModel {
  final int? id;
  final String? name;
  final String? code;

  /// Field cũ, giữ để tương thích response mobile cũ.
  final int? universityId;
  final String? universityName;

  /// Danh sách trường được phép đăng ký vào KTX này ở các bản API cũ/mở rộng.
  final List<DormitoryUniversityModel> universities;

  final String? address;

  /// Contract KTX mới dùng province_code / ward_code dạng chuỗi.
  final String? provinceCode;
  final String? wardCode;

  /// Legacy compatibility: một số response cũ trả id số.
  final int? provinceId;
  final int? wardId;

  final String? status;
  final String? image;
  final DateTime? deletedAt;

  /// Phí nhập ở và SLA duyệt hồ sơ theo OpenAPI KTX mới.
  final int? admissionFee;
  final bool admissionFeeEnabled;
  final int? approvalDueDays;

  const DormitoryModel({
    this.id,
    this.name,
    this.code,
    this.universityId,
    this.universityName,
    this.universities = const <DormitoryUniversityModel>[],
    this.address,
    this.provinceCode,
    this.wardCode,
    this.provinceId,
    this.wardId,
    this.status,
    this.image,
    this.deletedAt,
    this.admissionFee,
    this.admissionFeeEnabled = false,
    this.approvalDueDays,
  });

  factory DormitoryModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawUniversities =
        json['universities'] ?? json['university_list'] ?? json['universityList'];

    final List<DormitoryUniversityModel> parsedUniversities =
        <DormitoryUniversityModel>[];

    if (rawUniversities is List) {
      parsedUniversities.addAll(
        rawUniversities.whereType<Map>().map(
              (Map<dynamic, dynamic> item) => DormitoryUniversityModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            ),
      );
    } else if (rawUniversities is Map) {
      parsedUniversities.add(
        DormitoryUniversityModel.fromJson(
          Map<String, dynamic>.from(rawUniversities),
        ),
      );
    }

    final int? legacyUniversityId = _parseInt(
      json['university_id'] ?? json['universityId'] ?? json['univ_id'],
    );
    final String? legacyUniversityName = _cleanString(
      json['university_name'] ?? json['universityName'],
    );

    if (parsedUniversities.isEmpty &&
        (legacyUniversityId != null ||
            (legacyUniversityName ?? '').trim().isNotEmpty)) {
      parsedUniversities.add(
        DormitoryUniversityModel(
          univId: legacyUniversityId,
          name: legacyUniversityName,
        ),
      );
    }

    return DormitoryModel(
      id: _parseInt(json['id']),
      name: _cleanString(json['name']),
      code: _cleanString(json['code']),
      universityId: legacyUniversityId,
      universityName: legacyUniversityName,
      universities: List<DormitoryUniversityModel>.unmodifiable(
        parsedUniversities,
      ),
      address: _cleanString(json['address']),
      provinceCode: _cleanString(
        json['province_code'] ?? json['provinceCode'],
      ),
      wardCode: _cleanString(json['ward_code'] ?? json['wardCode']),
      provinceId: _parseInt(json['province_id'] ?? json['provinceId']),
      wardId: _parseInt(json['ward_id'] ?? json['wardId']),
      status: _cleanString(json['status']),
      image: _cleanString(
        json['image'] ?? json['image_url'] ?? json['imageUrl'],
      ),
      deletedAt: _parseDateTime(json['deleted_at'] ?? json['deletedAt']),
      admissionFee: _parseInt(json['admission_fee'] ?? json['admissionFee']),
      admissionFeeEnabled: _parseBool(
        json['admission_fee_enabled'] ?? json['admissionFeeEnabled'],
      ),
      approvalDueDays: _parseInt(
        json['approval_due_days'] ?? json['approvalDueDays'],
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'code': code,
        'university_id': universityId,
        'university_name': universityName,
        'universities': universities
            .map((DormitoryUniversityModel item) => item.toJson())
            .toList(growable: false),
        'address': address,
        'province_code': provinceCode,
        'ward_code': wardCode,
        'province_id': provinceId,
        'ward_id': wardId,
        'status': status,
        'image': image,
        'deleted_at': deletedAt?.toIso8601String(),
        'admission_fee': admissionFee,
        'admission_fee_enabled': admissionFeeEnabled,
        'approval_due_days': approvalDueDays,
      };
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final String normalized = value?.toString().trim().toLowerCase() ?? '';
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String? _cleanString(dynamic value) {
  if (value == null) return null;
  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}
