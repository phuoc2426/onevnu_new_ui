import 'package:flutter/widgets.dart';

import 'app_guide_registry.dart';

class AppGuideRegistryScope extends InheritedWidget {
  const AppGuideRegistryScope({
    super.key,
    required this.registry,
    required super.child,
  });

  final AppGuideRegistry registry;

  static AppGuideRegistry of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppGuideRegistryScope>();

    if (scope == null) {
      throw FlutterError(
        'AppGuideRegistryScope not found. '
        'Wrap your app or main screen with AppGuideRegistryScope.',
      );
    }

    return scope.registry;
  }

  static AppGuideRegistry? maybeOf(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppGuideRegistryScope>();
    return scope?.registry;
  }

  @override
  bool updateShouldNotify(AppGuideRegistryScope oldWidget) {
    return registry != oldWidget.registry;
  }
}
