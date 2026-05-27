class AiRadarAnalysis {
  const AiRadarAnalysis({
    required this.detectedMajorProfile,
    required this.axisDesignLogic,
    required this.radarAxes,
    required this.dominantSpikes,
    required this.weakSpikes,
    required this.overallInterpretationVi,
    required this.confidence,
    required this.usedCache,
  });

  final DetectedMajorProfile detectedMajorProfile;
  final AxisDesignLogic axisDesignLogic;
  final List<RadarDimension> radarAxes;
  final List<RadarSpike> dominantSpikes;
  final List<RadarSpike> weakSpikes;
  final String overallInterpretationVi;
  final double confidence;
  final bool usedCache;

  // Compatibility getters for the view
  String get school => detectedMajorProfile.school;
  String get major => detectedMajorProfile.facultyOrMajor;
  String get inferredContext => detectedMajorProfile.reasonVi;
  List<RadarDimension> get dimensions => radarAxes;

  Map<String, dynamic> toJson() {
    return {
      'detected_major_profile': detectedMajorProfile.toJson(),
      'axis_design_logic': axisDesignLogic.toJson(),
      'radar_axes': radarAxes.map((e) => e.toJson()).toList(),
      'dominant_spikes': dominantSpikes.map((e) => e.toJson()).toList(),
      'weak_spikes': weakSpikes.map((e) => e.toJson()).toList(),
      'overall_interpretation_vi': overallInterpretationVi,
      'confidence': confidence,
      'used_cache': usedCache,
    };
  }

  factory AiRadarAnalysis.fromJson(Map<String, dynamic> json) {
    return AiRadarAnalysis(
      detectedMajorProfile: DetectedMajorProfile.fromJson(
        json['detected_major_profile'] as Map<String, dynamic>? ?? {},
      ),
      axisDesignLogic: AxisDesignLogic.fromJson(
        json['axis_design_logic'] as Map<String, dynamic>? ?? {},
      ),
      radarAxes: ((json['radar_axes'] as List?) ?? [])
          .map((e) => RadarDimension.fromJson(e as Map<String, dynamic>))
          .toList(),
      dominantSpikes: ((json['dominant_spikes'] as List?) ?? [])
          .map((e) => RadarSpike.fromJson(e as Map<String, dynamic>))
          .toList(),
      weakSpikes: ((json['weak_spikes'] as List?) ?? [])
          .map((e) => RadarSpike.fromJson(e as Map<String, dynamic>))
          .toList(),
      overallInterpretationVi: json['overall_interpretation_vi']?.toString() ?? '',
      confidence: double.tryParse(json['confidence']?.toString() ?? '') ?? 0.0,
      usedCache: json['used_cache'] as bool? ?? false,
    );
  }
}

class DetectedMajorProfile {
  const DetectedMajorProfile({
    required this.school,
    required this.facultyOrMajor,
    required this.inferredDomain,
    required this.inferredSpecificMajor,
    required this.domainConfidence,
    required this.reasonVi,
  });

  final String school;
  final String facultyOrMajor;
  final String inferredDomain;
  final String inferredSpecificMajor;
  final double domainConfidence;
  final String reasonVi;

  Map<String, dynamic> toJson() {
    return {
      'school': school,
      'faculty_or_major': facultyOrMajor,
      'inferred_domain': inferredDomain,
      'inferred_specific_major': inferredSpecificMajor,
      'domain_confidence': domainConfidence,
      'reason_vi': reasonVi,
    };
  }

  factory DetectedMajorProfile.fromJson(Map<String, dynamic> json) {
    return DetectedMajorProfile(
      school: json['school']?.toString() ?? '',
      facultyOrMajor: json['faculty_or_major']?.toString() ?? json['faculty_or_major']?.toString() ?? '',
      inferredDomain: json['inferred_domain']?.toString() ?? '',
      inferredSpecificMajor: json['inferred_specific_major']?.toString() ?? '',
      domainConfidence: double.tryParse(json['domain_confidence']?.toString() ?? '') ?? 0.8,
      reasonVi: json['reason_vi']?.toString() ?? '',
    );
  }
}

class AxisDesignLogic {
  const AxisDesignLogic({
    required this.principleVi,
    required this.whyNotCourseClusterVi,
    required this.axisSourceVi,
  });

  final String principleVi;
  final String whyNotCourseClusterVi;
  final String axisSourceVi;

  Map<String, dynamic> toJson() {
    return {
      'principle_vi': principleVi,
      'why_not_course_cluster_vi': whyNotCourseClusterVi,
      'axis_source_vi': axisSourceVi,
    };
  }

