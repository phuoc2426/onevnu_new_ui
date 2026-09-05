import 'dart:async';
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
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_core/services/services_url.dart';

class ApplicantAuthController extends GetxController {
  BuildContext? context;

  final TextEditingController cccdController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  final RxBool isLoading = false.obs;

  static const String _loginPath = '/api/applicant/auth/login';

  Future<void> login() async {
    if (isLoading.value) return;

    FocusManager.instance.primaryFocus?.unfocus();

    // Business requirement: both fields are free-form identifiers.
    // Do not normalize, strip characters, convert to digits, or force +84.
    final String cccd = cccdController.text.trim();
    final String phoneNumber = phoneNumberController.text.trim();

    if (cccd.isEmpty) {
      snackBarError('Vui lòng nhập CCCD / hộ chiếu / định danh');
      return;
    }

    if (phoneNumber.isEmpty) {
      snackBarError('Vui lòng nhập số điện thoại / thông tin liên hệ');
      return;
    }

    isLoading.value = true;
    _showProgress();

    _showUiTrace(
      'LOGIN - BƯỚC 1',
      'Đã kiểm tra dữ liệu đầu vào.\n'
      'Thiết bị: $_deviceInfo\n'
      'CCCD/định danh: ${cccd.length} ký tự\n'
      'SĐT/thông tin liên hệ: ${phoneNumber.length} ký tự\n'
      'Không hiển thị giá trị thật trên màn hình debug.',
    );

    try {
      final String loginUrl = '${ServicesUrl().baseUrl}$_loginPath';

      _showUiTrace(
        'LOGIN - BƯỚC 2',
        'Đang gửi request đăng nhập.\n'
        'URL: $loginUrl\n'
        'deviceToken: null\n'
        'FCM KHÔNG tham gia vào bước đăng nhập.',
      );

      logInfo(
        '[NEW_STUDENT_LOGIN] Start applicant login '
        'device=$_deviceInfo cccdLength=${cccd.length} '
        'phoneLength=${phoneNumber.length} deviceToken=null',
      );

      // Login must never depend on Firebase/FCM.
      final response = await ApiRepository().applicantLogin(
        cccd: cccd,
        phoneNumber: phoneNumber,
        deviceToken: null,
        deviceInfo: _deviceInfo,
      );

      _showUiTrace(
        'LOGIN - BƯỚC 3',
        'Đã nhận response đăng nhập từ máy chủ.\n'
        'Đang kiểm tra dữ liệu phiên.\n'
        'Không hiển thị accessToken / refreshToken.',
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

      _showUiTrace(
        'LOGIN - BƯỚC 4',
        'Đã lưu Applicant session thành công.\n'
        'Token được lưu nội bộ nhưng KHÔNG hiển thị trên giao diện.',
      );

      Globals().token = response.accessToken.trim();
      Globals().refreshToken = response.refreshToken.trim();
      ApiRepository().setToken(Globals().token);

      _showUiTrace(
        'LOGIN - BƯỚC 5',
        'Đã áp dụng access token cho ApiRepository.\n'
        'Đăng nhập chính đã hoàn tất.',
      );

      _dismissProgress();

      _showUiTrace(
        'LOGIN - BƯỚC 6',
        'Đang chuyển vào màn hình Tân sinh viên.\n'
        'FCM sẽ được xử lý sau, theo chế độ best-effort.',
      );

      logInfo('[NEW_STUDENT_LOGIN] Applicant login succeeded');

      Get.offAll(() => ApplicantHomeScreen(fullName: fullName));

      _showUiTrace(
        'LOGIN THÀNH CÔNG',
        'Đăng nhập thành công.\n'
        'Phiên đăng nhập đã được lưu.\n'
        'Bắt đầu đồng bộ FCM sau đăng nhập.',
      );

      // FCM must not block, roll back, clear session, or make login fail.
      unawaited(_syncFcmAfterLogin());
    } on FormatException catch (error, stackTrace) {
      _dismissProgress();

      final String message =
          'Loại lỗi: ${error.runtimeType}\n'
          'Chi tiết: ${_safeText(error.toString())}\n\n'
          'KẾT LUẬN:\n'
          'Request đăng nhập đã qua bước gọi API nhưng dữ liệu trả về không '
          'đúng cấu trúc mà ứng dụng cần. Đây là lỗi dữ liệu/response, không '
          'phải lỗi FCM.';

      _showUiTrace(
        'LOGIN THẤT BẠI - LOCAL',
        message,
        isError: true,
        duration: const Duration(seconds: 60),
      );

      logError(
        '[NEW_STUDENT_LOGIN] Invalid response format: $error\n$stackTrace',
      );
    } on DioException catch (error, stackTrace) {
      _dismissProgress();

      final DioException rawError = _unwrapDio(error);
      final Object? nativeError = rawError.error;
      final int? statusCode = rawError.response?.statusCode;
      final String? requestId = _extractRequestId(error, rawError);
      final String serverMessage = _extractServerMessage(
        rawError.response?.data,
      );

      final String diagnostic = _buildDioDiagnosticMessage(
        outerError: error,
        rawError: rawError,
        nativeError: nativeError,
        statusCode: statusCode,
        requestId: requestId,
        serverMessage: serverMessage,
      );

      _showUiTrace(
        statusCode == null
            ? 'LOGIN THẤT BẠI - DIO'
            : 'LOGIN THẤT BẠI - RESPONSE',
        diagnostic,
        isError: true,
        duration: const Duration(seconds: 60),
      );

      logError(
        '[NEW_STUDENT_LOGIN] HTTP_ERROR '
        'uri=${rawError.requestOptions.uri} '
        'status=${statusCode ?? '-'} '
        'requestId=${requestId ?? '-'} '
        'outerType=${error.runtimeType} '
        'rawDioType=${rawError.type} '
        'nativeType=${nativeError?.runtimeType ?? '-'} '
        'nativeError=${_safeText(nativeError?.toString() ?? '-')}\n'
        '$stackTrace',
      );
    } catch (error, stackTrace) {
      _dismissProgress();

      final String message =
          'Loại lỗi: ${error.runtimeType}\n'
          'Chi tiết: ${_safeText(error.toString())}\n\n'
          'KẾT LUẬN:\n'
          'Đây là lỗi cục bộ ngoài Dio. Cần chụp màn hình này để kiểm tra '
          'đúng runtime error.';

      _showUiTrace(
        'LOGIN THẤT BẠI - LOCAL',
        message,
        isError: true,
        duration: const Duration(seconds: 60),
      );

      logError(
        '[NEW_STUDENT_LOGIN] Unexpected login error: $error\n$stackTrace',
      );
    } finally {
      isLoading.value = false;
    }
  }

  DioException _unwrapDio(DioException error) {
    if (error is AppDioException) {
      return error.original;
    }
    return error;
  }

  String _buildDioDiagnosticMessage({
    required DioException outerError,
    required DioException rawError,
    required Object? nativeError,
    required int? statusCode,
    required String? requestId,
    required String serverMessage,
  }) {
    final AppDioException? wrapped =
        outerError is AppDioException ? outerError : null;

    final String nativeDetail = _nativeErrorDetail(nativeError);
    final String conclusion = _diagnoseNetworkError(
      rawError: rawError,
      nativeError: nativeError,
      statusCode: statusCode,
    );

    return 'URL:\n'
        '${rawError.requestOptions.uri}\n\n'
        'Dio type:\n'
        '${rawError.type}\n\n'
        'HTTP status:\n'
        '${statusCode?.toString() ?? 'KHÔNG CÓ RESPONSE'}\n\n'
        'Request ID:\n'
        '${requestId ?? 'KHÔNG CÓ'}\n\n'
        'Wrapper type:\n'
        '${outerError.runtimeType}\n\n'
        'App error code:\n'
        '${wrapped?.appError.code ?? 'KHÔNG CÓ'}\n\n'
        'Native error type:\n'
        '${nativeError?.runtimeType ?? 'KHÔNG CÓ'}\n\n'
        'Native error:\n'
        '$nativeDetail\n\n'
        'Server message:\n'
        '$serverMessage\n\n'
        'Thiết bị:\n'
        '$_deviceInfo\n\n'
        'KẾT LUẬN TẠM THỜI:\n'
        '$conclusion';
  }

  String _diagnoseNetworkError({
    required DioException rawError,
    required Object? nativeError,
    required int? statusCode,
  }) {
    if (statusCode != null) {
      return 'Máy chủ đã trả HTTP $statusCode. Request đã đi tới tầng HTTP; '
          'hãy đối chiếu Nginx/Spring Boot theo đúng thời điểm và Request ID.';
    }

    switch (rawError.type) {
      case DioExceptionType.connectionTimeout:
        return 'Hết thời gian thiết lập kết nối tới máy chủ. Nghi route mạng, '
            'firewall/VPN, DNS chậm hoặc mạng thiết bị không đi được tới server.';
      case DioExceptionType.sendTimeout:
        return 'Hết thời gian gửi request. Nghi kết nối mạng bị nghẽn hoặc '
            'đường truyền bị chặn/gián đoạn khi gửi dữ liệu.';
      case DioExceptionType.receiveTimeout:
        return 'Đã gửi request nhưng quá thời gian chờ nhận dữ liệu. Cần kiểm '
            'tra mạng trung gian và log Nginx/backend cùng thời điểm.';
      case DioExceptionType.badCertificate:
        return 'Dart/Android từ chối chứng chỉ HTTPS. Kiểm tra TLS certificate '
            'chain, trust store của thiết bị, proxy/VPN/Private DNS.';
      case DioExceptionType.cancel:
        return 'Request bị huỷ ở phía ứng dụng trước khi hoàn tất.';
      case DioExceptionType.badResponse:
        return 'Dio đánh dấu response lỗi nhưng không đọc được status tại đây. '
            'Cần xem Native error và log server.';
      case DioExceptionType.connectionError:
        break;
      case DioExceptionType.unknown:
        break;
    }

    if (nativeError is HandshakeException ||
        nativeError is TlsException) {
      return 'Lỗi TLS/SSL ở Dart/Android trước khi có HTTP response. Chrome '
          'có thể vẫn mở được vì Chrome và Dart không nhất thiết dùng cùng '
          'đường TLS/trust behavior. Kiểm tra certificate chain, VPN/proxy, '
          'Private DNS và phiên bản Android.';
    }

    if (nativeError is SocketException) {
      final String text = nativeError.toString().toLowerCase();

      if (text.contains('failed host lookup') ||
          text.contains('name or service not known') ||
          text.contains('nodename nor servname')) {
        return 'DNS của tiến trình ứng dụng không phân giải được domain. '
            'Ưu tiên kiểm tra Private DNS, VPN, DNS của Wi-Fi/4G và thử '
            'hotspot/mạng khác.';
      }

      if (text.contains('permission denied') ||
          text.contains('operation not permitted')) {
        return 'Hệ điều hành hoặc lớp bảo mật đang từ chối socket của ứng '
            'dụng. Nghi mạnh quyền truy cập mạng theo app, Data Saver, '
            'Restrict data usage, VPN/firewall hoặc chính sách ROM OPPO/'
            'Realme/Xiaomi/Vivo.';
      }

      if (text.contains('connection reset') ||
          text.contains('reset by peer')) {
        return 'Kết nối TCP đã được tạo nhưng bị reset trước khi nhận HTTP '
            'response. Kiểm tra firewall/proxy/VPN/mạng trung gian và Nginx.';
      }

      if (text.contains('connection refused')) {
        return 'Đích kết nối từ chối TCP connection. Kiểm tra route, cổng '
            'HTTPS, reverse proxy hoặc upstream tại thời điểm xảy ra lỗi.';
      }

      if (text.contains('network is unreachable') ||
          text.contains('no route to host')) {
        return 'Thiết bị/app không có route tới máy chủ. Thử đổi Wi-Fi/4G, '
            'tắt VPN/Private DNS và kiểm tra giới hạn dữ liệu theo ứng dụng.';
      }

      if (text.contains('timed out') || text.contains('timeout')) {
        return 'Socket bị timeout trước khi nhận HTTP response. Nghi mạng, '
            'route, firewall hoặc DNS/TCP chậm.';
      }

      return 'Đây là SocketException trước khi có HTTP response. Dòng Native '
          'error và OS errno ở phía trên là dữ liệu chính để xác định DNS, '
          'route, permission, reset hay refused.';
    }

    if (nativeError is HttpException) {
      return 'Dart HttpClient gặp lỗi protocol/connection trước khi tạo được '
          'HTTP response hoàn chỉnh. Cần đối chiếu nội dung Native error với '
          'Nginx và mạng trung gian.';
    }

    if (nativeError is OSError) {
      return 'Hệ điều hành trả OSError cho kết nối mạng. Hãy dùng errno và '
          'message phía trên để xác định permission/route/socket cụ thể.';
    }

    if (nativeError == null) {
      return 'Không có HTTP response và Dio không cung cấp native error. '
          'Hãy đối chiếu đúng thời điểm với Nginx access/error log; nếu Nginx '
          'không có request thì lỗi nằm trước server.';
    }

    return 'Request chết trước khi có HTTP response. Native error phía trên '
        'là lỗi runtime thật; chụp nguyên màn hình này để phân tích tiếp.';
  }

  String _nativeErrorDetail(Object? nativeError) {
    if (nativeError == null) {
      return 'KHÔNG CÓ';
    }

    if (nativeError is SocketException) {
      final OSError? osError = nativeError.osError;
      return '${_safeText(nativeError.toString())}\n'
          'OS error: ${_safeText(osError?.message ?? 'KHÔNG CÓ')}\n'
          'OS errno: ${osError?.errorCode ?? 'KHÔNG CÓ'}';
    }

    if (nativeError is OSError) {
      return '${_safeText(nativeError.toString())}\n'
          'OS errno: ${nativeError.errorCode}';
    }

    return _safeText(nativeError.toString());
  }

  String? _extractRequestId(
    DioException outerError,
    DioException rawError,
  ) {
    if (outerError is AppDioException) {
      final String fromAppError = outerError.appError.requestId?.trim() ?? '';
      if (fromAppError.isNotEmpty) return fromAppError;
    }

    final response = rawError.response;
    if (response == null) return null;

    const candidateHeaders = <String>{
      'x-request-id',
      'request-id',
      'x-correlation-id',
      'correlation-id',
      'x-trace-id',
      'trace-id',
    };

    for (final entry in response.headers.map.entries) {
      if (!candidateHeaders.contains(entry.key.toLowerCase())) continue;
      for (final value in entry.value) {
        final String normalized = value.trim();
        if (normalized.isNotEmpty) return normalized;
      }
    }

    final dynamic data = response.data;
    if (data is Map) {
      for (final key in const <String>[
        'requestId',
        'request_id',
        'correlationId',
        'traceId',
      ]) {
        final String value = data[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }

    return null;
  }

  String _extractServerMessage(dynamic data) {
    if (data == null) {
      return 'Không nhận được thông báo lỗi cụ thể từ máy chủ.';
    }

    if (data is Map) {
      for (final key in const <String>[
        'message',
        'error',
        'detail',
        'title',
      ]) {
        final dynamic value = data[key];
        if (value == null) continue;

        final String text = value.toString().trim();
        if (text.isNotEmpty && text != '{}') {
          return _safeText(text);
        }
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return _safeText(data.trim());
    }

    return 'Máy chủ có trả dữ liệu lỗi nhưng không có trường message dễ đọc.';
  }

  String _safeText(String value, {int maxLength = 1800}) {
    String normalized = value.replaceAll(
      RegExp(
        r'Bearer\s+[A-Za-z0-9._~+/=-]+',
        caseSensitive: false,
      ),
      'Bearer [REDACTED]',
    );

    normalized = normalized.replaceAllMapped(
      RegExp(
        r'(accessToken|refreshToken|deviceToken|token)\s*[:=]\s*[^,}\]\s]+',
        caseSensitive: false,
      ),
      (Match match) => '${match.group(1)}=[REDACTED]',
    );

    if (normalized.length > maxLength) {
      normalized = '${normalized.substring(0, maxLength)}... [ĐÃ RÚT GỌN]';
    }

    return normalized;
  }

  Future<void> _syncFcmAfterLogin() async {
    final String oldDeviceToken = ServicesUrl().firebaseToken?.trim() ?? '';

    try {
      _showUiTrace(
        'FCM - BƯỚC 1',
        'Đăng nhập đã thành công. Đang lấy FCM token sau login.\n'
        'Lỗi ở bước này KHÔNG được phép làm mất phiên đăng nhập.',
      );

      final String newDeviceToken = await _getFcmTokenAfterLogin();

      if (newDeviceToken.isEmpty) {
        _showUiTrace(
          'FCM LỖI',
          'Đăng nhập vẫn thành công.\n'
          'Firebase không trả về FCM token nên bỏ qua đồng bộ thông báo.\n'
          'Không logout và không xoá Applicant session.',
          duration: const Duration(seconds: 15),
        );
        return;
      }

      _showUiTrace(
        'FCM - BƯỚC 2',
        'Đã lấy được FCM token.\n'
        'Đang gọi /api/auth/devicetoken.\n'
        'Không hiển thị token thật trên giao diện.',
      );

      await ApiRepository().deviceToken(
        oldDeviceToken,
        newDeviceToken,
        _deviceInfo,
      );

      ServicesUrl().firebaseToken = newDeviceToken;

      _showUiTrace(
        'FCM THÀNH CÔNG',
        'Đã đồng bộ device token sau đăng nhập thành công.',
        duration: const Duration(seconds: 8),
      );

      logInfo('[NEW_STUDENT_LOGIN] FCM sync after login succeeded');
    } on DioException catch (error, stackTrace) {
      final DioException rawError = _unwrapDio(error);
      final Object? nativeError = rawError.error;

      _showUiTrace(
        'FCM LỖI - KHÔNG ẢNH HƯỞNG LOGIN',
        'Đăng nhập và Applicant session vẫn giữ nguyên.\n\n'
        'Dio type: ${rawError.type}\n'
        'HTTP status: ${rawError.response?.statusCode ?? 'KHÔNG CÓ RESPONSE'}\n'
        'Native type: ${nativeError?.runtimeType ?? 'KHÔNG CÓ'}\n'
        'Native error: ${_nativeErrorDetail(nativeError)}',
        duration: const Duration(seconds: 20),
      );

      logError(
        '[NEW_STUDENT_LOGIN] FCM sync Dio error '
        'type=${rawError.type} '
        'status=${rawError.response?.statusCode ?? '-'} '
        'nativeType=${nativeError?.runtimeType ?? '-'} '
        'nativeError=${_safeText(nativeError?.toString() ?? '-')}\n'
        '$stackTrace',
      );
    } catch (error, stackTrace) {
      _showUiTrace(
        'FCM LỖI - KHÔNG ẢNH HƯỞNG LOGIN',
        'Đăng nhập và Applicant session vẫn giữ nguyên.\n'
        'Loại lỗi: ${error.runtimeType}\n'
        'Chi tiết: ${_safeText(error.toString())}',
        duration: const Duration(seconds: 20),
      );

      logError(
        '[NEW_STUDENT_LOGIN] FCM sync error: $error\n$stackTrace',
      );
    }
  }

  Future<String> _getFcmTokenAfterLogin() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    logInfo(
      '[NEW_STUDENT_LOGIN] Notification permission after login: '
      '${settings.authorizationStatus}',
    );

    if (Platform.isIOS) {
      final String? apnsToken = await _waitForApnsToken(messaging);
      logInfo(
        '[NEW_STUDENT_LOGIN] APNs token available after login: '
        '${apnsToken?.isNotEmpty == true}',
      );
    }

    final String? token = await messaging.getToken();
    return token?.trim() ?? '';
  }

  Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final String? token = await messaging.getAPNSToken();
      if (token != null && token.trim().isNotEmpty) {
        return token.trim();
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }

  String get _deviceInfo {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return Platform.operatingSystem;
  }

  String _productionLoginErrorMessage(String title, String message) {
    if (title.contains('RESPONSE')) {
      const String marker = 'Server message:\n';
      final int markerIndex = message.indexOf(marker);
      if (markerIndex >= 0) {
        final String tail = message.substring(markerIndex + marker.length);
        final int blockEnd = tail.indexOf('\n\n');
        final String serverMessage =
            (blockEnd >= 0 ? tail.substring(0, blockEnd) : tail).trim();

        if (serverMessage.isNotEmpty &&
            !serverMessage.startsWith('Không nhận được thông báo lỗi') &&
            !serverMessage.startsWith('Máy chủ có trả dữ liệu lỗi')) {
          return _safeText(serverMessage, maxLength: 350);
        }
      }
    }

    if (title.contains('DIO')) {
      return 'Không thể kết nối đến hệ thống đăng nhập. '
          'Vui lòng kiểm tra kết nối mạng và thử lại.';
    }

    return 'Không thể hoàn tất đăng nhập. Vui lòng thử lại sau.';
  }

  void _showUiTrace(
    String title,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 5),
  }) {
    // Production/store mode: never show technical login/FCM traces on screen.
    // Keep only a normal user-facing error message when the login itself fails.
    // Success/step/FCM diagnostics remain internal via logInfo/logError calls.
    if (isError && title.startsWith('LOGIN THẤT BẠI')) {
      snackBarError(_productionLoginErrorMessage(title, message));
    }
  }

  void _showProgress() {
    try {
      Utils.showProgress(context);
    } catch (error, stackTrace) {
      logError(
        '[NEW_STUDENT_LOGIN] Show progress error: $error\n$stackTrace',
      );
    }
  }

  void _dismissProgress() {
    try {
      Utils.dismissProgress(context);
    } catch (error, stackTrace) {
      logError(
        '[NEW_STUDENT_LOGIN] Dismiss progress error: $error\n$stackTrace',
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
