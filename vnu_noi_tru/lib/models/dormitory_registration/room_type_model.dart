class RoomTypeListResponse {
  final bool? success;
  final RoomTypeListData? data;

  RoomTypeListResponse({this.success, this.data});

  factory RoomTypeListResponse.fromJson(Map<String, dynamic> json) {
    return RoomTypeListResponse(
      success: json['success'] as bool?,
      data: json['data'] != null
          ? RoomTypeListData.fromJson(json['data'])
          : null,
    );
  }
}

class RoomTypeListData {
  final List<RoomTypeModel>? items;

  RoomTypeListData({this.items});

  factory RoomTypeListData.fromJson(Map<String, dynamic> json) {
    return RoomTypeListData(
      items: json['items'] != null
          ? (json['items'] as List)
                .map((e) => RoomTypeModel.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }
}

class RoomTypeModel {
  final int? id;
  final String? name;
  final String? gender;
  final int? capacity;
  final String? price; // e.g. "800000"
  final String? description;

  RoomTypeModel({
    this.id,
    this.name,
    this.gender,
    this.capacity,
    this.price,
    this.description,
  });

  factory RoomTypeModel.fromJson(Map<String, dynamic> json) {
    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return RoomTypeModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString(),
      gender: json['gender']?.toString(),
      capacity: _parseInt(json['capacity']),
      price: json['price']?.toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gender': gender,
    'capacity': capacity,
    'price': price,
    'description': description,
  };
}
