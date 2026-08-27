import 'package:flutter/foundation.dart';

import '../registry/app_guide_registry.dart';
import 'app_guide_flow.dart';
import 'app_guide_flow_step.dart';

class AppGuideFlowRuntimeSnapshot {
  const AppGuideFlowRuntimeSnapshot({
    required this.flow,
    required this.step,
    required this.index,
    required this.totalSteps,
  });

  final AppGuideFlow flow;
  final AppGuideFlowStep step;
  final int index;
  final int totalSteps;

  bool matchesAnchor(String anchorId, AppGuideRegistry registry) {
    if (step.itemId == anchorId) return true;
    if (step.fallbackTargetId == anchorId) return true;

    final localItem = registry.itemById(step.itemId);
    return localItem?.fallbackId == anchorId;
  }
}

/// Runtime-only state used to connect a one-key-at-a-time cross-screen flow to
/// the tooltip rendered by AppGuideAnchor. It intentionally contains no
/// navigation code and no server data fetching.
class AppGuideFlowRuntime {
  AppGuideFlowRuntime._();

  static final ValueNotifier<AppGuideFlowRuntimeSnapshot?> notifier =
      ValueNotifier<AppGuideFlowRuntimeSnapshot?>(null);

  static AppGuideFlowRuntimeSnapshot? get current => notifier.value;

  static void setCurrent(AppGuideFlowRuntimeSnapshot snapshot) {
    notifier.value = snapshot;
  }

  static void clear() {
    if (notifier.value != null) {
      notifier.value = null;
    }
  }
}
