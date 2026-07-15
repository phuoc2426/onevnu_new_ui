import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

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
      disableBarrierInteraction: true,
      onFinish: onFinish,
      onDismiss: (_) => onDismiss?.call(),
      builder: (context) {
        return child;
      },
    );
  }
}
