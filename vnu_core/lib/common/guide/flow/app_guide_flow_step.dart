class AppGuideFlowStep {
  const AppGuideFlowStep({
    required this.id,
    required this.itemId,
    this.delayMs = 220,
  });

  final String id;
  final String itemId;
  final int delayMs;
}
