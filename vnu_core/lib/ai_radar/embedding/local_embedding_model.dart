abstract class LocalEmbeddingModel {
  Future<void> load();

  Future<List<double>> embed(String text);

  Future<Map<String, List<double>>> embedMany(Map<String, String> texts) async {
    final result = <String, List<double>>{};

    for (final entry in texts.entries) {
      result[entry.key] = await embed(entry.value);
    }

    return result;
  }
}
