import '../registry/app_guide_global_registry.dart';
import '../services/app_guide_contract_validator.dart';
import 'app_guide_catalog.dart';

class AppGuideGlobalInitializer {
  const AppGuideGlobalInitializer._();

  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;

    final items = AppGuideCatalog.items;
    final groups = AppGuideCatalog.groups;

    AppGuideContractValidator.debugValidateOrThrow(
      items: items,
      groups: groups,
    );

    globalAppGuideRegistry
      ..registerItems(items)
      ..registerGroups(groups);

    _initialized = true;
  }
}
