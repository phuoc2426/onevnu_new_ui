import 'dart:async';

import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../core/app_showcase_scope.dart';
import '../models/app_guide_item.dart';
import '../models/app_guide_item_type.dart';
import '../registry/app_guide_registry.dart';
import 'app_guide_pending_service.dart';

class AppGuideNavigationService {
  const AppGuideNavigationService();

  /// User-driven navigation (for example bottom navigation) must cancel the
  /// current guide session. This prevents a delayed Home guide from painting
  /// its spotlight over another IndexedStack tab.
  void cancelActiveGuide({required BuildContext context}) {
    AppGuidePendingService.clear();
    AppGuideOverlayVisibility.hide();

    try {
      ShowCaseWidget.of(context).dismiss();
    } catch (_) {
      // No active ShowCaseWidget for this context.
    }
  }

  Future<bool> openItem({
    required BuildContext context,
    required AppGuideRegistry registry,
    required AppGuideItem item,
    bool preferHighlight = false,
    FutureOr<void> Function()? onPendingExpired,
  }) async {
    await _runBeforeHighlight(
      registry: registry,
      item: item,
    );

    // A function item represents a navigation/action capability. When it has
    // an openAction, selecting it from search must perform the function rather
    // than silently falling back to a Home tile and highlighting the wrong UI.
    if (!preferHighlight &&
        item.type == AppGuideItemType.function &&
        item.openAction != null) {
      AppGuidePendingService.clear();
      AppGuideOverlayVisibility.hide();
      await item.openAction!.call();
      return true;
    }

    var resolved = await _resolveRenderableItem(
      registry: registry,
      item: item,
    );

    var targetItem = resolved.item;
    var anchor = resolved.anchor;
    var anchorContext = anchor == null ? null : _resolveAnchorContext(anchor);

    if (anchor == null || anchorContext == null) {
      if (item.openAction == null) {
        AppGuidePendingService.clear();
        return false;
      }

      AppGuidePendingService.setPendingTarget(
        item.id,
        itemOverride: item,
        preferHighlight: preferHighlight,
        onExpired: onPendingExpired,
      );
      await item.openAction!.call();
      return false;
    }

    await _scrollToContext(anchorContext);

    // After scrolling, resolve one last time because the widget may have been
    // rebuilt or moved between tabs.
    resolved = await _resolveRenderableItem(
      registry: registry,
      item: targetItem,
      runBeforeHighlight: false,
    );

    targetItem = resolved.item;
    anchor = resolved.anchor;
    anchorContext = anchor == null ? null : _resolveAnchorContext(anchor);

    if (anchor == null || anchorContext == null) return false;
    if (!anchorContext.mounted) return false;

    AppGuidePendingService.clear();
    AppGuideOverlayVisibility.show();
    try {
      ShowCaseWidget.of(anchorContext).startShowCase([anchor.key]);
      return true;
    } catch (_) {
      AppGuideOverlayVisibility.hide();
      rethrow;
    }
  }

  Future<bool> openGroup({
    required BuildContext context,
    required AppGuideRegistry registry,
    required String groupId,
  }) async {
    final items = registry.itemsByGroup(groupId);
    if (items.isEmpty) return false;

    final firstItem = items.first;

    await _runBeforeHighlight(
      registry: registry,
      item: firstItem,
    );

    final firstResolved = await _resolveRenderableItem(
      registry: registry,
      item: firstItem,
      runBeforeHighlight: false,
    );

    final firstAnchor = firstResolved.anchor;
    final firstContext =
        firstAnchor == null ? null : _resolveAnchorContext(firstAnchor);

    if (firstAnchor == null || firstContext == null) {
      AppGuidePendingService.setPendingGroup(groupId);

      if (firstItem.openAction != null) {
        await firstItem.openAction!.call();
      }

      return false;
    }

    await _scrollToContext(firstContext);

    final keys = <GlobalKey>[];
    final ids = <String>[];
    final seenKeys = <GlobalKey>{};

    for (final item in items) {
      // A static group only includes anchors that are currently visible on the
      // active screen. Cross-screen async sequences belong to FlowController.
      final resolved = await _resolveRenderableItem(
        registry: registry,
        item: item,
        runBeforeHighlight: false,
      );

      final anchor = resolved.anchor;
      final anchorContext =
          anchor == null ? null : _resolveAnchorContext(anchor);

      if (anchor != null &&
          anchorContext != null &&
          !seenKeys.contains(anchor.key)) {
        seenKeys.add(anchor.key);
        keys.add(anchor.key);
        ids.add(resolved.item.id);
      }
    }

    if (keys.isEmpty) {
      AppGuidePendingService.clear();
      return false;
    }
    if (!firstContext.mounted) return false;

    debugPrint(
      '[GUIDE_GROUP_START] group=$groupId keys=${keys.length} ids=${ids.join(', ')}',
    );

    AppGuidePendingService.clear();
    AppGuideOverlayVisibility.show();
    try {
      ShowCaseWidget.of(firstContext).startShowCase(keys);
      return true;
    } catch (_) {
      AppGuideOverlayVisibility.hide();
      rethrow;
    }
  }

  Future<_ResolvedGuideItem> _resolveRenderableItem({
    required AppGuideRegistry registry,
    required AppGuideItem item,
    bool runBeforeHighlight = true,
  }) async {
    if (runBeforeHighlight) {
      await _runBeforeHighlight(registry: registry, item: item);
    }

    await _waitForLayout(frames: 2);

    var anchor = registry.anchorById(item.id);
    if (anchor != null && _resolveAnchorContext(anchor) != null) {
      return _ResolvedGuideItem(item: item, anchor: anchor);
    }

    final fallbackId = item.fallbackId;
    if (fallbackId != null) {
      final fallbackItem = registry.itemById(fallbackId);
      final fallbackAnchor = registry.anchorById(fallbackId);

      if (fallbackItem != null &&
          fallbackAnchor != null &&
          _resolveAnchorContext(fallbackAnchor) != null) {
        return _ResolvedGuideItem(
          item: fallbackItem,
          anchor: fallbackAnchor,
        );
      }
    }

    return _ResolvedGuideItem(item: item, anchor: null);
  }

  BuildContext? _resolveAnchorContext(AppGuideRuntimeAnchor anchor) {
    if (!anchor.isVisible) return null;
    return anchor.mountedContext;
  }

  Future<void> _runBeforeHighlight({
    required AppGuideRegistry registry,
    required AppGuideItem item,
  }) async {
    await registry.runAction(item.beforeHighlightActionId);

    if (item.beforeHighlight != null) {
      await item.beforeHighlight!.call();
    }

    await _waitForLayout(frames: 2);
  }

  Future<void> _scrollToContext(
    BuildContext targetContext, {
    double alignment = 0.18,
  }) async {
    await _waitForLayout(frames: 2);

    if (!targetContext.mounted) return;

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      alignment: alignment,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );

    await Future<void>.delayed(const Duration(milliseconds: 100));
    await _waitForLayout(frames: 2);
  }

  Future<void> _waitForLayout({int frames = 1}) async {
    for (var i = 0; i < frames; i++) {
      await WidgetsBinding.instance.endOfFrame;
    }
  }
}

class _ResolvedGuideItem {
  const _ResolvedGuideItem({
    required this.item,
    required this.anchor,
  });

  final AppGuideItem item;
  final AppGuideRuntimeAnchor? anchor;
}

