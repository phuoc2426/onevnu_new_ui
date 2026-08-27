import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_core/common/log.dart';

import 'app_config_service.dart';
import 'app_requirement_gate_service.dart';
import 'app_update_policy.dart';

enum AppUpdateGateMode {
  checking,
  allowed,
  optional,
  force,
}

class AppUpdateGateSnapshot {
  const AppUpdateGateSnapshot({
    required this.mode,
    required this.postSplashReady,
    this.evaluation,
    this.reason = '',
  });

  const AppUpdateGateSnapshot.initial()
      : mode = AppUpdateGateMode.checking,
        postSplashReady = false,
        evaluation = null,
        reason = 'initial';

  final AppUpdateGateMode mode;
  final bool postSplashReady;
  final AppUpdateEvaluation? evaluation;
  final String reason;

  bool get shouldBlock =>
      postSplashReady &&
      (mode == AppUpdateGateMode.checking || mode == AppUpdateGateMode.force);

  bool get shouldShowOptional =>
      postSplashReady && mode == AppUpdateGateMode.optional;

  AppUpdatePlatformPolicy? get platformPolicy => evaluation?.platformPolicy;

  AppUpdateGateSnapshot copyWith({
    AppUpdateGateMode? mode,
    bool? postSplashReady,
    AppUpdateEvaluation? evaluation,
    bool clearEvaluation = false,
    String? reason,
  }) {
    return AppUpdateGateSnapshot(
      mode: mode ?? this.mode,
      postSplashReady: postSplashReady ?? this.postSplashReady,
      evaluation:
          clearEvaluation ? null : (evaluation ?? this.evaluation),
      reason: reason ?? this.reason,
    );
  }
}

/// Global source of truth for app-update requirements.
///
/// Rules:
/// - Fetch immediately on cold start, but never cover the Splash screen.
/// - Re-fetch whenever the app resumes (including return from Store/Recent Apps).
/// - Re-fetch periodically while the app stays open, so an admin can enable a
///   minimum version without waiting for users to relaunch.
/// - Keep the force state above the Navigator; navigation cannot dismiss it.
/// - Cache the last valid policy. If a previously-known force policy exists,
///   a temporary network failure cannot be used to bypass the update gate.
class AppUpdateCoordinator {
  AppUpdateCoordinator._();

  static final AppUpdateCoordinator instance = AppUpdateCoordinator._();

  static const Duration checkInterval = Duration(minutes: 5);
  static const String _policyCacheKey = 'onevnu.app_update_policy.v1';

  final ValueNotifier<AppUpdateGateSnapshot> notifier =
      ValueNotifier<AppUpdateGateSnapshot>(
    const AppUpdateGateSnapshot.initial(),
  );

  Timer? _timer;
  Future<void>? _inFlight;
  bool _started = false;
  String? _dismissedOptionalKey;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    // A recreated app root must always start with the gate hidden during
    // Splash, even if this singleton survived a widget-tree rebuild.
    notifier.value = const AppUpdateGateSnapshot.initial();

    // A cached force decision can already be prepared during Splash. The UI
    // remains hidden until markPostSplashReady() is called by Splash.
    await _evaluateCachedPolicy(reason: 'cold_start_cache');

    // A cached FORCE state is already safe to keep. For cached ALLOWED or
    // OPTIONAL states, require one fresh server check before the post-Splash UI
    // becomes usable, otherwise a newly-enabled minimumVersion could be missed
    // for a short window at cold start.
    if (notifier.value.mode != AppUpdateGateMode.force) {
      notifier.value = notifier.value.copyWith(
        mode: AppUpdateGateMode.checking,
        reason: 'cold_start_wait_remote',
      );
    }

    unawaited(refresh(reason: 'cold_start', forceRefresh: true));

