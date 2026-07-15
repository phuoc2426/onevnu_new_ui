import 'package:shared_preferences/shared_preferences.dart';

class AppGuideCacheService {
  const AppGuideCacheService();

  static const String _prefix = 'app_guide_seen_';

  Future<bool> hasSeenGroup(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$groupId') ?? false;
  }

  Future<void> markGroupSeen(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$groupId', true);
  }

  Future<void> resetGroup(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$groupId');
  }
}
