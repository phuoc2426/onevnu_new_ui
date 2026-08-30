class KtxIssueAccommodationContext {
  final int dormitoryId;
  final int roomId;
  final String status;
  final String accommodationId;

  const KtxIssueAccommodationContext({
    required this.dormitoryId,
    required this.roomId,
    required this.status,
    this.accommodationId = '',
  });

  bool get isValid => dormitoryId > 0 && roomId > 0;
}

class KtxIssueOption {
  final int value;
  final String label;

  const KtxIssueOption({
    required this.value,
    required this.label,
  });

  factory KtxIssueOption.fromJson(Map<String, dynamic> json) {
    return KtxIssueOption(
      value: _asInt(json['value']) ?? 0,
      label: _asString(json['label']),
    );
  }
}

class KtxIssueMeta {
  final List<KtxIssueOption> types;
  final List<KtxIssueOption> priorities;

  const KtxIssueMeta({
    this.types = const <KtxIssueOption>[],
    this.priorities = const <KtxIssueOption>[],
  });

  factory KtxIssueMeta.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'] ?? json;
    if (data is! Map) {
      return const KtxIssueMeta();
    }

    return KtxIssueMeta(
      types: _asMapList(data['types'])
          .map(KtxIssueOption.fromJson)
          .where((KtxIssueOption item) => item.value > 0)
          .toList(),
      priorities: _asMapList(data['priorities'])
          .map(KtxIssueOption.fromJson)
          .where((KtxIssueOption item) => item.value > 0)
          .toList(),
    );
  }

  String typeLabel(int? value) {
    if (value == null) return '';
    for (final KtxIssueOption item in types) {
      if (item.value == value) return item.label;
    }
    return '';
  }

  String priorityLabel(int? value) {
    if (value == null) return '';
    for (final KtxIssueOption item in priorities) {
      if (item.value == value) return item.label;
    }
    return '';
  }
}

class KtxIssueComment {
  final int id;
  final String comment;
  final bool fromStudent;
  final String senderName;
  final DateTime? createdAt;

  const KtxIssueComment({
    required this.id,
    required this.comment,
    required this.fromStudent,
    required this.senderName,
    this.createdAt,
  });

  factory KtxIssueComment.fromJson(Map<String, dynamic> json) {
    final bool fromStudent =
        _asBool(json['from_student']) ?? json['student_id'] != null;

    return KtxIssueComment(
      id: _asInt(json['id']) ?? 0,
      comment: _asString(json['comment']),
      fromStudent: fromStudent,
      senderName: _asString(json['sender_name']).isNotEmpty
          ? _asString(json['sender_name'])
          : (fromStudent ? 'Sinh viên' : 'Cán bộ KTX'),
      createdAt: _asDate(json['created_at']),
    );
  }
}

class KtxIssue {
  final int id;
  final int? dormitoryId;
  final int? studentId;
  final int? roomId;
  final String title;
  final String description;
  final int? type;
  final String typeLabel;
  final int? priority;
  final String priorityLabel;
  final int? status;
  final String statusLabel;
  final int? assignedTo;
  final double? latitude;
  final double? longitude;
  final String address;
  final String mapUrl;
  final List<String> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<KtxIssueComment> comments;

  const KtxIssue({
    required this.id,
    this.dormitoryId,
    this.studentId,
    this.roomId,
    required this.title,
    required this.description,
    this.type,
    this.typeLabel = '',
    this.priority,
    this.priorityLabel = '',
    this.status,
    this.statusLabel = '',
    this.assignedTo,
    this.latitude,
    this.longitude,
    this.address = '',
    this.mapUrl = '',
    this.images = const <String>[],
    this.createdAt,
    this.updatedAt,
    this.comments = const <KtxIssueComment>[],
  });

