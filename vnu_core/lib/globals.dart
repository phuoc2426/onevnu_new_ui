import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:vnu_core/common/events.dart';
import 'package:vnu_core/common/file_utils.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/services_url.dart';

import 'package:shared_preferences/shared_preferences.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class Globals {
  String token = '';
  String refreshToken = '';

  String usernameLogin = '';

  Rxn<StudentInfoModel> thongTinSinhVienModel = Rxn();
  Rxn<CurrentUserModel> currentUserModel = Rxn();
  Rxn<LopDaoTaoModel> lopDaoTaoModel = Rxn();
  Rxn<NienKhoaDaoTaoModel> nienKhoaDaoTaoModel = Rxn();

  String maKhuVuc = kKhuVucKhac;

  int maxSizeMbUploadPaht = 30;

  StreamController<int> unreadCountStream = StreamController.broadcast();

  Talker talker = TalkerFlutter.init();

  Globals._internal() {
    loadLocalProperty();
  }

  static final Globals _singleton = Globals._internal();

  factory Globals() {
    return _singleton;
  }

  loadLocalProperty() async {
    try {
      usernameLogin =
          await DataRepository().getSecureSaveKey(kLoginUserName) ?? '';
    } catch (e) {
      logError(e.toString());
    }
    //Load mã khu vực
    maKhuVuc =
        await DataRepository().getSecureSaveKey(kMaKhuVuc) ?? kKhuVucKhac;
    unreadCountStream.sink.add(0);
  }

  Future<void> refreshStudentInfo() async {
    // ONEVNU_STALE_STUDENT_FIX_20260725: không giữ hồ sơ của tài khoản trước.
    thongTinSinhVienModel.value = null;
    lopDaoTaoModel.value = null;
    nienKhoaDaoTaoModel.value = null;

    try {
      var responseUser = await ApiRepository().getSinhVienInfo();
      Globals().thongTinSinhVienModel.value = responseUser;
    } catch (e) {
      // ONEVNU_STALE_STUDENT_FIX_20260725_CATCH
      thongTinSinhVienModel.value = null;
      lopDaoTaoModel.value = null;

            nienKhoaDaoTaoModel.value = null;

logError(e.toString());
    }
  }

  refreshUnread() {
    globalEvent.fire(FetchUnreadEvent());
  }

  fetchUnreadCount() async {
    try {
      var response = await ApiRepository().getNotificationCount();
      unreadCountStream.sink.add(response);
    } catch (e) {
      logError(e.toString());
    }
  }

  saveMaKhuVuc(String maKhuVuc) {
    DataRepository().saveSecureKey(kMaKhuVuc, maKhuVuc);
  }

  Future<void> clearSession({bool deleteUserLogin = false}) async {
    token = '';
    refreshToken = '';
    usernameLogin = '';
    thongTinSinhVienModel.value = null;
    currentUserModel.value = null;
    lopDaoTaoModel.value = null;
    nienKhoaDaoTaoModel.value = null;

    await DataRepository().deleteSecureKey(kLoginToken);
    await DataRepository().deleteSecureKey(kLoginRefreshToken);
    await DataRepository().deleteSecureKey(kApplicantAccessToken);
    await DataRepository().deleteSecureKey(kApplicantRefreshToken);
    await DataRepository().deleteSecureKey(kSessionPrincipalType);

    if (deleteUserLogin) {
      await DataRepository().deleteSecureKey(kLoginUserName);
      await DataRepository().deleteSecureKey(kLoginPassword);
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    const List<String> applicantKeys = <String>[
      'applicant_id',
      'applicant_cccd',
      'applicant_fullname',
      'applicant_email',
      'applicant_dob',
      'applicant_phone_number',
      'applicant_university_name',
      // Xóa cả key cũ để không còn dữ liệu tồn từ các bản trước.
      'applicant_phone',
    ];

    for (final String key in applicantKeys) {
      await prefs.remove(key);
    }

    try {
      await Future.forEach(ServicesUrl().topics, (topic) async {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      });
    } catch (e) {}

    ServicesUrl().topics = [];
  }

  Map<String, String> headerToken() {
    return {'Authorization': 'Bearer $token'};
  }
}
