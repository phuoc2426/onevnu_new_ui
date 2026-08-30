import 'package:vnu_core/common/error/app_feedback.dart';
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
import 'package:vnu_noi_tru/models/dormitory_registration/accommodation_status_model.dart';
import 'package:vnu_noi_tru/repository/dormitory_payment_repository.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_noi_tru/repository/dormitory_registration_repository.dart';
import 'package:vnu_noi_tru/widgets/dormitory_leather_wallet_3d.dart';

import 'dr_history_bottom_sheet.dart';
import 'dr_wizard_flow.dart';
import 'dr_invoices_screen.dart';
import 'dr_student_update_sheet.dart';
import 'dr_student_history_sheet.dart';
import 'package:vnu_core/widgets/field/vnu_text_field.dart';

class DRMyRegistrationScreen extends StatefulWidget {
  const DRMyRegistrationScreen({super.key});

  @override
  State<DRMyRegistrationScreen> createState() => _DRMyRegistrationScreenState();
}

class _DRMyRegistrationScreenState extends State<DRMyRegistrationScreen> {
  final DormitoryRegistrationCubit _cubit = DormitoryRegistrationCubit();

  final DormitoryRegistrationRepository _repository =
      DormitoryRegistrationRepository();

  final DormitoryPaymentRepository _paymentRepository =
      DormitoryPaymentRepository();

  List<dynamic> _roomTypes = <dynamic>[];
  DormitoryInvoiceModel? _latestReceipt;
  List<DormitoryInvoiceModel> _dashboardReceipts = <DormitoryInvoiceModel>[];
  List<DormitoryAccommodationStatusModel> _statusCatalog =
      <DormitoryAccommodationStatusModel>[];
  Map<String, dynamic>? _fullStudentProfile;

  late BuildContext _hubContext;

  bool _hasOpenRegistrationPeriod = false;
  bool _isCheckingOpenRegistrationPeriod = true;
  bool _isSubmittingAccommodationRequest = false;

  String? _registrationPeriodMessage;

  // Số ngày dự kiến duyệt của đúng đợt thuộc hồ sơ mới nhất.
  // Chỉ dùng khi hồ sơ mới nhất đang ở trạng thái pending.
  int? _latestPendingMaxApprovalDays;
  int _pendingApprovalLookupSerial = 0;

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
    await _loadStatusCatalog();

    final bool hasOpenPeriod = await _cubit.checkAnyOpenRegistrationPeriod();

    if (mounted) {
      setState(() {
        _hasOpenRegistrationPeriod = hasOpenPeriod;
        _isCheckingOpenRegistrationPeriod = false;
        _registrationPeriodMessage = _cubit.openPeriodMessage;
      });
    }

