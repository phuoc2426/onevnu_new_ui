import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Moves picker output into app-managed storage before the registration Cubit
/// keeps it. This avoids depending on transient ImagePicker/provider paths.
class DormitoryLocalFileStore {
  DormitoryLocalFileStore._();

  static const String _folderName = 'dormitory_registration';

  static Future<Directory> _directory() async {
    final Directory support = await getApplicationSupportDirectory();
    final Directory dir = Directory(p.join(support.path, _folderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> persist(
    File source, {
    required String role,
  }) async {
    if (!await source.exists()) {
      throw StateError('Tệp đã chọn không còn tồn tại trên thiết bị.');
    }

    final Directory dir = await _directory();
    final String extension = p.extension(source.path).isEmpty
        ? '.jpg'
        : p.extension(source.path).toLowerCase();
    final String safeRole = role.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final String filename =
        '${safeRole}_${DateTime.now().microsecondsSinceEpoch}$extension';
    final File target = File(p.join(dir.path, filename));
    return source.copy(target.path);
  }

  static Future<void> deleteIfManaged(File? file) async {
    if (file == null) return;
    try {
      final Directory dir = await _directory();
      final String normalizedRoot = p.normalize(dir.absolute.path);
      final String normalizedFile = p.normalize(file.absolute.path);
      if (!p.isWithin(normalizedRoot, normalizedFile)) return;
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best-effort cleanup; never fail the business flow because cleanup fails.
    }
  }

  static Future<void> clearAll() async {
    try {
      final Directory dir = await _directory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // Best-effort cleanup.
    }
  }
}
