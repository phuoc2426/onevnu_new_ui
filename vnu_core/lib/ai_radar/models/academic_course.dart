class AcademicCourse {
  const AcademicCourse({
    required this.name,
    required this.grade,
    required this.credits,
    this.description,
  });

  final String name;
  final double grade;
  final double credits;
  final String? description;

  double get normalizedGrade => (grade / 10).clamp(0.0, 1.0);

  String get semanticText {
    final desc = description?.trim() ?? '';
    if (desc.isEmpty) return name;
    return '$name. $desc';
  }

  factory AcademicCourse.fromLine(String line) {
    final parts = line
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return AcademicCourse(
      name: parts.isNotEmpty ? parts[0] : 'Không rõ học phần',
      grade: parts.length > 1
          ? (double.tryParse(parts[1].replaceAll(',', '.')) ?? 0.0).clamp(0.0, 10.0)
          : 0.0,
      credits: parts.length > 2
          ? (double.tryParse(parts[2].replaceAll(',', '.')) ?? 3.0).clamp(1.0, 10.0)
          : 3.0,
      description: parts.length > 3 ? parts.sublist(3).join(', ') : null,
    );
  }

  static List<AcademicCourse> parseMany(String rawText) {
    return rawText
        .split(RegExp(r'[\n;]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map(AcademicCourse.fromLine)
        .toList();
  }
}