    await _cubit.getMyRegistrations();
    await _loadFullStudentProfileFromCurrentState();
    await _loadLatestPendingApprovalDaysFromCurrentState();
    await _loadLatestReceiptFromCurrentState();
  }

  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _isCheckingOpenRegistrationPeriod = true;
      });
    }

    await _loadRoomTypesForDisplay();
    await _loadStatusCatalog();

    final bool hasOpenPeriod = await _cubit.checkAnyOpenRegistrationPeriod();

    if (mounted) {
      setState(() {
        _hasOpenRegistrationPeriod = hasOpenPeriod;
        _isCheckingOpenRegistrationPeriod = false;
        _registrationPeriodMessage = _cubit.openPeriodMessage;
      });
    }

    await _cubit.getMyRegistrations();
    await _loadFullStudentProfileFromCurrentState();
    await _loadLatestPendingApprovalDaysFromCurrentState();
    await _loadLatestReceiptFromCurrentState();
  }

  Future<void> _loadFullStudentProfileFromCurrentState() async {
    final dynamic data = _readDataFromState(_cubit.state);
    dynamic student;
    if (data is Map) {
      student = data['student'];
    } else {
      try {
        student = data?.student;
      } catch (_) {
        student = null;
      }
    }

    final String studentCode = _studentCodeText(student).trim();
    String identityNo = _studentIdentityNo(student).trim();
    if (identityNo.isEmpty) {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      identityNo = preferences.getString('applicant_cccd')?.trim() ?? '';
    }

    if (studentCode.isEmpty && identityNo.isEmpty) {
      if (mounted && _fullStudentProfile != null) {
        setState(() => _fullStudentProfile = null);
      } else {
        _fullStudentProfile = null;
      }
      return;
    }

    try {
      final Map<String, dynamic>? profile = await _repository.getStudentProfile(
        studentCode: studentCode,
        identityNo: identityNo,
      );
      if (!mounted) {
        _fullStudentProfile = profile;
        return;
      }
      setState(() => _fullStudentProfile = profile);
    } catch (_) {
      // /dormitory/me vẫn là nguồn chính; profile đầy đủ chỉ bổ sung familyMembers.
    }
  }

  Future<void> _loadStatusCatalog() async {
    try {
      final List<DormitoryAccommodationStatusModel> values =
          await _repository.getAccommodationStatuses();
      if (!mounted) {
        _statusCatalog = values;
        return;
      }
      setState(() => _statusCatalog = values);
    } catch (_) {
      // Progressive enhancement only. Local labels/colors remain the fallback.
    }
  }

  DormitoryAccommodationStatusModel? _statusCatalogItem(String? status) {
    final String value = status?.trim() ?? '';
    if (value.isEmpty) return null;
    for (final DormitoryAccommodationStatusModel item in _statusCatalog) {
      if (item.matches(value)) return item;
    }
    return null;
  }

  Color? _statusCatalogColor(String? status) {
    final String raw = _statusCatalogItem(status)?.color.trim() ?? '';
    if (raw.isEmpty) return null;
    String hex = raw.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final int? value = int.tryParse(hex, radix: 16);
    return value == null ? null : Color(value);
  }

  Future<void> _loadLatestPendingApprovalDaysFromCurrentState() async {
    final int requestSerial = ++_pendingApprovalLookupSerial;
    final dynamic data = _readDataFromState(_cubit.state);
    final List<dynamic> accommodations = _readAccommodations(data);

    accommodations.sort((dynamic first, dynamic second) {
      final DateTime firstTime =
          _accommodationCreatedAt(first) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime secondTime =
          _accommodationCreatedAt(second) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final int timeCompare = secondTime.compareTo(firstTime);
      if (timeCompare != 0) return timeCompare;

      final int firstId =
          int.tryParse(_accommodationId(first)?.toString() ?? '') ?? 0;
      final int secondId =
          int.tryParse(_accommodationId(second)?.toString() ?? '') ?? 0;
      return secondId.compareTo(firstId);
    });

    if (accommodations.isEmpty ||
        _accommodationStatus(accommodations.first) != 'pending') {
      _setLatestPendingMaxApprovalDays(null, requestSerial);
      return;
    }

    final dynamic latestAccommodation = accommodations.first;
    final int? registrationPeriodId = _registrationPeriodId(
      latestAccommodation,
    );
    final int? dormitoryId = _resolveDormitoryIdForAccommodation(
      latestAccommodation,
    );

    if (registrationPeriodId == null || dormitoryId == null) {
      _setLatestPendingMaxApprovalDays(null, requestSerial);
      return;
    }

    try {
      final dynamic response = await _repository.getRegistrationPeriods(
        dormitoryId: dormitoryId,
      );
      final List<dynamic> periods = List<dynamic>.from(
        response.data?.items ?? const <dynamic>[],
      );

      dynamic matchedPeriod;
      for (final dynamic period in periods) {
        final int? periodId = _readInt(
          period,
          'id',
          (dynamic object) => object.id,
        );
        if (periodId == registrationPeriodId) {
          matchedPeriod = period;
          break;
        }
      }

      // Không lấy maxApprovalDays của đợt khác. Endpoint hiện trả đợt active
      // mới nhất, nên chỉ dùng khi id trùng đúng đợt của hồ sơ mới nhất.
      final int? maxApprovalDays = matchedPeriod == null
          ? null
          : _readInt(
              matchedPeriod,
              'max_approval_days',
              (dynamic object) => object.maxApprovalDays,
              aliases: const <String>['maxApprovalDays'],
            );

      _setLatestPendingMaxApprovalDays(
        maxApprovalDays != null && maxApprovalDays > 0 ? maxApprovalDays : null,
        requestSerial,
      );
    } catch (_) {
      // Banner vẫn hiển thị trạng thái chờ duyệt, chỉ bỏ phần số ngày khi
      // không lấy được thông tin đợt đăng ký.
      _setLatestPendingMaxApprovalDays(null, requestSerial);
    }
  }

  void _setLatestPendingMaxApprovalDays(int? value, int requestSerial) {
    if (requestSerial != _pendingApprovalLookupSerial) return;

    if (!mounted) {
      _latestPendingMaxApprovalDays = value;
      return;
    }

    if (_latestPendingMaxApprovalDays == value) return;

    setState(() {
      _latestPendingMaxApprovalDays = value;
    });
  }

  Future<void> _loadLatestReceiptFromCurrentState() async {
    final dynamic data = _readDataFromState(_cubit.state);
    final dynamic student = _readStudent(data);

    String identityNo = _studentIdentityNo(student).trim();

    if (identityNo.isEmpty) {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      identityNo = preferences.getString('applicant_cccd')?.trim() ?? '';
    }

    if (identityNo.isEmpty) {
      if (mounted) {
        setState(() {
          _latestReceipt = null;
          _dashboardReceipts = <DormitoryInvoiceModel>[];
        });
      } else {
        _latestReceipt = null;
        _dashboardReceipts = <DormitoryInvoiceModel>[];
      }
      return;
    }

    try {
      final DormitoryInvoiceResponse response = await _paymentRepository
          .getReceipts(identityNo: identityNo);

      final List<DormitoryInvoiceModel> receipts =
          List<DormitoryInvoiceModel>.from(response.invoices);

      receipts.sort(_compareReceiptNewestFirst);

      final DormitoryInvoiceModel? latest = receipts.isEmpty
          ? null
          : receipts.first;

      if (!mounted) {
        _latestReceipt = latest;
        _dashboardReceipts = receipts;
        return;
      }

      setState(() {
        _latestReceipt = latest;
        _dashboardReceipts = receipts;
      });
    } catch (_) {
      // Không dùng lại giá phòng cơ bản khi API biên lai lỗi.
      // Ẩn giá để tránh hiển thị một con số không đúng với khoản thu mới nhất.
      if (!mounted) {
        _latestReceipt = null;
        _dashboardReceipts = <DormitoryInvoiceModel>[];
        return;
      }

      setState(() {
        _latestReceipt = null;
        _dashboardReceipts = <DormitoryInvoiceModel>[];
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
    if (data == null) return _fullStudentProfile;

    dynamic baseStudent;
    if (data is Map) {
      baseStudent = data['student'];
    } else {
      try {
        baseStudent = data.student;
      } catch (_) {
        baseStudent = null;
      }
    }

    final Map<String, dynamic>? profile = _fullStudentProfile;
    if (profile == null) return baseStudent;
    if (baseStudent is Map) {
      return <String, dynamic>{
        ...Map<String, dynamic>.from(baseStudent),
        ...profile,
      };
    }
    return profile;
  }

  List<dynamic> _readTopLevelList(
    dynamic data,
    String key, {
    List<String> aliases = const <String>[],
  }) {
    if (data == null) return <dynamic>[];

    if (data is Map) {
      dynamic value = data[key];
      for (final String alias in aliases) {
        value ??= data[alias];
      }
      return _asList(value);
    }

    try {
      switch (key) {
        case 'accommodations':
          return _asList(data.accommodations);
        case 'roommates':
          return _asList(data.roommates);
        case 'receipts':
          return _asList(data.receipts);
        case 'issues':
          return _asList(data.issues);
        case 'histories':
          return _asList(data.histories);
      }
    } catch (_) {
      return <dynamic>[];
    }

    return <dynamic>[];
  }

  Future<void> _showStudentHistory(dynamic data) async {
    if (data == null || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DRStudentHistorySheet(data: data);
      },
    );
  }

  String _studentIdentityNo(dynamic student) {
    final String value = _readString(
      student,
      'identity_no',
      (dynamic object) => object.cccd,
      aliases: const <String>['identityNo', 'identity_number', 'cccd'],
    );

    if (value.trim().isNotEmpty) {
      return value.trim();
    }

    return Globals().thongTinSinhVienModel.value?.soCmtCccd?.trim() ?? '';
  }

  int? _dormitoryId(dynamic item) {
    final dynamic dormitory = _dormitory(item);

    final int? nestedId = _readInt(
      dormitory,
      'id',
      (dynamic object) => object.id,
    );

    if (nestedId != null) {
      return nestedId;
    }

    return _readInt(
      item,
      'dormitory_id',
      (dynamic object) => object.dormitoryId,
      aliases: const <String>['dormitoryId'],
    );
  }

  int? _registrationPeriodId(dynamic item) {
    final dynamic period = _registrationPeriod(item);
    final int? nestedId = _readInt(period, 'id', (dynamic object) => object.id);

    if (nestedId != null) return nestedId;

    return _readInt(
      item,
      'registration_period_id',
      (dynamic object) => object.registrationPeriodId,
      aliases: const <String>['registrationPeriodId'],
    );
  }

  int? _resolveDormitoryIdForAccommodation(dynamic item) {
    final int? directId = _dormitoryId(item);
    if (directId != null) return directId;

    final String targetName = _normalizeDormitoryNameForMatch(
      _dormitoryName(item),
    );
    if (targetName.isEmpty) return null;

    for (final dynamic dormitory in _cubit.dormitories) {
      final String candidateName = _normalizeDormitoryNameForMatch(
        _readString(dormitory, 'name', (dynamic object) => object.name),
      );

      if (candidateName == targetName) {
        return _readInt(dormitory, 'id', (dynamic object) => object.id);
      }
    }

    // student.show có thể trả tên rút gọn, ví dụ "Mễ Trì", trong khi
    // danh mục trả "Ký túc xá Mễ Trì - ĐHQGHN". Chỉ dùng phép chứa khi
    // tên đủ dài để tránh ghép nhầm các KTX có tên quá ngắn.
    if (targetName.length >= 4) {
      for (final dynamic dormitory in _cubit.dormitories) {
        final String candidateName = _normalizeDormitoryNameForMatch(
          _readString(dormitory, 'name', (dynamic object) => object.name),
        );

        if (candidateName.length >= 4 &&
            (candidateName.contains(targetName) ||
                targetName.contains(candidateName))) {
          return _readInt(dormitory, 'id', (dynamic object) => object.id);
        }
      }
    }

    return null;
  }

  String _normalizeDormitoryNameForMatch(String value) {
    String normalized = value.trim().toLowerCase();
    normalized = normalized.replaceAll(RegExp(r'[\s_-]+'), ' ');
    normalized = normalized.replaceFirst(RegExp(r'^(ký túc xá|ktx)\s*'), '');
    return normalized.trim();
  }

  bool _hasMeaningfulApiValue(dynamic value) {
    if (value == null) return false;
    if (value is String) {
      final String text = value.trim();
      return text.isNotEmpty && text.toLowerCase() != 'null';
    }
    if (value is Map) return value.isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    return true;
  }

  Map<String, dynamic> _asStringMap(dynamic value) {
    if (value is! Map) return <String, dynamic>{};
    return value.map<String, dynamic>(
      (dynamic key, dynamic item) => MapEntry<String, dynamic>(
        key.toString(),
        item,
      ),
    );
  }

  Map<String, dynamic> _historyDataAsMap(dynamic rawData) {
    if (rawData is Map) return _asStringMap(rawData);

    // OpenAPI currently declares StudentHistory.data as array|null, while
    // production history payloads can also be JSON objects. Support both.
    if (rawData is Iterable && rawData is! String) {
      final Map<String, dynamic> merged = <String, dynamic>{};
      for (final dynamic item in rawData) {
        if (item is Map) {
          merged.addAll(_asStringMap(item));
        }
      }
      return merged;
    }

    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _historySourceMaps(
    Map<String, dynamic> history,
  ) {
    final List<Map<String, dynamic>> sources = <Map<String, dynamic>>[];
    final Map<String, dynamic> dataMap = _historyDataAsMap(history['data']);
    if (dataMap.isNotEmpty) sources.add(dataMap);

    final Map<String, dynamic> accommodationSnapshot = _asStringMap(
      history['accommodation'],
    );
    if (accommodationSnapshot.isNotEmpty) {
      sources.add(accommodationSnapshot);
    }

    sources.add(history);

    // Some backends put room/building fields inside a room snapshot.
    for (final Map<String, dynamic> source in List<Map<String, dynamic>>.from(
      sources,
    )) {
      final Map<String, dynamic> room = _asStringMap(source['room']);
      if (room.isNotEmpty) sources.add(room);

      final Map<String, dynamic> building = _asStringMap(source['building']);
      if (building.isNotEmpty) sources.add(building);
    }

    return sources;
  }

  dynamic _firstMeaningfulHistoryValue(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final Map<String, dynamic> source in sources) {
      for (final String key in keys) {
        final dynamic value = source[key];
        if (_hasMeaningfulApiValue(value)) return value;
      }
    }
    return null;
  }

  String _historyComparableId(dynamic value) {
    if (value == null) return '';
    final String text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '';
    return text;
  }

  bool _historyMatchesAccommodation({
    required Map<String, dynamic> history,
    required dynamic accommodation,
    required int accommodationCount,
  }) {
    final Map<String, dynamic> dataMap = _historyDataAsMap(history['data']);
    final Map<String, dynamic> snapshot = _asStringMap(
      history['accommodation'],
    );

    final String accommodationId = _historyComparableId(
      _accommodationId(accommodation),
    );
    final String historyAccommodationId = _historyComparableId(
      history['accommodation_id'] ??
          history['accommodationId'] ??
          dataMap['accommodation_id'] ??
          dataMap['accommodationId'] ??
          snapshot['id'] ??
          snapshot['accommodation_id'] ??
          snapshot['accommodationId'],
    );

    if (accommodationId.isNotEmpty && historyAccommodationId.isNotEmpty) {
      return accommodationId == historyAccommodationId;
    }

    // Some history rows do not expose accommodation_id but do expose the
    // registration period. Use that as a safe second-level match.
    final String periodId = _historyComparableId(
      _registrationPeriodId(accommodation),
    );
    final String historyPeriodId = _historyComparableId(
      dataMap['registration_period_id'] ??
          dataMap['registrationPeriodId'] ??
          dataMap['period_id'] ??
          dataMap['periodId'] ??
          snapshot['registration_period_id'] ??
          snapshot['registrationPeriodId'] ??
          history['registration_period_id'] ??
          history['registrationPeriodId'],
    );

    if (periodId.isNotEmpty && historyPeriodId.isNotEmpty) {
      return periodId == historyPeriodId;
    }

    // Only use an unscoped history row when there is exactly one
    // accommodation; this avoids copying an old KTX/building into a newer
    // registration when the student has multiple historical stays.
    return accommodationCount == 1 &&
        historyAccommodationId.isEmpty &&
        historyPeriodId.isEmpty;
  }

  DateTime _historySortTime(Map<String, dynamic> history) {
    final Map<String, dynamic> dataMap = _historyDataAsMap(history['data']);
    return _parseDate(
          history['created_at'] ??
              history['createdAt'] ??
              dataMap['created_at'] ??
              dataMap['createdAt'] ??
              history['updated_at'] ??
              history['updatedAt'],
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _fillAccommodationFieldFromHistory({
    required Map<String, dynamic> target,
    required String targetKey,
    required List<String> existingKeys,
    required List<Map<String, dynamic>> sources,
    required List<String> sourceKeys,
  }) {
    if (_hasMeaningfulApiValue(target[targetKey])) return;

    // Canonicalize an already-present alias first. This matters because the
    // generic reader treats an existing empty primary key as authoritative and
    // therefore would not fall through to a non-empty alias.
    for (final String key in existingKeys) {
      if (key == targetKey) continue;
      final dynamic existingValue = target[key];
      if (_hasMeaningfulApiValue(existingValue)) {
        target[targetKey] = existingValue;
        return;
      }
    }

    final dynamic value = _firstMeaningfulHistoryValue(sources, sourceKeys);
    if (_hasMeaningfulApiValue(value)) {
      target[targetKey] = value;
    }
  }

  Map<String, dynamic> _enrichAccommodationFromHistory({
    required Map<String, dynamic> accommodation,
    required List<dynamic> histories,
    required int accommodationCount,
  }) {
    final Map<String, dynamic> result = Map<String, dynamic>.from(accommodation);

    final List<Map<String, dynamic>> candidates = histories
        .whereType<Map>()
        .map(_asStringMap)
        .where(
          (Map<String, dynamic> history) => _historyMatchesAccommodation(
            history: history,
            accommodation: result,
            accommodationCount: accommodationCount,
          ),
        )
        .toList()
      ..sort(
        (Map<String, dynamic> first, Map<String, dynamic> second) =>
            _historySortTime(second).compareTo(_historySortTime(first)),
      );

    for (final Map<String, dynamic> history in candidates) {
      final List<Map<String, dynamic>> sources = _historySourceMaps(history);

      _fillAccommodationFieldFromHistory(
        target: result,
        targetKey: 'dormitory',
        existingKeys: const <String>[
          'dormitory',
          'dormitoryName',
          'dormitory_name',
        ],
        sources: sources,
        sourceKeys: const <String>[
          'dormitory',
          'dormitoryName',
          'dormitory_name',
          'dormitoryLabel',
          'dormitory_label',
        ],
      );
      _fillAccommodationFieldFromHistory(
        target: result,
        targetKey: 'building',
        existingKeys: const <String>[
          'building',
          'buildingName',
          'building_name',
          'buildingCode',
          'building_code',
        ],
        sources: sources,
        sourceKeys: const <String>[
          'building',
          'buildingName',
          'building_name',
          'buildingCode',
          'building_code',
          'blockName',
          'block_name',
          'toa',
        ],
      );
      _fillAccommodationFieldFromHistory(
        target: result,
        targetKey: 'roomTypeName',
        existingKeys: const <String>['roomTypeName', 'room_type_name'],
        sources: sources,
        sourceKeys: const <String>['roomTypeName', 'room_type_name'],
      );
      _fillAccommodationFieldFromHistory(
        target: result,
        targetKey: 'roomType',
        existingKeys: const <String>['roomType', 'room_type'],
        sources: sources,
        sourceKeys: const <String>['roomType', 'room_type'],
      );
      _fillAccommodationFieldFromHistory(
        target: result,
        targetKey: 'assignedRoom',
        existingKeys: const <String>[
          'assignedRoom',
          'assigned_room',
          'roomNumber',
          'room_number',
        ],
        sources: sources,
        sourceKeys: const <String>[
          'assignedRoom',
          'assigned_room',
          'roomNumber',
          'room_number',
        ],
      );
      _fillAccommodationFieldFromHistory(
        target: result,
        targetKey: 'dormitory_id',
        existingKeys: const <String>['dormitory_id', 'dormitoryId'],
        sources: sources,
        sourceKeys: const <String>['dormitory_id', 'dormitoryId'],
      );
      _fillAccommodationFieldFromHistory(
        target: result,
        targetKey: 'room_type_id',
        existingKeys: const <String>['room_type_id', 'roomTypeId'],
        sources: sources,
        sourceKeys: const <String>['room_type_id', 'roomTypeId'],
      );
      _fillAccommodationFieldFromHistory(
        target: result,
        targetKey: 'room_id',
        existingKeys: const <String>['room_id', 'roomId'],
        sources: sources,
        sourceKeys: const <String>['room_id', 'roomId'],
      );
      _fillAccommodationFieldFromHistory(
        target: result,
        targetKey: 'startDate',
        existingKeys: const <String>['startDate', 'start_date'],
        sources: sources,
        sourceKeys: const <String>['startDate', 'start_date'],
      );
      _fillAccommodationFieldFromHistory(
        target: result,
        targetKey: 'endDate',
        existingKeys: const <String>['endDate', 'end_date'],
        sources: sources,
        sourceKeys: const <String>['endDate', 'end_date'],
      );
    }

    return result;
  }

  List<dynamic> _readAccommodations(dynamic data) {
    if (data == null) return <dynamic>[];

    // /dormitory/me only guarantees a compact accommodations[] response
    // (roomTypeName + assignedRoom) plus histories[]. student.show returns a
    // richer accommodations[] response containing dormitory/building as well.
    // Merge every available source and finally recover missing room metadata
    // from the matching StudentHistory row by accommodation_id/period_id.
    final List<dynamic> summaryItems = _readTopLevelList(data, 'accommodations');
    final List<dynamic> histories = _readTopLevelList(data, 'histories');

    dynamic student;
    if (data is Map) {
      student = data['student'];
    } else {
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

    final Map<String, dynamic> detailById = <String, dynamic>{};
    for (final dynamic detail in detailItems) {
      final Object? id = _accommodationId(detail);
      if (id != null) detailById[id.toString()] = detail;
    }

    final List<dynamic> mergedItems = <dynamic>[];
    final Set<String> usedDetailIds = <String>{};

    for (final dynamic summary in summaryItems) {
      final Object? id = _accommodationId(summary);
      final String? key = id?.toString();
      final dynamic detail = key == null ? null : detailById[key];
      if (key != null) usedDetailIds.add(key);

      if (summary is Map && detail is Map) {
        final Map<String, dynamic> merged = _asStringMap(detail);
        _asStringMap(summary).forEach((String field, dynamic value) {
          // Do not let an empty string from the compact response erase richer
          // dormitory/building/room metadata from another source.
          if (_hasMeaningfulApiValue(value) || !merged.containsKey(field)) {
            merged[field] = value;
          }
        });
        mergedItems.add(merged);
      } else if (summary is Map) {
        mergedItems.add(_asStringMap(summary));
      } else {
        mergedItems.add(detail ?? summary);
      }
    }

    for (final dynamic detail in detailItems) {
      final Object? id = _accommodationId(detail);
      if (id == null || !usedDetailIds.contains(id.toString())) {
        mergedItems.add(detail is Map ? _asStringMap(detail) : detail);
      }
    }

    // In case an unusual response contains only student.accommodations.
    if (mergedItems.isEmpty && detailItems.isNotEmpty) {
      mergedItems.addAll(
        detailItems.map<dynamic>(
          (dynamic value) => value is Map ? _asStringMap(value) : value,
        ),
      );
    }

    final int accommodationCount = mergedItems.length;
    return mergedItems.map<dynamic>((dynamic item) {
      if (item is! Map) return item;
      return _enrichAccommodationFromHistory(
        accommodation: _asStringMap(item),
        histories: histories,
        accommodationCount: accommodationCount,
      );
    }).toList();
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
    return _readString(student, 'major', (dynamic object) => object.major);
  }

  String _studentPhone(dynamic student) {
    return _readString(
      student,
      'phone_number',
      (dynamic object) => object.phone,
      aliases: const <String>['phoneNumber', 'phone'],
    );
  }

  String _studentEmail(dynamic student) {
    return _readString(student, 'email', (dynamic object) => object.email);
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
    return _readString(student, 'level', (dynamic object) => object.level);
  }

  String _studentPermanentAddress(dynamic student) {
    return _readString(
      student,
      'permanent_address',
      (dynamic object) => object.permanentAddress,
      aliases: const <String>['permanentAddress'],
    );
  }

  String _studentTemporaryAddress(dynamic student) {
    return _readString(
      student,
      'temporary_address',
      (dynamic object) => object.temporaryAddress,
      aliases: const <String>['temporaryAddress'],
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

  String _studentAvatarUrl(dynamic student) {
    return _readString(
      student,
      'avatar',
      (dynamic object) => object.avatar,
      aliases: const <String>['avatar_url', 'avatarUrl'],
    );
  }

  String _resolveAvatarUrl(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) return normalized;
    final Uri? uri = Uri.tryParse(normalized);
    if (uri != null && uri.hasScheme) return normalized;
    final String host = ServicesUrl().effectiveKtxHostUrl;
    return normalized.startsWith('/')
        ? '$host${normalized.substring(1)}'
        : '$host$normalized';
  }

  List<dynamic> _studentFamilyMembers(dynamic student) {
    final dynamic raw = _readNested(
      student,
      'family_members',
      (dynamic object) => object.familyMembers,
      aliases: const <String>['familyMembers'],
    );

    return _asList(raw);
  }

  String _familyMemberRelationshipLabel(dynamic member) {
    final String explicitLabel = _readString(
      member,
      'relationship_label',
      (dynamic object) => object.relationshipLabel,
      aliases: const <String>['relationshipLabel'],
    );
    if (explicitLabel.isNotEmpty) return explicitLabel;

    final String relationship = _readString(
      member,
      'relationship',
      (dynamic object) => object.relationship,
    ).toLowerCase();

    switch (relationship) {
      case 'father':
        return 'Bố';
      case 'mother':
        return 'Mẹ';
      case 'guardian':
        return 'Người giám hộ';
      default:
        return relationship.isEmpty ? 'Người thân' : relationship;
    }
  }

  String _familyMemberFullName(dynamic member) {
    return _readString(
      member,
      'full_name',
      (dynamic object) => object.fullName,
      aliases: const <String>['fullName'],
    );
  }

  String _familyMemberDetail(dynamic member) {
    final List<String> values = <String>[];

    final int? birthYear = _readInt(
      member,
      'birth_year',
      (dynamic object) => object.birthYear,
      aliases: const <String>['birthYear'],
    );
    if (birthYear != null) values.add('Năm sinh $birthYear');

    final String occupation = _readString(
      member,
      'occupation',
      (dynamic object) => object.occupation,
    );
    if (occupation.isNotEmpty) values.add(occupation);

    final String phone = _readString(
      member,
      'phone_number',
      (dynamic object) => object.phoneNumber,
      aliases: const <String>['phoneNumber'],
    );
    if (phone.isNotEmpty) values.add(phone);

    return values.join(' · ');
  }

  bool _isStudentInformationLocked(dynamic latestAccommodation) {
    final String status = _accommodationStatus(
      latestAccommodation,
    ).trim().toLowerCase();
    return status == 'approved' || status == 'assigned' || status == 'active';
  }

  Future<void> _openStudentUpdateSheet(
    dynamic student,
    dynamic latestAccommodation,
  ) async {
    String identityNo = _studentIdentityNo(student).trim();
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    if (identityNo.isEmpty) {
      identityNo = preferences.getString('applicant_cccd')?.trim() ?? '';
    }
    if (identityNo.isEmpty) {
      identityNo = _studentCodeText(student).trim();
    }

    if (identityNo.isEmpty) {
      snackBarError('Không tìm thấy CCCD hoặc mã sinh viên để cập nhật');
      return;
    }

    dynamic editableStudent = student;
    try {
      final Map<String, dynamic>? fullProfile =
          await _repository.getStudentProfile(
        studentCode: _studentCodeText(student),
        identityNo: identityNo,
      );
      if (fullProfile != null) {
        editableStudent = fullProfile;
        final String profileIdentityNo = _studentIdentityNo(fullProfile).trim();
        if (profileIdentityNo.isNotEmpty) {
          identityNo = profileIdentityNo;
        }
      }
    } catch (_) {
      // Giữ dữ liệu /me làm fallback; không chặn người dùng mở màn cập nhật.
    }

    if (!mounted) return;

    final DRStudentUpdateResult? result =
        await showModalBottomSheet<DRStudentUpdateResult>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return DRStudentUpdateSheet(
              student: editableStudent,
              accommodation: latestAccommodation,
              identityNo: identityNo,
              // Nút cập nhật hiện đang tạm ẩn. Không truyền tham số
              // initialPriorityObjectName vì constructor DRStudentUpdateSheet
              // trong source hiện tại chưa khai báo tham số này.
            );
          },
        );

    if (result == null || !mounted) return;

    final String? applicantIdentityNo = preferences.getString('applicant_cccd');
    if (applicantIdentityNo != null &&
        applicantIdentityNo.trim().isNotEmpty &&
        applicantIdentityNo.trim() != result.identityNo.trim()) {
      await preferences.setString('applicant_cccd', result.identityNo.trim());
    }

    if (!mounted) return;
    snackBarSuccess(result.message);
    await _refreshData();
  }

  // =========================================================
  // Thông tin hồ sơ nội trú
  // =========================================================

  Object? _accommodationId(dynamic item) {
    if (item == null) return null;

    if (item is Map) {
      final dynamic value = item['id'];

      if (value == null) return null;

      return int.tryParse(value.toString()) ?? value.toString();
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
    return _readString(item, 'note', (dynamic object) => object.note);
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
    final int? nestedId = _readInt(room, 'id', (dynamic object) => object.id);
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

  String _roomOptionRoomName(Map<String, dynamic> room) {
    final String value = _readString(
      room,
      'room_number',
      (dynamic object) => object.roomNumber,
      aliases: const <String>[
        'roomNumber',
        'name',
        'code',
        'room_code',
        'roomCode',
      ],
    ).trim();

    return value.isEmpty ? 'Phòng chưa có tên' : value;
  }

  int? _roomOptionBuildingId(Map<String, dynamic> room) {
    // Theo API VNUConnect /api/dormitory/rooms, phòng chỉ trả buildingId,
    // không trả tên tòa. ID chỉ dùng nội bộ để gom nhóm, không hiển thị.
    return _readInt(
      room,
      'buildingId',
      (dynamic object) => object.buildingId,
      aliases: const <String>['building_id'],
    );
  }

  int? _roomOptionCapacity(Map<String, dynamic> room) {
    return _readInt(room, 'capacity', (dynamic object) => object.capacity);
  }

  int _roomOptionCurrentOccupancy(Map<String, dynamic> room) {
    return _readInt(
          room,
          'currentOccupancy',
          (dynamic object) => object.currentOccupancy,
          aliases: const <String>['current_occupancy'],
        ) ??
        0;
  }

  String _roomOptionStatus(Map<String, dynamic> room) {
    return _readString(
      room,
      'status',
      (dynamic object) => object.status,
    ).trim();
  }

  String _roomOptionFloorName(Map<String, dynamic> room) {
    final dynamic rawFloor = room['floor'];

    String value;
    if (rawFloor is Map) {
      value = _readString(
        rawFloor,
        'name',
        (dynamic object) => object.name,
        aliases: const <String>['floor_name', 'floorName', 'number'],
      ).trim();
    } else {
      value =
          (rawFloor ??
                  room['floor_name'] ??
                  room['floorName'] ??
                  room['floor_number'] ??
                  room['floorNumber'])
              ?.toString()
              .trim() ??
          '';
    }

    if (value.isEmpty) return '';

    final String normalized = value.toLowerCase();
    if (normalized.contains('tầng') || normalized.contains('tang')) {
      return value;
    }

    return 'Tầng $value';
  }

  String _roomOptionTypeName(Map<String, dynamic> room) {
    final dynamic rawRoomType = room['room_type'] ?? room['roomType'];

    if (rawRoomType is String && rawRoomType.trim().isNotEmpty) {
      return rawRoomType.trim();
    }

    return _readString(
      rawRoomType,
      'name',
      (dynamic object) => object.name,
      aliases: const <String>['room_type_name', 'roomTypeName'],
    ).trim();
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
    return _readNested(item, 'dormitory', (dynamic object) => object.dormitory);
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
    return _readNested(item, 'room', (dynamic object) => object.room);
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
          final String name = _readString(
            priority,
            'name',
            (dynamic object) => object.name,
          ).trim();
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

    // Contract student.show trả accommodations[].priorityObject là String,
    // không phải object có thuộc tính name. Vẫn hỗ trợ object cho response cũ.
    final String nestedName = nested is String
        ? nested.trim()
        : _readString(
            nested,
            'name',
            (dynamic object) => object.name,
            aliases: const <String>[
              'priority_object_name',
              'priorityObjectName',
            ],
          ).trim();

    for (final String value in nestedName.split(RegExp(r'[,;|]'))) {
      final String name = value.trim();
      if (name.isNotEmpty && !names.contains(name)) {
        names.add(name);
      }
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
          final String name = _readString(
            priority,
            'name',
            (dynamic object) => object.name,
          ).trim();
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
      (dynamic object) => object.registrationPeriodName ?? '',
      aliases: const <String>['registration_period_name'],
    );

    if (directName.isNotEmpty) {
      return directName;
    }

    final int? periodId = _readInt(
      item,
      'registration_period_id',
      (dynamic object) => object.registrationPeriodId,
      aliases: const <String>['registrationPeriodId'],
    );

    if (periodId != null) {
      return 'Đợt đăng ký nội trú';
    }

    return 'Đợt đăng ký nội trú';
  }

  String _dormitoryName(dynamic item) {
    // OpenAPI hiện tại trả accommodations[].dormitory trực tiếp.
    // Vẫn hỗ trợ object/alias cũ để không phá response legacy.
    final dynamic dormitory = _readNested(
      item,
      'dormitory',
      (dynamic object) => object.dormitory,
      aliases: const <String>['dormitoryName', 'dormitory_name'],
    );

    if (dormitory is String && dormitory.trim().isNotEmpty) {
      return dormitory.trim();
    }

    final String nestedName = _readString(
      dormitory,
      'name',
      (dynamic object) => object.name,
      aliases: const <String>['dormitoryName', 'dormitory_name', 'title'],
    ).trim();
    if (nestedName.isNotEmpty) return nestedName;

    final int? dormitoryId = _dormitoryId(item);
    if (dormitoryId != null) {
      for (final dynamic value in _cubit.dormitories) {
        final int? id = _readInt(value, 'id', (dynamic object) => object.id);
        if (id == dormitoryId) {
          final String name = _readString(
            value,
            'name',
            (dynamic object) => object.name,
          );
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

  String _assignedBuildingHintFromRoomNumber(String roomNumber) {
    final String value = roomNumber.trim().toUpperCase();
    if (value.isEmpty) return '';

    // Dạng phổ biến: CT1-101, CT2_305, CT3 402.
    final RegExpMatch? towerMatch = RegExp(
      r'^(CT\d+)[\-_\s]',
    ).firstMatch(value);
    if (towerMatch != null) {
      return towerMatch.group(1) ?? '';
    }

    // Dạng B101, A205, G2-301... Khi có dấu phân cách thì phần trước
    // dấu phân cách được ưu tiên nếu nhìn giống mã tòa.
    final RegExpMatch? delimitedMatch = RegExp(
      r'^([A-Z]+\d*)[\-_\s]',
    ).firstMatch(value);
    if (delimitedMatch != null) {
      return delimitedMatch.group(1) ?? '';
    }

    // Fallback cho A101/B205: lấy cụm chữ đầu trước số phòng.
    final RegExpMatch? letterMatch = RegExp(
      r'^([A-Z]{1,5})(?=\d{2,})',
    ).firstMatch(value);
    return letterMatch?.group(1) ?? '';
  }

  String _assignedBuildingName(dynamic item) {
    // Production API: student.accommodations[].room.building_name is the
    // canonical display name of the assigned building. Prefer it before every
    // legacy/top-level fallback so the UI shows exactly what KTX returns.
    final dynamic room = _room(item);
    final String roomBuildingName = _readString(
      room,
      'building_name',
      (dynamic object) => object.buildingName ?? '',
      aliases: const <String>[
        'buildingName',
        'building_code',
        'buildingCode',
        'block_name',
        'blockName',
        'toa',
      ],
    ).trim();
    if (roomBuildingName.isNotEmpty) {
      return _normalizeBuildingName(roomBuildingName);
    }

    // Backward compatibility for responses that expose room.building as an
    // object/string instead of room.building_name.
    final dynamic roomBuilding = _readNested(
      room,
      'building',
      (dynamic object) => object.building,
    );

    if (roomBuilding is String && roomBuilding.trim().isNotEmpty) {
      return _normalizeBuildingName(roomBuilding);
    }

    final String nestedRoomBuildingName = _readString(
      roomBuilding,
      'name',
      (dynamic object) => object.name,
      aliases: const <String>[
        'building_name',
        'buildingName',
        'code',
        'buildingCode',
        'building_code',
        'title',
      ],
    ).trim();
    if (nestedRoomBuildingName.isNotEmpty) {
      return _normalizeBuildingName(nestedRoomBuildingName);
    }

    // Older/alternate API responses may still expose building on the
    // accommodation itself. Keep this only as fallback after room.*.
    final dynamic contractBuilding = _readNested(
      item,
      'building',
      (dynamic object) => object.building,
      aliases: const <String>[
        'buildingName',
        'building_name',
        'buildingCode',
        'building_code',
        'blockName',
        'block_name',
        'toa',
      ],
    );

    if (contractBuilding is String && contractBuilding.trim().isNotEmpty) {
      return _normalizeBuildingName(contractBuilding);
    }

    final String contractBuildingName = _readString(
      contractBuilding,
      'name',
      (dynamic object) => object.name,
      aliases: const <String>[
        'buildingName',
        'building_name',
        'code',
        'buildingCode',
        'building_code',
        'title',
      ],
    ).trim();
    if (contractBuildingName.isNotEmpty) {
      return _normalizeBuildingName(contractBuildingName);
    }

    // Last-resort compatibility only. New production responses should never
    // need to infer a building name from the room number.
    final String hint = _assignedBuildingHintFromRoomNumber(_roomNumber(item));
    if (hint.isNotEmpty) {
      return _normalizeBuildingName(hint);
    }

    return '';
  }

  String _normalizeBuildingName(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) return '';

    final String lower = normalized.toLowerCase();
    if (lower.startsWith('tòa') ||
        lower.startsWith('toa') ||
        lower.startsWith('block') ||
        lower.startsWith('building')) {
      return normalized;
    }

    return 'Tòa $normalized';
  }

  String _roomTypeName(dynamic item) {
    // OpenAPI có đồng thời roomTypeName và roomType.
    // roomTypeName là tên hiển thị; roomType có thể là mã/kiểu phòng.
    final String directName = _readString(
      item,
      'roomTypeName',
      (dynamic object) => object.roomTypeName ?? '',
      aliases: const <String>['room_type_name'],
    ).trim();

    final dynamic rawRoomType = _readNested(
      item,
      'roomType',
      (dynamic object) => object.roomType,
      aliases: const <String>['room_type'],
    );

    String directType = '';
    if (rawRoomType is String) {
      directType = rawRoomType.trim();
    } else {
      directType = _readString(
        rawRoomType,
        'name',
        (dynamic object) => object.name,
        aliases: const <String>[
          'roomTypeName',
          'room_type_name',
          'code',
          'roomTypeCode',
          'room_type_code',
        ],
      ).trim();
    }

    if (directName.isNotEmpty && directType.isNotEmpty) {
      if (directName.toLowerCase() == directType.toLowerCase()) {
        return directName;
      }
      return '$directName · $directType';
    }
    if (directName.isNotEmpty) return directName;
    if (directType.isNotEmpty) return directType;

    // Legacy fallback: room_type object + room_type_id.
    final dynamic legacyRoomType = _roomType(item);
    final String nestedName = _readString(
      legacyRoomType,
      'name',
      (dynamic object) => object.name,
      aliases: const <String>['room_type_name', 'roomTypeName', 'code'],
    ).trim();
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

    final String amount = '${_formatPrice(receipt.totalAmount.toString())} đ';

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
    // OpenAPI trả accommodations[].assignedRoom trực tiếp.
    final String assignedRoom = _readString(
      item,
      'assignedRoom',
      (dynamic object) => object.assignedRoom ?? '',
      aliases: const <String>['assigned_room', 'roomNumber', 'room_number'],
    ).trim();
    if (assignedRoom.isNotEmpty) return assignedRoom;

    final dynamic room = _room(item);
    return _readString(
      room,
      'room_number',
      (dynamic object) => object.roomNumber,
      aliases: const <String>['roomNumber', 'name', 'code'],
    ).trim();
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
      (dynamic object) => object.currentOccupancy,
    );

    return currentOccupancy?.toString() ?? '';
  }

  // =========================================================
  // Trạng thái hồ sơ
  // =========================================================

  bool _hasBlockingRegistration(List<dynamic> accommodations) {
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

    final String latestStatus = _accommodationStatus(
      sorted.first,
    ).trim().toLowerCase();

    // Chỉ ba trạng thái này mới ẩn nút đăng ký mới.
    return latestStatus == 'approved' ||
        latestStatus == 'assigned' ||
        latestStatus == 'active';
  }

  Color _getStatusColor(String? status) {
    final Color? configuredColor = _statusCatalogColor(status);
    if (configuredColor != null) return configuredColor;

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
    final String configuredLabel = _statusCatalogItem(status)?.label.trim() ?? '';
    if (configuredLabel.isNotEmpty) return configuredLabel;

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
      floatingActionButton:
          BlocBuilder<DormitoryRegistrationCubit, DormitoryRegistrationState>(
            bloc: _cubit,
            builder: (BuildContext context, DormitoryRegistrationState state) {
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
        child: BlocListener<DormitoryRegistrationCubit, DormitoryRegistrationState>(
          bloc: _cubit,
          listener: (BuildContext context, DormitoryRegistrationState state) {
            if (state is DormitoryRegistrationShowHub) {
              Utils.showProgress(_hubContext);
            }

            if (state is DormitoryRegistrationDismissHub) {
              Utils.dismissProgress(_hubContext);
            }

            if (state is DormitoryRegistrationSavedSuccess) {
              snackBarSuccess(state.message);
              _refreshData();
            }

            if (state is DormitoryRegistrationError) {
              snackBarError(state.message);
            }
          },
          child:
              BlocBuilder<
                DormitoryRegistrationCubit,
                DormitoryRegistrationState
              >(
                bloc: _cubit,
                builder: (BuildContext context, DormitoryRegistrationState state) {
                  if (state is DormitoryRegistrationLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.colorMain,
                      ),
                    );
                  }

                  final dynamic data = _readDataFromState(state);

                  if (data == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.colorMain,
                      ),
                    );
                  }

                  final dynamic student = _readStudent(data);

                  final List<dynamic> accommodations = _readAccommodations(
                    data,
                  );

                  accommodations.sort((dynamic first, dynamic second) {
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

                    final Object? firstId = _accommodationId(first);

                    final Object? secondId = _accommodationId(second);

                    final int firstInt = firstId is int
                        ? firstId
                        : int.tryParse(firstId?.toString() ?? '') ?? 0;

                    final int secondInt = secondId is int
                        ? secondId
                        : int.tryParse(secondId?.toString() ?? '') ?? 0;

                    return secondInt.compareTo(firstInt);
                  });

                  if (accommodations.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refreshData,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: <Widget>[
                          _buildDashboardStudentHeader(student, null),
                          const SizedBox(height: 14),
                          _buildDashboardInvoiceOverview(student, null),
                          const SizedBox(height: 14),
                          _buildEmptyRegistrationDashboardCard(),
                          const SizedBox(height: 14),
                          _buildDashboardQuickActions(
                            data: data,
                            student: student,
                            latestAccommodation: null,
                          ),
                          const SizedBox(height: 14),
                          _buildStudentHistoryOverviewCard(data),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        _buildDashboardStudentHeader(
                          student,
                          accommodations.first,
                        ),
                        const SizedBox(height: 14),
                        _buildDashboardInvoiceOverview(
                          student,
                          accommodations.first,
                        ),
                        const SizedBox(height: 14),
                        if (_accommodationStatus(accommodations.first) ==
                            'pending') ...<Widget>[
                          _buildPendingApprovalBanner(),
                          const SizedBox(height: 14),
                        ],
                        _buildCurrentRegistrationStatusCard(
                          accommodations.first,
                        ),
                        if (_shouldShowRoomDashboard(accommodations.first)) ...<Widget>[
                          const SizedBox(height: 14),
                          _buildRoomDashboardCard(
                            accommodations.first,
                            data,
                          ),
                        ],
                        const SizedBox(height: 14),
                        _buildDashboardQuickActions(
                          data: data,
                          student: student,
                          latestAccommodation: accommodations.first,
                        ),
                        const SizedBox(height: 14),
                        _buildStudentHistoryOverviewCard(data),
                        const SizedBox(height: 14),
                        _buildRegistrationDetailsExpansion(
                          data: data,
                          student: student,
                          accommodations: accommodations,
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

  Widget _buildDashboardStudentHeader(
    dynamic student,
    dynamic latestAccommodation,
  ) {
    final String fullName = _studentFullName(student).trim();
    final String studentCode = _studentCodeText(student).trim();
    final String className = _studentClass(student).trim();
    final String avatarUrl = _studentAvatarUrl(student).trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E9E5)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEAF6EE),
              border: Border.all(color: const Color(0xFFCDE7D5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl.isNotEmpty
                ? Image.network(
                    _resolveAvatarUrl(avatarUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF078B3E),
                      size: 34,
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF078B3E),
                    size: 34,
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  fullName.isEmpty ? 'Hồ sơ lưu trú của bạn' : fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppFontSizes.medium,
                    color: Color(0xFF141A16),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  <String>[
                    if (studentCode.isNotEmpty) 'MSSV: $studentCode',
                    if (className.isNotEmpty) className,
                  ].join(' · ').isEmpty
                      ? 'Xem thông tin cá nhân hoặc cập nhật thông tin cá nhân'
                      : <String>[
                          if (studentCode.isNotEmpty) 'MSSV: $studentCode',
                          if (className.isNotEmpty) className,
                        ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppFontSizes.font11,
                    color: Color(0xFF68716B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cập nhật hồ sơ',
            onPressed: student == null
                ? null
                : () => _openStudentUpdateSheet(
                    student,
                    latestAccommodation,
                  ),
            icon: const Icon(Icons.chevron_right_rounded),
            color: const Color(0xFF078B3E),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardInvoiceOverview(
    dynamic student,
    dynamic latestAccommodation,
  ) {
    final int unpaidCount = _dashboardReceipts
        .where(
          (DormitoryInvoiceModel invoice) =>
              !invoice.isPaid && !invoice.hasPendingPayment,
        )
        .length;
    final int pendingCount = _dashboardReceipts
        .where((DormitoryInvoiceModel invoice) => invoice.hasPendingPayment)
        .length;
    final int paidCount = _dashboardReceipts
        .where((DormitoryInvoiceModel invoice) => invoice.isPaid)
        .length;
    final double totalDebt = _dashboardReceipts.fold<double>(
      0,
      (double total, DormitoryInvoiceModel invoice) {
        if (invoice.isPaid) return total;
        final double remaining = invoice.remainingAmount > 0
            ? invoice.remainingAmount
            : (invoice.totalAmount - invoice.paidAmount);
        return total + (remaining > 0 ? remaining : 0);
      },
    );

    return Semantics(
      button: true,
      label: 'Mở hóa đơn và thanh toán',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openInvoices(student, latestAccommodation),
          borderRadius: BorderRadius.circular(30),
          child: DormitoryLeatherWallet3D(
            totalAmount: _formatPrice(totalDebt.toString()),
            unpaid: unpaidCount,
            pending: pendingCount,
            paid: paidCount,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardMetric({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.065),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: AppFontSizes.mediumSmall,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppFontSizes.extraSmall,
              color: Color(0xFF656D68),
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowRoomDashboard(dynamic item) {
    final String status = _accommodationStatus(item);
    return _roomNumber(item).trim().isNotEmpty ||
        status == 'assigned' ||
        status == 'active';
  }

  Widget _buildRoomDashboardCard(dynamic item, dynamic data) {
    final String roomNumber = _roomNumber(item);
    final String roomType = _roomTypeName(item);
    final String dormitory = _dormitoryName(item);
    final String buildingName = _assignedBuildingName(item);
    final String status = _accommodationStatus(item);
    final int roommateCount = _readTopLevelList(data, 'roommates').length;
    final DateTime? start = _accommodationStartDate(item);
    final DateTime? end = _accommodationEndDate(item);
    final Color statusColor = _getStatusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E9E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bedroom_parent_rounded,
                  color: Color(0xFF315BEA),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Phòng ở hiện tại',
                  style: TextStyle(
                    fontSize: AppFontSizes.mediumSmall,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF151A17),
                  ),
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 14),
          // KTX và loại phòng thường dài: để full-width để hiển thị đủ.
          _buildRoomInfoTile(
            icon: Icons.apartment_rounded,
            label: 'Ký túc xá',
            value: dormitory,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _buildRoomInfoTile(
                  icon: Icons.location_city_rounded,
                  label: 'Tòa',
                  value: buildingName.isEmpty ? 'Chưa cập nhật' : buildingName,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRoomInfoTile(
                  icon: Icons.meeting_room_rounded,
                  label: 'Phòng',
                  value: roomNumber.isEmpty ? 'Đang bố trí' : roomNumber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRoomInfoTile(
            icon: Icons.groups_rounded,
            label: 'Loại phòng',
            value: roomType.isEmpty ? 'Chưa cập nhật' : roomType,
          ),
          const SizedBox(height: 10),
          _buildRoomInfoTile(
            icon: Icons.people_alt_outlined,
            label: 'Bạn cùng phòng',
            value: '$roommateCount',
          ),
          if (start != null || end != null) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.date_range_rounded, size: 18, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thời gian ở: ${start == null ? '—' : DateFormat('dd/MM/yyyy').format(start.toLocal())}'
                      ' - ${end == null ? '—' : DateFormat('dd/MM/yyyy').format(end.toLocal())}',
                      style: const TextStyle(
                        fontSize: AppFontSizes.extraSmall,
                        color: Color(0xFF4E5751),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (status == 'assigned' || status == 'active') ...<Widget>[
            const SizedBox(height: 12),
            _buildAccommodationRequestActions(item),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: const Color(0xFF315BEA)),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppFontSizes.extraSmall,
                    color: Color(0xFF818883),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: AppFontSizes.font11,
                    color: Color(0xFF252B27),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardQuickActions({
    required dynamic data,
    required dynamic student,
    required dynamic latestAccommodation,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _buildDashboardAction(
              width: width,
              icon: Icons.badge_outlined,
              label: 'Hồ sơ lưu trú',
              color: const Color(0xFF0A9B61),
              onTap: student == null
                  ? null
                  : () => _openStudentUpdateSheet(
                      student,
                      latestAccommodation,
                    ),
            ),
            _buildDashboardAction(
              width: width,
              icon: Icons.receipt_long_outlined,
              label: 'Hóa đơn',
              color: const Color(0xFF315BEA),
              onTap: () => _openInvoices(student, latestAccommodation),
            ),
            _buildDashboardAction(
              width: width,
              icon: Icons.history_rounded,
              label: 'Lịch sử',
              color: const Color(0xFF7C4DFF),
              onTap: () => _showStudentHistory(data),
            ),
            _buildDashboardAction(
              width: width,
              icon: latestAccommodation == null
                  ? Icons.app_registration_rounded
                  : Icons.swap_horiz_rounded,
              label: latestAccommodation == null
                  ? 'Đăng ký nội trú'
                  : 'Đổi / trả phòng',
              color: const Color(0xFFF59E0B),
              onTap: latestAccommodation == null
                  ? (_hasOpenRegistrationPeriod ? _goToRegisterFlow : null)
                  : () => _showAccommodationActionSheet(latestAccommodation),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardAction({
    required double width,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 82),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4E9E6)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    style: TextStyle(
                      color: onTap == null
                          ? const Color(0xFF9AA09C)
                          : const Color(0xFF252A27),
                      fontSize: AppFontSizes.font11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRegistrationDashboardCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E9E5)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3F1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.apartment_outlined,
              color: Color(0xFF69716C),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Chưa có đơn đăng ký hiện tại',
                  style: TextStyle(
                    fontSize: AppFontSizes.mediumSmall,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF252A27),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Khi có đợt mở, bạn có thể bắt đầu đăng ký ngay từ màn hình này.',
                  style: TextStyle(
                    fontSize: AppFontSizes.extraSmall,
                    color: Color(0xFF717873),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationDetailsExpansion({
    required dynamic data,
    required dynamic student,
    required List<dynamic> accommodations,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E9E5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text(
            'Thông tin hồ sơ chi tiết',
            style: TextStyle(
              fontSize: AppFontSizes.mediumSmall,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: const Text(
            'Thông tin cá nhân và các lần đăng ký trước',
            style: TextStyle(fontSize: AppFontSizes.extraSmall),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: <Widget>[
            _buildStudentCard(student, accommodations.first),
            const SizedBox(height: 12),
            ...accommodations.asMap().entries.map(
              (MapEntry<int, dynamic> entry) => _buildAccommodationCard(
                entry.value,
                student,
                isLatest: entry.key == 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInvoices(dynamic student, dynamic item) async {
    String identityNo = _studentIdentityNo(student).trim();
    if (identityNo.isEmpty) {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      identityNo = preferences.getString('applicant_cccd')?.trim() ?? '';
    }

    if (!mounted) return;

    if (identityNo.isEmpty) {
      snackBarError('Không tìm thấy mã sinh viên/CCCD để tải hóa đơn');
      return;
    }

    final int? dormitoryId = item == null
        ? null
        : _resolveDormitoryIdForAccommodation(item);

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => DRInvoicesScreen(
          identityNo: identityNo,
          dormitoryId: dormitoryId,
          dormitoryName: item == null ? '' : _dormitoryName(item),
          accommodationStartDate:
              item == null ? null : _accommodationStartDate(item),
          accommodationEndDate:
              item == null ? null : _accommodationEndDate(item),
        ),
      ),
    );

    if (mounted) await _loadLatestReceiptFromCurrentState();
  }

  Future<void> _showAccommodationActionSheet(dynamic item) async {
    final String status = _accommodationStatus(item);
    if (status != 'assigned' && status != 'active') {
      snackBarError('Chỉ có thể gửi yêu cầu khi đã được bố trí phòng');
      return;
    }

    final bool pending = _hasPendingAccommodationRequest(item);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Yêu cầu lưu trú',
                    style: TextStyle(
                      fontSize: AppFontSizes.medium,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (pending)
                  ListTile(
                    leading: const Icon(Icons.close_rounded, color: Colors.red),
                    title: const Text('Hủy yêu cầu đang chờ'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _confirmCancelAccommodationRequest(item);
                    },
                  )
                else ...<Widget>[
                  ListTile(
                    leading: const Icon(
                      Icons.swap_horiz_rounded,
                      color: Color(0xFF315BEA),
                    ),
                    title: const Text('Yêu cầu đổi phòng'),
                    subtitle: const Text('Gửi yêu cầu để cán bộ KTX xem xét'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _openChangeRoomRequest(item);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFE67E22),
                    ),
                    title: const Text('Yêu cầu trả phòng'),
                    subtitle: const Text('Không tự động trả phòng ngay'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _openCheckoutRequest(item);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingApprovalBanner() {
    final int? days = _latestPendingMaxApprovalDays;
    final String expectedResultText = days != null
        ? 'dự kiến có kết quả trong vòng $days ngày. '
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1D48A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE8A3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              size: 21,
              color: Color(0xFF9A6A00),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: AppFontSizes.font11,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5E4B18),
                ),
                children: <InlineSpan>[
                  const TextSpan(
                    text: 'Đăng ký ký túc xá thành công! ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7A5400),
                    ),
                  ),
                  TextSpan(
                    text:
                        'Đơn của bạn đang chờ Ban quản lý duyệt, '
                        '$expectedResultText'
                        'Bạn có thể theo dõi trạng thái đơn trong mục '
                        '\'Đơn đăng ký\'.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentRegistrationStatusCard(dynamic item) {
    final String status = _accommodationStatus(item);
    final Color statusColor = _getStatusColor(status);
    final DateTime? createdAt = _accommodationCreatedAt(item);
    final String dormitoryName = _dormitoryName(item);
    final String periodName = _periodName(item);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E9E5)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showHistory(_accommodationId(item)),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: statusColor,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Đơn đăng ký hiện tại',
                          style: TextStyle(
                            fontSize: AppFontSizes.mediumSmall,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF151A17),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Theo dõi tiến trình xử lý hồ sơ',
                          style: TextStyle(
                            fontSize: AppFontSizes.extraSmall,
                            color: Color(0xFF747B76),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.055),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$dormitoryName · $periodName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSizes.font11,
                        color: Color(0xFF2F3632),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (createdAt != null) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        'Gửi lúc ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toLocal())}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.extraSmall,
                          color: Color(0xFF737A75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 17),
              _buildRegistrationTimeline(status),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    'Xem lịch sử xử lý',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: AppFontSizes.extraSmall,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.chevron_right_rounded, color: statusColor, size: 19),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationTimeline(String status) {
    const List<String> codes = <String>[
      'draft',
      'pending',
      'approved',
      'assigned',
    ];
    const List<String> labels = <String>[
      'Khởi tạo',
      'Đã gửi',
      'Đã duyệt',
      'Bố trí phòng',
    ];

    int currentIndex;
    switch (status.toLowerCase()) {
      case 'draft':
        currentIndex = 0;
        break;
      case 'pending':
      case 'rejected':
        currentIndex = 1;
        break;
      case 'approved':
        currentIndex = 2;
        break;
      case 'assigned':
      case 'active':
      case 'checkout':
      case 'terminated':
        currentIndex = 3;
        break;
      default:
        currentIndex = 0;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List<Widget>.generate(codes.length, (int index) {
        final bool done = index <= currentIndex;
        final Color color = done
            ? const Color(0xFF078B3E)
            : const Color(0xFFD8DEDA);

        return Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        if (index > 0)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: index <= currentIndex
                                  ? const Color(0xFF8CCDA7)
                                  : const Color(0xFFE2E6E3),
                            ),
                          ),
                        Container(
                          width: 23,
                          height: 23,
                          decoration: BoxDecoration(
                            color: done ? color : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2),
                          ),
                          child: done
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        if (index < codes.length - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: index < currentIndex
                                  ? const Color(0xFF8CCDA7)
                                  : const Color(0xFFE2E6E3),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: AppFontSizes.extraSmall,
                        height: 1.15,
                        color: done
                            ? const Color(0xFF245D3B)
                            : const Color(0xFF929894),
                        fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStudentCard(dynamic student, dynamic latestAccommodation) {
    final DateTime? dob = _studentDateOfBirth(student);
    final String identityNo = _studentIdentityNo(student);
    final String identityType = _studentIdentityType(student);
    final String gender = _studentGender(student);
    final String academicYear = _studentAcademicYear(student);
    final String level = _studentLevel(student);
    final String permanentAddress = _studentPermanentAddress(student);
    final String temporaryAddress = _studentTemporaryAddress(student);
    final String priorityObject = _studentPriorityObjectName(student);
    final String avatarUrl = _studentAvatarUrl(student);
    final List<dynamic> familyMembers = _studentFamilyMembers(student);
    // Tạm ẩn trạng thái khóa trên giao diện.
    // Logic khóa trong hàm cập nhật vẫn được giữ để bật lại khi cần.
    /*
    final bool informationLocked =
        _isStudentInformationLocked(latestAccommodation);
    */

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF078B3E),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Thông tin sinh viên',
                    style: TextStyle(
                      fontSize: AppFontSizes.mediumSmall,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111318),
                    ),
                  ),
                ),
                /*
                if (informationLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F2F4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: Color(0xFF666B75),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Đã khóa',
                          style: TextStyle(
                            fontSize: AppFontSizes.extraSmall,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF666B75),
                          ),
                        ),
                      ],
                    ),
                  ),
                */
                TextButton.icon(
                  onPressed: () =>
                      _openStudentUpdateSheet(student, latestAccommodation),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Cập nhật'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF078B3E),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (avatarUrl.isNotEmpty) ...<Widget>[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    _resolveAvatarUrl(avatarUrl),
                    width: 92,
                    height: 116,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 92,
                      height: 116,
                      color: const Color(0xFFF1F3F5),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 42,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            _buildInfoRow('Họ và tên:', _studentFullName(student)),
            _buildInfoRow('Mã sinh viên:', _studentCodeText(student)),
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
              _buildInfoRow('Năm học:', academicYear),
            if (level.isNotEmpty) _buildInfoRow('Bậc đào tạo:', level),
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
            if (familyMembers.isNotEmpty) ...<Widget>[
              const Divider(height: 24),
              const Row(
                children: <Widget>[
                  Icon(
                    Icons.family_restroom_rounded,
                    size: 18,
                    color: Color(0xFF078B3E),
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Thông tin gia đình',
                    style: TextStyle(
                      fontSize: AppFontSizes.font11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111318),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ...familyMembers.map((dynamic member) {
                final String name = _familyMemberFullName(member);
                if (name.isEmpty) return const SizedBox.shrink();
                final String detail = _familyMemberDetail(member);

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${_familyMemberRelationshipLabel(member)}: $name',
                        style: const TextStyle(
                          fontSize: AppFontSizes.font11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111318),
                        ),
                      ),
                      if (detail.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          detail,
                          style: const TextStyle(
                            fontSize: AppFontSizes.extraSmall,
                            color: Color(0xFF666B75),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
            /*
            if (informationLocked) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      size: 17,
                      color: Color(0xFF666B75),
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Không thể sửa thông tin sau khi hồ sơ đã được duyệt, xếp phòng hoặc chuyển sang trạng thái đang lưu trú.',
                        style: TextStyle(
                          fontSize: AppFontSizes.extraSmall,
                          color: Color(0xFF666B75),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            */
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHistoryOverviewCard(dynamic data) {
    final int accommodationCount = _readTopLevelList(
      data,
      'accommodations',
    ).length;
    final int historyCount = _readTopLevelList(data, 'histories').length;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: const Color(0xFFF7FAF8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFDCE8E0)),
      ),
      child: InkWell(
        onTap: () => _showStudentHistory(data),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5F5EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.manage_search_rounded,
                  color: Color(0xFF078B3E),
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Thông tin và lịch sử sinh viên',
                      style: TextStyle(
                        fontSize: AppFontSizes.mediumSmall,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF171A18),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$accommodationCount hồ sơ nội trú · '
                      '$historyCount sự kiện lịch sử',
                      style: const TextStyle(
                        fontSize: AppFontSizes.extraSmall,
                        color: Color(0xFF626A65),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF078B3E)),
            ],
          ),
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
    final String statusLabel = _readString(
      item, 'statusLabel', (dynamic object) => object.statusLabel,
      aliases: const <String>['status_label'],
    );
    final String periodName = _readString(
      item, 'registrationPeriodName',
      (dynamic object) => object.registrationPeriodName,
      aliases: const <String>['registration_period_name'],
    );
    final String studentCode = _readString(
      item, 'studentCode', (dynamic object) => object.studentCode,
      aliases: const <String>['student_code'],
    );
    final String studentName = _readString(
      item, 'studentName', (dynamic object) => object.studentName,
      aliases: const <String>['student_name'],
    );
    final String rejectReason = _readString(
      item, 'rejectReason', (dynamic object) => object.rejectReason,
      aliases: const <String>['reject_reason'],
    );
    final String roomTypeName = _readString(
      item, 'roomTypeName', (dynamic object) => object.roomTypeName,
      aliases: const <String>['room_type_name'],
    );
    final String assignedRoom = _readString(
      item, 'assignedRoom', (dynamic object) => object.assignedRoom,
      aliases: const <String>['assigned_room'],
    );
    bool? isDraft;
    if (item is Map) {
      final dynamic raw = item['isDraft'] ?? item['is_draft'];
      if (raw is bool) isDraft = raw;
    } else {
      try { isDraft = item.isDraft as bool?; } catch (_) {}
    }
    final DateTime? createdAt = _accommodationCreatedAt(item);
    final DateTime? updatedAt = _accommodationUpdatedAt(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _showHistory(_accommodationId(item)),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(children: <Widget>[
                Icon(_getStatusIcon(status), size: 20, color: _getStatusColor(status)),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  periodName.isEmpty ? 'Hồ sơ nội trú' : periodName,
                  style: const TextStyle(fontSize: AppFontSizes.mediumSmall, fontWeight: FontWeight.bold, color: Color(0xFF111318)),
                )),
                const SizedBox(width: 8),
                _buildStatusBadge(status),
              ]),
              const Divider(height: 22),
              if (statusLabel.isNotEmpty) _buildInfoRow('Trạng thái:', statusLabel),
              if (studentName.isNotEmpty) _buildInfoRow('Sinh viên:', studentName),
              if (studentCode.isNotEmpty) _buildInfoRow('Mã sinh viên:', studentCode),
              if (periodName.isNotEmpty) _buildInfoRow('Đợt đăng ký:', periodName),
              if (roomTypeName.isNotEmpty) _buildInfoRow('Loại phòng:', roomTypeName),
              if (assignedRoom.isNotEmpty) _buildInfoRow('Phòng được xếp:', assignedRoom),
              if (isDraft != null) _buildInfoRow('Hồ sơ nháp:', isDraft ? 'Có' : 'Không'),
              if (rejectReason.isNotEmpty) _buildInfoRow('Lý do từ chối:', rejectReason),
              if (createdAt != null) _buildInfoRow('Ngày tạo:', DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toLocal())),
              if (updatedAt != null) _buildInfoRow('Cập nhật:', DateFormat('dd/MM/yyyy HH:mm').format(updatedAt.toLocal())),
              const SizedBox(height: 14),
              _buildActionArea(item, student),
              const SizedBox(height: 10),
              const Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                Text('Xem lịch sử xử lý', style: TextStyle(fontSize: AppFontSizes.font11, color: Color(0xFF078B3E), fontWeight: FontWeight.bold)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF078B3E)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
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

  Widget _buildActionArea(dynamic item, dynamic student) {
    final String status = _accommodationStatus(item);

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
          color: AppTheme.colorError.withOpacity(0.08),
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

    if (status == 'approved' || status == 'assigned' || status == 'active') {
      final bool hasRoomType = _roomTypeName(item).isNotEmpty;
      final bool hasRoom = _roomNumber(item).isNotEmpty;

      String notice;
      IconData noticeIcon;

      if (status == 'active') {
        noticeIcon = Icons.home_rounded;
        notice =
            'Bạn đang lưu trú tại ký túc xá. '
            'Vui lòng theo dõi hóa đơn và trạng thái thanh toán.';
      } else if (status == 'assigned' || hasRoom) {
        noticeIcon = Icons.meeting_room_rounded;
        notice =
            'Hồ sơ đã được duyệt và bạn đã được xếp phòng. '
            'Vui lòng kiểm tra thông tin phòng và hóa đơn.';
      } else if (hasRoomType) {
        noticeIcon = Icons.bed_rounded;
        notice =
            'Hồ sơ đã được duyệt và đã có loại phòng. '
            'Vui lòng kiểm tra hóa đơn và chờ xếp phòng cụ thể.';
      } else {
        noticeIcon = Icons.verified_rounded;
        notice =
            'Hồ sơ đã được duyệt. Ban quản lý chưa trả '
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

  Object? _registrationIdForRequest(dynamic item) {
    final dynamic rawId = _accommodationId(item);
    if (rawId == null) return null;

    if (rawId is num) {
      return rawId.toInt();
    }

    final String value = rawId.toString().trim();
    return value.isEmpty ? null : value;
  }

  Future<List<_AccommodationRoomChoice>> _loadAccommodationRoomChoices({
    required int dormitoryId,
    int? currentRoomId,
  }) async {
    final List<Map<String, dynamic>> rooms = await _repository.getRooms(
      dormitoryId: dormitoryId,
    );

    final Map<int, _AccommodationRoomChoice> unique =
        <int, _AccommodationRoomChoice>{};

    for (final Map<String, dynamic> room in rooms) {
      final int? roomId = _roomOptionId(room);
      if (roomId == null || roomId == currentRoomId) continue;

      unique[roomId] = _AccommodationRoomChoice(
        id: roomId,
        roomName: _roomOptionRoomName(room),
        buildingId: _roomOptionBuildingId(room) ?? 0,
        floorName: _roomOptionFloorName(room),
        roomTypeName: _roomOptionTypeName(room),
        capacity: _roomOptionCapacity(room),
        currentOccupancy: _roomOptionCurrentOccupancy(room),
        status: _roomOptionStatus(room),
      );
    }

    final List<_AccommodationRoomChoice> result = unique.values.toList()
      ..sort((_AccommodationRoomChoice first, _AccommodationRoomChoice second) {
        final int buildingCompare = first.buildingId.compareTo(
          second.buildingId,
        );
        if (buildingCompare != 0) return buildingCompare;

        return first.displayName.toLowerCase().compareTo(
          second.displayName.toLowerCase(),
        );
      });

    return result;
  }

  Future<_AccommodationRequestFormResult?>
  _showAccommodationRequestBottomSheet({
    required String type,
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required String noteLabel,
    required String noteHint,
    String? currentRoom,
    int? currentRoomId,
    int? dormitoryId,
  }) async {
    if (!mounted) return null;

    return showModalBottomSheet<_AccommodationRequestFormResult>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (BuildContext sheetContext) {
        return _AccommodationRequestFormSheet(
          type: type,
          title: title,
          icon: icon,
          color: color,
          description: description,
          noteLabel: noteLabel,
          noteHint: noteHint,
          currentRoom: currentRoom,
          // Luồng chuyển phòng chỉ nhận lý do; không tải danh sách phòng.
          roomLoader: null,
          roomLookupUnavailable: false,
        );
      },
    );
  }

  Future<void> _openChangeRoomRequest(dynamic item) async {
    final Object? registrationId = _registrationIdForRequest(item);

    if (registrationId == null) {
      snackBarError('Không tìm thấy hồ sơ nội trú');
      return;
    }

    final String roomNumber = _roomNumber(item);

    final _AccommodationRequestFormResult? result =
        await _showAccommodationRequestBottomSheet(
          type: 'change_room',
          title: 'Yêu cầu chuyển phòng',
          icon: Icons.swap_horiz_rounded,
          color: const Color(0xFF078B3E),
          currentRoom: roomNumber.isEmpty ? null : roomNumber,
          // Không tải và không hiển thị danh sách phòng. Sinh viên chỉ gửi
          // lý do; Ban quản lý sẽ xem xét và bố trí phòng phù hợp.
          description:
              'Yêu cầu sẽ được gửi đến Ban quản lý ký túc xá để xem xét. '
              'Ban quản lý sẽ chủ động bố trí phòng phù hợp theo tình trạng '
              'phòng thực tế.',
          noteLabel: 'Lý do chuyển phòng',
          noteHint: 'Nhập lý do hoặc nhu cầu cần hỗ trợ',
        );

    if (result == null) return;

    await _submitAccommodationRequest(
      registrationId: registrationId,
      type: 'change_room',
      note: result.note,
      successMessage: 'Đã gửi yêu cầu chuyển phòng',
    );
  }

  Future<void> _openCheckoutRequest(dynamic item) async {
    final Object? registrationId = _registrationIdForRequest(item);

    if (registrationId == null) {
      snackBarError('Không tìm thấy hồ sơ nội trú');
      return;
    }

    final String roomNumber = _roomNumber(item);
    final _AccommodationRequestFormResult? result =
        await _showAccommodationRequestBottomSheet(
          type: 'checkout',
          title: 'Yêu cầu trả phòng',
          icon: Icons.logout_rounded,
          color: Colors.orange.shade700,
          currentRoom: roomNumber.isEmpty ? null : roomNumber,
          description:
              'Yêu cầu trả phòng sẽ được gửi đến Ban quản lý ký túc xá. '
              'Hệ thống chỉ ghi nhận yêu cầu, chưa tự động kết thúc lưu trú '
              'hoặc bàn giao phòng.',
          noteLabel: 'Lý do trả phòng',
          noteHint: 'Nhập lý do và thời gian dự kiến rời ký túc xá',
        );

    if (result == null) return;

    await _submitAccommodationRequest(
      registrationId: registrationId,
      type: 'checkout',
      note: result.note,
      successMessage: 'Đã gửi yêu cầu trả phòng',
    );
  }

  Future<void> _confirmCancelAccommodationRequest(dynamic item) async {
    final Object? registrationId = _registrationIdForRequest(item);
    if (registrationId == null) {
      snackBarError('Không tìm thấy hồ sơ nội trú');
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
    required Object registrationId,
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
      debugPrint(
        '[DORMITORY-REQUEST-SUBMIT] '
        'registrationId=$registrationId, type=$type, '
        'desiredRoomId=$desiredRoomId, hasNote=${normalizedNote.isNotEmpty}',
      );

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
        AppFeedback.showError(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAccommodationRequest = false;
        });
      }
    }
  }

  Widget _buildInvoiceButton(dynamic item, dynamic student) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _openInvoices(student, item),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF078B3E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.receipt_long_rounded),
        label: const Text('Hóa đơn & thanh toán'),
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
          Icon(icon, size: 16, color: color),
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
    final Color color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  Widget _buildInfoRow(String label, String value) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSizes.font11,
                color: Color(0xFF666B75),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppFontSizes.font11,
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
    final String raw = value.replaceAll(',', '');

    final double? number = double.tryParse(raw);

    if (number == null) {
      return value;
    }

    return NumberFormat('#,###', 'vi_VN').format(number);
  }

  void _showHistory(Object? accommodationId) {
    if (accommodationId == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DRHistoryBottomSheet(registrationId: accommodationId);
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

    final dynamic result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => const DRWizardFlow(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result is String && result.isNotEmpty) {
      await _refreshData();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF078B3E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: <Widget>[
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(result)),
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

class _AccommodationRequestFormResult {
  final String? note;
  final int? desiredRoomId;

  const _AccommodationRequestFormResult({this.note, this.desiredRoomId});
}

class _AccommodationRoomChoice {
  final int id;
  final String roomName;
  final int buildingId;
  final String floorName;
  final String roomTypeName;
  final int? capacity;
  final int currentOccupancy;
  final String status;

  const _AccommodationRoomChoice({
    required this.id,
    required this.roomName,
    required this.buildingId,
    this.floorName = '',
    this.roomTypeName = '',
    this.capacity,
    this.currentOccupancy = 0,
    this.status = '',
  });

  String get displayName {
    final String value = roomName.trim();
    if (value.isEmpty) return 'Phòng chưa có tên';

    final String normalized = value.toLowerCase();
    if (normalized.startsWith('phòng ') ||
        normalized.startsWith('phong ') ||
        normalized.startsWith('room ')) {
      return value;
    }

    return 'Phòng $value';
  }

  int? get availableBeds {
    final int? roomCapacity = capacity;
    if (roomCapacity == null || roomCapacity <= 0) return null;
    final int remaining = roomCapacity - currentOccupancy;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isSelectable {
    final String normalized = status.trim().toLowerCase();
    const Set<String> blockedStatuses = <String>{
      'full',
      'inactive',
      'closed',
      'maintenance',
      'unavailable',
      'disabled',
    };

    if (blockedStatuses.contains(normalized)) return false;

    final int? beds = availableBeds;
    return beds == null || beds > 0;
  }

  String get statusLabel {
    switch (status.trim().toLowerCase()) {
      case 'available':
      case 'active':
      case 'open':
        return 'Có thể đăng ký';
      case 'full':
        return 'Đã đủ người';
      case 'maintenance':
        return 'Đang bảo trì';
      case 'inactive':
      case 'closed':
      case 'unavailable':
      case 'disabled':
        return 'Tạm ngừng';
      default:
        return status.trim();
    }
  }

  String get detailText {
    final List<String> values = <String>[];

    if (capacity != null && capacity! > 0) {
      values.add('$currentOccupancy/${capacity!} người');

      final int? beds = availableBeds;
      if (beds != null) {
        values.add(beds > 0 ? 'Còn $beds chỗ' : 'Đã đủ chỗ');
      }
    }

    if (floorName.trim().isNotEmpty) values.add(floorName.trim());
    if (roomTypeName.trim().isNotEmpty) values.add(roomTypeName.trim());
    if (statusLabel.isNotEmpty) values.add(statusLabel);

    return values.join(' · ');
  }
}

class _AccommodationRequestFormSheet extends StatefulWidget {
  final String type;
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final String noteLabel;
  final String noteHint;
  final String? currentRoom;
  final Future<List<_AccommodationRoomChoice>> Function()? roomLoader;
  final bool roomLookupUnavailable;

  const _AccommodationRequestFormSheet({
    required this.type,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.noteLabel,
    required this.noteHint,
    this.currentRoom,
    this.roomLoader,
    this.roomLookupUnavailable = false,
  });

  @override
  State<_AccommodationRequestFormSheet> createState() =>
      _AccommodationRequestFormSheetState();
}

class _AccommodationRequestFormSheetState
    extends State<_AccommodationRequestFormSheet> {
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();

  List<_AccommodationRoomChoice> _roomChoices = <_AccommodationRoomChoice>[];
  final Set<int> _expandedBuildingIds = <int>{};
  int _selectedRoomValue = -1;
  bool _loadingRooms = false;
  bool _closing = false;
  String? _roomLoadMessage;

  bool get _isChangeRoom => widget.type == 'change_room';

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _noteFocusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    if (!_isChangeRoom || widget.roomLoader == null) {
      if (_isChangeRoom && widget.roomLookupUnavailable) {
        _roomLoadMessage =
            'Không xác định được ký túc xá để tải danh sách phòng. '
            'Bạn vẫn có thể gửi yêu cầu để Ban quản lý sắp xếp.';
      }
      return;
    }

    setState(() {
      _loadingRooms = true;
      _roomLoadMessage = null;
    });

    try {
      final List<_AccommodationRoomChoice> rooms = await widget.roomLoader!
          .call();
      if (!mounted) return;

      setState(() {
        _roomChoices = rooms;
        _expandedBuildingIds
          ..clear()
          ..addAll(
            rooms.isEmpty ? const <int>[] : <int>[rooms.first.buildingId],
          );
        _roomLoadMessage = rooms.isEmpty
            ? 'Hiện chưa có phòng khác để lựa chọn. '
                  'Ban quản lý sẽ xem xét và sắp xếp phòng phù hợp.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _roomChoices = <_AccommodationRoomChoice>[];
        _roomLoadMessage =
            'Chưa tải được danh sách phòng. Bạn vẫn có thể gửi yêu cầu '
            'mà không chỉ định phòng mong muốn.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingRooms = false;
        });
      }
    }
  }

  Future<void> _close(_AccommodationRequestFormResult? result) async {
    if (_closing) return;

    setState(() {
      _closing = true;
    });

    // Đóng bàn phím và để RenderEditable hoàn tất callback hiển thị caret
    // trước khi bottom sheet bị gỡ khỏi cây render.
    _noteFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 120));

    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  void _submit() {
    final String note = _noteController.text.trim();
    _close(
      _AccommodationRequestFormResult(
        note: note.isEmpty ? null : note,
        // Luồng chuyển phòng hiện chỉ gửi lý do. Ban quản lý tự bố trí phòng.
        desiredRoomId: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final ThemeData baseTheme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          _close(null);
        }
      },
      child: Theme(
        data: baseTheme.copyWith(
          colorScheme: baseTheme.colorScheme.copyWith(
            primary: widget.color,
            secondary: widget.color,
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: AppTheme.colorMain,
            selectionColor: AppTheme.colorMain.withOpacity(0.20),
            selectionHandleColor: AppTheme.colorMain,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFFAFBFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: widget.color, width: 1.6),
            ),
          ),
        ),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: SafeArea(
            top: false,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
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
                              color: widget.color.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              widget.icon,
                              color: widget.color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: AppFontSizes.medium,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111318),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Đóng',
                            onPressed: _closing ? null : () => _close(null),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (widget.currentRoom != null &&
                          widget.currentRoom!.trim().isNotEmpty) ...<Widget>[
                        _buildCurrentRoomCard(),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        widget.description,
                        style: const TextStyle(
                          fontSize: AppFontSizes.font11,
                          color: Color(0xFF666B75),
                          height: 1.45,
                        ),
                      ),
                      // Tạm bỏ phần chọn tòa/phòng trong yêu cầu chuyển phòng.
                      // Sinh viên chỉ nhập lý do, Ban quản lý quyết định phòng mới.
                      const SizedBox(height: 16),
                      VnuFloatingTextFieldAdapter(
                        controller: _noteController,
                        focusNode: _noteFocusNode,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 500,
                        cursorColor: AppTheme.colorMain,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          labelText: widget.noteLabel,
                          hintText: widget.noteHint,
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _closing ? null : () => _close(null),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475467),
                                side: const BorderSide(
                                  color: Color(0xFFD0D5DD),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
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
                              onPressed: _closing ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: widget.color,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: widget.color
                                    .withOpacity(0.55),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _closing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded, size: 18),
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
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentRoomCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
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
              'Phòng hiện tại: ${widget.currentRoom}',
              style: const TextStyle(
                fontSize: AppFontSizes.font11,
                color: Color(0xFF344054),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildingHintFromRoomNumber(String roomNumber) {
    final String value = roomNumber.trim().toUpperCase();
    if (value.isEmpty) return '';

    final RegExpMatch? towerMatch = RegExp(
      r'^(CT\d+)[\-_\s]',
    ).firstMatch(value);
    if (towerMatch != null) {
      return towerMatch.group(1) ?? '';
    }

    final RegExpMatch? letterMatch = RegExp(
      r'^([A-Z]{1,5})(?=\d{2,})',
    ).firstMatch(value);
    return letterMatch?.group(1) ?? '';
  }

  String _buildingDisplayName({
    required List<_AccommodationRoomChoice> rooms,
    required int index,
    required int totalBuildings,
  }) {
    final Set<String> hints = rooms
        .map(
          (_AccommodationRoomChoice room) =>
              _buildingHintFromRoomNumber(room.roomName),
        )
        .where((String value) => value.isNotEmpty)
        .toSet();

    if (hints.length == 1) {
      return 'Tòa ${hints.first}';
    }

    // API rooms chỉ có buildingId, không có tên tòa. Không hiển thị ID kỹ
    // thuật; dùng nhãn thứ tự chỉ khi có nhiều nhóm mà không suy ra được tên.
    if (totalBuildings <= 1) return 'Tòa nhà';
    return 'Tòa nhà ${index + 1}';
  }

  Widget _buildDesiredRoomField() {
    if (_loadingRooms) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFD0D5DD)),
        ),
        child: const Row(
          children: <Widget>[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF078B3E),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đang tải danh sách phòng...',
                style: TextStyle(
                  fontSize: AppFontSizes.font11,
                  color: Color(0xFF667085),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final Map<int, List<_AccommodationRoomChoice>> groupedRooms =
        <int, List<_AccommodationRoomChoice>>{};

    for (final _AccommodationRoomChoice room in _roomChoices) {
      groupedRooms
          .putIfAbsent(room.buildingId, () => <_AccommodationRoomChoice>[])
          .add(room);
    }

    final List<int> buildingIds = groupedRooms.keys.toList()..sort();
    final int selectableRoomCount = _roomChoices
        .where((_AccommodationRoomChoice room) => room.isSelectable)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.apartment_rounded,
              size: 20,
              color: Color(0xFF078B3E),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Chọn tòa nhà và phòng mong muốn',
                style: TextStyle(
                  fontSize: AppFontSizes.font11,
                  color: Color(0xFF344054),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (_roomChoices.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8EF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$selectableRoomCount phòng có thể chọn',
                  style: const TextStyle(
                    fontSize: AppFontSizes.extraSmall,
                    color: Color(0xFF078B3E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _buildManagementArrangementOption(),
        if (buildingIds.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD0D5DD)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (
                  int index = 0;
                  index < buildingIds.length;
                  index++
                ) ...<Widget>[
                  _buildBuildingFolder(
                    buildingId: buildingIds[index],
                    buildingName: _buildingDisplayName(
                      rooms:
                          groupedRooms[buildingIds[index]] ??
                          const <_AccommodationRoomChoice>[],
                      index: index,
                      totalBuildings: buildingIds.length,
                    ),
                    rooms:
                        groupedRooms[buildingIds[index]] ??
                        const <_AccommodationRoomChoice>[],
                  ),
                  if (index < buildingIds.length - 1)
                    const Divider(height: 1, color: Color(0xFFE4E7EC)),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          _roomLoadMessage ??
              'Chạm vào biểu tượng tòa nhà để mở danh sách phòng. '
                  'Phòng được chọn chỉ là nguyện vọng; Ban quản lý quyết định '
                  'phòng chính thức.',
          style: TextStyle(
            fontSize: AppFontSizes.extraSmall,
            height: 1.35,
            color: _roomLoadMessage == null
                ? const Color(0xFF667085)
                : const Color(0xFF9A6700),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementArrangementOption() {
    final bool selected = _selectedRoomValue <= 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _closing
            ? null
            : () {
                setState(() {
                  _selectedRoomValue = -1;
                });
              },
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF8EF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? const Color(0xFF078B3E)
                  : const Color(0xFFD0D5DD),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.auto_awesome_outlined,
                size: 20,
                color: selected
                    ? const Color(0xFF078B3E)
                    : const Color(0xFF667085),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Để Ban quản lý sắp xếp phù hợp',
                      style: TextStyle(
                        fontSize: AppFontSizes.font11,
                        color: Color(0xFF344054),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Không chỉ định phòng cụ thể',
                      style: TextStyle(
                        fontSize: AppFontSizes.extraSmall,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              _buildRoomSelectionIndicator(selected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuildingFolder({
    required int buildingId,
    required String buildingName,
    required List<_AccommodationRoomChoice> rooms,
  }) {
    final bool expanded = _expandedBuildingIds.contains(buildingId);
    final bool hasSelectedRoom = rooms.any(
      (_AccommodationRoomChoice room) => room.id == _selectedRoomValue,
    );
    final int selectableCount = rooms
        .where((_AccommodationRoomChoice room) => room.isSelectable)
        .length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: hasSelectedRoom
              ? const Color(0xFFF1FAF4)
              : const Color(0xFFF8FAFC),
          child: InkWell(
            onTap: _closing
                ? null
                : () {
                    setState(() {
                      if (expanded) {
                        _expandedBuildingIds.remove(buildingId);
                      } else {
                        _expandedBuildingIds.add(buildingId);
                      }
                    });
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: <Widget>[
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 21,
                      color: Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hasSelectedRoom
                          ? const Color(0xFFE0F4E7)
                          : const Color(0xFFE9EEF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.apartment_rounded,
                      size: 22,
                      color: hasSelectedRoom
                          ? const Color(0xFF078B3E)
                          : const Color(0xFF475467),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          buildingName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppFontSizes.font11,
                            color: Color(0xFF344054),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${rooms.length} phòng · $selectableCount phòng có thể chọn',
                          style: const TextStyle(
                            fontSize: AppFontSizes.extraSmall,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasSelectedRoom)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: Color(0xFF078B3E),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (expanded)
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: rooms
                  .map(
                    (_AccommodationRoomChoice room) =>
                        _buildRoomExplorerItem(room),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildRoomExplorerItem(_AccommodationRoomChoice room) {
    final bool selected = room.id == _selectedRoomValue;
    final bool enabled = room.isSelectable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _closing || !enabled
            ? null
            : () {
                setState(() {
                  _selectedRoomValue = room.id;
                });
              },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.fromLTRB(8, 9, 8, 9),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFEAF8EF)
                : enabled
                ? Colors.transparent
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF8FD2A9) : Colors.transparent,
            ),
          ),
          child: Row(
            children: <Widget>[
              const SizedBox(
                width: 18,
                child: Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  size: 16,
                  color: Color(0xFF98A2B3),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFDDF3E5)
                      : const Color(0xFFF1F3F6),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.meeting_room_rounded,
                  size: 21,
                  color: selected
                      ? const Color(0xFF078B3E)
                      : enabled
                      ? const Color(0xFF475467)
                      : const Color(0xFF98A2B3),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      room.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppFontSizes.font11,
                        color: selected
                            ? const Color(0xFF056B31)
                            : enabled
                            ? const Color(0xFF344054)
                            : const Color(0xFF98A2B3),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (room.detailText.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        room.detailText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppFontSizes.extraSmall,
                          color: enabled
                              ? const Color(0xFF667085)
                              : const Color(0xFF98A2B3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              enabled
                  ? _buildRoomSelectionIndicator(selected)
                  : const Icon(
                      Icons.block_rounded,
                      size: 19,
                      color: Color(0xFF98A2B3),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomSelectionIndicator(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? const Color(0xFF078B3E) : Colors.white,
        border: Border.all(
          color: selected ? const Color(0xFF078B3E) : const Color(0xFF98A2B3),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}
