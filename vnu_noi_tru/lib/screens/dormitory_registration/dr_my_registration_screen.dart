import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_noi_tru/cubit/dormitory_registration_cubit.dart';
import 'package:vnu_noi_tru/models/dormitory_payment/dormitory_invoice_model.dart';
import 'package:vnu_noi_tru/repository/dormitory_payment_repository.dart';
import 'package:vnu_noi_tru/repository/dormitory_registration_repository.dart';

import 'dr_history_bottom_sheet.dart';
import 'dr_wizard_flow.dart';
import 'dr_invoices_screen.dart';
class DRMyRegistrationScreen extends StatefulWidget {
  const DRMyRegistrationScreen({super.key});

  @override
  State<DRMyRegistrationScreen> createState() =>
      _DRMyRegistrationScreenState();
}

class _DRMyRegistrationScreenState
    extends State<DRMyRegistrationScreen> {
  final DormitoryRegistrationCubit _cubit =
  DormitoryRegistrationCubit();

  final DormitoryRegistrationRepository _repository =
  DormitoryRegistrationRepository();

  final DormitoryPaymentRepository _paymentRepository =
  DormitoryPaymentRepository();

  List<dynamic> _roomTypes = <dynamic>[];
  DormitoryInvoiceModel? _latestReceipt;

  late BuildContext _hubContext;

  bool _hasOpenRegistrationPeriod = false;
  bool _isCheckingOpenRegistrationPeriod = true;
  bool _isSubmittingAccommodationRequest = false;

  String? _registrationPeriodMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isCheckingOpenRegistrationPeriod = true;
      });
    }

    await _cubit.getDormitories();
    await _loadRoomTypesForDisplay();
    await _cubit.getPriorityObjects();

    final bool hasOpenPeriod =
    await _cubit.checkAnyOpenRegistrationPeriod();

    if (mounted) {
      setState(() {
        _hasOpenRegistrationPeriod = hasOpenPeriod;
        _isCheckingOpenRegistrationPeriod = false;
        _registrationPeriodMessage = _cubit.openPeriodMessage;
      });
    }

    await _cubit.getMyRegistrations();
    await _loadLatestReceiptFromCurrentState();
  }

  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _isCheckingOpenRegistrationPeriod = true;
      });
    }

    await _loadRoomTypesForDisplay();

    final bool hasOpenPeriod =
    await _cubit.checkAnyOpenRegistrationPeriod();

    if (mounted) {
      setState(() {
        _hasOpenRegistrationPeriod = hasOpenPeriod;
        _isCheckingOpenRegistrationPeriod = false;
        _registrationPeriodMessage = _cubit.openPeriodMessage;
      });
    }

    await _cubit.getMyRegistrations();
    await _loadLatestReceiptFromCurrentState();
  }

  Future<void> _loadLatestReceiptFromCurrentState() async {
    final dynamic data = _readDataFromState(_cubit.state);
    final dynamic student = _readStudent(data);

    String identityNo = _studentIdentityNo(student).trim();

    if (identityNo.isEmpty) {
      final SharedPreferences preferences =
      await SharedPreferences.getInstance();
      identityNo =
          preferences.getString('applicant_cccd')?.trim() ?? '';
    }

    if (identityNo.isEmpty) {
      if (mounted) {
        setState(() {
          _latestReceipt = null;
        });
      } else {
        _latestReceipt = null;
      }
      return;
    }

    try {
      final DormitoryInvoiceResponse response =
      await _paymentRepository.getReceipts(identityNo: identityNo);

      final List<DormitoryInvoiceModel> receipts =
      List<DormitoryInvoiceModel>.from(response.invoices);

      receipts.sort(_compareReceiptNewestFirst);

      final DormitoryInvoiceModel? latest =
      receipts.isEmpty ? null : receipts.first;

      if (!mounted) {
        _latestReceipt = latest;
        return;
      }

      setState(() {
        _latestReceipt = latest;
      });
    } catch (_) {
      // Không dùng lại giá phòng cơ bản khi API biên lai lỗi.
      // Ẩn giá để tránh hiển thị một con số không đúng với khoản thu mới nhất.
      if (!mounted) {
        _latestReceipt = null;
        return;
      }

      setState(() {
        _latestReceipt = null;
      });
    }
  }

  int _compareReceiptNewestFirst(
      DormitoryInvoiceModel first,
      DormitoryInvoiceModel second,
      ) {
    final DateTime firstDate =
        first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final DateTime secondDate =
        second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    final int dateCompare = secondDate.compareTo(firstDate);
    if (dateCompare != 0) {
      return dateCompare;
    }

    final int firstId = int.tryParse(first.id?.toString() ?? '') ?? 0;
    final int secondId = int.tryParse(second.id?.toString() ?? '') ?? 0;
    return secondId.compareTo(firstId);
  }

  Future<void> _loadRoomTypesForDisplay() async {
    try {
      final dynamic response = await _repository.getRoomTypes();
      final List<dynamic> values = response.data?.items == null
          ? <dynamic>[]
          : List<dynamic>.from(response.data!.items!);

      if (!mounted) {
        _roomTypes = values;
        return;
      }

      setState(() {
        _roomTypes = values;
      });
    } catch (_) {
      // Loại phòng chỉ là dữ liệu bổ sung để đổi room_type_id thành tên.
      // Không chặn màn hình hồ sơ khi API danh mục tạm thời lỗi.
      _roomTypes = <dynamic>[];
    }
  }

  // =========================================================
  // Đọc dữ liệu dynamic
  // Hỗ trợ cả Map và model object.
  // =========================================================

  dynamic _readDataFromState(dynamic state) {
    try {
      return state.data;
    } catch (_) {
      return null;
    }
  }

  dynamic _readStudent(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      return data['student'];
    }

    try {
      return data.student;
    } catch (_) {
      return null;
    }
  }
  String _studentIdentityNo(
      dynamic student,
      ) {
    final String value = _readString(
      student,
      'identity_no',
          (dynamic object) =>
      object.cccd,
      aliases: const <String>[
        'identityNo',
        'identity_number',
        'cccd',
      ],
    );

    if (value.trim().isNotEmpty) {
      return value.trim();
    }

    return Globals()
        .thongTinSinhVienModel
        .value
        ?.soCmtCccd
        ?.trim() ??
        '';
  }

  int? _dormitoryId(dynamic item) {
    final dynamic dormitory =
    _dormitory(item);

    final int? nestedId = _readInt(
      dormitory,
      'id',
          (dynamic object) =>
      object.id,
    );

    if (nestedId != null) {
      return nestedId;
    }

    return _readInt(
      item,
      'dormitory_id',
          (dynamic object) =>
      object.dormitoryId,
      aliases: const <String>[
        'dormitoryId',
      ],
    );
  }
  List<dynamic> _readAccommodations(dynamic data) {
    if (data == null) return <dynamic>[];

    // API /dormitory/me đang trả hai danh sách:
    // 1. data.accommodations: bản tóm tắt, có status/statusLabel.
    // 2. data.student.accommodations: bản đầy đủ, có dormitory,
    //    registration_period, room_type, room, ngày ở và ghi chú.
    // Phải ghép hai danh sách theo id, nếu chỉ dùng danh sách tóm tắt
    // thì UI sẽ hiện "Chưa có thông tin" dù API đã trả dữ liệu đầy đủ.
    List<dynamic> summaryItems = <dynamic>[];
    dynamic student;

    if (data is Map) {
      summaryItems = _asList(data['accommodations']);
      student = data['student'];
    } else {
      try {
        summaryItems = _asList(data.accommodations);
      } catch (_) {
        summaryItems = <dynamic>[];
      }

      try {
        student = data.student;
      } catch (_) {
        student = null;
      }
    }

    List<dynamic> detailItems = <dynamic>[];
    if (student is Map) {
      detailItems = _asList(student['accommodations']);
    } else if (student != null) {
      try {
        detailItems = _asList(student.accommodations);
      } catch (_) {
        detailItems = <dynamic>[];
      }
    }

    if (summaryItems.isEmpty) {
      return detailItems;
    }

    if (detailItems.isEmpty) {
      return summaryItems;
    }

    final Map<String, dynamic> detailById = <String, dynamic>{};

    for (final dynamic detail in detailItems) {
      final Object? id = _accommodationId(detail);
      if (id != null) {
        detailById[id.toString()] = detail;
      }
    }

    final List<dynamic> result = <dynamic>[];
    final Set<String> usedIds = <String>{};

    for (final dynamic summary in summaryItems) {
      final Object? id = _accommodationId(summary);
      final String? key = id?.toString();
      final dynamic detail = key == null ? null : detailById[key];

      if (key != null) {
        usedIds.add(key);
      }

      if (summary is Map && detail is Map) {
        final Map<String, dynamic> merged =
        Map<String, dynamic>.from(detail);

        // Ưu tiên giá trị tóm tắt khi khác null vì status ở đây
        // đã được backend chuẩn hóa thành PENDING/APPROVED/ASSIGNED...
        summary.forEach((dynamic rawKey, dynamic value) {
          if (value != null) {
            merged[rawKey.toString()] = value;
          }
        });

        result.add(merged);
      } else {
        result.add(detail ?? summary);
      }
    }

    // Giữ cả bản ghi chi tiết mà danh sách tóm tắt chưa trả về.
    for (final dynamic detail in detailItems) {
      final Object? id = _accommodationId(detail);
      if (id == null || !usedIds.contains(id.toString())) {
        result.add(detail);
      }
    }

    return result;
  }

  List<dynamic> _asList(dynamic value) {
    if (value == null) return <dynamic>[];

    if (value is List) {
      return List<dynamic>.from(value);
    }

    if (value is Iterable && value is! String) {
      return List<dynamic>.from(value);
    }

    if (value is Map) {
      return <dynamic>[value];
    }

    return <dynamic>[];
  }

  String _readString(
      dynamic obj,
      String mapKey,
      String Function(dynamic object) getter, {
        List<String> aliases = const <String>[],
      }) {
    if (obj == null) return '';

    if (obj is Map) {
      dynamic value = obj[mapKey];

      for (final String alias in aliases) {
        value ??= obj[alias];
      }

      return value?.toString() ?? '';
    }

    try {
      final dynamic value = getter(obj);
      return value?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  int? _readInt(
      dynamic obj,
      String mapKey,
      int? Function(dynamic object) getter, {
        List<String> aliases = const <String>[],
      }) {
    if (obj == null) return null;

    if (obj is Map) {
      dynamic value = obj[mapKey];

      for (final String alias in aliases) {
        value ??= obj[alias];
      }

      if (value is int) {
        return value;
      }

      return int.tryParse(value?.toString() ?? '');
    }

    try {
      return getter(obj);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  DateTime? _readDate(
      dynamic obj,
      String mapKey,
      dynamic Function(dynamic object) getter, {
        List<String> aliases = const <String>[],
      }) {
    if (obj == null) return null;

    if (obj is Map) {
      dynamic value = obj[mapKey];

      for (final String alias in aliases) {
        value ??= obj[alias];
      }

      return _parseDate(value);
    }

    try {
      return _parseDate(getter(obj));
    } catch (_) {
      return null;
    }
  }

  dynamic _readNested(
      dynamic obj,
      String mapKey,
      dynamic Function(dynamic object) getter, {
        List<String> aliases = const <String>[],
      }) {
    if (obj == null) return null;

    if (obj is Map) {
      dynamic value = obj[mapKey];

      for (final String alias in aliases) {
        value ??= obj[alias];
      }

      return value;
    }

    try {
      return getter(obj);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // Thông tin sinh viên
  // =========================================================

  String _studentFullName(dynamic student) {
    final String fromApi = _readString(
      student,
      'full_name',
          (dynamic object) => object.fullName,
      aliases: const <String>['fullName'],
    );

    if (fromApi.isNotEmpty) {
      return fromApi;
    }

    return Globals().thongTinSinhVienModel.value?.hoVaTen ?? '';
  }

  String _studentCodeText(dynamic student) {
    final String fromApi = _readString(
      student,
      'student_code',
          (dynamic object) => object.studentCode,
      aliases: const <String>['studentCode'],
    );

    if (fromApi.isNotEmpty) {
      return fromApi;
    }

    return Globals().thongTinSinhVienModel.value?.maSinhVien ?? '';
  }

  String _studentClass(dynamic student) {
    return _readString(
      student,
      'class',
          (dynamic object) => object.className,
      aliases: const <String>['className'],
    );
  }

  String _studentMajor(dynamic student) {
    return _readString(
      student,
      'major',
          (dynamic object) => object.major,
    );
  }

  String _studentPhone(dynamic student) {
    return _readString(
      student,
      'phone_number',
          (dynamic object) => object.phone,
      aliases: const <String>[
        'phoneNumber',
        'phone',
      ],
    );
  }

  String _studentEmail(dynamic student) {
    return _readString(
      student,
      'email',
          (dynamic object) => object.email,
    );
  }

  String _studentUniversity(dynamic student) {
    return _readString(
      student,
      'university_name',
          (dynamic object) => object.universityName,
      aliases: const <String>['university'],
    );
  }

  String _studentIdentityType(dynamic student) {
    return _readString(
      student,
      'identity_type',
          (dynamic object) => object.identityType,
      aliases: const <String>['identityType'],
    );
  }

  DateTime? _studentDateOfBirth(dynamic student) {
    return _readDate(
      student,
      'dob',
          (dynamic object) => object.dob,
      aliases: const <String>['dateOfBirth'],
    );
  }

  String _studentGender(dynamic student) {
    final String value = _readString(
      student,
      'gender',
          (dynamic object) => object.gender,
    ).trim().toLowerCase();

    if (value == 'male' || value == 'nam') return 'Nam';
    if (value == 'female' || value == 'nữ' || value == 'nu') return 'Nữ';
    return value;
  }

  String _studentAcademicYear(dynamic student) {
    return _readString(
      student,
      'academic_year',
          (dynamic object) => object.academicYear,
      aliases: const <String>['academicYear'],
    );
  }

  String _studentLevel(dynamic student) {
    return _readString(
      student,
      'level',
          (dynamic object) => object.level,
    );
  }

  String _studentPermanentAddress(dynamic student) {
    return _readString(
      student,
      'permanent_address',
          (dynamic object) => object.permanentAddress,
      aliases: const <String>[
        'permanentAddress',
        'vneid_permanent_address',
        'vneidPermanentAddress',
      ],
    );
  }

  String _studentTemporaryAddress(dynamic student) {
    return _readString(
      student,
      'temporary_address',
          (dynamic object) => object.temporaryAddress,
      aliases: const <String>[
        'temporaryAddress',
        'vneid_temporary_address',
        'vneidTemporaryAddress',
      ],
    );
  }

  String _studentPriorityObjectName(dynamic student) {
    final dynamic rawObjects = _readNested(
      student,
      'priority_objects',
          (dynamic object) => object.priorityObjects,
      aliases: const <String>['priorityObjects'],
    );

    final List<String> names = <String>[];
    for (final dynamic value in _asList(rawObjects)) {
      final String name = value is String
          ? value.trim()
          : _readString(value, 'name', (dynamic object) => object.name).trim();
      if (name.isNotEmpty && !names.contains(name)) {
        names.add(name);
      }
    }

    if (names.isNotEmpty) {
      return names.join(', ');
    }

    return _readString(
      student,
      'priority_object_name',
          (dynamic object) => object.priorityObjectName,
      aliases: const <String>['priorityObjectName'],
    );
  }

  // =========================================================
  // Thông tin hồ sơ nội trú
  // =========================================================

  Object? _accommodationId(dynamic item) {
    if (item == null) return null;

    if (item is Map) {
      final dynamic value = item['id'];

      if (value == null) return null;

      return int.tryParse(value.toString()) ??
          value.toString();
    }

    try {
      return item.id;
    } catch (_) {
      return null;
    }
  }

  String _accommodationStatus(dynamic item) {
    final String raw = _readString(
      item,
      'status',
          (dynamic object) => object.status,
    ).trim().toLowerCase();

    if (raw.isNotEmpty && int.tryParse(raw) == null) {
      return raw;
    }

    // Fallback cho bản chi tiết cũ trả status dạng số.
    // Danh sách tóm tắt vẫn được ưu tiên vì trả status dạng chữ.
    switch (raw) {
      case '0':
        return 'draft';
      case '1':
        return 'pending';
      case '2':
        return 'approved';
      case '3':
        return 'assigned';
      case '4':
        return 'active';
      case '5':
        return 'rejected';
      case '6':
        return 'checkout';
      case '7':
        return 'terminated';
      default:
        return raw;
    }
  }

  String _accommodationNote(dynamic item) {
    return _readString(
      item,
      'note',
          (dynamic object) => object.note,
    );
  }

  DateTime? _accommodationCreatedAt(dynamic item) {
    return _readDate(
      item,
      'created_at',
          (dynamic object) => object.createdAt,
      aliases: const <String>['createdAt'],
    );
  }

  DateTime? _accommodationApprovedAt(dynamic item) {
    return _readDate(
      item,
      'approved_at',
          (dynamic object) => object.approvedAt,
      aliases: const <String>['approvedAt'],
    );
  }

  DateTime? _accommodationAssignedAt(dynamic item) {
    return _readDate(
      item,
      'assigned_at',
          (dynamic object) => object.assignedAt,
      aliases: const <String>['assignedAt'],
    );
  }

  DateTime? _accommodationStartDate(dynamic item) {
    return _readDate(
      item,
      'start_date',
          (dynamic object) => object.startDate,
      aliases: const <String>['startDate'],
    );
  }

  DateTime? _accommodationEndDate(dynamic item) {
    return _readDate(
      item,
      'end_date',
          (dynamic object) => object.endDate,
      aliases: const <String>['endDate'],
    );
  }

  DateTime? _accommodationUpdatedAt(dynamic item) {
    return _readDate(
      item,
      'updated_at',
          (dynamic object) => object.updatedAt,
      aliases: const <String>['updatedAt'],
    );
  }

  DateTime? _accommodationCheckinAt(dynamic item) {
    return _readDate(
      item,
      'checkin_at',
          (dynamic object) => object.checkinAt,
      aliases: const <String>['checkinAt'],
    );
  }

  DateTime? _accommodationCheckoutAt(dynamic item) {
    return _readDate(
      item,
      'checkout_at',
          (dynamic object) => object.checkoutAt,
      aliases: const <String>['checkoutAt'],
    );
  }

  String _accommodationReasonStay(dynamic item) {
    return _readString(
      item,
      'reason_stay',
          (dynamic object) => object.reasonStay,
      aliases: const <String>['reasonStay', 'reason'],
    );
  }

  bool? _accommodationIsRoomLeader(dynamic item) {
    final dynamic value = _readNested(
      item,
      'is_room_leader',
          (dynamic object) => object.isRoomLeader,
      aliases: const <String>['isRoomLeader'],
    );

    if (value is bool) return value;
    if (value is num) return value != 0;

    final String text = value?.toString().trim().toLowerCase() ?? '';
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return null;
  }

  String _requestStatusRaw(dynamic item) {
    final String value = _readString(
      item,
      'request_status',
          (dynamic object) => object.requestStatus,
      aliases: const <String>['requestStatus'],
    ).trim().toLowerCase();

    switch (value) {
      case 'change-room':
      case 'room_change':
      case 'transfer':
        return 'change_room';
      case 'check_out':
      case 'check-out':
        return 'checkout';
      case 'none':
      case 'null':
      case '0':
        return '';
      default:
        return value;
    }
  }

  String _requestStatusText(dynamic item) {
    switch (_requestStatusRaw(item)) {
      case 'change_room':
        return 'Đang yêu cầu chuyển phòng';
      case 'checkout':
        return 'Đang yêu cầu trả phòng';
      default:
        return '';
    }
  }

  String _accommodationRequestType(dynamic item) {
    return _requestStatusRaw(item);
  }

  String _requestTypeText(String requestType) {
    switch (requestType) {
      case 'change_room':
        return 'Yêu cầu chuyển phòng';
      case 'checkout':
        return 'Yêu cầu trả phòng';
      default:
        return 'Yêu cầu nội trú';
    }
  }

  bool _hasPendingAccommodationRequest(dynamic item) {
    final String requestType = _requestStatusRaw(item);
    return requestType == 'change_room' || requestType == 'checkout';
  }

  int? _currentRoomId(dynamic item) {
    final dynamic room = _room(item);
    final int? nestedId = _readInt(
      room,
      'id',
          (dynamic object) => object.id,
    );
    if (nestedId != null) {
      return nestedId;
    }

    return _readInt(
      item,
      'room_id',
          (dynamic object) => object.roomId,
      aliases: const <String>['roomId'],
    );
  }

  int? _roomOptionId(Map<String, dynamic> room) {
    return _readInt(room, 'id', (dynamic object) => object.id);
  }

  String _roomOptionLabel(Map<String, dynamic> room) {
    final String roomNumber = _readString(
      room,
      'room_number',
          (dynamic object) => object.roomNumber,
      aliases: const <String>['roomNumber', 'name'],
    ).trim();

    final dynamic building = room['building'];
    final String buildingName = _readString(
      building,
      'name',
          (dynamic object) => object.name,
    ).trim();

    final String roomType = _readString(
      room['room_type'] ?? room['roomType'],
      'name',
          (dynamic object) => object.name,
    ).trim();

    final List<String> parts = <String>[
      if (roomNumber.isNotEmpty) 'Phòng $roomNumber',
      if (buildingName.isNotEmpty) buildingName,
      if (roomType.isNotEmpty) roomType,
    ];

    if (parts.isNotEmpty) {
      return parts.join(' · ');
    }

    final int? id = _roomOptionId(room);
    return id == null ? 'Phòng chưa có tên' : 'Phòng #$id';
  }

  dynamic _registrationPeriod(dynamic item) {
    return _readNested(
      item,
      'registration_period',
          (dynamic object) => object.registrationPeriod,
      aliases: const <String>['registrationPeriod'],
    );
  }

  dynamic _dormitory(dynamic item) {
    return _readNested(
      item,
      'dormitory',
          (dynamic object) => object.dormitory,
    );
  }

  /// Loại phòng chỉ dùng để hiển thị sau khi cán bộ KTX đã xếp.
  /// Sinh viên không chọn loại phòng khi đăng ký.
  dynamic _roomType(dynamic item) {
    return _readNested(
      item,
      'room_type',
          (dynamic object) => object.roomType,
      aliases: const <String>['roomType'],
    );
  }

  dynamic _room(dynamic item) {
    return _readNested(
      item,
      'room',
          (dynamic object) => object.room,
    );
  }

  DateTime? _periodStartTime(dynamic item) {
    final dynamic period = _registrationPeriod(item);
    return _readDate(
      period,
      'start_time',
          (dynamic object) => object.startTime,
      aliases: const <String>['startTime'],
    );
  }

  DateTime? _periodEndTime(dynamic item) {
    final dynamic period = _registrationPeriod(item);
    return _readDate(
      period,
      'end_time',
          (dynamic object) => object.endTime,
      aliases: const <String>['endTime'],
    );
  }

  String _periodDescription(dynamic item) {
    final dynamic period = _registrationPeriod(item);
    return _readString(
      period,
      'description',
          (dynamic object) => object.description,
    );
  }

  String _priorityObjectName(dynamic item, dynamic student) {
    final List<String> names = <String>[];

    final dynamic pluralObjects = _readNested(
      item,
      'priority_objects',
          (dynamic object) => object.priorityObjects,
      aliases: const <String>['priorityObjects'],
    );

    for (final dynamic value in _asList(pluralObjects)) {
      final String name = value is String
          ? value.trim()
          : _readString(value, 'name', (dynamic object) => object.name).trim();
      if (name.isNotEmpty && !names.contains(name)) {
        names.add(name);
      }
    }

    final dynamic rawIds = _readNested(
      item,
      'priority_object_ids',
          (dynamic object) => object.priorityObjectIds,
      aliases: const <String>['priorityObjectIds'],
    );

    for (final dynamic rawId in _asList(rawIds)) {
      final int? priorityId = rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? '');
      if (priorityId == null) continue;

      for (final dynamic priority in _cubit.priorityObjects) {
        final int? id = _readInt(priority, 'id', (dynamic object) => object.id);
        if (id == priorityId) {
          final String name =
          _readString(priority, 'name', (dynamic object) => object.name)
              .trim();
          if (name.isNotEmpty && !names.contains(name)) {
            names.add(name);
          }
          break;
        }
      }
    }

    final dynamic nested = _readNested(
      item,
      'priority_object',
          (dynamic object) => object.priorityObject,
      aliases: const <String>['priorityObject'],
    );

    final String nestedName =
    _readString(nested, 'name', (dynamic object) => object.name).trim();
    if (nestedName.isNotEmpty && !names.contains(nestedName)) {
      names.add(nestedName);
    }

    final int? singularId = _readInt(
      item,
      'priority_object_id',
          (dynamic object) => object.priorityObjectId,
      aliases: const <String>['priorityObjectId'],
    );

    if (singularId != null) {
      for (final dynamic priority in _cubit.priorityObjects) {
        final int? id = _readInt(priority, 'id', (dynamic object) => object.id);
        if (id == singularId) {
          final String name =
          _readString(priority, 'name', (dynamic object) => object.name)
              .trim();
          if (name.isNotEmpty && !names.contains(name)) {
            names.add(name);
          }
          break;
        }
      }
    }

    final String studentNames = _studentPriorityObjectName(student).trim();
    if (studentNames.isNotEmpty) {
      for (final String name in studentNames.split(',')) {
        final String normalized = name.trim();
        if (normalized.isNotEmpty && !names.contains(normalized)) {
          names.add(normalized);
        }
      }
    }

    return names.join(', ');
  }

  String _periodName(dynamic item) {
    final dynamic period = _registrationPeriod(item);

    final String name = _readString(
      period,
      'name',
          (dynamic object) => object.name,
    );

    if (name.isNotEmpty) {
      return name;
    }

    final String directName = _readString(
      item,
      'registrationPeriodName',
          (dynamic object) =>
      object.registrationPeriodName ?? '',
      aliases: const <String>[
        'registration_period_name',
      ],
    );

    if (directName.isNotEmpty) {
      return directName;
    }

    final int? periodId = _readInt(
      item,
      'registration_period_id',
          (dynamic object) =>
      object.registrationPeriodId,
      aliases: const <String>[
        'registrationPeriodId',
      ],
    );

    if (periodId != null) {
      return 'Đợt đăng ký nội trú';
    }

    return 'Đợt đăng ký nội trú';
  }

  String _dormitoryName(dynamic item) {
    final dynamic dormitory = _dormitory(item);

    if (dormitory is String && dormitory.trim().isNotEmpty) {
      return dormitory.trim();
    }

    final String nestedName = _readString(
      dormitory,
      'name',
          (dynamic object) => object.name,
    );
    if (nestedName.isNotEmpty) return nestedName;

    final int? dormitoryId = _dormitoryId(item);
    if (dormitoryId != null) {
      for (final dynamic value in _cubit.dormitories) {
        final int? id = _readInt(value, 'id', (dynamic object) => object.id);
        if (id == dormitoryId) {
          final String name =
          _readString(value, 'name', (dynamic object) => object.name);
          if (name.isNotEmpty) return name;
        }
      }
    }

    return 'Chưa xác định ký túc xá';
  }

  String _dormitoryAddress(dynamic item) {
    final dynamic dormitory = _dormitory(item);
    final String nestedAddress = _readString(
      dormitory,
      'address',
          (dynamic object) => object.address,
    );
    if (nestedAddress.isNotEmpty) return nestedAddress;

    final int? dormitoryId = _dormitoryId(item);
    if (dormitoryId != null) {
      for (final dynamic value in _cubit.dormitories) {
        final int? id = _readInt(value, 'id', (dynamic object) => object.id);
        if (id == dormitoryId) {
          return _readString(
            value,
            'address',
                (dynamic object) => object.address,
          );
        }
      }
    }

    return '';
  }

  String _roomTypeName(dynamic item) {
    final dynamic roomType = _roomType(item);

    if (roomType is String && roomType.trim().isNotEmpty) {
      return roomType.trim();
    }

    final String nestedName = _readString(
      roomType,
      'name',
          (dynamic object) => object.name,
    );
    if (nestedName.isNotEmpty) return nestedName;

    final int? roomTypeId = _readInt(
      item,
      'room_type_id',
          (dynamic object) => object.roomTypeId,
      aliases: const <String>['roomTypeId'],
    );

    if (roomTypeId != null) {
      for (final dynamic value in _roomTypes) {
        final int? id = _readInt(value, 'id', (dynamic object) => object.id);
        if (id == roomTypeId) {
          return _readString(value, 'name', (dynamic object) => object.name);
        }
      }
    }

    return '';
  }

  String _latestReceiptPriceText(dynamic item) {
    final DormitoryInvoiceModel? receipt = _latestReceipt;

    if (receipt == null || receipt.totalAmount <= 0) {
      return '';
    }

    final String amount =
        '${_formatPrice(receipt.totalAmount.toString())} đ';

    final DateTime? start =
        receipt.resolvedPeriodStartDate ?? _accommodationStartDate(item);
    final DateTime? end =
        receipt.resolvedPeriodEndDate ?? _accommodationEndDate(item);

    if (start != null && end != null) {
      return '$amount '
          '(${DateFormat('dd/MM/yy').format(start.toLocal())} - '
          '${DateFormat('dd/MM/yy').format(end.toLocal())})';
    }

    if (start != null) {
      return '$amount '
          '(từ ${DateFormat('dd/MM/yy').format(start.toLocal())})';
    }

    if (end != null) {
      return '$amount '
          '(đến ${DateFormat('dd/MM/yy').format(end.toLocal())})';
    }

    return amount;
  }

  String _roomNumber(dynamic item) {
    final dynamic room = _room(item);

    final String roomNumber = _readString(
      room,
      'room_number',
          (dynamic object) => object.roomNumber,
      aliases: const <String>['roomNumber'],
    );

    if (roomNumber.isNotEmpty) {
      return roomNumber;
    }

    return _readString(
      item,
      'assignedRoom',
          (dynamic object) =>
      object.assignedRoom ?? '',
      aliases: const <String>['assigned_room'],
    );
  }

  String _roomCapacity(dynamic item) {
    final dynamic room = _room(item);

    final int? capacity = _readInt(
      room,
      'capacity',
          (dynamic object) => object.capacity,
    );

    return capacity?.toString() ?? '';
  }

  String _roomCurrentOccupancy(dynamic item) {
    final dynamic room = _room(item);

    final int? currentOccupancy = _readInt(
      room,
      'current_occupancy',
          (dynamic object) =>
      object.currentOccupancy,
    );

    return currentOccupancy?.toString() ?? '';
  }

  // =========================================================
  // Trạng thái hồ sơ
  // =========================================================

  bool _hasBlockingRegistration(
      List<dynamic> accommodations,
      ) {
    if (accommodations.isEmpty) {
      return false;
    }

    final List<dynamic> sorted = List<dynamic>.from(accommodations);
    sorted.sort((dynamic first, dynamic second) {
      final DateTime firstTime =
          _accommodationCreatedAt(first) ??
              DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime secondTime =
          _accommodationCreatedAt(second) ??
              DateTime.fromMillisecondsSinceEpoch(0);

      final int timeCompare = secondTime.compareTo(firstTime);
      if (timeCompare != 0) {
        return timeCompare;
      }

      final int firstId =
          int.tryParse(_accommodationId(first)?.toString() ?? '') ?? 0;
      final int secondId =
          int.tryParse(_accommodationId(second)?.toString() ?? '') ?? 0;
      return secondId.compareTo(firstId);
    });

    final String latestStatus =
    _accommodationStatus(sorted.first).trim().toLowerCase();

    // Chỉ ba trạng thái này mới ẩn nút đăng ký mới.
    return latestStatus == 'approved' ||
        latestStatus == 'assigned' ||
        latestStatus == 'active';
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return Colors.orange;

      case 'pending':
        return AppTheme.colorWarning;

      case 'approved':
        return Colors.blue;

      case 'assigned':
      case 'active':
        return AppTheme.colorSuccess;

      case 'rejected':
      case 'terminated':
        return AppTheme.colorError;

      case 'checkout':
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return Icons.edit_note;

      case 'pending':
        return Icons.hourglass_top_rounded;

      case 'approved':
        return Icons.verified_rounded;

      case 'assigned':
        return Icons.meeting_room_rounded;

      case 'active':
        return Icons.home_rounded;

      case 'rejected':
        return Icons.cancel_rounded;

      case 'checkout':
        return Icons.logout_rounded;

      case 'terminated':
        return Icons.block_rounded;

      default:
        return Icons.info_outline_rounded;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return 'Bản nháp cũ';

      case 'pending':
        return 'Chờ duyệt';

      case 'approved':
        return 'Đã duyệt';

      case 'assigned':
        return 'Đã xếp phòng';

      case 'active':
        return 'Đang ở';

      case 'rejected':
        return 'Từ chối';

      case 'checkout':
        return 'Đã trả phòng';

      case 'terminated':
        return 'Chấm dứt';

      default:
        return 'Không xác định';
    }
  }

  // =========================================================
  // Giao diện chính
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Ký túc xá của tôi',
      floatingActionButton: BlocBuilder<
          DormitoryRegistrationCubit,
          DormitoryRegistrationState>(
        bloc: _cubit,
        builder: (
            BuildContext context,
            DormitoryRegistrationState state,
            ) {
          final dynamic data = _readDataFromState(state);

          // Chưa tải xong dữ liệu hồ sơ thì chưa kết luận việc hiển thị nút.
          if (data == null) {
            return const SizedBox.shrink();
          }

          final List<dynamic> accommodations = _readAccommodations(data);

          // Chỉ ẩn khi hồ sơ mới nhất là APPROVED, ASSIGNED hoặc ACTIVE.
          if (_hasBlockingRegistration(accommodations)) {
            return const SizedBox.shrink();
          }

          final bool canRegister =
              _hasOpenRegistrationPeriod &&
                  !_isCheckingOpenRegistrationPeriod;

          return FloatingActionButton.extended(
            onPressed: canRegister ? _goToRegisterFlow : null,
            backgroundColor: canRegister
                ? const Color(0xFF078B3E)
                : const Color(0xFFBDBDBD),
            foregroundColor: Colors.white,
            elevation: canRegister ? 4 : 0,
            icon: _isCheckingOpenRegistrationPeriod
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(
              Icons.app_registration,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              _isCheckingOpenRegistrationPeriod
                  ? 'Đang kiểm tra'
                  : 'Đăng ký mới',
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppFontSizes.mediumSmall,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
      body: ProgressHubWidget(
        contextComplete: (BuildContext context) {
          _hubContext = context;
        },
        child: BlocListener<
            DormitoryRegistrationCubit,
            DormitoryRegistrationState>(
          bloc: _cubit,
          listener: (
              BuildContext context,
              DormitoryRegistrationState state,
              ) {
            if (state
            is DormitoryRegistrationShowHub) {
              Utils.showProgress(_hubContext);
            }

            if (state
            is DormitoryRegistrationDismissHub) {
              Utils.dismissProgress(_hubContext);
            }

            if (state
            is DormitoryRegistrationSavedSuccess) {
              snackBarSuccess(state.message);
              _refreshData();
            }

            if (state
            is DormitoryRegistrationError) {
              snackBarError(state.message);
            }
          },
          child: BlocBuilder<
              DormitoryRegistrationCubit,
              DormitoryRegistrationState>(
            bloc: _cubit,
            builder: (
                BuildContext context,
                DormitoryRegistrationState state,
                ) {
              if (state
              is DormitoryRegistrationLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.colorMain,
                  ),
                );
              }

              final dynamic data =
              _readDataFromState(state);

              if (data == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.colorMain,
                  ),
                );
              }

              final dynamic student =
              _readStudent(data);

              final List<dynamic> accommodations =
              _readAccommodations(data);

              accommodations.sort((
                  dynamic first,
                  dynamic second,
                  ) {
                final DateTime firstTime =
                    _accommodationCreatedAt(first) ??
                        DateTime.fromMillisecondsSinceEpoch(0);

                final DateTime secondTime =
                    _accommodationCreatedAt(second) ??
                        DateTime.fromMillisecondsSinceEpoch(0);

                final int timeCompare =
                secondTime.compareTo(firstTime);

                if (timeCompare != 0) {
                  return timeCompare;
                }

                final Object? firstId =
                _accommodationId(first);

                final Object? secondId =
                _accommodationId(second);

                final int firstInt = firstId is int
                    ? firstId
                    : int.tryParse(
                  firstId?.toString() ?? '',
                ) ??
                    0;

                final int secondInt = secondId is int
                    ? secondId
                    : int.tryParse(
                  secondId?.toString() ?? '',
                ) ??
                    0;

                return secondInt.compareTo(firstInt);
              });

              if (accommodations.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView(
                    physics:
                    const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.of(context)
                            .size
                            .height *
                            0.25,
                      ),
                      const Center(
                        child: Text(
                          'Chưa có thông tin đăng ký ký túc xá',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize:
                            AppFontSizes.mediumSmall,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    // Trạng thái mới nhất được hiển thị ở đầu màn hình.
                    // Danh sách accommodations đã được ghép giữa bản tóm tắt
                    // và bản chi tiết nên vẫn có đủ KTX, đợt và trạng thái.
                    _buildCurrentRegistrationStatusCard(
                      accommodations.first,
                    ),
                    const SizedBox(height: 16),
                    _buildStudentCard(student),
                    const SizedBox(height: 16),
                    // Giữ nguyên toàn bộ card hồ sơ chi tiết phía dưới.
                    ...accommodations.asMap().entries.map(
                          (MapEntry<int, dynamic> entry) =>
                          _buildAccommodationCard(
                            entry.value,
                            student,
                            isLatest: entry.key == 0,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentRegistrationStatusCard(dynamic item) {
    final String status = _accommodationStatus(item);
    final Color statusColor = _getStatusColor(status);
    final DateTime? createdAt = _accommodationCreatedAt(item);
    final String dormitoryName = _dormitoryName(item);
    final String periodName = _periodName(item);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: statusColor.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: statusColor.withOpacity(0.28),
        ),
      ),
      child: InkWell(
        onTap: () => _showHistory(_accommodationId(item)),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  _getStatusIcon(status),
                  color: statusColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'TRẠNG THÁI HỒ SƠ HIỆN TẠI',
                      style: TextStyle(
                        fontSize: AppFontSizes.font11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF666B75),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusText(status),
                      style: TextStyle(
                        fontSize: AppFontSizes.medium,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$dormitoryName · $periodName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSizes.font11,
                        color: Color(0xFF444A55),
                        height: 1.35,
                      ),
                    ),
                    if (createdAt != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        'Ngày đăng ký: '
                            '${DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toLocal())}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.font11,
                          color: Color(0xFF737982),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: statusColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(dynamic student) {
    final DateTime? dob = _studentDateOfBirth(student);
    final String identityNo = _studentIdentityNo(student);
    final String identityType = _studentIdentityType(student);
    final String gender = _studentGender(student);
    final String academicYear = _studentAcademicYear(student);
    final String level = _studentLevel(student);
    final String permanentAddress = _studentPermanentAddress(student);
    final String temporaryAddress = _studentTemporaryAddress(student);
    final String priorityObject = _studentPriorityObjectName(student);

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(
                  Icons.person_rounded,
                  color: Color(0xFF078B3E),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Thông tin sinh viên',
                  style: TextStyle(
                    fontSize: AppFontSizes.mediumSmall,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111318),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildInfoRow('Họ và tên:', _studentFullName(student)),
            _buildInfoRow('Mã SV:', _studentCodeText(student)),
            if (identityNo.isNotEmpty)
              _buildInfoRow(
                identityType.isNotEmpty ? '$identityType:' : 'CCCD:',
                identityNo,
              ),
            if (dob != null)
              _buildInfoRow(
                'Ngày sinh:',
                DateFormat('dd/MM/yyyy').format(dob.toLocal()),
              ),
            if (gender.isNotEmpty) _buildInfoRow('Giới tính:', gender),
            if (_studentClass(student).isNotEmpty)
              _buildInfoRow('Lớp:', _studentClass(student)),
            if (_studentMajor(student).isNotEmpty)
              _buildInfoRow('Ngành:', _studentMajor(student)),
            if (academicYear.isNotEmpty)
              _buildInfoRow('Năm nhập học:', academicYear),
            if (level.isNotEmpty) _buildInfoRow('Trình độ:', level),
            if (_studentPhone(student).isNotEmpty)
              _buildInfoRow('SĐT:', _studentPhone(student)),
            if (_studentEmail(student).isNotEmpty)
              _buildInfoRow('Email:', _studentEmail(student)),
            if (_studentUniversity(student).isNotEmpty)
              _buildInfoRow('Trường:', _studentUniversity(student)),
            if (priorityObject.isNotEmpty)
              _buildInfoRow('Đối tượng ưu tiên:', priorityObject),
            if (permanentAddress.isNotEmpty)
              _buildInfoRow('Thường trú:', permanentAddress),
            if (temporaryAddress.isNotEmpty)
              _buildInfoRow('Tạm trú:', temporaryAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildAccommodationCard(
      dynamic item,
      dynamic student, {
        required bool isLatest,
      }) {
    final String status = _accommodationStatus(item);
    final String periodName = _periodName(item);
    final String periodDescription = _periodDescription(item);
    final DateTime? periodStart = _periodStartTime(item);
    final DateTime? periodEnd = _periodEndTime(item);

    final String dormitoryName = _dormitoryName(item);
    final String dormitoryAddress = _dormitoryAddress(item);
    final String priorityObjectName = _priorityObjectName(item, student);

    final String roomTypeName = _roomTypeName(item);
    final String latestReceiptPrice =
    isLatest ? _latestReceiptPriceText(item) : '';
    final String roomNumber = _roomNumber(item);
    final String roomCapacity = _roomCapacity(item);
    final String roomCurrentOccupancy = _roomCurrentOccupancy(item);

    final DateTime? createdAt = _accommodationCreatedAt(item);
    final DateTime? updatedAt = _accommodationUpdatedAt(item);
    final DateTime? approvedAt = _accommodationApprovedAt(item);
    final DateTime? assignedAt = _accommodationAssignedAt(item);
    final DateTime? checkinAt = _accommodationCheckinAt(item);
    final DateTime? checkoutAt = _accommodationCheckoutAt(item);
    final DateTime? startDate = _accommodationStartDate(item);
    final DateTime? endDate = _accommodationEndDate(item);

    final String reasonStay = _accommodationReasonStay(item);
    final String requestStatus = _requestStatusText(item);
    final bool? isRoomLeader = _accommodationIsRoomLeader(item);
    final String note = _accommodationNote(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => _showHistory(_accommodationId(item)),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      _getStatusIcon(status),
                      size: 20,
                      color: _getStatusColor(status),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      periodName,
                      style: const TextStyle(
                        fontSize: AppFontSizes.mediumSmall,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111318),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(status),
                ],
              ),
              const Divider(height: 22),

              _buildSectionTitle(
                icon: Icons.apartment_rounded,
                title: 'Thông tin ký túc xá',
              ),
              _buildInfoRow('Khu nội trú:', dormitoryName),
              if (dormitoryAddress.isNotEmpty)
                _buildInfoRow('Địa chỉ:', dormitoryAddress),

              const SizedBox(height: 10),
              _buildSectionTitle(
                icon: Icons.description_outlined,
                title: 'Thông tin hồ sơ',
              ),
              _buildInfoRow('Đợt đăng ký:', periodName),
              if (periodDescription.isNotEmpty)
                _buildInfoRow('Mô tả đợt:', periodDescription),
              if (periodStart != null)
                _buildInfoRow(
                  'Mở đăng ký:',
                  DateFormat('dd/MM/yyyy HH:mm').format(periodStart.toLocal()),
                ),
              if (periodEnd != null)
                _buildInfoRow(
                  'Đóng đăng ký:',
                  DateFormat('dd/MM/yyyy HH:mm').format(periodEnd.toLocal()),
                ),
              if (priorityObjectName.isNotEmpty)
                _buildInfoRow('Đối tượng ưu tiên:', priorityObjectName),
              if (reasonStay.isNotEmpty)
                _buildInfoRow('Lý do lưu trú:', reasonStay),
              if (_accommodationRequestType(item).isNotEmpty &&
                  requestStatus.isNotEmpty)
                _buildInfoRow('Trạng thái yêu cầu:', requestStatus),
              if (isRoomLeader != null)
                _buildInfoRow(
                  'Trưởng phòng:',
                  isRoomLeader ? 'Có' : 'Không',
                ),
              if (startDate != null)
                _buildInfoRow(
                  'Thời gian ở từ:',
                  DateFormat('dd/MM/yyyy').format(startDate.toLocal()),
                ),
              if (endDate != null)
                _buildInfoRow(
                  'Thời gian ở đến:',
                  DateFormat('dd/MM/yyyy').format(endDate.toLocal()),
                ),
              if (createdAt != null)
                _buildInfoRow(
                  'Ngày đăng ký:',
                  DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toLocal()),
                ),
              if (updatedAt != null &&
                  (createdAt == null || updatedAt != createdAt))
                _buildInfoRow(
                  'Cập nhật gần nhất:',
                  DateFormat('dd/MM/yyyy HH:mm').format(updatedAt.toLocal()),
                ),
              if (note.isNotEmpty) _buildInfoRow('Ghi chú:', note),

              if (roomTypeName.isNotEmpty ||
                  roomNumber.isNotEmpty ||
                  latestReceiptPrice.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                _buildSectionTitle(
                  icon: Icons.meeting_room_outlined,
                  title: 'Thông tin xếp phòng',
                ),
                if (roomTypeName.isNotEmpty)
                  _buildInfoRow('Loại phòng:', roomTypeName),
                if (latestReceiptPrice.isNotEmpty)
                  _buildInfoRow(
                    'Giá phòng:',
                    latestReceiptPrice,
                  ),
                if (roomNumber.isNotEmpty) _buildInfoRow('Phòng:', roomNumber),
                if (roomCapacity.isNotEmpty)
                  _buildInfoRow(
                    'Sức chứa:',
                    roomCurrentOccupancy.isNotEmpty
                        ? '$roomCurrentOccupancy/$roomCapacity người'
                        : '$roomCapacity người',
                  ),
              ],

              if (approvedAt != null ||
                  assignedAt != null ||
                  checkinAt != null ||
                  checkoutAt != null) ...<Widget>[
                const SizedBox(height: 10),
                _buildSectionTitle(
                  icon: Icons.timeline_rounded,
                  title: 'Mốc xử lý',
                ),
                if (approvedAt != null)
                  _buildInfoRow(
                    'Ngày duyệt:',
                    DateFormat('dd/MM/yyyy HH:mm').format(approvedAt.toLocal()),
                  ),
                if (assignedAt != null)
                  _buildInfoRow(
                    'Ngày xếp phòng:',
                    DateFormat('dd/MM/yyyy HH:mm').format(assignedAt.toLocal()),
                  ),
                if (checkinAt != null)
                  _buildInfoRow(
                    'Ngày nhận phòng:',
                    DateFormat('dd/MM/yyyy HH:mm').format(checkinAt.toLocal()),
                  ),
                if (checkoutAt != null)
                  _buildInfoRow(
                    'Ngày trả phòng:',
                    DateFormat('dd/MM/yyyy HH:mm').format(checkoutAt.toLocal()),
                  ),
              ],

              const SizedBox(height: 14),
              _buildActionArea(item, student),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    'Xem lịch sử xử lý',
                    style: TextStyle(
                      fontSize: AppFontSizes.font11,
                      color: Color(0xFF078B3E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: Color(0xFF078B3E),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: const Color(0xFF078B3E)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppFontSizes.font11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF078B3E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(
      dynamic item,
      dynamic student,
      ) {
    final String status =
    _accommodationStatus(item);

    if (status == 'draft') {
      return _buildNoticeBox(
        icon: Icons.info_outline_rounded,
        color: Colors.orange,
        text:
        'Bản nháp cũ không còn được hỗ trợ. '
            'Vui lòng tạo đăng ký mới.',
      );
    }

    if (status == 'rejected') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.colorError
              .withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Hồ sơ đã bị từ chối. Bạn có thể đăng ký '
              'lại nếu đợt đăng ký còn mở.',
          style: TextStyle(
            fontSize: AppFontSizes.font11,
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (status == 'approved' ||
        status == 'assigned' ||
        status == 'active') {
      final bool hasRoomType = _roomTypeName(item).isNotEmpty;
      final bool hasRoom = _roomNumber(item).isNotEmpty;

      String notice;
      IconData noticeIcon;

      if (status == 'active') {
        noticeIcon = Icons.home_rounded;
        notice = 'Bạn đang lưu trú tại ký túc xá. '
            'Vui lòng theo dõi hóa đơn và trạng thái thanh toán.';
      } else if (status == 'assigned' || hasRoom) {
        noticeIcon = Icons.meeting_room_rounded;
        notice = 'Hồ sơ đã được duyệt và bạn đã được xếp phòng. '
            'Vui lòng kiểm tra thông tin phòng và hóa đơn.';
      } else if (hasRoomType) {
        noticeIcon = Icons.bed_rounded;
        notice = 'Hồ sơ đã được duyệt và đã có loại phòng. '
            'Vui lòng kiểm tra hóa đơn và chờ xếp phòng cụ thể.';
      } else {
        noticeIcon = Icons.verified_rounded;
        notice = 'Hồ sơ đã được duyệt. Ban quản lý chưa trả '
            'thông tin loại phòng hoặc phòng cụ thể.';
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildNoticeBox(
            icon: noticeIcon,
            color: AppTheme.colorSuccess,
            text: notice,
          ),
          const SizedBox(height: 12),
          _buildInvoiceButton(item, student),
          if (status == 'assigned' || status == 'active') ...<Widget>[
            const SizedBox(height: 12),
            _buildAccommodationRequestActions(item),
          ],
        ],
      );
    }

    if (status == 'pending') {
      return _buildNoticeBox(
        icon: Icons.hourglass_top_rounded,
        color: AppTheme.colorWarning,
        text:
        'Hồ sơ đang chờ ban quản lý '
            'xét duyệt.',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildAccommodationRequestActions(dynamic item) {
    final String requestType = _accommodationRequestType(item);
    final bool hasPendingRequest = _hasPendingAccommodationRequest(item);

    if (hasPendingRequest) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildNoticeBox(
            icon: requestType == 'checkout'
                ? Icons.logout_rounded
                : Icons.swap_horiz_rounded,
            color: Colors.orange,
            text:
            '${_requestTypeText(requestType)} đang chờ ban quản lý xử lý.',
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSubmittingAccommodationRequest
                  ? null
                  : () => _confirmCancelAccommodationRequest(item),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Hủy yêu cầu'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.colorError,
                side: BorderSide(color: AppTheme.colorError),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Yêu cầu lưu trú',
          style: TextStyle(
            fontSize: AppFontSizes.font11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF078B3E),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmittingAccommodationRequest
                    ? null
                    : () => _openChangeRoomRequest(item),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Chuyển phòng'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF078B3E),
                  side: const BorderSide(color: Color(0xFF078B3E)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isSubmittingAccommodationRequest
                    ? null
                    : () => _openCheckoutRequest(item),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Trả phòng'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<String?> _showAccommodationRequestBottomSheet({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required String noteLabel,
    required String noteHint,
    String? currentRoom,
  }) async {
    final TextEditingController noteController = TextEditingController();

    final String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (BuildContext sheetContext) {
        final double keyboardHeight =
            MediaQuery.of(sheetContext).viewInsets.bottom;

        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3E6EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            color: color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: AppFontSizes.medium,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111318),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Đóng',
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (currentRoom != null &&
                        currentRoom.trim().isNotEmpty) ...<Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.meeting_room_outlined,
                              size: 19,
                              color: Color(0xFF667085),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Phòng hiện tại: $currentRoom',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.font11,
                                  color: Color(0xFF344054),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: AppFontSizes.font11,
                        color: Color(0xFF666B75),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteController,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 500,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        labelText: noteLabel,
                        hintText: noteHint,
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: const Color(0xFFFAFBFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFD0D5DD),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFD0D5DD),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: color,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475467),
                              side: const BorderSide(
                                color: Color(0xFFD0D5DD),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Đóng'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(
                              sheetContext,
                              noteController.text.trim(),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.send_rounded,
                              size: 18,
                            ),
                            label: const Text('Gửi yêu cầu'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    noteController.dispose();
    return result;
  }

  Future<void> _openChangeRoomRequest(dynamic item) async {
    final int? registrationId =
    int.tryParse(_accommodationId(item)?.toString() ?? '');

    if (registrationId == null) {
      snackBarError('Không tìm thấy mã hồ sơ nội trú');
      return;
    }

    final String roomNumber = _roomNumber(item);
    final String? note = await _showAccommodationRequestBottomSheet(
      title: 'Yêu cầu chuyển phòng',
      icon: Icons.swap_horiz_rounded,
      color: const Color(0xFF078B3E),
      currentRoom: roomNumber.isEmpty ? null : roomNumber,
      description:
      'Ứng dụng chỉ ghi nhận yêu cầu chuyển phòng. Ban quản lý '
          'ký túc xá sẽ kiểm tra và thực hiện việc chuyển phòng sau.',
      noteLabel: 'Lý do chuyển phòng',
      noteHint: 'Nhập lý do hoặc thông tin phòng mong muốn',
    );

    if (note == null) {
      return;
    }

    await _submitAccommodationRequest(
      registrationId: registrationId,
      type: 'change_room',
      note: note,
      successMessage: 'Đã gửi yêu cầu chuyển phòng',
    );
  }

  Future<void> _openCheckoutRequest(dynamic item) async {
    final int? registrationId =
    int.tryParse(_accommodationId(item)?.toString() ?? '');

    if (registrationId == null) {
      snackBarError('Không tìm thấy mã hồ sơ nội trú');
      return;
    }

    final String roomNumber = _roomNumber(item);
    final String? note = await _showAccommodationRequestBottomSheet(
      title: 'Yêu cầu trả phòng',
      icon: Icons.logout_rounded,
      color: Colors.orange.shade700,
      currentRoom: roomNumber.isEmpty ? null : roomNumber,
      description:
      'Yêu cầu trả phòng sẽ được gửi đến Ban quản lý ký túc xá. '
          'Hệ thống chỉ ghi nhận yêu cầu và chưa tự động kết thúc lưu trú.',
      noteLabel: 'Lý do trả phòng',
      noteHint: 'Nhập lý do trả phòng',
    );

    if (note == null) {
      return;
    }

    await _submitAccommodationRequest(
      registrationId: registrationId,
      type: 'checkout',
      note: note,
      successMessage: 'Đã gửi yêu cầu trả phòng',
    );
  }

  Future<void> _confirmCancelAccommodationRequest(dynamic item) async {
    final int? registrationId =
    int.tryParse(_accommodationId(item)?.toString() ?? '');
    if (registrationId == null) {
      snackBarError('Không tìm thấy mã hồ sơ nội trú');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hủy yêu cầu'),
          content: const Text(
            'Bạn có chắc chắn muốn hủy yêu cầu đang chờ xử lý không?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Không'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.colorError,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hủy yêu cầu'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _submitAccommodationRequest(
      registrationId: registrationId,
      type: 'none',
      successMessage: 'Đã hủy yêu cầu',
    );
  }

  Future<void> _submitAccommodationRequest({
    required int registrationId,
    required String type,
    int? desiredRoomId,
    String? note,
    required String successMessage,
  }) async {
    if (_isSubmittingAccommodationRequest) {
      return;
    }

    const Set<String> allowedTypes = <String>{
      'change_room',
      'checkout',
      'none',
    };

    if (!allowedTypes.contains(type)) {
      snackBarError('Loại yêu cầu không hợp lệ');
      return;
    }

    final String normalizedNote = note?.trim() ?? '';
    if (normalizedNote.length > 500) {
      snackBarError('Lý do không được vượt quá 500 ký tự');
      return;
    }

    if (mounted) {
      setState(() {
        _isSubmittingAccommodationRequest = true;
      });
    }

    try {
      await _repository.updateAccommodationRequestStatus(
        registrationId: registrationId,
        type: type,
        desiredRoomId: desiredRoomId,
        note: normalizedNote.isEmpty ? null : normalizedNote,
      );

      if (!mounted) {
        return;
      }

      snackBarSuccess(successMessage);
      await _refreshData();
    } catch (error) {
      if (mounted) {
        snackBarError(
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAccommodationRequest = false;
        });
      }
    }
  }

  Widget _buildInvoiceButton(
      dynamic item,
      dynamic student,
      ) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          final String identityNo =
          _studentIdentityNo(student);

          final int? dormitoryId =
          _dormitoryId(item);

          if (identityNo.isEmpty) {
            snackBarError(
              'Không tìm thấy số CCCD '
                  'của sinh viên',
            );
            return;
          }

          if (dormitoryId == null) {
            snackBarError(
              'Không tìm thấy mã ký túc xá',
            );
            return;
          }

          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (
                  BuildContext context,
                  ) {
                return DRInvoicesScreen(
                  identityNo: identityNo,
                  dormitoryId: dormitoryId,
                  dormitoryName: _dormitoryName(item),
                  accommodationStartDate:
                  _accommodationStartDate(item),
                  accommodationEndDate:
                  _accommodationEndDate(item),
                );
              },
            ),
          );
        },
        style: FilledButton.styleFrom(
          backgroundColor:
          const Color(0xFF078B3E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(
          Icons.receipt_long_rounded,
        ),
        label: const Text(
          'Hóa đơn & thanh toán',
        ),
      ),
    );
  }

  Widget _buildNoticeBox({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppFontSizes.font11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final Color color =
    _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: AppFontSizes.extraSmall,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      String label,
      String value,
      ) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
      const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                fontSize:
                AppFontSizes.font11,
                color: Color(0xFF666B75),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize:
                AppFontSizes.font11,
                color: Color(0xFF111318),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(String value) {
    final String raw =
    value.replaceAll(',', '');

    final double? number =
    double.tryParse(raw);

    if (number == null) {
      return value;
    }

    return NumberFormat(
      '#,###',
      'vi_VN',
    ).format(number);
  }

  void _showHistory(
      Object? accommodationId,
      ) {
    if (accommodationId == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DRHistoryBottomSheet(
          registrationId: accommodationId,
        );
      },
    );
  }

  Future<void> _goToRegisterFlow() async {
    if (!_hasOpenRegistrationPeriod) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.grey[700],
          content: Text(
            _registrationPeriodMessage ??
                'Hiện chưa có đợt đăng ký '
                    'nội trú nào đang mở',
          ),
        ),
      );

      return;
    }

    final dynamic result =
    await Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) =>
        const DRWizardFlow(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result is String &&
        result.isNotEmpty) {
      await _refreshData();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
          const Color(0xFF078B3E),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(14),
          ),
          content: Row(
            children: <Widget>[
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(result),
              ),
            ],
          ),
        ),
      );

      return;
    }

    if (result == true) {
      await _refreshData();
    }
  }
}
