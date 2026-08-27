enum ScheduleType { classSession, exam }

class ScheduleEvent {
  final ScheduleType type;
  final String title;
  final DateTime date;
  final String startTime; // Class: lesson label. Exam: concrete start time.
  final String endTime; // Class: lesson label. Exam: duration/end value.
  final String location;
  final String teacher;
  final String? hocPhanCode;
  final String? id;
  final String? soTinChi;
  final String? nhom;
  final String? caThi;
  final String? hinhThucThi;
  final String? soBaoDanh;

  /// Resolved clock values. For class sessions these are now produced by the
  /// shared AcademicPeriodConfig resolver, after applying any course override.
  final String? actualStartTime;
  final String? actualEndTime;
  final bool fromExtraTerm;
  final String? sourceNote;

  const ScheduleEvent({
    required this.type,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.teacher,
    this.hocPhanCode,
    this.id,
    this.soTinChi,
    this.nhom,
    this.caThi,
    this.hinhThucThi,
    this.soBaoDanh,
    this.actualStartTime,
    this.actualEndTime,
    this.fromExtraTerm = false,
    this.sourceNote,
  });

  String get displayStartTime {
    final actual = actualStartTime?.trim() ?? '';
    return actual.isNotEmpty ? actual : startTime;
  }

  String get displayEndTime {
    final actual = actualEndTime?.trim() ?? '';
    return actual.isNotEmpty ? actual : endTime;
  }

  String get displayTimeRange {
    final actualStart = actualStartTime?.trim() ?? '';
    final actualEnd = actualEndTime?.trim() ?? '';
    if (actualStart.isNotEmpty && actualEnd.isNotEmpty) {
      return '$actualStart - $actualEnd';
    }
    if (actualStart.isNotEmpty) return actualStart;

    final start = startTime.trim();
    final end = endTime.trim();
    if (start.isEmpty && end.isEmpty) return 'Chưa có giờ';
    if (start.isEmpty) return end;
    if (end.isEmpty || start == end) return start;
    return '$start - $end';
  }
}
