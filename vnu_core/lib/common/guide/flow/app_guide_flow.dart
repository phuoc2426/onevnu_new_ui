import 'app_guide_flow_step.dart';

class AppGuideFlow {
  const AppGuideFlow({
    required this.id,
    required this.title,
    required this.steps,
    this.runOnce = true,
    this.priority = 0,
  });

  final String id;
  final String title;
  final List<AppGuideFlowStep> steps;
  final bool runOnce;
  final int priority;
}
