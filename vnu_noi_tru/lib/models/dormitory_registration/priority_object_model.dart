class PriorityObjectListResponse {
  final bool? success;
  final PriorityObjectListData? data;

  PriorityObjectListResponse({this.success, this.data});

  factory PriorityObjectListResponse.fromJson(Map<String, dynamic> json) {
    return PriorityObjectListResponse(
      success: json['success'] as bool?,
      data: json['data'] is Map
          ? PriorityObjectListData.fromJson(
              Map<String, dynamic>.from(json['data'] as Map),
            )
          : null,
    );
  }
}

class PriorityObjectListData {
  final List<PriorityObjectModel>? items;
  final int? page;
  final int? size;
  final int? totalElements;
  final int? totalPages;

  PriorityObjectListData({
    this.items,
    this.page,
    this.size,
    this.totalElements,
    this.totalPages,
  });

  factory PriorityObjectListData.fromJson(Map<String, dynamic> json) {
    return PriorityObjectListData(
      items: json['items'] is List
          ? (json['items'] as List)
              .whereType<Map>()
              .map(
                (Map<dynamic, dynamic> item) => PriorityObjectModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : <PriorityObjectModel>[],
      page: _parseInt(json['page']),
      size: _parseInt(json['size']),
      totalElements: _parseInt(
        json['totalElements'] ?? json['total_elements'],
      ),
      totalPages: _parseInt(json['totalPages'] ?? json['total_pages']),
    );
  }
}

class PriorityObjectModel {
  final int? id;
  final String? name;
  final String? description;
  final int? priorityScore;
  final DateTime? deletedAt;

  const PriorityObjectModel({
    this.id,
    this.name,
    this.description,
    this.priorityScore,
    this.deletedAt,
  });

  factory PriorityObjectModel.fromJson(Map<String, dynamic> json) {
    return PriorityObjectModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      priorityScore: _parseInt(
        json['priority_score'] ?? json['priorityScore'],
      ),
      deletedAt: _parseDateTime(json['deleted_at'] ?? json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'priority_score': priorityScore,
        'deleted_at': deletedAt?.toIso8601String(),
      };
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
