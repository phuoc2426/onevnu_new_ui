class RoomTypeListResponse {
  final bool? success;
  final RoomTypeListData? data;

  RoomTypeListResponse({this.success, this.data});

  factory RoomTypeListResponse.fromJson(Map<String, dynamic> json) {
    return RoomTypeListResponse(
      success: json['success'] as bool?,
      data: json['data'] is Map
          ? RoomTypeListData.fromJson(
              Map<String, dynamic>.from(json['data'] as Map),
            )
          : null,
    );
  }
}

class RoomTypeListData {
  final List<RoomTypeModel>? items;
  final int? page;
  final int? size;
  final int? totalElements;
  final int? totalPages;

  RoomTypeListData({
    this.items,
    this.page,
    this.size,
    this.totalElements,
    this.totalPages,
  });

  factory RoomTypeListData.fromJson(Map<String, dynamic> json) {
    return RoomTypeListData(
      items: json['items'] is List
          ? (json['items'] as List)
              .whereType<Map>()
              .map(
                (Map<dynamic, dynamic> item) => RoomTypeModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : <RoomTypeModel>[],
      page: _parseInt(json['page']),
      size: _parseInt(json['size']),
      totalElements: _parseInt(
        json['totalElements'] ?? json['total_elements'],
      ),
      totalPages: _parseInt(json['totalPages'] ?? json['total_pages']),
    );
  }
}

class RoomTypeModel {
  final int? id;
  final int? dormitoryId;
  final String? name;
  final String? color;
  final String? image;
  final List<dynamic> amenities;
  final List<dynamic> extraAmenities;
  final String? price;
  final bool feeEnabled;
  final String? description;
  final DateTime? deletedAt;
  final int? sortOrder;
  final String? priceUnit;

  /// Legacy fields kept for old mobile responses.
  final String? gender;
  final int? capacity;

  const RoomTypeModel({
    this.id,
    this.dormitoryId,
    this.name,
    this.color,
    this.image,
    this.amenities = const <dynamic>[],
    this.extraAmenities = const <dynamic>[],
    this.price,
    this.feeEnabled = false,
    this.description,
    this.deletedAt,
    this.sortOrder,
    this.priceUnit,
    this.gender,
    this.capacity,
  });

  factory RoomTypeModel.fromJson(Map<String, dynamic> json) {
    return RoomTypeModel(
      id: _parseInt(json['id']),
      dormitoryId: _parseInt(json['dormitory_id'] ?? json['dormitoryId']),
      name: _cleanString(json['name']),
      color: _cleanString(json['color']),
      image: _cleanString(json['image'] ?? json['image_url'] ?? json['imageUrl']),
      amenities: _asList(json['amenities']),
      extraAmenities: _asList(
        json['extra_amenities'] ?? json['extraAmenities'],
      ),
      price: _cleanString(json['price']),
      feeEnabled: _parseBool(json['fee_enabled'] ?? json['feeEnabled']),
      description: _cleanString(json['description']),
      deletedAt: _parseDateTime(json['deleted_at'] ?? json['deletedAt']),
      sortOrder: _parseInt(json['sort_order'] ?? json['sortOrder']),
      priceUnit: _cleanString(json['price_unit'] ?? json['priceUnit']),
      gender: _cleanString(json['gender']),
      capacity: _parseInt(json['capacity']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'dormitory_id': dormitoryId,
        'name': name,
        'color': color,
        'image': image,
        'amenities': amenities,
        'extra_amenities': extraAmenities,
        'price': price,
        'fee_enabled': feeEnabled,
        'description': description,
        'deleted_at': deletedAt?.toIso8601String(),
        'sort_order': sortOrder,
        'price_unit': priceUnit,
        'gender': gender,
        'capacity': capacity,
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

List<dynamic> _asList(dynamic value) {
  if (value is List) return List<dynamic>.from(value);
  if (value is Iterable && value is! String) return List<dynamic>.from(value);
  return const <dynamic>[];
}
