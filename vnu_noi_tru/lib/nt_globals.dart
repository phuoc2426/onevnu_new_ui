import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_badge_plus/app_badge_plus.dart';  // ĐỔI import
import 'package:vnu_core/common/events.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_noi_tru/models/nt_danh_sach_menu_model.dart';
import 'package:vnu_noi_tru/repository/noitru_repository.dart';

class NtGlobals {
  String token = '';
  String fireBaseToken = '';
  int unreadCount = 0;

  NtDanhSachMenuModel? menuModel;
  int? menuIDChuyenMuc;
  String? menuNameChuyenMuc;

  StreamController<int> unreadCountStream = StreamController.broadcast();
  StreamController<NtDanhSachMenuModel?> menuStream =
  StreamController.broadcast();

  NtGlobals._internal();

  static final NtGlobals _singleton = NtGlobals._internal();
  factory NtGlobals() {
    return _singleton;
  }

  void fetchUnreadCount() {
    Future.delayed(Duration.zero, () async {
      try {
        var response = await NoiTruRepository().getThongBaoSoLuongChuaDoc();
        if (response.data.soLuongChuaDoc != null) {
          unreadCount = response.data.soLuongChuaDoc ?? 0;
          unreadCountStream.add(unreadCount);

          // ĐỔI: Sử dụng AppBadgePlus
          AppBadgePlus.updateBadge(unreadCount);
        }
      } catch (e) {
        logError(e.toString());
      }
    });
  }

  void fetchMenuList(VoidCallback complete) {
    Future.delayed(Duration.zero, () async {
      try {
        var response = await NoiTruRepository().getDanhSachMenu();
        if (response.resultCode == '0') {
          menuModel = response.data;
          // globalEvent.fire(FetchMenuSuccess());
          menuStream.add(menuModel);
        }
      } catch (e) {
        logError(e.toString());
      }
    });
  }

  clearSession() {
    token = '';
    // ĐỔI: Sử dụng AppBadgePlus
    AppBadgePlus.updateBadge(0);  // Hoặc dùng removeBadge()
  }
}