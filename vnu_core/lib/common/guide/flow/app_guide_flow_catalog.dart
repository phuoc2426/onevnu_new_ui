import 'app_guide_flow.dart';
import 'app_guide_flow_step.dart';

class AppGuideFlowCatalog {
  const AppGuideFlowCatalog._();

  static const String firstOpenHome = 'flow.first_open_home';

  static const List<AppGuideFlow> flows = [
    AppGuideFlow(
      id: firstOpenHome,
      title: 'Hướng dẫn sử dụng OneVNU',
      runOnce: true,
      priority: 1000,
      steps: [
        AppGuideFlowStep(id: 'home_header', itemId: 'home.header'),
        AppGuideFlowStep(id: 'home_search', itemId: 'home.search'),
        AppGuideFlowStep(id: 'home_overview', itemId: 'home.overview'),
        AppGuideFlowStep(id: 'home_schedule', itemId: 'home.schedule'),
        AppGuideFlowStep(id: 'home_quick_access', itemId: 'home.quick_access'),
        AppGuideFlowStep(id: 'home_notice', itemId: 'home.notice'),
        AppGuideFlowStep(id: 'home_news', itemId: 'home.news'),

        // Các step dưới đây chỉ chạy đúng khi catalog có item openAction
        // và page đích có AppGuideAnchor tương ứng.
        AppGuideFlowStep(id: 'course_points_summary', itemId: 'course_points.summary'),
        AppGuideFlowStep(id: 'profile_header', itemId: 'profile.header'),
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
