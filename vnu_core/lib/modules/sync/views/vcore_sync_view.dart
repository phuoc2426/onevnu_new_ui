import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/sync/vneid_deep_link_service.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/field/vnu_text_field.dart';

// LƯU Ý: ApiRepository.setToken(rawToken) phải gắn header
// Authorization: Bearer <rawToken> cho Dio dùng trong repository.

class VcoreSyncView extends StatefulWidget {
  const VcoreSyncView({super.key});

  @override
  State<VcoreSyncView> createState() => _VcoreSyncViewState();
}

class _VcoreSyncViewState extends State<VcoreSyncView> {
  static final Uri _vneidShareUri = Uri.parse(
    'https://universal.dancuquocgia.com/share',
  );

  final TextEditingController _configNameController = TextEditingController();
  final ApiRepository _repository = ApiRepository();

  StreamSubscription<VneidDeepLinkEvent>? _callbackSubscription;

  bool _isCallingShareInfo = false;
  bool _isOpeningVneid = false;
  bool _isCheckingStatus = false;

  String? _currentTransitionCode;
  String? _currentResultCode;
  String? _screenMessage;

  VneidShareInfoStatusModel? _currentStatus;

  bool get _isBusy =>
      _isCallingShareInfo || _isOpeningVneid || _isCheckingStatus;

