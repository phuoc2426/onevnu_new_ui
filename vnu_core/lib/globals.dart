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
import 'package:vnu_core/modules/auth_mode/auth_entry_mode_service.dart';
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

  /// Clears only in-memory auth/user state. This is synchronous by design so
  /// user-triggered logout can leave the authenticated UI in the same frame.
  ///
  /// Returns the current FCM topic snapshot so topic cleanup can continue in
  /// the background without keeping the logout screen blocked.
  List<String> clearSessionMemory({bool deleteUserLogin = false}) {
    final List<String> topicSnapshot = List<String>.from(ServicesUrl().topics);

    token = '';
    refreshToken = '';
    usernameLogin = '';
    thongTinSinhVienModel.value = null;
    currentUserModel.value = null;
    lopDaoTaoModel.value = null;
    nienKhoaDaoTaoModel.value = null;
    ServicesUrl().topics = [];

    dlog(
      '[P1A_DIAG][LOGOUT_LOCAL][MEMORY_CLEARED] '
      'deleteUserLogin=$deleteUserLogin topicCount=${topicSnapshot.length}',
    );
    return topicSnapshot;
  }

  /// Critical persistent auth cleanup. Secure-storage writes and preferences
  /// are parallelized; no network work (FCM unsubscribe) is allowed here.
  Future<void> clearSessionStorage({bool deleteUserLogin = false}) async {
    final Stopwatch watch = Stopwatch()..start();
    dlog(
      '[P1A_DIAG][LOGOUT_LOCAL][STORAGE_CLEAR_BEGIN] '
      'deleteUserLogin=$deleteUserLogin',
    );

    final List<Future<void>> secureDeletes = <Future<void>>[
      DataRepository().deleteSecureKey(kLoginToken),
      DataRepository().deleteSecureKey(kLoginRefreshToken),
      DataRepository().deleteSecureKey(kApplicantAccessToken),
      DataRepository().deleteSecureKey(kApplicantRefreshToken),
      DataRepository().deleteSecureKey(kSessionPrincipalType),
      AuthEntryModeService().clear(),
    ];

    if (deleteUserLogin) {
      secureDeletes.addAll(<Future<void>>[
        DataRepository().deleteSecureKey(kLoginUserName),
        DataRepository().deleteSecureKey(kLoginPassword),
      ]);
    }

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

    final Future<void> preferencesCleanup = () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await Future.wait<bool>(
        applicantKeys.map((String key) => prefs.remove(key)),
      );
    }();

    await Future.wait<void>(<Future<void>>[
      ...secureDeletes,
      preferencesCleanup,
    ]);

    dlog(
      '[P1A_DIAG][LOGOUT_LOCAL][STORAGE_CLEAR_DONE] '
      'elapsedMs=${watch.elapsedMilliseconds}',
    );
  }

  /// Non-critical network cleanup. Never put this on the logout navigation
  /// critical path.
  Future<void> unsubscribeTopics(Iterable<String> topics) async {
    final List<String> snapshot = topics
        .map((String topic) => topic.trim())
        .where((String topic) => topic.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (snapshot.isEmpty) return;

    final Stopwatch watch = Stopwatch()..start();
    dlog(
      '[P1A_DIAG][LOGOUT_LOCAL][FCM_UNSUBSCRIBE_BEGIN] '
      'topicCount=${snapshot.length}',
    );

    try {
      await Future.wait<void>(
        snapshot.map(
          (String topic) => FirebaseMessaging.instance.unsubscribeFromTopic(topic),
        ),
      );
      dlog(
        '[P1A_DIAG][LOGOUT_LOCAL][FCM_UNSUBSCRIBE_DONE] '
        'topicCount=${snapshot.length} elapsedMs=${watch.elapsedMilliseconds}',
      );
    } catch (error) {
      logError(
        '[P1A_DIAG][LOGOUT_LOCAL][FCM_UNSUBSCRIBE_ERROR] '
        'type=${error.runtimeType} elapsedMs=${watch.elapsedMilliseconds}',
      );
    }
  }

  /// Backward-compatible full clear for non-interactive call sites.
  Future<void> clearSession({bool deleteUserLogin = false}) async {
    final List<String> topics = clearSessionMemory(
      deleteUserLogin: deleteUserLogin,
    );
    await clearSessionStorage(deleteUserLogin: deleteUserLogin);
    await unsubscribeTopics(topics);
  }

  Map<String, String> headerToken() {
    return {'Authorization': 'Bearer $token'};
  }
}

