class PahtTopic {
  final int id;
  final String code;
  final String name;
  final bool allowPublic;

  const PahtTopic({
    required this.id,
    required this.code,
    required this.name,
    required this.allowPublic,
  });

  factory PahtTopic.fromJson(Map<String, dynamic> json) {
    return PahtTopic(
      id: _toInt(json['id']),
      code: _text(json['code']),
      name: _text(json['name']),
      allowPublic: _toBool(json['allow_public'] ?? json['allowPublic'], true),
    );
  }
}

class PahtTopicRef {
  final int id;
  final String code;
  final String name;
  final bool primary;
  final int displayOrder;

  const PahtTopicRef({
    required this.id,
    required this.code,
    required this.name,
    required this.primary,
    required this.displayOrder,
  });

  factory PahtTopicRef.fromJson(Map<String, dynamic> json) {
    return PahtTopicRef(
      id: _toInt(json['id'] ?? json['topic_id'] ?? json['topicId']),
      code: _text(json['code'] ?? json['topic_code'] ?? json['topicCode']),
      name: _text(json['name'] ?? json['topic_name'] ?? json['topicName']),
      primary: _toBool(json['primary'] ?? json['is_primary'] ?? json['isPrimary'], false),
      displayOrder: _toInt(json['displayOrder'] ?? json['display_order']),
    );
  }
}

class PahtArea {
  final int id;
  final String code;
  final String name;
  final String areaType;

  const PahtArea({
    required this.id,
    required this.code,
    required this.name,
    required this.areaType,
  });

  factory PahtArea.fromJson(Map<String, dynamic> json) {
    return PahtArea(
      id: _toInt(json['id']),
      code: _text(json['code']),
      name: _text(json['name']),
      areaType: _text(json['area_type'] ?? json['areaType']),
    );
  }
}

class PahtBootstrap {
  final List<PahtTopic> topics;
  final List<PahtArea> areas;
  final String studentCode;
  final int followingCount;

  const PahtBootstrap({
    required this.topics,
    required this.areas,
    this.studentCode = '',
    this.followingCount = 0,
  });

  factory PahtBootstrap.fromJson(Map<String, dynamic> json) {
    return PahtBootstrap(
      topics: _mapList(json['topics'], PahtTopic.fromJson),
      areas: _mapList(json['areas'], PahtArea.fromJson),
      studentCode: _text(json['studentCode'] ?? json['student_code']),
      followingCount: _toInt(json['followingCount'] ?? json['following_count']),
    );
  }
}

class PahtForumItem {
  final String guid;
  final String code;
  final String title;
  final String content;
  final int? topicId;
  final String topicName;
  final List<PahtTopicRef> topics;
  final int? areaId;
  final String areaName;
  final String locationText;
  final String workflowStatus;
  final String visibility;
  final String moderationStatus;
  final int careCount;
  final int responseCount;
  final int? ktxIssueId;
  final bool canDelete;
  final bool interested;
  // True only when the backend payload explicitly provided the interest state.
  // This prevents an older/mixed backend node that omits `interested` from
  // overwriting optimistic/server-confirmed UI state with the parser default.
  final bool interestStateProvided;
  final String priorityLevel;
  final DateTime? createdAt;
  final bool hasOfficialAnswer;
  final String thumbnailExternalFileId;
  final String thumbnailStorageKey;
  final String thumbnailFileName;

  const PahtForumItem({
    required this.guid,
    required this.code,
    required this.title,
    required this.content,
    required this.topicId,
    required this.topicName,
    required this.topics,
    required this.areaId,
    required this.areaName,
    required this.locationText,
    required this.workflowStatus,
    required this.visibility,
    required this.moderationStatus,
    required this.careCount,
    required this.responseCount,
    this.ktxIssueId,
    required this.canDelete,
    required this.interested,
    this.interestStateProvided = false,
    required this.priorityLevel,
    required this.createdAt,
    required this.hasOfficialAnswer,
    required this.thumbnailExternalFileId,
    required this.thumbnailStorageKey,
    required this.thumbnailFileName,
  });

