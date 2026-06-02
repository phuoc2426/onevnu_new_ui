class UploadedAttachmentListResponse {
  final bool? success;
  final List<UploadedAttachmentModel>? data;

  UploadedAttachmentListResponse({this.success, this.data});

  factory UploadedAttachmentListResponse.fromJson(Map<String, dynamic> json) {
    return UploadedAttachmentListResponse(
      success: json['success'] as bool?,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => UploadedAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class UploadedAttachmentModel {
  final Object? id;
  final String? name; // CCCD.jpg or file_name
  final String? path; // upload/CCCD.jpg or file_path
  final String? type; // cccd_front, cccd_back, proof

  UploadedAttachmentModel({
    this.id,
    this.name,
    this.path,
    this.type,
  });

  factory UploadedAttachmentModel.fromJson(Map<String, dynamic> json) {
    final id = _normalizeAttachmentId(json['id']);
    return UploadedAttachmentModel(
      id: id,
      name: (json['name'] ?? json['file_name']) as String?,
      path: (json['path'] ?? json['file_path']) as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'type': type,
      };
}

Object? _normalizeAttachmentId(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  final text = value.toString();
  return int.tryParse(text) ?? text;
}
