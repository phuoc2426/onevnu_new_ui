import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

/// Shared guide visibility state for floating UI that must remain below the
/// showcase overlay. The Zalo speech bubble uses this to hide its root overlay
/// entry while a guide is active.
class AppGuideOverlayVisibility {
  AppGuideOverlayVisibility._();

  static final ValueNotifier<bool> notifier = ValueNotifier<bool>(false);

  static bool get isActive => notifier.value;

  static void show() {
    if (!notifier.value) {
      notifier.value = true;
    }
  }

  static void hide() {
    if (notifier.value) {
      notifier.value = false;
    }
  }
}

class AppShowcaseScope extends StatelessWidget {
  const AppShowcaseScope({
    super.key,
    required this.child,
    this.onFinish,
    this.onDismiss,
  });

  final Widget child;
  final VoidCallback? onFinish;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      enableAutoScroll: true,

      // Block taps on the dark barrier/background while a guide is visible.
      // IMPORTANT: do not wrap the whole app with AbsorbPointer here. The
      // showcase tooltip is rendered from this subtree; absorbing the entire
      // subtree also prevents its Previous/Next/Skip/Finish buttons from
      // receiving pointer events.
      disableBarrierInteraction: true,
      onFinish: () {
        AppGuideOverlayVisibility.hide();
        onFinish?.call();
      },
      onDismiss: (_) {
        AppGuideOverlayVisibility.hide();
        onDismiss?.call();
      },
      builder: (context) {
        return ValueListenableBuilder<bool>(
          valueListenable: AppGuideOverlayVisibility.notifier,
          child: child,
          builder: (context, guideActive, appChild) {
            // Keep Android/iOS system back disabled during an active guide,
            // but leave pointer handling to Showcase itself so the tooltip
            // controls remain clickable.
            return PopScope(
              canPop: !guideActive,
              child: appChild!,
            );
          },
        );
      },
    );
  }
}
