import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_guide_item.dart';
import '../registry/app_guide_global_registry.dart';
import '../registry/app_guide_registry_scope.dart';
import 'app_guide_navigation_service.dart';

class AppGuidePendingService {
  static const Duration _maxPendingAge = Duration(seconds: 8);

  static String? _pendingTargetId;
  static String? _pendingGroupId;
  static AppGuideItem? _pendingItemOverride;
  static bool _pendingPreferHighlight = false;
  static DateTime? _pendingSince;
  static bool _running = false;
  static int _generation = 0;
  static Timer? _expiryTimer;
  static FutureOr<void> Function()? _onExpired;

  static bool get hasPending =>
      _pendingTargetId != null || _pendingGroupId != null;

  static void setPendingTarget(
    String targetId, {
    AppGuideItem? itemOverride,
    bool preferHighlight = false,
    FutureOr<void> Function()? onExpired,
  }) {
    _generation += 1;
    _pendingTargetId = targetId;
    _pendingGroupId = null;
    _pendingItemOverride = itemOverride;
    _pendingPreferHighlight = preferHighlight;
    _pendingSince = DateTime.now();
    _onExpired = onExpired;
    _scheduleExpiry();
  }

  static void setPendingGroup(
    String groupId, {
    FutureOr<void> Function()? onExpired,
  }) {
    _generation += 1;
    _pendingGroupId = groupId;
    _pendingTargetId = null;
    _pendingItemOverride = null;
    _pendingPreferHighlight = false;
    _pendingSince = DateTime.now();
    _onExpired = onExpired;
    _scheduleExpiry();
  }

  static void clear() {
    _generation += 1;
    _cancelExpiryTimer();
    _onExpired = null;
    _pendingTargetId = null;
    _pendingGroupId = null;
    _pendingItemOverride = null;
    _pendingPreferHighlight = false;
    _pendingSince = null;
    _running = false;
  }

  static bool _isExpired() {
    final since = _pendingSince;
    if (since == null) return false;
    return DateTime.now().difference(since) > _maxPendingAge;
  }

  static Future<void> tryRunPendingForId({
    required BuildContext context,
    required String id,
  }) async {
    if (_running) return;

    if (_isExpired()) {
      await _expirePending();
      return;
    }

    final registry =
        AppGuideRegistryScope.maybeOf(context) ?? globalAppGuideRegistry;

    final generation = _generation;

    if (_pendingTargetId == id) {
      final targetId = _pendingTargetId;
      if (targetId == null) return;

      final item = _pendingItemOverride ?? registry.itemById(targetId);
      final preferHighlight = _pendingPreferHighlight;
      final onExpired = _onExpired;
      if (item == null || !context.mounted) {
        clear();
        return;
      }

      _cancelExpiryTimer();
      _onExpired = null;
      _pendingTargetId = null;
      _pendingItemOverride = null;
      _pendingPreferHighlight = false;
      _pendingSince = null;
      _running = true;

      try {
        await Future<void>.delayed(const Duration(milliseconds: 120));

        if (!context.mounted || generation != _generation) return;

        final opened = await const AppGuideNavigationService().openItem(
          context: context,
          registry: registry,
          item: item,
          preferHighlight: preferHighlight,
          onPendingExpired: onExpired,
        );

        // The matching anchor can register while its route/tab is still not
        // actually visible. Preserve the flow continuation instead of
        // consuming the pending state and leaving FlowController stuck.
        if (!opened && !hasPending && onExpired != null) {
          await onExpired();
        }
      } finally {
        if (generation == _generation) {
          _running = false;
        }
      }
      return;
    }

    final pendingGroupId = _pendingGroupId;
    if (pendingGroupId == null) return;

    final group = registry.groupById(pendingGroupId);
    if (group == null) {
      clear();
      return;
    }
    if (!group.targetIds.contains(id)) return;
    if (!context.mounted) return;

    _cancelExpiryTimer();
    _onExpired = null;
    _pendingGroupId = null;
    _pendingSince = null;
    _running = true;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 120));

      if (!context.mounted || generation != _generation) return;

      await const AppGuideNavigationService().openGroup(
        context: context,
        registry: registry,
        groupId: pendingGroupId,
      );
    } finally {
      if (generation == _generation) {
        _running = false;
      }
    }
  }
  static void _scheduleExpiry() {
    _cancelExpiryTimer();
    final generation = _generation;
    _expiryTimer = Timer(_maxPendingAge, () {
      if (generation != _generation || !hasPending) return;
      unawaited(_expirePending());
    });
  }

  static void _cancelExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
  }

  static Future<void> _expirePending() async {
    if (!hasPending) return;

    debugPrint(
      '[GUIDE_PENDING_EXPIRED] target=$_pendingTargetId group=$_pendingGroupId',
    );

    final callback = _onExpired;
    clear();

    if (callback != null) {
      try {
        await callback();
      } catch (error) {
        debugPrint('[GUIDE_PENDING_EXPIRED_CALLBACK_ERROR] $error');
      }
    }
  }

}

