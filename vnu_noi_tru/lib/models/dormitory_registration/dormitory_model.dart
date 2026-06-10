class DormitoryListResponse {
  final bool? success;
  final DormitoryListData? data;

  DormitoryListResponse({this.success, this.data});

  factory DormitoryListResponse.fromJson(Map<String, dynamic> json) {
    return DormitoryListResponse(
      success: json['success'] as bool?,
      data: json['data'] != null
          ? DormitoryListData.fromJson(json['data'])
          : null,
    );
  }
}

class DormitoryListData {
  final List<DormitoryModel>? items;

  DormitoryListData({this.items});

  factory DormitoryListData.fromJson(Map<String, dynamic> json) {
    return DormitoryListData(
      items: json['items'] != null
          ? (json['items'] as List)
                .map((e) => DormitoryModel.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }
}

class DormitoryModel {
  final int? id;
  final String? name;
  final int? universityId;
  final String? address;
  final int? provinceId;
  final int? wardId;
  final String? status;

  DormitoryModel({
    this.id,
    this.name,
    this.universityId,
    this.address,
    this.provinceId,
    this.wardId,
    this.status,
  });

  factory DormitoryModel.fromJson(Map<String, dynamic> json) {
    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return DormitoryModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString(),
      universityId: _parseInt(json['university_id'] ?? json['universityId']),
      address: json['address']?.toString(),
      provinceId: _parseInt(json['province_id'] ?? json['provinceId']),
      wardId: _parseInt(json['ward_id'] ?? json['wardId']),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'university_id': universityId,
    'address': address,
    'province_id': provinceId,
    'ward_id': wardId,
    'status': status,
  };
}
