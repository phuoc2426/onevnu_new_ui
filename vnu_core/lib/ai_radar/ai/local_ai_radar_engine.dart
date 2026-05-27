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

    final dominant = dimensions
        .where((e) => e.score >= 65.0)
        .take(3)
        .map(
          (e) => RadarSpike(
            code: e.code,
            nameVi: e.nameVi,
            score: e.score,
            explanationVi:
                '${e.nameVi} là vùng nổi bật vì có nhiều học phần liên quan đạt kết quả tốt.',
          ),
        )
        .toList();

    final weakList = [...dimensions]..sort((a, b) => a.score.compareTo(b.score));
    final weak = weakList
        .take(3)
        .map(
          (e) => RadarSpike(
            code: e.code,
            nameVi: e.nameVi,
            score: e.score,
            explanationVi:
                '${e.nameVi} còn yếu hoặc chưa ổn định do điểm học phần liên quan chưa cao hoặc thiếu học phần chứng minh.',
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
      confidence: _confidence(courses.length, dimensions.length, usedCache),
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

  double _confidence(int courseCount, int axisCount, bool usedCache) {
    final base = 50.0 + courseCount.clamp(0, 30) * 1.0 + axisCount * 2.0;
    return (base + (usedCache ? 5.0 : 0.0)).clamp(40.0, 95.0);
  }
}
