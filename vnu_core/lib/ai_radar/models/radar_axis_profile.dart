class RadarAxisProfile {
  const RadarAxisProfile({
    required this.cacheKey,
    required this.school,
    required this.major,
    required this.inferredDomain,
    required this.inferredSpecificMajor,
    required this.domainConfidence,
    required this.reasonVi,
    required this.axes,
  });

  final String cacheKey;
  final String school;
  final String major;
  final String inferredDomain;
  final String inferredSpecificMajor;
  final double domainConfidence;
  final String reasonVi;
  final List<RadarAxis> axes;

  Map<String, dynamic> toJson() {
    return {
      'cache_key': cacheKey,
      'school': school,
      'major': major,
      'inferred_domain': inferredDomain,
      'inferred_specific_major': inferredSpecificMajor,
      'domain_confidence': domainConfidence,
      'reason_vi': reasonVi,
      'axes': axes.map((e) => e.toJson()).toList(),
    };
  }

  factory RadarAxisProfile.fromJson(Map<String, dynamic> json) {
    return RadarAxisProfile(
      cacheKey: json['cache_key']?.toString() ?? '',
      school: json['school']?.toString() ?? '',
      major: json['major']?.toString() ?? '',
      inferredDomain: json['inferred_domain']?.toString() ?? '',
      inferredSpecificMajor: json['inferred_specific_major']?.toString() ?? '',
      domainConfidence: double.tryParse(json['domain_confidence']?.toString() ?? '') ?? 0.8,
      reasonVi: json['reason_vi']?.toString() ?? '',
      axes: ((json['axes'] as List?) ?? [])
          .map((e) => RadarAxis.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RadarAxis {
  const RadarAxis({
    required this.code,
    required this.nameVi,
    required this.nameEn,
    required this.sectorRoleVi,
    required this.axisImportance,
    required this.axisDefinitionVi,
    required this.expectedEvidenceVi,
    required this.seedText,
  });

  final String code;
  final String nameVi;
  final String nameEn;
  final String sectorRoleVi;
  final double axisImportance;
  final String axisDefinitionVi;
  final String expectedEvidenceVi;
  final String seedText;

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name_vi': nameVi,
      'name_en': nameEn,
      'sector_role_vi': sectorRoleVi,
      'axis_importance': axisImportance,
      'axis_definition_vi': axisDefinitionVi,
      'expected_evidence_vi': expectedEvidenceVi,
      'seed_text': seedText,
    };
  }

  factory RadarAxis.fromJson(Map<String, dynamic> json) {
    return RadarAxis(
      code: json['code']?.toString() ?? '',
      nameVi: json['name_vi']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      sectorRoleVi: json['sector_role_vi']?.toString() ?? '',
      axisImportance: double.tryParse(json['axis_importance']?.toString() ?? '') ?? 1.0,
      axisDefinitionVi: json['axis_definition_vi']?.toString() ?? '',
      expectedEvidenceVi: json['expected_evidence_vi']?.toString() ?? '',
      seedText: json['seed_text']?.toString() ?? '',
    );
  }
}
