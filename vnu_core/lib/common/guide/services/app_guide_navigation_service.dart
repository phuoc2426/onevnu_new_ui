import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../core/app_showcase_scope.dart';
import '../models/app_guide_item.dart';
import '../registry/app_guide_registry.dart';
import 'app_guide_pending_service.dart';

class AppGuideNavigationService {
  const AppGuideNavigationService();

  Future<bool> openItem({
    required BuildContext context,
    required AppGuideRegistry registry,
    required AppGuideItem item,
  }) async {
    // Quan trọng: chạy action của item gốc trước khi resolve fallback.
    // Ví dụ profile.password -> app.open_profile_tab.
    // Ví dụ home.schedule.next_exam -> home.show_exam_tab.
    await _runBeforeHighlight(
      registry: registry,
      item: item,
    );

    var resolved = await _resolveRenderableItem(
      registry: registry,
      item: item,
      allowOpenAction: true,
    );

    var targetItem = resolved.item;
    var anchor = resolved.anchor;
    var anchorContext = anchor == null ? null : _resolveAnchorContext(anchor);

    if (anchor == null || anchorContext == null) {
      AppGuidePendingService.setPendingTarget(item.id);

      if (item.openAction != null) {
        await item.openAction!.call();
      }

      return false;
    }

    await _scrollToContext(anchorContext);

    // Sau khi scroll, resolve lại lần cuối vì widget có thể rebuild/unmount.
    resolved = await _resolveRenderableItem(
      registry: registry,
      item: targetItem,
      allowOpenAction: false,
      runBeforeHighlight: false,
    );

    targetItem = resolved.item;
    anchor = resolved.anchor;
    anchorContext = anchor == null ? null : _resolveAnchorContext(anchor);

    if (anchor == null || anchorContext == null) return false;
    if (!anchorContext.mounted) return false;

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
      allowOpenAction: true,
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
      // Group mặc định chỉ resolve những anchor đang có ở màn hiện tại.
      // Không chạy action từng step ở đây, vì ShowCaseWidget.next() không hỗ trợ async action.
      final resolved = await _resolveRenderableItem(
        registry: registry,
        item: item,
        allowOpenAction: false,
        runBeforeHighlight: false,
      );

      final anchor = resolved.anchor;
      final anchorContext =
          anchor == null ? null : _resolveAnchorContext(anchor);

      if (anchor != null && anchorContext != null && !seenKeys.contains(anchor.key)) {
        seenKeys.add(anchor.key);
        keys.add(anchor.key);
        ids.add(resolved.item.id);
      }
    }

    if (keys.isEmpty) return false;
    if (!firstContext.mounted) return false;

    debugPrint(
      '[GUIDE_GROUP_START] group=$groupId keys=${keys.length} ids=${ids.join(', ')}',
    );

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
    bool allowOpenAction = true,
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

    return _ResolvedGuideItem(item: item, anchor: anchor);
  }

  BuildContext? _resolveAnchorContext(AppGuideRuntimeAnchor anchor) {
    final keyContext = anchor.key.currentContext;
    if (keyContext != null) return keyContext;

    if (anchor.context.mounted) return anchor.context;

    return null;
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
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
      alignment: alignment,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );

    await Future<void>.delayed(const Duration(milliseconds: 220));
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
