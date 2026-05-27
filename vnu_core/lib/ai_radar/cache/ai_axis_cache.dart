import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radar_axis_profile.dart';
import '../models/ai_radar_analysis.dart';

class AiAxisCache {
  static const _prefix = 'ai_radar_axis_profile_';
  static const _analysisPrefix = 'ai_radar_analysis_json_';
  static const _sigPrefix = 'ai_radar_analysis_sig_';

  static String buildKey({
    required String school,
    required String major,
  }) {
    final raw = '${school.trim().toLowerCase()}|${major.trim().toLowerCase()}';
    // Sanitize string to make a clean, deterministic storage key
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_|]'), '_');
  }

  Future<RadarAxisProfile?> get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');

      if (raw == null) return null;

      return RadarAxisProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> save(RadarAxisProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefix${profile.cacheKey}',
        jsonEncode(profile.toJson()),
      );
    } catch (_) {}
  }

  // --- AiRadarAnalysis Cache Support ---

  Future<AiRadarAnalysis?> getAnalysis(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_analysisPrefix$key');
      if (raw == null) return null;
      return AiRadarAnalysis.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> getSignature(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_sigPrefix$key');
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAnalysis(String key, String signature, AiRadarAnalysis analysis) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_analysisPrefix$key', jsonEncode(analysis.toJson()));
      await prefs.setString('$_sigPrefix$key', signature);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (key.startsWith(_prefix) || key.startsWith(_analysisPrefix) || key.startsWith(_sigPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (_) {}
  }
}