  factory PahtForumItem.fromJson(Map<String, dynamic> json) {
    final String workflow = _text(
      json['workflow_status'] ?? json['workflowStatus'],
    ).toUpperCase();
    final int? primaryId = _toNullableInt(json['topic_id'] ?? json['topicId']);
    final String primaryName = _text(json['topic_name'] ?? json['topicName']);
    final List<PahtTopicRef> parsedTopics = _mapList(
      json['topics'],
      PahtTopicRef.fromJson,
    );
    final List<PahtTopicRef> topics = parsedTopics.isNotEmpty
        ? parsedTopics
        : (primaryId != null || primaryName.isNotEmpty)
            ? <PahtTopicRef>[
                PahtTopicRef(
                  id: primaryId ?? 0,
                  code: _text(json['topic_code'] ?? json['topicCode']),
                  name: primaryName,
                  primary: true,
                  displayOrder: 0,
                ),
              ]
            : const <PahtTopicRef>[];
    final Map<String, dynamic> thumbnail = _asMap(json['thumbnail']);
    final int responseCount = _toInt(
      json['response_count'] ??
          json['responseCount'] ??
          json['public_response_count'] ??
          json['publicResponseCount'] ??
          json['all_response_count'] ??
          json['allResponseCount'],
    );
    return PahtForumItem(
      guid: _text(json['guid']),
      code: _text(json['code']),
      title: _text(json['title']),
      content: _text(json['content']),
      topicId: primaryId,
      topicName: primaryName,
      topics: topics,
      areaId: _toNullableInt(json['area_id'] ?? json['areaId']),
      // Privacy: vị trí/khu vực xử lý không được bind vào UI sinh viên.
      // Backend vẫn lưu cho cán bộ xử lý/admin.
      areaName: '',
      locationText: '',
      workflowStatus: workflow,
      visibility: _text(json['visibility']).toUpperCase(),
      moderationStatus: _text(
        json['moderation_status'] ?? json['moderationStatus'],
      ).toUpperCase(),
      careCount: _toInt(json['care_count'] ?? json['careCount']),
      responseCount: responseCount,
      ktxIssueId: _toNullableInt(json['ktx_issue_id'] ?? json['ktxIssueId']),
      // Quyền xóa phải do backend quyết định. Không suy ra từ responseCount
      // vì response public có thể khác tổng response thực tế.
      canDelete: _toBool(
        json['can_delete'] ?? json['canDelete'],
        false,
      ),
      interested: _toBool(json['interested'], false),
      interestStateProvided: json.containsKey('interested'),
      priorityLevel: _text(
        json['priority_level'] ?? json['priorityLevel'],
      ).toUpperCase(),
      createdAt: _toDate(json['created_at'] ?? json['createdAt']),
      hasOfficialAnswer: _toBool(
        json['has_official_answer'] ?? json['hasOfficialAnswer'],
        false,
      ),
      thumbnailExternalFileId: _text(
        thumbnail['external_file_id'] ?? thumbnail['externalFileId'] ??
            json['thumbnail_external_file_id'] ?? json['thumbnailExternalFileId'],
      ),
      thumbnailStorageKey: _text(
        thumbnail['storage_key'] ?? thumbnail['storageKey'] ??
            json['thumbnail_storage_key'] ?? json['thumbnailStorageKey'],
      ),
      thumbnailFileName: _text(
        thumbnail['file_name'] ?? thumbnail['fileName'] ??
            json['thumbnail_file_name'] ?? json['thumbnailFileName'],
      ),
    );
  }

  PahtForumItem copyWithInterest({
    required bool interested,
    required int careCount,
  }) {
    return PahtForumItem(
      guid: guid,
      code: code,
      title: title,
      content: content,
      topicId: topicId,
      topicName: topicName,
      topics: topics,
      areaId: areaId,
      areaName: areaName,
      locationText: locationText,
      workflowStatus: workflowStatus,
      visibility: visibility,
      moderationStatus: moderationStatus,
      careCount: careCount,
      responseCount: responseCount,
      ktxIssueId: ktxIssueId,
      canDelete: canDelete,
      interested: interested,
      interestStateProvided: true,
      priorityLevel: priorityLevel,
      createdAt: createdAt,
      hasOfficialAnswer: hasOfficialAnswer,
      thumbnailExternalFileId: thumbnailExternalFileId,
      thumbnailStorageKey: thumbnailStorageKey,
      thumbnailFileName: thumbnailFileName,
    );
  }

  PahtForumItem copyWithResponseCount(int value) {
    return PahtForumItem(
      guid: guid,
      code: code,
      title: title,
      content: content,
      topicId: topicId,
      topicName: topicName,
      topics: topics,
      areaId: areaId,
      areaName: areaName,
      locationText: locationText,
      workflowStatus: workflowStatus,
      visibility: visibility,
      moderationStatus: moderationStatus,
      careCount: careCount,
      responseCount: value < 0 ? 0 : value,
      ktxIssueId: ktxIssueId,
      canDelete: canDelete,
      interested: interested,
      interestStateProvided: interestStateProvided,
      priorityLevel: priorityLevel,
      createdAt: createdAt,
      hasOfficialAnswer: hasOfficialAnswer,
      thumbnailExternalFileId: thumbnailExternalFileId,
      thumbnailStorageKey: thumbnailStorageKey,
      thumbnailFileName: thumbnailFileName,
    );
  }
}

class PahtForumPage {
  final List<PahtForumItem> items;
  final int total;
  final int page;
  final int size;
  final int totalPages;

