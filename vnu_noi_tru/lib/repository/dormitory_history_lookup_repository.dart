import 'package:dio/dio.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_noi_tru/models/dormitory_registration/registration_history_model.dart';

class DormitoryHistoryLookupRepository {
  DormitoryHistoryLookupRepository._internal() {
    _dio = DioOptions().createDio(ServicesUrl().effectiveKtxDormitoryApiUrl);
  }

  static final DormitoryHistoryLookupRepository _instance =
      DormitoryHistoryLookupRepository._internal();

  factory DormitoryHistoryLookupRepository() => _instance;

  late final Dio _dio;

  Future<DormitoryHistoryResolvedData> loadResolvedHistory(
    Object registrationId,
  ) async {
    await _loadTokenIfNeeded();

    final Map<String, dynamic> historyJson = await _getJson(
      'registrations/$registrationId/histories',
    );

    final RegistrationHistoryResponse historyResponse =
        RegistrationHistoryResponse.fromJson(historyJson);

    final List<Map<String, dynamic>> baseResponses =
        await Future.wait<Map<String, dynamic>>(<Future<Map<String, dynamic>>>[
          _safeGetJson('registrations/$registrationId'),
          _safeGetJson('list'),
          _safeGetJson('room-types'),
          _safeGetJson('priority-objects'),
          _safeGetJson(
            'rooms',
            queryParameters: <String, dynamic>{'size': 1000},
          ),
        ]);

    final Map<String, dynamic> registrationDetail = _extractObject(
      baseResponses[0]['data'],
    );

    final List<Map<String, dynamic>> dormitories = _extractItems(
      baseResponses[1],
    );
    final List<Map<String, dynamic>> roomTypes = _extractItems(
      baseResponses[2],
    );
    final List<Map<String, dynamic>> priorityObjects = _extractItems(
      baseResponses[3],
    );
    final List<Map<String, dynamic>> rooms = _extractItems(baseResponses[4]);

    final Set<int> dormitoryIds = <int>{};

    for (final Map<String, dynamic> dormitory in dormitories) {
      final int? id = _toInt(dormitory['id']);
      if (id != null) dormitoryIds.add(id);
    }

    final int? detailDormitoryId = _toInt(
      registrationDetail['dormitory_id'] ??
          registrationDetail['dormitoryId'] ??
          _nestedValue(registrationDetail, 'dormitory', 'id'),
    );
    if (detailDormitoryId != null) dormitoryIds.add(detailDormitoryId);

    for (final RegistrationHistoryModel history in historyResponse.data) {
      final int? dataDormitoryId = _toInt(
        history.data['dormitory_id'] ?? history.data['dormitoryId'],
      );
      if (dataDormitoryId != null) dormitoryIds.add(dataDormitoryId);

      final int? snapshotDormitoryId = history.accommodation?.dormitoryId;
      if (snapshotDormitoryId != null) dormitoryIds.add(snapshotDormitoryId);
    }

    final List<Map<String, dynamic>> periodResponses = dormitoryIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await Future.wait<Map<String, dynamic>>(
            dormitoryIds.map(
              (int id) => _safeGetJson('$id/registration-periods'),
            ),
          );

    final List<Map<String, dynamic>> periods = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> response in periodResponses) {
      periods.addAll(_extractItems(response));
    }

