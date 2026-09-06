import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:vnu_core/common/error/app_feedback.dart';
import 'package:vnu_core/common/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/modules/idp_auth/services/idp_auth_flow.dart';
import 'package:vnu_core/modules/auth_mode/auth_entry_mode_service.dart';
import 'package:vnu_core/modules/qr/models/qr_action_model.dart';
import 'package:vnu_core/modules/qr/repository/qr_repository.dart';

/// QR scanner + identity verification flow.
///
/// Design goals:
/// - Scanner frame corners are always drawn inward.
/// - Verification steps behave like a queue:
///   completed step slides left and disappears; remaining steps move upward.
/// - Final success is a screen-level overlay, independent from scroll position.
/// - Success checkmark is drawn by CustomPainter and must finish before pop.
/// - Layout adapts to small phones, tall phones, tablets and large text.
enum _VerificationStage {
  idle,
  qrReceived,
  resolving,
  authenticating,
  completing,
  success,
}

class VcoreQrScannerView extends StatefulWidget {
  const VcoreQrScannerView({super.key});

  @override
  State<VcoreQrScannerView> createState() => _VcoreQrScannerViewState();
}

class _VcoreQrScannerViewState extends State<VcoreQrScannerView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const Color _accent = Color(0xFF55F3A6);
  static const Color _accentStrong = Color(0xFF1AD27C);
  static const Color _accentDeep = Color(0xFF087C49);
  static const Color _darkSurface = Color(0xFF06100C);

  // Backend controls the real retry schedule. These are client-side circuit
  // breakers only, preventing a malformed/old backend from keeping the QR view
  // in an infinite retry loop.
  static const Duration _idpNotReadyClientHardCap = Duration(seconds: 25);
  static const int _idpNotReadyClientMaxCycles = 10;

  final LocalAuthentication _localAuthentication = LocalAuthentication();

  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
    facing: CameraFacing.back,
    torchEnabled: false,
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );

  late final AnimationController _scanLineController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  late final AnimationController _ambientController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  StreamSubscription<BarcodeCapture>? _barcodeSubscription;

  bool _processing = false;
  bool _disposed = false;
  bool _showSuccessOverlay = false;
  Completer<void>? _successCompleter;

  _VerificationStage _stage = _VerificationStage.idle;
  String _stageMessage = 'Đưa mã QR vào khung để bắt đầu';
  final Map<_VerificationStage, DateTime> _stageTimes =
      <_VerificationStage, DateTime>{};

  void _trace(String event, [String details = '']) {
    final String suffix = details.trim().isEmpty ? '' : ' ${details.trim()}';
    dlog('[QR_FLOW][SCANNER][$event]$suffix', wrapWidth: 1000);
  }

  void _traceError(String event, Object error, StackTrace stackTrace) {
    final String compactStack = stackTrace
        .toString()
        .split('\n')
        .where((String line) => line.trim().isNotEmpty)
        .take(8)
        .join(' | ');

    String apiDetails = '';
    if (error is QrApiException) {
      apiDetails =
          ' code=${error.code}'
          ' status=${error.statusCode ?? "none"}'
          ' providerStatus=${error.providerStatus ?? "none"}'
          ' providerError=${error.providerError ?? "none"}'
          ' providerRequestId=${error.providerRequestId ?? "none"}'
          ' stage=${error.failureStage ?? "none"}'
          ' classification=${error.classification ?? "none"}'
          ' networkKind=${error.networkKind ?? "none"}'
          ' outcome=${error.outcome ?? "none"}'
          ' retryable=${error.retryable ?? "none"}'
          ' userAction=${error.userAction ?? "none"}'
          ' flowId=${error.flowId ?? "none"}'
          ' rid=${error.requestId ?? "none"}';
    }

    final DateTime? flowStartedAt =
        _stageTimes[_VerificationStage.qrReceived];
    final int? flowElapsedMs = flowStartedAt == null
        ? null
        : DateTime.now().difference(flowStartedAt).inMilliseconds;

    _trace(
      event,
      'stage=${_stage.name} type=${error.runtimeType}$apiDetails '
      'flowElapsedMs=${flowElapsedMs ?? "none"} message=$error',
    );
    dlog('[QR_FLOW][SCANNER][STACK] $compactStack', wrapWidth: 1000);
  }

  String _sessionPrefix(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return 'none';
    return trimmed.length <= 8 ? trimmed : trimmed.substring(0, 8);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_guardAndStartScanner());
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_barcodeSubscription?.cancel());
    _scannerController.dispose();
    _scanLineController.dispose();
    _ambientController.dispose();

    final Completer<void>? completer = _successCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scannerController.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_processing) {
          Future<void>.delayed(const Duration(milliseconds: 120), () {
            if (mounted && !_disposed && !_processing) {
              unawaited(_startScanner());
            }
          });
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_barcodeSubscription?.cancel());
        _barcodeSubscription = null;
        unawaited(_scannerController.stop());
        break;
    }
  }

  Future<void> _guardAndStartScanner() async {
    _trace('ACCESS_CHECK_START');
    final QrAccessDecision decision =
        await AuthEntryModeService().qrAccessDecision();
    _trace(
      'ACCESS_CHECK_RESULT',
      'allowed=${decision.allowed} messageLength=${decision.message.length}',
    );
    if (!mounted || _disposed) return;

    if (!decision.allowed) {
      snackBarWarning(decision.message);
      Navigator.of(context).maybePop();
      return;
    }

    await _startScanner();
  }

  Future<void> _startScanner() async {
    if (_disposed) return;

    _trace('SCANNER_START_REQUEST');
    await _barcodeSubscription?.cancel();
    _barcodeSubscription = _scannerController.barcodes.listen(_onDetect);

    try {
      await _scannerController.start();
      _trace('SCANNER_STARTED');
    } catch (error, stackTrace) {
      _traceError('SCANNER_START_ERROR', error, stackTrace);
      if (mounted && !_disposed) {
        AppFeedback.showError(
          error,
          fallbackMessage: 'Không thể mở camera. Vui lòng thử lại.',
        );
      }
    }
  }

  /// Stop receiving barcodes but keep camera preview when possible.
  Future<void> _pauseDetection() async {
    await _barcodeSubscription?.cancel();
    _barcodeSubscription = null;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing || _showSuccessOverlay) return;

    String? rawQr;
    for (final Barcode barcode in capture.barcodes) {
      final String value = barcode.rawValue?.trim() ?? '';
      if (value.isNotEmpty) {
        rawQr = value;
        break;
      }
    }

    if (rawQr == null || rawQr.isEmpty) return;

    _trace(
      'SCAN_DETECTED',
      'barcodes=${capture.barcodes.length} rawLength=${rawQr.length}',
    );
    HapticFeedback.mediumImpact();
    unawaited(_resolveAndConfirm(rawQr));
  }

  Future<void> _resolveAndConfirm(String rawQr) async {
    final String flowId = const Uuid().v4();
    if (_processing) {
      _trace('FLOW_IGNORED', 'reason=already_processing');
      return;
    }

    _trace('FLOW_START', 'flowId=$flowId rawLength=${rawQr.length}');

    setState(() {
      _processing = true;
      _stageTimes.clear();
      _stage = _VerificationStage.qrReceived;
      _stageTimes[_VerificationStage.qrReceived] = DateTime.now();
      _stageMessage = 'Đã nhận mã QR · khởi tạo phiên xác minh';
    });

    await _pauseDetection();
    _trace('DETECTION_PAUSED');

    // Keep the first state visible long enough to be perceived.
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted || _disposed) return;

    _setStage(
      _VerificationStage.resolving,
      'Đang kiểm tra yêu cầu và thông tin phiên',
    );

    try {
      _trace('RESOLVE_CALL');
      final QrResolvedAction action = await QrRepository().resolve(rawQr, flowId: flowId);
      _trace(
        'RESOLVE_OK',
        'session=${_sessionPrefix(action.sessionId)} '
        'provider=${action.provider} type=${action.type} '
        'requiresConfirmation=${action.requiresConfirmation} '
        'localAuthRequired=${action.localAuthenticationRequired} '
        'contextVerified=${action.requestingContextVerified} '
        'requestingHost=${action.requestingHost ?? "none"} '
        'status=${action.status}',
      );
      if (!mounted || _disposed) return;

      setState(() {
        _stageMessage = 'Yêu cầu hợp lệ · sẵn sàng xác minh';
      });

      // Normal VNU IDP QR approval is deliberately simple: the user is already
      // authenticated in ONEVNU and must explicitly tap "Cho phép". Optional
      // device-local auth is controlled separately by the backend feature flag.
      bool confirmed = true;
      if (action.requiresConfirmation) {
        _trace(
          'CONFIRM_OPEN',
          'session=${_sessionPrefix(action.sessionId)} '
          'actionLabelLength=${action.actionLabel.length}',
        );
        final bool? confirmationResult = await _showConfirmation(action);
        confirmed = confirmationResult == true;
        _trace(
          'CONFIRM_RESULT',
          'session=${_sessionPrefix(action.sessionId)} '
          'result=${confirmationResult == null ? "dismissed" : confirmed}',
        );
      } else {
        _trace(
          'CONFIRM_SKIPPED',
          'session=${_sessionPrefix(action.sessionId)}',
        );
      }

      if (!confirmed) {
        _trace(
          'CANCEL_DISPATCH',
          'session=${_sessionPrefix(action.sessionId)}',
        );
        try {
          await QrRepository().cancel(action.sessionId, flowId: flowId);
          _trace(
            'CANCEL_DONE',
            'session=${_sessionPrefix(action.sessionId)}',
          );
        } catch (cancelError, cancelStack) {
          _traceError('CANCEL_ERROR', cancelError, cancelStack);
        }
        await _resumeAfterAction();
        return;
      }

      if (action.isIdp && action.localAuthenticationRequired) {
        _trace(
          'LOCAL_AUTH_START',
          'session=${_sessionPrefix(action.sessionId)}',
        );
        final bool locallyVerified = await _authenticateLocalIdentity();
        _trace(
          'LOCAL_AUTH_RESULT',
          'session=${_sessionPrefix(action.sessionId)} success=$locallyVerified',
        );
        if (!locallyVerified) {
          try {
            await QrRepository().cancel(action.sessionId, flowId: flowId);
          } catch (cancelError, cancelStack) {
            _traceError('LOCAL_AUTH_CANCEL_ERROR', cancelError, cancelStack);
          }
          if (mounted && !_disposed) {
            snackBarWarning(
              'Bạn cần xác thực bằng sinh trắc học hoặc mã khóa thiết bị để cho phép đăng nhập QR.',
            );
          }
          await _resumeAfterAction();
          return;
        }
      }

      _setStage(
        _VerificationStage.authenticating,
        action.isIdp
            ? 'Đang xác minh danh tính người dùng với VNU IDP'
            : 'Đang xác thực danh tính và quyền truy cập',
      );

      _trace(
        'EXECUTE_DISPATCH',
        'session=${_sessionPrefix(action.sessionId)} isIdp=${action.isIdp}',
      );
      await _execute(action, flowId);
    } catch (error, stackTrace) {
      _traceError('FLOW_ERROR', error, stackTrace);
      if (!mounted || _disposed) return;
      if (await _handleKnownQrFailure(error, flowId: flowId, session: 'none')) {
        return;
      }
      AppFeedback.showError(error);
      await _resumeAfterAction();
    }
  }

  Future<void> _execute(QrResolvedAction action, String flowId) async {
    final String session = _sessionPrefix(action.sessionId);
    _trace('EXECUTE_START', 'flowId=$flowId session=$session');

    try {
      final QrExecutionResult result = await _executeWithIdpReadinessRetry(
        action,
        flowId,
      );

      _trace(
        'EXECUTE_OK',
        'session=$session status=${result.status} '
        'messageLength=${result.message.length}',
      );
      if (!mounted || _disposed) return;
      await _completeSuccess(result.message);
    } catch (error, stackTrace) {
      _traceError('EXECUTE_ERROR', error, stackTrace);
      if (!mounted || _disposed) return;

      if (action.isIdp && await _handleKnownQrFailure(
        error,
        flowId: flowId,
        session: session,
        excludeReauth: true,
      )) {
        return;
      }

      if (action.isIdp && _requiresIdpReauth(error)) {
        _trace('IDP_REAUTH_REQUIRED', 'session=$session');
        final bool reLogin = await _askIdpLogin();
        _trace('IDP_REAUTH_DECISION', 'session=$session accepted=$reLogin');

        if (!reLogin || !mounted || _disposed) {
          await _resumeAfterAction();
          return;
        }

        try {
          _setStage(
            _VerificationStage.authenticating,
            'Đang làm mới phiên đăng nhập VNU IDP',
          );

          _trace('IDP_LOGIN_START', 'session=$session');
          final bool loggedIn = await IdpAuthFlow().login(
            context,
            forceLogin: true,
            flowId: flowId,
          );
          _trace('IDP_LOGIN_RESULT', 'session=$session success=$loggedIn');
          if (!loggedIn || !mounted || _disposed) {
            await _resumeAfterAction();
            return;
          }

          _setStage(
            _VerificationStage.authenticating,
            'Đã đăng nhập · đang xác minh lại danh tính',
          );

          if (action.localAuthenticationRequired) {
            _trace('LOCAL_AUTH_RETRY_START', 'session=$session');
            final bool retryLocallyVerified =
                await _authenticateLocalIdentity();
            _trace(
              'LOCAL_AUTH_RETRY_RESULT',
              'session=$session success=$retryLocallyVerified',
            );
            if (!retryLocallyVerified) {
              await _resumeAfterAction();
              return;
            }
          }

          _trace('EXECUTE_RETRY', 'session=$session');
          final QrExecutionResult retry = await _executeWithIdpReadinessRetry(
            action,
            flowId,
          );
          _trace(
            'EXECUTE_RETRY_OK',
            'session=$session status=${retry.status} '
            'messageLength=${retry.message.length}',
          );

          if (!mounted || _disposed) return;
          await _completeSuccess(retry.message);
          return;
        } catch (idpError, idpStack) {
          _traceError('IDP_REAUTH_FLOW_ERROR', idpError, idpStack);
          if (mounted && !_disposed) {
            _showFlowError(idpError);
          }
          await _resumeAfterAction();
          return;
        }
      }

      _showFlowError(error);
      await _resumeAfterAction();
    }
  }

  Future<QrExecutionResult> _executeWithIdpReadinessRetry(
    QrResolvedAction action,
    String flowId,
  ) async {
    final Stopwatch waitWindow = Stopwatch()..start();
    int cycle = 0;

    while (true) {
      if (!mounted || _disposed) {
        throw StateError('QR scanner view disposed during provider wait.');
      }

      cycle += 1;
      try {
        return await QrRepository().execute(
          action.sessionId,
          flowId: flowId,
        );
      } on QrApiException catch (error) {
        final bool confirmedNotReady =
            action.isIdp &&
            error.code == kQrErrorIdpChallengeNotReady &&
            error.providerStatus == 404 &&
            (error.providerError ?? '').toLowerCase() == 'not_found' &&
            error.retryable == true;

        if (!confirmedNotReady) rethrow;

        final int advisedMs = error.retryAfterMs ?? 1000;
        final int boundedMs = advisedMs.clamp(250, 5000).toInt();
        final int hardCapRemainingMs =
            _idpNotReadyClientHardCap.inMilliseconds -
                waitWindow.elapsedMilliseconds;

        _trace(
          'IDP_CHALLENGE_NOT_READY',
          'flowId=$flowId session=${_sessionPrefix(action.sessionId)} '
          'cycle=$cycle backendAttempt=${error.attempt ?? "none"}/${error.maxAttempts ?? "none"} '
          'providerStatus=${error.providerStatus} providerError=${error.providerError} '
          'retryAfterMs=$boundedMs waitElapsedMs=${error.waitElapsedMs ?? waitWindow.elapsedMilliseconds} '
          'graceMs=${error.graceMs ?? "none"} rid=${error.requestId ?? "none"} '
          'action=WAIT_AND_RETRY_SAME_SESSION',
        );

        if (cycle >= _idpNotReadyClientMaxCycles || hardCapRemainingMs <= 0) {
          _trace(
            'IDP_CHALLENGE_CLIENT_CIRCUIT_BREAKER',
            'flowId=$flowId session=${_sessionPrefix(action.sessionId)} '
            'cycle=$cycle elapsedMs=${waitWindow.elapsedMilliseconds} '
            'action=RESCAN_CURRENT_QR',
          );
          throw QrApiException(
            code: kQrErrorChallengeUnavailable,
            message:
                'Mã QR chưa sẵn sàng sau thời gian chờ. Vui lòng quét lại mã đang hiển thị.',
            statusCode: 410,
            requestId: error.requestId,
            flowId: flowId,
            providerStatus: error.providerStatus,
            providerError: error.providerError,
            failureStage: 'IDP_APPROVE',
            classification: 'CLIENT_NOT_READY_CIRCUIT_BREAKER',
            retryable: false,
            userAction: 'RESCAN_CURRENT_QR',
            outcome: 'NOT_APPROVED_CONFIRMED',
          );
        }

        final int actualDelayMs = math.min(boundedMs, hardCapRemainingMs);
        _setStage(
          _VerificationStage.authenticating,
          'Đang chuẩn bị xác nhận mã QR · ONEVNU sẽ tự thử lại',
        );
        await Future<void>.delayed(Duration(milliseconds: actualDelayMs));
      }
    }
  }

  Future<bool> _handleKnownQrFailure(
    Object error, {
    required String flowId,
    required String session,
    bool excludeReauth = false,
  }) async {
    if (error is! QrApiException) return false;

    _trace(
      'CLASSIFIED_FAILURE',
      'flowId=$flowId session=$session code=${error.code} '
      'stage=${error.failureStage ?? "none"} '
      'classification=${error.classification ?? "none"} '
      'providerStatus=${error.providerStatus ?? "none"} '
      'providerError=${error.providerError ?? "none"} '
      'networkKind=${error.networkKind ?? "none"} '
      'outcome=${error.outcome ?? "none"} '
      'retryable=${error.retryable ?? "none"} '
      'userAction=${error.userAction ?? "none"} '
      'retryAfterMs=${error.retryAfterMs ?? "none"} '
      'waitElapsedMs=${error.waitElapsedMs ?? "none"} graceMs=${error.graceMs ?? "none"} '
      'attempt=${error.attempt ?? "none"}/${error.maxAttempts ?? "none"} '
      'rid=${error.requestId ?? "none"}',
    );

    if (!excludeReauth && error.code == kQrErrorIdpReauthRequired) {
      return false;
    }

    switch (error.code) {
      case kQrErrorChallengeStale:
      case kQrErrorChallengeUnavailable:
      case kQrErrorExpired:
      case kQrErrorAlreadyUsed:
        snackBarWarning(
          error.message.isEmpty
              ? 'Mã QR không còn hiệu lực. Hãy quét mã đang hiển thị hiện tại.'
              : error.message,
        );
        await _resumeAfterAction();
        return true;
      case kQrErrorOutcomeUnknown:
        snackBarWarning(
          'Chưa xác định được kết quả xác nhận QR. Hãy kiểm tra trang web; nếu chưa đăng nhập, tạo mã QR mới rồi quét lại.',
        );
        await _resumeAfterAction();
        return true;
      case kQrErrorExecutionInProgress:
        snackBarWarning('Yêu cầu QR đang được xử lý. Vui lòng chờ trong giây lát.');
        await _resumeAfterAction();
        return true;
      case kQrErrorDeviceMismatch:
        snackBarWarning(
          'Phiên QR này được tạo trên thiết bị khác. Vui lòng quét lại mã bằng thiết bị hiện tại.',
        );
        await _resumeAfterAction();
        return true;
      case kQrErrorDeviceBindingRequired:
        snackBarWarning(
          'Phiên bản/phiên đăng nhập hiện tại chưa có thông tin thiết bị. Vui lòng mở lại OneVNU và đăng nhập lại.',
        );
        await _resumeAfterAction();
        return true;
      case kQrErrorTemporary:
        snackBarWarning(
          error.message.isEmpty
              ? 'VNU IDP đang tạm thời không phản hồi. Vui lòng thử lại sau.'
              : error.message,
        );
        await _resumeAfterAction();
        return true;
      case kQrErrorInvalidFormat:
      case kQrErrorInvalidPayload:
      case kQrErrorUnsupported:
        snackBarWarning(
          error.message.isEmpty
              ? 'Mã QR không đúng định dạng OneVNU hỗ trợ. Vui lòng quét mã QR VNU đang hiển thị.'
              : error.message,
        );
        await _resumeAfterAction();
        return true;
      case kQrErrorSecurityPolicyRejected:
        snackBarError(
          'Mã QR không thuộc miền/đường dẫn VNU IDP được OneVNU cho phép. Không xác nhận mã này.',
        );
        await _resumeAfterAction();
        return true;
    }

    if (error.userAction == 'RESCAN_CURRENT_QR') {
      snackBarWarning(error.message);
      await _resumeAfterAction();
      return true;
    }
    return false;
  }

  void _showFlowError(Object error) {
    if (error is QrApiException) {
      snackBarError(error.message);
      return;
    }
    AppFeedback.showError(error);
  }

  void _setStage(_VerificationStage stage, String message) {
    if (!mounted || _disposed) return;

    _trace('STAGE', 'from=${_stage.name} to=${stage.name}');
    setState(() {
      _stage = stage;
      _stageMessage = message;
      _stageTimes.putIfAbsent(stage, DateTime.now);
    });
  }

  Future<void> _completeSuccess(String backendMessage) async {
    _trace('SUCCESS_SEQUENCE_START', 'messageLength=${backendMessage.length}');
    _setStage(
      _VerificationStage.completing,
      'Đang hoàn tất và ghi nhận kết quả xác minh',
    );

    // Let "Hoàn tất xác minh" become the active queue item first.
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || _disposed) return;

    // Advancing to success makes the final queue item slide left and disappear.
    setState(() {
      _stage = _VerificationStage.success;
      _stageTimes[_VerificationStage.success] = DateTime.now();
      _stageMessage = backendMessage.trim();
    });

    await Future<void>.delayed(const Duration(milliseconds: 560));
    if (!mounted || _disposed) return;

    _successCompleter = Completer<void>();

    setState(() {
      _showSuccessOverlay = true;
    });

    HapticFeedback.heavyImpact();

    // IMPORTANT: wait for the actual success sequence, not an estimated delay.
    await _successCompleter!.future;
    if (!mounted || _disposed) return;

    // Hold the fully rendered checkmark and text for readability.
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _disposed) return;

    _trace('SUCCESS_SEQUENCE_DONE');
    Navigator.of(context).pop();
  }

  void _onSuccessAnimationCompleted() {
    final Completer<void>? completer = _successCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  bool _isStaleChallenge(Object error) {
    return error is QrApiException &&
        error.code == kQrErrorChallengeStale;
  }

  bool _requiresIdpReauth(Object error) {
    return error is QrApiException &&
        error.code == kQrErrorIdpReauthRequired;
  }

  Future<bool> _authenticateLocalIdentity() async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason:
            'Xác nhận danh tính để cho phép phiên web đăng nhập bằng tài khoản VNU của bạn',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (error, stackTrace) {
      _traceError('LOCAL_AUTH_ERROR', error, stackTrace);
      return false;
    }
  }

  Future<void> _safeToggleTorch() async {
    if (_scannerController.value.torchState == TorchState.unavailable) return;

    try {
      await _scannerController.toggleTorch();
    } catch (_) {
      // Torch is optional. Some iOS devices reject it while the camera starts.
    }
  }

  Future<bool?> _showConfirmation(QrResolvedAction action) {
    _trace(
      'CONFIRM_SHEET_BUILD',
      'session=${_sessionPrefix(action.sessionId)} '
      'titleLength=${action.title.length} descriptionLength=${action.description.length}',
    );
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.58),
      builder: (BuildContext sheetContext) {
        return _Sheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _SheetHandle(),
              const SizedBox(height: 20),
              _IconBadge(icon: Icons.qr_code_2_rounded, accent: _accentStrong),
              const SizedBox(height: 18),
              Text(
                action.title,
                textAlign: TextAlign.center,
                style: _titleStyle,
              ),
              if (action.description.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  action.description,
                  textAlign: TextAlign.center,
                  style: _bodyStyle,
                ),
              ],
              if (action.requestingContextVerified &&
                  (action.requestingService != null ||
                      action.requestingHost != null)) ...<Widget>[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Đăng nhập vào',
                        style: _bodyStyle.copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        action.requestingService ?? action.requestingHost!,
                        style: _bodyStyle.copyWith(
                          color: _accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB84D).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFB84D).withOpacity(0.35),
                  ),
                ),
                child: Text(
                  'Chỉ chọn Cho phép nếu bạn vừa chủ động quét mã QR trên trang VNU đang đăng nhập.',
                  textAlign: TextAlign.center,
                  style: _bodyStyle.copyWith(
                    color: const Color(0xFFFFD28A),
                    fontSize: 12,
                  ),
                ),
              ),
              if (action.localAuthenticationRequired) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  'Sau bước này, OneVNU sẽ yêu cầu sinh trắc học hoặc mã khóa thiết bị.',
                  textAlign: TextAlign.center,
                  style: _bodyStyle.copyWith(fontSize: 12),
                ),
              ],
              const SizedBox(height: 26),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SecondaryButton(
                      label: 'Hủy',
                      onTap: () => Navigator.of(sheetContext).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PrimaryButton(
                      label: action.actionLabel,
                      onTap: () => Navigator.of(sheetContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _askIdpLogin() async {
    _trace('IDP_REAUTH_DIALOG_OPEN');
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _Dialog(
          icon: Icons.lock_outline_rounded,
          accent: const Color(0xFFDD9A2B),
          title: 'Cần đăng nhập VNU IDP',
          content: 'Phiên IdP hiện tại đã hết hạn. Đăng nhập lại để tiếp tục?',
          actions: <Widget>[
            Expanded(
              child: _SecondaryButton(
                label: 'Để sau',
                onTap: () => Navigator.of(dialogContext).pop(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PrimaryButton(
                label: 'Đăng nhập',
                onTap: () => Navigator.of(dialogContext).pop(true),
              ),
            ),
          ],
        );
      },
    );

    _trace(
      'IDP_REAUTH_DIALOG_RESULT',
      'result=${result == null ? "dismissed" : result}',
    );
    return result == true;
  }

  Future<void> _resumeAfterAction() async {
    if (!mounted || _disposed) return;

    _trace('FLOW_RESUME_SCANNER');
    setState(() {
      _processing = false;
      _showSuccessOverlay = false;
      _stage = _VerificationStage.idle;
      _stageMessage = 'Đưa mã QR vào khung để bắt đầu';
      _stageTimes.clear();
    });

    await _startScanner();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            controller: _scannerController,
            errorBuilder:
                (
                  BuildContext context,
                  MobileScannerException error,
                  Widget? child,
                ) {
                  return const _CameraErrorView();
                },
          ),

          _CameraScrim(processing: _processing, surface: _darkSurface),

          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double viewportWidth = constraints.maxWidth;
                final double viewportHeight = constraints.maxHeight;
                final double contentWidth = math.min(viewportWidth, 520.0);

                final double horizontalPadding = viewportWidth < 360
                    ? 16.0
                    : 22.0;

                final double availableContentWidth =
                    contentWidth - horizontalPadding * 2;

                final double scanByWidth = availableContentWidth;
                final double scanByHeight = viewportHeight * 0.37;
                final double scanSize = math
                    .min(scanByWidth, scanByHeight)
                    .clamp(180.0, 330.0)
                    .toDouble();

                final bool compactHeight = viewportHeight < 690;

                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    height: viewportHeight,
                    child: Column(
                      children: <Widget>[
                        _ScannerHeader(
                          scannerController: _scannerController,
                          accent: _accent,
                          onBack: () => Navigator.of(context).maybePop(),
                          onTorch: _safeToggleTorch,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              compactHeight ? 8 : 12,
                              horizontalPadding,
                              28,
                            ),
                            child: Column(
                              children: <Widget>[
                                _IdentityIntro(
                                  processing: _processing,
                                  accent: _accent,
                                  compact: compactHeight,
                                ),
                                SizedBox(height: compactHeight ? 16 : 22),
                                _ScannerFrame(
                                  size: scanSize,
                                  scanLineAnimation: _scanLineController,
                                  ambientAnimation: _ambientController,
                                  accent: _accent,
                                  accentStrong: _accentStrong,
                                  processing: _processing,
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 420),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: _processing
                                      ? Padding(
                                          padding: EdgeInsets.only(
                                            top: compactHeight ? 22 : 30,
                                          ),
                                          child: _VerificationSection(
                                            stage: _stage,
                                            message: _stageMessage,
                                            stageTimes: _stageTimes,
                                            ambientAnimation:
                                                _ambientController,
                                            accent: _accent,
                                            accentStrong: _accentStrong,
                                          ),
                                        )
                                      : Padding(
                                          padding: EdgeInsets.only(
                                            top: compactHeight ? 16 : 22,
                                          ),
                                          child: _IdleHint(accent: _accent),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_showSuccessOverlay)
            Positioned.fill(
              child: _FinalSuccessOverlay(
                animation: _ambientController,
                accent: _accent,
                accentStrong: _accentStrong,
                accentDeep: _accentDeep,
                onCompleted: _onSuccessAnimationCompleted,
              ),
            ),
        ],
      ),
    );
  }
}

class _CameraScrim extends StatelessWidget {
  const _CameraScrim({required this.processing, required this.surface});

  final bool processing;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      child: processing
          ? ClipRect(
              key: const ValueKey<String>('processing'),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: ColoredBox(color: surface.withOpacity(0.74)),
              ),
            )
          : DecoratedBox(
              key: const ValueKey<String>('idle'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.black.withOpacity(0.64),
                    const Color(0xFF02110B).withOpacity(0.35),
                    Colors.black.withOpacity(0.78),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ScannerHeader extends StatelessWidget {
  const _ScannerHeader({
    required this.scannerController,
    required this.accent,
    required this.onBack,
    required this.onTorch,
  });

  final MobileScannerController scannerController;
  final Color accent;
  final VoidCallback onBack;
  final VoidCallback onTorch;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      child: Row(
        children: <Widget>[
          _RoundGlassButton(icon: Icons.arrow_back_rounded, onTap: onBack),
          const Expanded(
            child: Text(
              'Quét mã QR',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: scannerController,
            builder:
                (
                  BuildContext context,
                  MobileScannerState value,
                  Widget? child,
                ) {
                  if (value.torchState == TorchState.unavailable) {
                    return const SizedBox(width: 46, height: 46);
                  }

                  final bool isOn = value.torchState == TorchState.on;
                  return _RoundGlassButton(
                    icon: isOn
                        ? Icons.flash_on_rounded
                        : Icons.flashlight_on_rounded,
                    color: isOn ? accent : Colors.white,
                    onTap: onTorch,
                  );
                },
          ),
        ],
      ),
    );
  }
}

class _IdentityIntro extends StatelessWidget {
  const _IdentityIntro({
    required this.processing,
    required this.accent,
    required this.compact,
  });

  final bool processing;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.07),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withOpacity(0.32)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                processing
                    ? Icons.shield_outlined
                    : Icons.center_focus_strong_rounded,
                color: accent,
                size: 16,
              ),
              const SizedBox(width: 7),
              Text(
                processing ? 'XÁC MINH BẢO MẬT' : 'QUÉT AN TOÀN',
                style: TextStyle(
                  color: accent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.15,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 10 : 13),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 27 : 30,
                height: 1.10,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.8,
              ),
              children: <InlineSpan>[
                const TextSpan(text: 'OneVNU '),
                TextSpan(
                  text: 'Identity',
                  style: TextStyle(color: accent),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.12),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            processing
                ? 'Hệ thống đang xác thực thông tin\nvà quyền truy cập của bạn'
                : 'Đặt mã QR vào khung để bắt đầu\nquá trình xác minh an toàn',
            key: ValueKey<bool>(processing),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: compact ? 13.5 : 14.5,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame({
    required this.size,
    required this.scanLineAnimation,
    required this.ambientAnimation,
    required this.accent,
    required this.accentStrong,
    required this.processing,
  });

  final double size;
  final Animation<double> scanLineAnimation;
  final Animation<double> ambientAnimation;
  final Color accent;
  final Color accentStrong;
  final bool processing;

  @override
  Widget build(BuildContext context) {
    final double radius = size * 0.105;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Colors.white.withOpacity(0.035),
                    const Color(0xFF00140D).withOpacity(0.18),
                  ],
                ),
              ),
              child: AnimatedBuilder(
                animation: ambientAnimation,
                builder: (BuildContext context, Widget? child) {
                  return CustomPaint(
                    painter: _ScannerParticlesPainter(
                      progress: ambientAnimation.value,
                      color: accent,
                    ),
                  );
                },
              ),
            ),
          ),
          CustomPaint(
            painter: _ScannerFramePainter(
              accent: accent,
              accentStrong: accentStrong,
              radius: radius,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: AnimatedBuilder(
              animation: scanLineAnimation,
              builder: (BuildContext context, Widget? child) {
                final double progress = scanLineAnimation.value
                    .clamp(0.0, 1.0)
                    .toDouble();
                final double lineY = 14 + (size - 28) * progress;

                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 15,
                      right: 15,
                      top: lineY - 13,
                      child: Container(
                        height: 27,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              accent.withOpacity(0),
                              accent.withOpacity(0.11),
                              accent.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 13,
                      right: 13,
                      top: lineY,
                      child: Container(
                        height: processing ? 2.1 : 2.6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: LinearGradient(
                            colors: <Color>[
                              accent.withOpacity(0),
                              accent,
                              Colors.white.withOpacity(0.96),
                              accent,
                              accent.withOpacity(0),
                            ],
                            stops: const <double>[0, 0.22, 0.50, 0.78, 1],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: accent.withOpacity(0.78),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  const _ScannerFramePainter({
    required this.accent,
    required this.accentStrong,
    required this.radius,
  });

  final Color accent;
  final Color accentStrong;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const double outlineInset = 1.0;

    final RRect frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        outlineInset,
        outlineInset,
        size.width - outlineInset * 2,
        size.height - outlineInset * 2,
      ),
      Radius.circular(radius),
    );

    final Paint outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withOpacity(0.28);

    canvas.drawRRect(frame, outlinePaint);

    final double inset = math.max(16.0, size.width * 0.055);
    final double length = math.min(45.0, size.width * 0.16);
    final double bend = math.min(14.0, length * 0.36);

    final Paint glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent.withOpacity(0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final Paint cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: <Color>[accent, accentStrong],
      ).createShader(Offset.zero & size);

    final Path topLeft = Path()
      ..moveTo(inset + length, inset)
      ..lineTo(inset + bend, inset)
      ..quadraticBezierTo(inset, inset, inset, inset + bend)
      ..lineTo(inset, inset + length);

    final Path topRight = Path()
      ..moveTo(size.width - inset - length, inset)
      ..lineTo(size.width - inset - bend, inset)
      ..quadraticBezierTo(
        size.width - inset,
        inset,
        size.width - inset,
        inset + bend,
      )
      ..lineTo(size.width - inset, inset + length);

    final Path bottomLeft = Path()
      ..moveTo(inset, size.height - inset - length)
      ..lineTo(inset, size.height - inset - bend)
      ..quadraticBezierTo(
        inset,
        size.height - inset,
        inset + bend,
        size.height - inset,
      )
      ..lineTo(inset + length, size.height - inset);

    final Path bottomRight = Path()
      ..moveTo(size.width - inset, size.height - inset - length)
      ..lineTo(size.width - inset, size.height - inset - bend)
      ..quadraticBezierTo(
        size.width - inset,
        size.height - inset,
        size.width - inset - bend,
        size.height - inset,
      )
      ..lineTo(size.width - inset - length, size.height - inset);

    for (final Path path in <Path>[
      topLeft,
      topRight,
      bottomLeft,
      bottomRight,
    ]) {
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.accentStrong != accentStrong ||
        oldDelegate.radius != radius;
  }
}

class _ScannerParticlesPainter extends CustomPainter {
  const _ScannerParticlesPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 14; i++) {
      final double seed = i / 14;
      final double phase = (seed + progress) % 1;
      final double x = size.width * (0.11 + ((i * 37) % 79) / 100 * 0.78);
      final double y = size.height * (0.15 + phase * 0.70);
      final double opacity =
          math.sin(phase * math.pi).clamp(0.0, 1.0).toDouble() * 0.24;

      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), i % 3 == 0 ? 1.25 : 0.75, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _VerificationSection extends StatelessWidget {
  const _VerificationSection({
    required this.stage,
    required this.message,
    required this.stageTimes,
    required this.ambientAnimation,
    required this.accent,
    required this.accentStrong,
  });

  final _VerificationStage stage;
  final String message;
  final Map<_VerificationStage, DateTime> stageTimes;
  final Animation<double> ambientAnimation;
  final Color accent;
  final Color accentStrong;

  int get activeIndex {
    switch (stage) {
      case _VerificationStage.idle:
        return -1;
      case _VerificationStage.qrReceived:
        return 0;
      case _VerificationStage.resolving:
        return 1;
      case _VerificationStage.authenticating:
        return 2;
      case _VerificationStage.completing:
        return 3;
      case _VerificationStage.success:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: ambientAnimation,
              builder: (BuildContext context, Widget? child) {
                return CustomPaint(
                  painter: _LowerParticleFieldPainter(
                    progress: ambientAnimation.value,
                    color: accentStrong,
                  ),
                );
              },
            ),
          ),
        ),
        _VerificationQueue(
          activeIndex: activeIndex,
          message: message,
          stageTimes: stageTimes,
          ambientAnimation: ambientAnimation,
          accent: accent,
          accentStrong: accentStrong,
        ),
      ],
    );
  }
}

