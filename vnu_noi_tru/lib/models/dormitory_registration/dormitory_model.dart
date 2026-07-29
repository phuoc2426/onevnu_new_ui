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

  const DormitoryListData({this.items = const <DormitoryModel>[]});

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

  /// Field cũ, giữ để tương thích response mobile cũ.
  final int? universityId;
  final String? universityName;

  /// Danh sách trường được phép đăng ký vào KTX này.
  final List<DormitoryUniversityModel> universities;

  final String? address;
  final int? provinceId;
  final int? wardId;
  final String? status;
  final String? image;

  const DormitoryModel({
    this.id,
    this.name,
    this.universityId,
    this.universityName,
    this.universities = const <DormitoryUniversityModel>[],
    this.address,
    this.provinceId,
    this.wardId,
    this.status,
    this.image,
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

    // Một số bản API cũ trả trực tiếp university_id/university_name.
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
      universityId: legacyUniversityId,
      universityName: legacyUniversityName,
      universities: List<DormitoryUniversityModel>.unmodifiable(
        parsedUniversities,
      ),
      address: _cleanString(json['address']),
      provinceId: _parseInt(json['province_id'] ?? json['provinceId']),
      wardId: _parseInt(json['ward_id'] ?? json['wardId']),
      status: _cleanString(json['status']),
      image: _cleanString(
        json['image'] ?? json['image_url'] ?? json['imageUrl'],
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'university_id': universityId,
        'university_name': universityName,
        'universities': universities
            .map((DormitoryUniversityModel item) => item.toJson())
            .toList(growable: false),
        'address': address,
        'province_id': provinceId,
        'ward_id': wardId,
        'status': status,
        'image': image,
      };
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

String? _cleanString(dynamic value) {
  if (value == null) return null;
  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}
