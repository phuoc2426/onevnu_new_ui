import 'package:flutter/widgets.dart';

import '../models/app_guide_item.dart';
import '../registry/app_guide_global_registry.dart';
import '../registry/app_guide_registry_scope.dart';
import '../services/app_guide_cache_service.dart';
import '../services/app_guide_navigation_service.dart';
import '../services/app_guide_pending_service.dart';
import 'app_guide_flow.dart';
import 'app_guide_flow_step.dart';
import 'app_guide_flow_runtime.dart';

class AppGuideFlowController {
  AppGuideFlowController._();

  static final AppGuideFlowController instance = AppGuideFlowController._();

  AppGuideFlow? _flow;
  int _index = 0;
  bool _running = false;
  bool _markSeenOnFinish = false;
  int _sessionGeneration = 0;

  bool get isRunning => _running && _flow != null;

  String? get currentItemId {
    final flow = _flow;
    if (!_running || flow == null) return null;
    if (_index < 0 || _index >= flow.steps.length) return null;
    return flow.steps[_index].itemId;
  }

  int get currentIndex => _index;

  int get totalSteps => _flow?.steps.length ?? 0;

  Future<bool> start({
    required BuildContext context,
    required AppGuideFlow flow,
    bool force = false,
  }) async {
    final cache = const AppGuideCacheService();

    if (flow.steps.isEmpty) return false;

    if (flow.runOnce && !force) {
      final hasSeen = await cache.hasSeenGroup(flow.seenCacheKey);
      if (hasSeen) return false;
    }

    if (isRunning) {
      await cancel(context: context);
    }

    _sessionGeneration += 1;
    _flow = flow;
    _index = 0;
    _running = true;
    _markSeenOnFinish = flow.runOnce;

    final generation = _sessionGeneration;
    await _runCurrent(context, generation: generation);
    return generation == _sessionGeneration && _running;
  }

  Future<void> next(BuildContext context) async {
    final flow = _flow;
    if (!_running || flow == null) return;

    _dismissCurrent(context);

    _index += 1;
    if (_index >= flow.steps.length) {
      await finish(context: context);
      return;
    }

    await _runCurrent(context, generation: _sessionGeneration);
  }

  Future<void> previous(BuildContext context) async {
    final flow = _flow;
    if (!_running || flow == null) return;

    _dismissCurrent(context);

    _index -= 1;
    if (_index < 0) {
      _index = 0;
    }

    await _runCurrent(context, generation: _sessionGeneration);
  }

  Future<void> skip(BuildContext context) async {
    await finish(context: context);
  }

  /// Completes the flow intentionally. For run-once flows this marks the
  /// current published revision as seen.
  Future<void> finish({required BuildContext context}) async {
    final flow = _flow;
    final shouldMarkSeen = flow != null && _markSeenOnFinish;
    final seenCacheKey = flow?.seenCacheKey;

    _sessionGeneration += 1;
    _clearRuntimeState();
    const AppGuideNavigationService().cancelActiveGuide(context: context);

    if (shouldMarkSeen && seenCacheKey != null) {
      await const AppGuideCacheService().markGroupSeen(seenCacheKey);
    }
  }

  /// Cancels because the user navigated away or the owning screen is no longer
  /// active. Unlike finish/skip, cancellation does NOT mark a run-once flow as
  /// seen, so returning to the correct screen may safely retry later.
  Future<void> cancel({required BuildContext context}) async {
    _sessionGeneration += 1;
    _clearRuntimeState();
    const AppGuideNavigationService().cancelActiveGuide(context: context);
  }

  Future<void> _runCurrent(
    BuildContext context, {
    required int generation,
  }) async {
    final flow = _flow;
    if (!_running || flow == null) return;
    if (_index < 0 || _index >= flow.steps.length) return;

    final step = flow.steps[_index];

    await Future<void>.delayed(Duration(milliseconds: step.delayMs));

    if (generation != _sessionGeneration || !_running) return;
    if (!context.mounted) {
      _clearRuntimeState();
      return;
    }

    final registry =
        AppGuideRegistryScope.maybeOf(context) ?? globalAppGuideRegistry;

    final localItem = registry.itemById(step.itemId);
    if (localItem == null) {
      debugPrint('[GUIDE_FLOW_MISSING_TARGET] ${step.itemId}');
      if (step.skipIfUnavailable) {
        await next(context);
      } else {
        await cancel(context: context);
      }
      return;
    }

    final runtimeItem = _applyStepOverrides(localItem, step);

    AppGuideFlowRuntime.setCurrent(
      AppGuideFlowRuntimeSnapshot(
        flow: flow,
        step: step,
        index: _index,
        totalSteps: flow.steps.length,
      ),
    );

    final opened = await const AppGuideNavigationService().openItem(
      context: context,
      registry: registry,
      item: runtimeItem,
      preferHighlight: true,
      onPendingExpired: () async {
        if (generation != _sessionGeneration || !_running) return;
        if (!context.mounted) {
          _clearRuntimeState();
          return;
        }

        debugPrint('[GUIDE_FLOW_PENDING_TIMEOUT] ${step.itemId}');
        if (step.skipIfUnavailable) {
          await next(context);
        } else {
          await cancel(context: context);
        }
      },
    );

    if (generation != _sessionGeneration || !_running) return;

    // false + pending means navigation has started and the destination anchor
    // will resume this exact step after it registers. false without pending is
    // a genuinely unavailable target.
    if (!opened && !AppGuidePendingService.hasPending) {
      debugPrint('[GUIDE_FLOW_TARGET_UNAVAILABLE] ${step.itemId}');
      if (step.skipIfUnavailable) {
        await next(context);
      } else {
        await cancel(context: context);
      }
    }
  }

  AppGuideItem _applyStepOverrides(
    AppGuideItem item,
    AppGuideFlowStep step,
  ) {
    return item.copyWith(
      title: step.title ?? item.title,
      description: step.description ?? item.description,
      beforeHighlightActionId:
          step.beforeActionId ?? item.beforeHighlightActionId,
      fallbackId: step.fallbackTargetId ?? item.fallbackId,
    );
  }

  void _clearRuntimeState() {
    AppGuidePendingService.clear();
    AppGuideFlowRuntime.clear();
    _flow = null;
    _index = 0;
    _running = false;
    _markSeenOnFinish = false;
  }

  void _dismissCurrent(BuildContext context) {
    AppGuidePendingService.clear();
    AppGuideFlowRuntime.clear();
    const AppGuideNavigationService().cancelActiveGuide(context: context);
  }
}
