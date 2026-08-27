import 'dart:convert';
import 'package:vnu_core/common/error/app_feedback.dart';
import 'package:vnu_core/common/academic_period_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/hoc_ky_date_helper.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/schedule_override_config.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';

import '../../../models/model.dart';

class VcoreExamScheduleController extends GetxController {
  BuildContext? context;

  RxList<String> danhSachKieuTruong = RxList([]);
  Rxn<String> kieuTruong = Rxn();

  // Raw list of all semesters from API
  RxList<HocKyModel> danhSachHocKy = RxList([]);

  // Selected filters
  RxList<String> danhSachNamHoc = RxList([]);
  RxnString namHocSelected = RxnString();

  RxList<HocKyModel> danhSachHocKyFilter = RxList([]);
  Rxn<HocKyModel> hocKySelected = Rxn();

  // Raw data from cache/API
  RxList<ThoiKhoaBieuModel> listThoiKhoaBieu = RxList([]);
  RxList<LichThiHocKyModel> listLichThi = RxList([]);
  RxList<ScheduleEvent> extraTermCourses = RxList([]);

  // Unified calendar events Map
  RxMap<DateTime, List<ScheduleEvent>> eventsMap = RxMap();

  // Selected date and events for UI
  Rx<DateTime> selectedDay = DateTime.now().obs;
  Rx<DateTime> focusedDay = DateTime.now().obs;
  RxList<ScheduleEvent> selectedEvents = RxList([]);

  RefreshController refreshController = RefreshController();
  RxBool isTheoChuongTrinhDaoTao = true.obs;
  RxBool isLoading = false.obs;
  RxBool showIncompleteExams = false.obs;
  RxBool showExtraTermCourses = false.obs;
  bool skipAutoSelectNearest = false;
  ScheduleOverrideConfig scheduleOverrideConfig = ScheduleOverrideConfig.empty();
  AcademicPeriodConfig academicPeriodConfig = AcademicPeriodConfig.projectDefault();
  RxBool hasPersonalAcademicPeriodOverride = false.obs;

  // Mỗi lần tải lịch có một generation riêng. Response/cache của generation
  // cũ không được phép ghi đè state của học kỳ mới.
  int _scheduleLoadGeneration = 0;
  int _semesterCatalogGeneration = 0;

  // Effective term range shown on the calendar. A student-local override has
  // the highest priority, then the backend-overridden TKB dates, then the
  // semester metadata/fallback range.
  Rxn<DateTime> effectiveTermStartDate = Rxn<DateTime>();
  Rxn<DateTime> effectiveTermEndDate = Rxn<DateTime>();
  RxBool hasPersonalTermDateOverride = false.obs;

  String get _termOverrideScope {
    final value = kieuTruong.value?.trim() ?? '';
    return value.isEmpty ? 'default' : value;
  }

  DateTime? get currentTermStartDate {
    final value = effectiveTermStartDate.value;
    if (value != null) return value;
    final sem = hocKySelected.value;
    return sem == null ? null : HocKyDateHelper.rangeFor(sem).start;
  }

  DateTime? get currentTermEndDate {
    final value = effectiveTermEndDate.value;
    if (value != null) return value;
    final sem = hocKySelected.value;
    return sem == null ? null : HocKyDateHelper.rangeFor(sem).end;
  }

  /// Range thực tế mà TableCalendar được phép hiển thị.
  ///
  /// Nguồn gốc:
  /// 1. Range học kỳ hiện tại (override/backend/fallback).
  /// 2. Mở rộng thêm nếu có event thực tế nằm ngoài metadata học kỳ.
  ///
  /// Invariant bắt buộc:
  /// calendarDisplayRange.start <= focusedDay/selectedDay <= calendarDisplayRange.end.
  HocKyDateRange get calendarDisplayRange {
    final today = _normalizeDate(DateTime.now());
    final sem = hocKySelected.value;

    HocKyDateRange baseRange;
    if (sem == null) {
      baseRange = HocKyDateRange(
        start: DateTime(today.year - 1, 1, 1),
        end: DateTime(today.year + 1, 12, 31),
      );
    } else {
      final fallback = HocKyDateHelper.rangeFor(sem);
      final start = currentTermStartDate ?? fallback.start;
      final end = currentTermEndDate ?? fallback.end;
      baseRange = HocKyDateRange(
        start: _normalizeDate(start),
        end: _normalizeDate(end.isBefore(start) ? start : end),
      );
    }

    return HocKyDateHelper.expandRangeToInclude(
      baseRange,
      eventsMap.keys,
    );
  }

  DateTime clampToCalendarRange(DateTime date) {
    return HocKyDateHelper.clampToRange(date, calendarDisplayRange);
  }

  void normalizeCalendarCursor({String reason = 'normalize'}) {
    final range = calendarDisplayRange;
    final nextFocused = HocKyDateHelper.clampToRange(focusedDay.value, range);
    final nextSelected = HocKyDateHelper.clampToRange(selectedDay.value, range);

    if (nextFocused != _normalizeDate(focusedDay.value)) {
      focusedDay.value = nextFocused;
    }
    if (nextSelected != _normalizeDate(selectedDay.value)) {
      selectedDay.value = nextSelected;
    }

    _logScheduleRange(reason);
  }

  String _semesterStateKey(HocKyModel sem) {
    return '${sem.id ?? ''}|${sem.nam ?? ''}|${sem.ten ?? ''}';
  }

  int _invalidateScheduleLoads(String reason) {
    final generation = ++_scheduleLoadGeneration;
    logInfo(
      '[SCHEDULE_LOAD] generation=$generation status=invalidated reason=$reason',
    );
    return generation;
  }

  bool _isScheduleLoadCurrent({
    required int generation,
    required String semesterKey,
    required String school,
  }) {
    final selected = hocKySelected.value;
    return generation == _scheduleLoadGeneration &&
        selected != null &&
        _semesterStateKey(selected) == semesterKey &&
        (kieuTruong.value ?? '') == school;
  }

  String _scheduleCacheKey(
    String prefix,
    String semesterId,
    String school,
  ) {
    final safeSchool = school
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final scope = safeSchool.isEmpty ? 'default' : safeSchool;
    return '${prefix}_${scope}_$semesterId.json';
  }

