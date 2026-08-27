import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_noi_tru/domain/registration/dormitory_student_draft.dart';

/// Dedicated cache for the Step-3 student draft.
///
/// This cache is intentionally separate from applicant login preferences and
/// from Globals. It stores what the user is preparing to submit to KTX.
class DormitoryRegistrationDraftCache {
  DormitoryRegistrationDraftCache._();

  static const String _prefix = 'dormitory_registration_student_draft_v2_';

  static String _key(String ownerKey) => '$_prefix${ownerKey.trim()}';

  static Future<DormitoryStudentDraft?> read(String ownerKey) async {
    final String normalized = ownerKey.trim();
    if (normalized.isEmpty) return null;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key(normalized));
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return DormitoryStudentDraft.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(
    String ownerKey,
    DormitoryStudentDraft draft,
  ) async {
    final String normalized = ownerKey.trim();
    if (normalized.isEmpty) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(normalized), jsonEncode(draft.toJson()));
  }

  static Future<void> clear(String ownerKey) async {
    final String normalized = ownerKey.trim();
    if (normalized.isEmpty) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(normalized));
  }
}
