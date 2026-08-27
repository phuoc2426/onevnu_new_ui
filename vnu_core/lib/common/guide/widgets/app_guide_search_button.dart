import 'package:flutter/material.dart';

import '../flow/app_guide_flow.dart';
import '../flow/app_guide_flow_controller.dart';
import '../registry/app_guide_global_registry.dart';
import '../registry/app_guide_registry_scope.dart';
import '../services/app_guide_ai_predictor.dart';
import '../services/app_guide_navigation_service.dart';
import '../services/app_guide_remote_manifest_service.dart';
import '../services/app_guide_search_service.dart';
import 'app_guide_search_sheet.dart';

class AppGuideSearchButton extends StatelessWidget {
  const AppGuideSearchButton({
    super.key,
    this.moduleId,
    this.icon = Icons.search_rounded,
    this.color,
  });

  final String? moduleId;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: () async {
        final pageContext = context;
        final registry =
            AppGuideRegistryScope.maybeOf(pageContext) ?? globalAppGuideRegistry;

        final searchService = AppGuideSearchService(
          items: registry.items,
          predictor: const AppGuideLightAiPredictor(),
        );

        final remoteService = const AppGuideRemoteManifestService();
        final manifest = await remoteService.loadBestEffort();
        final manualFlows = manifest
                ?.flowsForTrigger(AppGuideFlow.manualTrigger) ??
            const <AppGuideFlow>[];

        if (!pageContext.mounted) return;

        await showModalBottomSheet<void>(
          context: pageContext,
          isScrollControlled: true,
          useSafeArea: true,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withOpacity(0.45),
          builder: (sheetContext) {
            return AppGuideSearchSheet(
              moduleId: moduleId,
              searchService: searchService,
              manualFlows: manualFlows,
              onOpenFlow: (flow) async {
                Navigator.of(sheetContext, rootNavigator: true).pop();

                await Future<void>.delayed(
                  const Duration(milliseconds: 260),
                );

                if (!pageContext.mounted) return;

                await AppGuideFlowController.instance.start(
                  context: pageContext,
                  flow: flow,
                  force: true,
                );
              },
              onOpenGuide: (result) async {
                Navigator.of(sheetContext, rootNavigator: true).pop();

                await Future<void>.delayed(
                  const Duration(milliseconds: 260),
                );

                if (!pageContext.mounted) return;

                await const AppGuideNavigationService().openItem(
                  context: pageContext,
                  registry: registry,
                  item: result.item,
                );
              },
            );
          },
        );
      },
    );
  }
}

