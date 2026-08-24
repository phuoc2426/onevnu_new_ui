import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/responsive/vnu_responsive_context.dart';

class VnuAdaptiveActions extends StatelessWidget {
  const VnuAdaptiveActions({
    super.key,
    required this.children,
    this.minActionWidth = 132,
    this.spacing = 12,
    this.stackOnLargeText = true,
  });

  final List<Widget> children;
  final double minActionWidth;
  final double spacing;
  final bool stackOnLargeText;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = VnuResponsiveContext.of(context, constraints: constraints);
        final stack = (stackOnLargeText && r.isVeryLargeText) ||
            r.shouldStack(
              columns: children.length,
              minChildWidth: minActionWidth,
              spacing: spacing,
            );
        if (stack) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                SizedBox(width: double.infinity, child: children[i]),
                if (i != children.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}