  void _logScheduleRange(String reason) {
    final sem = hocKySelected.value;
    final range = calendarDisplayRange;
    final eventDates = eventsMap.keys.map(_normalizeDate).toList()..sort();
    final eventMin = eventDates.isEmpty ? '-' : eventDates.first.toIso8601String();
    final eventMax = eventDates.isEmpty ? '-' : eventDates.last.toIso8601String();

    logInfo(
      '[SCHEDULE_RANGE] reason=$reason '
      'year=${namHocSelected.value ?? '-'} '
      'semesterId=${sem?.id ?? '-'} semester=${sem?.ten ?? '-'} '
      'first=${range.start.toIso8601String()} '
      'last=${range.end.toIso8601String()} '
      'focused=${_normalizeDate(focusedDay.value).toIso8601String()} '
      'selected=${_normalizeDate(selectedDay.value).toIso8601String()} '
      'eventMin=$eventMin eventMax=$eventMax',
    );
  }

  List<LichThiHocKyModel> get incompleteExams {
    return listLichThi.where(_isIncompleteExam).toList();
  }

  bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  bool _isIncompleteExam(LichThiHocKyModel exam) {
    final hasNoDate = _isBlank(exam.ngayThi) || _parseDate(exam.ngayThi) == null;
    final hasNoTime = _isBlank(exam.gioBatDauThi);
    final hasNoRoom = _isBlank(exam.phongThi);
    final hasNoSbd = _isBlank(exam.sobaodanh);
    return hasNoDate || hasNoTime || hasNoRoom || hasNoSbd;
  }

  String _unknownIfBlank(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '?' : text;
  }

  String _buildExamLocation(LichThiHocKyModel exam) {
    final room = _unknownIfBlank(exam.phongThi);
    final address = exam.diaChi?.trim() ?? '';

    if (address.isEmpty) return room;
    return '$room - $address';
  }

  String _buildExamTeacherText(LichThiHocKyModel exam) {
    if (!_isBlank(exam.sobaodanh)) {
      return 'SBD: ${exam.sobaodanh!.trim()}';
    }

    if (!_isBlank(exam.hinhThucThi)) {
      return exam.hinhThucThi!.trim();
    }

    return '?';
  }

  String _classLocation(ThoiKhoaBieuModel classSession) {
    final room = _unknownIfBlank(classSession.tenPhong);
    final address = classSession.diaChi?.trim() ?? '';

    if (address.isEmpty) return room;
    return '$room - $address';
  }

  String _classTeachers(ThoiKhoaBieuModel classSession) {
    final teachers = [
      classSession.giangVien1,
      classSession.giangVien2,
      classSession.giangVien3,
      classSession.giangVien4,
    ].where((g) => g != null && g.trim().isNotEmpty).join(', ');

    return teachers.isEmpty ? '?' : teachers;
  }

  String _lessonLabel(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '?' : 'Tiết $text';
  }

  HocKyDateRange _classDateRange({
    required HocKyModel sem,
    required ThoiKhoaBieuModel classSession,
    required ScheduleCourseOverride? override,
    required bool termOverrideActive,
    required DateTime defaultStart,
    required DateTime defaultEnd,
  }) {
    // If the student has changed the whole semester range, use that range for
    // every normal course. A course-specific override still has higher
    // priority and is clipped inside the selected semester range.
    if (termOverrideActive && override == null) {
      return HocKyDateRange(start: defaultStart, end: defaultEnd);
    }

    final range = HocKyDateHelper.rangeForDates(
      sem,
      startDate: override?.startDate ?? classSession.ngayBatDau,
      endDate: override?.endDate ?? classSession.ngayKetThuc,
    );

    final start = range.start.isBefore(defaultStart) ? defaultStart : range.start;
    final end = range.end.isAfter(defaultEnd) ? defaultEnd : range.end;

    if (end.isBefore(start)) {
      return HocKyDateRange(start: defaultStart, end: defaultEnd);
    }

    return HocKyDateRange(start: start, end: end);
  }

  ScheduleEvent _buildClassEvent({
    required HocKyModel sem,
    required ThoiKhoaBieuModel classSession,
    required DateTime date,
    required ScheduleCourseOverride? override,
    bool fromExtraTerm = false,
  }) {
    final globalRange = academicPeriodConfig.resolveLessonRange(
      classSession.tietBatDau,
      classSession.tietKetThuc,
    );

    final overrideStart = _unknownIfBlank(override?.startTime);
    final overrideEnd = _unknownIfBlank(override?.endTime);
    final hasOverrideStart = overrideStart != '?';
    final hasOverrideEnd = overrideEnd != '?';

    final actualStartTime = hasOverrideStart
        ? overrideStart
        : (globalRange?.startTime ?? '?');
    final actualEndTime = hasOverrideEnd
        ? overrideEnd
        : hasOverrideStart
            ? (AcademicPeriodConfig.addMinutes(
                  overrideStart,
                  academicPeriodConfig.lessonDurationMinutes,
                ) ?? globalRange?.endTime ?? '?')
            : (globalRange?.endTime ?? '?');

    return ScheduleEvent(
      type: ScheduleType.classSession,
      title: _unknownIfBlank(classSession.tenHocPhan) == '?'
          ? 'Lịch học'
          : _unknownIfBlank(classSession.tenHocPhan),
      date: date,
      startTime: _lessonLabel(classSession.tietBatDau),
      endTime: _lessonLabel(classSession.tietKetThuc),
      location: _classLocation(classSession),
      teacher: _classTeachers(classSession),
      hocPhanCode: _unknownIfBlank(classSession.maHocPhan),
      soTinChi: _unknownIfBlank(classSession.soTinChi),
      nhom: _unknownIfBlank(classSession.nhom),
      actualStartTime: actualStartTime == '?' ? null : actualStartTime,
      actualEndTime: actualEndTime == '?' ? null : actualEndTime,
      fromExtraTerm: fromExtraTerm,
      sourceNote: fromExtraTerm ? 'Kỳ phụ' : null,
    );
  }

  bool _hasSelectedNearestDate = false;
  DateTime? pendingInitialDate;
  String? pendingInitialHocKyId;
  String? pendingInitialKieuTruong;
  bool _isInitialDateSet = false;

  /// Context điều hướng ban đầu. Home truyền cả ngày + học kỳ + loại trường
  /// để màn lịch mở đúng chính xác dataset mà Home đang hiển thị.
  void setInitialContext({
    DateTime? date,
    String? hocKyId,
    String? kieuTruongValue,
  }) {
    if (_isInitialDateSet) return;
    _isInitialDateSet = true;

    if (date != null) {
      final normalized = DateTime(date.year, date.month, date.day);
      pendingInitialDate = normalized;
      selectedDay.value = normalized;
      focusedDay.value = normalized;
      skipAutoSelectNearest = true;
    }

    final term = hocKyId?.trim();
    if (term != null && term.isNotEmpty) {
      pendingInitialHocKyId = term;
    }

    final school = kieuTruongValue?.trim();
    if (school != null && school.isNotEmpty) {
      pendingInitialKieuTruong = school;
    }
  }

