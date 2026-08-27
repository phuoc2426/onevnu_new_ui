import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vnu_core/common/error/app_feedback.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/services/services_url.dart';

/// Cross-platform attachment preview used by notifications/jobs.
///
/// - PDF: preview inside the app with flutter_pdfview (Android + iOS).
/// - Image: preview inside the app with InteractiveViewer (Android + iOS).
/// - Office/other formats: download to app cache then ask the OS to preview/open
///   the file via open_filex (Quick Look / document interaction on iOS).
class VnuAttachmentPreview {
  VnuAttachmentPreview._();

  static const Set<String> _imageExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
  };

  static Future<void> open({
    required BuildContext context,
    required String guid,
    required String fileName,
    String? title,
  }) async {
    final cleanGuid = guid.trim();
    if (cleanGuid.isEmpty) {
      snackBarError('Không tìm thấy thông tin tệp đính kèm.');
      return;
    }

    final cleanName = fileName.trim().isEmpty
        ? 'Tài liệu đính kèm'
        : fileName.trim();
    final extension = _extensionOf(cleanName);

    logInfo(
      '[ATTACHMENT_PREVIEW] open guid=$cleanGuid name=$cleanName ext=$extension platform=${Platform.operatingSystem}',
    );

    var progressVisible = true;
    Utils.showProgress(context, withoutBinding: true);
    try {
      final url = '${ServicesUrl().baseUrlFileDownload}$cleanGuid';
      final File? file = await VnuCacheManager.downloadAndCache(
        url,
        cleanGuid,
        extension,
      );
      Utils.dismissProgress(context);
      progressVisible = false;

      if (file == null) {
        logError('[ATTACHMENT_PREVIEW] download failed guid=$cleanGuid');
        snackBarError('Không thể tải tệp đính kèm.');
        return;
      }

      logSuccess('[ATTACHMENT_PREVIEW] downloaded ${file.path}');

      if (extension == 'pdf') {
        await Get.to(
          () => _LocalPdfPreviewScreen(
            title: title ?? cleanName,
            filePath: file.path,
          ),
        );
        return;
      }

      if (_imageExtensions.contains(extension)) {
        await Get.to(
          () => _LocalImagePreviewScreen(
            title: title ?? cleanName,
            filePath: file.path,
          ),
        );
        return;
      }

      await OpenFilex.open(file.path);
      logSuccess(
        '[ATTACHMENT_PREVIEW] requested native preview ${file.path}',
      );
    } catch (error, stackTrace) {
      if (progressVisible) {
        try {
          Utils.dismissProgress(context);
        } catch (_) {}
      }
      logError('[ATTACHMENT_PREVIEW] $error\n$stackTrace');
      AppFeedback.showError(error);
    }
  }

  static Future<void> share({
    required BuildContext context,
    required String guid,
    required String fileName,
  }) async {
    final cleanGuid = guid.trim();
    if (cleanGuid.isEmpty) {
      snackBarError('Không tìm thấy thông tin tệp đính kèm.');
      return;
    }

    final cleanName = fileName.trim().isEmpty
        ? 'Tài liệu đính kèm'
        : fileName.trim();
    final extension = _extensionOf(cleanName);

    var progressVisible = true;
    Utils.showProgress(context, withoutBinding: true);
    try {
      final url = '${ServicesUrl().baseUrlFileDownload}$cleanGuid';
      final File? file = await VnuCacheManager.downloadAndCache(
        url,
        cleanGuid,
        extension,
      );
      Utils.dismissProgress(context);
      progressVisible = false;

      if (file == null) {
        snackBarError('Không thể tải tệp đính kèm.');
        return;
      }

      logSuccess('[ATTACHMENT_PREVIEW] share ${file.path}');
      await Share.shareXFiles(<XFile>[XFile(file.path)], subject: cleanName);
    } catch (error, stackTrace) {
      if (progressVisible) {
        try {
          Utils.dismissProgress(context);
        } catch (_) {}
      }
      logError('[ATTACHMENT_PREVIEW] share error=$error\n$stackTrace');
      AppFeedback.showError(error);
    }
  }

  static String _extensionOf(String fileName) {
    final normalized = fileName.split('?').first.split('#').first.trim();
    final index = normalized.lastIndexOf('.');
    if (index < 0 || index == normalized.length - 1) return '';
    return normalized.substring(index + 1).toLowerCase();
  }
}

class _LocalPdfPreviewScreen extends StatefulWidget {
  const _LocalPdfPreviewScreen({
    required this.title,
    required this.filePath,
  });

  final String title;
  final String filePath;

  @override
  State<_LocalPdfPreviewScreen> createState() => _LocalPdfPreviewScreenState();
}

class _LocalPdfPreviewScreenState extends State<_LocalPdfPreviewScreen> {
  bool _ready = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PDFView(
            filePath: widget.filePath,
            pageFling: true,
            pageSnap: true,
            onRender: (_) {
              if (mounted) setState(() => _ready = true);
            },
            onError: (error) {
              logError('[ATTACHMENT_PREVIEW] pdf error=$error');
              if (mounted) setState(() => _error = error.toString());
            },
            onPageError: (page, error) {
              logError(
                '[ATTACHMENT_PREVIEW] pdf page=$page error=$error',
              );
              if (mounted) {
                setState(() => _error = 'Không thể hiển thị trang ${(page ?? 0) + 1}.');
              }
            },
          ),
          if (!_ready && _error == null)
            const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 44,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Không thể hiển thị tài liệu',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocalImagePreviewScreen extends StatelessWidget {
  const _LocalImagePreviewScreen({
    required this.title,
    required this.filePath,
  });

  final String title;
  final String filePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111412),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.7,
            maxScale: 5,
            child: Image.file(
              File(filePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                logError('[ATTACHMENT_PREVIEW] image error=$error');
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Không thể hiển thị ảnh này.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
