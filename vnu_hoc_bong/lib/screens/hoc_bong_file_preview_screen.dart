import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/log.dart';

import '../repository/hoc_bong_repository.dart';
import '../widgets/hoc_bong_screen_shell.dart';

/// Xem tệp đính kèm qua API preview (PDF/ảnh) — hỗ trợ hiển thị logs lỗi chi tiết.
class HocBongFilePreviewScreen extends StatefulWidget {
  final int fileId;
  final String? title;
  final HocBongRepository repository;

  const HocBongFilePreviewScreen({
    super.key,
    required this.fileId,
    required this.repository,
    this.title,
  });

  @override
  State<HocBongFilePreviewScreen> createState() => _HocBongFilePreviewScreenState();
}

class _HocBongFilePreviewScreenState extends State<HocBongFilePreviewScreen> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final url = widget.repository.getPreviewFileUrl(widget.fileId);
    final headers = widget.repository.previewAuthHeaders;

    // Logging chi tiết thông tin preview file
    logInfo('--- HỌC BỔNG FILE PREVIEW ---');
    logInfo('File ID: ${widget.fileId}');
    logInfo('Tên hiển thị: ${widget.title}');
    logInfo('Đường dẫn Preview: $url');
    logInfo('Headers Xác thực: $headers');

    final isImage = widget.title != null &&
        (widget.title!.toLowerCase().endsWith('.png') ||
            widget.title!.toLowerCase().endsWith('.jpg') ||
            widget.title!.toLowerCase().endsWith('.jpeg') ||
            widget.title!.toLowerCase().endsWith('.webp'));

    return HocBongScreenShell(
      title: widget.title ?? 'Xem tài liệu',
      body: Column(
        children: [
          Expanded(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyles.regular.copyWith(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                : (isImage
                    ? Image.network(
                        url,
                        headers: headers,
                        errorBuilder: (context, error, stackTrace) {
                          logError('Tải hình ảnh thất bại: $error');
                          return const Center(
                            child: Text('Không tải được hình ảnh'),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenAccent),
                            ),
                          );
                        },
                      )
                    : SfPdfViewer.network(
                        url,
                        headers: headers,
                        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                          logError('Tải tài liệu PDF thất bại: ${details.description}, Error: ${details.error}');
                          if (mounted) {
                            setState(() {
                              _error = 'Không tải được tài liệu: ${details.description}';
                            });
                          }
                        },
                        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                          logSuccess('Tải tài liệu PDF thành công.');
                        },
                      )),
          ),
        ],
      ),
    );
  }
}
