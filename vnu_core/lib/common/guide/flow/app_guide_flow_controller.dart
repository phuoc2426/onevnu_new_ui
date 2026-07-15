import 'package:flutter/widgets.dart';
import 'package:showcaseview/showcaseview.dart';

import '../registry/app_guide_registry_scope.dart';
import '../services/app_guide_cache_service.dart';
import '../services/app_guide_navigation_service.dart';
import '../services/app_guide_pending_service.dart';
import 'app_guide_flow.dart';

class AppGuideFlowController {
  AppGuideFlowController._();

  static final AppGuideFlowController instance = AppGuideFlowController._();

  AppGuideFlow? _flow;
  int _index = 0;
  bool _running = false;
  bool _markSeenOnFinish = false;

  bool get isRunning => _running && _flow != null;

  String? get currentItemId {
    final flow = _flow;
    if (!_running || flow == null) return null;
    if (_index < 0 || _index >= flow.steps.length) return null;
    return flow.steps[_index].itemId;
  }

  int get currentIndex => _index;

  int get totalSteps => _flow?.steps.length ?? 0;

  Future<void> start({
    required BuildContext context,
    required AppGuideFlow flow,
    bool force = false,
  }) async {
    final cache = const AppGuideCacheService();

    if (flow.runOnce && !force) {
      final hasSeen = await cache.hasSeenGroup(flow.id);
      if (hasSeen) return;
    }

    _flow = flow;
    _index = 0;
    _running = true;
    _markSeenOnFinish = flow.runOnce;

    await _runCurrent(context);
  }

  Future<void> next(BuildContext context) async {
    final flow = _flow;
    if (!_running || flow == null) return;

    _dismissCurrent(context);

    _index += 1;
    if (_index >= flow.steps.length) {
      await finish(context);
      return;
    }

    await _runCurrent(context);
  }

  Future<void> previous(BuildContext context) async {
    final flow = _flow;
    if (!_running || flow == null) return;

    _dismissCurrent(context);

    _index -= 1;
    if (_index < 0) {
      _index = 0;
    }

    await _runCurrent(context);
  }

  Future<void> skip(BuildContext context) async {
    _dismissCurrent(context);
    await finish(context);
  }

  Future<void> finish(BuildContext context) async {
    final flow = _flow;

    _dismissCurrent(context);
    AppGuidePendingService.clear();

    if (flow != null && _markSeenOnFinish) {
      await const AppGuideCacheService().markGroupSeen(flow.id);
    }

    _flow = null;
    _index = 0;
    _running = false;
    _markSeenOnFinish = false;
  }

  Future<void> _runCurrent(BuildContext context) async {
    final flow = _flow;
    if (!_running || flow == null) return;
    if (_index < 0 || _index >= flow.steps.length) return;

    final step = flow.steps[_index];

    await Future<void>.delayed(Duration(milliseconds: step.delayMs));

    if (!context.mounted) return;

    final registry = AppGuideRegistryScope.maybeOf(context);
    if (registry == null) return;

    final item = registry.itemById(step.itemId);
    if (item == null) {
      await next(context);
      return;
    }

    await const AppGuideNavigationService().openItem(
      context: context,
      registry: registry,
      item: item,
    );
  }

  void _dismissCurrent(BuildContext context) {
    try {
      ShowCaseWidget.of(context).dismiss();
    } catch (_) {
      // Ignore when the current context is already outside ShowCaseWidget.
    }
  }
}
