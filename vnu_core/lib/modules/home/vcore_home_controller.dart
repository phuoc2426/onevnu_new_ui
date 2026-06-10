import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/common/gpa_cache_manager.dart';

import 'package:vnu_core/globals.dart';
import 'package:vnu_core/extensions/map_ext.dart';

import 'package:vnu_core/repository/app_repository.dart';
import 'package:intl/intl.dart';

import '../../models/model.dart';
import 'package:vnu_core/modules/browser/views/vcore_browser_view.dart';

const kCacheKeyListNguonTin = 'listNguonTin.json';
const kCacheKeyListTinTuc = 'listTinTuc.json';
const kCacheKeyListLienKetDanhDau = 'listLienKetDanhDau.json';
const kCacheKeyListThongBaoDaoTao = 'listThongBaoDaoTao.json';
const kCacheKeyListTop10ThongBao = 'listTop10ThongBao.json';

const kCacheKeyListTinTucBySchool = 'listTinTucBySchool.json';
class HomeClassScheduleItem {
  final ThoiKhoaBieuModel data;
  final DateTime date;

  HomeClassScheduleItem({
    required this.data,
    required this.date,
  });

  String get ngayHocText {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String get ngayHocShortText {
    return DateFormat('dd/MM').format(date);
  }
}

class VcoreHomeController extends GetxController {
  BuildContext? context;

  RxList<NguonTinModel> listNguonTin = RxList([]);
  RxList<TopTinTucModel> listTinTuc = RxList([]);
  RxList<TinTucModel> listTinTuc2 = RxList([]);
  RxList<TopTinTucModel> listTinTucBySchool = RxList([]);
  RxList<LienKetDanhDauModel> listLienKetDanhDau = RxList([]);

  RxList<ThongBaoDaoTaoModel> listThongBaoDaoTao = RxList([]);
  RxList<TopThongBaoModel> listTop10ThongBao = RxList([]);
  RxList<StudentInfoModel> listStudentInfo = RxList([]);

  // ── GPA & Schedule data ──
  Rxn<TongKetDenHienTaiModel> tongKetModel = Rxn();
  RxList<ThoiKhoaBieuModel> listThoiKhoaBieu = RxList([]);
  RxList<LichThiHocKyModel> listLichThi = RxList([]);
  HocKyModel? currentThoiKhoaBieuHocKy;
  HocKyModel? currentLichThiHocKy;
  RxBool isLoadingSchedule = false.obs;

  RxInt unreadSystemCount = 0.obs;
  RxInt unreadTrainingCount = 0.obs;

  @override
  void onInit() {
    super.onInit();

    getCacheAllData();

    Future.delayed(Duration.zero, () {
      getAllData();
    });

    Globals().unreadCountStream.stream.listen((count) {
      unreadSystemCount.value = count;
    });
  }

