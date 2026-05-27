enum ScheduleType { classSession, exam }

class ScheduleEvent {
  final ScheduleType type;
  final String title;
  final DateTime date;
  final String startTime; // For class: start lesson (tietBatDau). For exam: start time (gioBatDauThi).
  final String endTime;   // For class: end lesson (tietKetThuc). For exam: duration (thoiLuong).
  final String location;  // Room & Building address
  final String teacher;   // For class: Lecturer name. For exam: candidate number (sobaodanh) / format.
  final String? hocPhanCode;
  final String? id;
  final String? soTinChi;
  final String? nhom;
  final String? caThi;
  final String? hinhThucThi;
  final String? soBaoDanh;

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
  });
}
