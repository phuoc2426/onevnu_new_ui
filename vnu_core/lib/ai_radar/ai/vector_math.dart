import 'dart:math' as math;

class VectorMath {
  static double cosine(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;

    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  static List<double> mean(List<List<double>> vectors) {
    if (vectors.isEmpty) return const [];

    final dim = vectors.first.length;
    final result = List<double>.filled(dim, 0.0);

    for (final vector in vectors) {
      for (var i = 0; i < dim; i++) {
        result[i] += vector[i];
      }
    }

    for (var i = 0; i < dim; i++) {
      result[i] /= vectors.length;
    }

    return normalize(result);
  }

  static List<double> normalize(List<double> vector) {
    final norm = math.sqrt(
      vector.fold<double>(0.0, (sum, value) => sum + value * value),
    );

    if (norm == 0.0) return vector;

    return vector.map((e) => e / norm).toList(growable: false);
  }
}
