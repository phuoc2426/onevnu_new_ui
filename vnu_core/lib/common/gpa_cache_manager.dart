import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/repository/app_repository.dart';

class GpaCacheManager {
  static const String _gpaCacheKey = 'bg_cached_gpa_data';
  static const int _schemaVersion = 2;

  static Future<Map<String, dynamic>?> getCachedGpaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_gpaCacheKey);

      if (raw == null || raw.isEmpty) {
        return null;
      }

      final data = jsonDecode(raw) as Map<String, dynamic>;

      if (data['schemaVersion'] != _schemaVersion) {
        // Không sử dụng cache từng được tính cục bộ từ điểm môn.
        await prefs.remove(_gpaCacheKey);
        return null;
      }

      return data;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gpaCacheKey);
  }

  static Future<Map<String, dynamic>?> calculateAndCacheGpa() async {
    try {
      final api = ApiRepository();

      String kieuTruong = '';

      final listKieuTruong = await api
          .getDanhSachKieuTruong()
          .catchError((_) => <String>[]);

      if (listKieuTruong.isNotEmpty) {
        kieuTruong = listKieuTruong.firstWhere(
              (value) => value == 'TruongChinh',
          orElse: () => listKieuTruong.first,
        );
      }

      final listHocKy = await api.getDanhSachHocKyTheoDiem(
        true,
        kieuTruong,
      );

      if (listHocKy.isEmpty) {
        return null;
      }

      final selectedSemester = listHocKy.firstWhere(
            (semester) => (semester.id ?? '').trim().isNotEmpty,
        orElse: () => listHocKy.first,
      );

      final selectedSemesterId = selectedSemester.id?.trim() ?? '';

      if (selectedSemesterId.isEmpty) {
        return null;
      }

      // GPA chính thức: lấy trực tiếp từ API backend đã tính theo logic ASP.
      final officialGpaList = await api.getDiemTrungBinhHocKy(
        selectedSemesterId,
        kieuTruong,
        true,
      );

      if (officialGpaList.isEmpty) {
        return null;
      }

      final officialGpa = officialGpaList.first;

      // Danh sách môn vẫn được tải để phục vụ AI Radar, không dùng tính GPA.
      final futures = listHocKy.map((semester) {
        return api
            .getDiemThiHocKy(
          semester.id ?? '',
          kieuTruong,
          true,
        )
            .catchError((_) => <DiemThiHocKyModel>[]);
      }).toList();

      final results = await Future.wait(futures);

      final uniqueCourses = <String, DiemThiHocKyModel>{};

      for (final list in results) {
        for (final course in list) {
          final name = course.tenHocPhan?.trim() ?? '';

          if (name.isEmpty) {
            continue;
          }

          final key = '${course.maHocPhan?.trim() ?? ''}_$name';
          final existing = uniqueCourses[key];

          if (existing == null) {
            uniqueCourses[key] = course;
            continue;
          }

          final existingGrade =
              double.tryParse(
                existing.diemHe4?.replaceAll(',', '.') ?? '',
              ) ??
                  0.0;

          final currentGrade =
              double.tryParse(
                course.diemHe4?.replaceAll(',', '.') ?? '',
              ) ??
                  0.0;

          if (currentGrade > existingGrade) {
            uniqueCourses[key] = course;
          }
        }
      }

      final deduplicatedList = uniqueCourses.values.toList();

      final data = <String, dynamic>{
        'schemaVersion': _schemaVersion,
        'selectedHocKyId': selectedSemesterId,

        // Các key tương thích ngược luôn chứa giá trị tích lũy chính thức.
        'gpaHe4':
        double.tryParse(
          officialGpa
              .diemTrungBinhHe4TichLuyDenHocKyHienTai ??
              '0',
        ) ??
            0.0,

        'gpaHe10':
        double.tryParse(
          officialGpa
              .diemTrungBinhHe10TichLuyDenHocKyHienTai ??
              '0',
        ) ??
            0.0,

        'tongTinChi':
        int.tryParse(
          officialGpa
              .tongSoTinChiTichLuyTichLuyDenHocKyHienTai ??
              '0',
        ) ??
            0,

        'gpaHe4HocKy':
        officialGpa.diemTrungBinhHe4HocKy ?? '0.00',

        'gpaHe4TichLuy':
        officialGpa
            .diemTrungBinhHe4TichLuyDenHocKyHienTai ??
            '0.00',

        'gpaHe10HocKy':
        officialGpa.diemTrungBinhHe10HocKy ?? '0.00',

        'gpaHe10TichLuy':
        officialGpa
            .diemTrungBinhHe10TichLuyDenHocKyHienTai ??
            '0.00',

        'tongTinChiHocKy':
        officialGpa.tongSoTinChiTichLuyHocKy ?? '0',

        'tongTinChiTichLuy':
        officialGpa
            .tongSoTinChiTichLuyTichLuyDenHocKyHienTai ??
            '0',

        'tongTinChiTruotHocKy':
        officialGpa.tongSoTinChiTruotHocKy ?? '0',

        'tongTinChiTruotTichLuy':
        officialGpa
            .tongSoTinChiTruotTichLuyDenHocKyHienTai ??
            '0',

        'soKyDaHoc': listHocKy.length,

        'deduplicatedList': deduplicatedList
            .map((course) => course.toJson())
            .toList(),

        'danhSachHocKy': listHocKy
            .map((semester) => semester.toJson())
            .toList(),

        'kieuTruong': kieuTruong,
      };

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _gpaCacheKey,
        jsonEncode(data),
      );

      return data;
    } catch (_) {
      return null;
    }
  }
}