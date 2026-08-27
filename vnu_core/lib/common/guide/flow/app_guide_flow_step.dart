class AppGuideFlowStep {
  const AppGuideFlowStep({
    required this.id,
    required this.itemId,
    this.title,
    this.description,
    this.beforeActionId,
    this.fallbackTargetId,
    this.delayMs = 120,
    this.skipIfUnavailable = true,
  });

  final String id;
  final String itemId;

  /// Optional content overrides supplied by the Dynamic Guide manifest.
  /// When null, Flutter keeps the local AppGuideItem copy as the source of
  /// truth so a remote guide can safely omit presentation text.
  final String? title;
  final String? description;

  /// Symbolic action registered by Flutter. Backend only chooses the ID; it
  /// never sends executable code to the app.
  final String? beforeActionId;

  /// Optional remote override for the local item's fallback anchor.
  final String? fallbackTargetId;

  final int delayMs;
  final bool skipIfUnavailable;
}

