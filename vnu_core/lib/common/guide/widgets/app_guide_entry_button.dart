import 'package:flutter/material.dart';

import '../registry/app_guide_registry_scope.dart';
import '../services/app_guide_navigation_service.dart';

class AppGuideEntryButton extends StatelessWidget {
  const AppGuideEntryButton({
    super.key,
    required this.groupId,
    this.label = 'Hướng dẫn',
    this.icon = Icons.help_outline_rounded,
  });

  final String groupId;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final registry = AppGuideRegistryScope.of(context);

        await const AppGuideNavigationService().openGroup(
          context: context,
          registry: registry,
          groupId: groupId,
        );
      },
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
