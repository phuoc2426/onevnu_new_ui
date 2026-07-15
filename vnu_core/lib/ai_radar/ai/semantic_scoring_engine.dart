import 'dart:math' as math;

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

    final assignedCourses = await _assignCoursesToAxes(
      profile: profile,
      courses: courses,
    );

    for (final axis in profile.axes) {
      final matches = assignedCourses[axis.code] ?? <CourseAxisMatch>[];

      result.add(
        _scoreAxis(
          axis: axis,
          matches: matches,
        ),
      );
    }

    result.sort((a, b) => b.score.compareTo(a.score));

    return result;
  }

  Future<Map<String, List<CourseAxisMatch>>> _assignCoursesToAxes({
    required RadarAxisProfile profile,
    required List<AcademicCourse> courses,
  }) async {
    final axisVectors = <String, List<double>>{};

    for (final axis in profile.axes) {
      axisVectors[axis.code] = await embeddingModel.embed(axis.seedText);
    }

    final result = <String, List<CourseAxisMatch>>{
      for (final axis in profile.axes) axis.code: <CourseAxisMatch>[],
    };

    for (final course in courses) {
      final courseVector = await embeddingModel.embed(course.semanticText);

      final matches = <CourseAxisMatch>[];

      for (final axis in profile.axes) {
        final rawSimilarity = VectorMath.cosine(
          axisVectors[axis.code]!,
          courseVector,
        );

        // Không dùng ((cosine + 1) / 2) nữa vì cách đó nâng nền similarity,
        // khiến môn học bị rải sang quá nhiều trục.
        final relevance = rawSimilarity.clamp(0.0, 1.0);

        matches.add(
          CourseAxisMatch(
            course: course,
            axisCode: axis.code,
            relevance: relevance,
            shareWeight: 1.0,
          ),
        );
      }

      matches.sort((a, b) => b.relevance.compareTo(a.relevance));

      if (matches.isEmpty) continue;

      final top1 = matches[0];
      final top2 = matches.length > 1 ? matches[1] : null;

      // Nếu môn không liên quan đủ mạnh tới bất kỳ trục nào thì bỏ qua.
      if (top1.relevance < 0.58) {
        continue;
      }

      // Trục phù hợp nhất luôn được nhận đóng góp đầy đủ.
      result[top1.axisCode]!.add(
        CourseAxisMatch(
          course: course,
          axisCode: top1.axisCode,
          relevance: top1.relevance,
          shareWeight: 1.0,
        ),
      );

      // Chỉ cho phép môn đóng góp sang trục thứ 2 nếu nó thật sự là môn liên ngành.
      if (top2 != null) {
        final closeEnough = top1.relevance - top2.relevance < 0.12;
        final strongEnough = top2.relevance >= 0.58;

        if (closeEnough && strongEnough) {
          result[top2.axisCode]!.add(
            CourseAxisMatch(
              course: course,
              axisCode: top2.axisCode,
              relevance: top2.relevance,
              shareWeight: 0.55,
            ),
          );
        }
      }
    }

    return result;
  }

  RadarDimension _scoreAxis({
    required RadarAxis axis,
    required List<CourseAxisMatch> matches,
  }) {
    final evidences = <EvidenceCourse>[];

    double weightedSum = 0.0;
    double maxPossible = 0.0;

    bool hasCoreCourse = false;

    for (final match in matches) {
      final course = match.course;
      final relevance = match.relevance;
      final shareWeight = match.shareWeight;

      double coreWeight = 1.0;

      if (relevance >= 0.78 && shareWeight >= 1.0) {
        coreWeight = 1.6;
        hasCoreCourse = true;
      } else if (relevance >= 0.65) {
        coreWeight = 1.2;
      } else {
        coreWeight = 0.7;
      }

      final courseScore = _grade4ToScore(course.grade4);

      weightedSum +=
          relevance * courseScore * course.credits * coreWeight * shareWeight;

      maxPossible +=
          relevance * course.credits * coreWeight * shareWeight;

      evidences.add(
        EvidenceCourse(
          courseName: course.name,
          grade: course.grade4,
          credits: course.credits,
          relevance: relevance,
          coreWeight: coreWeight * shareWeight,
          impact: course.grade4 >= 3.0
              ? 'positive'
              : course.grade4 < 2.0
              ? 'negative'
              : 'neutral',
          reasonVi:
          'Mức độ liên quan: ${(relevance * 100).round()}%, '
              'trọng số đóng góp: ${(shareWeight * 100).round()}%, '
              '${course.credits.toStringAsFixed(0)} tín chỉ, '
              'điểm hệ 4: ${course.grade4.toStringAsFixed(2)}.',
        ),
      );
    }

    evidences.sort((a, b) => b.relevance.compareTo(a.relevance));

    double finalScore = 0.0;
    String missingEvidenceVi = '';

    if (evidences.isEmpty || maxPossible == 0.0) {
      finalScore = axis.axisImportance >= 0.85 ? 12.0 : 20.0;
      missingEvidenceVi =
      'Thiếu bằng chứng: Không tìm thấy học phần liên quan trực tiếp đến năng lực này.';
    } else {
      final axisScore = weightedSum / maxPossible;

      final effectiveCredits = evidences.fold<double>(
        0.0,
            (sum, e) => sum + e.credits * e.relevance * e.coreWeight,
      );

      final expectedCredits = 10.0 * axis.axisImportance;

      final coverageFactor =
      math.sqrt((effectiveCredits / expectedCredits).clamp(0.25, 1.0));

      final stableCourses = evidences
          .where((e) => e.relevance >= 0.6 && e.grade >= 3.0)
          .length;

      final evidenceBonus = stableCourses >= 4 ? 4.0 : 0.0;

      final coreCourses = evidences
          .where((e) => e.coreWeight >= 1.5)
          .toList(growable: false);

      final weakCorePenalty = _weakCorePenalty(coreCourses);

      double missingEvidencePenalty = 0.0;

      final shouldCapByMissingCore =
          !hasCoreCourse && axis.axisImportance >= 0.85;

      if (shouldCapByMissingCore) {
        missingEvidencePenalty = 25.0;
        missingEvidenceVi =
        'Thiếu bằng chứng: Chưa có học phần lõi đủ mạnh cho năng lực này.';
      }

      finalScore = axisScore * coverageFactor +
          evidenceBonus -
          weakCorePenalty -
          missingEvidencePenalty;

      if (shouldCapByMissingCore) {
        finalScore = finalScore.clamp(0.0, 58.0);
      } else {
        finalScore = finalScore.clamp(0.0, 100.0);
      }
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
      reasonVi: _reason(
        axis: axis,
        score: finalScore,
        evidences: evidences,
        missingEvidence: missingEvidenceVi,
      ),
    );
  }

  double _grade4ToScore(double grade4) {
    if (grade4 >= 3.7) return 96.0;
    if (grade4 >= 3.5) return 92.0;
    if (grade4 >= 3.2) return 85.0;
    if (grade4 >= 3.0) return 78.0;
    if (grade4 >= 2.5) return 68.0;
    if (grade4 >= 2.0) return 56.0;
    if (grade4 >= 1.5) return 42.0;
    if (grade4 >= 1.0) return 30.0;
    return 12.0;
  }

  double _weakCorePenalty(List<EvidenceCourse> coreCourses) {
    if (coreCourses.isEmpty) return 0.0;

    if (coreCourses.any((e) => e.grade < 1.5)) {
      return 25.0;
    }

    if (coreCourses.any((e) => e.grade < 2.0)) {
      return 18.0;
    }

    if (coreCourses.any((e) => e.grade < 2.5)) {
      return 10.0;
    }

    return 0.0;
  }

  String _level(double score) {
    if (score >= 90) return 'xuất sắc';
    if (score >= 80) return 'mạnh';
    if (score >= 70) return 'khá mạnh';
    if (score >= 60) return 'khá';
    if (score >= 50) return 'trung bình';
    if (score >= 35) return 'yếu';
    return 'rất yếu';
  }

  String _reason({
    required RadarAxis axis,
    required double score,
    required List<EvidenceCourse> evidences,
    required String missingEvidence,
  }) {
    if (evidences.isEmpty) {
      return 'Năng lực ${axis.nameVi} được đánh giá ở mức thấp '
          '(${score.round()}/100) do thiếu học phần chứng minh trực tiếp.';
    }

    final positive = evidences
        .where((e) => e.grade >= 3.0)
        .map((e) => e.courseName)
        .take(3)
        .toList();

    final negative = evidences
        .where((e) => e.grade < 2.0)
        .map((e) => e.courseName)
        .take(2)
        .toList();

    final coreEvidence = evidences
        .where((e) => e.coreWeight >= 1.5)
        .map((e) => e.courseName)
        .take(3)
        .toList();

    final buffer = StringBuffer();

    buffer.write(
      '${axis.nameVi} đạt ${score.round()}/100 (${_level(score)}). ',
    );

    if (coreEvidence.isNotEmpty) {
      buffer.write(
        'Học phần lõi chứng minh năng lực: ${coreEvidence.join(', ')}. ',
      );
    }

    if (positive.isNotEmpty) {
      buffer.write(
        'Học phần có kết quả tốt: ${positive.join(', ')}. ',
      );
    }

    if (negative.isNotEmpty) {
      buffer.write(
        'Học phần có kết quả thấp kéo điểm xuống: ${negative.join(', ')}. ',
      );
    }

    if (missingEvidence.isNotEmpty) {
      buffer.write(missingEvidence);
    } else {
      buffer.write(
        'Điểm được tính từ điểm hệ 4, số tín chỉ, mức độ liên quan ngữ nghĩa, '
            'độ phủ bằng chứng và vai trò lõi/phụ của từng học phần.',
      );
    }

    return buffer.toString();
  }
}

class CourseAxisMatch {
  const CourseAxisMatch({
    required this.course,
    required this.axisCode,
    required this.relevance,
    required this.shareWeight,
  });

  final AcademicCourse course;
  final String axisCode;
  final double relevance;

  /// 1.0 nếu là trục chính.
  /// Khoảng 0.45 - 0.65 nếu là trục phụ.
  final double shareWeight;
}