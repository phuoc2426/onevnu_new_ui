class GradeScaleHelper {
  GradeScaleHelper._();

  /// Quy đổi từ điểm hệ 10 sang điểm chữ
  static String getLetterGrade(double? score10) {
    if (score10 == null) return 'Chưa có';
    if (score10 >= 9.0) return 'A+';
    if (score10 >= 8.5) return 'A';
    if (score10 >= 8.0) return 'B+';
    if (score10 >= 7.0) return 'B';
    if (score10 >= 6.5) return 'C+';
    if (score10 >= 5.5) return 'C';
    if (score10 >= 5.0) return 'D+';
    if (score10 >= 4.0) return 'D';
    return 'F';
  }

  /// Quy đổi từ điểm hệ 10 sang điểm hệ 4
  static double getScore4(double? score10) {
    if (score10 == null) return 0.0;
    if (score10 >= 8.5) return 4.0;
    if (score10 >= 8.0) return 3.5;
    if (score10 >= 7.0) return 3.0;
    if (score10 >= 6.5) return 2.5;
    if (score10 >= 5.5) return 2.0;
    if (score10 >= 5.0) return 1.5;
    if (score10 >= 4.0) return 1.0;
    return 0.0;
  }

  /// Kiểm tra trạng thái môn học (Đạt / Chưa đạt)
  static bool isPassed(double? score10) {
    if (score10 == null) return false;
    return score10 >= 4.0;
  }
}
