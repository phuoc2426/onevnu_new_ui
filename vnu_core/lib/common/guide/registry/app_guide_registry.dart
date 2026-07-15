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
      _items[item.id] = item;
    }
  }

  void registerGroups(List<AppGuideGroup> groups) {
    for (final group in groups) {
      _groups[group.id] = group;
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
    _anchors[id] = AppGuideRuntimeAnchor(
      id: id,
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
    return _anchors[id]?.key.currentContext != null;
  }

  void registerAction({
    required String id,
    required AppGuideRuntimeAction action,
  }) {
    _actions[id] = action;
  }

  void unregisterAction(String id) {
    _actions.remove(id);
  }

  bool hasAction(String id) => _actions.containsKey(id);

  Future<void> runAction(String? id) async {
    if (id == null) return;

    final action = _actions[id];
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
