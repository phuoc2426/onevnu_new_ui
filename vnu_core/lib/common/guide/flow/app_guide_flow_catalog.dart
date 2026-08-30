import 'app_guide_flow.dart';
import 'app_guide_flow_step.dart';

class AppGuideFlowCatalog {
  const AppGuideFlowCatalog._();

  static const String firstOpenHome = 'flow.first_open_home';

  /// Bundled last-known fallback. Keep this sequence aligned with the P5
  /// Home `home.intro` experience; P6 changes where the scenario is managed,
  /// not the default user journey shipped before the server is configured.
  static const List<AppGuideFlow> flows = [
    AppGuideFlow(
      id: firstOpenHome,
      title: 'Hướng dẫn trang chủ',
      description:
          'Giới thiệu các khu vực chính trên trang chủ OneVNU.',
      triggerCode: AppGuideFlow.homeFirstOpenTrigger,
      runOnce: true,
      priority: 1000,
      steps: [
        AppGuideFlowStep(id: 'home_header', itemId: 'home.header'),
        AppGuideFlowStep(id: 'home_search', itemId: 'home.search'),
        AppGuideFlowStep(
          id: 'home_notification',
          itemId: 'home.notification',
        ),
        AppGuideFlowStep(id: 'home_qr', itemId: 'home.qr'),
        AppGuideFlowStep(id: 'home_overview', itemId: 'home.overview'),
        AppGuideFlowStep(id: 'home_schedule', itemId: 'home.schedule'),
        AppGuideFlowStep(
          id: 'home_quick_access',
          itemId: 'home.quick_access',
        ),
        AppGuideFlowStep(id: 'home_notice', itemId: 'home.notice'),
        AppGuideFlowStep(id: 'home_news', itemId: 'home.news'),
      ],
    ),
  ];

  static AppGuideFlow? flowById(String id) {
    for (final flow in flows) {
      if (flow.id == id) return flow;
    }
    return null;
  }
}
