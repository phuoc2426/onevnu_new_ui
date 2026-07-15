import '../models/app_guide_item.dart';

abstract class AppGuideAiPredictor {
  Future<Map<String, double>> predictIntentScores(
    String query,
    List<AppGuideItem> items,
  );
}

class AppGuideLightAiPredictor implements AppGuideAiPredictor {
  const AppGuideLightAiPredictor();

  @override
  Future<Map<String, double>> predictIntentScores(
    String query,
    List<AppGuideItem> items,
  ) async {
    final normalizedQuery = _normalize(query);
    final queryTokens = normalizedQuery
        .split(' ')
        .where((token) => token.trim().isNotEmpty)
        .toSet();

    if (queryTokens.isEmpty) return {};

    final scores = <String, double>{};

    for (final item in items) {
      final text = _normalize(item.searchableText);
      final textTokens = text
          .split(' ')
          .where((token) => token.trim().isNotEmpty)
          .toSet();

      final overlap = queryTokens.intersection(textTokens).length;
      var score = overlap / queryTokens.length;

      if (text.contains(normalizedQuery)) {
        score = score < 0.85 ? 0.85 : score;
      }

      if (score > 0) {
        scores[item.id] = score.clamp(0.0, 1.0);
      }
    }

    return scores;
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
