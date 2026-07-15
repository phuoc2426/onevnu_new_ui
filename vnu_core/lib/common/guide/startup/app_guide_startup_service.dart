import 'package:flutter/widgets.dart';

import '../flow/app_guide_flow_catalog.dart';
import '../flow/app_guide_flow_controller.dart';

class AppGuideStartupService {
  const AppGuideStartupService();

  Future<void> runFirstOpenHomeGuide({
    required BuildContext context,
    bool force = false,
  }) async {
    final flow = AppGuideFlowCatalog.flowById(AppGuideFlowCatalog.firstOpenHome);
    if (flow == null) return;

    await AppGuideFlowController.instance.start(
      context: context,
      flow: flow,
      force: force,
    );
  }
}
