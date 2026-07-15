class AppGuideGroup {
  const AppGuideGroup({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.targetIds,
    this.description,
  });

  final String id;
  final String moduleId;
  final String title;
  final String? description;
  final List<String> targetIds;
}
