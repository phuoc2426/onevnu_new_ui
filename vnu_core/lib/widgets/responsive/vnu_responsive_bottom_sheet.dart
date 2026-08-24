import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/responsive/vnu_responsive_context.dart';

class VnuResponsiveBottomSheetFrame extends StatelessWidget {
  const VnuResponsiveBottomSheetFrame({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.maxHeightFraction = 0.9,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final double maxHeightFraction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final r = VnuResponsiveContext.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = (r.height - keyboard) * maxHeightFraction;
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
