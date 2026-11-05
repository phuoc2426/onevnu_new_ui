import 'dart:async';

/// Demo-only models. When SSO is ready, replace this repository behind the
/// screen interface, not the UI. Nothing in this store calls a remote server.
class OneDoorPaper {
  const OneDoorPaper(this.id, this.name, {
    this.isRequired = true, this.hasTemplate = false,
  });
  final String id;
  final String name;
  final bool isRequired;
  final bool hasTemplate;
}

class OneDoorProcedure {
  const OneDoorProcedure({
    required this.id,
    required this.name,
    required this.domain,
    required this.processingDays,
    required this.fee,
    required this.papers,
    this.description = '',
    this.deliveryMethods = const <String,String>{},
    this.unitId,
    this.unitName = '',
    this.unitLevel,
    this.unitLevelName = '',
    this.audience = '',
    this.hasFee = true,
    this.hasProcessingDays = true,
  });
  final String id;
  final String name;
  final String domain;
  final int processingDays;
  final int fee;
  final String description;
  /// Public One Door unit metadata (from ThuTucListItem / ThuTucDetail).
  /// No numeric capDonVi values are inferred in the Flutter client.
  final int? unitId;
  final String unitName;
  final int? unitLevel;
  final String unitLevelName;
  final String audience;
  /// OpenAPI permits null. Null is NOT assumed to mean zero-fee / zero-day.
  final bool hasFee;
  final bool hasProcessingDays;
  /// Visible delivery label -> authoritative IdHinhThucNhanKetQua.
  final Map<String,String> deliveryMethods;
  final List<OneDoorPaper> papers;
}

enum OneDoorRecordStatus { processing, supplement, completed, rejected, cancelled }

extension OneDoorRecordStatusText on OneDoorRecordStatus {
  String get label {
    switch (this) {
      case OneDoorRecordStatus.processing: return 'Đang xử lý';
      case OneDoorRecordStatus.supplement: return 'Cần bổ sung';
      case OneDoorRecordStatus.completed: return 'Đã hoàn thành';
      case OneDoorRecordStatus.rejected: return 'Từ chối';
      case OneDoorRecordStatus.cancelled: return 'Đã hủy';
    }
  }
}

class OneDoorActivity {
  const OneDoorActivity({required this.title, required this.time, this.note = ''});
  final String title;
  final DateTime time;
  final String note;
}

class OneDoorRecord {
  OneDoorRecord({
    required this.id,
    required this.procedure,
    required this.createdAt,
    required this.requestText,
    required this.deliveryMethod,
    required this.quantity,
    required this.paperFileNames,
    required this.status,
    this.reason = '',
    List<OneDoorActivity>? history,
  }) : history = history ?? <OneDoorActivity>[];

  final String id;
  final OneDoorProcedure procedure;
  final DateTime createdAt;
  final String requestText;
  final String deliveryMethod;
  final int quantity;
  final Map<String, String> paperFileNames;
  OneDoorRecordStatus status;
  String reason;
  final List<OneDoorActivity> history;
  int get totalFee => procedure.fee * quantity;
}

abstract class OneDoorRepository {
  Future<List<OneDoorProcedure>> listProcedures();
  Future<List<OneDoorRecord>> myRecords();
  Future<OneDoorRecord> submit({
    required OneDoorProcedure procedure,
    required String requestText,
    required String deliveryMethod,
    required int quantity,
    required Map<String, String> papers,
  });
  Future<void> cancel(OneDoorRecord record);
  Future<void> supplement(OneDoorRecord record, String note, Map<String, String> papers);
}

class OneDoorDemoRepository implements OneDoorRepository {
  OneDoorDemoRepository._();
  static final OneDoorDemoRepository instance = OneDoorDemoRepository._();

  static const _generalPapers = <OneDoorPaper>[
    OneDoorPaper('demo-form', 'Đơn đề nghị / biểu mẫu'),
    OneDoorPaper('demo-id', 'Giấy tờ minh chứng (bản scan)'),
  ];

