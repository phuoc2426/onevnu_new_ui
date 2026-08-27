import 'package:flutter/material.dart';

import '../models/app_guide_group.dart';
import '../models/app_guide_item.dart';

typedef AppGuideRuntimeAction = Future<void> Function();

class AppGuideRuntimeAnchor {
  const AppGuideRuntimeAnchor({
    required this.id,
    required this.key,
    required this.context,
  });

  final String id;
  final GlobalKey key;
  final BuildContext context;

  BuildContext? get mountedContext {
    final keyContext = key.currentContext;
    if (keyContext != null && keyContext.mounted) return keyContext;
    if (context.mounted) return context;
    return null;
  }

  /// IndexedStack keeps inactive tabs mounted. `currentContext != null` alone
  /// therefore is not enough to decide whether a guide target is actually on
  /// screen. Walk the element ancestors and reject offstage targets.
  bool get isVisible {
    final targetContext = mountedContext;
    if (targetContext == null) return false;

    var offstage = false;
    targetContext.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is Offstage && widget.offstage) {
        offstage = true;
        return false;
      }
      return true;
    });

    if (offstage) return false;

    final route = ModalRoute.of(targetContext);
    if (route != null && !route.isCurrent) return false;

    final renderObject = targetContext.findRenderObject();
    if (renderObject == null || !renderObject.attached) return false;

    if (renderObject is RenderBox) {
      return renderObject.hasSize && !renderObject.size.isEmpty;
    }

    return true;
  }
}

class AppGuideRegistry {
  final Map<String, AppGuideItem> _items = {};
  final Map<String, AppGuideGroup> _groups = {};
  final Map<String, AppGuideRuntimeAnchor> _anchors = {};
  final Map<String, AppGuideRuntimeAction> _actions = {};

  List<AppGuideItem> get items => _items.values.toList();
  List<AppGuideGroup> get groups => _groups.values.toList();

  void registerItems(List<AppGuideItem> items) {
    for (final item in items) {
      final id = item.id.trim();
      assert(id.isNotEmpty, 'AppGuideItem.id must not be empty.');
      if (id.isEmpty) {
        debugPrint('[GUIDE_REGISTRY_REJECT] empty item id');
        continue;
      }
      _items[id] = item;
    }
  }

  void registerGroups(List<AppGuideGroup> groups) {
    for (final group in groups) {
      final id = group.id.trim();
      assert(id.isNotEmpty, 'AppGuideGroup.id must not be empty.');
      if (id.isEmpty) {
        debugPrint('[GUIDE_REGISTRY_REJECT] empty group id');
        continue;
      }
      _groups[id] = group;
    }
  }

  AppGuideItem? itemById(String id) => _items[id];

  AppGuideGroup? groupById(String id) => _groups[id];

  List<AppGuideItem> itemsByGroup(String groupId) {
    final group = groupById(groupId);
    if (group == null) return [];

    return group.targetIds
        .map(itemById)
        .whereType<AppGuideItem>()
        .toList();
  }

  List<AppGuideItem> itemsByModule(String moduleId) {
    return items.where((item) => item.moduleId == moduleId).toList();
  }

  void registerAnchor({
    required String id,
    required GlobalKey key,
    required BuildContext context,
  }) {
    final normalizedId = id.trim();
    assert(normalizedId.isNotEmpty, 'AppGuideAnchor.id must not be empty.');
    if (normalizedId.isEmpty) {
      debugPrint('[GUIDE_REGISTRY_REJECT] empty anchor id');
      return;
    }

    if (!_items.containsKey(normalizedId)) {
      debugPrint(
        '[GUIDE_CONTRACT_WARN] runtime anchor has no AppGuideItem: $normalizedId',
      );
    }

    final existing = _anchors[normalizedId];
    if (existing != null && existing.key != key && existing.isVisible) {
      debugPrint(
        '[GUIDE_CONTRACT_WARN] duplicate visible anchor id: $normalizedId',
      );
    }

    _anchors[normalizedId] = AppGuideRuntimeAnchor(
      id: normalizedId,
      key: key,
      context: context,
    );
  }

  void unregisterAnchor(String id, GlobalKey key) {
    final current = _anchors[id];
    if (current == null) return;

    if (current.key == key) {
      _anchors.remove(id);
    }
  }

  AppGuideRuntimeAnchor? anchorById(String id) => _anchors[id];

  bool isRendered(String id) {
    return _anchors[id]?.isVisible ?? false;
  }

  void registerAction({
    required String id,
    required AppGuideRuntimeAction action,
  }) {
    final normalizedId = id.trim();
    assert(normalizedId.isNotEmpty, 'AppGuide action id must not be empty.');
    if (normalizedId.isEmpty) {
      debugPrint('[GUIDE_REGISTRY_REJECT] empty action id');
      return;
    }

    _actions[normalizedId] = action;
  }

  void unregisterAction(String id) {
    if (id.trim().isEmpty) return;
    _actions.remove(id);
  }

  bool hasAction(String id) => id.trim().isNotEmpty && _actions.containsKey(id);

  Future<void> runAction(String? id) async {
    final normalizedId = id?.trim();
    if (normalizedId == null || normalizedId.isEmpty) return;

    final action = _actions[normalizedId];
    if (action == null) return;

    await action.call();
  }

  void clearRuntimeAnchors() {
    _anchors.clear();
  }

  void clearRuntimeActions() {
    _actions.clear();
  }

  void clearRuntime() {
    _anchors.clear();
    _actions.clear();
  }

  void clearAll() {
    _items.clear();
    _groups.clear();
    _anchors.clear();
    _actions.clear();
  }
}