  @override
  void initState() {
    super.initState();

    _initializeRepositoryToken();
    VneidDeepLinkService().isSyncViewVisible = true;

    _callbackSubscription = VneidDeepLinkService().callbackStream.listen(
          (event) async {
        VneidDeepLinkService().consumeLatestCallback();
        await _handleVneidCallback(event);
      },
      onError: (Object error, StackTrace stackTrace) {
        _logBlock(
          title: 'VNEID CALLBACK STREAM ERROR',
          isError: true,
          values: {
            'errorType': error.runtimeType,
            'error': error,
            'stackTrace': stackTrace,
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final event = VneidDeepLinkService().consumeLatestCallback();

      if (event != null) {
        await _handleVneidCallback(event);
        return;
      }

      await _restoreLatestCachedTicket();
    });
  }

  @override
  void dispose() {
    VneidDeepLinkService().isSyncViewVisible = false;
    _callbackSubscription?.cancel();
    _configNameController.dispose();
    super.dispose();
  }


  /// Chuẩn hóa token để tránh trường hợp Globals().token đã chứa sẵn
  /// tiền tố "Bearer ", dẫn tới header bị thành "Bearer Bearer <token>".
  String _normalizeRawToken(String token) {
    final normalized = token.trim();

    if (normalized.toLowerCase().startsWith('bearer ')) {
      return normalized.substring(7).trim();
    }

    return normalized;
  }

  /// Gắn token cho ApiRepository.
  ///
  /// ApiRepository.setToken(rawToken) phải tạo header:
  /// Authorization: Bearer <rawToken>
  ///
  /// Không truyền chuỗi "Bearer <token>" trực tiếp vào setToken nếu
  /// setToken đã tự thêm tiền tố Bearer, vì sẽ gây "Bearer Bearer ...".
  void _applyBearerToken(
      String token, {
        required String action,
      }) {
    final rawToken = _normalizeRawToken(token);

    if (rawToken.isEmpty) {
      _logBlock(
        title: 'VNEID APPLY BEARER TOKEN FAILED',
        isError: true,
        values: {
          'action': action,
          'reason': 'Token rỗng',
        },
      );
      return;
    }

    _repository.setToken(rawToken);

    _logToken(
      action: action,
      token: rawToken,
    );
  }

  void _initializeRepositoryToken() {
    final token = Globals().token.trim();

    if (token.isEmpty) {
      _logBlock(
        title: 'VNEID INITIALIZATION',
        isError: true,
        values: {
          'message': 'Token rỗng, người dùng chưa đăng nhập',
          'tokenLength': token.length,
        },
      );
      return;
    }

    _applyBearerToken(
      token,
      action: 'INIT STATE - GÁN BEARER TOKEN CHO API REPOSITORY',
    );
  }

  Future<void> _startVneidSync() async {
    if (_isBusy) {
      logWarning('VNEID SYNC | Bỏ qua vì màn hình đang xử lý request khác');
      return;
    }

    final token = Globals().token.trim();

    _logToken(
      action: 'START SYNC - TOKEN LẤY TỪ GLOBALS',
      token: token,
    );

    if (token.isEmpty) {
      if (mounted) {
        setState(() {
          _screenMessage = 'Chưa có token xác thực – vui lòng đăng nhập.';
        });
      }

      snackBarError(
        'Bạn chưa đăng nhập. Vui lòng đăng nhập trước khi đồng bộ.',
      );
      return;
    }

    _applyBearerToken(
      token,
      action: 'START SYNC - GÁN BEARER TOKEN TRƯỚC SHARE-INFO',
    );

    if (mounted) {
      setState(() {
        _isCallingShareInfo = true;
        _currentTransitionCode = null;
        _currentResultCode = null;
        _currentStatus = null;
        _screenMessage =
        'Đang kiểm tra và gửi thông tin chia sẻ với OneVNU...';
      });
    }

    final configName = _configNameController.text.trim();
    final stopwatch = Stopwatch()..start();

    _logBlock(
      title: 'VNEID SHARE-INFO REQUEST',
      values: {
        'apiName': 'shareVneidInfo',
        'expectedMethod': 'POST',
        'expectedEndpoint': '/share-info',
        'configName': configName.isEmpty ? '<empty>' : configName,
        'tokenIsEmpty': token.isEmpty,
        'tokenLength': token.length,
        'authorization': 'Bearer ${_maskToken(_normalizeRawToken(token))}',
        'requestArguments': {
          'configName': configName,
        },
        'note':
        'Đây là toàn bộ tham số màn hình truyền vào ApiRepository. '
            'Body/headers cuối cùng do ApiRepository tạo cần Dio interceptor '
            'để quan sát chính xác.',
      },
    );

    try {
      final responseShareVneid = await _repository.shareVneidInfo(
        configName: configName,
      );

      stopwatch.stop();

      _logBlock(
        title: 'VNEID SHARE-INFO RESPONSE',
        values: {
          'apiName': 'shareVneidInfo',
          'elapsedMilliseconds': stopwatch.elapsedMilliseconds,
          'responseType': responseShareVneid.runtimeType,
          'responseData': _sanitizeForLog(responseShareVneid),
        },
      );

      if (!mounted) return;

      setState(() {
        _isCallingShareInfo = false;
        _isOpeningVneid = true;
        _screenMessage =
        'Đã gửi thông tin. Đang mở VNeID để xác nhận chia sẻ...';
      });

      _logBlock(
        title: 'VNEID OPEN EXTERNAL APP REQUEST',
        values: {
          'uri': _vneidShareUri,
          'launchMode': LaunchMode.externalApplication,
        },
      );

      final isOpened = await launchUrl(
        _vneidShareUri,
        mode: LaunchMode.externalApplication,
      );

      _logBlock(
        title: 'VNEID OPEN EXTERNAL APP RESULT',
        values: {
          'uri': _vneidShareUri,
          'isOpened': isOpened,
        },
      );

      if (!isOpened) {
        if (!mounted) return;

        setState(() {
          _screenMessage = 'Không thể mở ứng dụng VNeID. Vui lòng thử lại.';
        });

        snackBarError('Không thể mở ứng dụng VNeID. Vui lòng thử lại.');
        return;
      }

      if (!mounted) return;

      setState(() {
        _screenMessage =
        'Vui lòng hoàn tất xác nhận chia sẻ trên ứng dụng VNeID.';
      });
    } catch (error, stackTrace) {
      if (stopwatch.isRunning) {
        stopwatch.stop();
      }

      _logApiError(
        apiName: 'shareVneidInfo',
        error: error,
        stackTrace: stackTrace,
        token: token,
        additionalData: {
          'configName': configName,
          'elapsedMilliseconds': stopwatch.elapsedMilliseconds,
        },
      );

      if (!mounted) return;

      final message = _errorMessage(error);

      setState(() {
        _screenMessage = message;
      });

      snackBarError(message);
    } finally {
      if (mounted) {
        setState(() {
          _isCallingShareInfo = false;
          _isOpeningVneid = false;
        });
      }
    }
  }

  Future<void> _handleVneidCallback(VneidDeepLinkEvent event) async {
    final data = event.data;

    _logBlock(
      title: 'VNEID CALLBACK RECEIVED',
      values: {
        'uri': event.uri,
        'rawEventType': event.runtimeType,
        'rawEvent': _sanitizeForLog(event),
        'dataType': data?.runtimeType,
        'data': _sanitizeForLog(data),
      },
    );

    if (!mounted) return;

    if (data == null) {
      _logBlock(
        title: 'VNEID CALLBACK INVALID',
        isError: true,
        values: {
          'reason': 'Callback data is null',
          'uri': event.uri,
        },
      );

      setState(() {
        _screenMessage = 'Không nhận được kết quả hợp lệ từ VNeID.';
      });

      snackBarError('Không nhận được kết quả hợp lệ từ VNeID.');
      return;
    }

    final transitionCode = data.transactionCode.trim();
    final resultCode = data.result?.trim() ?? '';
    final isValidResultCode = const ['1', '2', '3'].contains(resultCode);

    _logBlock(
      title: 'VNEID CALLBACK PARSED',
      values: {
        'callbackUri': event.uri,
        'transitionCode': transitionCode,
        'transitionCodeIsEmpty': transitionCode.isEmpty,
        'resultCode': resultCode,
        'resultLabel': _resultLabel(resultCode),
        'isValidResultCode': isValidResultCode,
      },
    );

    if (transitionCode.isEmpty || !isValidResultCode) {
      _logBlock(
        title: 'VNEID CALLBACK VALIDATION FAILED',
        isError: true,
        values: {
          'transitionCode': transitionCode,
          'resultCode': resultCode,
          'acceptedResultCodes': const ['1', '2', '3'],
        },
      );

      setState(() {
        _screenMessage = 'Không nhận được kết quả hợp lệ từ VNeID.';
      });

      snackBarError('Không nhận được kết quả hợp lệ từ VNeID.');
      return;
    }

    setState(() {
      _currentTransitionCode = transitionCode;
      _currentResultCode = resultCode;
      _currentStatus = null;
    });

    final ticket = VneidSyncTicket(
      transactionCode: transitionCode,
      createdAt: DateTime.now(),
      status: null,
      message: _resultLabel(resultCode),
    );

    _logBlock(
      title: 'VNEID CACHE TICKET UPSERT REQUEST',
      values: {
        'ticket': _sanitizeForLog(ticket),
      },
    );

    await _repository.upsertVneidSyncTicket(ticket);

    _logBlock(
      title: 'VNEID CACHE TICKET UPSERT SUCCESS',
      values: {
        'transitionCode': transitionCode,
        'resultCode': resultCode,
      },
    );

    if (resultCode == '2') {
      setState(() {
        _screenMessage = 'Bạn chưa đồng ý chia sẻ thông tin từ VNeID.';
      });

      snackBarWarning('Bạn chưa đồng ý chia sẻ thông tin từ VNeID.');
      return;
    }

    if (resultCode == '3') {
      setState(() {
        _screenMessage =
        'Phiên chia sẻ thông tin đã hết hạn. Vui lòng thử lại.';
      });

      snackBarWarning('Phiên chia sẻ thông tin đã hết hạn.');
      return;
    }

    await _checkVneidStatus(transitionCode);
  }

  Future<void> _checkVneidStatus(String transitionCode) async {
    if (_isCheckingStatus) {
      logWarning(
        'VNEID STATUS | Bỏ qua vì request kiểm tra trạng thái đang chạy',
      );
      return;
    }

    final normalizedTransitionCode = transitionCode.trim();
    final token = Globals().token.trim();

    if (normalizedTransitionCode.isEmpty) {
      logWarning('VNEID STATUS | transitionCode rỗng');
      snackBarError('Mã giao dịch không hợp lệ.');
      return;
    }

    if (token.isEmpty) {
      logWarning('VNEID STATUS | Token rỗng');
      snackBarError('Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.');
      return;
    }

    _applyBearerToken(
      token,
      action: 'CHECK STATUS - GÁN BEARER TOKEN TRƯỚC STATUS API',
    );

    if (mounted) {
      setState(() {
        _isCheckingStatus = true;
        _screenMessage =
        'Đã xác nhận chia sẻ. Đang kiểm tra trạng thái phiếu...';
      });
    }

    final stopwatch = Stopwatch()..start();

    _logBlock(
      title: 'VNEID STATUS REQUEST',
      values: {
        'apiName': 'getVneidShareInfoStatus',
        'expectedMethod': 'GET',
        'expectedEndpoint':
        '/share-info/status/$normalizedTransitionCode',
        'transitionCode': normalizedTransitionCode,
        'tokenIsEmpty': token.isEmpty,
        'tokenLength': token.length,
        'authorization': 'Bearer ${_maskToken(_normalizeRawToken(token))}',
        'requestArguments': {
          'transitionCode': normalizedTransitionCode,
        },
      },
    );

    try {
      final response = await _repository.getVneidShareInfoStatus(
        normalizedTransitionCode,
      );

      stopwatch.stop();

      _logBlock(
        title: 'VNEID STATUS RESPONSE',
        values: {
          'apiName': 'getVneidShareInfoStatus',
          'elapsedMilliseconds': stopwatch.elapsedMilliseconds,
          'responseType': response.runtimeType,
          'responseData': {
            'txnId': response.txnId,
            'status': response.status,
            'studentCode': response.studentCode,
            'fullName': response.fullName,
            'identityNo': _maskNullableIdentityNo(response.identityNo),
            'message': response.message,
          },
          'serializedResponse': _sanitizeForLog(response),
        },
      );

      if (!mounted) return;

      final status = response.status?.trim().toUpperCase();
      final ticket = VneidSyncTicket(
        transactionCode: normalizedTransitionCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: response.status,
        studentCode: response.studentCode,
        fullName: response.fullName,
        identityNo: response.identityNo,
        message: response.message,
      );

      _logBlock(
        title: 'VNEID CACHE STATUS UPSERT REQUEST',
        values: {
          'ticket': _sanitizeForLog(ticket),
        },
      );

      await _repository.upsertVneidSyncTicket(ticket);

      _logBlock(
        title: 'VNEID CACHE STATUS UPSERT SUCCESS',
        values: {
          'transitionCode': normalizedTransitionCode,
          'status': response.status,
        },
      );

      setState(() {
        _currentStatus = response;
        _screenMessage = response.message?.trim().isNotEmpty == true
            ? response.message
            : 'Đã nhận trạng thái phiếu đồng bộ.';
      });

      if (status == 'SUCCESS') {
        snackBarSuccess('Đồng bộ thông tin thành công.');
      } else if (status == 'PENDING') {
        snackBarWarning('Phiếu đồng bộ đang được xử lý.');
      } else {
        snackBarError(response.message ?? 'Đồng bộ thông tin thất bại.');
      }
    } catch (error, stackTrace) {
      if (stopwatch.isRunning) {
        stopwatch.stop();
      }

      _logApiError(
        apiName: 'getVneidShareInfoStatus',
        error: error,
        stackTrace: stackTrace,
        token: token,
        additionalData: {
          'transitionCode': normalizedTransitionCode,
          'elapsedMilliseconds': stopwatch.elapsedMilliseconds,
        },
      );

      if (!mounted) return;

      final message = _errorMessage(error);

      setState(() {
        _screenMessage = message;
      });

      snackBarError(message);
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }

      _logBlock(
        title: 'VNEID STATUS FINISHED',
        values: {
          'transitionCode': normalizedTransitionCode,
          'elapsedMilliseconds': stopwatch.elapsedMilliseconds,
        },
      );
    }
  }

  void _logToken({required String action, required String token}) {
    _logBlock(
      title: 'VNEID TOKEN',
      values: {
        'action': action,
        'tokenIsEmpty': token.isEmpty,
        'tokenLength': token.length,
        'tokenMasked': _maskToken(token),
        'authorizationHeaderMasked': 'Bearer ${_maskToken(_normalizeRawToken(token))}',
      },
    );
  }

  void _logApiError({
    required String apiName,
    required Object error,
    required StackTrace stackTrace,
    required String token,
    Map<String, dynamic>? additionalData,
  }) {
    final values = <String, dynamic>{
      'apiName': apiName,
      'tokenIsEmpty': token.isEmpty,
      'tokenLength': token.length,
      'tokenMasked': _maskToken(token),
      'errorType': error.runtimeType,
      'error': error,
      if (additionalData != null) ...additionalData,
    };

    if (error is DioException) {
      values.addAll({
        'dioErrorType': error.type,
        'dioMessage': error.message,
        'requestMethod': error.requestOptions.method,
        'requestUri': error.requestOptions.uri,
        'requestPath': error.requestOptions.path,
        'requestBaseUrl': error.requestOptions.baseUrl,
        'requestHeaders': _sanitizeForLog(error.requestOptions.headers),
        'requestQueryParameters':
        _sanitizeForLog(error.requestOptions.queryParameters),
        'requestBody': _sanitizeForLog(error.requestOptions.data),
        'requestContentType': error.requestOptions.contentType,
        'requestResponseType': error.requestOptions.responseType,
        'requestConnectTimeout': error.requestOptions.connectTimeout,
        'requestSendTimeout': error.requestOptions.sendTimeout,
        'requestReceiveTimeout': error.requestOptions.receiveTimeout,
        'responseStatusCode': error.response?.statusCode,
        'responseStatusMessage': error.response?.statusMessage,
        'responseHeaders': _sanitizeForLog(error.response?.headers.map),
        'responseData': _sanitizeForLog(error.response?.data),
        'responseRealUri': error.response?.realUri,
      });
    }

    values['stackTrace'] = stackTrace;

    _logBlock(
      title: 'VNEID API ERROR',
      values: values,
      isError: true,
    );
  }

  void _logBlock({
    required String title,
    required Map<String, dynamic> values,
    bool isError = false,
  }) {
    final logger = isError ? logError : logInfo;
    final separator = '=' * 18;

    logger('$separator $title $separator');

    for (final entry in values.entries) {
      logger('${entry.key}: ${_sanitizeForLog(entry.value)}');
    }

    logger('=' * (title.length + 38));
  }

  dynamic _sanitizeForLog(dynamic value, {String? keyName}) {
    if (value == null) return null;

    final normalizedKey = keyName?.trim().toLowerCase();

    if (_isTokenKey(normalizedKey)) {
      return _maskToken(value.toString());
    }

    if (_isIdentityKey(normalizedKey)) {
      return _maskIdentityNo(value.toString());
    }

    if (value is Map) {
      return value.map(
            (key, item) => MapEntry(
          key.toString(),
          _sanitizeForLog(item, keyName: key.toString()),
        ),
      );
    }

    if (value is Iterable) {
      return value.map((item) => _sanitizeForLog(item)).toList();
    }

    if (value is FormData) {
      return {
        'fields': value.fields
            .map(
              (entry) => {
            'name': entry.key,
            'value': _sanitizeForLog(
              entry.value,
              keyName: entry.key,
            ),
          },
        )
            .toList(),
        'files': value.files
            .map(
              (entry) => {
            'fieldName': entry.key,
            'fileName': entry.value.filename,
            'length': entry.value.length,
            'contentType': entry.value.contentType?.toString(),
          },
        )
            .toList(),
      };
    }

    if (value is String || value is num || value is bool || value is Uri) {
      return value;
    }

    try {
      final dynamic dynamicValue = value;
      final dynamic jsonValue = dynamicValue.toJson();
      return _sanitizeForLog(jsonValue, keyName: keyName);
    } catch (_) {
      return value.toString();
    }
  }

  bool _isTokenKey(String? key) {
    if (key == null || key.isEmpty) return false;

    return key == 'authorization' ||
        key == 'token' ||
        key == 'jwt' ||
        key == 'access_token' ||
        key == 'accesstoken' ||
        key == 'refresh_token' ||
        key == 'refreshtoken';
  }

  bool _isIdentityKey(String? key) {
    if (key == null || key.isEmpty) return false;

    return key == 'cccd' ||
        key == 'identityno' ||
        key == 'identity_no' ||
        key == 'citizenid' ||
        key == 'citizen_id';
  }

  String _maskToken(String token) {
    final normalized = token.trim();

    if (normalized.isEmpty) return '<empty>';

    final lower = normalized.toLowerCase();
    final hasBearerPrefix = lower.startsWith('bearer ');
    final rawToken = hasBearerPrefix ? normalized.substring(7).trim() : normalized;
    final prefix = hasBearerPrefix ? 'Bearer ' : '';

    if (rawToken.length <= 14) {
      return '${prefix}***';
    }

    final firstPart = rawToken.substring(0, 8);
    final lastPart = rawToken.substring(rawToken.length - 6);
    return '$prefix$firstPart...$lastPart';
  }

  String? _maskNullableIdentityNo(String? value) {
    if (value == null) return null;
    return _maskIdentityNo(value);
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        final message = data['message'].toString().trim();

        if (message.isNotEmpty) {
          return message;
        }
      }

      if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }
    }

    return 'Đồng bộ thông tin thất bại. Vui lòng kiểm tra lại thông tin sinh viên.';
  }

  String _maskIdentityNo(String value) {
    final normalized = value.trim();

    if (normalized.length <= 4) {
      return normalized;
    }

    final last4 = normalized.substring(normalized.length - 4);
    return '********$last4';
  }

  String _statusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUCCESS':
        return 'Thành công';
      case 'PENDING':
        return 'Đang xử lý';
      case 'FAILED':
        return 'Thất bại';
      case 'EXPIRED':
        return 'Hết hạn';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status ?? 'Chưa có trạng thái';
    }
  }

  Color _statusBackgroundColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUCCESS':
        return const Color(0xFFE8F5E9);
      case 'PENDING':
        return const Color(0xFFFFF8E1);
      case 'FAILED':
        return const Color(0xFFFFEBEE);
      case 'EXPIRED':
        return const Color(0xFFFFF3E0);
      case 'CANCELLED':
        return const Color(0xFFF5F5F5);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  Color _statusForegroundColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUCCESS':
        return const Color(0xFF2E7D32);
      case 'PENDING':
        return const Color(0xFFF57F17);
      case 'FAILED':
        return const Color(0xFFC62828);
      case 'EXPIRED':
        return const Color(0xFFE65100);
      case 'CANCELLED':
        return const Color(0xFF616161);
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _resultLabel(String? resultCode) {
    switch (resultCode) {
      case '1':
        return 'Đã đồng ý chia sẻ';
      case '2':
        return 'Không đồng ý chia sẻ';
      case '3':
        return 'Phiên chia sẻ hết hạn';
      default:
        return 'Chưa có kết quả';
    }
  }

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Đồng bộ VNeID',
      showBackButton: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroCard(),
                    const SizedBox(height: 16),
                    _buildConfigCard(),
                    if (_currentTransitionCode != null) ...[
                      const SizedBox(height: 16),
                      _buildCallbackCard(),
                    ],
                    if (_currentStatus != null) ...[
                      const SizedBox(height: 16),
                      _buildStatusCard(_currentStatus!),
                    ],
                  ],
                ),
              ),
            ),
            _buildBottomSyncBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.tune_outlined,
            title: 'Cấu hình test',
          ),
          const SizedBox(height: 12),
          const Text(
            'Nhập tên config đã tạo trên service test. Ví dụ: quocanh, phuoc.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          VnuFloatingTextFieldAdapter(
            controller: _configNameController,
            enabled: !_isBusy,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Ví dụ: quocanh',
              prefixIcon: const Icon(Icons.settings_outlined),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Để trống nếu muốn dùng dữ liệu sinh viên thật trong app.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF2563EB),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đồng bộ dữ liệu VNeID',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Hệ thống sẽ kiểm tra thông tin và mở VNeID để bạn xác nhận chia sẻ dữ liệu.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreLatestCachedTicket() async {
    try {
      final tickets = await _repository.getCachedVneidSyncTickets();

      _logBlock(
        title: 'VNEID CACHE RESTORE',
        values: {
          'ticketCount': tickets.length,
          'tickets': _sanitizeForLog(tickets),
        },
      );

      if (!mounted || tickets.isEmpty) return;

      final latest = tickets.first;

      setState(() {
        _currentTransitionCode = latest.transactionCode;
        _currentResultCode = null;
        _screenMessage = latest.message?.trim().isNotEmpty == true
            ? latest.message
            : 'Đã khôi phục mã giao dịch gần nhất.';

        if (latest.status?.trim().isNotEmpty == true) {
          _currentStatus = VneidShareInfoStatusModel(
            txnId: latest.transactionCode,
            status: latest.status,
            studentCode: latest.studentCode,
            fullName: latest.fullName,
            identityNo: latest.identityNo,
            message: latest.message,
          );
        } else {
          _currentStatus = null;
        }
      });
    } catch (error, stackTrace) {
      _logBlock(
        title: 'VNEID CACHE RESTORE ERROR',
        isError: true,
        values: {
          'errorType': error.runtimeType,
          'error': error,
          'stackTrace': stackTrace,
        },
      );
    }
  }

  Widget _buildCallbackCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.link_outlined,
            title: 'Kết quả xác nhận từ VNeID',
          ),
          const SizedBox(height: 14),
          _buildInfoRow('Mã giao dịch', _currentTransitionCode ?? ''),
          _buildInfoRow('Kết quả', _resultLabel(_currentResultCode)),
        ],
      ),
    );
  }

  Widget _buildStatusCard(VneidShareInfoStatusModel status) {
    final statusCode = status.status?.toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSectionHeader(
                  icon: Icons.assignment_outlined,
                  title: 'Phiếu trạng thái đồng bộ',
                ),
              ),
              _buildStatusChip(statusCode),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            'Mã giao dịch',
            status.txnId?.trim().isNotEmpty == true
                ? status.txnId!
                : _currentTransitionCode ?? '',
          ),
          if ((status.studentCode ?? '').isNotEmpty)
            _buildInfoRow('Mã sinh viên', status.studentCode!),
          if ((status.fullName ?? '').isNotEmpty)
            _buildInfoRow('Họ tên', status.fullName!),
          if ((status.identityNo ?? '').isNotEmpty)
            _buildInfoRow('Số định danh', _maskIdentityNo(status.identityNo!)),
          if ((status.message ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildMessageBox(status.message!),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ShadButton.outline(
              onPressed: _currentTransitionCode == null || _isCheckingStatus
                  ? null
                  : () => _checkVneidStatus(_currentTransitionCode!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isCheckingStatus) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ] else ...[
                    const Icon(Icons.refresh, size: 16),
                  ],
                  const SizedBox(width: 6),
                  const Text('Kiểm tra lại'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: const Color(0xFF475569), size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _statusBackgroundColor(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: _statusForegroundColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF334155),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildBottomSyncBar() {
    final buttonText = _isCallingShareInfo
        ? 'Đang gửi yêu cầu...'
        : _isOpeningVneid
        ? 'Đang mở VNeID...'
        : _isCheckingStatus
        ? 'Đang kiểm tra...'
        : 'Đồng bộ dữ liệu VNeID';

    final helperText = _screenMessage?.trim().isNotEmpty == true
        ? _screenMessage!
        : 'Nhấn để đồng bộ dữ liệu thông tin';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            helperText,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed: _isBusy ? null : _startVneidSync,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isBusy) ...[
                      const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ] else ...[
                      const Icon(Icons.sync_rounded, size: 18),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      buttonText,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
