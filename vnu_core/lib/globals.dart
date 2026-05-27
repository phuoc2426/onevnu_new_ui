import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:vnu_core/common/events.dart';
import 'package:vnu_core/common/file_utils.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/services_url.dart';

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
    loadLocalProperty().then((_) {
      // Set up automatic local caching on changes
      thongTinSinhVienModel.listen((val) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          if (val != null) {
            await prefs.setString("cached_student_info", jsonEncode(val.toJson()));
          } else {
            await prefs.remove("cached_student_info");
          }
        } catch (e) {
          logError("cache student info error: $e");
        }
      });

      currentUserModel.listen((val) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          if (val != null) {
            await prefs.setString("cached_current_user", jsonEncode(val.toJson()));
          } else {
            await prefs.remove("cached_current_user");
          }
        } catch (e) {
          logError("cache current user error: $e");
        }
      });

      lopDaoTaoModel.listen((val) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          if (val != null) {
            await prefs.setString("cached_lop_dao_tao", jsonEncode(val.toJson()));
          } else {
            await prefs.remove("cached_lop_dao_tao");
          }
        } catch (e) {
          logError("cache lop dao tao error: $e");
        }
      });

      nienKhoaDaoTaoModel.listen((val) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          if (val != null) {
            await prefs.setString("cached_nien_khoa_dao_tao", jsonEncode(val.toJson()));
          } else {
            await prefs.remove("cached_nien_khoa_dao_tao");
          }
        } catch (e) {
          logError("cache nien khoa dao tao error: $e");
        }
      });
    });
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

    // Load cached info
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final studentInfoStr = prefs.getString("cached_student_info");
      if (studentInfoStr != null) {
        thongTinSinhVienModel.value = StudentInfoModel.fromJson(jsonDecode(studentInfoStr));
      }
      
      final currentUserStr = prefs.getString("cached_current_user");
      if (currentUserStr != null) {
        currentUserModel.value = CurrentUserModel.fromJson(jsonDecode(currentUserStr));
      }
      
      final lopDaoTaoStr = prefs.getString("cached_lop_dao_tao");
      if (lopDaoTaoStr != null) {
        lopDaoTaoModel.value = LopDaoTaoModel.fromJson(jsonDecode(lopDaoTaoStr));
      }

      final nienKhoaStr = prefs.getString("cached_nien_khoa_dao_tao");
      if (nienKhoaStr != null) {
        nienKhoaDaoTaoModel.value = NienKhoaDaoTaoModel.fromJson(jsonDecode(nienKhoaStr));
      }
    } catch (e) {
      logError("load cached info error: $e");
    }
  }

  Future<void> refreshStudentInfo() async {
    try {
      var responseUser = await ApiRepository().getSinhVienInfo();
      Globals().thongTinSinhVienModel.value = responseUser;

      if (responseUser != null) {
        // Fetch class info
        try {
          var classResp = await ApiRepository().getDataLopDaoTao(
            responseUser.idLopDaoTao,
            responseUser.guidDonVi,
            responseUser.idBacDaoTao,
            responseUser.idHeDaoTao,
            responseUser.idNganhDaoTao,
            responseUser.idNienKhoaDaoTao,
            responseUser.idChuongTrinhDaoTao,
          );
          if (classResp.isNotEmpty) {
            Globals().lopDaoTaoModel.value = classResp.first;
          }
        } catch (e) {
          logError("refreshStudentInfo fetch class error: $e");
        }

        // Fetch cohort/intake info
        try {
          var cohortResp = await ApiRepository().getDataNienKhoaDaoTao(
            responseUser.idNienKhoaDaoTao,
            responseUser.guidDonVi,
            responseUser.idBacDaoTao,
          );
          if (cohortResp.isNotEmpty) {
            Globals().nienKhoaDaoTaoModel.value = cohortResp.first;
          }
        } catch (e) {
          logError("refreshStudentInfo fetch cohort error: $e");
        }
      }
    } catch (e) {
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

  clearSession({bool deleteUserLogin = false}) async {
    token = '';
    thongTinSinhVienModel.value = null;
    currentUserModel.value = null;
    lopDaoTaoModel.value = null;
    nienKhoaDaoTaoModel.value = null;
    
    // Clear SharedPreferences Cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("cached_student_info");
      await prefs.remove("cached_current_user");
      await prefs.remove("cached_lop_dao_tao");
      await prefs.remove("cached_nien_khoa_dao_tao");
    } catch (e) {
      logError("clear cached info error: $e");
    }

    DataRepository().deleteSecureKey(kLoginToken);
    DataRepository().deleteSecureKey(kLoginRefreshToken);
    if (deleteUserLogin) {
      DataRepository().deleteSecureKey(kLoginUserName);
      DataRepository().deleteSecureKey(kLoginPassword);
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
