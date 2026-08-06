import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/repository/app_repository.dart';

class GpaCacheManager {
  static const String _gpaCacheKey = 'bg_cached_gpa_data';

  static Future<Map<String, dynamic>?> getCachedGpaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_gpaCacheKey);
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> calculateAndCacheGpa() async {
    try {
      final api = ApiRepository();
      
      // 1. Get kieuTruong
      String kieuTruong = "";
      final listKieuTruong = await api.getDanhSachKieuTruong().catchError((_) => <String>[]);
      if (listKieuTruong.isNotEmpty) {
        kieuTruong = listKieuTruong.firstWhere((obj) => obj == "TruongChinh", orElse: () => listKieuTruong.first);
      }

      // 2. Get semesters list
      final listHocKy = await api.getDanhSachHocKyTheoDiem(true, kieuTruong);
      if (listHocKy.isEmpty) return null;

      // 3. Fetch all grades in parallel
      final futures = listHocKy.map((hk) {
        return api.getDiemThiHocKy(hk.id ?? '', kieuTruong, true).catchError((_) => <DiemThiHocKyModel>[]);
      }).toList();

      final results = await Future.wait(futures);

      // 4. Deduplicate courses: highest grade for repeated courses
      final uniqueCourses = <String, DiemThiHocKyModel>{};
      for (final list in results) {
        for (final course in list) {
          final name = course.tenHocPhan?.trim() ?? '';
          if (name.isEmpty) continue;
          final key = '${course.maHocPhan?.trim() ?? ''}_$name';
          final existing = uniqueCourses[key];
          if (existing == null) {
            uniqueCourses[key] = course;
          } else {
            final existingGrade = double.tryParse(existing.diemHe10?.replaceAll(',', '.') ?? '') ?? 0.0;
            final currentGrade = double.tryParse(course.diemHe10?.replaceAll(',', '.') ?? '') ?? 0.0;
            if (currentGrade > existingGrade) {
              uniqueCourses[key] = course;
            }
          }
        }
      }

      final deduplicatedList = uniqueCourses.values.toList();
      if (deduplicatedList.isEmpty) return null;

      // 5. Calculate cumulative GPA statistics
      double totalCredits = 0;
      double weightedGrade10 = 0;
      double weightedGrade4 = 0;
      int tcTichLuy = 0;
      int tcTruot = 0;

      for (final course in deduplicatedList) {
        final grade10 = double.tryParse(course.diemHe10?.replaceAll(',', '.') ?? '');
        final grade4 = double.tryParse(course.diemHe4?.replaceAll(',', '.') ?? '');
        final credits = double.tryParse(course.soTinChi?.replaceAll(',', '.') ?? '');

        if (grade10 == null || credits == null) continue;

        weightedGrade10 += grade10 * credits;
        if (grade4 != null) {
          weightedGrade4 += grade4 * credits;
        }
        totalCredits += credits;

        if (grade10 >= 4.0) {
          tcTichLuy += credits.round();
        } else {
          tcTruot += credits.round();
        }
      }

      double gpa10 = totalCredits > 0 ? (weightedGrade10 / totalCredits) : 0.0;
      double gpa4 = totalCredits > 0 ? (weightedGrade4 / totalCredits) : 0.0;

      final data = {
        'gpaHe4': double.parse(gpa4.toStringAsFixed(2)),
        'gpaHe10': double.parse(gpa10.toStringAsFixed(2)),
        'tongTinChi': tcTichLuy,
        'soKyDaHoc': listHocKy.length,
        'deduplicatedList': deduplicatedList.map((e) => e.toJson()).toList(),
        'danhSachHocKy': listHocKy.map((e) => e.toJson()).toList(),
        'kieuTruong': kieuTruong,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_gpaCacheKey, jsonEncode(data));
      return data;
    } catch (_) {
      return null;
    }
  }
}
