import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/widgets/vnu_loading.dart';
import 'package:vnu_core/modules/tuition/data/tuition_api_diagnostics.dart';
import 'package:intl/intl.dart';
import 'package:vnu_core/modules/tuition/data/tuition_demo_repository.dart';
import 'package:vnu_core/modules/tuition/data/tuition_web_mock_gateway.dart';
import 'package:vnu_core/modules/tuition/data/tuition_charge_category.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_receivable_lifecycle.dart';
import 'package:vnu_core/modules/tuition/data/tuition_payable_reconciliation.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_session_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_session_recovery_policy.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_clear_session_overlay.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_receipt_motion.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_scene_preparation.dart';
import 'package:vnu_core/modules/tuition/data/tuition_overview_total.dart';
import 'package:dio/dio.dart';
import 'package:vnu_core/widgets/student_service_ui.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_premium_ui.dart';
import 'package:vnu_core/widgets/vnu_press_motion.dart';
import 'package:vnu_core/widgets/vcore_action_dialog.dart';
import 'package:vnu_core/widgets/vcore_notice_toast.dart';
import 'package:vnu_core/widgets/select/vnu_select.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_ticket_paper.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_responsive_width.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_status_motion.dart';
import 'package:vnu_core/modules/tuition/widgets/tuition_stable_qr.dart';

/// Native ULIS payment UI. Only a trusted backend can provide [liveSession].
/// Demo data is rendered exclusively in Flutter Debug mode.
class VcoreTuitionView extends StatefulWidget {
  const VcoreTuitionView({super.key, required this.universityId,
    this.developerPreview = false, this.liveSession, this.mockGateway = false});
  final int universityId;
  final bool developerPreview;
  /// Use the ORIGINAL production screen with an in-memory API substitute.
  /// This is always disabled in profile/release builds.
  final bool mockGateway;
  final TuitionGatewaySession? liveSession;
  @override
  State<VcoreTuitionView> createState() => _VcoreTuitionViewState();
}