  void setInitialDate(DateTime date) {
    setInitialContext(date: date);
  }

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    selectedDay.value = DateTime(now.year, now.month, now.day);
    focusedDay.value = DateTime(now.year, now.month, now.day);

  }

  @override
  void onClose() {
    refreshController.dispose();
    super.onClose();
  }

  /// Nạp dữ liệu cho Home bằng CHÍNH pipeline của màn Lịch học & lịch thi.
  /// Home không tự suy luận thứ/ngày nữa; sau hàm này chỉ đọc [eventsMap].
  Future<void> loadDefaultScheduleForHome({DateTime? targetDate}) async {
    final target = _normalizeDate(targetDate ?? DateTime.now());

    scheduleOverrideConfig = await ScheduleOverrideConfigCache().load();

    final schoolResponse = await ApiRepository().getDanhSachKieuTruong();
    danhSachKieuTruong.value = schoolResponse;
    if (schoolResponse.isEmpty) {
      kieuTruong.value = null;
      hocKySelected.value = null;
      listThoiKhoaBieu.clear();
      listLichThi.clear();
      eventsMap.clear();
      selectedEvents.clear();
      return;
    }

    final selectedSchool = schoolResponse.firstWhereOrNull(
          (item) => item == 'TruongChinh',
        ) ??
        schoolResponse.first;
    kieuTruong.value = selectedSchool;

    final semesterResponse =
        await ApiRepository().getDanhSachHocKyTheoThoiKhoaBieu(
      isTheoChuongTrinhDaoTao.value,
      selectedSchool,
    );

    danhSachHocKy.value = semesterResponse;
    if (semesterResponse.isEmpty) {
      hocKySelected.value = null;
      listThoiKhoaBieu.clear();
      listLichThi.clear();
      eventsMap.clear();
      selectedEvents.clear();
      return;
    }

    final years = semesterResponse
        .map((item) => item.nam)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    danhSachNamHoc.value = years;

    HocKyModel? selectedSem = HocKyDateHelper.findContaining(
      semesterResponse,
      target,
    );

    if (selectedSem == null) {
      final newestYear = years.isNotEmpty ? years.first : null;
      final candidates = newestYear == null
          ? List<HocKyModel>.from(semesterResponse)
          : semesterResponse.where((item) => item.nam == newestYear).toList();
      candidates.sort((a, b) => (a.ten ?? '').compareTo(b.ten ?? ''));
      if (candidates.isNotEmpty) {
        selectedSem = candidates.first;
      }
    }

    if (selectedSem == null) {
      hocKySelected.value = null;
      eventsMap.clear();
      selectedEvents.clear();
      return;
    }

    final resolvedSem = selectedSem;
    namHocSelected.value = resolvedSem.nam;
    final sems = semesterResponse
        .where((item) => item.nam == resolvedSem.nam)
        .toList()
      ..sort((a, b) => (a.ten ?? '').compareTo(b.ten ?? ''));
    danhSachHocKyFilter.value = sems;
    hocKySelected.value = resolvedSem;
    _hasSelectedNearestDate = false;
    effectiveTermStartDate.value = null;
    effectiveTermEndDate.value = null;
    hasPersonalTermDateOverride.value = false;

    // Home không yêu cầu tự nhảy selectedDay; chỉ cần eventsMap chính xác.
    selectedDay.value = target;
    focusedDay.value = target;
    pendingInitialDate = null;
    skipAutoSelectNearest = true;

    await _loadData();
    skipAutoSelectNearest = false;
  }

  /// Các API đọc bên dưới là nguồn dùng chung cho Home và calendar.
  /// Chúng KHÔNG tự tạo ngày; chỉ đọc những event đã thực sự tồn tại
  /// trong [eventsMap] do [_generateEventsMap] sinh ra.
  List<ScheduleEvent> getEventsForDate(
    DateTime date, {
    ScheduleType? type,
  }) {
    final key = _normalizeDate(date);
    final result = List<ScheduleEvent>.from(eventsMap[key] ?? const <ScheduleEvent>[]);
    if (type != null) {
      result.removeWhere((event) => event.type != type);
    }
    result.sort(_compareScheduleEvents);
    return result;
  }

  List<ScheduleEvent> getEventsInRange({
    required DateTime from,
    required DateTime toExclusive,
    ScheduleType? type,
  }) {
    final start = _normalizeDate(from);
    final end = _normalizeDate(toExclusive);
    final result = <ScheduleEvent>[];

    final keys = eventsMap.keys.map(_normalizeDate).toSet().toList()..sort();
    for (final key in keys) {
      if (key.isBefore(start) || !key.isBefore(end)) continue;
      final events = eventsMap[key] ?? const <ScheduleEvent>[];
      for (final event in events) {
        if (type == null || event.type == type) {
          result.add(event);
        }
      }
    }

    result.sort(_compareScheduleEvents);
    return result;
  }

  DateTime? getFirstEventDateFrom(
    DateTime from, {
    ScheduleType? type,
  }) {
    final start = _normalizeDate(from);
    final keys = eventsMap.keys.map(_normalizeDate).toSet().toList()..sort();

    for (final key in keys) {
      if (key.isBefore(start)) continue;
      final hasEvent = (eventsMap[key] ?? const <ScheduleEvent>[]).any(
        (event) => type == null || event.type == type,
      );
      if (hasEvent) return key;
    }
    return null;
  }

  int _compareScheduleEvents(ScheduleEvent a, ScheduleEvent b) {
    final dateCompare = _normalizeDate(a.date).compareTo(_normalizeDate(b.date));
    if (dateCompare != 0) return dateCompare;

    final startA = _extractStartOrder(a.startTime);
    final startB = _extractStartOrder(b.startTime);
    if (startA != startB) return startA.compareTo(startB);
    return a.title.compareTo(b.title);
  }

  getDanhSachKieuTruong() async {
    kieuTruong.value = null;
    try {
      Utils.showProgress(context);
      var response = await ApiRepository().getDanhSachKieuTruong();
      Utils.dismissProgress(context);

      danhSachKieuTruong.value = response;
      if (danhSachKieuTruong.isNotEmpty) {
        final preferredSchool = pendingInitialKieuTruong;
        kieuTruong.value = preferredSchool != null &&
                danhSachKieuTruong.contains(preferredSchool)
            ? preferredSchool
            : (danhSachKieuTruong.firstWhereOrNull((obj) {
                  return obj == "TruongChinh";
                }) ??
                danhSachKieuTruong.first);
        getDanhSachHocKy();
      }
    } catch (e) {
      Utils.dismissProgress(context);
      AppFeedback.showError(e);
    }
  }

  Future<void> getDanhSachHocKy() async {
    _invalidateScheduleLoads('reload-semester-catalog');
    final catalogGeneration = ++_semesterCatalogGeneration;
    final requestedSchool = kieuTruong.value ?? '';
    final requestedMode = isTheoChuongTrinhDaoTao.value;

    danhSachHocKy.value = [];
    danhSachNamHoc.value = [];
    danhSachHocKyFilter.value = [];
    namHocSelected.value = null;
    hocKySelected.value = null;
    listThoiKhoaBieu.clear();
    listLichThi.clear();
    eventsMap.clear();
    selectedEvents.clear();
    _hasSelectedNearestDate = false;

    logInfo(
      '[SCHEDULE_CATALOG] generation=$catalogGeneration status=started '
      'school=$requestedSchool mode=$requestedMode',
    );

    try {
      Utils.showProgress(context);
      final response = await ApiRepository().getDanhSachHocKyTheoThoiKhoaBieu(
        requestedMode,
        requestedSchool,
      );
      Utils.dismissProgress(context);

      final stillCurrent = catalogGeneration == _semesterCatalogGeneration &&
          (kieuTruong.value ?? '') == requestedSchool &&
          isTheoChuongTrinhDaoTao.value == requestedMode;
      if (!stillCurrent) {
        logInfo(
          '[SCHEDULE_CATALOG] generation=$catalogGeneration status=ignored_stale',
        );
        return;
      }

      danhSachHocKy.value = response;
      if (danhSachHocKy.isEmpty) {
        normalizeCalendarCursor(reason: 'empty-semester-catalog');
        return;
      }

      final years = response
          .map((e) => e.nam)
          .whereType<String>()
          .toSet()
          .toList();
      years.sort((a, b) => b.compareTo(a));
      danhSachNamHoc.value = years;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final targetDate = pendingInitialDate ?? today;
      final preferredTermId = pendingInitialHocKyId;
      final exactSem = preferredTermId == null
          ? null
          : response.firstWhereOrNull(
              (item) => (item.id ?? '').trim() == preferredTermId,
            );
      final currentSem =
          exactSem ?? HocKyDateHelper.findContaining(response, targetDate);

      if (currentSem != null) {
        final year = currentSem.nam ?? years.first;
        namHocSelected.value = year;

        final sems = response.where((e) => e.nam == year).toList();
        sems.sort((a, b) {
          final tA = a.ten ?? '';
          final tB = b.ten ?? '';
          return tA.compareTo(tB);
        });
        danhSachHocKyFilter.value = sems;

        selectSemester(currentSem);
      } else if (danhSachNamHoc.isNotEmpty) {
        selectYear(danhSachNamHoc.first);
      }

      logInfo(
        '[SCHEDULE_CATALOG] generation=$catalogGeneration status=completed '
        'years=${danhSachNamHoc.length} semesters=${danhSachHocKy.length}',
      );
    } catch (e) {
      Utils.dismissProgress(context);
      if (catalogGeneration != _semesterCatalogGeneration) {
        logInfo(
          '[SCHEDULE_CATALOG] generation=$catalogGeneration status=ignored_stale_error',
        );
        return;
      }
      AppFeedback.showError(e);
    }
  }

  Future<List<HocKyModel>> previewHocKyCatalog(String school) async {
    final requestedSchool = school.trim();
    if (requestedSchool.isEmpty) return const <HocKyModel>[];

    logInfo(
      '[SELECT_PREVIEW] id=academic_period level=school '
      'school=$requestedSchool',
    );

    return ApiRepository().getDanhSachHocKyTheoThoiKhoaBieu(
      isTheoChuongTrinhDaoTao.value,
      requestedSchool,
    );
  }

  void commitAcademicPeriodSelection({
    required String school,
    required String year,
    required List<HocKyModel> catalog,
    required HocKyModel semester,
  }) {
    _invalidateScheduleLoads('academic-period-commit');
    _semesterCatalogGeneration++;

    kieuTruong.value = school;
    danhSachHocKy.value = List<HocKyModel>.from(catalog);

    final years = catalog
        .map((item) => item.nam?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    danhSachNamHoc.value = years;

    namHocSelected.value = year;
    final semesters = catalog.where((item) => item.nam == year).toList()
      ..sort((a, b) => (a.ten ?? '').compareTo(b.ten ?? ''));
    danhSachHocKyFilter.value = semesters;

    // Manual selection supersedes any pending deep-link/bootstrap target.
    pendingInitialDate = null;
    pendingInitialHocKyId = null;
    pendingInitialKieuTruong = null;

    logInfo(
      '[SCHEDULE_SELECT] type=academic-period '
      'school=$school year=$year '
      'semesterId=${semester.id ?? '-'} semester=${semester.ten ?? '-'}',
    );

    selectSemester(semester);
  }

  void selectYear(String year) {
    logInfo('[SCHEDULE_SELECT] type=year year=$year');
    namHocSelected.value = year;

    final sems = danhSachHocKy.where((e) => e.nam == year).toList();
    sems.sort((a, b) {
      final tA = a.ten ?? '';
      final tB = b.ten ?? '';
      return tA.compareTo(tB);
    });
    danhSachHocKyFilter.value = sems;

    if (danhSachHocKyFilter.isNotEmpty) {
      selectSemester(danhSachHocKyFilter.first);
      return;
    }

    _invalidateScheduleLoads('year-without-semester');
    hocKySelected.value = null;
    listThoiKhoaBieu.clear();
    listLichThi.clear();
    eventsMap.clear();
    selectedEvents.clear();
    extraTermCourses.clear();
    showExtraTermCourses.value = false;
    showIncompleteExams.value = false;
    normalizeCalendarCursor(reason: 'year-without-semester');
  }

  void selectSemester(HocKyModel sem) {
    logInfo(
      '[SCHEDULE_SELECT] type=semester '
      'year=${sem.nam ?? '-'} semesterId=${sem.id ?? '-'} semester=${sem.ten ?? '-'}',
    );

    hocKySelected.value = sem;
    _hasSelectedNearestDate = false;
    effectiveTermStartDate.value = null;
    effectiveTermEndDate.value = null;
    hasPersonalTermDateOverride.value = false;

    // Không để dataset của học kỳ trước hiển thị trong lúc học kỳ mới đang tải.
    listThoiKhoaBieu.clear();
    listLichThi.clear();
    eventsMap.clear();
    selectedEvents.clear();
    extraTermCourses.clear();
    showExtraTermCourses.value = false;
    showIncompleteExams.value = false;

    final baseRange = HocKyDateHelper.rangeFor(sem);
    final requestedTarget = pendingInitialDate ?? baseRange.start;
    final targetDate = HocKyDateHelper.clampToRange(
      requestedTarget,
      baseRange,
    );

    focusedDay.value = targetDate;
    selectedDay.value = targetDate;
    normalizeCalendarCursor(reason: 'semester-selected');

    refreshData();
  }

  Future<void> refreshData() => _loadData();

  Future<void> _loadData() async {
    // One resolver supplies the exact same clock values to Home and Calendar.
    // Server -> LKG cache on network failure -> exact project default.
    final periodRepository = AcademicPeriodConfigRepository();
    academicPeriodConfig = await periodRepository.load();
    hasPersonalAcademicPeriodOverride.value =
        await periodRepository.hasPersonalOverride();
    logInfo(
      '[SCHEDULE_PERIOD_CONFIG] action=apply_to_controller '
      'personal=${hasPersonalAcademicPeriodOverride.value} '
      'duration=${academicPeriodConfig.lessonDurationMinutes} '
      'break=${academicPeriodConfig.defaultBreakMinutes}',
    );
    final sem = hocKySelected.value;
    if (sem == null) {
      _invalidateScheduleLoads('load-without-semester');
      eventsMap.clear();
      selectedEvents.clear();
      extraTermCourses.clear();
      showExtraTermCourses.value = false;
      showIncompleteExams.value = false;

      refreshController.refreshCompleted();
      refreshController.loadComplete();
      normalizeCalendarCursor(reason: 'load-without-semester');
      return;
    }

    final generation = ++_scheduleLoadGeneration;
    final semesterKey = _semesterStateKey(sem);
    final hocKyId = sem.id ?? '';
    final kieuTruongVal = kieuTruong.value ?? '';
    final tkbCacheKey = _scheduleCacheKey('tkb', hocKyId, kieuTruongVal);
    final examCacheKey = _scheduleCacheKey('lichthi', hocKyId, kieuTruongVal);

    logInfo(
      '[SCHEDULE_LOAD] generation=$generation status=started '
      'semesterId=$hocKyId school=$kieuTruongVal',
    );

    bool isCurrent() => _isScheduleLoadCurrent(
          generation: generation,
          semesterKey: semesterKey,
          school: kieuTruongVal,
        );

    // Cache-first: chỉ apply cache nếu request này vẫn là lựa chọn hiện tại.
    isLoading.value = true;
    try {
      final loadedOverride = await ScheduleOverrideConfigCache().load();
      final cachedTkb = await VnuCacheFileManager().getCacheFile(tkbCacheKey);
      final cachedLichThi =
          await VnuCacheFileManager().getCacheFile(examCacheKey);

      if (!isCurrent()) {
        logInfo(
          '[SCHEDULE_LOAD] generation=$generation status=ignored_stale source=cache',
        );
        return;
      }

      scheduleOverrideConfig = loadedOverride;

      List<ThoiKhoaBieuModel> localTkb = [];
      List<LichThiHocKyModel> localLichThi = [];

      if (cachedTkb != null) {
        final decoded = json.decode(cachedTkb);
        if (decoded is List) {
          localTkb = decoded
              .map((e) => ThoiKhoaBieuModel.fromJson(e))
              .toList();
        }
      }
      if (cachedLichThi != null) {
        final decoded = json.decode(cachedLichThi);
        if (decoded is List) {
          localLichThi = decoded
              .map((e) => LichThiHocKyModel.fromJson(e))
              .toList();
        }
      }

      if (localTkb.isNotEmpty || localLichThi.isNotEmpty) {
        listThoiKhoaBieu.value = localTkb;
        listLichThi.value = localLichThi;
        _generateEventsMap(sem);
        logInfo(
          '[SCHEDULE_LOAD] generation=$generation status=applied source=cache',
        );
      }
    } catch (e) {
      debugPrint('Error loading schedule from cache: $e');
    } finally {
      if (isCurrent()) {
        isLoading.value = false;
      }
    }

    if (!isCurrent()) return;

    // Refresh from Network.
    try {
      final loadedOverride = await ScheduleOverrideConfigCache().load();
      final results = await Future.wait([
        ApiRepository().getThoiKhoaBieuHocKy(hocKyId, kieuTruongVal),
        ApiRepository().getLichThiHocKy(hocKyId, kieuTruongVal),
      ]);

      final netTkb = results[0] as List<ThoiKhoaBieuModel>;
      final netLichThi = results[1] as List<LichThiHocKyModel>;

      if (!isCurrent()) {
        logInfo(
          '[SCHEDULE_LOAD] generation=$generation status=ignored_stale source=network',
        );
        return;
      }

      // Chỉ generation hiện tại mới được ghi cache; tránh response cũ cùng
      // semester ghi đè cache sau một pull-to-refresh mới hơn.
      await VnuCacheFileManager().saveCacheFile(
        tkbCacheKey,
        json.encode(netTkb.map((e) => e.toJson()).toList()),
      );
      await VnuCacheFileManager().saveCacheFile(
        examCacheKey,
        json.encode(netLichThi.map((e) => e.toJson()).toList()),
      );

      if (!isCurrent()) {
        logInfo(
          '[SCHEDULE_LOAD] generation=$generation status=ignored_stale source=post_cache_write',
        );
        return;
      }

      scheduleOverrideConfig = loadedOverride;
      listThoiKhoaBieu.value = netTkb;
      listLichThi.value = netLichThi;
      _generateEventsMap(sem);

      refreshController.refreshCompleted();
      refreshController.loadComplete();
      logInfo(
        '[SCHEDULE_LOAD] generation=$generation status=completed source=network',
      );
    } catch (e) {
      if (!isCurrent()) {
        logInfo(
          '[SCHEDULE_LOAD] generation=$generation status=ignored_stale source=network_error',
        );
        return;
      }

      debugPrint('Error fetching schedule from network: $e');
      refreshController.refreshFailed();
      if (listThoiKhoaBieu.isEmpty && listLichThi.isEmpty) {
        AppFeedback.showError(e);
      }
    }
  }

  void _generateEventsMap(HocKyModel sem) {
    final Map<DateTime, List<ScheduleEvent>> tempMap = {};
    final extraCourses = <ScheduleEvent>[];

    // 1. Map Lịch thi.
// Chỉ cần có ngày thi hợp lệ thì vẫn hiển thị trên calendar.
// Nếu thiếu giờ/phòng/SBD thì các trường thiếu hiển thị bằng "?".
// Đồng thời vẫn được giữ trong tab "Chưa cập nhật" thông qua incompleteExams.
    for (var exam in listLichThi) {
      final examDate = _parseDate(exam.ngayThi);

      // Không có ngày thi thì không thể gắn lên calendar.
      // Nhưng vẫn nằm trong tab "Chưa cập nhật".
      if (examDate == null) continue;

      final key = _normalizeDate(examDate);

      final event = ScheduleEvent(
        type: ScheduleType.exam,
        title: _unknownIfBlank(exam.tenHocPhan) == '?'
            ? 'Lịch thi'
            : _unknownIfBlank(exam.tenHocPhan),
        date: examDate,
        startTime: _unknownIfBlank(exam.gioBatDauThi),
        endTime: !_isBlank(exam.thoiLuong)
            ? '${exam.thoiLuong!.trim()} phút'
            : '?',
        location: _buildExamLocation(exam),
        teacher: _buildExamTeacherText(exam),
        hocPhanCode: _unknownIfBlank(exam.maHocPhan),
        id: exam.idLichThi,
        soTinChi: exam.soTinChi,
        caThi: _unknownIfBlank(exam.caThi),
        hinhThucThi: _unknownIfBlank(exam.hinhThucThi),
        soBaoDanh: _unknownIfBlank(exam.sobaodanh),
      );

      if (!tempMap.containsKey(key)) {
        tempMap[key] = [];
      }
      tempMap[key]!.add(event);
    }

    // 2. Map Lich hoc (Class schedule) - recurring weekly on weekdays.
    // Priority:
    // student local override > backend-overridden TKB dates > semester metadata.
    final termOverride = scheduleOverrideConfig.termFor(
      sem,
      scope: _termOverrideScope,
    );
    final termOverrideRange = _rangeFromTermOverride(termOverride);
    final semesterRange = termOverrideRange ??
        _backendScheduleRange() ??
        HocKyDateHelper.rangeFor(sem);
    final startDate = semesterRange.start;
    final endDate = semesterRange.end;
    final isExtraTerm = HocKyDateHelper.isExtraTerm(sem);

    effectiveTermStartDate.value = startDate;
    effectiveTermEndDate.value = endDate;
    hasPersonalTermDateOverride.value =
        scheduleOverrideConfig.hasScopedTermOverride(
      sem,
      scope: _termOverrideScope,
    );

    for (var classSession in listThoiKhoaBieu) {
      final override = scheduleOverrideConfig.courseFor(sem, classSession);
      if (isExtraTerm) {
        extraCourses.add(
          _buildClassEvent(
            sem: sem,
            classSession: classSession,
            date: startDate,
            override: override,
            fromExtraTerm: true,
          ),
        );
        continue;
      }

      final ngayTrongTuanStr = classSession.ngayTrongTuan;
      if (ngayTrongTuanStr == null || ngayTrongTuanStr.isEmpty) continue;

      int? ngayTrongTuan = int.tryParse(ngayTrongTuanStr);
      if (ngayTrongTuan == null) continue;

      // Dart weekday representation: 1 = Monday, ..., 7 = Sunday
      // ngayTrongTuan mapping matches: '1' is Thứ 2 (Monday), ..., '7' is Chủ nhật (Sunday)
      int targetWeekday = ngayTrongTuan;

      final classRange = _classDateRange(
        sem: sem,
        classSession: classSession,
        override: override,
        termOverrideActive: termOverrideRange != null,
        defaultStart: startDate,
        defaultEnd: endDate,
      );

      for (var date = classRange.start;
      date.isBefore(classRange.end) || date.isAtSameMomentAs(classRange.end);
      date = date.add(const Duration(days: 1))) {
        if (date.weekday == targetWeekday) {
          final key = _normalizeDate(date);

          final event = _buildClassEvent(
            sem: sem,
            classSession: classSession,
            date: date,
            override: override,
          );

          if (!tempMap.containsKey(key)) {
            tempMap[key] = [];
          }

          tempMap[key]!.add(event);
        }
      }
    }

    eventsMap.value = tempMap;

    extraTermCourses.value = extraCourses;
    showExtraTermCourses.value = isExtraTerm && extraCourses.isNotEmpty;

    if (showExtraTermCourses.value) {
      showIncompleteExams.value = false;
    }
    if (pendingInitialDate != null) {
      final requestedDate = _normalizeDate(pendingInitialDate!);
      pendingInitialDate = null;

      if (eventsMap.containsKey(requestedDate) &&
          (eventsMap[requestedDate]?.isNotEmpty ?? false)) {
        selectedDay.value = requestedDate;
        focusedDay.value = requestedDate;
      } else {
        // Màn Home có thể mở lịch tại "hôm nay" trong khi học kỳ thực tế
        // chưa bắt đầu. Khi ngày yêu cầu không có sự kiện, tự đưa tới sự kiện
        // gần nhất ở phía sau để người dùng không nhìn thấy một calendar trống.
        _selectNearestEventDateFrom(requestedDate, preferFuture: true);
      }

      skipAutoSelectNearest = false;
    } else if (!skipAutoSelectNearest && !_hasSelectedNearestDate) {
      _selectNearestEventDate();
      _hasSelectedNearestDate = true;
    }

    normalizeCalendarCursor(reason: 'events-generated');
    updateSelectedEvents();
  }

  HocKyDateRange? _rangeFromTermOverride(ScheduleTermOverride? override) {
    if (override == null) return null;
    final start = HocKyDateHelper.parseApiDate(override.startDate);
    final end = HocKyDateHelper.parseApiDate(override.endDate);
    if (start == null || end == null || end.isBefore(start)) return null;
    return HocKyDateRange(start: start, end: end);
  }

  HocKyDateRange? _backendScheduleRange() {
    DateTime? minStart;
    DateTime? maxEnd;

    for (final item in listThoiKhoaBieu) {
      final start = HocKyDateHelper.parseApiDate(item.ngayBatDau);
      final end = HocKyDateHelper.parseApiDate(item.ngayKetThuc);

      if (start != null && (minStart == null || start.isBefore(minStart))) {
        minStart = start;
      }
      if (end != null && (maxEnd == null || end.isAfter(maxEnd))) {
        maxEnd = end;
      }
    }

    if (minStart == null || maxEnd == null || maxEnd.isBefore(minStart)) {
      return null;
    }

    return HocKyDateRange(start: minStart, end: maxEnd);
  }

  Future<bool> savePersonalTermDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final sem = hocKySelected.value;
    if (sem == null) return false;

    final start = HocKyDateHelper.dateOnly(startDate);
    final end = HocKyDateHelper.dateOnly(endDate);
    if (end.isBefore(start)) {
      snackBarError('Ng\u00e0y k\u1ebft th\u00fac ph\u1ea3i t\u1eeb ng\u00e0y b\u1eaft \u0111\u1ea7u tr\u1edf \u0111i.');
      return false;
    }

    logInfo(
      '[SCHEDULE_ADJUST] action=save_term_range status=started '
      'start=${_formatIsoDate(start)} end=${_formatIsoDate(end)} '
      'semester=${sem.id ?? sem.ten ?? '-'} scope=$_termOverrideScope',
    );

    scheduleOverrideConfig = scheduleOverrideConfig.withTermOverride(
      sem,
      ScheduleTermOverride(
        startDate: _formatIsoDate(start),
        endDate: _formatIsoDate(end),
      ),
      scope: _termOverrideScope,
    );

    await ScheduleOverrideConfigCache().save(scheduleOverrideConfig);
    _generateEventsMap(sem);
    _keepSelectedDayInsideCurrentRange();
    update();
    logSuccess(
      '[SCHEDULE_ADJUST] action=save_term_range status=success '
      'start=${_formatIsoDate(start)} end=${_formatIsoDate(end)}',
    );
    snackBarSuccess('\u0110\u00e3 l\u01b0u kho\u1ea3ng ng\u00e0y l\u1ecbch h\u1ecdc c\u00e1 nh\u00e2n.');
    return true;
  }

  Future<void> clearPersonalTermDateRange() async {
    final sem = hocKySelected.value;
    if (sem == null) return;

    logInfo(
      '[SCHEDULE_ADJUST] action=clear_term_range status=started '
      'semester=${sem.id ?? sem.ten ?? '-'} scope=$_termOverrideScope',
    );

    scheduleOverrideConfig = scheduleOverrideConfig.withTermOverride(
      sem,
      null,
      scope: _termOverrideScope,
    );

    await ScheduleOverrideConfigCache().save(scheduleOverrideConfig);
    _generateEventsMap(sem);
    _keepSelectedDayInsideCurrentRange();
    update();
    logSuccess('[SCHEDULE_ADJUST] action=clear_term_range status=success');
    snackBarSuccess('\u0110\u00e3 kh\u00f4i ph\u1ee5c th\u1eddi gian t\u1eeb h\u1ec7 th\u1ed1ng.');
  }

  /// Lưu đồng thời khoảng ngày + cấu hình giờ tiết cá nhân trên app.
  /// Không đóng sheet; eventsMap được regenerate ngay.
  Future<bool> savePersonalScheduleAdjustments({
    required DateTime startDate,
    required DateTime endDate,
    required AcademicPeriodConfig periodConfig,
  }) async {
    final sem = hocKySelected.value;
    if (sem == null) return false;

    final start = HocKyDateHelper.dateOnly(startDate);
    final end = HocKyDateHelper.dateOnly(endDate);
    if (end.isBefore(start)) {
      snackBarError('Ngày kết thúc phải từ ngày bắt đầu trở đi.');
      logWarning(
        '[SCHEDULE_ADJUST] action=save_all status=rejected reason=invalid_range',
      );
      return false;
    }

    logInfo(
      '[SCHEDULE_ADJUST] action=save_all status=started '
      'semester=${sem.id ?? sem.ten ?? '-'} scope=$_termOverrideScope '
      'start=${_formatIsoDate(start)} end=${_formatIsoDate(end)} '
      'duration=${periodConfig.lessonDurationMinutes} '
      'break=${periodConfig.defaultBreakMinutes}',
    );

    final normalizedPeriods = periodConfig.copyWith(
      configured: true,
      enabled: true,
      version: 'personal-v1',
      updatedAt: DateTime.now(),
    );

    final periodSaved =
        await AcademicPeriodConfigRepository().savePersonal(normalizedPeriods);
    if (!periodSaved) {
      logError(
        '[SCHEDULE_ADJUST] action=save_all status=failed step=period_cache',
      );
      snackBarError('Không thể lưu cấu hình giờ tiết. Vui lòng thử lại.');
      return false;
    }

    scheduleOverrideConfig = scheduleOverrideConfig.withTermOverride(
      sem,
      ScheduleTermOverride(
        startDate: _formatIsoDate(start),
        endDate: _formatIsoDate(end),
      ),
      scope: _termOverrideScope,
    );
    await ScheduleOverrideConfigCache().save(scheduleOverrideConfig);

    academicPeriodConfig = normalizedPeriods;
    hasPersonalAcademicPeriodOverride.value = true;
    _generateEventsMap(sem);
    _keepSelectedDayInsideCurrentRange();
    update();

    logSuccess(
      '[SCHEDULE_ADJUST] action=save_all status=success '
      'start=${_formatIsoDate(start)} end=${_formatIsoDate(end)} '
      'periods=${normalizedPeriods.maxPeriods}',
    );
    snackBarSuccess('Đã lưu điều chỉnh lịch học.');
    return true;
  }

  /// Xóa toàn bộ điều chỉnh cá nhân của màn lịch và regenerate ngay.
  Future<bool> restorePersonalScheduleDefaults() async {
    final sem = hocKySelected.value;
    if (sem == null) return false;

    logInfo(
      '[SCHEDULE_ADJUST] action=restore_all status=started '
      'semester=${sem.id ?? sem.ten ?? '-'} scope=$_termOverrideScope',
    );

    scheduleOverrideConfig = scheduleOverrideConfig.withTermOverride(
      sem,
      null,
      scope: _termOverrideScope,
    );
    await ScheduleOverrideConfigCache().save(scheduleOverrideConfig);

    final repository = AcademicPeriodConfigRepository();
    await repository.clearPersonal();
    academicPeriodConfig = await repository.load(ignorePersonal: true);
    hasPersonalAcademicPeriodOverride.value = false;

    _generateEventsMap(sem);
    _keepSelectedDayInsideCurrentRange();
    update();

    logSuccess(
      '[SCHEDULE_ADJUST] action=restore_all status=success '
      'duration=${academicPeriodConfig.lessonDurationMinutes} '
      'break=${academicPeriodConfig.defaultBreakMinutes}',
    );
    snackBarSuccess('Đã khôi phục lịch học mặc định.');
    return true;
  }

  String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _keepSelectedDayInsideCurrentRange() {
    normalizeCalendarCursor(reason: 'term-range-changed');
    updateSelectedEvents();
  }

  void _selectNearestEventDateFrom(
    DateTime target, {
    bool preferFuture = true,
  }) {
    if (eventsMap.isEmpty) {
      selectedDay.value = _normalizeDate(target);
      focusedDay.value = _normalizeDate(target);
      return;
    }

    final normalizedTarget = _normalizeDate(target);
    final dates = eventsMap.keys
        .where((date) => (eventsMap[date]?.isNotEmpty ?? false))
        .map(_normalizeDate)
        .toSet()
        .toList()
      ..sort();

    if (dates.isEmpty) {
      selectedDay.value = normalizedTarget;
      focusedDay.value = normalizedTarget;
      return;
    }

    DateTime? selected;

    if (preferFuture) {
      for (final date in dates) {
        if (!date.isBefore(normalizedTarget)) {
          selected = date;
          break;
        }
      }
    }

    selected ??= dates.reduce((a, b) {
      final diffA = a.difference(normalizedTarget).inDays.abs();
      final diffB = b.difference(normalizedTarget).inDays.abs();
      if (diffA == diffB) return a.isAfter(b) ? a : b;
      return diffA < diffB ? a : b;
    });

    selectedDay.value = selected;
    focusedDay.value = selected;
  }

  void _selectNearestEventDate() {
    if (eventsMap.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (eventsMap.containsKey(today)) {
      selectedDay.value = today;
      focusedDay.value = today;
      return;
    }

    DateTime? nearestDate;
    int minDiffInDays = -1;

    for (var date in eventsMap.keys) {
      final diff = (date.difference(today).inDays).abs();
      if (minDiffInDays == -1 || diff < minDiffInDays) {
        minDiffInDays = diff;
        nearestDate = date;
      } else if (diff == minDiffInDays) {
        if (nearestDate != null && date.isAfter(nearestDate)) {
          nearestDate = date;
        }
      }
    }

    if (nearestDate != null) {
      selectedDay.value = nearestDate;
      focusedDay.value = nearestDate;
    }
  }

  void selectCalendarDay(DateTime selected, DateTime focused) {
    showIncompleteExams.value = false;
    showExtraTermCourses.value = false;
    selectedDay.value = clampToCalendarRange(selected);
    focusedDay.value = clampToCalendarRange(focused);
    updateSelectedEvents();
  }

  void setCalendarFocusedDay(DateTime focused) {
    focusedDay.value = clampToCalendarRange(focused);
  }

  void updateSelectedEvents() {
    final key = _normalizeDate(selectedDay.value);
    final events = List<ScheduleEvent>.from(eventsMap[key] ?? []);
    // Sort by real lesson/exam start time instead of string compare.
    events.sort((a, b) {
      final startA = _extractStartOrder(a.startTime);
      final startB = _extractStartOrder(b.startTime);
      if (startA != startB) return startA.compareTo(startB);
      return a.title.compareTo(b.title);
    });
    selectedEvents.value = events;
  }

  int _extractStartOrder(String value) {
    if (value.trim().isEmpty) return 9999;

    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(value);
    if (timeMatch != null) {
      final hour = int.tryParse(timeMatch.group(1) ?? '') ?? 99;
      final minute = int.tryParse(timeMatch.group(2) ?? '') ?? 99;
      return hour * 60 + minute;
    }

    final lessonMatch = RegExp(r'\d+').firstMatch(value);
    if (lessonMatch != null) {
      final lesson = int.tryParse(lessonMatch.group(0) ?? '') ?? 9999;
      return lesson * 100;
    }

    return 9999;
  }

  DateTime _normalizeDate(DateTime date) {
    return HocKyDateHelper.dateOnly(date);
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    var parsed = DateTime.tryParse(dateStr);
    if (parsed != null) return parsed;

    // Attempt parsing dd/MM/yyyy or dd-MM-yyyy
    final cleanStr = dateStr.replaceAll('-', '/');
    var parts = cleanStr.split('/');
    if (parts.length == 3) {
      int? day = int.tryParse(parts[0]);
      int? month = int.tryParse(parts[1]);
      int? year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  // ignore: unused_element
  DateTime _inferSemesterStartDate(HocKyModel sem) {
    final yearStr = sem.nam ?? '';
    final semName = sem.ten ?? '';
    int startYear = DateTime.now().year;

    final years = yearStr.split('-');
    if (years.isNotEmpty) {
      startYear = int.tryParse(years[0]) ?? startYear;
    }
    int endYear = startYear + 1;
    if (years.length > 1) {
      endYear = int.tryParse(years[1]) ?? endYear;
    }

    if (semName.contains('1')) {
      return DateTime(startYear, 8, 15);
    } else if (semName.contains('2')) {
      return DateTime(endYear, 2, 1);
    } else if (semName.contains('3') || semName.toLowerCase().contains('he') || semName.toLowerCase().contains('hè')) {
      return DateTime(endYear, 7, 1);
    }
    return DateTime(startYear, 9, 1);
  }

  // ignore: unused_element
  DateTime _inferSemesterEndDate(HocKyModel sem) {
    final yearStr = sem.nam ?? '';
    final semName = sem.ten ?? '';
    int startYear = DateTime.now().year;

    final years = yearStr.split('-');
    if (years.isNotEmpty) {
      startYear = int.tryParse(years[0]) ?? startYear;
    }
    int endYear = startYear + 1;
    if (years.length > 1) {
      endYear = int.tryParse(years[1]) ?? endYear;
    }

    if (semName.contains('1')) {
      return DateTime(endYear, 1, 15);
    } else if (semName.contains('2')) {
      return DateTime(endYear, 6, 30);
    } else if (semName.contains('3') || semName.toLowerCase().contains('he') || semName.toLowerCase().contains('hè')) {
      return DateTime(endYear, 8, 15);
    }
    return DateTime(endYear, 2, 28);
  }
  void resetToToday() {
    final today = _normalizeDate(DateTime.now());
    final safeToday = clampToCalendarRange(today);

    selectedDay.value = safeToday;
    focusedDay.value = safeToday;

    _logScheduleRange('reset-to-today');
    updateSelectedEvents();
  }
}

