import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/responsive/vnu_adaptive_actions.dart';
import 'package:vnu_core/widgets/responsive/vnu_responsive_context.dart';

class VnuResponsiveDialog extends StatelessWidget {
  const VnuResponsiveDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final r = VnuResponsiveContext.of(context);
    final maxWidth = r.isCompact ? r.width - 32 : 560.0;
    final maxHeight = r.height * (r.isShortViewport ? 0.92 : 0.82);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: child)),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 20),
                VnuAdaptiveActions(children: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
