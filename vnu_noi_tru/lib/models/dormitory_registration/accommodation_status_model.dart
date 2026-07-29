class DormitoryAccommodationStatusModel {
  final String code;
  final String slug;
  final String label;
  final String color;

  const DormitoryAccommodationStatusModel({
    required this.code,
    required this.slug,
    required this.label,
    required this.color,
  });

  factory DormitoryAccommodationStatusModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DormitoryAccommodationStatusModel(
      code: json['code']?.toString().trim() ?? '',
      slug: json['slug']?.toString().trim().toLowerCase() ?? '',
      label: json['label']?.toString().trim() ?? '',
      color: json['color']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'slug': slug,
      'label': label,
      'color': color,
    };
  }

  bool matches(String value) {
    final String normalized = value.trim().toLowerCase();

    if (normalized.isEmpty) {
      return false;
    }

    return code.toLowerCase() == normalized ||
        slug.toLowerCase() == normalized;
  }

  bool get allowsAccommodationRequest {
    return slug == 'assigned' || slug == 'active';
  }
}