  factory KtxIssue.fromJson(Map<String, dynamic> json) {
    final List<KtxIssueComment> comments = _asMapList(json['comments'])
        .map(KtxIssueComment.fromJson)
        .toList();

    return KtxIssue(
      id: _asInt(json['id']) ?? 0,
      dormitoryId: _asInt(json['dormitory_id'] ?? json['dormitoryId']),
      studentId: _asInt(json['student_id'] ?? json['studentId']),
      roomId: _asInt(json['room_id'] ?? json['roomId']),
      title: _asString(json['title']),
      description: _asString(json['description']),
      type: _asInt(json['type']),
      typeLabel: _asString(json['type_label'] ?? json['typeLabel']),
      priority: _asInt(json['priority']),
      priorityLabel:
          _asString(json['priority_label'] ?? json['priorityLabel']),
      status: _asInt(json['status']),
      statusLabel: _asString(json['status_label'] ?? json['statusLabel']),
      assignedTo: _asInt(json['assigned_to'] ?? json['assignedTo']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      address: _asString(json['address']),
      mapUrl: _asString(json['map_url'] ?? json['mapUrl']),
      images: _asStringList(json['images']),
      createdAt: _asDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _asDate(json['updated_at'] ?? json['updatedAt']),
      comments: comments,
    );
  }

  String displayType(KtxIssueMeta? meta) {
    if (typeLabel.trim().isNotEmpty) return typeLabel.trim();
    final String fromMeta = meta?.typeLabel(type) ?? '';
    if (fromMeta.isNotEmpty) return fromMeta;
    return type == null ? 'Chưa phân loại' : 'Loại #$type';
  }

  String displayPriority(KtxIssueMeta? meta) {
    if (priorityLabel.trim().isNotEmpty) return priorityLabel.trim();
    final String fromMeta = meta?.priorityLabel(priority) ?? '';
    if (fromMeta.isNotEmpty) return fromMeta;
    return priority == null ? 'Không đặt' : 'Mức #$priority';
  }

  String get displayStatus {
    if (statusLabel.trim().isNotEmpty) return statusLabel.trim();
    return status == null ? 'Chưa cập nhật' : 'Trạng thái #$status';
  }

  bool get hasLocation => latitude != null && longitude != null;
}

class KtxIssuePage {
  final List<KtxIssue> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? nextPageUrl;

  const KtxIssuePage({
    this.items = const <KtxIssue>[],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.nextPageUrl,
  });

  factory KtxIssuePage.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'] ?? json;

    if (rawData is List) {
      final List<KtxIssue> items = rawData
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) =>
                KtxIssue.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      return KtxIssuePage(
        items: items,
        total: items.length,
      );
    }

    if (rawData is! Map) {
      return const KtxIssuePage();
    }

    final dynamic rawItems =
        rawData['data'] ?? rawData['items'] ?? rawData['issues'];
    final List<KtxIssue> items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (Map<dynamic, dynamic> item) =>
                  KtxIssue.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList()
        : <KtxIssue>[];

    return KtxIssuePage(
      items: items,
      currentPage: _asInt(rawData['current_page'] ?? rawData['page']) ?? 1,
      lastPage:
          _asInt(rawData['last_page'] ?? rawData['totalPages']) ?? 1,
      total: _asInt(rawData['total'] ?? rawData['totalElements']) ??
          items.length,
      nextPageUrl:
          _nullableString(rawData['next_page_url'] ?? rawData['nextPageUrl']),
    );
  }

  factory KtxIssuePage.fromStudentShow(Map<String, dynamic> json) {
    final dynamic data = json['data'] ?? json;
    if (data is! Map) return const KtxIssuePage();

    final dynamic rawIssues = data['issues'];
    if (rawIssues is! List) return const KtxIssuePage();

    final List<KtxIssue> items = rawIssues
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) =>
              KtxIssue.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    return KtxIssuePage(
      items: items,
      total: items.length,
    );
  }
}

class KtxIssueApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  const KtxIssueApiException(
    this.message, {
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];

  return value
      .whereType<Map>()
      .map((Map<dynamic, dynamic> item) => Map<String, dynamic>.from(item))
      .toList();
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return <String>[];

  return value
      .map((dynamic item) => item?.toString().trim() ?? '')
      .where((String item) => item.isNotEmpty)
      .toList();
}

String _asString(dynamic value) => value?.toString().trim() ?? '';

String? _nullableString(dynamic value) {
  final String text = _asString(value);
  return text.isEmpty ? null : text;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool? _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final String text = value?.toString().trim().toLowerCase() ?? '';
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return null;
}

DateTime? _asDate(dynamic value) {
  final String text = _asString(value);
  if (text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}
