import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Chuẩn hóa ảnh trước khi upload lên hệ thống KTX.
///
/// Mọi ảnh được chuyển sang JPEG, bỏ EXIF, giới hạn cạnh ảnh và dung lượng.
/// Luồng này xử lý được ảnh HEIC/HEIF thường gặp trên iOS trước khi gửi API.
class DormitoryImageUploadUtil {
  DormitoryImageUploadUtil._();

  static const int maxUploadMb = 5;
  static const int maxUploadBytes = maxUploadMb * 1024 * 1024;

  static const int _defaultMaxImageSide = 1600;
  static const int _fallbackMaxImageSide = 1280;
  static const int _defaultImageQuality = 82;
  static const int _minImageQuality = 55;

  static Future<File> normalizeToJpeg(File originalFile) async {
    if (!await originalFile.exists()) {
      throw Exception(
        'Không tìm thấy ảnh ${path.basename(originalFile.path)} trên thiết bị.',
      );
    }

    final Directory tempDirectory = await getTemporaryDirectory();
    final int originalSize = await originalFile.length();

    int quality = _defaultImageQuality;
    int maxSide = _defaultMaxImageSide;
    File? lastCompressedFile;

    while (quality >= _minImageQuality) {
      final String targetPath = path.join(
        tempDirectory.path,
        'payment_proof_${DateTime.now().microsecondsSinceEpoch}'
        '_q${quality}_${maxSide}px.jpg',
      );

      final compressed = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxSide,
        minHeight: maxSide,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (compressed == null) {
        throw Exception(
          'Không thể xử lý ảnh ${path.basename(originalFile.path)}. '
          'Vui lòng chọn ảnh JPG hoặc PNG khác.',
        );
      }

      lastCompressedFile = File(compressed.path);
      final int compressedSize = await lastCompressedFile.length();

      debugPrint(
        '[PAYMENT-PROOF-IMAGE-NORMALIZE] '
        'platform=${Platform.operatingSystem}, '
        'source=${path.basename(originalFile.path)}, '
        'sourceBytes=$originalSize, '
        'output=${path.basename(lastCompressedFile.path)}, '
        'outputBytes=$compressedSize, '
        'quality=$quality, '
        'maxSide=$maxSide',
      );

      if (compressedSize <= maxUploadBytes) {
        return lastCompressedFile;
      }

      quality -= 8;
      if (quality <= 66) {
        maxSide = _fallbackMaxImageSide;
      }
    }

    if (lastCompressedFile == null) {
      throw Exception(
        'Không thể tạo ảnh tải lên từ ${path.basename(originalFile.path)}.',
      );
    }

    final double sizeMb = await _fileSizeMb(lastCompressedFile);
    if (sizeMb > maxUploadMb) {
      throw Exception(
        'Ảnh minh chứng sau khi xử lý vẫn có dung lượng '
        '${sizeMb.toStringAsFixed(2)} MB, vượt quá giới hạn '
        '$maxUploadMb MB.',
      );
    }

    return lastCompressedFile;
  }

  static Future<void> deleteTemporaryFile({
    required File? normalizedFile,
    required File? originalFile,
  }) async {
    if (normalizedFile == null) {
      return;
    }

    if (originalFile != null &&
        normalizedFile.absolute.path == originalFile.absolute.path) {
      return;
    }

    try {
      if (await normalizedFile.exists()) {
        await normalizedFile.delete();
      }
    } catch (error) {
      debugPrint('[PAYMENT-PROOF-TEMP-CLEANUP] $error');
    }
  }

  static Future<double> _fileSizeMb(File file) async {
    final int bytes = await file.length();
    return bytes / 1024 / 1024;
  }
}
