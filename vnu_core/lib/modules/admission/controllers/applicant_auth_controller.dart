import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/error/app_feedback.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/admission/views/applicant_home_screen.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/applicant_session_repository.dart';
import 'package:vnu_core/services/services_url.dart';

class ApplicantAuthController extends GetxController {
  BuildContext? context;

  final TextEditingController cccdController = TextEditingController();

  final TextEditingController phoneNumberController = TextEditingController();

  final RxBool isLoading = false.obs;

  Future<void> login() async {
    if (isLoading.value) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final String cccd = cccdController.text.trim();
    final String phoneNumber = phoneNumberController.text.trim();

    if (cccd.isEmpty) {
      snackBarError('Vui lòng nhập số CCCD');
      return;
    }

    if (phoneNumber.isEmpty) {
      snackBarError('Vui lòng nhập số điện thoại');
      return;
    }

    isLoading.value = true;
    _showProgress();

    try {
      final String maskedCccd = cccd.length > 8
          ? '********${cccd.substring(cccd.length - 4)}'
          : '********';
      logInfo(
        '[NEW_STUDENT_LOGIN] '
        'Bắt đầu đăng nhập, '
        'CCCD=$maskedCccd',
      );

      final String fcmToken = await _getFcmToken();

      logInfo(
        '[NEW_STUDENT_LOGIN] '
        'FCM token tồn tại: '
        '${fcmToken.isNotEmpty}',
      );

      final response = await ApiRepository().applicantLogin(
        cccd: cccd,
        phoneNumber: phoneNumber,
        deviceToken: fcmToken,
        deviceInfo: _deviceInfo,
      );

      logInfo(
        '[NEW_STUDENT_LOGIN] '
        'API đăng nhập thành công, '
        'principalType=${response.principalType}, '
        'applicantId=${response.applicant.id}',
      );

      if (response.accessToken.trim().isEmpty) {
        throw const FormatException('Máy chủ không trả về access token');
      }

      if (response.refreshToken.trim().isEmpty) {
        throw const FormatException('Máy chủ không trả về refresh token');
      }

      final String fullName = response.applicant.fullName.trim();

      if (fullName.isEmpty) {
        throw const FormatException('Máy chủ không trả về tên tân sinh viên');
      }

      await ApplicantSessionRepository().save(response);

      logInfo('[NEW_STUDENT_LOGIN] Đã lưu session');

      Globals().token = response.accessToken.trim();

      Globals().refreshToken = response.refreshToken.trim();

      ApiRepository().setToken(Globals().token);

      logInfo(
        '[NEW_STUDENT_LOGIN] '
        'Đã gắn Authorization header',
      );

      _dismissProgress();

      logInfo(
        '[NEW_STUDENT_LOGIN] '
        'Chuyển tới ApplicantHomeScreen',
      );

      Get.offAll(() => ApplicantHomeScreen(fullName: fullName));
    } on FormatException catch (error, stackTrace) {
      _dismissProgress();
      logError('[NEW_STUDENT_LOGIN] Invalid response format');
      AppFeedback.showError(
        error,
        stackTrace: stackTrace,
        fallbackMessage:
            'Dữ liệu đăng nhập từ máy chủ chưa đúng định dạng. Vui lòng thử lại.',
      );
    } on DioException catch (error, stackTrace) {
      _dismissProgress();
      logError(
        '[NEW_STUDENT_LOGIN] HTTP error status=${error.response?.statusCode ?? '-'}',
      );
      AppFeedback.showError(
        error,
        stackTrace: stackTrace,
        fallbackMessage:
            'Không thể đăng nhập. Vui lòng kiểm tra CCCD và số điện thoại.',
      );
    } catch (error, stackTrace) {
      _dismissProgress();
      logError('[NEW_STUDENT_LOGIN] Unexpected login error');
      AppFeedback.showError(
        error,
        stackTrace: stackTrace,
        fallbackMessage:
            'Không thể đăng nhập. Vui lòng kiểm tra CCCD và số điện thoại.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  String get _deviceInfo {
    if (Platform.isAndroid) {
      return 'Android';
    }

    if (Platform.isIOS) {
      return 'iOS';
    }

    return Platform.operatingSystem;
  }

  Future<String> _getFcmToken() async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      final NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      logInfo(
        '[NEW_STUDENT_LOGIN] '
        'Notification permission: '
        '${settings.authorizationStatus}',
      );

      if (Platform.isIOS) {
        final String? apnsToken = await messaging.getAPNSToken();

        logInfo(
          '[NEW_STUDENT_LOGIN] '
          'APNs token tồn tại: '
          '${apnsToken?.isNotEmpty == true}',
        );
      }

      final String? token = await messaging.getToken();

      if (token != null && token.trim().isNotEmpty) {
        final String normalizedToken = token.trim();

        ServicesUrl().firebaseToken = normalizedToken;

        logInfo('[NEW_STUDENT_LOGIN] FCM token is available');

        return normalizedToken;
      }
    } catch (error, stackTrace) {
      // Firebase lỗi không được phép chặn đăng nhập.
      logError(
        '[NEW_STUDENT_LOGIN] '
        'Không lấy được FCM token: '
        '$error\n$stackTrace',
      );
    }

    return ServicesUrl().firebaseToken?.trim() ?? '';
  }


  void _showProgress() {
    try {
      Utils.showProgress(context);
    } catch (error, stackTrace) {
      logError(
        '[NEW_STUDENT_LOGIN] '
        'Show progress error: '
        '$error\n$stackTrace',
      );
    }
  }

  void _dismissProgress() {
    try {
      Utils.dismissProgress(context);
    } catch (error, stackTrace) {
      logError(
        '[NEW_STUDENT_LOGIN] '
        'Dismiss progress error: '
        '$error\n$stackTrace',
      );
    }
  }

  @override
  void onClose() {
    cccdController.dispose();
    phoneNumberController.dispose();
    super.onClose();
  }
}