  getCacheAllData() {
    // Tin tuc
    VnuCacheFileManager().getCacheFile(kCacheKeyListTinTuc).then(
      (data) {
        try {
          var dataString = data ?? '';
          if (dataString.isEmpty) {
            return;
          }
          var dataJson = jsonDecode(dataString) as List;
          List<TopTinTucModel> listObj = [];
          for (var element in dataJson) {
            try {
              TopTinTucModel? model;
              if (element is Map<String, dynamic>) {
                model = TopTinTucModel.fromJson(element);
              } else if (element is Map<dynamic, dynamic>) {
                model = TopTinTucModel.fromJson(element.toStringDynamic());
              }
              if (model != null) {
                listObj.add(model);
              }
            } catch (e) {
              logError(e.toString());
            }
          }
          // Api gọi chưa xong thì update trước.
          if (listTinTuc.isEmpty) {
            listTinTuc.value = listObj;
          }
        } catch (e) {
          logError(e.toString());
        }
      },
    );
    // {phuoc} Tin tức theo trường
    VnuCacheFileManager().getCacheFile(kCacheKeyListTinTucBySchool).then(
      (data) async {
        try {
          var dataString = data ?? '';
          if (dataString.isEmpty) {
            return;
          }
          // Dữ liệu có sẵn trong cache, giải mã và chuyển thành List
          var dataJson = jsonDecode(dataString);

          // Lấy giá trị guild và data từ cache
          String guild = dataJson['guild'];
          List<TopTinTucModel> listObj = [];

          if (dataJson['data'] != null) {
            for (var element in dataJson['data']) {
              try {
                TopTinTucModel? model;
                if (element is Map<String, dynamic>) {
                  model = TopTinTucModel.fromJson(element);
                } else if (element is Map<dynamic, dynamic>) {
                  model = TopTinTucModel.fromJson(element.toStringDynamic());
                }
                if (model != null) {
                  listObj.add(model);
                }
              } catch (e) {
                logError(e.toString());
              }
            }
          }

          // Nếu không có dữ liệu trong danh sách, không cần cập nhật
          if (listTinTucBySchool.isEmpty && listObj.isNotEmpty) {
            listTinTucBySchool.value = listObj;
          }
        } catch (e) {
          logError(e.toString());
        }
      },
    );

    // Top 10 thong bao
    VnuCacheFileManager().getCacheFile(kCacheKeyListTop10ThongBao).then(
      (data) {
        try {
          var dataString = data ?? '';
          if (dataString.isEmpty) {
            return;
          }
          var dataJson = jsonDecode(dataString) as List;
          List<TopThongBaoModel> listObj = [];
          for (var element in dataJson) {
            try {
              TopThongBaoModel? model;
              if (element is Map<String, dynamic>) {
                model = TopThongBaoModel.fromJson(element);
              } else if (element is Map<dynamic, dynamic>) {
                model = TopThongBaoModel.fromJson(element.toStringDynamic());
              }
              if (model != null) {
                listObj.add(model);
              }
            } catch (e) {
              logError(e.toString());
            }
          }
          // Api gọi chưa xong thì update trước.
          if (listTop10ThongBao.isEmpty) {
            listTop10ThongBao.value = listObj;
          }
        } catch (e) {
          logError(e.toString());
        }
      },
    );

    // Thong Bao Dao Tao
    VnuCacheFileManager().getCacheFile(kCacheKeyListThongBaoDaoTao).then(
      (data) {
        try {
          var dataString = data ?? '';
          if (dataString.isEmpty) {
            return;
          }
          var dataJson = jsonDecode(dataString) as List;
          List<ThongBaoDaoTaoModel> listObj = [];
          for (var element in dataJson) {
            try {
              ThongBaoDaoTaoModel? model;
              if (element is Map<String, dynamic>) {
                model = ThongBaoDaoTaoModel.fromJson(element);
              } else if (element is Map<dynamic, dynamic>) {
                model = ThongBaoDaoTaoModel.fromJson(element.toStringDynamic());
              }
              if (model != null) {
                listObj.add(model);
              }
            } catch (e) {
              logError(e.toString());
            }
          }
          // Api gọi chưa xong thì update trước.
          if (listThongBaoDaoTao.isEmpty) {
            listThongBaoDaoTao.value = listObj;
            updateUnreadCounts();
          }
        } catch (e) {
          logError(e.toString());
        }
      },
    );

    // Lien ket danh dau
    VnuCacheFileManager().getCacheFile(kCacheKeyListLienKetDanhDau).then(
      (data) {
        try {
          var dataString = data ?? '';
          if (dataString.isEmpty) {
            return;
          }
          var dataJson = jsonDecode(dataString) as List;
          List<LienKetDanhDauModel> listObj = [];
          for (var element in dataJson) {
            try {
              LienKetDanhDauModel? model;
              if (element is Map<String, dynamic>) {
                model = LienKetDanhDauModel.fromJson(element);
              } else if (element is Map<dynamic, dynamic>) {
                model = LienKetDanhDauModel.fromJson(element.toStringDynamic());
              }
              if (model != null) {
                listObj.add(model);
              }
            } catch (e) {
              logError(e.toString());
            }
          }
          // Api gọi chưa xong thì update trước.
          if (listLienKetDanhDau.isEmpty) {
            listLienKetDanhDau.value = listObj;
          }
        } catch (e) {
          logError(e.toString());
        }
      },
    );

    // List nguon tin
    VnuCacheFileManager().getCacheFile(kCacheKeyListNguonTin).then(
      (data) {
        try {
          var dataString = data ?? '';
          if (dataString.isEmpty) {
            return;
          }
          var dataJson = jsonDecode(dataString) as List;
          List<NguonTinModel> listObj = [];
          for (var element in dataJson) {
            try {
              NguonTinModel? model;
              if (element is Map<String, dynamic>) {
                model = NguonTinModel.fromJson(element);
              } else if (element is Map<dynamic, dynamic>) {
                model = NguonTinModel.fromJson(element.toStringDynamic());
              }
              if (model != null) {
                listObj.add(model);
              }
            } catch (e) {
              logError(e.toString());
            }
          }
          // Api gọi chưa xong thì update trước.
          if (listNguonTin.isEmpty) {
            listNguonTin.value = listObj;
          }
        } catch (e) {
          logError(e.toString());
        }
      },
    );
  }