    _timer = Timer.periodic(checkInterval, (_) {
      unawaited(refresh(reason: 'periodic', forceRefresh: true));
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  void markPostSplashReady() {
    final current = notifier.value;
    if (current.postSplashReady) return;

    notifier.value = current.copyWith(postSplashReady: true);
    logInfo('[APP_UPDATE] global gate is now post-splash ready');
  }

  Future<void> onAppResumed() {
    return refresh(reason: 'app_resumed', forceRefresh: true);
  }

  Future<void> refresh({
    required String reason,
    bool forceRefresh = true,
  }) async {
    final existing = _inFlight;
    if (existing != null) {
      await existing;
      return;
    }

    final task = _refreshInternal(
      reason: reason,
      forceRefresh: forceRefresh,
    );
    _inFlight = task;

    try {
      await task;
    } finally {
      if (identical(_inFlight, task)) {
        _inFlight = null;
      }
    }
  }

  Future<void> _refreshInternal({
    required String reason,
    required bool forceRefresh,
  }) async {
    logInfo('[APP_UPDATE] check start reason=$reason');

    await AppConfigService().ensureLoaded(forceRefresh: forceRefresh);

    final configService = AppConfigService();
    final policy = configService.appUpdatePolicy;

    if (configService.isLoadedSuccessfully && policy != null) {
      await _saveCachedPolicy(policy);
      await _evaluateAndPublish(policy, reason: reason);
      logInfo('[APP_UPDATE] check end reason=$reason source=remote');
      return;
    }

    final cached = await _readCachedPolicy();
    if (cached != null) {
      await _evaluateAndPublish(cached, reason: '${reason}_cache_fallback');
      logWarning('[APP_UPDATE] remote unavailable; using cached policy');
      return;
    }

    // No trustworthy remote or cached policy exists. Fail open rather than
    // locking all users because of an outage or a malformed first response.
    final current = notifier.value;
    if (current.mode != AppUpdateGateMode.force) {
      notifier.value = current.copyWith(
        mode: AppUpdateGateMode.allowed,
        clearEvaluation: true,
        reason: '${reason}_fail_open',
      );
    }
    logWarning('[APP_UPDATE] no valid policy available; fail open');
  }

  Future<void> _evaluateCachedPolicy({required String reason}) async {
    final cached = await _readCachedPolicy();
    if (cached == null) return;
    await _evaluateAndPublish(cached, reason: reason);
  }

  Future<void> _evaluateAndPublish(
    AppUpdatePolicy policy, {
    required String reason,
  }) async {
    try {
      final evaluation =
          await AppRequirementGateService.instance.evaluatePolicy(policy);
      if (evaluation == null) {
        return;
      }

      AppUpdateGateMode mode;
      switch (evaluation.requirement) {
        case AppUpdateRequirement.force:
          mode = AppUpdateGateMode.force;
          break;
        case AppUpdateRequirement.optional:
          final optionalKey = _optionalKey(evaluation);
          mode = _dismissedOptionalKey == optionalKey
              ? AppUpdateGateMode.allowed
              : AppUpdateGateMode.optional;
          break;
        case AppUpdateRequirement.allowed:
          mode = AppUpdateGateMode.allowed;
          break;
      }

      notifier.value = notifier.value.copyWith(
        mode: mode,
        evaluation: evaluation,
        reason: reason,
      );

      logInfo(
        '[APP_UPDATE] state=$mode reason=$reason '
        'current=${evaluation.currentVersion} '
        'minimum=${evaluation.minimumVersion} '
        'latest=${evaluation.latestVersion}',
      );
    } catch (error, stackTrace) {
      logError('[APP_UPDATE] evaluation failed: $error\n$stackTrace');
    }
  }

  void dismissOptional() {
    final evaluation = notifier.value.evaluation;
    if (evaluation == null || !evaluation.isOptional) return;

    _dismissedOptionalKey = _optionalKey(evaluation);
    notifier.value = notifier.value.copyWith(
      mode: AppUpdateGateMode.allowed,
      reason: 'optional_dismissed',
    );
  }

  Future<bool> openStore() async {
    final policy = notifier.value.platformPolicy;
    if (policy == null) return false;
    return AppRequirementGateService.instance.openStore(policy);
  }

  String _optionalKey(AppUpdateEvaluation evaluation) {
    return '${evaluation.currentVersion}|${evaluation.latestVersion ?? ''}';
  }

  Future<void> _saveCachedPolicy(AppUpdatePolicy policy) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_policyCacheKey, jsonEncode(policy.toMap()));
    } catch (error) {
      logWarning('[APP_UPDATE] cannot cache policy: $error');
    }
  }

  Future<AppUpdatePolicy?> _readCachedPolicy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_policyCacheKey);
      if (raw == null || raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AppUpdatePolicy.fromMap(Map<String, dynamic>.from(decoded));
    } catch (error) {
      logWarning('[APP_UPDATE] cannot read cached policy: $error');
      return null;
    }
  }
}
