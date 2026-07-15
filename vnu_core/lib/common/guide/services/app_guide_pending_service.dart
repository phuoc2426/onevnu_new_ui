import 'package:flutter/material.dart';

import '../registry/app_guide_registry_scope.dart';
import 'app_guide_navigation_service.dart';

class AppGuidePendingService {
  static String? _pendingTargetId;
  static String? _pendingGroupId;
  static bool _running = false;

  static void setPendingTarget(String targetId) {
    _pendingTargetId = targetId;
    _pendingGroupId = null;
  }

  static void setPendingGroup(String groupId) {
    _pendingGroupId = groupId;
    _pendingTargetId = null;
  }

  static void clear() {
    _pendingTargetId = null;
    _pendingGroupId = null;
    _running = false;
  }

  static Future<void> tryRunPendingForId({
    required BuildContext context,
    required String id,
  }) async {
    if (_running) return;

    final registry = AppGuideRegistryScope.maybeOf(context);
    if (registry == null) return;

    if (_pendingTargetId == id) {
      final targetId = _pendingTargetId;
      _pendingTargetId = null;

      final item = registry.itemById(targetId!);
      if (item == null) return;
      if (!context.mounted) return;

      _running = true;
      await Future<void>.delayed(const Duration(milliseconds: 280));

      await const AppGuideNavigationService().openItem(
        context: context,
        registry: registry,
        item: item,
      );

      _running = false;
      return;
    }

    final pendingGroupId = _pendingGroupId;
    if (pendingGroupId == null) return;

    final group = registry.groupById(pendingGroupId);
    if (group == null) return;
    if (!group.targetIds.contains(id)) return;

    _pendingGroupId = null;

    if (!context.mounted) return;

    _running = true;
    await Future<void>.delayed(const Duration(milliseconds: 280));

    await const AppGuideNavigationService().openGroup(
      context: context,
      registry: registry,
      groupId: pendingGroupId,
    );

    _running = false;
  }
}