    return DormitoryHistoryResolvedData(
      histories: historyResponse.data,
      registrationDetail: registrationDetail,
      dormitoriesById: _indexById(dormitories),
      periodsById: _indexById(periods),
      roomTypesById: _indexById(roomTypes),
      priorityObjectsById: _indexById(priorityObjects),
      roomsById: _indexById(rooms),
    );
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final Response<Map<String, dynamic>> response = await _dio
        .get<Map<String, dynamic>>(
          path,
          queryParameters: queryParameters,
          options: _jsonOptions(),
        );

    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _safeGetJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _getJson(path, queryParameters: queryParameters);
    } catch (error) {
      logWarning('History lookup failed for $path: $error');
      return <String, dynamic>{};
    }
  }

  List<Map<String, dynamic>> _extractItems(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];

    if (rawData is List) {
      return rawData
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (rawData is Map) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);
      final dynamic rawItems =
          data['items'] ?? data['data'] ?? data['results'] ?? data['rows'];

      if (rawItems is List) {
        return rawItems
            .whereType<Map>()
            .map((Map item) => Map<String, dynamic>.from(item))
            .toList();
      }

      if (data['id'] != null) {
        return <Map<String, dynamic>>[data];
      }
    }

    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractObject(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  Map<int, Map<String, dynamic>> _indexById(List<Map<String, dynamic>> items) {
    final Map<int, Map<String, dynamic>> result = <int, Map<String, dynamic>>{};

    for (final Map<String, dynamic> item in items) {
      final int? id = _toInt(item['id']);
      if (id != null) result[id] = item;
    }

    return result;
  }

  dynamic _nestedValue(
    Map<String, dynamic> source,
    String objectKey,
    String valueKey,
  ) {
    final dynamic nested = source[objectKey];
    if (nested is Map) return nested[valueKey];
    return null;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Options _jsonOptions() {
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final String token = Globals().token;
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return Options(headers: headers);
  }

  Future<void> _loadTokenIfNeeded() async {
    if (Globals().token.isNotEmpty) return;

    final String? stored = await DataRepository().getSecureSaveKey(kLoginToken);

    if (stored != null && stored.isNotEmpty) {
      Globals().token = stored;
      ApiRepository().setToken(stored);
    }
  }
}

class DormitoryHistoryResolvedData {
  final List<RegistrationHistoryModel> histories;
  final Map<String, dynamic> registrationDetail;
  final Map<int, Map<String, dynamic>> dormitoriesById;
  final Map<int, Map<String, dynamic>> periodsById;
  final Map<int, Map<String, dynamic>> roomTypesById;
  final Map<int, Map<String, dynamic>> priorityObjectsById;
  final Map<int, Map<String, dynamic>> roomsById;

  const DormitoryHistoryResolvedData({
    required this.histories,
    required this.registrationDetail,
    required this.dormitoriesById,
    required this.periodsById,
    required this.roomTypesById,
    required this.priorityObjectsById,
    required this.roomsById,
  });

  String studentNameFor(int? studentId) {
    final String direct = _firstText(<dynamic>[
      registrationDetail['student_name'],
      registrationDetail['studentName'],
      _nestedValue(registrationDetail, 'student', 'full_name'),
      _nestedValue(registrationDetail, 'student', 'fullName'),
    ]);

    return direct.isNotEmpty ? direct : 'Sinh viên đăng ký nội trú';
  }

  String dormitoryNameFor(int? id) {
    if (id == null) return '';
    return _nameFromMap(dormitoriesById[id], <String>['name']);
  }

  String dormitoryAddressFor(int? id) {
    if (id == null) return '';
    return _nameFromMap(dormitoriesById[id], <String>['address']);
  }

  String periodNameFor(int? id) {
    if (id == null) return '';

    final String catalogName = _nameFromMap(periodsById[id], <String>['name']);
    if (catalogName.isNotEmpty) return catalogName;

    final int? detailId = _toInt(
      registrationDetail['registration_period_id'] ??
          registrationDetail['registrationPeriodId'],
    );

    if (detailId == id) {
      return _firstText(<dynamic>[
        registrationDetail['registration_period_name'],
        registrationDetail['registrationPeriodName'],
        _nestedValue(registrationDetail, 'registration_period', 'name'),
        _nestedValue(registrationDetail, 'registrationPeriod', 'name'),
      ]);
    }

    return '';
  }

  String roomTypeNameFor(int? id) {
    if (id == null) return '';
    return _nameFromMap(roomTypesById[id], <String>['name']);
  }

  String priorityObjectNameFor(int? id) {
    if (id == null) return '';
    return _nameFromMap(priorityObjectsById[id], <String>['name']);
  }

  String roomNumberFor(int? id) {
    if (id == null) return '';

    final Map<String, dynamic>? room = roomsById[id];
    final String catalogNumber = _nameFromMap(room, <String>[
      'roomNumber',
      'room_number',
      'name',
    ]);
    if (catalogNumber.isNotEmpty) return catalogNumber;

    final int? detailRoomId = _toInt(
      registrationDetail['room_id'] ?? registrationDetail['roomId'],
    );

    if (detailRoomId == id) {
      return _firstText(<dynamic>[
        registrationDetail['assigned_room'],
        registrationDetail['assignedRoom'],
        _nestedValue(registrationDetail, 'room', 'room_number'),
        _nestedValue(registrationDetail, 'room', 'roomNumber'),
      ]);
    }

    return '';
  }

  String buildingNameFor(int? id) {
    if (id == null) return '';

    for (final Map<String, dynamic> room in roomsById.values) {
      final int? roomBuildingId = _toInt(
        room['buildingId'] ?? room['building_id'],
      );
      if (roomBuildingId != id) continue;

      final dynamic rawBuilding = room['building'];
      if (rawBuilding is String && rawBuilding.trim().isNotEmpty) {
        return _normalizeBuildingName(rawBuilding);
      }
      if (rawBuilding is Map) {
        final Map<String, dynamic> building =
            Map<String, dynamic>.from(rawBuilding);
        final String name = _firstText(<dynamic>[
          building['name'],
          building['buildingName'],
          building['building_name'],
          building['code'],
        ]);
        if (name.isNotEmpty) return _normalizeBuildingName(name);
      }

      final String directName = _firstText(<dynamic>[
        room['buildingName'],
        room['building_name'],
        room['buildingCode'],
        room['building_code'],
      ]);
      if (directName.isNotEmpty) return _normalizeBuildingName(directName);
    }

    return 'Tòa nhà chưa cập nhật tên';
  }

  String buildingNameForRoom(int? roomId) {
    if (roomId == null) return '';
    final Map<String, dynamic>? room = roomsById[roomId];
    if (room == null) return '';
    return buildingNameFor(_toInt(room['buildingId'] ?? room['building_id']));
  }

  static String _normalizeBuildingName(String value) {
    final String text = value.trim();
    if (text.isEmpty) return '';
    final String lower = text.toLowerCase();
    if (lower.startsWith('tòa') ||
        lower.startsWith('toa') ||
        lower.startsWith('block') ||
        lower.startsWith('building')) {
      return text;
    }
    return 'Tòa $text';
  }

  String roomDescriptionFor(int? id) {
    if (id == null) return '';
    final Map<String, dynamic>? room = roomsById[id];
    if (room == null) return '';

    final String number = roomNumberFor(id);
    final String capacity = _firstText(<dynamic>[room['capacity']]);
    final String occupancy = _firstText(<dynamic>[
      room['currentOccupancy'],
      room['current_occupancy'],
    ]);

    final List<String> parts = <String>[];
    if (number.isNotEmpty) parts.add('Phòng $number');
    if (capacity.isNotEmpty) {
      parts.add(
        occupancy.isNotEmpty
            ? '$occupancy/$capacity người'
            : 'Sức chứa $capacity người',
      );
    }

    return parts.join(' - ');
  }

  String currentStatusLabel() {
    return _firstText(<dynamic>[
      registrationDetail['status_label'],
      registrationDetail['statusLabel'],
    ]);
  }

  String statusLabelFor(dynamic status) {
    if (status == null) return 'Chưa xác định';

    final dynamic currentStatus =
        registrationDetail['status'] ?? registrationDetail['status_code'];
    final String currentLabel = currentStatusLabel();

    if (currentLabel.isNotEmpty &&
        currentStatus != null &&
        currentStatus.toString().toLowerCase() ==
            status.toString().toLowerCase()) {
      return currentLabel;
    }

    final String normalized = status.toString().trim().toLowerCase();

    switch (normalized) {
      case '0':
      case 'draft':
        return 'Bản nháp';
      case '1':
      case 'pending':
        return 'Chờ duyệt';
      case '2':
      case 'approved':
        return 'Đã duyệt';
      case '3':
      case 'assigned':
        return 'Đã xếp phòng';
      case '4':
      case 'active':
        return 'Đang lưu trú';
      case '5':
      case 'rejected':
        return 'Từ chối';
      case '6':
      case 'checkout':
        return 'Đã trả phòng';
      case '7':
      case 'terminated':
        return 'Đã chấm dứt';
      default:
        return status.toString();
    }
  }

  String requestStatusLabelFor(dynamic status) {
    if (status == null) return 'Chưa xác định';
    final String normalized = status.toString().trim().toLowerCase();

    switch (normalized) {
      case '0':
        return 'Chưa xử lý';
      case '1':
        return 'Đang xử lý';
      case '2':
        return 'Đã hoàn thành';
      case '3':
        return 'Từ chối';
      default:
        return status.toString();
    }
  }

  String performerNameFor(RegistrationHistoryModel history) {
    final RegistrationHistoryPerformerModel? performer = history.performer;
    if (performer != null && performer.displayName != 'Không có thông tin') {
      final List<String> parts = <String>[performer.displayName];
      if (_hasText(performer.position)) parts.add(performer.position!.trim());
      if (_hasText(performer.unitName)) parts.add(performer.unitName!.trim());
      return parts.join(' - ');
    }

    if (history.performedBy == null) {
      return 'Hệ thống / dữ liệu import';
    }

    return 'API chưa trả thông tin người thực hiện';
  }

  String approvedByNameFor(RegistrationHistoryModel history, int? approvedBy) {
    if (approvedBy == null) return '';

    if (history.performedBy == approvedBy && history.performer != null) {
      return performerNameFor(history);
    }

    return 'API chưa trả thông tin người duyệt';
  }

  static String _nameFromMap(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return '';
    return _firstText(keys.map((String key) => source[key]).toList());
  }

  static dynamic _nestedValue(
    Map<String, dynamic> source,
    String objectKey,
    String valueKey,
  ) {
    final dynamic nested = source[objectKey];
    if (nested is Map) return nested[valueKey];
    return null;
  }

  static String _firstText(Iterable<dynamic> values) {
    for (final dynamic value in values) {
      if (value == null) continue;
      final String text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
