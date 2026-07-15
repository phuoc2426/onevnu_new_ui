import 'app_guide_item.dart';

class AppGuideSearchResult {
  const AppGuideSearchResult({
    required this.item,
    required this.score,
    required this.fuzzyScore,
    required this.aiScore,
    required this.source,
  });

  final AppGuideItem item;
  final double score;
  final double fuzzyScore;
  final double aiScore;
  final String source;
}
