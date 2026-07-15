import '../models/app_guide_item.dart';
import '../models/app_guide_item_type.dart';
import '../models/app_guide_search_result.dart';
import 'app_guide_ai_predictor.dart';

class AppGuideSearchService {
  const AppGuideSearchService({
    required this.items,
    this.predictor,
  });

  final List<AppGuideItem> items;
  final AppGuideAiPredictor? predictor;

  Future<List<AppGuideSearchResult>> search(
    String rawQuery, {
    String? moduleId,
    int limit = 12,
  }) async {
    final query = _normalize(rawQuery);

    final pool = moduleId == null
        ? items
        : items.where((item) => item.moduleId == moduleId).toList();

    if (query.isEmpty) {
      final defaults = [...pool]
        ..sort((a, b) => _searchPriority(b).compareTo(_searchPriority(a)));

      return defaults.take(limit).map((item) {
        return AppGuideSearchResult(
          item: item,
          score: _searchPriority(item),
          fuzzyScore: 0,
          aiScore: 0,
          source: 'default',
        );
      }).toList();
    }

    final fuzzyScores = <String, double>{};
    for (final item in pool) {
      fuzzyScores[item.id] = _fuzzyScore(
        query,
        _normalize(item.searchableText),
      );
    }

    final bestFuzzy = fuzzyScores.values.isEmpty
        ? 0.0
        : fuzzyScores.values.reduce((a, b) => a > b ? a : b);

    final aiScores = bestFuzzy >= 0.68
        ? <String, double>{}
        : await predictor?.predictIntentScores(rawQuery, pool) ??
            <String, double>{};

    final results = pool.map((item) {
      final fuzzy = fuzzyScores[item.id] ?? 0.0;
      final ai = aiScores[item.id] ?? 0.0;

      final baseScore = bestFuzzy < 0.35
          ? fuzzy * 0.30 + ai * 0.70
          : fuzzy * 0.55 + ai * 0.45;

      final score = baseScore + _typeBoost(item) + _priorityBoost(item);

      return AppGuideSearchResult(
        item: item,
        score: score,
        fuzzyScore: fuzzy,
        aiScore: ai,
        source: ai > fuzzy ? 'ai' : 'mixed',
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return results.where((result) {
      return result.fuzzyScore >= 0.18 ||
          result.aiScore >= 0.18 ||
          result.item.preferInSearch;
    }).take(limit).toList();
  }

  double _searchPriority(AppGuideItem item) {
    return _typeBoost(item) + _priorityBoost(item);
  }

  double _typeBoost(AppGuideItem item) {
    switch (item.type) {
      case AppGuideItemType.page:
        return 0.30;
      case AppGuideItemType.function:
        return 0.25;
      case AppGuideItemType.section:
        return 0.12;
      case AppGuideItemType.widget:
        return 0.0;
    }
  }

  double _priorityBoost(AppGuideItem item) {
    final preferBoost = item.preferInSearch ? 0.10 : 0.0;
    return preferBoost + item.priority.clamp(0, 2000) / 10000;
  }

  double _fuzzyScore(String query, String text) {
    if (query.isEmpty || text.isEmpty) return 0;
    if (text.contains(query)) return 1.0;

    final queryTokens = query.split(' ').where((e) => e.isNotEmpty).toList();
    final textTokens = text.split(' ').where((e) => e.isNotEmpty).toSet();

    if (queryTokens.isEmpty) return 0;

    var matched = 0;
    for (final token in queryTokens) {
      if (textTokens.contains(token) || text.contains(token)) {
        matched++;
      }
    }

    return matched / queryTokens.length;
  }

  String _normalize(String input) {
    var value = input.toLowerCase().trim();

    const vietnamese = {
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'đ': 'd',
    };

    vietnamese.forEach((from, to) {
      value = value.replaceAll(from, to);
    });

    value = value.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    value = value.replaceAll(RegExp(r'\s+'), ' ');

    return value.trim();
  }
}