  static const procedures = <OneDoorProcedure>[
    OneDoorProcedure(id: 'p1', name: 'Giấy xác nhận sinh viên (Tiếng Anh)', domain: 'Công tác sinh viên', processingDays: 3, fee: 0, papers: _generalPapers, description: 'Xác nhận tình trạng học tập của sinh viên bằng tiếng Anh.'),
    OneDoorProcedure(id: 'p2', name: 'Giấy xác nhận sinh viên (Tiếng Việt)', domain: 'Công tác sinh viên', processingDays: 3, fee: 0, papers: _generalPapers, description: 'Xin giấy xác nhận đang học tại trường.'),
    OneDoorProcedure(id: 'p3', name: 'Đơn xin nghỉ học, bảo lưu kết quả học tập', domain: 'Công tác sinh viên', processingDays: 3, fee: 0, papers: _generalPapers),
    OneDoorProcedure(id: 'p4', name: 'Xác nhận bảng điểm học tập', domain: 'Công tác sinh viên', processingDays: 3, fee: 0, papers: _generalPapers),
    OneDoorProcedure(id: 'p5', name: 'Cấp lại thẻ sinh viên', domain: 'Công tác sinh viên', processingDays: 7, fee: 30000, papers: _generalPapers),
    OneDoorProcedure(id: 'p6', name: 'Xác nhận vay vốn tín dụng sinh viên', domain: 'Công tác sinh viên', processingDays: 7, fee: 0, papers: _generalPapers),
    OneDoorProcedure(id: 'p7', name: 'Đơn xin miễn, giảm học phí', domain: 'Công tác sinh viên', processingDays: 7, fee: 0, papers: _generalPapers),
    OneDoorProcedure(id: 'p8', name: 'Đơn xin chuyển ngành đào tạo', domain: 'Đào tạo', processingDays: 15, fee: 0, papers: _generalPapers),
    OneDoorProcedure(id: 'p9', name: 'Xác nhận hoàn thành chương trình đào tạo', domain: 'Đào tạo', processingDays: 7, fee: 0, papers: _generalPapers),
  ];

  final List<OneDoorRecord> _items = <OneDoorRecord>[];
  bool _seeded = false;

  void _seed() {
    if (_seeded) return;
    _seeded = true;
    final now = DateTime.now();
    for (final seed in <(int, OneDoorRecordStatus, int)>[
      (0, OneDoorRecordStatus.processing, 5),
      (1, OneDoorRecordStatus.completed, 12),
      (2, OneDoorRecordStatus.supplement, 17),
      (4, OneDoorRecordStatus.rejected, 28),
    ]) {
      final proc = procedures[seed.$1];
      final date = now.subtract(Duration(days: seed.$3));
      _items.add(OneDoorRecord(
        id: 'HS-${1001 + seed.$1}', procedure: proc, createdAt: date,
        requestText: 'Đề nghị giải quyết ${proc.name.toLowerCase()}',
        deliveryMethod: 'Nhận trực tiếp', quantity: 1,
        paperFileNames: const <String, String>{'demo-form': 'don-de-nghi.pdf'},
        status: seed.$2,
        reason: seed.$2 == OneDoorRecordStatus.supplement ? 'Vui lòng bổ sung giấy tờ minh chứng.' : '',
        history: <OneDoorActivity>[
          OneDoorActivity(title: 'Đã nộp hồ sơ', time: date),
          OneDoorActivity(title: 'Tiếp nhận hồ sơ', time: date.add(const Duration(hours: 2))),
        ],
      ));
    }
  }

  @override
  Future<List<OneDoorProcedure>> listProcedures() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return procedures;
  }

  @override
  Future<List<OneDoorRecord>> myRecords() async {
    _seed();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return List<OneDoorRecord>.from(_items.reversed);
  }

  @override
  Future<OneDoorRecord> submit({required OneDoorProcedure procedure, required String requestText, required String deliveryMethod, required int quantity, required Map<String, String> papers}) async {
    _seed();
    final now = DateTime.now();
    final record = OneDoorRecord(
      id: 'HS-${now.millisecondsSinceEpoch}', procedure: procedure,
      createdAt: now, requestText: requestText,
      deliveryMethod: deliveryMethod, quantity: quantity,
      paperFileNames: Map<String, String>.from(papers),
      status: OneDoorRecordStatus.processing,
      history: <OneDoorActivity>[OneDoorActivity(title: 'Đã lưu yêu cầu', time: now, note: 'Chưa đồng bộ với hệ thống Một cửa')],
    );
    _items.add(record);
    return record;
  }

  @override
  Future<void> cancel(OneDoorRecord record) async {
    record.status = OneDoorRecordStatus.cancelled;
    record.history.add(OneDoorActivity(title: 'Đã hủy hồ sơ', time: DateTime.now()));
  }

  @override
  Future<void> supplement(OneDoorRecord record, String note, Map<String, String> papers) async {
    record.paperFileNames.addAll(papers);
    record.status = OneDoorRecordStatus.processing;
    record.reason = '';
    record.history.add(OneDoorActivity(title: 'Đã lưu nội dung bổ sung', time: DateTime.now(), note: note));
  }
}

/// API contract for the later live phase. No authorization assumptions here.
class OneDoorApiPaths {
  static const procedures = '/api/v1/public/thu-tuc';
  static const myRecords = '/api/v1/ho-so/cua-toi';
  static const records = '/api/v1/ho-so';
  static String procedure(String id) => '$procedures/${Uri.encodeComponent(id)}';
  static String conditions(String id) => '/api/v1/ho-so/dieu-kien-nop/${Uri.encodeComponent(id)}';
  static String supplement(String id) => '$records/${Uri.encodeComponent(id)}/bo-sung';
  static String cancel(String id) => '$records/${Uri.encodeComponent(id)}/huy';
  // Files must be posted as multipart fields named with their idGiayTo.
}
