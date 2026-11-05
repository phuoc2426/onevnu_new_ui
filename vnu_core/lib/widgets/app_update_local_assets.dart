import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Read only files already authored by the ONEVNU team. No hard-coded icon
/// replacement: invalid/missing assets produce a visible error and a log.
/// The Flutter package asset key has the `packages/vnu_core/` prefix.
class AppUpdateLocalAssets {
  AppUpdateLocalAssets._();

  static final Future<Uint8List> animation = _load('update.json');
  static final Future<Uint8List> androidIcon = _load('android.png');
  static final Future<Uint8List> iosIcon = _load('apple.png');

  static Future<Uint8List> _load(String fileName) async {
    final paths = <String>[
      'packages/vnu_core/assets/update/$fileName',
      'assets/update/$fileName',
    ];
    Object? lastError;
    for (final assetPath in paths) {
      try {
        final data = await rootBundle.load(assetPath);
        if (data.lengthInBytes == 0) {
          throw StateError('Asset rỗng');
        }
        final bytes = Uint8List.fromList(data.buffer.asUint8List(
          data.offsetInBytes, data.lengthInBytes));
        if (fileName.endsWith('.json')) {
          final decoded = jsonDecode(utf8.decode(bytes));
          if (decoded is! Map || decoded['layers'] is! List ||
              decoded['w'] is! num || decoded['h'] is! num) {
            throw const FormatException('Không phải Lottie JSON hợp lệ');
          }
        } else {
          if (bytes.length < 8 || bytes[0] != 137 || bytes[1] != 80 ||
              bytes[2] != 78 || bytes[3] != 71) {
            throw const FormatException('Không phải ảnh PNG');
          }
        }
        if (kDebugMode) {
          debugPrint('[OneVNU Update] Asset loaded: $assetPath '
              '(${bytes.length} bytes)');
        }
        return bytes;
      } catch (error) {
        lastError = error;
        if (kDebugMode) {
          debugPrint('[OneVNU Update] Cannot load $assetPath: $error');
        }
      }
    }
    throw FlutterError('Không tải được $fileName từ vnu_core/assets/update/. '
        'Đã thử: ${paths.join(', ')}. Lỗi cuối: $lastError. '
        'Hãy kiểm tra pubspec.yaml và chạy flutter clean, pub get.');
  }
}
