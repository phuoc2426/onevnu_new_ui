import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/hoc_ky_date_helper.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/repository/app_repository.dart';

import '../../../models/model.dart';
import 'package:vnu_core/extensions/extension_string.dart';
class VcoreTimeScheduleController extends GetxController {
  BuildContext? context;

  RxList<String> danhSachKieuTruong = RxList([]);
  Rxn<String> kieuTruong = Rxn();

  RxList<HocKyModel> danhSachHocKy = RxList([]);

  Rx<DateTime> selectedDate = DateTime.now().obs;
  Rx<DateTime> focusedDate = DateTime.now().obs;
  Rxn<HocKyModel> hocKy = Rxn();

  //For list data
  RxList<LichThiHocKyModel> lichThiHocKy = RxList([]);

  RxMap<String, List<LichThiHocKyModel>> mapLichThiHocKy = RxMap();

  RxBool isTheoChuongTrinhDaoTao = true.obs;

  RefreshController refreshController = RefreshController();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
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
    hocKy.value = null;
    try {
      Utils.showProgress(context);
      var response = await ApiRepository().getDanhSachHocKyTheoLichThi(
          isTheoChuongTrinhDaoTao.value, kieuTruong.value ?? '');
      Utils.dismissProgress(context);

      danhSachHocKy.value = response;
      if (danhSachHocKy.isNotEmpty) {
        hocKy.value = _findDefaultHocKy();
      }

      selectedDate.value = DateTime.now();
      focusedDate.value = DateTime.now();

      refreshData();
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }

  HocKyModel _findDefaultHocKy() {
    final now = DateTime.now();
    final currentYear = now.year;
    final today = DateTime(now.year, now.month, now.day);

    final byDateRange = HocKyDateHelper.findContaining(danhSachHocKy, today);
    if (byDateRange != null) {
      return byDateRange;
    }

    // Ưu tiên học kỳ có năm bắt đầu trùng năm hiện tại.
    // Ví dụ: "2026-2027" => lấy 2026.
    final byCurrentStartYear = danhSachHocKy.firstWhereOrNull((hk) {
      final startYear = HocKyDateHelper.extractStartYear(hk.nam);
      return startYear == currentYear;
    });

    if (byCurrentStartYear != null) {
      return byCurrentStartYear;
    }

    // Nếu không có, chọn học kỳ gần năm hiện tại nhất.
    final sorted = danhSachHocKy.toList()
      ..sort((a, b) {
        final yearA = HocKyDateHelper.extractStartYear(a.nam) ?? 0;
        final yearB = HocKyDateHelper.extractStartYear(b.nam) ?? 0;

        final diffA = (yearA - currentYear).abs();
        final diffB = (yearB - currentYear).abs();

        return diffA.compareTo(diffB);
      });

    return sorted.first;
  }

  // ignore: unused_element
  int? _extractStartYear(String? nam) {
    if (nam == null || nam.trim().isEmpty) return null;

    final text = nam.trim();

    // Trường hợp "2026-2027"
    final match = RegExp(r'\d{4}').firstMatch(text);
    if (match == null) return null;

    return int.tryParse(match.group(0)!);
  }

  Future<void> changeKieuTruong(String? displayName) async {
    final selected = danhSachKieuTruong.firstWhereOrNull(
          (e) => e.toDisplayName() == displayName,
    );

    if (selected == null) return;
    if (selected == kieuTruong.value) return;

    kieuTruong.value = selected;

    hocKy.value = null;
    danhSachHocKy.clear();

    lichThiHocKy.clear();
    mapLichThiHocKy.clear();

    selectedDate.value = DateTime.now();
    focusedDate.value = DateTime.now();

    await getDanhSachHocKy();
  }

  changeHocKy(String? displayName) {
    HocKyModel? obj = danhSachHocKy.firstWhereOrNull(
        (element) => element.disPlayName() == (displayName ?? "_///_"));
    if (obj != null) {
      hocKy.value = obj;
      refreshData();
    }
  }

  refreshData() {
    _loadData();
  }

  loadMoreData() {
    _loadData();
  }
  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      final parts = value.trim().split('/');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }
  _loadData() async {
    lichThiHocKy.value = [];
    mapLichThiHocKy.clear();

    try {
      Utils.showProgress(context);

      final response = await ApiRepository().getLichThiHocKy(
        hocKy.value?.id ?? '',
        kieuTruong.value ?? '',
      );

      lichThiHocKy.value = response;

      // Convert to Map ngayThi - List<>
      final Map<String, List<LichThiHocKyModel>> dict = {};

      for (final item in response) {
        final ngayThi = item.ngayThi;

        if (ngayThi == null || ngayThi.trim().isEmpty) continue;

        if (dict.containsKey(ngayThi)) {
          dict[ngayThi]!.add(item);
        } else {
          dict[ngayThi] = [item];
        }
      }

      // Sort ngày thi tăng dần theo dd/MM/yyyy
      final sortedKeys = dict.keys.toList()
        ..sort((a, b) {
          final dateA = _parseDate(a);
          final dateB = _parseDate(b);

          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;

          return dateA.compareTo(dateB);
        });

      final sortedDict = <String, List<LichThiHocKyModel>>{};

      for (final key in sortedKeys) {
        final exams = dict[key] ?? [];

        exams.sort((a, b) {
          final timeA = a.gioBatDauThi ?? '';
          final timeB = b.gioBatDauThi ?? '';
          return timeA.compareTo(timeB);
        });

        sortedDict[key] = exams;
      }

      mapLichThiHocKy.value = sortedDict;

      refreshController.refreshCompleted();
      refreshController.loadComplete();
      Utils.dismissProgress(context);
    } catch (e) {
      snackBarError(e.toString());
      refreshController.refreshCompleted();

      Utils.dismissProgress(context);
      refreshController.loadComplete();
    }
  }
}