class _VcoreTuitionViewState extends State<VcoreTuitionView> with WidgetsBindingObserver {
  final TuitionDemoRepository _repo = TuitionDemoRepository.instance;
  TuitionWebMockGateway? _webMockStore;
  TuitionWebMockGateway get _webMock =>
      _webMockStore ??= TuitionWebMockGateway();
  bool get _mockMode => kDebugMode &&
      (widget.mockGateway || (kIsWeb &&
        const bool.fromEnvironment('ONEVNU_TUITION_WEB_MOCK')));
  TuitionDemoBill? _selected;
  String _filter = 'Tất cả';
  // CP1 filters (server): termId, collectionPeriodCode, payableOnly.
  // The 3 overview tabs remain independent financial-debt views.
  String? _selectedTermId;
  String? _selectedPeriodCode;
  bool _canCreateOnly = false;
  // Local-only filters: NOT exposed in the CP1 query DTO.
  String _financeFilter = '';
  String _qrStatusFilter = '';
  String _sortFilter = 'due_asc';
  final TextEditingController _searchController = TextEditingController();
  Set<String>? _serverFilterIds;
  bool _serverFilterLoading = false;
  String? _serverFilterError;
  bool _cancelLockAwaitingRelease = false;
  Timer? _searchDebounce;
  int _serverFilterEpoch = 0;
  bool _checking = false;
  String? _detailError;
  int _detailEpoch = 0;
  // Visual-only generations. GET status polls must never replay these motions.
  int _listWaveGeneration = 0;
  // V13: physical-feed motion starts BEFORE POST create or GET/POST recreate;
  // success/failure merely releases the final stage. No extra payment API.
  int _printerAttemptSerial = 0;
  bool _printerActive = false;
  // Bounded entry + QR warmup. These are VISUAL gates, never API retries.
  bool _entryPreparing = true;
  bool _qrPreparing = false;
  bool _lightweightPrinterAttempt = false;
  int _preparationGeneration = 0;
  TuitionPrintOutcome _printerOutcome = TuitionPrintOutcome.waitingForGateway;
  Widget? _printerOldReceipt;
  final ScrollController _mockDetailScroll = ScrollController();
  final GlobalKey _detailPrinterLayerKey = GlobalKey(debugLabel: 'tuition_body');
  final GlobalKey _detailTicketTargetKey = GlobalKey(debugLabel: 'tuition_sheet');
  bool _isForeground = true;
  bool _statusRequestInFlight = false;
  Completer<void>? _statusDone;
  bool _connecting = false;
  bool _manualRefreshing = false;
  bool _clearAnimationVisible = false;
  bool _autoSessionRefreshing = false;
  bool _autoRotateAfterLoad = false;
  TuitionSessionRecoveryPolicy _sessionRecovery = TuitionSessionRecoveryPolicy();
  String? _connectError;
  bool _liveLoading = false;
  Completer<void>? _payableDone;
  int _payableEpoch = 0;
  String? _liveError;
  DateTime? _lastStatusSync;
  TuitionGatewayApi? _api;
  TuitionPaymentRequest? _activeRequest;
  Timer? _statusPolling;
  // One-shot visual deadline: dim the old QR promptly without POSTing.
  Timer? _qrDeadlineTimer;
  Timer? _expiryReconciliationTimer;
  Timer? _payableRetryTimer;
  int _payableRetryAttempt = 0;
  DateTime? _lastPayableAttempt;
  bool _overviewStatusInFlight = false;
  final Map<String, DateTime> _overviewStatusCheckedAt = <String, DateTime>{};
  // Prevent repeated taps / lifecycle events from flooding the gateway.
  // A GET must finish before another can start.
  static const Duration _payableMinSpacing = Duration(seconds: 3);
  Timer? _countdownTicker;
  final ValueNotifier<DateTime> _countdownNow = ValueNotifier(DateTime.now());
  Map<String,TuitionReceivableState> _receivables = <String,TuitionReceivableState>{};
  Set<String> _unverifiedReceivables = <String>{};
  DateTime? _pausePollingUntil;
  List<TuitionDemoBill> _liveBills = <TuitionDemoBill>[];
  // Distinguish verified rows from carried rows in diagnostic logs and UX.
  int? _lastPayableServerRows;
  final Map<String, String> _existingRequests = <String, String>{};
  bool get _explicitDeveloperPreview =>
      kDebugMode && widget.developerPreview && _api == null;
  List<TuitionDemoBill> get _bills => _mockMode ? _webMock.bills
      : _api != null ? _liveBills
      : (_explicitDeveloperPreview ? _repo.bills : <TuitionDemoBill>[]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Prepare only for the ULIS/payment screen, not for unsupported schools.
    // The loading frame must paint BEFORE mask/printer decoding starts.
    if (_mockMode || widget.universityId == 4 || _explicitDeveloperPreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_prepareEntryScene());
      });
    } else {
      _entryPreparing = false;
    }
    TuitionApiDiagnostics.instance.record('ENTRY', 'TUITION_PREWARM_V21_20261023');
    unawaited(debugAuditTuitionArtworkBundle());
    // Cosmetic timer: payment status changes only via GET /payment-requests/{id}.
    // A ValueNotifier prevents re-rendering the image QR every second.
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isForeground) _countdownNow.value = DateTime.now();
    });
    final session = widget.liveSession;
    if (_mockMode) {
      // No SSO, payment session, CP1 GET, polling, or payment POST on Web.
      TuitionApiDiagnostics.instance.record('ENTRY',
          'FULL_TUITION_VIEW_MOCK_NO_HTTP');
    } else if (widget.universityId != 4) {
      TuitionApiDiagnostics.instance.record('ENTRY',
        _explicitDeveloperPreview ? 'MOCK_EXPLICIT' : 'BLOCKED_NON_ULIS');
    } else if (session != null && session.isValid) {
      _configureApi(session);
      unawaited(_loadLive());
    } else {
      // Show the actual authentication and payable phases on this screen.
      unawaited(_connect(forceRefresh: true));
    }
  }

  Future<void> _prepareEntryScene() async {
    final generation = ++_preparationGeneration;
    final ready = await TuitionScenePreloader.ensureReady(context,
      maximum: TuitionScenePreparationConfig.entryMaxWait);
    if (!mounted || generation != _preparationGeneration) return;
    setState(() => _entryPreparing = false);
    TuitionApiDiagnostics.instance.record('SCENE_WARMUP',
      ready ? 'ENTRY_READY' : 'ENTRY_TIMEOUT',
      note: 'budgetMs=${TuitionScenePreparationConfig.entryMaxWait.inMilliseconds}');
  }

  /// An explicit QR creation gets a short preparation gate. This runs only
  /// on a student tap/first CREATE, never on the 5-second GET status polling.
  /// If assets need more time, the next stage uses a paint-only fallback.
  Future<bool> _prepareQrScene(TuitionDemoBill bill) async {
    if (!mounted || _qrPreparing || _entryPreparing ||
        _printerActive || !identical(_selected, bill)) return false;
    final generation = ++_preparationGeneration;
    final detailEpoch = _detailEpoch;
    setState(() => _qrPreparing = true);
    final ready = await TuitionScenePreloader.ensureReady(context,
      maximum: TuitionScenePreparationConfig.printerMaxWait);
    if (!mounted || generation != _preparationGeneration ||
        detailEpoch != _detailEpoch || !identical(_selected, bill)) {
      return false;
    }
    setState(() {
      _qrPreparing = false;
      _lightweightPrinterAttempt = !ready;
    });
    TuitionApiDiagnostics.instance.record('SCENE_WARMUP',
      ready ? 'PRINTER_READY' : 'PRINTER_TIMEOUT_LIGHTWEIGHT',
      note: 'budgetMs=${TuitionScenePreparationConfig.printerMaxWait.inMilliseconds}');
    return true;
  }

  void _cancelScenePreparation() {
    ++_preparationGeneration;
    _qrPreparing = false;
    _lightweightPrinterAttempt = false;
  }

  void _configureApi(TuitionGatewaySession session) {
    _sessionRecovery = TuitionSessionRecoveryPolicy();
    _autoRotateAfterLoad = false;
    // A refreshed ONEVNU identity must never reuse a filter response
    // fetched under the previous identity.
    ++_serverFilterEpoch;
    _serverFilterIds = null;
    _serverFilterError = null;
    _serverFilterLoading = false;
    _cancelLockAwaitingRelease = false;
    _api = TuitionGatewayApi(session,
      renewSession: () => TuitionGatewaySessionApi().issueForCurrentStudent(
          forceRefresh: true));
    // A fresh widget instance must not forget outstanding QR-locked bills.
    // The cache lives only in RAM and is keyed by the verified gateway student.
    _receivables = TuitionReceivableMemoryCache.instance
        .read(session.canonicalStudentId);
    // An RAM snapshot is informational until this session verifies it again.
    _unverifiedReceivables = _receivables.keys.toSet();
    // Show this canonical student's LAST KNOWN rows immediately on re-entry.
    // They are marked unverified until a new CP1 response confirms them.
    // This allows Back/re-entry to preserve a PENDING QR without re-POSTing.
    _liveBills = _buildBills(_receivables.values);
    _lastPayableServerRows = null;
    _existingRequests
      ..clear()
      ..addAll(<String, String>{
        for (final life in _receivables.values)
          if ((life.activeRequestId ?? life.lastRequestId) != null)
            life.id: (life.activeRequestId ?? life.lastRequestId)!,
      });
  }

  List<TuitionDemoBill> _buildBills(Iterable<TuitionReceivableState> rows) {
    final result = <TuitionDemoBill>[];
    for (final life in rows) {
      final entry = life.source;
      final charges = entry['charges'];
      final first = charges is List && charges.isNotEmpty && charges.first is Map
          ? charges.first as Map : const <String,dynamic>{};
      final name = (first['name'] ?? entry['collectionPeriodName'] ??
          entry['title'] ?? entry['description'] ?? entry['receivableName'] ??
          'Khoản phải thu').toString();
      result.add(TuitionDemoBill(code: life.id, title: name,
        amount: life.displayAmount,
        dueDate: DateTime.tryParse((entry['dueDate'] ??
            entry['expiresAt'])?.toString() ?? ''),
        status: _statusFromReceivable(life.phase),
        isPayable: life.payable,
        periodName: entry['collectionPeriodName']?.toString(),
        termId: entry['termId']?.toString(),
        collectionPeriodCode: entry['collectionPeriodCode']?.toString(),
        chargeCategory: TuitionChargeCategoryResolver.fromReceivable(entry)));
    }
    return result;
  }

  void _rememberBillsInRam() {
    final api = _api;
    if (api == null) return;
    TuitionReceivableMemoryCache.instance.write(
        api.canonicalStudentId, _receivables);
  }

  Future<void> _connect({bool forceRefresh = false}) async {
    if (_connecting || widget.universityId != 4) return;
    setState(() {
      _connecting = true;
      _connectError = null;
      _liveError = null;
    });
    try {
      final session = await TuitionGatewaySessionApi().issueForCurrentStudent(
          forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _configureApi(session);
        _connecting = false;
      });
      await _loadLive();
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _connectError = _sessionError(error.response?.statusCode);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _connectError = 'ONEVNU chưa cấp được phiên thanh toán hợp lệ.';
      });
    }
  }

  /// Both the AppBar Lottie button and the third recoverable PAYABLE miss
  /// use the SAME modal animation. This visual operation never creates QR.
  void _showClearAnimation({required String reason}) {
    if (!mounted || _clearAnimationVisible || !_isForeground) return;
    TuitionApiDiagnostics.instance.record('CLEAR_LOTTIE', 'START', note: reason);
    setState(() => _clearAnimationVisible = true);
  }

  /// Manual button: immediately rotate this device's ULIS session and GET
  /// all receivables. Pull-to-refresh uses the same GET flow silently.
  void _runBroomRefresh() {
    if (!mounted || _clearAnimationVisible || _manualRefreshing ||
        _autoSessionRefreshing || _connecting || _checking ||
        widget.universityId != 4) return;
    _showClearAnimation(reason: 'manual_lottie_button');
    unawaited(_refreshFromServer());
  }

  /// Exactly three consecutive unusable loads trigger one ULIS re-issue.
  /// A rate-limited response and authorization denial are not evidence that
  /// a new token is needed. A successful feed resets the episode.
  void _recordPayableMiss(String reason) {
    final shouldRotate = _sessionRecovery.recordRecoverableMiss();
    TuitionApiDiagnostics.instance.record('PAYABLE_RECOVERY', 'MISS',
      note: 'reason=$reason;count=${_sessionRecovery.consecutiveMisses};'
        'autoRotate=${shouldRotate ? 1 : 0}');
    if (shouldRotate && !_manualRefreshing && !_autoSessionRefreshing &&
        _api != null) {
      // Run only AFTER the current GET's completion barrier is released.
      _autoRotateAfterLoad = true;
    }
  }

  void _recordVerifiedPayable() {
    if (_sessionRecovery.consecutiveMisses > 0) {
      TuitionApiDiagnostics.instance.record('PAYABLE_RECOVERY',
        'VERIFIED_RESET');
    }
    _sessionRecovery.recordVerifiedFeed();
  }

  /// Keeps previous invoices, QR snapshots and idempotency keys; only the
  /// current ULIS student token is rotated. Never rotates ONEVNU login JWT,
  /// never logs credentials, and never POSTs CREATE/RECREATE automatically.
  Future<void> _renewAfterThreeMisses() async {
    final api = _api;
    if (!mounted || api == null || _autoSessionRefreshing ||
        _manualRefreshing || _connecting) return;
    _payableRetryTimer?.cancel();
    _payableRetryTimer = null;
    // V8 bug: the automatic third failure reissued the token but NEVER
    // started clear.json. Show the exact same full-screen animation as a tap.
    _showClearAnimation(reason: 'three_consecutive_payable_misses');
    setState(() => _autoSessionRefreshing = true);
    TuitionApiDiagnostics.instance.record('PAYABLE_RECOVERY',
      'AUTO_SESSION_REFRESH_START', note: 'three_consecutive_misses');
    try {
      final previousStatus = _statusDone;
      if (previousStatus != null) await previousStatus.future;
      if (!mounted || _api != api) return;
      await api.refreshSession();
      if (!mounted || _api != api) return;
      TuitionApiDiagnostics.instance.record('PAYABLE_RECOVERY',
          'AUTO_SESSION_REFRESH_OK');
      await _loadLive(force: true);
      if (mounted && _selected != null && _activeRequest != null &&
          _api == api) {
        await _checkStatus(silent: true, force: true);
      }
    } on TuitionGatewayIdentityMismatchException {
      if (mounted) _invalidateIdentity();
    } on DioException catch (error) {
      TuitionApiDiagnostics.instance.record('PAYABLE_RECOVERY',
        'AUTO_SESSION_REFRESH_FAILED', statusCode: error.response?.statusCode);
      if (mounted && _selected == null && error.response?.statusCode != 403) {
        _schedulePayableRetry();
      }
    } catch (_) {
      TuitionApiDiagnostics.instance.record('PAYABLE_RECOVERY',
        'AUTO_SESSION_REFRESH_FAILED', note: 'session_or_client_error');
      if (mounted && _selected == null) _schedulePayableRetry();
    } finally {
      if (mounted) setState(() => _autoSessionRefreshing = false);
    }
  }

  void _invalidateIdentity() {
    if (!mounted) return;
    _stopPolling();
    _cancelScenePreparation();
    ++_detailEpoch;
    ++_payableEpoch;
    setState(() {
      _api = null;
      _selected = null;
      _activeRequest = null;
      _printerActive = false;
      _printerOldReceipt = null;
      _receivables = <String, TuitionReceivableState>{};
      _liveBills = <TuitionDemoBill>[];
      _lastPayableServerRows = null;
      _existingRequests.clear();
      _unverifiedReceivables = <String>{};
      _sessionRecovery = TuitionSessionRecoveryPolicy();
      _autoRotateAfterLoad = false;
      ++_serverFilterEpoch;
      _serverFilterIds = null;
      _serverFilterLoading = false;
      _serverFilterError = null;
      _selectedTermId = null;
      _selectedPeriodCode = null;
      _canCreateOnly = false;
      _financeFilter = '';
      _qrStatusFilter = '';
      _cancelLockAwaitingRelease = false;
      _searchController.clear();
      _connectError = 'Tài khoản đã thay đổi. Hãy tải lại phiên.';
      _liveError = _connectError;
    });
    TuitionApiDiagnostics.instance.record('PAGE_REFRESH',
        'STUDENT_IDENTITY_CHANGED');
  }

  /// Manual pull-to-refresh / app-bar reload: issue a NEW payment session,
  /// then read the entire receivable feed. GET status for an open detail too.
  /// Never POST a payment request from a refresh action.
  Future<void> _refreshFromServer() async {
    if (_mockMode) {
      // Same RefreshIndicator and real cards; refresh is local, read-only.
      if (mounted) setState(() => ++_listWaveGeneration);
      return;
    }
    if (!mounted || widget.universityId != 4 ||
        _manualRefreshing || _autoSessionRefreshing ||
        _connecting || _checking) return;
    if (_selected != null) _stopPolling();
    _payableRetryTimer?.cancel();
    _payableRetryTimer = null;
    _autoRotateAfterLoad = false;
    setState(() => _manualRefreshing = true);
    TuitionApiDiagnostics.instance.record('PAGE_REFRESH', 'START',
        note: 'force_new_ulis_session');
    try {
      // Serialize session rotation with the old payable GET so an old
      // response can never overwrite data fetched with the new token.
      final previousLoad = _payableDone;
      if (previousLoad != null) await previousLoad.future;
      final previousStatus = _statusDone;
      if (previousStatus != null) await previousStatus.future;
      if (!mounted) return;
      final selected = _selected;
      final previousRequestId = selected == null ? null :
          (_activeRequest?.id ?? _existingRequests[selected.code] ??
              _life(selected)?.activeRequestId);
      final api = _api;
      if (api == null) {
        final session = await TuitionGatewaySessionApi()
            .issueForCurrentStudent(forceRefresh: true);
        if (!mounted) return;
        setState(() => _configureApi(session));
      } else {
        // Preserves payment request identity, QR snapshot and idempotency
        // keys. Rotates only the student-scoped ULIS access token.
        await api.refreshSession();
      }
      if (!mounted) return;
      _sessionRecovery.recordManualRotation();
      setState(() {
        _connectError = null;
        _payableRetryAttempt = 0;
      });
      await _loadLive(force: true);
      if (!mounted) return;
      // A payable reload is sufficient for the overview; in a detail screen,
      // also GET the payment request using the new session.
      if (_selected != null && _api != null) {
        if (_activeRequest != null) {
          await _checkStatus(silent: true, force: true);
        } else if (previousRequestId != null && previousRequestId.isNotEmpty &&
            identical(_selected, selected)) {
          await _restoreExistingRequest(selected!, previousRequestId);
        }
      }
      final refreshOutcome = _lastPayableServerRows == 0 &&
              _liveBills.isNotEmpty
          ? 'COMPLETE_WITH_CARRIED_ROWS'
          : _liveError != null ? 'COMPLETE_PARTIAL'
          : _lastPayableServerRows == 0 ? 'COMPLETE_EMPTY'
          : _unverifiedReceivables.isNotEmpty
              ? 'COMPLETE_PARTIAL' : 'COMPLETE_WITH_ROWS';
      TuitionApiDiagnostics.instance.record('PAGE_REFRESH', refreshOutcome,
          note: 'session_then_payable;server=${_lastPayableServerRows ?? -1};'
              'visible=${_liveBills.length};unverified=${_unverifiedReceivables.length}');
    } on TuitionGatewayIdentityMismatchException {
      _invalidateIdentity();
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _connectError = _api == null
            ? _sessionError(error.response?.statusCode) : null;
        _liveError = _api == null ? _connectError
            : _sessionError(error.response?.statusCode);
        _unverifiedReceivables = _receivables.keys.toSet();
      });
      TuitionApiDiagnostics.instance.record('PAGE_REFRESH', 'FAILED',
          statusCode: error.response?.statusCode);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liveError = 'Ch\u01b0a c\u1ea5p l\u1ea1i \u0111\u01b0\u1ee3c phi\u00ean thanh to\u00e1n. H\u00e3y th\u1eed l\u1ea1i.';
        _unverifiedReceivables = _receivables.keys.toSet();
      });
      TuitionApiDiagnostics.instance.record('PAGE_REFRESH', 'FAILED',
          note: 'session_or_client_error');
    } finally {
      if (mounted) {
        setState(() => _manualRefreshing = false);
        if (_selected != null) {
          _startPolling();
          _scheduleExpiryReconciliation();
        }
      }
    }
  }

  String _sessionError(int? status) {
    switch (status) {
      case 401: return 'Phiên ONEVNU đã hết hạn. Vui lòng đăng nhập lại.';
      case 403: return 'Tài khoản chưa được cấp quyền thanh toán học phí ULIS.';
      case 404: return 'Backend ONEVNU chưa có API /api/ulis-tuition/session.';
      case 502: return 'ONEVNU không lấy được token từ cổng học phí.';
      case 503: return 'Dịch vụ cấp phiên học phí đang tạm gián đoạn.';
      default: return 'Không kết nối được hệ thống học phí. Vui lòng thử lại.';
    }
  }

  @override
  void dispose() {
    ++_serverFilterEpoch;
    _searchDebounce?.cancel();
    _searchController.dispose();
    ++_preparationGeneration;
    _stopPolling();
    _qrDeadlineTimer?.cancel();
    _payableRetryTimer?.cancel();
    _countdownTicker?.cancel();
    _countdownNow.dispose();
    _mockDetailScroll.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (!_isForeground) {
      _stopPolling();
      _payableRetryTimer?.cancel();
    } else {
      // Recalculate the local QR deadline after resuming from background.
      if (mounted && _selected != null) setState(() {});
      if (_selected != null && _activeRequest != null && !_activeRequest!.terminal) {
        unawaited(_checkStatus(silent:true));
      } else if (_selected != null && _activeRequest != null &&
          const <String>{'EXPIRED','CANCELLED'}
              .contains(_activeRequest!.status.toUpperCase())) {
        unawaited(_loadLive(force: true));
      }
      _startPolling();
      _scheduleExpiryReconciliation();
      // A cancelled retry timer must never strand an empty page after the
      // app returns from background. Refresh even with no RAM snapshot.
      if (_selected == null && _api != null && !_liveLoading) {
        unawaited(_loadLive());
      }
    }
  }

  TuitionPaymentStatus _fromStatus(String status) {
    switch (status.trim().toUpperCase()) {
      case 'PROCESSING': return TuitionPaymentStatus.processing;
      case 'PAID': return TuitionPaymentStatus.paid;
      case 'EXPIRED': return TuitionPaymentStatus.expired;
      case 'CANCELLED': return TuitionPaymentStatus.cancelled;
      default: return TuitionPaymentStatus.pending;
    }
  }

  TuitionPaymentStatus _statusFromReceivable(TuitionReceivablePhase phase) =>
    switch (phase) {
      TuitionReceivablePhase.processing => TuitionPaymentStatus.processing,
      TuitionReceivablePhase.paid => TuitionPaymentStatus.paid,
      TuitionReceivablePhase.qrExpired => TuitionPaymentStatus.expired,
      TuitionReceivablePhase.cancelled => TuitionPaymentStatus.cancelled,
      _ => TuitionPaymentStatus.pending,
    };

  TuitionReceivableState? _life(TuitionDemoBill bill) => _receivables[bill.code];

  void _recordGatewayRequest(TuitionDemoBill bill, TuitionPaymentRequest request) {
    _existingRequests[bill.code] = request.id;
    final life = _life(bill);
    if (life != null) {
      _receivables = <String,TuitionReceivableState>{..._receivables,
        bill.code: life.withGatewayRequest(
          requestId: request.id, status: request.status,
          expiresAt: request.expiresAt, qrPayload: request.payload,
          qrImageBase64: request.imageBase64,
        ),
      };
    }
    bill.status = _receivables[bill.code] == null
        ? _fromStatus(request.status)
        : _statusFromReceivable(_receivables[bill.code]!.phase);
    bill.processedAt = request.updatedAt;
    _rememberBillsInRam();
  }

  String _timeRemaining(DateTime end, [DateTime? now]) {
    final remaining = end.difference(now ?? DateTime.now());
    if (remaining.inSeconds <= 0) {
      // Local time only controls the dim/retry UI, never payment state/POST.
      return '00:00';
    }
    final seconds = remaining.inSeconds;
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }

  Widget _remainingChip(DateTime expiresAt, {bool dark = false}) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: _countdownNow,
      builder: (context, now, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFFFFF0D3) : const Color(0xFFFCEFD6),
          borderRadius: BorderRadius.circular(12)),
        child: Text(_timeRemaining(expiresAt, now),
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: TextStyles.fontName,
            fontSize: 10, fontWeight: FontWeight.w700,
            color: Color(0xFF9D5C0B), height: 1.05)),
      ),
    );
  }

  Future<void> _loadLive({bool force = false}) async {
    // Automatic retry / foreground GET must never race a forced re-auth.
    if ((_manualRefreshing || _autoSessionRefreshing) && !force) return;
    if (_liveLoading) {
      if (!force) return;
      final pending = _payableDone;
      if (pending != null) await pending.future;
      if (!mounted) return;
    }
    final api = _api;
    if (api == null) return;
    final now = DateTime.now();
    final last = _lastPayableAttempt;
    if (!force && last != null &&
        now.difference(last) < _payableMinSpacing) {
      // Schedule a trailing GET rather than discard the refresh request.
      // This also fixes a quick back/resume leaving the page permanently
      // stale after the foreground retry timer was cancelled.
      final remaining = _payableMinSpacing - now.difference(last);
      _payableRetryTimer?.cancel();
      _payableRetryTimer = Timer(remaining + const Duration(milliseconds: 50), () {
        if (mounted && _isForeground && !_liveLoading && _api != null) {
          unawaited(_loadLive());
        }
      });
      TuitionApiDiagnostics.instance.record('PAYABLE_RETRY', 'THROTTLED',
        note:'delayed_ms=${remaining.inMilliseconds}');
      return;
    }
    _lastPayableAttempt = now;
    _payableRetryTimer?.cancel();
    _payableRetryTimer = null;
    final epoch = ++_payableEpoch;
    final done = Completer<void>();
    _payableDone = done;
    // Preserve an inconclusive-feed message while a background GET retries,
    // instead of flashing between error artwork and the loading spinner.
    setState(() { _liveLoading = true; });
    try {
      // On EVERY reload fetch all receivables, including payable=false/locked.
      final data = await api.payableAll(payableOnly: false);
      if (!mounted || epoch != _payableEpoch) return;
      final result = TuitionPayableReconciliation.reconcile(
        incoming: data, previous: _receivables);
      final states = result.states;
      // IMPORTANT: zero rows in a NEW GET must not wipe a known receivable.
      // A PENDING payment often changes payable=true -> false and may be
      // temporarily omitted by a buggy gateway despite payableOnly=false.
      // Carry forward the last known rows (with unverifiedIds safeguards).
      // If we have NEVER seen any receivable, the overview remains empty.
      final bills = _buildBills(result.visibleRows);
      final requestIds = <String, String>{
        for (final life in states.values)
          if ((life.activeRequestId ?? life.lastRequestId) != null)
            life.id: (life.activeRequestId ?? life.lastRequestId)!,
      };
      for (final life in states.values) {
        final active = life.activePaymentRequest;
        if (active != null) {
          try {
            api.rememberActiveRequest(active);
          } catch (_) {
            TuitionApiDiagnostics.instance.record('PAYABLE_MAPPING',
              'ACTIVE_SNAPSHOT_INVALID');
          }
        }
        // Historical QR is stored separately from active locks. Its
        // paymentRequestId lets a second device GET the SAME old request.
        final last = life.lastPaymentRequest;
        if (last != null && life.lastRequestId != null &&
            const <String>{'EXPIRED','CANCELLED','PAID'}.contains(
              (last['status'] ?? '').toString().toUpperCase())) {
          try {
            api.rememberHistoricalRequest(last);
          } catch (_) {
            TuitionApiDiagnostics.instance.record('PAYABLE_MAPPING',
              'HISTORY_SNAPSHOT_INVALID');
          }
        }
      }
      setState(() {
        // Replay the wave for a first verified feed, a changed bill set,
        // or a user-initiated refresh; never for a routine status poll.
        if (result.serverRows > 0 && _selected == null &&
            (_liveBills.isEmpty || _manualRefreshing ||
             !listEquals(_liveBills.map((b) => b.code).toList(),
               bills.map((b) => b.code).toList()))) {
          _listWaveGeneration++;
        }
        _liveBills = bills;
        _lastPayableServerRows = result.serverRows;
        _receivables = states;
        _unverifiedReceivables = result.unverifiedIds;
        _liveError = null;
        if (result.invalidRows > 0) {
          _liveError = 'Một số khoản thu chưa đủ dữ liệu. Đang đồng bộ lại.';
        } else if (result.serverRows == 0 && states.isNotEmpty) {
          _liveError = 'Cổng thanh toán tạm thời chưa trả đầy đủ khoản thu. '
              'Đang hiển thị các khoản được xác nhận gần nhất; '
              'không thể tạo giao dịch mới trước khi đồng bộ.';
        } else if (result.serverRows == 0 && states.isEmpty) {
          _liveError = 'Danh sách khoản thu tạm thời chưa có dữ liệu. '
              'Đang tự đồng bộ lại.';
        }
        _existingRequests
          ..clear()
          ..addAll(requestIds);
        _liveLoading = false;
      });
      _rememberBillsInRam();
      // Keep a selected CP1 server filter synchronized on explicit reload.
      // Background status polling uses its existing GET without doubling
      // every request through the filtered endpoint.
      if (_cancelLockAwaitingRelease && _selected != null &&
          result.serverRows > 0 &&
          !result.unverifiedIds.contains(_selected!.code)) {
        final latest = states[_selected!.code];
        if (latest != null && latest.payable && !latest.hasActiveLock) {
          _cancelLockAwaitingRelease = false;
        }
      }
      if (_selected == null && _manualRefreshing &&
          _hasBackendStudentFilters) {
        unawaited(_refreshServerFilters());
      }
      // A list-only session must also observe expiry; the detail polling
      // stops on Back. The list GET may lag behind payment request status.
      if (_selected == null) unawaited(_syncOverviewRequestStatuses());
      TuitionApiDiagnostics.instance.record('PAYABLE_MAPPING', 'OK',
        note: 'server=${result.serverRows};visible=${bills.length};'
          'carried=${result.retainedCount};invalid=${result.invalidRows};'
          'reused=${result.reusedAmounts};payableOnly=false');
      final feedEmpty = result.serverRows == 0;
      if (feedEmpty || result.invalidRows > 0 ||
          result.retainedCount > 0 || result.reusedAmounts > 0) {
        _recordPayableMiss(feedEmpty ? 'empty_gateway_feed' :
            'partial_gateway_feed');
      } else {
        _recordVerifiedPayable();
      }
      final needsLifecycleSync = states.values.any((row) =>
          row.hasDebt && <TuitionReceivablePhase>{
            TuitionReceivablePhase.waitingPayment,
            TuitionReceivablePhase.processing,
            TuitionReceivablePhase.qrExpired,
            TuitionReceivablePhase.cancelled,
          }.contains(row.phase));
      if (result.retainedCount > 0 || result.invalidRows > 0 ||
          result.reusedAmounts > 0 || feedEmpty) {
        TuitionApiDiagnostics.instance.record('PAYABLE_MAPPING',
          'INCOMPLETE_RESPONSE', note: feedEmpty
            ? (states.isEmpty ? 'empty_gateway_feed' : 'keeping_last_known_rows')
            : 'partial_gateway_feed');
        _schedulePayableRetry();
      } else if (needsLifecycleSync) {
        // While the list is visible, read the server periodically so an
        // expired/released QR updates from 'Mã đã hết hạn' to 'Chờ thanh toán'
        // WITHOUT needing Back or a manual reload. GET only, no POST.
        _payableRetryAttempt = 0;
        _schedulePayableRetry(minDelaySeconds: 20);
      } else {
        _payableRetryAttempt = 0;
      }
      // `_selected` can be a previous UI object even after feed reconcile.
      // Its immutable amount is shown from _life in the detail renderer.
      final showing = _selected;
      if (showing != null) {
        final state = states[showing.code];
        if (state != null && mounted) {
          showing.status = _statusFromReceivable(state.phase);
        }
      }
    } on TuitionGatewayIdentityMismatchException {
      if (mounted && epoch == _payableEpoch) _invalidateIdentity();
    } on FormatException catch (_) {
      if (mounted && epoch == _payableEpoch) {
        setState(() {
          _liveLoading = false;
          _unverifiedReceivables = _receivables.keys.toSet();
          _liveError = 'Gateway trả HTTP 200 nhưng dữ liệu khoản thu sai định dạng. Hệ thống đang tự thử lại.';
        });
        TuitionApiDiagnostics.instance.record(
          'PAYABLE_MAPPING', 'SCHEMA_ERROR');
        _recordPayableMiss('schema_error');
        _schedulePayableRetry();
      }
    } on DioException catch (error) {
      if (mounted && epoch == _payableEpoch) {
        setState(() {
          _liveLoading = false;
          _unverifiedReceivables = _receivables.keys.toSet();
          _liveError = error.response?.statusCode == 403
            ? 'Không có quyền xem các khoản thu này.'
            : 'Không tải được khoản thu mới. Đang giữ dữ liệu gần nhất.';
        });
        final status = error.response?.statusCode;
        if (status != 403 && status != 429) {
          _recordPayableMiss('http_or_transport');
        }
        if (status != 403) {
          // Respect numeric Retry-After on HTTP 429; never POST from a retry.
          final retryAfter = error.response?.statusCode == 429
              ? int.tryParse(error.response?.headers.value('retry-after') ?? '')
              : null;
          _schedulePayableRetry(minDelaySeconds: retryAfter);
        }
      }
    } catch (_) {
      if (mounted && epoch == _payableEpoch) {
        setState(() {
          _liveLoading = false;
          _unverifiedReceivables = _receivables.keys.toSet();
          _liveError = 'Chưa thể đồng bộ danh sách. Đang giữ dữ liệu gần nhất.';
        });
        _recordPayableMiss('client_error');
        _schedulePayableRetry();
      }
    } finally {
      if (identical(_payableDone, done)) _payableDone = null;
      if (!done.isCompleted) done.complete();
      if (_autoRotateAfterLoad && mounted && !_manualRefreshing &&
          !_autoSessionRefreshing) {
        _autoRotateAfterLoad = false;
        unawaited(_renewAfterThreeMisses());
      }
    }
  }

  /// Read-only request-status reconciliation on the overview. A backend
  /// PAYABLE snapshot may still advertise PENDING AFTER the QR expired.
  /// Only GET /payment-requests/{id} is allowed to confirm its terminal state.
  /// Never issue POST while observing a list on another device.
  Future<void> _syncOverviewRequestStatuses() async {
    if (_overviewStatusInFlight || !mounted || !_isForeground ||
        _selected != null || _manualRefreshing ||
        _autoSessionRefreshing || _api == null) return;
    final api = _api!;
    final now = DateTime.now();
    final candidates = _receivables.values.where((life) {
      final status = life.activeStatus;
      final shouldRead = status == 'PROCESSING' ||
          (status == 'PENDING' && life.activeExpiresAt != null &&
           !life.activeExpiresAt!.isAfter(now));
      final last = life.activeRequestId == null ? null
          : _overviewStatusCheckedAt[life.activeRequestId!];
      return life.hasDebt && life.activeRequestId != null && shouldRead &&
          (last == null || now.difference(last) > const Duration(seconds: 20));
    }).take(3).toList();
    if (candidates.isEmpty) return;
    _overviewStatusInFlight = true;
    try {
      for (final initial in candidates) {
        if (!mounted || !_isForeground || _selected != null ||
            _manualRefreshing || _api != api) break;
        final id = initial.activeRequestId!;
        _overviewStatusCheckedAt[id] = DateTime.now();
        try {
          final latest = await api.status(id);
          if (!mounted || _selected != null || _api != api) break;
          final current = _receivables[initial.id];
          if (current == null || current.activeRequestId != id) continue;
          if (latest.status.toUpperCase() != current.activeStatus) {
            setState(() {
              final updated = current.withGatewayRequest(
                requestId: latest.id, status: latest.status,
                expiresAt: latest.expiresAt, qrPayload: latest.payload,
                qrImageBase64: latest.imageBase64);
              _receivables = <String, TuitionReceivableState>{
                ..._receivables, current.id: updated,
              };
              _liveBills = _buildBills(_receivables.values);
              _existingRequests[current.id] = latest.id;
            });
            _rememberBillsInRam();
            TuitionApiDiagnostics.instance.record('LIST_REQUEST_STATUS',
              latest.status.toUpperCase());
            if (latest.terminal) {
              // Re-read receivable's lock/outstanding after observing the
              // terminal request, then keep GET-ing if still unavailable.
              unawaited(_loadLive(force: true));
            }
          }
        } on DioException catch (error) {
          final retryAfter = error.response?.statusCode == 429
              ? int.tryParse(error.response?.headers.value('retry-after') ?? '')
              : null;
          if (retryAfter != null) {
            _overviewStatusCheckedAt[id] = DateTime.now()
                .add(Duration(seconds: retryAfter.clamp(0, 120).toInt()));
          }
          TuitionApiDiagnostics.instance.record('LIST_REQUEST_STATUS',
              'GET_FAILED', statusCode: error.response?.statusCode);
        } catch (_) {
          TuitionApiDiagnostics.instance.record('LIST_REQUEST_STATUS',
              'GET_FAILED');
        }
      }
    } finally {
      _overviewStatusInFlight = false;
    }
  }

  /// Continuous but rate-limited recovery while the list is on screen.
  /// Backoff: 5, 10, 20, 40, 60s; stays at 60s until valid data arrives.
  /// Never runs when app is backgrounded, on the detail screen or after 403.
  /// This calls GET only. Never CREATE / RECREATE payment requests.
  void _schedulePayableRetry({int? minDelaySeconds}) {
    _payableRetryTimer?.cancel();
    if (!mounted || !_isForeground || _selected != null || _api == null) return;
    const intervals = <int>[5, 10, 20, 40, 60];
    final seconds = math.max(
      intervals[_payableRetryAttempt.clamp(0, intervals.length-1).toInt()],
      (minDelaySeconds ?? 0).clamp(0, 120).toInt());
    _payableRetryAttempt = math.min(_payableRetryAttempt+1, intervals.length-1);
    TuitionApiDiagnostics.instance.record('PAYABLE_RETRY', 'SCHEDULED',
      note:'after=${seconds}s;step=$_payableRetryAttempt');
    _payableRetryTimer = Timer(Duration(seconds: seconds), () {
      if (mounted && _isForeground && _selected == null &&
          !_liveLoading && !_autoSessionRefreshing) {
        unawaited(_loadLive());
      }
    });
  }

  void _stopPolling() {
    _statusPolling?.cancel();
    _statusPolling = null;
    _qrDeadlineTimer?.cancel();
    _qrDeadlineTimer = null;
    _expiryReconciliationTimer?.cancel();
    _expiryReconciliationTimer = null;
  }

  /// An expired QR is *history*, while the payable/lock state can take
  /// seconds to become available again. Reconcile in the open detail as well
  /// as the overview until CP1 confirms a released lock or settled balance.
  /// This is a read-only GET and never issues a new payment request.
  void _scheduleExpiryReconciliation() {
    _expiryReconciliationTimer?.cancel();
    _expiryReconciliationTimer = null;
    final bill = _selected;
    final request = _activeRequest;
    if (!mounted || !_isForeground || _api == null || bill == null ||
        request == null ||
        !const <String>{'EXPIRED','CANCELLED'}
            .contains(request.status.toUpperCase())) return;
    final life = _life(bill);
    if (life?.isSettled == true ||
        (life?.releasedAfterExpiry == true &&
         !_unverifiedReceivables.contains(bill.code))) return;
    _expiryReconciliationTimer = Timer(const Duration(seconds: 12), () async {
      if (!mounted || !_isForeground || _selected?.code != bill.code) return;
      await _loadLive(force: true);
      if (mounted && _selected?.code == bill.code) {
        _scheduleExpiryReconciliation();
      }
    });
  }

  /// The phone clock is only a VISUAL deadline; the gateway is authoritative.
  /// This timer never creates payment requests. When elapsed, blur the old QR,
  /// make the refresh affordance visible, and ask the gateway for the status.
  void _scheduleQrDeadline() {
    _qrDeadlineTimer?.cancel();
    _qrDeadlineTimer = null;
    final request = _activeRequest;
    if (!mounted || !_isForeground || request == null ||
        request.status.toUpperCase() != 'PENDING' ||
        request.expiresAt == null) return;
    final wait = request.expiresAt!.difference(DateTime.now());
    if (wait <= Duration.zero) return; // Already dimmed on next build.
    _qrDeadlineTimer = Timer(wait, () {
      if (!mounted || !_isForeground || _selected == null ||
          _activeRequest?.id != request.id) return;
      setState(() {}); // Trigger expiry overlay without reissuing the QR.
      unawaited(_checkStatus(silent: true, force: true));
    });
  }

  /// Never issue overlapping GET status calls. Resume every 5 s after the
  /// latest request, and respect 429 Retry-After from the provider.
  void _startPolling() {
    _stopPolling();
    if (_mockMode) return; // Mock QR never polls a real server.
    final request = _activeRequest;
    if (!_isForeground || _selected == null || _api == null ||
        request == null || request.terminal) return;
    _scheduleQrDeadline();
    _statusPolling = Timer.periodic(const Duration(seconds: 5), (_) {
      final pause = _pausePollingUntil;
      if (mounted && _isForeground && !_checking && !_statusRequestInFlight &&
          (pause == null || !DateTime.now().isBefore(pause))) {
        unawaited(_checkStatus(silent: true));
      }
    });
  }

  Future<void> _createOrRecreate() async {
    if (_mockMode) {
      await _mockCreateOrRecreate();
      return;
    }
    final api = _api;
    final bill = _selected;
    if (_checking || _qrPreparing || _entryPreparing ||
        _manualRefreshing || _autoSessionRefreshing || _connecting ||
        api == null || bill == null ||
        bill.status == TuitionPaymentStatus.paid ||
        _activeRequest?.status.toUpperCase() == 'PAID') return;

    final requestBefore = _activeRequest;
    final canRecreate = requestBefore != null &&
        const <String>{'EXPIRED', 'CANCELLED'}.contains(requestBefore.status.toUpperCase());
    // One active QR -> ONE request. Never issue another POST while pending
    // or processing; payable=false simply means the receivable is locked.
    if (requestBefore != null && !canRecreate) return;
    if (canRecreate) {
      await _reloadExpiredQr(); // Server confirms expiry before RECREATE.
      return;
    }
    final life = _life(bill);
    if (_unverifiedReceivables.contains(bill.code)) {
      setState(() => _detailError =
        'Chưa thể tạo mã thanh toán mới. Vui lòng tải lại sau ít phút.');
      return;
    }
    if (!canRecreate && !(life?.canCreate ?? (bill.isPayable && bill.amount > 0))) {
      return;
    }

    final epoch = _detailEpoch;
    if (!await _prepareQrScene(bill)) return;
    if (!mounted || epoch != _detailEpoch || !identical(_selected, bill)) return;
    // First-time CREATE uses the same V16 physical-feed effect as RECREATE.
    // This is a visual action only: it never sends another POST or changes
    // idempotency. The skeleton does not contain an unconfirmed QR.
    _beginQrPrinter(bill);
    setState(() {
      _checking = true;
      _detailError = null;
    });
    try {
      final request = canRecreate
          ? await api.recreate(requestBefore!.id)
          : await api.create(bill.code);
      if (!mounted || epoch != _detailEpoch || !identical(_selected, bill)) return;
      setState(() {
        _activeRequest = request;
        _recordGatewayRequest(bill, request);
        _lastStatusSync = DateTime.now();
        _pausePollingUntil = null;
      });
      _resolveQrPrinter(true); // Only after CREATE returns a server QR.
      _startPolling();
    } on DioException catch (error) {
      _resolveQrPrinter(false);
      if (!mounted || epoch != _detailEpoch) return;
      setState(() => _detailError = switch (error.response?.statusCode) {
        401 => 'Phiên thanh toán đã hết hạn. Nhấn thử lại để kết nối lại.',
        403 => 'Tài khoản hiện không được phép tạo yêu cầu thanh toán này.',
        409 => 'Đã có một yêu cầu thanh toán khác. Hãy làm mới để xem trạng thái.',
        _ => 'Chưa tạo được mã QR. Vui lòng thử lại sau ít phút.',
      });
    } catch (_) {
      _resolveQrPrinter(false);
      if (mounted && epoch == _detailEpoch) {
        setState(() => _detailError = 'Không tạo được mã QR. Vui lòng thử lại.');
      }
    } finally {
      if (mounted && epoch == _detailEpoch) {
        setState(() => _checking = false);
      }
    }
  }

  /// A long ticket is naturally scrollable. Never scroll to its BOTTOM to
  /// start a printer animation: that hid the heading/QR on 440x956 devices
  /// and forced a tall document into the transition. The visual stage itself
  /// clamps its preview to the visible viewport without changing scroll.
  void _positionMockDetailForPrint() { /* Keep the user's scroll position. */ }

  /// Production widget tree + simulated backend result. Never accesses Dio,
  /// a ONEVNU session, or CP1. The SAME printer overlay as production starts
  /// before the fake response, and the old QR survives a simulated failure.
  Future<void> _mockCreateOrRecreate() async {
    final bill = _selected;
    if (!_mockMode || !mounted || bill == null || _checking ||
        _entryPreparing || _qrPreparing || _printerActive) {
      return;
    }
    final before = _webMock.requestFor(bill.code);
    if (before != null && !before.terminal) return;
    final epoch = _detailEpoch;
    if (!await _prepareQrScene(bill)) return;
    if (!mounted || epoch != _detailEpoch || !identical(_selected, bill)) return;
    _positionMockDetailForPrint();
    _beginQrPrinter(bill);
    setState(() {
      _checking = true;
      _detailError = null;
    });
    try {
      final request = await _webMock.createOrRecreate(bill.code);
      if (!mounted || epoch != _detailEpoch || !identical(_selected, bill)) {
        return;
      }
      setState(() {
        _activeRequest = request;
        _lastStatusSync = DateTime.now();
      });
      _resolveQrPrinter(true);
    } catch (_) {
      if (!mounted || epoch != _detailEpoch) return;
      // The previous QR remains untouched, including its ID and payload.
      setState(() {
        _activeRequest = before;
        _detailError = 'Mô phỏng: không tạo được mã mới. Mã cũ vẫn được giữ.';
      });
      _resolveQrPrinter(false);
    } finally {
      if (mounted && epoch == _detailEpoch) {
        setState(() => _checking = false);
      }
    }
  }

  void _showTuitionNotice(String message,
      {VcoreNoticeTone tone = VcoreNoticeTone.info}) {
    if (!mounted) return;
    showVcoreNotice(
      context: context,
      title: switch (tone) {
        VcoreNoticeTone.success => 'Thành công',
        VcoreNoticeTone.warning => 'Lưu ý',
        VcoreNoticeTone.error => 'Lỗi',
        VcoreNoticeTone.info => 'Thông báo',
      },
      message: message,
      tone: tone,
    );
  }

  void _mockMenuAction(String action) {
    if (!_mockMode || !mounted) return;
    if (action == 'fail') {
      _webMock.failNextCreate = true;
      _showTuitionNotice('MOCK: lượt tạo QR tiếp theo sẽ thất bại.');
    } else if (action == 'success') {
      _webMock.failNextCreate = false;
      _showTuitionNotice('MOCK: lượt tạo QR tiếp theo sẽ thành công.');
    } else if (action == 'slow') {
      _webMock.responseDelay = const Duration(seconds: 4);
    } else if (action == 'fast') {
      _webMock.responseDelay = const Duration(milliseconds: 1400);
    } else if (action == 'mark_paid') {
      final bill=_selected;
      if (bill!=null && !_checking && !_printerActive) {
        _webMock.markPaid(bill.code);
        setState(() => _activeRequest=_webMock.requestFor(bill.code));
      }
    } else if (action == 'expire' || action == 'clear_qr') {
      final bill = _selected;
      if (bill != null && !_checking && !_printerActive) {
        if (action == 'expire') {
          _webMock.expire(bill.code);
        } else {
          _webMock.clearRequest(bill.code);
        }
        setState(() => _activeRequest = _webMock.requestFor(bill.code));
      }
    } else if (action == 'reset') {
      _stopPolling();
      ++_detailEpoch;
      _cancelScenePreparation();
      _webMock.reset();
      setState(() {
        _selected = null;
        _activeRequest = null;
        _detailError = null;
        _checking = false;
        _printerActive = false;
        _printerOldReceipt = null;
        _printerOutcome = TuitionPrintOutcome.waitingForGateway;
        ++_listWaveGeneration;
      });
    }
  }

  /// Save the old paper BEFORE a gateway GET can update its request. The
  /// foreground stage covers the viewport below AppBar, not the ListView.
  /// Used for user-started CREATE and RECREATE; NEVER status polling/refresh.
  void _beginQrPrinter(TuitionDemoBill bill) {
    if (!mounted || _printerActive) return;
    final oldRequest = _activeRequest;
    final frozenReceipt = _detailTicketPaper(bill, snapshot: oldRequest);
    setState(() {
      _printerOldReceipt = frozenReceipt;
      _printerActive = true;
      _printerOutcome = TuitionPrintOutcome.waitingForGateway;
      ++_printerAttemptSerial;
    });
    TuitionApiDiagnostics.instance.record('QR_PRINTER', 'START',
        note: 'before_create_or_recreate;visual_only;paper_speed=1.25');
  }

  void _resolveQrPrinter(bool success) {
    if (!mounted || !_printerActive) return;
    setState(() => _printerOutcome = success
        ? TuitionPrintOutcome.succeeded : TuitionPrintOutcome.failed);
    TuitionApiDiagnostics.instance.record('QR_PRINTER',
        success ? 'NEW_QR_CONFIRMED' : 'RESTORE_OLD_RECEIPT');
  }

  void _printerAnimationFinished() {
    if (!mounted || !_printerActive) return;
    setState(() {
      _printerActive = false;
      _printerOldReceipt = null;
      _printerOutcome = TuitionPrintOutcome.waitingForGateway;
    });
    TuitionApiDiagnostics.instance.record('QR_PRINTER', 'COMPLETE');
  }

  Rect? _measuredTicketInDetailBody() {
    final viewport = _detailPrinterLayerKey.currentContext?.findRenderObject();
    final paper = _detailTicketTargetKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || paper is! RenderBox ||
        !viewport.hasSize || !paper.hasSize) return null;
    try {
      final origin = paper.localToGlobal(Offset.zero, ancestor: viewport);
      return origin & paper.size;
    } catch (_) {
      return null;
    }
  }

  /// A locally expired QR can show Reload immediately, but a new payment
  /// request must ONLY be posted if GET confirms EXPIRED/CANCELLED upstream.
  /// When gateway still says PENDING/PROCESSING, keep the old request and
  /// continue polling; do not let repeated taps create duplicate payments.
  Future<void> _reloadExpiredQr() async {
    if (_mockMode) {
      await _mockCreateOrRecreate();
      return;
    }
    final api = _api;
    final bill = _selected;
    final old = _activeRequest;
    if (api == null || bill == null || old == null || _checking ||
        _qrPreparing || _entryPreparing || _printerActive ||
        _manualRefreshing || _autoSessionRefreshing ||
        (_life(bill)?.isSettled ?? false) ||
        _cancelLockAwaitingRelease) return;
    // This is NOT a generic CREATE. GET must first confirm the old request
    // is EXPIRED/CANCELLED. Backend RECREATE must atomically re-check the
    // outstanding amount, active lock and idempotency. An empty PAYABLE feed
    // cannot independently authorize OR block this server-validated action.
    final epoch = _detailEpoch;
    if (!await _prepareQrScene(bill)) return;
    if (!mounted || epoch != _detailEpoch || !identical(_selected, bill) ||
        _activeRequest?.id != old.id) return;
    _beginQrPrinter(bill); // BEFORE waiting on status and recreate APIs.
    setState(() { _checking = true; _detailError = null; });
    try {
      final latest = await api.status(old.id);
      if (!mounted || epoch != _detailEpoch ||
          !identical(_selected, bill) || _activeRequest?.id != old.id) return;
      setState(() {
        _activeRequest = latest;
        _recordGatewayRequest(bill, latest);
        _lastStatusSync = DateTime.now();
      });
      if (latest.status.toUpperCase() == 'EXPIRED' ||
          latest.status.toUpperCase() == 'CANCELLED') {
        final replacement = await api.recreate(latest.id);
        if (!mounted || epoch != _detailEpoch ||
            !identical(_selected, bill)) return;
        setState(() {
          TuitionApiDiagnostics.instance.record(
            'QR_PRINT', 'RECREATE_OK', note: 'source=reload_expired_qr');
          _activeRequest = replacement;
          _recordGatewayRequest(bill, replacement);
          _lastStatusSync = DateTime.now();
          _pausePollingUntil = null;
        });
        _resolveQrPrinter(true); // Animate the now-confirmed NEW QR into place.
        unawaited(_loadLive(force: true));
      } else if (latest.status.toUpperCase() == 'PAID') {
        _resolveQrPrinter(false);
        unawaited(_loadLive());
      } else {
        _resolveQrPrinter(false);
        setState(() => _detailError =
          'Hệ thống chưa xác nhận mã hết hạn. Vui lòng thử lại sau ít giây.');
      }
    } on DioException catch (error) {
      _resolveQrPrinter(false);
      if (mounted && epoch == _detailEpoch) {
        setState(() => _detailError = error.response?.statusCode == 409
          ? 'Mã thanh toán có thể đã thay đổi trên thiết bị khác. Vui lòng thử lại.'
          : 'Chưa làm mới được mã. Hãy thử lại.');
        if (error.response?.statusCode == 409) {
          unawaited(_loadLive(force: true));
        }
      }
    } catch (_) {
      _resolveQrPrinter(false);
      if (mounted && epoch == _detailEpoch) {
        setState(() => _detailError =
          'Chưa kiểm tra được trạng thái mã. Vui lòng thử lại.');
      }
    } finally {
      if (mounted && epoch == _detailEpoch) {
        setState(() => _checking = false);
        _startPolling();
        _scheduleExpiryReconciliation();
      }
    }
  }

  Future<void> _restoreExistingRequest(TuitionDemoBill bill, String requestId) async {
    final api = _api;
    if (api == null) return;
    final epoch = _detailEpoch;
    setState(() {
      _checking = true;
      _detailError = null;
    });
    try {
      final request = await api.status(requestId);
      if (!mounted || epoch != _detailEpoch || !identical(_selected, bill)) return;
      setState(() {
        _activeRequest = request;
        _recordGatewayRequest(bill, request);
        _lastStatusSync = DateTime.now();
      });
      _startPolling();
      if (const <String>{'EXPIRED','CANCELLED'}
          .contains(request.status.toUpperCase())) {
        unawaited(_loadLive(force: true));
        _scheduleExpiryReconciliation();
      }
    } catch (_) {
      if (mounted && epoch == _detailEpoch && identical(_selected, bill)) {
        setState(() => _detailError =
          'Chưa tải được mã QR đang có. Thử tải lại trạng thái của yêu cầu.');
      }
    } finally {
      if (mounted && epoch == _detailEpoch) {
        setState(() => _checking = false);
      }
    }
  }

  void _selectBill(TuitionDemoBill bill) {
    // Never create or resume a payment while its authentication is rotating.
    if (_manualRefreshing || _autoSessionRefreshing || _connecting) return;
    _payableRetryTimer?.cancel();
    _stopPolling();
    _cancelScenePreparation();
    ++_detailEpoch;
    _cancelLockAwaitingRelease = false;
    _printerActive = false;
    _printerOldReceipt = null;
    _printerOutcome = TuitionPrintOutcome.waitingForGateway;
    setState(() {
      _selected = bill;
      _activeRequest = null;
      _detailError = null;
      _lastStatusSync = null;
      _pausePollingUntil = null;
    });
    if (_mockMode) {
      setState(() => _activeRequest = _webMock.requestFor(bill.code));
      // Flutter Web may reuse the same controller for the next bill. Do not
      // reopen a different bill halfway down the previous long document.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selected?.code != bill.code ||
            !_mockDetailScroll.hasClients) return;
        if (_mockDetailScroll.offset > 0) _mockDetailScroll.jumpTo(0);
      });
      return;
    }
    final api = _api;
    if (api == null) return; // Legacy visual preview.
    final life = _life(bill);
    if (life?.isSettled == true) return; // Never resume/recreate a paid debt.
    final existing = life?.activeRequestId ?? life?.lastRequestId ??
        _existingRequests[bill.code];
    if (existing != null && existing.isNotEmpty) {
      // Show backend-supplied QR immediately. GET latest status in parallel.
      final snapshot = life?.activePaymentRequest ?? life?.lastPaymentRequest;
      if (snapshot != null) {
        try {
          setState(() => _activeRequest = api.rememberActiveRequest(snapshot));
          _startPolling();
        } catch (_) { /* status GET below remains authoritative */ }
      }
      unawaited(_restoreExistingRequest(bill, existing));
    } else if (life?.hasExpiredHistory == true ||
        life?.phase == TuitionReceivablePhase.qrExpired ||
        life?.phase == TuitionReceivablePhase.cancelled) {
      // An expired/cancelled bill WITHOUT an active request must wait for the
      // student's explicit tap on the green in-QR reload button. No surprise
      // POST just because the detail page was opened.
    } else if (!_unverifiedReceivables.contains(bill.code) &&
        (life?.canCreate ??
         (bill.status != TuitionPaymentStatus.paid && bill.isPayable && bill.amount > 0))) {
      // A first-time, verified unpaid receivable may create exactly once.
      unawaited(_createOrRecreate());
    }
  }

  void _back() {
    if (_selected != null) {
      _stopPolling();
      _cancelScenePreparation();
      ++_detailEpoch;
      setState(() {
        _cancelLockAwaitingRelease = false;
        _printerActive = false;
        _printerOldReceipt = null;
        _printerOutcome = TuitionPrintOutcome.waitingForGateway;
        _selected = null;
        _activeRequest = null;
        _detailError = null;
        _checking = false;
      });
      // Keep current cards immediately visible on Back. Refresh in the
      // background only; its empty feed is reconciled with known invoices.
      // Session rotation remains an EXPLICIT manual reload action.
      if (_api != null) unawaited(_loadLive());
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _checkStatus({bool silent = false, bool force = false}) async {
    if (_mockMode) {
      if (_selected != null && mounted) {
        setState(() => _activeRequest = _webMock.requestFor(_selected!.code));
      }
      return;
    }
    if (_checking || _statusRequestInFlight ||
        ((_manualRefreshing || _autoSessionRefreshing) && !force)) return;
    final api = _api;
    final active = _activeRequest;
    if (api == null || active == null || (active.terminal && !force) || _selected == null) return;
    final epoch = _detailEpoch;
    _statusRequestInFlight = true;
    final done = Completer<void>();
    _statusDone = done;
    if (!silent && mounted) setState(() {});
    try {
      final latest = await api.status(active.id);
      if (!mounted || epoch != _detailEpoch || _selected == null ||
          _activeRequest?.id != active.id) return;
      // Polling is data-only: an unchanged GET must NOT rebuild/redecode the
      // visible QR, re-run its entrance animations, or flash the mask.
      final redraw = !silent ||
          active.status != latest.status ||
          active.payload != latest.payload ||
          active.imageBase64 != latest.imageBase64 ||
          active.expiresAt != latest.expiresAt ||
          active.provider != latest.provider ||
          _detailError != null;
      void applyLatest() {
        _activeRequest = latest;
        _lastStatusSync = DateTime.now();
        _recordGatewayRequest(_selected!, latest);
        _detailError = null;
        _pausePollingUntil = null;
      }
      if (redraw) {
        setState(applyLatest);
      } else {
        applyLatest();
      }
      if (latest.terminal) {
        _stopPolling();
        // A status transition MUST propagate to the receivable list while
        // the detail is still open. This does not create/recreate anything.
        unawaited(_loadLive(force: true));
        if (const <String>{'EXPIRED','CANCELLED'}
            .contains(latest.status.toUpperCase())) {
          _scheduleExpiryReconciliation();
        }
      } else {
        _startPolling(); // Update deadline if upstream changed expiresAt.
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 429) {
        final raw = error.response?.headers.value('retry-after');
        final seconds = int.tryParse(raw ?? '') ?? 15;
        _pausePollingUntil = DateTime.now().add(
          Duration(seconds: seconds.clamp(5, 120).toInt()));
      } else if (!silent && mounted) {
        _showTuitionNotice('Chưa kiểm tra được trạng thái. Hệ thống sẽ tự thử lại.', tone: VcoreNoticeTone.warning);
      }
    } catch (_) {
      if (!silent && mounted) {
        _showTuitionNotice('Chưa kiểm tra được trạng thái. Hệ thống sẽ tự thử lại.', tone: VcoreNoticeTone.warning);
      }
    } finally {
      _statusRequestInFlight = false;
      if (identical(_statusDone, done)) _statusDone = null;
      if (!done.isCompleted) done.complete();
      if (!silent && mounted) setState(() {});
    }
  }

  Widget _qrMissing(String message) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      const TuitionArtIcon(name: 'tuition_qr_placeholder',
        fallback: Icons.qr_code_2_rounded, size: 48,
        color: TuitionPalette.subdued),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: TextStyles.fontName, fontSize: 11.5, color: TuitionPalette.muted,
          height: 1.5)),
    ],
  ));

  String _money(int value) => '${NumberFormat.decimalPattern('vi_VN').format(value)} đ';
  String _date(DateTime? value) => value == null
      ? 'Chưa có thông tin' : DateFormat('dd/MM/yyyy').format(value);
  String _stamp(DateTime value) => DateFormat('HH:mm · dd/MM/yyyy').format(value);
  String _time(DateTime value) => DateFormat('HH:mm').format(value);

  Widget _stateMessage({required String title, required String description,
      bool loading = false, VoidCallback? retry, IconData? stateIcon}) {
    return Center(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 30),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: 66, width: 66, child: DecoratedBox(
          decoration: BoxDecoration(color: TuitionPalette.greenSoft,
            borderRadius: BorderRadius.circular(21)),
          child: Center(child: loading ? VnuLoading.inline(size: 35)
            : Icon(stateIcon ?? (retry == null
                  ? Icons.lock_outline_rounded : Icons.wifi_off_rounded),
              size: 31, color: TuitionPalette.green)),
        )),
        const SizedBox(height: 20),
        Text(title, textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: TextStyles.fontName, fontSize: 16, fontWeight: FontWeight.w800,
            color: TuitionPalette.ink)),
        const SizedBox(height: 9),
        Text(description, textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: TextStyles.fontName, fontSize: 12, height: 1.4,
            color: TuitionPalette.muted)),
        if (retry != null) ...[
          const SizedBox(height: 22),
          VnuPressMotion(child: OutlinedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh_rounded, size: 19),
            label: const Text('Thử lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TuitionPalette.green,
              side: const BorderSide(color: Color(0xFFCDE4D6)),
              padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
          )),
        ],
      ]),
    ));
  }

  PreferredSizeWidget _compactAppBar(String title) => AppBar(
    toolbarHeight: 56,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    foregroundColor: TuitionPalette.ink,
    scrolledUnderElevation: 0,
    elevation: 0.5,
    shadowColor: const Color(0x14000000),
    centerTitle: true,
    leadingWidth: 45,
    leading: VnuPressMotion(child: BackButton(onPressed: _back,
      color: TuitionPalette.ink)),
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontFamily: TextStyles.fontName,
        fontSize: 14.5, fontWeight: FontWeight.w700,
        color: TuitionPalette.ink)),
    actions: [
      if (_mockMode)
        const Center(child: Text('MOCK', style: TextStyle(
          fontSize: 9, color: Color(0xFF47826B),
          fontWeight: FontWeight.w900))),
      // In mock mode these controls belong to the REAL payment screen.
      // No separate Animation Lab route and no Lottie clear-session action.
      if (_mockMode)
        PopupMenuButton<String>(
          key: const ValueKey<String>('tuition_mock_tools'),
          tooltip: 'Điều khiển dữ liệu giả để thử QR',
          icon: const Icon(Icons.science_outlined,
              color: TuitionPalette.deepGreen, size: 25),
          onSelected: _mockMenuAction,
          itemBuilder: (_) => <PopupMenuEntry<String>>[
            const PopupMenuItem(value: 'success',
                child: Text('Lượt tạo QR tiếp theo: thành công')),
            const PopupMenuItem(value: 'fail',
                child: Text('Lượt tạo QR tiếp theo: thất bại')),
            if (_selected != null) ...[
              const PopupMenuItem(value: 'expire',
                  child: Text('Cho QR hiện tại hết hạn')),
              const PopupMenuItem(value: 'clear_qr',
                  child: Text('Bỏ QR mock để thử tạo lần đầu')),
              const PopupMenuItem(value: 'mark_paid',
                  child: Text('Đánh dấu đã nộp đủ (mock)')),
            ],
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'fast',
                child: Text('Phản hồi sau 1,4 giây')),
            const PopupMenuItem(value: 'slow',
                child: Text('Phản hồi sau 4 giây')),
            const PopupMenuItem(value: 'reset',
                child: Text('Đặt lại hai khoản thu mock')),
          ],
        ),
      if (widget.universityId == 4 && !_mockMode)
        IconButton(
          key: const ValueKey<String>('tuition_force_reload'),
          tooltip: 'Dọn phiên học phí và tải lại dữ liệu',
          onPressed: _manualRefreshing || _autoSessionRefreshing ||
                  _connecting || _checking
              ? null : _runBroomRefresh,
          // Actual small Lottie artwork, not a Material broom icon.
          icon: const TuitionClearLottieIcon(),
          iconSize: TuitionClearMotionConfig.toolbarIconSize,
          constraints: const BoxConstraints(minWidth: 56, minHeight: 54),
          padding: EdgeInsets.zero,
        ),
      const SizedBox(width: 6),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final permitted = _mockMode || widget.universityId == 4 ||
        _explicitDeveloperPreview;
    Widget content;
    if (!permitted) {
      content = _stateMessage(title: 'Ch\u01b0a h\u1ed7 tr\u1ee3 thanh to\u00e1n',
        description: 'Thanh to\u00e1n h\u1ecdc ph\u00ed hi\u1ec7n \u0111\u01b0\u1ee3c h\u1ed7 tr\u1ee3 cho sinh vi\u00ean ULIS.');
    } else if (_entryPreparing) {
      // The initial frame is deliberately lightweight; alpha-mask/image
      // preparation runs behind a bounded loading surface first.
      content = const SizedBox.expand();
    } else {
      // Authentication, empty feeds and API failures must never replace the
      // payment overview with a full-page error or loading illustration.
      content = StudentViewSwitch(
        pageKey: _selected == null ? 'tuition-overview' :
            'tuition-${_selected!.code}',
        child: _selected == null ? _overview() : _details(_selected!),
      );
    }

    return StudentServiceUI.withoutTapHighlight(context, Stack(
      children: <Widget>[
        PopScope<Object?>(
          canPop: _selected == null && !_clearAnimationVisible,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && mounted && !_clearAnimationVisible) _back();
          },
          child: Scaffold(
            backgroundColor: TuitionPalette.canvas,
            appBar: _compactAppBar(_selected == null
              ? 'Thanh toán học phí' : 'Thanh toán khoản thu'),
            body: DefaultTextStyle.merge(
              style: const TextStyle(fontFamily: TextStyles.fontName),
              child: content,
            ),
          ),
        ),
        if (_entryPreparing || _qrPreparing)
          TuitionScenePreparationOverlay(entering: _entryPreparing),
        if (_clearAnimationVisible)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: TuitionClearSessionOverlay(
                // Await either manual or automatic token-rotation GET.
                readyToDismiss: !_manualRefreshing &&
                    !_autoSessionRefreshing && !_connecting,
                onDismiss: () {
                  if (mounted) {
                    setState(() => _clearAnimationVisible = false);
                  }
                },
              ),
            ),
          ),
      ],
    ));
  }

  bool get _hasBackendStudentFilters =>
      _selectedTermId != null || _selectedPeriodCode != null ||
      _canCreateOnly;

  /// Backend has NO paymentStatus/QR-status/search/sort query parameters.
  /// These are consistently evaluated on the complete client snapshot.
  List<TuitionDemoBill> _filteredStudentBills() {
    final query = _searchController.text.trim().toLowerCase();
    final result = _bills.where((bill) {
      final life = _life(bill);
      final outstanding = life?.outstandingAmount ??
          (bill.status == TuitionPaymentStatus.paid ? 0 : bill.amount);
      if (_filter == 'Cần thanh toán' && outstanding <= 0) return false;
      if (_filter == 'Đã thanh toán' && outstanding > 0) return false;
      // The server owns the authoritative term/period/payability filter.
      // Before server responds, use the local copy with identical semantics.
      if (_hasBackendStudentFilters && _api != null &&
          _serverFilterIds != null) {
        if (!_serverFilterIds!.contains(bill.code)) return false;
      } else {
        if (_selectedTermId != null && bill.termId != _selectedTermId) {
          return false;
        }
        if (_selectedPeriodCode != null &&
            bill.collectionPeriodCode != _selectedPeriodCode) return false;
        final mockStatus=_mockMode
          ? _webMock.requestFor(bill.code)?.status.toUpperCase() : null;
        final mockCanPay=bill.status!=TuitionPaymentStatus.paid &&
          outstanding>0 && (mockStatus==null ||
            const <String>{'EXPIRED','CANCELLED'}.contains(mockStatus));
        final serverPayable=life==null
          ? (_mockMode ? mockCanPay : bill.isPayable && outstanding > 0)
          : life.hasDebt && life.payable && !life.hasActiveLock &&
            life.source['payability']?.toString().toUpperCase() != 'BLOCKED';
        if (_canCreateOnly && !serverPayable) {
          return false;
        }
      }
      final finance = life?.paymentStatus.toUpperCase() ??
          (bill.status == TuitionPaymentStatus.paid ? 'PAID' : 'UNPAID');
      if (_financeFilter.isNotEmpty && finance != _financeFilter) {
        return false;
      }
      final request = _mockMode ? _webMock.requestFor(bill.code) : null;
      final qr = (request?.status ?? life?.activeStatus ??
          life?.recentRequestStatus ?? '').toUpperCase();
      if (_qrStatusFilter.isNotEmpty && qr != _qrStatusFilter) return false;
      if (query.isNotEmpty && !<String>[
        bill.title, bill.code, bill.periodName ?? '',
        bill.collectionPeriodCode ?? '', _date(bill.dueDate),
      ].any((value) => value.toLowerCase().contains(query))) return false;
      return true;
    }).toList();
    result.sort((a,b) {
      switch (_sortFilter) {
        case 'amount_desc':
          return ( _life(b)?.outstandingAmount ?? b.amount)
              .compareTo(_life(a)?.outstandingAmount ?? a.amount);
        case 'amount_asc':
          return (_life(a)?.outstandingAmount ?? a.amount)
              .compareTo(_life(b)?.outstandingAmount ?? b.amount);
        case 'due_desc':
          return (b.dueDate ?? DateTime(1900))
              .compareTo(a.dueDate ?? DateTime(1900));
        default:
          return (a.dueDate ?? DateTime(9999))
              .compareTo(b.dueDate ?? DateTime(9999));
      }
    });
    return result;
  }

  Future<void> _refreshServerFilters() async {
    final generation = ++_serverFilterEpoch;
    final api = _api;
    if (!_hasBackendStudentFilters || _mockMode || api == null) {
      if (mounted) setState(() {
        _serverFilterIds = null;
        _serverFilterError = null;
        _serverFilterLoading = false;
      });
      return;
    }
    setState(() {
      _serverFilterIds = null;
      _serverFilterError = null;
      _serverFilterLoading = true;
    });
    try {
      // Never overwrite the GLOBAL debt snapshot with filtered rows.
      final rows = await api.payableAll(
        payableOnly:_canCreateOnly,termId:_selectedTermId,
        collectionPeriodCode:_selectedPeriodCode,pageSize:100);
      if (!mounted || generation != _serverFilterEpoch || _api != api) return;
      setState(() {
        _serverFilterIds = rows.map((row) =>
          row['receivableId']?.toString() ?? '').where((id) => id.isNotEmpty)
          .toSet();
        _serverFilterLoading = false;
      });
    } on TuitionGatewayIdentityMismatchException {
      if (mounted && generation == _serverFilterEpoch) _invalidateIdentity();
    } catch (_) {
      if (!mounted || generation != _serverFilterEpoch) return;
      setState(() {
        // Failed filter requests must not erase invoices or turn off debts.
        _serverFilterIds = null;
        _serverFilterLoading = false;
        _serverFilterError = 'Chưa xác minh được bộ lọc từ máy chủ; '
          'đang lọc các khoản đã tải trên thiết bị.';
      });
    }
  }

  void _changeBackendFilters({String? termId, String? periodCode,
      bool? canCreateOnly, bool changeTerm=false,
      bool changePeriod=false}) {
    setState(() {
      if (changeTerm) _selectedTermId = termId;
      if (changePeriod) _selectedPeriodCode = periodCode;
      if (canCreateOnly != null) _canCreateOnly = canCreateOnly;
      _serverFilterIds = null;
      _serverFilterError = null;
      ++_listWaveGeneration;
    });
    unawaited(_refreshServerFilters());
  }

  Widget _studentFilterButton(String label,
      List<MapEntry<String,String>> choices, String? selected,
      void Function(String?) onPicked, {required double width,
      bool searchable=false}) {
    return SizedBox(
      width: width,
      child: VnuSingleSelect<String>(
        key: ValueKey<String>('tuition_filter_$label'),
        items: choices.map((choice) => VnuSelectItem<String>(
          value: choice.key, label: choice.value)).toList(),
        value: selected,
        hintText: label,
        sheetTitle: 'Chọn $label',
        searchable: searchable,
        searchHint: 'Tìm $label',
        clearable: true,
        clearLabel: label == 'Sắp xếp'
            ? 'Mặc định (hạn gần nhất)' : 'Tất cả $label',
        compact: true,
        onChanged: onPicked,
      ),
    );
  }

  Widget _studentFilterPanel() {
    final periods=<String,String>{};
    final terms=<String,String>{};
    for (final bill in _bills) {
      final term=bill.termId;
      final period=bill.collectionPeriodCode;
      if (term!=null && term.isNotEmpty) {
        terms.putIfAbsent(term, () => 'Kỳ thu ${term.substring(0,8)}');
      }
      if (period!=null && period.isNotEmpty) {
        periods.putIfAbsent(period, () =>
          '${bill.periodName ?? period} ($period)');
      }
    }
    // Do not disappear selected values when a remote refresh is incomplete.
    if (_selectedTermId != null && !terms.containsKey(_selectedTermId)) {
      terms[_selectedTermId!] = 'Kỳ thu ${_selectedTermId!.substring(0,8)}';
    }
    if (_selectedPeriodCode != null &&
        !periods.containsKey(_selectedPeriodCode)) {
      periods[_selectedPeriodCode!] = _selectedPeriodCode!;
    }
    final termOptions=terms.entries.toList();
    final periodOptions=periods.entries.toList();
    return Padding(
      padding:const EdgeInsets.symmetric(horizontal:13),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        TextField(
          key:const ValueKey<String>('tuition_student_search'),
          controller:_searchController,
          onChanged: (_) {
          _searchDebounce?.cancel();
          _searchDebounce=Timer(const Duration(milliseconds:150), () {
            if (mounted) setState(() {});
          });
        },
          style:const TextStyle(fontFamily:TextStyles.fontName,fontSize:12),
          decoration:InputDecoration(
            isDense:true,hintText:'Tìm khoản thu hoặc mã đợt thu',
            hintStyle:const TextStyle(fontFamily:TextStyles.fontName,
              fontSize:11,color:TuitionPalette.muted),
            prefixIcon:const Icon(Icons.search,size:18),
            filled:true,fillColor:Colors.white,
            contentPadding:const EdgeInsets.symmetric(vertical:11),
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(11),
              borderSide:const BorderSide(color:TuitionPalette.line)),
          ),
        ),
        const SizedBox(height:7),
        LayoutBuilder(builder: (context, constraints) {
          final filterWidth = math.min(180.0,
              math.max(110.0, (constraints.maxWidth - 6.0) / 2.0));
          return Wrap(spacing:6,runSpacing:6,
            crossAxisAlignment:WrapCrossAlignment.center,children:[
            _studentFilterButton('Kỳ thu',termOptions,_selectedTermId,
              (value) => _changeBackendFilters(
                termId:value,changeTerm:true), width:filterWidth, searchable:true),
            _studentFilterButton('Đợt thu',periodOptions,
              _selectedPeriodCode,(value) => _changeBackendFilters(
                periodCode:value,changePeriod:true), width:filterWidth, searchable:true),
            _studentFilterButton('Công nợ',const <MapEntry<String,String>>[
              MapEntry('UNPAID','Chưa nộp'),
              MapEntry('PARTIALLY_PAID','Đã nộp một phần'),
              MapEntry('PAID','Đã nộp đủ'),
              MapEntry('OVERPAID','Nộp thừa'),
              MapEntry('NO_PAYMENT_REQUIRED','Không cần thanh toán'),
            ],_financeFilter.isEmpty ? null : _financeFilter,
              (value) => setState(() => _financeFilter = value ?? ''), width:filterWidth),
            _studentFilterButton('QR',const <MapEntry<String,String>>[
              MapEntry('PENDING','Đang chờ'),
              MapEntry('PROCESSING','Đang xử lý'),
              MapEntry('PAID','Đã thanh toán'),
              MapEntry('EXPIRED','Hết hạn'),
              MapEntry('CANCELLED','Đã hủy'),
            ],_qrStatusFilter.isEmpty ? null : _qrStatusFilter,
              (value) => setState(() => _qrStatusFilter = value ?? ''), width:filterWidth),
            _studentFilterButton('Sắp xếp',const <MapEntry<String,String>>[
              MapEntry('due_asc','Hạn gần nhất'),
              MapEntry('due_desc','Hạn xa nhất'),
              MapEntry('amount_desc','Số tiền giảm dần'),
              MapEntry('amount_asc','Số tiền tăng dần'),
            ],_sortFilter == 'due_asc' ? null : _sortFilter,
              (value) => setState(() => _sortFilter = value ?? 'due_asc'), width:filterWidth),
            FilterChip(
              label:const Text('Có thể tạo QR',style:TextStyle(fontSize:10.5)),
              selected:_canCreateOnly,
              onSelected:(value)=>_changeBackendFilters(canCreateOnly:value),
              visualDensity:VisualDensity.compact,
              side:BorderSide(color:TuitionPalette.line),
            ),
            if (_serverFilterLoading)
              const SizedBox(width:15,height:15,
                child:CircularProgressIndicator(strokeWidth:1.5)),
            if (_hasBackendStudentFilters || _financeFilter.isNotEmpty ||
                _qrStatusFilter.isNotEmpty ||
                _searchController.text.isNotEmpty ||
                _sortFilter != 'due_asc')
              TextButton(onPressed:(){
                _searchController.clear();
                setState(() {
                  _selectedTermId=null;
                  _selectedPeriodCode=null;
                  _canCreateOnly=false;
                  _financeFilter='';
                  _qrStatusFilter='';
                  _sortFilter='due_asc';
                  _serverFilterIds=null;
                  _serverFilterError=null;
                  ++_listWaveGeneration;
                });
                unawaited(_refreshServerFilters());
              }, child:const Text('Xóa lọc',style:TextStyle(fontSize:10.5))),
          ],
          );
        }),
      ]),
    );
  }

  int? _cp1Amount(dynamic value) => value is num ? value.round()
      : int.tryParse(value?.toString() ?? '');

  List<MapEntry<String,String>> _cp1Charges(Map<String,dynamic> source) {
    final raw=source['charges'];
    if (raw is! List) return const <MapEntry<String,String>>[];
    return raw.whereType<Map>().map((charge) => MapEntry<String,String>(
      (charge['name'] ?? 'Khoản mục').toString(),
      _money(_cp1Amount(charge['amount']) ?? 0),
    )).toList();
  }

  bool get _canCancelCurrentRequest {
    final request=_activeRequest;
    if (request == null || request.status.toUpperCase()!='PENDING') {
      return false;
    }
    return request.expiresAt == null ||
        request.expiresAt!.isAfter(DateTime.now());
  }

  Future<void> _cancelPendingRequest() async {
    final bill=_selected;
    final request=_activeRequest;
    if (bill == null || request == null || !_canCancelCurrentRequest ||
        _checking || _qrPreparing || _printerActive ||
        _manualRefreshing || _autoSessionRefreshing) return;
    final bool? confirmed = await showVcoreActionDialog<bool>(
      context: context,
      title: 'Hủy mã QR đang chờ?',
      content: 'Mã QR hiện tại sẽ không còn được ứng dụng '
          'chấp nhận. Nếu đã chuyển khoản, hãy kiểm tra kết quả với '
          'nhà trường trước khi tạo mã mới.',
      leadingIcon: Icons.qr_code_2_rounded,
      actions: const <VcoreDialogAction<bool>>[
        VcoreDialogAction<bool>(
          label: 'Giữ mã', value: false,
          tone: VcoreDialogActionTone.secondary,
        ),
        VcoreDialogAction<bool>(
          label: 'Xác nhận hủy', value: true,
          icon: Icons.cancel_outlined,
          tone: VcoreDialogActionTone.danger,
        ),
      ],
    );
    if (confirmed != true || !mounted || !identical(_selected,bill) ||
        request.id != _activeRequest?.id || !_canCancelCurrentRequest) return;
    final epoch=_detailEpoch;
    setState(() { _checking=true; _detailError=null; });
    try {
      // A second device might have moved the request to PROCESSING.
      // Re-read before POST; backend rechecks ownership and state atomically.
      final api=_api;
      late final TuitionPaymentCancellation outcome;
      if (_mockMode) {
        outcome=await _webMock.cancel(bill.code);
      } else if (api != null) {
        final latest=await api.status(request.id);
        if (!mounted || epoch!=_detailEpoch ||
            !identical(_selected,bill)) return;
        if (latest.status!='PENDING' ||
            (latest.expiresAt!=null &&
             !latest.expiresAt!.isAfter(DateTime.now()))) {
          setState(() {
            _activeRequest=latest;
            _recordGatewayRequest(bill,latest);
            _detailError='Trạng thái đã thay đổi. Không hủy được mã này.';
          });
          return;
        }
        outcome=await api.cancel(request.id);
      } else { return; }
      if (!mounted || epoch!=_detailEpoch ||
          !identical(_selected,bill)) return;
      setState(() {
        _activeRequest=outcome.request;
        _cancelLockAwaitingRelease = !outcome.lockReleased;
        if (!_mockMode) _recordGatewayRequest(bill,outcome.request);
        _detailError=outcome.lockReleased ? null :
          'Đã hủy mã, nhưng hệ thống đang xác nhận giải phóng khoản thu. '
          'Chưa thể tạo mã mới.';
      });
      if (!_mockMode) unawaited(_loadLive(force:true));
      if (outcome.lockReleased) _scheduleExpiryReconciliation();
    } on DioException catch(error) {
      if (mounted && epoch==_detailEpoch) {
        setState(() => _detailError=error.response?.statusCode==409
          ? 'Giao dịch đã thay đổi hoặc đang xử lý; không thể hủy.'
          : 'Chưa thể hủy mã. Mã cũ vẫn được giữ để kiểm tra trạng thái.');
        if (error.response?.statusCode==409 && !_mockMode) {
          unawaited(_loadLive(force:true));
        }
      }
    } catch (_) {
      if (mounted && epoch==_detailEpoch) {
        setState(() => _detailError=
          'Chưa xác nhận được việc hủy. Hãy kiểm tra trạng thái mã.');
      }
    } finally {
      if (mounted && epoch==_detailEpoch) {
        setState(() => _checking=false);
      }
    }
  }

  Widget _overview() {
    // A live filter query is independent of the global receivables feed:
    // it never wipes invoices or changes the all-student debt total.
    final filtered = _filteredStudentBills();
    final owed = _bills.where((bill) => _life(bill)?.inUnpaidTab ??
      (bill.status != TuitionPaymentStatus.paid && bill.amount > 0)).toList();
    // payable=false may simply be a lock while a QR exists. Not used here.
    // Sum by unique receivableId and OUTSTANDING amount, not by payable=true
    // (a QR lock can temporarily make payable=false while money is still due).
    final balance = _api == null ? null : TuitionOverviewTotal.fromStates(
      _receivables.values, unverifiedIds: _unverifiedReceivables);
    final outstanding = balance?.amount ?? owed.fold<int>(0,
      (sum, bill) => sum + (bill.amount > 0 ? bill.amount : 0));
    // Always display the actual sum of visible known rows. An incomplete
    // snapshot is described as the displayed-card total, never fresh debt.
    final amountUnknown = balance?.hasRows == false ||
        (_api == null && _bills.isEmpty);
    final balanceLabel = balance?.isPartiallyUnverified == true
        ? 'Tổng các khoản đang hiển thị' : 'Tổng cần thanh toán';
    // Internal reconciliation/retry diagnostics remain in debug logs only.
    // The student sees normal loading or a short actionable failure message;
    // never expose cache, stale snapshot, lock or mapping implementation.
    final String? notice = _connectError != null
        ? 'Chưa thể mở dữ liệu học phí. Vui lòng thử lại.'
        : (_liveError != null && _bills.isEmpty
            ? 'Chưa tải được khoản thu. Vuốt xuống để thử lại.'
            : null);
    return RefreshIndicator.adaptive(
      color: TuitionPalette.green,
      onRefresh: _refreshFromServer,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 18),
        children: [
          TuitionResponsiveFrame(child: _overviewHero(outstanding, owed.length,
            amountUnknown: amountUnknown, totalLabel: balanceLabel)),
          const SizedBox(height: 11),
          TuitionResponsiveFrame(child: _filterTabs()),
          const SizedBox(height: 6),
          TuitionResponsiveFrame(child: _studentFilterPanel()),
          const SizedBox(height: 10),
          if (_serverFilterError != null)
            TuitionResponsiveFrame(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(_serverFilterError!,
                style: const TextStyle(fontFamily: TextStyles.fontName,
                  color: Color(0xFF96672A), fontSize: 10.5)),
            )),
          if (notice != null || _connecting || _manualRefreshing ||
              (_liveLoading && _bills.isEmpty))
            TuitionResponsiveFrame(child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 1, 17, 6),
              child: Row(children: [
                if (_connecting || _manualRefreshing ||
                    (_liveLoading && _bills.isEmpty))
                  const SizedBox(width: 13, height: 13,
                    child: CircularProgressIndicator(strokeWidth: 1.7,
                      color: TuitionPalette.green))
                else
                  const Icon(Icons.sync_rounded, size: 14,
                    color: TuitionPalette.muted),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  notice ?? 'Đang tải khoản thu...',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: TextStyles.fontName,
                    color: TuitionPalette.muted, fontSize: 10.3, height: 1.3))),
              ]),
            )),
          if (filtered.isEmpty)
            TuitionResponsiveFrame(child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Text(
                _connecting || _liveLoading || _manualRefreshing ||
                    _serverFilterLoading
                  ? '\u0110ang t\u1ea3i danh s\u00e1ch kho\u1ea3n thu...'
                  : (notice != null ? 'Danh sách chưa tải được. Vuốt xuống để thử lại.'
                      : 'Ch\u01b0a c\u00f3 kho\u1ea3n thu \u0111\u1ec3 hi\u1ec3n th\u1ecb.'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: TextStyles.fontName,
                  color: TuitionPalette.muted, fontSize: 11.5))))
          else for (var index = 0; index < filtered.length; index++) ...[
            TuitionResponsiveFrame(child: TuitionTicketWaveEntrance(
              key: ValueKey<String>('tuition_wave_${filtered[index].code}'),
              index: index,
              generation: _listWaveGeneration,
              child: _billRow(filtered[index], index))),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _overviewHero(int outstanding, int unpaidCount,
      {required bool amountUnknown, required String totalLabel}) {
    final year = DateTime.now().month >= 8
      ? DateTime.now().year : DateTime.now().year - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 4, 15, 0),
      child: LayoutBuilder(builder: (context, layout) {
        // Wallet uses the WHOLE right hero region, never shares the row with
        // the amount. This reproduces the original image hierarchy.
        final walletWidth = math.min(165.0, layout.maxWidth * 0.42);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Khoản thu của bạn', maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: TextStyles.fontName,
                    fontSize: 21, height: 1.08,
                    fontWeight: FontWeight.w800, color: TuitionPalette.ink)),
                const SizedBox(height: 5),
                Text('Năm học $year–${year + 1}',
                  style: const TextStyle(fontFamily: TextStyles.fontName,
                    color: TuitionPalette.muted, fontSize: 11.5)),
                const SizedBox(height: 12),
                Text(totalLabel,
                  style: const TextStyle(fontFamily: TextStyles.fontName,
                    color: Color(0xFF526C5E), fontSize: 11.8)),
              ],
            )),
            SizedBox(width: walletWidth, height: walletWidth,
              child: TuitionStatusMotion(wallet: true, size: walletWidth)),
          ]),
          const SizedBox(height: 0),
          // Amount has its OWN full-width row below the title + wallet.
          SizedBox(width: double.infinity,
            child: FittedBox(fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(amountUnknown ? '\u2014' : _money(outstanding), style: const TextStyle(
                fontFamily: TextStyles.fontName, fontSize: 29,
                height: 1.10, fontWeight: FontWeight.w800,
                color: TuitionPalette.deepGreen, letterSpacing: -0.5)))),
          const SizedBox(height: 10),
          Material(color: const Color(0xFFFFF0CC),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => setState(() {
                _filter = 'Cần thanh toán';
                _listWaveGeneration++;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                child: Row(children: [
                  const Icon(Icons.schedule_rounded,
                    size: 16, color: Color(0xFFB87319)),
                  const SizedBox(width: 7),
                  Expanded(child: Text(
                    amountUnknown
                      ? 'Xem danh sách khoản thu'
                      : (unpaidCount == 0 ? 'Không có khoản chưa thanh toán'
                          : '$unpaidCount khoản chưa thanh toán'),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: TextStyles.fontName,
                      color: Color(0xFF985D17), fontSize: 10.5,
                      fontWeight: FontWeight.w700))),
                  const Icon(Icons.chevron_right_rounded,
                    size: 16, color: Color(0xFF985D17)),
                ]),
              ),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _filterTabs() {
    const options = <String>['Tất cả', 'Cần thanh toán', 'Đã thanh toán'];
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Row(children: [
        for (final value in options)
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: _filter == value ? TuitionPalette.deepGreen : Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                key: ValueKey<String>('tuition_tab_$value'),
                onTap: () => setState(() {
                  if (_filter != value) _listWaveGeneration++;
                  _filter = value;
                }),
                borderRadius: BorderRadius.circular(12),
                child: Container(height: 35,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: _filter == value
                      ? TuitionPalette.deepGreen : TuitionPalette.line),
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: TextStyles.fontName,
                      fontSize: 10.1,
                      fontWeight: _filter == value ? FontWeight.w700 : FontWeight.w600,
                      color: _filter == value ? Colors.white : TuitionPalette.muted)),
                ),
              ),
            ),
          )),
      ]),
    );
  }

  Widget _billRow(TuitionDemoBill bill, int index) {
    final life = _life(bill);
    final phase = life?.phase;
    final state = TuitionStatusPresentation.from(bill.status);
    final label = _mockMode && bill.status == TuitionPaymentStatus.expired
        ? 'Mã đã hết hạn' : switch (phase) {
      TuitionReceivablePhase.unpaid => life?.hasExpiredHistory == true
          ? 'Chờ thanh toán' : 'Chưa thanh toán',
      TuitionReceivablePhase.qrExpired => 'Mã đã hết hạn',
      TuitionReceivablePhase.blocked => 'Tạm khóa',
      _ => state.label,
    };
    final stateColor = phase == TuitionReceivablePhase.unpaid
        ? TuitionPalette.green : state.color;
    final category = bill.chargeCategory;
    // ONLY the gateway's exact FIRST_TIME / RETAKE / IMPROVEMENT /
    // OUT_OF_PROGRAM code sets a category tint. Null => mint/sand by index.
    final tint = TuitionTicketDefaults.tintForCategory(category, index);
    final retakeArtwork = category == TuitionChargeCategory.retake ||
        category == TuitionChargeCategory.improvement ||
        (category == null && index.isOdd);

    return TuitionListTicketAB(
      key: ValueKey<String>('tuition_ticket_ab_${bill.code}'),
      indexLabel: '${index + 1}'.padLeft(2, '0'),
      tint: tint,
      height: 189,
      margin: 4,
      onTap: () => _selectBill(bill),
      // B's top row consists of [icon] + [A1 text] + [arrow B].
      // A2 (deadline) is a separate group BELOW, never in arrow B's row.
      leadingIcon: TuitionArtIcon(
        name: retakeArtwork ? 'tuition_retake' : 'tuition_bill',
        fallback: retakeArtwork
          ? Icons.menu_book_rounded : Icons.school_rounded,
        color: TuitionTicketDefaults.indexInkForTint(tint),
        size: 20),
      mainContent: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
          Text(bill.title,
            softWrap: true,
            style: const TextStyle(fontFamily: TextStyles.fontName,
              fontSize: 11.8, fontWeight: FontWeight.w800,
              color: TuitionPalette.ink, height: 1.14)),
          if (bill.periodName?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 2),
            Text(bill.periodName!,
              softWrap: true,
              style: const TextStyle(fontFamily: TextStyles.fontName,
                fontSize: 9.8, color: TuitionPalette.muted)),
          ],
          const SizedBox(height: 5),
          FittedBox(fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(_money(life?.displayAmount ?? bill.amount),
              style: const TextStyle(fontFamily: TextStyles.fontName,
                fontSize: 17, height: 1.06,
                fontWeight: FontWeight.w800, color: TuitionPalette.ink))),
          const SizedBox(height: 5),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (phase == TuitionReceivablePhase.unpaid ||
                phase == TuitionReceivablePhase.blocked)
              Icon(Icons.circle, size: 7, color: stateColor)
            else TuitionStatusMotion(status: bill.status, size: 17),
            const SizedBox(width: 4),
            Flexible(child: Text(label, maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: TextStyles.fontName,
                fontSize: 9.5, height: 1.05,
                fontWeight: FontWeight.w700, color: stateColor))),
            // Countdown is DIRECTLY adjacent to the status, not at row end.
            if (life?.activeExpiresAt != null &&
                phase == TuitionReceivablePhase.waitingPayment) ...[
              const SizedBox(width: 5),
              _remainingChip(life!.activeExpiresAt!),
            ],
          ]),
        ]),
      // Small, separate deadline box; it never stretches to fill B.
      deadline: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.event_outlined, size: 12,
            color: TuitionPalette.muted),
          const SizedBox(width: 4),
          Flexible(child: Text(
            bill.dueDate == null ? 'Chưa có hạn' : _date(bill.dueDate),
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: TextStyles.fontName,
              fontSize: 9, color: TuitionPalette.muted))),
        ]),
      ),
    );
  }

  Future<void> _refreshDetail() => _refreshFromServer();

  /// Render the SAME full-size detail paper for normal layout and for the
  /// final animation frame. The actual destination is measured with a GlobalKey.
  Widget _detailTicketPaper(TuitionDemoBill bill,
      {TuitionPaymentRequest? snapshot}) {
    final request = snapshot ?? _activeRequest;
    final life = _life(bill);
    final status = request == null ? bill.status : _fromStatus(request.status);
    final canPay = !_unverifiedReceivables.contains(bill.code) &&
        (life?.canCreate ?? (bill.amount > 0 && bill.isPayable));
    final chargeLines=life==null
        ? const <MapEntry<String,String>>[] : _cp1Charges(life.source);
    return TuitionTicketPaper(
      kind: TuitionTicketKind.detail,
      margin: 0,
      minHeight: 490,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.fromLTRB(3, 13, 3, 16),
          child: Column(children: [
            const Text('MÃ THANH TOÁN',
              style: TextStyle(fontFamily: TextStyles.fontName,
                fontSize: 9.5, letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                color: TuitionPalette.muted)),
            const SizedBox(height: 5),
            _qrCard(bill, status, canPay, request),
          ]),
        ),
        const TuitionTicketDashedDivider(sideInset: 0),
        Padding(padding: const EdgeInsets.fromLTRB(3, 14, 3, 7),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chi tiết', style: TextStyle(
                fontFamily: TextStyles.fontName,
                color: TuitionPalette.ink, fontSize: 16,
                fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (bill.periodName?.trim().isNotEmpty ?? false)
                _ticketInfoLine('Kỳ thu', bill.periodName!),
              _ticketInfoLine('Hạn nộp', _date(bill.dueDate)),
              _ticketInfoLine('Đơn vị', 'Trường Đại học Ngoại ngữ'),
              if (life != null) ...[
                _ticketInfoLine('Tổng khoản',
                  _money(_cp1Amount(life.source['finalAmount'] ??
                    life.source['totalAmount']) ?? life.displayAmount)),
                _ticketInfoLine('Đã nộp',
                  _money(_cp1Amount(life.source['paidAmount']) ?? 0)),
                _ticketInfoLine('Còn nợ',_money(life.outstandingAmount)),
                if (chargeLines.isNotEmpty) ...[
                  const SizedBox(height:12),
                  const Text('Các khoản mục',style:TextStyle(
                    fontFamily:TextStyles.fontName,fontSize:12.4,
                    fontWeight:FontWeight.w800,color:TuitionPalette.ink)),
                  const SizedBox(height:5),
                  for (final charge in chargeLines) _chargeInfoLine(charge),
                ],
              ] else if (_mockMode) ...[
                _ticketInfoLine('Đã nộp',_money(0)),
                _ticketInfoLine('Còn nợ',_money(bill.amount)),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  Widget _details(TuitionDemoBill bill) {
    final request = _activeRequest;
    final status = request == null ? bill.status : _fromStatus(request.status);
    return Stack(key: _detailPrinterLayerKey, children: [
      const TuitionDetailPageBackground(),
      RefreshIndicator.adaptive(
        color: TuitionPalette.green,
        onRefresh: _refreshDetail,
        child: ListView(
          controller: _mockMode ? _mockDetailScroll : null,
          // The ticket's geometry is frozen while printing. Prevent a swipe
          // from moving its destination between the feed and dock frames.
          physics: _printerActive
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 22),
          children: [
            TuitionResponsiveFrame(child: _detailAmount(bill, status)),
            TuitionResponsiveFrame(child: TuitionDetailRiseEntrance(
              key: ValueKey<String>(
                'tuition_detail_rise_${bill.code}_$_detailEpoch'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TuitionReceiptMotionConfig.detailMargin),
                // Opacity hides ONLY the foreground sheet during printing.
                // It continues laying out at its real location, providing
                // an accurate measurement target on phones of any size.
                child: Opacity(opacity: _printerActive ? 0.0 : 1.0,
                  child: SizedBox(
                    key: _detailTicketTargetKey,
                    child: _detailTicketPaper(bill),
                  ),
                ),
              ),
            )),
            if (_canCancelCurrentRequest)
              TuitionResponsiveFrame(child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 8, 15, 12),
                child: OutlinedButton.icon(
                  key: const ValueKey<String>('tuition_cancel_request'),
                  onPressed: (_checking || _qrPreparing || _printerActive)
                    ? null : () => unawaited(_cancelPendingRequest()),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Hủy mã thanh toán đang chờ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF99562B)),
                ),
              )),
          ],
        ),
      ),
      if (_printerActive && _printerOldReceipt != null)
        TuitionReceiptPrinterStage(
          key: ValueKey<String>(
            'tuition_printer_attempt_$_printerAttemptSerial'),
          attemptSerial: _printerAttemptSerial,
          outcome: _printerOutcome,
          blurPrintingPaper: !_mockMode,
          lightweightPreview: _lightweightPrinterAttempt,
          targetRect: _measuredTicketInDetailBody,
          outgoingReceipt: _printerOldReceipt!,
          receipt: _detailTicketPaper(bill),
          title: bill.title,
          amount: _money(_life(bill)?.displayAmount ?? bill.amount),
          onFinished: _printerAnimationFinished,
        ),
    ]);
  }

  Widget _detailAmount(TuitionDemoBill bill, TuitionPaymentStatus status) {
    final life = _life(bill);
    final request = _activeRequest;
    final presentation = TuitionStatusPresentation.from(status);
    final expired = status == TuitionPaymentStatus.pending &&
      request?.expiresAt != null &&
      !request!.expiresAt!.isAfter(DateTime.now());
    final label = request == null && life?.phase == TuitionReceivablePhase.unpaid
      ? (life?.hasExpiredHistory == true ? 'Chờ thanh toán' : 'Chưa thanh toán')
      : expired ? 'Mã hết giờ'
      : status == TuitionPaymentStatus.expired ? 'Mã đã hết hạn'
      : presentation.label;
    return Container(width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 27),
      color: Colors.transparent,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const TuitionArtIcon(name: 'tuition_bill',
            fallback: Icons.school_rounded, color: Colors.white, size: 21),
          const SizedBox(width: 7),
          Expanded(child: Text(bill.title, maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: TextStyles.fontName,
              fontSize: 12.5, color: Colors.white,
              fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 9),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
          child: Text(_money(life?.displayAmount ?? bill.amount), style: const TextStyle(
            fontFamily: TextStyles.fontName, color: Colors.white,
            fontSize: 29, height: 1.18, letterSpacing: -0.4,
            fontWeight: FontWeight.w800))),
        const SizedBox(height: 10),
        Row(children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: presentation.background,
              borderRadius: BorderRadius.circular(20)),
            child: Padding(padding: const EdgeInsets.fromLTRB(8, 4, 11, 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                TuitionStatusMotion(status: status, size: 16),
                const SizedBox(width: 5),
                Text(label, style: TextStyle(
                  fontFamily: TextStyles.fontName,
                  color: presentation.color, fontSize: 11,
                  fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
          if (status == TuitionPaymentStatus.pending &&
              request?.expiresAt != null) ...[
            const Spacer(),
            _remainingChip(request!.expiresAt!, dark: true),
          ],
        ]),
      ]),
    );
  }

  Widget _chargeInfoLine(MapEntry<String,String> charge) => Padding(
    padding:const EdgeInsets.symmetric(vertical:4),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Expanded(child:Text(charge.key,softWrap:true,
        style:const TextStyle(fontFamily:TextStyles.fontName,
          color:TuitionPalette.muted,fontSize:11.5,height:1.3))),
      const SizedBox(width:10),
      Text(charge.value,style:const TextStyle(
        fontFamily:TextStyles.fontName,color:TuitionPalette.ink,
        fontSize:11.5,fontWeight:FontWeight.w700)),
    ]),
  );

  Widget _ticketInfoLine(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 72, child: Text(label,
        style: const TextStyle(fontFamily: TextStyles.fontName,
          color: TuitionPalette.muted, fontSize: 11.7, height: 1.36))),
      const SizedBox(width: 5),
      Expanded(child: Text(value, softWrap: true,
        textAlign: TextAlign.end,
        style: const TextStyle(fontFamily: TextStyles.fontName,
          color: TuitionPalette.ink, fontSize: 12.4,
          height: 1.35, fontWeight: FontWeight.w700))),
    ]),
  );

  Widget _qrCard(TuitionDemoBill bill, TuitionPaymentStatus status,
      bool canPay, TuitionPaymentRequest? request) {
    final presentation = TuitionStatusPresentation.from(status);
    final hasQr = request != null &&
      ((request.imageBase64?.isNotEmpty ?? false) ||
       (request.payload?.isNotEmpty ?? false));
    final localExpiry = status == TuitionPaymentStatus.pending &&
      request?.expiresAt != null &&
      !request!.expiresAt!.isAfter(DateTime.now());
    final dimQr = presentation.dimQr || localExpiry;
    // Some gateways drop the active request as soon as it expires, leaving
    // only lastPaymentRequestStatus and a payable=true receivable. Allow the
    // same in-QR affordance then, but CREATE (not RECREATE) only on tap.
    final expiredWithoutRequest = request == null &&
        presentation.allowRecreate && canPay;
    final canRetry = !_cancelLockAwaitingRelease &&
      (presentation.allowRecreate || localExpiry) &&
      (_api != null || _mockMode) && !(_life(bill)?.isSettled ?? false) &&
      (request != null || expiredWithoutRequest);
    final loading = (_checking || _qrPreparing) && request == null && !canRetry;
    final error = _detailError;

    return LayoutBuilder(builder: (context, limits) {
      // QR is sized against the content-inside-mask width, not screen width.
      // The scanner backdrop adds 9dp white border on each side.
      final qrSize = math.max(0.0, math.min(248.0, limits.maxWidth - 18));
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Quét mã để thanh toán',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: TextStyles.fontName,
            color: TuitionPalette.ink, fontSize: 16,
            fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        TuitionQrBackdrop(child: SizedBox(
          width: qrSize, height: qrSize,
          child: Stack(alignment: Alignment.center, children: [
            // Keep the QR StatefulWidget at the SAME element position as the
            // overlay appears/disappears and status changes every 5 seconds.
            if (hasQr)
              Positioned.fill(child: RepaintBoundary(
                // Keep ONE stable QR element through pending -> processing,
                // expiration, and repeated identical status responses.
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: dimQr ? 4.0 : 0.0,
                    sigmaY: dimQr ? 4.0 : 0.0),
                  child: Opacity(opacity: dimQr ? 0.30 : 1.0,
                    child: TuitionStableQr(
                      key: ValueKey<String>('tuition_stable_${request!.id}'),
                      request: request, size: qrSize,
                      placeholderBuilder: _qrMissing)),
                ),
              )),
            if (dimQr && hasQr)
              Positioned.fill(child: IgnorePointer(child: ColoredBox(
                color: Color(0x3DFFFFFF)))),
            if (loading)
              Column(mainAxisSize: MainAxisSize.min, children: [
                VnuLoading.inline(size: 30),
                const SizedBox(height: 5),
                const Text('Đang tạo mã...', style: TextStyle(
                  fontFamily: TextStyles.fontName,
                  fontSize: 9.5, color: TuitionPalette.muted)),
              ])
            else if (!canRetry &&
                (dimQr || (status == TuitionPaymentStatus.paid && !hasQr)))
              Column(mainAxisSize: MainAxisSize.min, children: [
                TuitionStatusMotion(status: status, size: 42),
                const SizedBox(height: 4),
                Text(localExpiry ? 'Mã hết giờ' : presentation.label,
                  style: const TextStyle(fontFamily: TextStyles.fontName,
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: TuitionPalette.ink)),
              ])
            else if (!canRetry && !hasQr)
              _qrMissing(error ?? (request != null
                ? 'Chưa nhận được mã QR.'
                : canPay ? 'Đang tạo mã QR.'
                    : (_life(bill)?.blockingReason ?? 'Chưa thể tạo mã QR.'))),
            // Only EXPIRED / CANCELLED or locally timed-out PENDING requests
            // expose a RECREATE affordance. It sits directly ON the QR image,
            // not under the card. Tap verifies GET before a guarded POST.
            if (canRetry)
              Positioned.fill(child: Center(child: TuitionQrReloadOverlay(
                key: ValueKey<String>(
                  'tuition_reload_${request?.id ?? bill.code}'),
                busy: _checking || _qrPreparing,
                onPressed: (_checking || _qrPreparing) ? null : () {
                  if (request == null) {
                    unawaited(_createOrRecreate());
                  } else {
                    unawaited(_reloadExpiredQr());
                  }
                },
              ))),
          ]),
        )),
        // Errors may still be shown UNDER the artwork, but the action to
        // RECREATE the expired QR lives exclusively ON the QR artwork above.
        if (canRetry && error != null) ...[
          const SizedBox(height: 8),
          Text(error, maxLines: 3, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: TextStyles.fontName,
              color: Color(0xFFB44E3F), fontSize: 10)),
        ] else if (!canRetry && error != null && !loading) ...[
          const SizedBox(height: 6),
          Text(error, maxLines: 2, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: TextStyles.fontName,
              color: Color(0xFFB44E3F), fontSize: 9.5)),
          const SizedBox(height: 8),
          _qrButton(text: 'Thử lại',
            icon: const Icon(Icons.refresh_rounded,
              color: Colors.white, size: 18),
            onPressed: (_checking || _qrPreparing) ? null : () {
              if (request != null) {
                unawaited(_checkStatus(force: true));
              } else if (_api != null && _existingRequests.containsKey(bill.code)) {
                unawaited(_restoreExistingRequest(bill,
                  _existingRequests[bill.code]!));
              } else {
                unawaited(_createOrRecreate());
              }
            }),
        ] else if (!canRetry && request == null && canPay && !loading &&
                   status != TuitionPaymentStatus.paid) ...[
          const SizedBox(height: 8),
          _qrButton(text: 'Tạo mã',
            icon: const Icon(Icons.qr_code_2_rounded,
              color: Colors.white, size: 18),
            onPressed: (_checking || _qrPreparing) ? null : _createOrRecreate),
        ],
      ]);
    });
  }

  Widget _qrButton({required String text, required Widget icon,
      required VoidCallback? onPressed}) {
    return SizedBox(width: double.infinity, height: 40,
      child: VnuPressMotion(
        enabled: !_checking && !_qrPreparing && onPressed != null,
        child: FilledButton.icon(
          onPressed: (_checking || _qrPreparing) ? null : onPressed,
          icon: _checking ? VnuLoading.inline(size: 20, color: Colors.white) : icon,
          label: Text(text, style: const TextStyle(fontFamily: TextStyles.fontName, 
            fontSize: 10.5, fontWeight: FontWeight.w800)),
          style: FilledButton.styleFrom(
            backgroundColor: TuitionPalette.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