  const PahtForumPage({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.totalPages,
  });

  factory PahtForumPage.fromJson(Map<String, dynamic> json) {
    return PahtForumPage(
      items: _mapList(json['items'], PahtForumItem.fromJson),
      total: _toInt(json['total']),
      page: _toInt(json['page']),
      size: _toInt(json['size']),
      totalPages: _toInt(json['totalPages'] ?? json['total_pages']),
    );
  }

  bool get hasMore => page + 1 < totalPages && items.length < total;
}

class PahtResponseItem {
  final String responseType;
  final String content;

  /// Tên đơn vị dùng để hiển thị cho sinh viên. Không bao giờ chứa GUID.
  final String unit;

  /// Tham chiếu kỹ thuật tới đơn vị trả lời. Chỉ dùng để resolve tên đơn vị,
  /// tuyệt đối không render trực tiếp lên UI.
  final String unitRef;

  final DateTime? createdAt;
  final String sourceSystem;
  final String externalResponseId;

  const PahtResponseItem({
    required this.responseType,
    required this.content,
    required this.unit,
    this.unitRef = '',
    required this.createdAt,
    this.sourceSystem = 'ONEVNU',
    this.externalResponseId = '',
  });

  factory PahtResponseItem.fromJson(Map<String, dynamic> json) {
    return PahtResponseItem(
      responseType: _text(json['response_type'] ?? json['responseType']),
      content: _text(json['content']),
      // Chỉ nhận field tên. Không fallback sang created_by_unit_ref vì field
      // đó là GUID kỹ thuật và đã từng bị hiện thẳng trên app.
      unit: _text(json['created_by_unit_name'] ?? json['createdByUnitName']),
      unitRef: _text(json['created_by_unit_ref'] ?? json['createdByUnitRef']),
      createdAt: _toDate(json['created_at'] ?? json['createdAt']),
      sourceSystem: _text(json['source_system'] ?? json['sourceSystem']).isEmpty
          ? 'ONEVNU'
          : _text(json['source_system'] ?? json['sourceSystem']).toUpperCase(),
      externalResponseId: _text(json['external_response_id'] ?? json['externalResponseId']),
    );
  }

  PahtResponseItem withUnitName(String value) {
    return PahtResponseItem(
      responseType: responseType,
      content: content,
      unit: value.trim(),
      unitRef: unitRef,
      createdAt: createdAt,
      sourceSystem: sourceSystem,
      externalResponseId: externalResponseId,
    );
  }
}

class PahtTimelineItem {
  final String eventType;
  final String oldStatus;
  final String newStatus;
  final String note;
  final DateTime? createdAt;

  const PahtTimelineItem({
    required this.eventType,
    required this.oldStatus,
    required this.newStatus,
    required this.note,
    required this.createdAt,
  });

  factory PahtTimelineItem.fromJson(Map<String, dynamic> json) {
    return PahtTimelineItem(
      eventType: _text(json['event_type'] ?? json['eventType']),
      oldStatus: _text(json['old_status'] ?? json['oldStatus']),
      newStatus: _text(json['new_status'] ?? json['newStatus']),
      note: _text(json['note']),
      createdAt: _toDate(json['created_at'] ?? json['createdAt']),
    );
  }
}

class PahtAttachmentItem {
  final String fileName;
  final String mediaKind;
  final String storageKey;
  final String externalFileId;
  final String contentType;

  const PahtAttachmentItem({
    required this.fileName,
    required this.mediaKind,
    required this.storageKey,
    required this.externalFileId,
    required this.contentType,
  });

  factory PahtAttachmentItem.fromJson(Map<String, dynamic> json) {
    return PahtAttachmentItem(
      fileName: _text(json['file_name'] ?? json['fileName']),
      mediaKind: _text(json['media_kind'] ?? json['mediaKind']),
      storageKey: _text(json['storage_key'] ?? json['storageKey']),
      externalFileId: _text(json['external_file_id'] ?? json['externalFileId']),
      contentType: _text(json['content_type'] ?? json['contentType']),
    );
  }
}

class PahtForumDetail {
  final PahtForumItem item;
  final bool interested;
  final String publicLocationMode;
  final List<PahtResponseItem> responses;
  final List<PahtTimelineItem> timeline;
  final List<PahtAttachmentItem> attachments;
  final int? ktxIssueId;

  const PahtForumDetail({
    required this.item,
    required this.interested,
    required this.publicLocationMode,
    required this.responses,
    required this.timeline,
    required this.attachments,
    this.ktxIssueId,
  });

