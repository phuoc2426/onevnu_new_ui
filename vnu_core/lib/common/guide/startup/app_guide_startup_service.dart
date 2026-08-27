import 'package:flutter/widgets.dart';

import '../flow/app_guide_flow.dart';
import '../flow/app_guide_flow_catalog.dart';
import '../flow/app_guide_flow_controller.dart';
import '../services/app_guide_cache_service.dart';
import '../services/app_guide_remote_manifest_service.dart';

class AppGuideStartupService {
  const AppGuideStartupService();

  static const String _legacyHomeSeenKey = 'home.intro';

  /// Resolves the first-open flow with this precedence:
  /// published remote manifest -> last-known-good remote cache -> bundled flow.
  /// A valid remote manifest with no HOME_FIRST_OPEN flow means the server has
  /// intentionally disabled automatic onboarding, so local fallback is NOT
  /// used in that case.
  Future<AppGuideFlow?> resolveFirstOpenHomeFlow() async {
    final manifest =
        await const AppGuideRemoteManifestService().loadBestEffort();

    if (manifest != null) {
      return manifest.firstFlowForTrigger(AppGuideFlow.homeFirstOpenTrigger);
    }

    return AppGuideFlowCatalog.flowById(AppGuideFlowCatalog.firstOpenHome);
  }

  /// P5 used `home.intro` as the run-once cache key. Migrate that state into
  /// revision 1 so existing users are not forced through the same first-open
  /// onboarding again just because P6 moved it to the server.
  Future<bool> hasSeenFirstOpenHome(AppGuideFlow flow) async {
    final cache = const AppGuideCacheService();
    final seen = await cache.hasSeenGroup(flow.seenCacheKey);
    if (seen) return true;

    if (flow.id == AppGuideFlowCatalog.firstOpenHome && flow.revision <= 1) {
      final legacySeen = await cache.hasSeenGroup(_legacyHomeSeenKey);
      if (legacySeen) {
        await cache.markGroupSeen(flow.seenCacheKey);
        return true;
      }
    }

    return false;
  }

  Future<bool> runFirstOpenHomeGuide({
    required BuildContext context,
    bool force = false,
  }) async {
    final flow = await resolveFirstOpenHomeFlow();
    if (flow == null || !context.mounted) return false;

    if (!force && await hasSeenFirstOpenHome(flow)) return false;
    if (!context.mounted) return false;

    return AppGuideFlowController.instance.start(
      context: context,
      flow: flow,
      force: force,
    );
  }
}
