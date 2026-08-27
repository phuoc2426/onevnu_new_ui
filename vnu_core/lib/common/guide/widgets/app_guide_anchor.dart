import 'dart:async';

import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../core/app_showcase_style.dart';
import '../core/app_showcase_tooltip.dart';
import '../flow/app_guide_flow_controller.dart';
import '../flow/app_guide_flow_runtime.dart';
import '../registry/app_guide_global_registry.dart';
import '../registry/app_guide_registry.dart';
import '../registry/app_guide_registry_scope.dart';
import '../services/app_guide_pending_service.dart';

class AppGuideAnchor extends StatefulWidget {
  const AppGuideAnchor({
    super.key,
    required this.id,
    required this.child,
    this.style = const AppShowcaseStyle(),
  });

  final String id;
  final Widget child;
  final AppShowcaseStyle style;

  @override
  State<AppGuideAnchor> createState() => _AppGuideAnchorState();
}

class _AppGuideAnchorState extends State<AppGuideAnchor> {
  final GlobalKey _showcaseKey = GlobalKey();

  AppGuideRegistry? _registry;
  bool _pendingChecked = false;

  AppGuideRegistry get _effectiveRegistry =>
      _registry ?? globalAppGuideRegistry;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerAnchor();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextRegistry =
        AppGuideRegistryScope.maybeOf(context) ?? globalAppGuideRegistry;
    if (!identical(_registry, nextRegistry)) {
      _registry?.unregisterAnchor(widget.id, _showcaseKey);
      _registry = nextRegistry;
      _pendingChecked = false;
    }
  }

  @override
  void didUpdateWidget(covariant AppGuideAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.id != widget.id) {
      _effectiveRegistry.unregisterAnchor(oldWidget.id, _showcaseKey);
      _pendingChecked = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerAnchor();
    });
  }

  Future<void> _registerAnchor() async {
    if (!mounted) return;

    final id = widget.id.trim();
    if (id.isEmpty) {
      debugPrint('[GUIDE_ANCHOR_REJECT] empty id');
      return;
    }

    debugPrint('[GUIDE_ANCHOR_REGISTER] $id');

    _effectiveRegistry.registerAnchor(
      id: id,
      key: _showcaseKey,
      context: context,
    );

    if (_pendingChecked) return;
    _pendingChecked = true;

    await Future<void>.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;

    await AppGuidePendingService.tryRunPendingForId(
      context: context,
      id: id,
    );
  }

  @override
  void dispose() {
    _effectiveRegistry.unregisterAnchor(widget.id, _showcaseKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _effectiveRegistry.itemById(widget.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerAnchor();
    });

    if (item == null) {
      return widget.child;
    }

    final groupItems = _effectiveRegistry.itemsByGroup(item.groupId);
    final staticStepIndex = groupItems.indexWhere(
      (element) => element.id == widget.id,
    );
    final staticTotalSteps = groupItems.isEmpty ? 1 : groupItems.length;

    final targetBorderRadius =
        item.targetBorderRadius ?? BorderRadius.circular(16);
    final targetPadding = item.targetPadding ?? const EdgeInsets.all(6);

    return ValueListenableBuilder<AppGuideFlowRuntimeSnapshot?>(
      valueListenable: AppGuideFlowRuntime.notifier,
      child: widget.child,
      builder: (context, runtime, child) {
        final activeRuntime = runtime != null &&
                runtime.matchesAnchor(widget.id, _effectiveRegistry)
            ? runtime
            : null;
        final isRuntimeStep = activeRuntime != null;
        final runtimeBaseItem = activeRuntime == null
            ? item
            : (_effectiveRegistry.itemById(activeRuntime.step.itemId) ?? item);

        final title = activeRuntime?.step.title ?? runtimeBaseItem.title;
        final description =
            activeRuntime?.step.description ?? runtimeBaseItem.description;
        final icon = runtimeBaseItem.icon;
        final stepIndex = activeRuntime?.index ??
            (staticStepIndex < 0 ? 0 : staticStepIndex);
        final totalSteps = activeRuntime?.totalSteps ?? staticTotalSteps;

        return Builder(
          builder: (targetContext) {
            void dismissStaticShowcase() {
              AppGuidePendingService.clear();
              ShowCaseWidget.of(targetContext).dismiss();
            }

            void previousShowcase() {
              if (isRuntimeStep) {
                unawaited(
                  AppGuideFlowController.instance.previous(targetContext),
                );
                return;
              }
              ShowCaseWidget.of(targetContext).previous();
            }

            void nextShowcase() {
              if (isRuntimeStep) {
                unawaited(AppGuideFlowController.instance.next(targetContext));
                return;
              }
              ShowCaseWidget.of(targetContext).next();
            }

            void skipShowcase() {
              if (isRuntimeStep) {
                unawaited(AppGuideFlowController.instance.skip(targetContext));
                return;
              }
              dismissStaticShowcase();
            }

            void finishShowcase() {
              if (isRuntimeStep) {
                unawaited(
                  AppGuideFlowController.instance.finish(
                    context: targetContext,
                  ),
                );
                return;
              }
              dismissStaticShowcase();
            }

            return Showcase.withWidget(
              key: _showcaseKey,
              // P7: during a guide the highlighted target is explanatory only.
              // The user must use Previous/Next/Skip/Finish from the tooltip.
              disableDefaultTargetGestures: true,
              disableMovingAnimation: true,
              overlayColor: widget.style.overlayColor,
              overlayOpacity: widget.style.overlayOpacity,
              blurValue: widget.style.blurValue,
              targetPadding: targetPadding,
              targetBorderRadius: targetBorderRadius,
              tooltipPosition: item.tooltipPosition,
              container: AppShowcaseTooltip(
                title: title,
                description: description,
                icon: icon,
                stepIndex: stepIndex,
                totalSteps: totalSteps,
                style: widget.style,
                onSkip: skipShowcase,
                onPrevious: previousShowcase,
                onNext: nextShowcase,
                onFinish: finishShowcase,
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}

