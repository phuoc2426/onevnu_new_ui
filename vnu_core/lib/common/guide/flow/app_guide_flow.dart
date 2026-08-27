import 'app_guide_flow_step.dart';

class AppGuideFlow {
  const AppGuideFlow({
    required this.id,
    required this.title,
    required this.steps,
    this.description,
    this.triggerCode = manualTrigger,
    this.revision = 0,
    this.runOnce = true,
    this.priority = 0,
  });

  static const String homeFirstOpenTrigger = 'HOME_FIRST_OPEN';
  static const String manualTrigger = 'MANUAL';

  final String id;
  final String title;
  final String? description;
  final String triggerCode;
  final int revision;
  final List<AppGuideFlowStep> steps;
  final bool runOnce;
  final int priority;

  /// A published revision is a new guide experience. Cache by revision so an
  /// administrator can intentionally republish an onboarding flow and let it
  /// run once again without changing the stable flow code.
  String get seenCacheKey => revision > 0 ? '$id@r$revision' : id;

  bool get isRemote => revision > 0;
}