  getAllData() {
    getTinTuc();
    getTinTucBySchool();

    getTop10ThongBao();

    getThongBaoDaoTao();

    getNguonTin();

    // Fetch GPA & Schedule for home header
    fetchTongKetDenHienTai();
    fetchScheduleData();
    GpaCacheManager.calculateAndCacheGpa();

    //Get from build
    //getLienKetDanhDau();
    
    updateUnreadCounts();
  }

  // ── GPA ──
  fetchTongKetDenHienTai() async {
    try {
      var response = await ApiRepository().getTongKetDenHienTai();
      if (response.isNotEmpty) {
        tongKetModel.value = response.first;
      }
    } catch (e) {
      logError('fetchTongKetDenHienTai: ${e.toString()}');
    }
  }

  /// Get rank image asset path based on GPA (4-point scale)
  String getRankImageAsset() {
    final gpaStr = tongKetModel.value?.diemTrungBinhHe4TichLuy;
    if (gpaStr == null || gpaStr.isEmpty) return 'assets/images/rank_F.png';
    final gpa = double.tryParse(gpaStr) ?? 0.0;
    if (gpa >= 3.8) return 'assets/images/rank_A_plus.png';
    if (gpa >= 3.5) return 'assets/images/rank_A.png';
    if (gpa >= 3.2) return 'assets/images/rank_B_plus.png';
    if (gpa >= 2.8) return 'assets/images/rank_B.png';
    if (gpa >= 2.5) return 'assets/images/rank_C_plus.png';
    if (gpa >= 2.0) return 'assets/images/rank_C.png';
    if (gpa >= 1.0) return 'assets/images/rank_D.png';
    return 'assets/images/rank_F.png';
  }

  // ── Schedule ──
  fetchScheduleData() async {
    isLoadingSchedule.value = true;
    try {
      // Get kieuTruong
      var kieuTruongList = await ApiRepository().getDanhSachKieuTruong();
      String kieuTruong =
          kieuTruongList.firstWhereOrNull((obj) => obj == 'TruongChinh') ??
              (kieuTruongList.isNotEmpty ? kieuTruongList.first : '');

      // Fetch class schedule semesters & pick the semester containing today.
      try {
        var hocKyListTKB = await ApiRepository()
            .getDanhSachHocKyTheoThoiKhoaBieu(true, kieuTruong);
        final hocKyTKB = _selectCurrentSemester(hocKyListTKB);
        currentThoiKhoaBieuHocKy = hocKyTKB;

        if (hocKyTKB != null) {
          var tkbResponse = await ApiRepository()
              .getThoiKhoaBieuHocKy(hocKyTKB.id ?? '', kieuTruong);
          listThoiKhoaBieu.value = tkbResponse;
        } else {
          listThoiKhoaBieu.clear();
        }
      } catch (e) {
        logError('fetchThoiKhoaBieu: ${e.toString()}');
      }

      // Fetch exam schedule semesters & pick the semester containing today.
      try {
        var hocKyListLT =
            await ApiRepository().getDanhSachHocKyTheoLichThi(true, kieuTruong);
        final hocKyLT = _selectCurrentSemester(hocKyListLT);
        currentLichThiHocKy = hocKyLT;

        if (hocKyLT != null) {
          var ltResponse = await ApiRepository()
              .getLichThiHocKy(hocKyLT.id ?? '', kieuTruong);
          listLichThi.value = ltResponse;
        } else {
          listLichThi.clear();
        }
      } catch (e) {
        logError('fetchLichThi: ${e.toString()}');
      }
    } catch (e) {
      logError('fetchScheduleData: ${e.toString()}');
    }
    isLoadingSchedule.value = false;
  }

