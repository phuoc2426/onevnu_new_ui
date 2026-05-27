import '../embedding/local_embedding_model.dart';
import '../models/academic_course.dart';
import '../models/ai_radar_analysis.dart';
import '../models/radar_axis_profile.dart';
import 'vector_math.dart';

class SemanticScoringEngine {
  SemanticScoringEngine({
    required this.embeddingModel,
  });

  final LocalEmbeddingModel embeddingModel;

  Future<List<RadarDimension>> score({
    required RadarAxisProfile profile,
    required List<AcademicCourse> courses,
  }) async {
    final result = <RadarDimension>[];

    for (final axis in profile.axes) {
      result.add(await _scoreAxis(axis, courses));
    }

    // Sort by score descending to identify dominant capabilities
    result.sort((a, b) => b.score.compareTo(a.score));

    return result;
  }

  Future<RadarDimension> _scoreAxis(
    RadarAxis axis,
    List<AcademicCourse> courses,
  ) async {
    final axisVector = await embeddingModel.embed(axis.seedText);

    final evidences = <EvidenceCourse>[];

    double weightedSum = 0;
    double maxPossible = 0;
    bool hasCoreCourse = false;
    bool hasWeakCoreCourse = false;

    for (final course in courses) {
      final courseVector = await embeddingModel.embed(course.semanticText);

      final rawSimilarity = VectorMath.cosine(axisVector, courseVector);
      // Map cosine similarity [-1, 1] to relevance [0, 1]
      final relevance = ((rawSimilarity + 1) / 2).clamp(0.0, 1.0);

      // Filtering relevance threshold
      if (relevance < 0.35) continue;

      // Determine core weight semantically
      double coreWeight = 1.0;
      if (relevance >= 0.75) {
        coreWeight = 1.5;
        hasCoreCourse = true;
        if (course.grade < 5.5) {
          hasWeakCoreCourse = true;
        }
      } else if (relevance < 0.55) {
        coreWeight = 0.7;
      }

      weightedSum += relevance * course.normalizedGrade * course.credits * coreWeight;
      maxPossible += relevance * course.credits * coreWeight;

      evidences.add(
        EvidenceCourse(
          courseName: course.name,
          grade: course.grade,
          credits: course.credits,
          relevance: relevance,
          coreWeight: coreWeight,
          impact: course.grade >= 7.0
              ? 'positive'
              : course.grade < 5.5
                  ? 'negative'
                  : 'neutral',
          reasonVi: 'Mức độ liên quan: ${(relevance * 100).round()}%, ${course.credits.toStringAsFixed(0)} tín chỉ.',
        ),
      );
    }

    // Sort evidences by relevance descending
    evidences.sort((a, b) => b.relevance.compareTo(a.relevance));

    double finalScore = 0.0;
    String missingEvidenceVi = '';

    if (evidences.isEmpty || maxPossible == 0) {
      // Highly important axis with zero evidence -> Cap at low score
      finalScore = axis.axisImportance >= 0.8 ? 15.0 : 25.0;
      missingEvidenceVi = 'Thiếu bằng chứng: Không tìm thấy học phần nào trong bảng điểm liên quan đến năng lực cốt lõi này.';
    } else {
      final axisScore = (weightedSum / maxPossible) * 100;

      // 1. Evidence bonus (+3 if there are at least 4 stable evidence courses with grade >= 6.5)
      int stableCourses = evidences.where((e) => e.relevance >= 0.5 && e.grade >= 6.5).length;
      double evidenceBonus = stableCourses >= 4 ? 3.0 : 0.0;

      // 2. Weak core penalty (-5 to -15 if any core course has grade < 5.5)
      double weakCorePenalty = hasWeakCoreCourse ? 12.0 : 0.0;

      // 3. Missing evidence penalty (-10 to -25 if important axis lacks strong evidence courses)
      double missingEvidencePenalty = 0.0;
      if (!hasCoreCourse && axis.axisImportance >= 0.8) {
        missingEvidencePenalty = 15.0;
        missingEvidenceVi = 'Thiếu bằng chứng: Chưa hoàn thành các học phần chuyên môn cốt lõi của năng lực này.';
      }

      finalScore = (axisScore + evidenceBonus - weakCorePenalty - missingEvidencePenalty).clamp(0.0, 100.0);
    }

    final level = _level(finalScore);

    return RadarDimension(
      code: axis.code,
      nameVi: axis.nameVi,
      nameEn: axis.nameEn,
      sectorRoleVi: axis.sectorRoleVi,
      axisImportance: axis.axisImportance,
      axisDefinitionVi: axis.axisDefinitionVi,
      expectedEvidenceVi: axis.expectedEvidenceVi,
      score: finalScore,
      level: level,
      evidenceCourses: evidences.take(6).toList(),
      missingEvidenceVi: missingEvidenceVi,
      reasonVi: _reason(axis, finalScore, evidences, missingEvidenceVi),
    );
  }

  String _level(double score) {
    if (score >= 85) return 'rất mạnh';
    if (score >= 70) return 'mạnh';
    if (score >= 60) return 'khá';
    if (score >= 50) return 'trung bình';
    return 'yếu';
  }

  String _reason(
    RadarAxis axis,
    double score,
    List<EvidenceCourse> evidences,
    String missingEvidence,
  ) {
    if (evidences.isEmpty) {
      return 'Năng lực được đánh giá ở mức thấp (${score.round()}/100) do thiếu hoàn toàn học phần chứng minh trong bảng điểm.';
    }

    final positive = evidences
        .where((e) => e.grade >= 7.0)
        .map((e) => e.courseName)
        .take(3)
        .toList();

    final negative = evidences
        .where((e) => e.grade < 5.5)
        .map((e) => e.courseName)
        .take(2)
        .toList();

    final buffer = StringBuffer();
    buffer.write('${axis.nameVi} đạt ${score.round()}/100 (${_level(score)}). ');

    if (positive.isNotEmpty) {
      buffer.write('Môn học hỗ trợ tốt: ${positive.join(', ')}. ');
    }

    if (negative.isNotEmpty) {
      buffer.write('Học phần có kết quả chưa cao kéo điểm xuống: ${negative.join(', ')}. ');
    }

    if (missingEvidence.isNotEmpty) {
      buffer.write(missingEvidence);
    } else {
      buffer.write('Điểm số phản ánh đúng học lực các môn học tương đồng ngữ nghĩa.');
    }

    return buffer.toString();
  }
}