  factory AxisDesignLogic.fromJson(Map<String, dynamic> json) {
    return AxisDesignLogic(
      principleVi: json['principle_vi']?.toString() ?? '',
      whyNotCourseClusterVi: json['why_not_course_cluster_vi']?.toString() ?? '',
      axisSourceVi: json['axis_source_vi']?.toString() ?? '',
    );
  }
}

class RadarDimension {
  const RadarDimension({
    required this.code,
    required this.nameVi,
    required this.nameEn,
    required this.sectorRoleVi,
    required this.axisImportance,
    required this.axisDefinitionVi,
    required this.expectedEvidenceVi,
    required this.score,
    required this.level,
    required this.evidenceCourses,
    required this.missingEvidenceVi,
    required this.reasonVi,
  });

  final String code;
  final String nameVi;
  final String nameEn;
  final String sectorRoleVi;
  final double axisImportance;
  final String axisDefinitionVi;
  final String expectedEvidenceVi;
  final double score;
  final String level;
  final List<EvidenceCourse> evidenceCourses;
  final String missingEvidenceVi;
  final String reasonVi;

  // Compatibility getters for the view
  String get descriptionVi => axisDefinitionVi;
  String get whyThisAxisExistsVi => sectorRoleVi;

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name_vi': nameVi,
      'name_en': nameEn,
      'sector_role_vi': sectorRoleVi,
      'axis_importance': axisImportance,
      'axis_definition_vi': axisDefinitionVi,
      'expected_evidence_vi': expectedEvidenceVi,
      'score': score,
      'level': level,
      'evidence_courses': evidenceCourses.map((e) => e.toJson()).toList(),
      'missing_evidence_vi': missingEvidenceVi,
      'reason_vi': reasonVi,
    };
  }

  factory RadarDimension.fromJson(Map<String, dynamic> json) {
    return RadarDimension(
      code: json['code']?.toString() ?? '',
      nameVi: json['name_vi']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      sectorRoleVi: json['sector_role_vi']?.toString() ?? '',
      axisImportance: double.tryParse(json['axis_importance']?.toString() ?? '') ?? 1.0,
      axisDefinitionVi: json['axis_definition_vi']?.toString() ?? '',
      expectedEvidenceVi: json['expected_evidence_vi']?.toString() ?? '',
      score: double.tryParse(json['score']?.toString() ?? '') ?? 0.0,
      level: json['level']?.toString() ?? '',
      evidenceCourses: ((json['evidence_courses'] as List?) ?? [])
          .map((e) => EvidenceCourse.fromJson(e as Map<String, dynamic>))
          .toList(),
      missingEvidenceVi: json['missing_evidence_vi']?.toString() ?? '',
      reasonVi: json['reason_vi']?.toString() ?? '',
    );
  }
}

class EvidenceCourse {
  const EvidenceCourse({
    required this.courseName,
    required this.grade,
    required this.credits,
    required this.relevance,
    required this.coreWeight,
    required this.impact,
    required this.reasonVi,
  });

  final String courseName;
  final double grade;
  final double credits;
  final double relevance;
  final double coreWeight;
  final String impact;
  final String reasonVi;

  // Compatibility getter for similarity
  double get similarity => relevance;

  Map<String, dynamic> toJson() {
    return {
      'course_name': courseName,
      'grade': grade,
      'credits': credits,
      'relevance': relevance,
      'core_weight': coreWeight,
      'impact': impact,
      'reason_vi': reasonVi,
    };
  }

  factory EvidenceCourse.fromJson(Map<String, dynamic> json) {
    return EvidenceCourse(
      courseName: json['course_name']?.toString() ?? '',
      grade: double.tryParse(json['grade']?.toString() ?? '') ?? 0.0,
      credits: double.tryParse(json['credits']?.toString() ?? '') ?? 3.0,
      relevance: double.tryParse(json['relevance']?.toString() ?? '') ?? 0.0,
      coreWeight: double.tryParse(json['core_weight']?.toString() ?? '') ?? 1.0,
      impact: json['impact']?.toString() ?? 'neutral',
      reasonVi: json['reason_vi']?.toString() ?? '',
    );
  }
}

class RadarSpike {
  const RadarSpike({
    required this.code,
    required this.nameVi,
    required this.score,
    required this.explanationVi,
  });

  final String code;
  final String nameVi;
  final double score;
  final String explanationVi;

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name_vi': nameVi,
      'score': score,
      'explanation_vi': explanationVi,
    };
  }

  factory RadarSpike.fromJson(Map<String, dynamic> json) {
    return RadarSpike(
      code: json['code']?.toString() ?? '',
      nameVi: json['name_vi']?.toString() ?? '',
      score: double.tryParse(json['score']?.toString() ?? '') ?? 0.0,
      explanationVi: json['explanation_vi']?.toString() ?? '',
    );
  }
}