  HocKyModel? _selectCurrentSemester(List<HocKyModel> semesters) {
    if (semesters.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final semester in semesters) {
      final start = _inferSemesterStartDate(semester);
      final end = _inferSemesterEndDate(semester);
      final inRange = (today.isAfter(start) || today.isAtSameMomentAs(start)) &&
          (today.isBefore(end) || today.isAtSameMomentAs(end));
      if (inRange) return semester;
    }

    return semesters.first;
  }

  DateTime _inferSemesterStartDate(HocKyModel semester) {
    final yearStr = semester.nam ?? '';
    final semName = semester.ten ?? '';
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
    } else if (semName.contains('3') ||
        semName.toLowerCase().contains('he') ||
        semName.toLowerCase().contains('hè')) {
      return DateTime(endYear, 7, 1);
    }
    return DateTime(startYear, 9, 1);
  }

  DateTime _inferSemesterEndDate(HocKyModel semester) {
    final yearStr = semester.nam ?? '';
    final semName = semester.ten ?? '';
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
    } else if (semName.contains('3') ||
        semName.toLowerCase().contains('he') ||
        semName.toLowerCase().contains('hè')) {
      return DateTime(endYear, 8, 15);
    }
    return DateTime(endYear, 2, 28);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateToApiFormat(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  DateTime? _parseNgayHoc(String? ngayHoc) {
    if (ngayHoc == null || ngayHoc.trim().isEmpty) return null;

    try {
      return DateFormat('dd/MM/yyyy').parseStrict(ngayHoc.trim());
    } catch (_) {
      return null;
    }
  }
  /// Get today's day-of-week string for ThoiKhoaBieuModel (1=Mon...7=Sun)
  String _getTodayDayOfWeek() {
    int weekday = DateTime.now().weekday; // 1=Mon...7=Sun
    if (weekday == 7) return '7'; // Chủ nhật
    return (weekday).toString(); // 1=Thứ 2, 2=Thứ 3...
  }

  /// Get class schedule for a specific day of week
  List<ThoiKhoaBieuModel> getClassScheduleForDay(String dayOfWeek) {
    return listThoiKhoaBieu
        .where((item) => item.ngayTrongTuan == dayOfWeek)
        .toList()
      ..sort((a, b) => (int.tryParse(a.tietBatDau ?? '0') ?? 0)
          .compareTo(int.tryParse(b.tietBatDau ?? '0') ?? 0));
  }
  List<HomeClassScheduleItem> _getClassScheduleForDate(DateTime date) {
    final targetDate = _dateOnly(date);

    if (!_isDateInCurrentThoiKhoaBieuSemester(targetDate)) {
      return [];
    }

    final dayOfWeek = targetDate.weekday.toString();

    final items = getClassScheduleForDay(dayOfWeek);

    return items
        .map(
          (item) => HomeClassScheduleItem(
        data: item,
        date: targetDate,
      ),
    )
        .toList()
      ..sort((a, b) {
        final tietA = int.tryParse(a.data.tietBatDau ?? '') ?? 999;
        final tietB = int.tryParse(b.data.tietBatDau ?? '') ?? 999;
        return tietA.compareTo(tietB);
      });
  }

  bool _isDateInCurrentThoiKhoaBieuSemester(DateTime date) {
    final semester = currentThoiKhoaBieuHocKy;

    if (semester == null) {
      return true;
    }

    final start = _dateOnly(_inferSemesterStartDate(semester));
    final end = _dateOnly(_inferSemesterEndDate(semester));
    final target = _dateOnly(date);

    return !target.isBefore(start) && !target.isAfter(end);
  }
  /// Parse ngayThi string (dd/MM/yyyy) to DateTime
  DateTime? _parseNgayThi(String? ngayThi) {
    if (ngayThi == null || ngayThi.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parse(ngayThi);
    } catch (e) {
      return null;
    }
  }

  /// Get exam schedule for a specific date (format dd/MM/yyyy)
  List<LichThiHocKyModel> getExamScheduleForDate(String dateStr) {
    return listLichThi.where((item) => item.ngayThi == dateStr).toList()
      ..sort((a, b) => (a.gioBatDauThi ?? '').compareTo(b.gioBatDauThi ?? ''));
  }

  /// Get today's class schedule
  List<HomeClassScheduleItem> getTodayClassSchedule() {
    return _getClassScheduleForDate(DateTime.now());
  }
  /// Get class schedule from today through the next [days] days.
  List<HomeClassScheduleItem> getUpcomingClassSchedule({int days = 7}) {
    final result = <HomeClassScheduleItem>[];
    final today = _dateOnly(DateTime.now());

    for (var offset = 0; offset < days; offset++) {
      final date = today.add(Duration(days: offset));
      result.addAll(_getClassScheduleForDate(date));
    }

    result.sort((a, b) {
      final cmpDate = a.date.compareTo(b.date);
      if (cmpDate != 0) return cmpDate;

      final tietA = int.tryParse(a.data.tietBatDau ?? '') ?? 999;
      final tietB = int.tryParse(b.data.tietBatDau ?? '') ?? 999;

      return tietA.compareTo(tietB);
    });

    return result;
  }

  /// Get today's exam schedule
  List<LichThiHocKyModel> getTodayExamSchedule() {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    return getExamScheduleForDate(today);
  }

  /// Get exam schedule from today through the next [days] days.
  List<LichThiHocKyModel> getUpcomingExamSchedule({int days = 7}) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final endExclusive = todayStart.add(Duration(days: days));

    return listLichThi.where((item) {
      final date = _parseNgayThi(item.ngayThi);
      return date != null &&
          !date.isBefore(todayStart) &&
          date.isBefore(endExclusive);
    }).toList()
      ..sort((a, b) {
        final dateA = _parseNgayThi(a.ngayThi) ?? DateTime(2099);
        final dateB = _parseNgayThi(b.ngayThi) ?? DateTime(2099);
        final cmp = dateA.compareTo(dateB);
        if (cmp != 0) return cmp;
        return (a.gioBatDauThi ?? '').compareTo(b.gioBatDauThi ?? '');
      });
  }

