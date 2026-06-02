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
  final String? address;
  final String? status;

  DormitoryModel({this.id, this.name, this.address, this.status});

  factory DormitoryModel.fromJson(Map<String, dynamic> json) {
    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return DormitoryModel(
      id: _parseInt(json['id']),
      name: json['name'] as String?,
      address: json['address'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'status': status,
  };
}