class _VerificationQueue extends StatefulWidget {
  const _VerificationQueue({
    super.key,
    required this.activeIndex,
    required this.message,
    required this.stageTimes,
    required this.ambientAnimation,
    required this.accent,
    required this.accentStrong,
  });

  final int activeIndex;
  final String message;
  final Map<_VerificationStage, DateTime> stageTimes;
  final Animation<double> ambientAnimation;
  final Color accent;
  final Color accentStrong;

  @override
  State<_VerificationQueue> createState() => _VerificationQueueState();
}

class _VerificationQueueState extends State<_VerificationQueue>
    with TickerProviderStateMixin {
  static const List<_TimelineStep> _steps = <_TimelineStep>[
    _TimelineStep(title: 'Đã nhận mã QR', stage: _VerificationStage.qrReceived),
    _TimelineStep(
      title: 'Kiểm tra yêu cầu',
      stage: _VerificationStage.resolving,
    ),
    _TimelineStep(
      title: 'Xác minh danh tính người dùng',
      stage: _VerificationStage.authenticating,
    ),
    _TimelineStep(
      title: 'Hoàn tất xác minh',
      stage: _VerificationStage.completing,
    ),
  ];

  late final AnimationController _shiftController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 540),
  );

  late final AnimationController _introController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  late int _displayIndex;
  int? _fromIndex;
  int? _toIndex;

  @override
  void initState() {
    super.initState();
    _displayIndex = widget.activeIndex.clamp(0, _steps.length).toInt();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _introController.forward(from: 0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _VerificationQueue oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.activeIndex < 0 || widget.activeIndex > _steps.length) return;
    if (widget.activeIndex == _displayIndex) return;

    if (widget.activeIndex < _displayIndex) {
      _shiftController.stop();
      _shiftController.value = 0;
      setState(() {
        _displayIndex = widget.activeIndex;
        _fromIndex = null;
        _toIndex = null;
      });
      return;
    }

    _fromIndex = _displayIndex;
    _toIndex = widget.activeIndex;

    _shiftController.forward(from: 0).whenComplete(() {
      if (!mounted) return;

      setState(() {
        _displayIndex = widget.activeIndex;
        _fromIndex = null;
        _toIndex = null;
      });
    });
  }

  @override
  void dispose() {
    _shiftController.dispose();
    _introController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '';

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activeIndex < 0) return const SizedBox.shrink();

    if (_displayIndex >= _steps.length &&
        _fromIndex == null &&
        _toIndex == null) {
      return const SizedBox.shrink();
    }

    final double systemTextScale = MediaQuery.of(
      context,
    ).textScaleFactor.clamp(1.0, 1.30).toDouble();
    final double slotHeight = 74 * systemTextScale;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 8, 8),
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _shiftController,
          _introController,
          widget.ambientAnimation,
        ]),
        builder: (BuildContext context, Widget? child) {
          final bool moving =
              _fromIndex != null &&
              _toIndex != null &&
              _shiftController.isAnimating;

          final double shiftProgress = moving
              ? Curves.easeInOutCubic.transform(_shiftController.value)
              : 1.0;

          final double introProgress = Curves.easeOutBack.transform(
            _introController.value.clamp(0.0, 1.0).toDouble(),
          );

          final int baseIndex = moving ? _fromIndex! : _displayIndex;
          final int targetIndex = moving ? _toIndex! : _displayIndex;
          final int remaining = _steps.length - baseIndex;

          final double viewportHeight = math.min(
            remaining * slotHeight,
            slotHeight * 3.15,
          );

          return SizedBox(
            height: viewportHeight,
            child: ClipRect(
              child: Stack(
                children: <Widget>[
                  for (int index = baseIndex; index < _steps.length; index++)
                    _buildAnimatedRow(
                      context: context,
                      index: index,
                      baseIndex: baseIndex,
                      targetIndex: targetIndex,
                      shiftProgress: shiftProgress,
                      introProgress: introProgress,
                      moving: moving,
                      slotHeight: slotHeight,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedRow({
    required BuildContext context,
    required int index,
    required int baseIndex,
    required int targetIndex,
    required double shiftProgress,
    required double introProgress,
    required bool moving,
    required double slotHeight,
  }) {
    final bool outgoing = moving && index == baseIndex;
    final int initialSlot = index - baseIndex;
    final int targetSlot = moving
        ? (index > targetIndex ? index - targetIndex : 0)
        : initialSlot;

    // Intro: each row starts above its final slot and is visibly pushed down.
    final double staggeredIntro = (introProgress - initialSlot * 0.07)
        .clamp(0.0, 1.0)
        .toDouble();

    double y = initialSlot * slotHeight - (1.0 - staggeredIntro) * 34.0;
    double x = 0;
    double opacity = staggeredIntro;
    double scale = 0.965 + staggeredIntro * 0.035;

    if (moving) {
      if (outgoing) {
        final double exit = Curves.easeInCubic.transform(shiftProgress);

        x = -math.max(260.0, MediaQuery.of(context).size.width * 0.75) * exit;
        y += 12 * exit;
        opacity *= 1 - Curves.easeInQuad.transform(shiftProgress);
        scale *= 1 - 0.045 * shiftProgress;
      } else {
        final double targetY = targetSlot * slotHeight;
        final double lift = Curves.easeOutBack.transform(shiftProgress);

        y = y + (targetY - y) * lift;
      }
    }

    final bool current = moving ? index == targetIndex : index == _displayIndex;

    return Positioned(
      left: 0,
      right: 0,
      top: y,
      child: Transform.translate(
        offset: Offset(x, 0),
        child: Transform.scale(
          alignment: Alignment.centerLeft,
          scale: scale,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0).toDouble(),
            child: _VerificationTextRow(
              height: slotHeight,
              item: _steps[index],
              current: current,
              message: current ? widget.message : null,
              time: _formatTime(widget.stageTimes[_steps[index].stage]),
              animation: widget.ambientAnimation,
              accent: widget.accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationTextRow extends StatelessWidget {
  const _VerificationTextRow({
    required this.height,
    required this.item,
    required this.current,
    required this.message,
    required this.time,
    required this.animation,
    required this.accent,
  });

  final double height;
  final _TimelineStep item;
  final bool current;
  final String? message;
  final String time;
  final Animation<double> animation;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double titleOpacity = current ? 1.0 : 0.38;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 30,
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: current
                  ? AnimatedBuilder(
                      animation: animation,
                      builder: (BuildContext context, Widget? child) {
                        final double pulse =
                            0.5 + 0.5 * math.sin(animation.value * math.pi * 2);

                        return Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Transform.scale(
                              scale: 1 + pulse * 0.75,
                              child: Container(
                                width: 19,
                                height: 19,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: accent.withOpacity(
                                      0.25 * (1 - pulse * 0.60),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: accent.withOpacity(0.95),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.22),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: Colors.white.withOpacity(titleOpacity),
                fontSize: current ? 16.5 : 14.0,
                height: 1.20,
                fontWeight: current ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: current ? -0.15 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (current && time.isNotEmpty) ...<Widget>[
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.30),
                            fontSize: 10.5,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (current && message != null) ...<Widget>[
                    const SizedBox(height: 5),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.25),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                      child: Text(
                        message!,
                        key: ValueKey<String>(message!),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent.withOpacity(0.80),
                          fontSize: 11.5,
                          height: 1.22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalSuccessOverlay extends StatelessWidget {
  const _FinalSuccessOverlay({
    required this.animation,
    required this.accent,
    required this.accentStrong,
    required this.accentDeep,
    required this.onCompleted,
  });

  final Animation<double> animation;
  final Color accent;
  final Color accentStrong;
  final Color accentDeep;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.04),
                radius: 1.12,
                colors: <Color>[
                  accentDeep.withOpacity(0.24),
                  const Color(0xFF04130C).withOpacity(0.95),
                  Colors.black.withOpacity(0.985),
                ],
                stops: const <double>[0.0, 0.56, 1.0],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double width = constraints.maxWidth;
                  final double height = constraints.maxHeight;
                  final double horizontalPadding = width < 360 ? 18 : 26;

                  final double contentWidth = math
                      .min(width - horizontalPadding * 2, 380.0)
                      .clamp(200.0, 380.0)
                      .toDouble();

                  final double orbSize = math
                      .min(contentWidth * 0.42, height * 0.19)
                      .clamp(112.0, 156.0)
                      .toDouble();

                  final double titleFontSize = (contentWidth * 0.058)
                      .clamp(19.0, 22.0)
                      .toDouble();

                  final double bodyFontSize = (contentWidth * 0.037)
                      .clamp(12.8, 14.0)
                      .toDouble();

                  // Scroll only acts as an overflow safety valve for very short
                  // screens / very large accessibility fonts. In normal devices
                  // the child is still vertically centered.
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 18,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(0.0, height - 36),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: contentWidth,
                          child: _SuccessSequence(
                            ambientAnimation: animation,
                            accent: accent,
                            accentStrong: accentStrong,
                            accentDeep: accentDeep,
                            orbSize: orbSize,
                            titleFontSize: titleFontSize,
                            bodyFontSize: bodyFontSize,
                            onCompleted: onCompleted,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessSequence extends StatefulWidget {
  const _SuccessSequence({
    required this.ambientAnimation,
    required this.accent,
    required this.accentStrong,
    required this.accentDeep,
    required this.orbSize,
    required this.titleFontSize,
    required this.bodyFontSize,
    required this.onCompleted,
  });

  final Animation<double> ambientAnimation;
  final Color accent;
  final Color accentStrong;
  final Color accentDeep;
  final double orbSize;
  final double titleFontSize;
  final double bodyFontSize;
  final VoidCallback onCompleted;

  @override
  State<_SuccessSequence> createState() => _SuccessSequenceState();
}

class _SuccessSequenceState extends State<_SuccessSequence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2450),
  );

  late final Animation<double> _orbOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.00, 0.16, curve: Curves.easeOut),
  );

  late final Animation<double> _orbScale =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 0.24,
            end: 1.12,
          ).chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 72,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1.12,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 28,
        ),
      ]).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.03, 0.40)),
      );

  late final Animation<double> _checkProgress = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.34, 0.66, curve: Curves.easeInOutCubic),
  );

  late final Animation<double> _rippleProgress = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.48, 0.90, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _titleOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.64, 0.84, curve: Curves.easeOut),
  );

  late final Animation<double> _bodyOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.72, 0.92, curve: Curves.easeOut),
  );

  late final Animation<Offset> _titleSlide =
      Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.62, 0.86, curve: Curves.easeOutCubic),
        ),
      );

  late final Animation<Offset> _bodySlide =
      Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.70, 0.94, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void initState() {
    super.initState();

    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onCompleted();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double stageHeight = widget.orbSize * 1.68;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          height: stageHeight,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              _controller,
              widget.ambientAnimation,
            ]),
            builder: (BuildContext context, Widget? child) {
              final double ambient =
                  0.5 +
                  0.5 * math.sin(widget.ambientAnimation.value * math.pi * 2);

              return CustomPaint(
                painter: _SuccessEffectsPainter(
                  progress: _rippleProgress.value,
                  ambient: ambient,
                  color: widget.accent,
                  strongColor: widget.accentStrong,
                  orbSize: widget.orbSize,
                ),
                child: Center(
                  child: FadeTransition(
                    opacity: _orbOpacity,
                    child: Transform.scale(
                      scale: _orbScale.value,
                      child: Container(
                        width: widget.orbSize,
                        height: widget.orbSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              const Color(0xFF9BFFE2),
                              widget.accentStrong,
                              widget.accentDeep,
                            ],
                            stops: const <double>[0.0, 0.55, 1.0],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.94),
                            width: 2.2,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: widget.accent.withOpacity(
                                0.44 + ambient * 0.16,
                              ),
                              blurRadius: 34 + ambient * 12,
                              spreadRadius: 6 + ambient * 2,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: widget.orbSize * 0.52,
                          height: widget.orbSize * 0.52,
                          child: CustomPaint(
                            painter: _AnimatedCheckPainter(
                              progress: _checkProgress.value,
                              color: Colors.white,
                              strokeWidth: (widget.orbSize * 0.058)
                                  .clamp(6.0, 9.0)
                                  .toDouble(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Text is deliberately outside the visual effects stage.
        // Nothing from the ripple painter can overlap or push it.
        const SizedBox(height: 12),

        FadeTransition(
          opacity: _titleOpacity,
          child: SlideTransition(
            position: _titleSlide,
            child: Text(
              'Xác minh thành công!',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: widget.accent,
                fontSize: widget.titleFontSize,
                height: 1.18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.30,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        FadeTransition(
          opacity: _bodyOpacity,
          child: SlideTransition(
            position: _bodySlide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    'Bạn đã sẵn sàng truy cập',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.74),
                      fontSize: widget.bodyFontSize,
                      height: 1.38,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accent.withOpacity(0.08),
                    border: Border.all(color: widget.accent.withOpacity(0.28)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: widget.accent,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessEffectsPainter extends CustomPainter {
  const _SuccessEffectsPainter({
    required this.progress,
    required this.ambient,
    required this.color,
    required this.strongColor,
    required this.orbSize,
  });

  final double progress;
  final double ambient;
  final Color color;
  final Color strongColor;
  final double orbSize;

  @override
  void paint(Canvas canvas, Size size) {
    final double p = progress.clamp(0.0, 1.0).toDouble();
    final Offset center = size.center(Offset.zero);

    final Paint glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = strongColor.withOpacity(0.06 + ambient * 0.04);

    canvas.drawCircle(center, orbSize * (0.72 + ambient * 0.08), glowPaint);

    // Circular ripples. Their size is bounded by this visual stage only.
    for (int i = 0; i < 3; i++) {
      final double local = ((p - i * 0.07) / 0.93).clamp(0.0, 1.0).toDouble();
      if (local <= 0) continue;

      final Paint ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = color.withOpacity((1 - local) * (0.42 - i * 0.08));

      canvas.drawCircle(
        center,
        orbSize * (0.54 + local * (0.34 + i * 0.12)),
        ringPaint,
      );
    }

    // Elliptical floor ripple, drawn far enough below the orb but still inside
    // this visual stage. It cannot collide with the title below.
    final double ellipseProgress = Curves.easeOutCubic.transform(p);
    final Rect ellipseRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + orbSize * 0.54),
      width: orbSize * (1.20 + ellipseProgress * 0.72),
      height: orbSize * (0.12 + ellipseProgress * 0.08),
    );

    final Paint ellipsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = strongColor.withOpacity((1 - p * 0.45) * 0.34);

    canvas.drawOval(ellipseRect, ellipsePaint);

    // Small deterministic particles.
    final Paint particlePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 18; i++) {
      final double angle = (i / 18) * math.pi * 2 + ambient * math.pi * 0.45;
      final double radius = orbSize * (0.48 + (i % 4) * 0.08 + ambient * 0.015);

      final Offset point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius * 0.74,
      );

      particlePaint.color = color.withOpacity(0.10 + (i % 3) * 0.05);

      canvas.drawCircle(point, i % 4 == 0 ? 1.6 : 0.9, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessEffectsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ambient != ambient ||
        oldDelegate.color != color ||
        oldDelegate.strongColor != strongColor ||
        oldDelegate.orbSize != orbSize;
  }
}

class _AnimatedCheckPainter extends CustomPainter {
  const _AnimatedCheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double p = progress.clamp(0.0, 1.0).toDouble();
    if (p <= 0) return;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Offset a = Offset(size.width * 0.15, size.height * 0.52);
    final Offset b = Offset(size.width * 0.40, size.height * 0.74);
    final Offset c = Offset(size.width * 0.84, size.height * 0.25);

    if (p < 0.44) {
      final double local = p / 0.44;
      canvas.drawLine(a, Offset.lerp(a, b, local)!, paint);
      return;
    }

    canvas.drawLine(a, b, paint);

    final double local = ((p - 0.44) / 0.56).clamp(0.0, 1.0).toDouble();

    canvas.drawLine(
      b,
      Offset.lerp(b, c, Curves.easeOutCubic.transform(local))!,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AnimatedCheckPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _LowerParticleFieldPainter extends CustomPainter {
  const _LowerParticleFieldPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final double baseY = size.height * 0.72;

    for (int i = 0; i < 48; i++) {
      final double t = i / 47;
      final double x = size.width * t;
      final double wave = math.sin(t * math.pi * 4 + progress * math.pi * 2);
      final double y = baseY + wave * 12 + (i % 5) * 4;
      final double centerFade =
          1 - ((t - 0.5).abs() * 1.55).clamp(0.0, 1.0).toDouble();

      paint.color = color.withOpacity(0.035 + centerFade * 0.11);
      canvas.drawCircle(Offset(x, y), i % 7 == 0 ? 1.5 : 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LowerParticleFieldPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _IdleHint extends StatelessWidget {
  const _IdleHint({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.075),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.center_focus_strong_rounded, color: accent, size: 18),
              const SizedBox(width: 9),
              const Flexible(
                child: Text(
                  'Đưa mã QR vào giữa khung để quét',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundGlassButton extends StatelessWidget {
  const _RoundGlassButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withOpacity(0.055),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withOpacity(0.20)),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(icon, color: color, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF050907),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.videocam_off_rounded,
                color: Colors.white38,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                'Không thể mở camera',
                style: _bodyStyle.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineStep {
  const _TimelineStep({required this.title, required this.stage});

  final String title;
  final _VerificationStage stage;
}

const TextStyle _titleStyle = TextStyle(
  fontSize: 19,
  fontWeight: FontWeight.w700,
  color: Color(0xFF12141A),
  height: 1.3,
);

const TextStyle _bodyStyle = TextStyle(
  fontSize: 14,
  height: 1.5,
  color: Color(0xFF6B7280),
);

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: accent, size: 30),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9AA1AC),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF31DF8E), Color(0xFF0B9858)],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: Color(0xFFE2E5EA)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E5EA),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _Dialog extends StatelessWidget {
  const _Dialog({
    required this.icon,
    required this.accent,
    required this.title,
    required this.content,
    required this.actions,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _IconBadge(icon: icon, accent: accent),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: _titleStyle),
              const SizedBox(height: 8),
              Text(content, textAlign: TextAlign.center, style: _bodyStyle),
              const SizedBox(height: 20),
              Row(children: actions),
            ],
          ),
        ),
      ),
    );
  }
}