  /// Get next day's class schedule
  List<ThoiKhoaBieuModel> getNextDayClassSchedule() {
    int nextWeekday = DateTime.now().weekday + 1;
    if (nextWeekday > 7) nextWeekday = 1;
    if (nextWeekday == 7) return getClassScheduleForDay('7');
    return getClassScheduleForDay(nextWeekday.toString());
  }

  /// Get next day's exam schedule
  List<LichThiHocKyModel> getNextDayExamSchedule() {
    final tomorrow = DateFormat('dd/MM/yyyy')
        .format(DateTime.now().add(const Duration(days: 1)));
    return getExamScheduleForDate(tomorrow);
  }

  /// Get upcoming exams (from today onwards), sorted by date
  List<LichThiHocKyModel> getUpcomingExams() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return listLichThi.where((item) {
      final date = _parseNgayThi(item.ngayThi);
      return date != null && !date.isBefore(todayStart);
    }).toList()
      ..sort((a, b) {
        final dateA = _parseNgayThi(a.ngayThi) ?? DateTime(2099);
        final dateB = _parseNgayThi(b.ngayThi) ?? DateTime(2099);
        final cmp = dateA.compareTo(dateB);
        if (cmp != 0) return cmp;
        return (a.gioBatDauThi ?? '').compareTo(b.gioBatDauThi ?? '');
      });
  }



  /// Get count of upcoming exams
  int getUpcomingExamCount() => getUpcomingExamSchedule(days: 7).length;
  /// Total subjects today (class + exam)
  int getTodayTotalSubjects() {
    return getTodayClassSchedule().length + getTodayExamSchedule().length;
  }

  /// Total subjects next day (class + exam)
  int getNextDayTotalSubjects() {
    return getNextDayClassSchedule().length + getNextDayExamSchedule().length;
  }

  getNguonTin() async {
    try {
      var response = await ApiRepository().getNguonTin(1, 99, 'created,desc');
      final tinTucList = (response.data ?? []).toList();
      tinTucList.sort((a, b) => b.thuTu.compareTo(a.thuTu));
      listNguonTin.value = tinTucList;
      if (tinTucList.isNotEmpty) {
        try {
          var data = tinTucList.map((e) => e.toJson()).toList();
          VnuCacheFileManager()
              .saveCacheFile(kCacheKeyListNguonTin, jsonEncode(data));
        } catch (e) {
          logError(e.toString());
        }
      } else {
        VnuCacheFileManager().deleteCacheFile(kCacheKeyListNguonTin);
      }
    } catch (e) {
      logError(e.toString());
      snackBarError(e.toString());
    }
  }

  getTinTuc() async {
    try {
      var response = await ApiRepository().getTop10TinTuc(220, 220);
      listTinTuc.value = response;
      if (listTinTuc.isNotEmpty) {
        try {
          var data = listTinTuc.map((e) => e.toJson()).toList();
          VnuCacheFileManager()
              .saveCacheFile(kCacheKeyListTinTuc, jsonEncode(data));
        } catch (e) {
          logError(e.toString());
        }
      } else {
        VnuCacheFileManager().deleteCacheFile(kCacheKeyListTinTuc);
      }
    } catch (e) {
      logError(e.toString());
      snackBarError(e.toString());
    }
  }

  getTinTucBySchool() async {
    try {
      var currentUser = await ApiRepository().getCurrentUser();
      String guildDonVi = currentUser.guidDonVi.toString();
      var donVi = await ApiRepository().getDonVi(guildDonVi);
      // String tenDonVi ="Trường Đại học Khoa học Xã hội và Nhân văn";
      String tenDonVi = donVi.tenDonVi.toString();
      var response =
          await ApiRepository().getTinTuc(1, 50, "", "", "", "", "", "");
      if (response.data != null && response.data!.isNotEmpty) {
        List<TinTucModel> filteredData = response.data!.where((e) {
          return e.donViXuatBan != null && e.donViXuatBan!.contains(tenDonVi);
        }).toList();
        listTinTuc2.value = filteredData ?? [];

        if (filteredData.isNotEmpty) {
          List<TopTinTucModel> listTopTinTuc = filteredData.map((e) {
            return TopTinTucModel(
              id: e.guid,
              anhDaiDien: e.guidFileAnhDaiDiens?.first,
              tieuDe: e.tieuDe,
              tomTat: e.htmlNoiDungTinBai,
            );
          }).toList();

          listTinTucBySchool.value = listTopTinTuc;

          try {
            // Chuyển dữ liệu thành dạng JSON để lưu vào cache
            var data = listTopTinTuc.map((e) => e.toJson()).toList();

            // Lưu vào cache với key kCacheKeyListTinTucBySchool
            await VnuCacheFileManager().saveCacheFile(
                kCacheKeyListTinTucBySchool,
                jsonEncode({
                  "guild": tenDonVi,
                  "data": data,
                }));

            print("{phuoc} Dữ liệu tin tức đã được lưu vào cache.");
          } catch (e) {
            logError(e.toString());
          }
        } else {
          // Nếu không có dữ liệu sau khi lọc, xóa cache
          VnuCacheFileManager().deleteCacheFile(kCacheKeyListTinTucBySchool);
        }
      } else {
        // Xóa cache nếu không có dữ liệu
        VnuCacheFileManager().deleteCacheFile(kCacheKeyListTinTucBySchool);
      }
    } catch (e) {
      logError(e.toString());
      snackBarError(e.toString());
    }
  }

  getLienKetDanhDau() async {
    try {
      var response =
          await ApiRepository().getLienKetDanhDau(1, 4, 'created,desc', '');
      listLienKetDanhDau.value = response.data ?? [];

      if (listLienKetDanhDau.isNotEmpty) {
        try {
          var data = listLienKetDanhDau.map((e) => e.toJson()).toList();
          VnuCacheFileManager()
              .saveCacheFile(kCacheKeyListLienKetDanhDau, jsonEncode(data));
        } catch (e) {
          logError(e.toString());
        }
      } else {
        VnuCacheFileManager().deleteCacheFile(kCacheKeyListLienKetDanhDau);
      }
    } catch (e) {
      logError(e.toString());
      snackBarError(e.toString());
    }
  }

  getTop10ThongBao() async {
    try {
      var response = await ApiRepository().getTop10ThongBao();
      listTop10ThongBao.value = response;
      if (listTop10ThongBao.isNotEmpty) {
        try {
          var data = listTop10ThongBao.map((e) => e.toJson()).toList();
          VnuCacheFileManager()
              .saveCacheFile(kCacheKeyListTop10ThongBao, jsonEncode(data));
        } catch (e) {
          logError(e.toString());
        }
      } else {
        VnuCacheFileManager().deleteCacheFile(kCacheKeyListTop10ThongBao);
      }
    } catch (e) {
      logError(e.toString());
      snackBarError(e.toString());
    }
  }

  getThongBaoDaoTao() async {
    List<ThongBaoDaoTaoModel> listObj = [];
    try {
      var response = await ApiRepository().getThongBaoDaoTao('TruongChinh');
      listObj.add(response);
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getThongBaoDaoTao('BangKep');
      listObj.add(response);
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getThongBaoDaoTao('TruongGui');
      listObj.add(response);
    } catch (e) {
      logError(e.toString());
    }

    listThongBaoDaoTao.value = listObj;

    if (listThongBaoDaoTao.isNotEmpty) {
      try {
        var data = listThongBaoDaoTao.map((e) => e.toJson()).toList();
        VnuCacheFileManager()
            .saveCacheFile(kCacheKeyListThongBaoDaoTao, jsonEncode(data));
      } catch (e) {
        logError(e.toString());
      }
    } else {
      VnuCacheFileManager().deleteCacheFile(kCacheKeyListThongBaoDaoTao);
    }
    updateUnreadCounts();
  }

  // viewDetailTopTinTucModel(TopTinTucModel tintuc) async {
  //   if (tintuc.id == null || (tintuc.id ?? '').isEmpty) {
  //     return;
  //   }
  //   Utils.showProgress(context);
  //   try {
  //     var response = await ApiRepository().getChiTietCmsTinTuc(
  //         tintuc.id ?? '', kImageCmsWidhtHeight, kImageCmsWidhtHeight);
  //     logWarning(response.noiDung ?? '');
  //     Utils.dismissProgress(context);
  //
  //     Get.to(
  //           () => VcoreHtmlView(
  //           title: tintuc.tieuDe ?? '', html: response.noiDung ?? ''),
  //     );
  //   } catch (e) {
  //     Utils.dismissProgress(context);
  //     logError(e.toString());
  //     snackBarError(e.toString());
  //   }
  // }

  viewDetailTopTinTucModel(TopTinTucModel tintuc) {
    final url = tintuc.redirectUrl;
    if (url == null || url.isEmpty) {
      snackBarError('Không có đường dẫn để mở chi tiết');
      return;
    }
    Get.to(() => VcoreBrowserView(
          title: tintuc.tieuDe ?? 'Chi tiết',
          url: url,
        ));
  }

  viewDetailTopThongBaoModel(TopThongBaoModel thongbao) {
    // Nếu có redirectUrl, mở bằng VcoreBrowserView trong app
    final url = thongbao.redirectUrl;
    if (url != null && url.isNotEmpty) {
      Get.to(() => VcoreBrowserView(
            title: thongbao.tieuDe ?? 'Chi tiết',
            url: url,
          ));
    } else {
      snackBarError('Link không hợp lệ hoặc rỗng');
    }
  }

  Future<void> updateUnreadCounts() async {
    try {
      final sysCount = await ApiRepository().getNotificationCount(isRead: false);
      unreadSystemCount.value = sysCount;
    } catch (e) {
      logError("Home update system unread count error: $e");
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = Globals().usernameLogin;
      final key = "read_daotao_notifications_$username";
      final readIds = prefs.getStringList(key)?.toSet() ?? {};
      
      int unread = 0;
      for (var item in listThongBaoDaoTao) {
        if (item.tieuDe?.isNotEmpty == true) {
          final id = "${item.tieuDe ?? ''}_${item.noiDung?.hashCode ?? 0}";
          if (!readIds.contains(id)) {
            unread++;
          }
        }
      }
      unreadTrainingCount.value = unread;
    } catch (e) {
      logError("Home update training unread count error: $e");
    }
  }
}
