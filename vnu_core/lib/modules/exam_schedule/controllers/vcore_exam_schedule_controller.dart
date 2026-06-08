import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
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
  bool skipAutoSelectNearest = false;

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

  bool _hasSelectedNearestDate = false;
  DateTime? pendingInitialDate;
  bool _isInitialDateSet = false;

  void setInitialDate(DateTime date) {
    if (_isInitialDateSet) return;
    _isInitialDateSet = true;
    final normalized = DateTime(date.year, date.month, date.day);
    pendingInitialDate = normalized;
    selectedDay.value = normalized;
    focusedDay.value = normalized;
    skipAutoSelectNearest = true;
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

  getDanhSachKieuTruong() async {
    kieuTruong.value = null;
    try {
      Utils.showProgress(context);
      var response = await ApiRepository().getDanhSachKieuTruong();
      Utils.dismissProgress(context);

      danhSachKieuTruong.value = response;
      if (danhSachKieuTruong.isNotEmpty) {
        kieuTruong.value = danhSachKieuTruong.firstWhereOrNull((obj) {
          return obj == "TruongChinh";
        }) ??
            danhSachKieuTruong.first;
        getDanhSachHocKy();
      }
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }

  getDanhSachHocKy() async {
    danhSachHocKy.value = [];
    danhSachNamHoc.value = [];
    danhSachHocKyFilter.value = [];
    namHocSelected.value = null;
    hocKySelected.value = null;
    _hasSelectedNearestDate = false;

    try {
      Utils.showProgress(context);
      var response = await ApiRepository().getDanhSachHocKyTheoThoiKhoaBieu(
          isTheoChuongTrinhDaoTao.value, kieuTruong.value ?? '');
      Utils.dismissProgress(context);

      danhSachHocKy.value = response;
      if (danhSachHocKy.isNotEmpty) {
        // Extract unique academic years in descending order (newest first)
        final years = response
            .map((e) => e.nam)
            .whereType<String>()
            .toSet()
            .toList();
        years.sort((a, b) => b.compareTo(a));
        danhSachNamHoc.value = years;

        // Try to find the semester containing target date (pendingInitialDate or today)
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final targetDate = pendingInitialDate ?? today;
        HocKyModel? currentSem;

        for (var sem in response) {
          final start = _inferSemesterStartDate(sem);
          final end = _inferSemesterEndDate(sem);
          if ((targetDate.isAfter(start) || targetDate.isAtSameMomentAs(start)) &&
              (targetDate.isBefore(end) || targetDate.isAtSameMomentAs(end))) {
            currentSem = sem;
            break;
          }
        }

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
        } else {
          if (danhSachNamHoc.isNotEmpty) {
            selectYear(danhSachNamHoc.first);
          }
        }
      }
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }

  void selectYear(String year) {
    namHocSelected.value = year;
    // Filter semesters for the selected year
    final sems = danhSachHocKy.where((e) => e.nam == year).toList();
    // Sort semesters by ten (Semester 1, Semester 2, etc.)
    sems.sort((a, b) {
      final tA = a.ten ?? '';
      final tB = b.ten ?? '';
      return tA.compareTo(tB);
    });
    danhSachHocKyFilter.value = sems;

    if (danhSachHocKyFilter.isNotEmpty) {
      selectSemester(danhSachHocKyFilter.first);
    } else {
      hocKySelected.value = null;
      eventsMap.clear();
      selectedEvents.clear();
    }
  }

  void selectSemester(HocKyModel sem) {
    hocKySelected.value = sem;
    _hasSelectedNearestDate = false;

    // Jump calendar view to target date or the start date of this semester
    final targetDate = pendingInitialDate ?? _inferSemesterStartDate(sem);
    focusedDay.value = targetDate;
    selectedDay.value = targetDate;

    refreshData();
  }

  refreshData() {
    _loadData();
  }

  _loadData() async {
    final sem = hocKySelected.value;
    if (sem == null) {
      refreshController.refreshCompleted();
      refreshController.loadComplete();
      return;
    }

    final hocKyId = sem.id ?? '';
    final kieuTruongVal = kieuTruong.value ?? '';

    // Cache-first: loading local data instantly
    isLoading.value = true;
    try {
      final cachedTkb = await VnuCacheFileManager().getCacheFile('tkb_$hocKyId.json');
      final cachedLichThi = await VnuCacheFileManager().getCacheFile('lichthi_$hocKyId.json');

      List<ThoiKhoaBieuModel> localTkb = [];
      List<LichThiHocKyModel> localLichThi = [];

      if (cachedTkb != null) {
        final decoded = json.decode(cachedTkb);
        if (decoded is List) {
          localTkb = decoded.map((e) => ThoiKhoaBieuModel.fromJson(e)).toList();
        }
      }
      if (cachedLichThi != null) {
        final decoded = json.decode(cachedLichThi);
        if (decoded is List) {
          localLichThi = decoded.map((e) => LichThiHocKyModel.fromJson(e)).toList();
        }
      }

      if (localTkb.isNotEmpty || localLichThi.isNotEmpty) {
        listThoiKhoaBieu.value = localTkb;
        listLichThi.value = localLichThi;
        _generateEventsMap(sem);
      }
    } catch (e) {
      debugPrint("Error loading from cache: $e");
    } finally {
      isLoading.value = false;
    }

    // Refresh from Network
    try {
      final results = await Future.wait([
        ApiRepository().getThoiKhoaBieuHocKy(hocKyId, kieuTruongVal),
        ApiRepository().getLichThiHocKy(hocKyId, kieuTruongVal),
      ]);

      final netTkb = results[0] as List<ThoiKhoaBieuModel>;
      final netLichThi = results[1] as List<LichThiHocKyModel>;

      listThoiKhoaBieu.value = netTkb;
      listLichThi.value = netLichThi;

      // Save to cache
      await VnuCacheFileManager().saveCacheFile(
        'tkb_$hocKyId.json',
        json.encode(netTkb.map((e) => e.toJson()).toList()),
      );
      await VnuCacheFileManager().saveCacheFile(
        'lichthi_$hocKyId.json',
        json.encode(netLichThi.map((e) => e.toJson()).toList()),
      );

      _generateEventsMap(sem);

      refreshController.refreshCompleted();
      refreshController.loadComplete();
    } catch (e) {
      debugPrint("Error fetching schedule from network: $e");
      refreshController.refreshFailed();
      if (listThoiKhoaBieu.isEmpty && listLichThi.isEmpty) {
        snackBarError(e.toString());
      }
    }
  }

  void _generateEventsMap(HocKyModel sem) {
    final Map<DateTime, List<ScheduleEvent>> tempMap = {};

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

    // 2. Map Lịch học (Class schedule) - Recurring weekly on weekdays in date range
    final startDate = _inferSemesterStartDate(sem);
    final endDate = _inferSemesterEndDate(sem);

    for (var classSession in listThoiKhoaBieu) {
      final ngayTrongTuanStr = classSession.ngayTrongTuan;
      if (ngayTrongTuanStr == null || ngayTrongTuanStr.isEmpty) continue;

      int? ngayTrongTuan = int.tryParse(ngayTrongTuanStr);
      if (ngayTrongTuan == null) continue;

      // Dart weekday representation: 1 = Monday, ..., 7 = Sunday
      // ngayTrongTuan mapping matches: '1' is Thứ 2 (Monday), ..., '7' is Chủ nhật (Sunday)
      int targetWeekday = ngayTrongTuan;

      for (var date = startDate; date.isBefore(endDate) || date.isAtSameMomentAs(endDate); date = date.add(const Duration(days: 1))) {
        if (date.weekday == targetWeekday) {
          final key = _normalizeDate(date);
          final event = ScheduleEvent(
            type: ScheduleType.classSession,
            title: classSession.tenHocPhan ?? 'Lịch học',
            date: date,
            startTime: classSession.tietBatDau != null ? 'Tiết ${classSession.tietBatDau}' : '',
            endTime: classSession.tietKetThuc != null ? 'Tiết ${classSession.tietKetThuc}' : '',
            location: '${classSession.tenPhong ?? ""} - ${classSession.diaChi ?? ""}',
            teacher: [
              classSession.giangVien1,
              classSession.giangVien2,
              classSession.giangVien3,
              classSession.giangVien4
            ].where((g) => g != null && g.isNotEmpty).join(', '),
            hocPhanCode: classSession.maHocPhan,
            soTinChi: classSession.soTinChi,
            nhom: classSession.nhom,
          );

          if (!tempMap.containsKey(key)) {
            tempMap[key] = [];
          }
          tempMap[key]!.add(event);
        }
      }
    }

    eventsMap.value = tempMap;
    if (pendingInitialDate != null) {
      selectedDay.value = pendingInitialDate!;
      focusedDay.value = pendingInitialDate!;
      pendingInitialDate = null;
    } else if (!skipAutoSelectNearest && !_hasSelectedNearestDate) {
      _selectNearestEventDate();
      _hasSelectedNearestDate = true;
    }
    updateSelectedEvents();
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
    return DateTime(date.year, date.month, date.day);
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
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    selectedDay.value = today;
    focusedDay.value = today;

    updateSelectedEvents();
  }
}
