import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/admission/views/applicant_home_screen.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/applicant_session_repository.dart';
import 'package:vnu_core/services/services_url.dart';

class ApplicantAuthController extends GetxController {
  BuildContext? context;

  final TextEditingController cccdController =
  TextEditingController();

  final TextEditingController phoneNumberController =
  TextEditingController();

  final RxBool isLoading = false.obs;

  Future<void> login() async {
    if (isLoading.value) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final String cccd =
    cccdController.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

    final String phoneNumber =
    _normalizePhoneNumber(
      phoneNumberController.text,
    );

    if (cccd.length != 12) {
      snackBarError(
        'CCCD phải gồm đúng 12 chữ số',
      );
      return;
    }

    if (phoneNumber.length != 10) {
      snackBarError(
        'Số điện thoại phải gồm đúng 10 chữ số',
      );
      return;
    }

    isLoading.value = true;
    _showProgress();

    try {
      logInfo(
        '[NEW_STUDENT_LOGIN] '
            'Bắt đầu đăng nhập, '
            'CCCD=********${cccd.substring(8)}',
      );

      final String fcmToken =
      await _getFcmToken();

      logInfo(
        '[NEW_STUDENT_LOGIN] '
            'FCM token tồn tại: '
            '${fcmToken.isNotEmpty}',
      );

      final response =
      await ApiRepository().applicantLogin(
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
        throw const FormatException(
          'Máy chủ không trả về access token',
        );
      }

      if (response.refreshToken.trim().isEmpty) {
        throw const FormatException(
          'Máy chủ không trả về refresh token',
        );
      }

      final String fullName =
      response.applicant.fullName.trim();

      if (fullName.isEmpty) {
        throw const FormatException(
          'Máy chủ không trả về tên tân sinh viên',
        );
      }

      await ApplicantSessionRepository().save(
        response,
      );

      logInfo(
        '[NEW_STUDENT_LOGIN] Đã lưu session',
      );

      Globals().token =
          response.accessToken.trim();

      Globals().refreshToken =
          response.refreshToken.trim();

      ApiRepository().setToken(
        Globals().token,
      );

      logInfo(
        '[NEW_STUDENT_LOGIN] '
            'Đã gắn Authorization header',
      );

      _dismissProgress();

      logInfo(
        '[NEW_STUDENT_LOGIN] '
            'Chuyển tới ApplicantHomeScreen',
      );

      Get.offAll(
            () => ApplicantHomeScreen(
          fullName: fullName,
        ),
      );
    } on FormatException catch (
    error,
    stackTrace,
    ) {
    _dismissProgress();

    logError(
    '[NEW_STUDENT_LOGIN] '
    'Lỗi định dạng response: '
    '$error\n$stackTrace',
    );

    snackBarError(
    'Dữ liệu đăng nhập từ máy chủ '
    'không đúng định dạng: '
    '${error.message}',
    );
    } on DioException catch (
    error,
    stackTrace,
    ) {
    _dismissProgress();

    logError(
    '[NEW_STUDENT_LOGIN] '
    'HTTP error: '
    'status=${error.response?.statusCode}, '
    'data=${error.response?.data}\n'
    '$stackTrace',
    );

    snackBarError(
    _extractErrorMessage(
    error.response?.data,
    ),
    );
    } catch (
    error,
    stackTrace,
    ) {
    _dismissProgress();

    logError(
    '[NEW_STUDENT_LOGIN] '
    'Lỗi không xác định: '
    '$error\n$stackTrace',
    );

    snackBarError(
    _extractErrorMessage(error),
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
      final FirebaseMessaging messaging =
          FirebaseMessaging.instance;

      final NotificationSettings settings =
      await messaging.requestPermission(
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
        final String? apnsToken =
        await messaging.getAPNSToken();

        logInfo(
          '[NEW_STUDENT_LOGIN] '
              'APNs token tồn tại: '
              '${apnsToken?.isNotEmpty == true}',
        );
      }

      final String? token =
      await messaging.getToken();

      if (token != null &&
          token.trim().isNotEmpty) {
        final String normalizedToken =
        token.trim();

        ServicesUrl().firebaseToken =
            normalizedToken;

        logInfo(
          '[NEW_STUDENT_LOGIN] '
              'FCM token=${_maskToken(normalizedToken)}',
        );

        return normalizedToken;
      }
    } catch (
    error,
    stackTrace,
    ) {
    // Firebase lỗi không được phép chặn đăng nhập.
    logError(
    '[NEW_STUDENT_LOGIN] '
    'Không lấy được FCM token: '
    '$error\n$stackTrace',
    );
    }

    return ServicesUrl().firebaseToken?.trim() ??
    '';
  }

  String _normalizePhoneNumber(
      String value,
      ) {
    String phone = value.replaceAll(
      RegExp(r'\D'),
      '',
    );

    if (phone.startsWith('84') &&
        phone.length >= 11) {
      phone = '0${phone.substring(2)}';
    }

    return phone;
  }

  String _extractErrorMessage(
      dynamic data,
      ) {
    if (data is DioException) {
      return _extractErrorMessage(
        data.response?.data,
      );
    }

    if (data is Map) {
      final dynamic message =
          data['message'] ??
              data['error'] ??
              data['detail'];

      if (message != null &&
          message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }

      final dynamic nestedData = data['data'];

      if (nestedData is Map) {
        final dynamic nestedMessage =
            nestedData['message'] ??
                nestedData['error'];

        if (nestedMessage != null &&
            nestedMessage
                .toString()
                .trim()
                .isNotEmpty) {
          return nestedMessage
              .toString()
              .trim();
        }
      }
    }

    final String raw =
        data?.toString().trim() ?? '';

    if (raw.isNotEmpty && raw != 'null') {
      return raw
          .replaceFirst(
        'Exception: ',
        '',
      )
          .replaceFirst(
        'FormatException: ',
        '',
      );
    }

    return 'Không thể đăng nhập. '
        'Vui lòng kiểm tra CCCD '
        'và số điện thoại.';
  }

  String _maskToken(
      String token,
      ) {
    if (token.length <= 16) {
      return '***';
    }

    return '${token.substring(0, 8)}'
        '...'
        '${token.substring(token.length - 8)}';
  }

  void _showProgress() {
    try {
      Utils.showProgress(context);
    } catch (
    error,
    stackTrace,
    ) {
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
    } catch (
    error,
    stackTrace,
    ) {
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