  factory PahtForumDetail.fromJson(Map<String, dynamic> json) {
    final List<PahtResponseItem> responses =
        _mapList(json['responses'], PahtResponseItem.fromJson);
    responses.sort((PahtResponseItem a, PahtResponseItem b) {
      final DateTime ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ad.compareTo(bd);
    });
    return PahtForumDetail(
      item: PahtForumItem.fromJson(json),
      interested: _toBool(json['interested'], false),
      publicLocationMode: '',
      responses: responses,
      timeline: _mapList(json['timeline'], PahtTimelineItem.fromJson),
      attachments: _mapList(
        json['attachments'],
        PahtAttachmentItem.fromJson,
      ),
      ktxIssueId: _toNullableInt(json['ktx_issue_id'] ?? json['ktxIssueId']),
    );
  }

  PahtForumDetail copyWithInterest({
    required bool interested,
    required int careCount,
  }) {
    return PahtForumDetail(
      item: item.copyWithInterest(interested: interested, careCount: careCount),
      interested: interested,
      publicLocationMode: publicLocationMode,
      responses: responses,
      timeline: timeline,
      attachments: attachments,
      ktxIssueId: ktxIssueId,
    );
  }

  PahtForumDetail copyWithResponses(List<PahtResponseItem> value) {
    return PahtForumDetail(
      item: item.copyWithResponseCount(value.length),
      interested: interested,
      publicLocationMode: publicLocationMode,
      responses: value,
      timeline: timeline,
      attachments: attachments,
      ktxIssueId: ktxIssueId,
    );
  }

}

class PahtSimilarHit {
  final String guid;
  final String code;
  final String title;
  final String topic;
  final String area;
  final String excerpt;
  final int careCount;

  const PahtSimilarHit({
    required this.guid,
    required this.code,
    required this.title,
    required this.topic,
    required this.area,
    required this.excerpt,
    required this.careCount,
  });

  factory PahtSimilarHit.fromJson(Map<String, dynamic> json) {
    return PahtSimilarHit(
      guid: _text(json['guid']),
      code: _text(json['code']),
      title: _text(json['title']),
      topic: _text(json['topic']),
      area: '',
      excerpt: _text(json['excerpt']),
      careCount: _toInt(json['careCount'] ?? json['care_count']),
    );
  }
}

class PahtInterestResult {
  final bool interested;
  final int careCount;
  final int followingCount;

  const PahtInterestResult({
    required this.interested,
    required this.careCount,
    required this.followingCount,
  });

  factory PahtInterestResult.fromJson(Map<String, dynamic> json) {
    return PahtInterestResult(
      interested: _toBool(json['interested'], false),
      careCount: _toInt(json['careCount'] ?? json['care_count']),
      followingCount: _toInt(json['followingCount'] ?? json['following_count']),
    );
  }
}

class PahtCreateResult {
  final String guid;
  final String code;
  final DateTime? createdAt;

  const PahtCreateResult({
    required this.guid,
    required this.code,
    required this.createdAt,
  });

  factory PahtCreateResult.fromJson(Map<String, dynamic> json) {
    return PahtCreateResult(
      guid: _text(json['guid']),
      code: _text(json['code']),
      createdAt: _toDate(json['created_at'] ?? json['createdAt']),
    );
  }
}

String pahtStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'RECEIVED':
      return 'Đã tiếp nhận';
    case 'PROCESSING':
      return 'Đang xử lý';
    case 'ANSWERED':
      return 'Đã trả lời';
    case 'RESOLVED':
      return 'Đã hoàn tất';
    case 'REJECTED':
      return 'Từ chối';
    case 'DUPLICATE':
      return 'Trùng phản ánh';
    case 'WITHDRAW_REQUESTED':
      return 'Đang xin rút';
    case 'WITHDRAWN':
      return 'Đã rút';
    default:
      return status.trim().isEmpty ? 'Đang cập nhật' : status;
  }
}

String pahtVisibilityLabel(String visibility) {
  return visibility.toUpperCase() == 'PRIVATE' ? 'Riêng tư' : 'Công khai';
}

String pahtModerationLabel(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return 'Chờ duyệt';
    case 'APPROVED':
      return 'Đã duyệt';
    case 'REJECTED':
      return 'Không duyệt';
    default:
      return status;
  }
}

String pahtFormatDate(DateTime? value) {
  if (value == null) return '';
  final DateTime local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

List<T> _mapList<T>(dynamic value, T Function(Map<String, dynamic>) parser) {
  if (value is! List) return <T>[];
  return value
      .whereType<Map>()
      .map((dynamic item) => parser(Map<String, dynamic>.from(item as Map)))
      .toList(growable: false);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _text(dynamic value) => value?.toString().trim() ?? '';

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_text(value)) ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  final int parsed = _toInt(value);
  return parsed == 0 && _text(value) != '0' ? null : parsed;
}

bool _toBool(dynamic value, bool fallback) {
  if (value is bool) return value;
  final String text = _text(value).toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

DateTime? _toDate(dynamic value) {
  final String text = _text(value);
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}
