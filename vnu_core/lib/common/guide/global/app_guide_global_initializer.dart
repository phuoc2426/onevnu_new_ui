import '../registry/app_guide_global_registry.dart';
import 'app_guide_catalog.dart';

class AppGuideGlobalInitializer {
  const AppGuideGlobalInitializer._();

  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;

    globalAppGuideRegistry
      ..registerItems(AppGuideCatalog.items)
      ..registerGroups(AppGuideCatalog.groups);

    _initialized = true;
  }
}
