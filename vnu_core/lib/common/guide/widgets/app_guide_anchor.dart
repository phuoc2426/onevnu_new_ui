import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../core/app_showcase_style.dart';
import '../core/app_showcase_tooltip.dart';
import '../registry/app_guide_global_registry.dart';
import '../registry/app_guide_registry.dart';
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

  AppGuideRegistry get _registry => globalAppGuideRegistry;

  bool _pendingChecked = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerAnchor();
    });
  }

  @override
  void didUpdateWidget(covariant AppGuideAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.id != widget.id) {
      _registry.unregisterAnchor(oldWidget.id, _showcaseKey);
      _pendingChecked = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerAnchor();
    });
  }

  Future<void> _registerAnchor() async {
    if (!mounted) return;
	debugPrint('[GUIDE_ANCHOR_REGISTER] ${widget.id}');

    _registry.registerAnchor(
      id: widget.id,
      key: _showcaseKey,
      context: context,
    );

    if (_pendingChecked) return;
    _pendingChecked = true;

    await Future<void>.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;

    await AppGuidePendingService.tryRunPendingForId(
      context: context,
      id: widget.id,
    );
  }

  @override
  void dispose() {
    _registry.unregisterAnchor(widget.id, _showcaseKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _registry.itemById(widget.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerAnchor();
    });

    if (item == null) {
      return widget.child;
    }

    final groupItems = _registry.itemsByGroup(item.groupId);
    final stepIndex = groupItems.indexWhere(
      (element) => element.id == widget.id,
    );
    final totalSteps = groupItems.isEmpty ? 1 : groupItems.length;

    final targetBorderRadius =
        item.targetBorderRadius ?? BorderRadius.circular(16);
    final targetPadding = item.targetPadding ?? const EdgeInsets.all(6);

    return Builder(
      builder: (targetContext) {
        void dismissShowcase() {
          ShowCaseWidget.of(targetContext).dismiss();
        }

        void previousShowcase() {
          ShowCaseWidget.of(targetContext).previous();
        }

        void nextShowcase() {
          ShowCaseWidget.of(targetContext).next();
        }

        return Showcase.withWidget(
          key: _showcaseKey,
          overlayColor: widget.style.overlayColor,
          overlayOpacity: widget.style.overlayOpacity,
          blurValue: widget.style.blurValue,
          targetPadding: targetPadding,
          targetBorderRadius: targetBorderRadius,
          tooltipPosition: item.tooltipPosition,
          container: AppShowcaseTooltip(
            title: item.title,
            description: item.description,
            icon: item.icon,
            stepIndex: stepIndex < 0 ? 0 : stepIndex,
            totalSteps: totalSteps,
            style: widget.style,
            onSkip: dismissShowcase,
            onPrevious: previousShowcase,
            onNext: nextShowcase,
            onFinish: dismissShowcase,
          ),
          child: widget.child,
        );
      },
    );
  }
}