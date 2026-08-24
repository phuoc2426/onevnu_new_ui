import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/responsive/vnu_responsive_context.dart';

typedef VnuResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  VnuResponsiveContext responsive,
);

class VnuResponsiveBuilder extends StatelessWidget {
  const VnuResponsiveBuilder({super.key, required this.builder});

  final VnuResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => builder(
        context,
        VnuResponsiveContext.of(context, constraints: constraints),
      ),
    );
  }
}
