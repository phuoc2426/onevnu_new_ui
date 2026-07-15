import '../cache/ai_axis_cache.dart';
import '../embedding/local_embedding_model.dart';
import '../models/academic_course.dart';
import '../models/ai_radar_analysis.dart';
import 'semantic_axis_discovery_engine.dart';
import 'semantic_scoring_engine.dart';

class LocalAiRadarEngine {
  LocalAiRadarEngine({
    required LocalEmbeddingModel embeddingModel,
    AiAxisCache? cache,
  })  : _embeddingModel = embeddingModel,
        _cache = cache ?? AiAxisCache() {
    _axisDiscovery = SemanticAxisDiscoveryEngine(
      embeddingModel: _embeddingModel,
    );
    _scoringEngine = SemanticScoringEngine(
      embeddingModel: _embeddingModel,
    );
  }

  final LocalEmbeddingModel _embeddingModel;
  final AiAxisCache _cache;

  late final SemanticAxisDiscoveryEngine _axisDiscovery;
  late final SemanticScoringEngine _scoringEngine;

  Future<AiRadarAnalysis> analyze({
    required String school,
    required String major,
    required List<AcademicCourse> courses,
  }) async {
    await _embeddingModel.load();

    if (courses.length < 3) {
      throw Exception('Cần ít nhất 3 học phần để phân tích.');
    }

    final cacheKey = AiAxisCache.buildKey(
      school: school,
      major: major,
    );

    var usedCache = true;
    var profile = await _cache.get(cacheKey);

    if (profile == null || profile.axes.length < 3) {
      usedCache = false;

      profile = await _axisDiscovery.discover(
        cacheKey: cacheKey,
        school: school,
        major: major,
        courses: courses,
      );

      await _cache.save(profile);
    }

    final dimensions = await _scoringEngine.score(
      profile: profile,
      courses: courses,
    );

    final avgScore = dimensions.isEmpty
        ? 0.0
        : dimensions.fold<double>(0.0, (sum, e) => sum + e.score) /
        dimensions.length;

    final dominant = dimensions
        .where((e) => e.score >= 75.0 && e.score >= avgScore + 8.0)
        .take(3)
        .map(
          (e) => RadarSpike(
        code: e.code,
        nameVi: e.nameVi,
        score: e.score,
        explanationVi:
        '${e.nameVi} là vùng nổi bật vì điểm cao hơn rõ rệt so với mặt bằng năng lực chung và có bằng chứng học phần đủ mạnh.',
      ),
    )
        .toList();

    final weakList = [...dimensions]..sort((a, b) => a.score.compareTo(b.score));
    final weak = weakList
        .where((e) => e.score <= 55.0 || e.score <= avgScore - 8.0)
        .take(3)
        .map(
          (e) => RadarSpike(
        code: e.code,
        nameVi: e.nameVi,
        score: e.score,
        explanationVi:
        '${e.nameVi} là vùng cần cải thiện do điểm thấp hơn mặt bằng chung, thiếu học phần lõi hoặc có học phần lõi kết quả chưa tốt.',
      ),
    )
        .toList();

    return AiRadarAnalysis(
      detectedMajorProfile: DetectedMajorProfile(
        school: school,
        facultyOrMajor: major,
        inferredDomain: profile.inferredDomain,
        inferredSpecificMajor: profile.inferredSpecificMajor,
        domainConfidence: profile.domainConfidence,
        reasonVi: profile.reasonVi,
      ),
      axisDesignLogic: const AxisDesignLogic(
        principleVi: 'Mũi nhọn được thiết kế theo yêu cầu năng lực cốt lõi của ngành học, học phần được dùng làm bằng chứng chấm điểm.',
        whyNotCourseClusterVi: 'Không tạo trục trực tiếp từ cụm học phần để tránh biểu đồ cân bằng giả.',
        axisSourceVi: 'Chuẩn năng lực đào tạo đại học local sinh bởi AI.',
      ),
      radarAxes: dimensions,
      dominantSpikes: dominant,
      weakSpikes: weak,
      overallInterpretationVi: _overall(profile.inferredDomain, dimensions),
      confidence: _confidence(courses.length, dimensions, usedCache),
      usedCache: usedCache,
    );
  }

  String _overall(String domain, List<RadarDimension> dimensions) {
    if (dimensions.isEmpty) return 'Chưa đủ dữ liệu để phân tích năng lực.';

    final sorted = [...dimensions]..sort((a, b) => b.score.compareTo(a.score));
    final top = sorted.take(2).map((e) => e.nameVi).join(', ');
    final weak = sorted.reversed.take(2).map((e) => e.nameVi).join(', ');

    return 'Học lực của sinh viên được phân tích theo chuẩn ngành học "$domain". '
        'Điểm mạnh nổi bật nằm ở các năng lực: $top. '
        'Các khía cạnh cần tập trung cải thiện hoặc bổ sung học phần tích lũy gồm: $weak.';
  }

  double _confidence(
      int courseCount,
      List<RadarDimension> dimensions,
      bool usedCache,
      ) {
    if (dimensions.isEmpty) return 35.0;

    final axesWithEvidence =
        dimensions.where((e) => e.evidenceCourses.isNotEmpty).length;

    final axesWithCoreEvidence = dimensions.where((e) {
      return e.evidenceCourses.any((c) => c.coreWeight >= 1.5);
    }).length;

    final evidenceCoverage = axesWithEvidence / dimensions.length;
    final coreCoverage = axesWithCoreEvidence / dimensions.length;

    final base = 40.0;
    final courseBonus = courseCount.clamp(0, 30) * 0.7;
    final evidenceBonus = evidenceCoverage * 20.0;
    final coreBonus = coreCoverage * 25.0;
    final cacheBonus = usedCache ? 3.0 : 0.0;

    return (base + courseBonus + evidenceBonus + coreBonus + cacheBonus)
        .clamp(30.0, 95.0);
  }
}
