class PriorityObjectListResponse {
  final bool? success;
  final PriorityObjectListData? data;

  PriorityObjectListResponse({this.success, this.data});

  factory PriorityObjectListResponse.fromJson(Map<String, dynamic> json) {
    return PriorityObjectListResponse(
      success: json['success'] as bool?,
      data: json['data'] != null
          ? PriorityObjectListData.fromJson(json['data'])
          : null,
    );
  }
}

class PriorityObjectListData {
  final List<PriorityObjectModel>? items;

  PriorityObjectListData({this.items});

  factory PriorityObjectListData.fromJson(Map<String, dynamic> json) {
    return PriorityObjectListData(
      items: json['items'] != null
          ? (json['items'] as List)
                .map(
                  (e) =>
                      PriorityObjectModel.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
    );
  }
}

class PriorityObjectModel {
  final int? id;
  final String? name;
  final String? description;

  PriorityObjectModel({this.id, this.name, this.description});

  factory PriorityObjectModel.fromJson(Map<String, dynamic> json) {
    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return PriorityObjectModel(
      id: _parseInt(json['id']),
      name: json['name'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };
}
