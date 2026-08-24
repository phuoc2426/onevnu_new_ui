import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/responsive/vnu_responsive_context.dart';

/// Uses a row while every child has enough effective width, otherwise stacks
/// the children vertically. Text scaling participates in the decision.
class VnuResponsiveRow extends StatelessWidget {
  const VnuResponsiveRow({
    super.key,
    required this.children,
    this.minChildWidth = 240,
    this.spacing = 12,
    this.runSpacing = 12,
    this.forceStack = false,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final double minChildWidth;
  final double spacing;
  final double runSpacing;
  final bool forceStack;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1) return children.first;

    return LayoutBuilder(
      builder: (context, constraints) {
        final responsive = VnuResponsiveContext.of(context, constraints: constraints);
        final stack = forceStack || responsive.shouldStack(
          columns: children.length,
          minChildWidth: minChildWidth,
          spacing: spacing,
        );

        if (stack) {
          return Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                SizedBox(width: double.infinity, child: children[i]),
                if (i != children.length - 1) SizedBox(height: runSpacing),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: crossAxisAlignment,
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
