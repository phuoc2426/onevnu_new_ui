import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:docx_viewer_plus/docx_viewer_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:microsoft_viewer/microsoft_viewer.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vnu_core/widgets/student_service_ui.dart';

/// A single, compact preview surface for One Door attachments.
/// IMPORTANT: The simple MicrosoftViewer renderer must never render DOCX:
/// complex official templates cause overflowing RenderFlex and lost positions.
/// DOCX is shown via the already-installed read-only WebView DOCX renderer;
/// the native Office app remains the fidelity fallback for any document.
class OneDoorAttachmentPreview {
  static Future<void> openInOffice(BuildContext context, String path) async {
    if (!await File(path).exists()) {
      if (context.mounted) _notice(context, 'Tệp không còn tồn tại. Hãy chọn lại.');
      return;
    }
    await _openOutside(context, path);
  }

  /// Opens Android/iOS sharing targets (e.g. Zalo). The selected file remains
  /// unchanged; it is not silently reattached after editing in another app.
  static Future<void> shareFile(BuildContext context, {
    required String path, String? title,
  }) async {
    if (!await File(path).exists()) {
      if (context.mounted) _notice(context, 'Không tìm thấy tệp để chia sẻ.');
      return;
    }
    try {
      final render = context.findRenderObject();
      final box = render is RenderBox ? render : null;
      final size = MediaQuery.sizeOf(context);
      final rect = box == null
          ? Rect.fromLTWH(size.width / 2, size.height / 2, 1, 1)
          : box.localToGlobal(Offset.zero) & box.size;
      await SharePlus.instance.share(ShareParams(
        files: <XFile>[XFile(path)],
        subject: title,
        sharePositionOrigin: rect,
      ));
    } catch (_) {
      if (context.mounted) _notice(context,
        'Chưa thể mở bảng chia sẻ. Vui lòng thử lại.');
    }
  }

  /// Returns a new file path ONLY when an editable Word document was saved.
  /// Read-only preview always returns null and never changes the attachment.
  static Future<String?> open(BuildContext context, {
    required String path,
    required String title,
    bool allowDocxEditing = false,
  }) async {
    final file = File(path);
    if (!await file.exists() || await file.length() == 0) {
      if (context.mounted) _notice(context,
        'Tệp không tồn tại hoặc trống. Vui lòng tải lại hoặc chọn tệp khác.');
      return null;
    }
    final extension = path.toLowerCase().split('.').last;
    if (extension == 'docx' && allowDocxEditing) {
      if (!context.mounted) return null;
      return Navigator.of(context).push<String>(MaterialPageRoute(
        builder: (_) => _OneDoorEditableWordPage(
          sourcePath: path, fileName: title)));
    }
    const supported = <String>{
      'pdf', 'jpg', 'jpeg', 'png', 'docx', 'xlsx', 'doc', 'xls',
    };
    if (!supported.contains(extension)) {
      if (context.mounted) _notice(context, 'Định dạng tệp chưa được hỗ trợ.');
      return null;
    }
    if (!context.mounted) return null;
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => _OneDoorPreviewPage(
        sourcePath: path, fileName: title, extension: extension)));
    return null;
  }

  static Future<void> _openOutside(BuildContext context, String path) async {
    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done && context.mounted) {
        _notice(context, 'Không mở được bằng ứng dụng trên thiết bị: '
          '${result.message}. Hãy thử Chia sẻ để mở bằng Word/Excel.');
      }
    } catch (_) {
      if (context.mounted) _notice(context,
        'Không mở được tài liệu bên ngoài. Hãy thử Chia sẻ hoặc '
        'cài ứng dụng Word/Excel tương thích.');
    }
  }

  static void _notice(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message),
        backgroundColor: StudentServiceUI.ink),
    );
  }
}

const _previewInk = Color(0xFF1B2B26);
const _previewBackground = Color(0xFFF0F3F4);

/// Header intentionally contains ONLY 'Preview Docs', per UX requirement.
PreferredSizeWidget _previewAppBar(BuildContext context) => AppBar(
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.transparent,
  foregroundColor: _previewInk,
  elevation: 0,
  centerTitle: true,
  titleSpacing: 0,
  systemOverlayStyle: SystemUiOverlayStyle.dark,
  title: const Text('Preview Docs',
    style: TextStyle(fontSize: 17, height: 1.25,
      fontWeight: FontWeight.w700, color: _previewInk)),
  leading: IconButton(
    tooltip: 'Quay lại',
    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
    color: _previewInk,
    onPressed: () => Navigator.of(context).maybePop(),
  ),
  bottom: const PreferredSize(
    preferredSize: Size.fromHeight(1),
    child: SizedBox(height: 1, child: ColoredBox(color: Color(0xFFE5EBE8))),
  ),
);

/// Documents keep their original bytes. Preview is not a converted upload.
/// PDF: native PDFView. DOCX: WebView read-only DOCX renderer (avoids Flutter
/// RenderFlex overflow). XLSX: wide horizontally scrollable fallback; always
/// offer opening in the dedicated Office app to verify complex formatting.
class _OneDoorPreviewPage extends StatefulWidget {
  const _OneDoorPreviewPage({
    required this.sourcePath,
    required this.fileName,
    required this.extension,
  });
  final String sourcePath;
  final String fileName;
  final String extension;

  @override
  State<_OneDoorPreviewPage> createState() => _OneDoorPreviewPageState();
}

class _OneDoorPreviewPageState extends State<_OneDoorPreviewPage> {
  Future<Uint8List>? _xlsxBytes;

  @override
  void initState() {
    super.initState();
    if (widget.extension == 'xlsx') {
      _xlsxBytes = File(widget.sourcePath).readAsBytes();
    }
  }

  String get _officeLabel => switch (widget.extension) {
    'docx' || 'doc' => 'Mở Word',
    'xlsx' || 'xls' => 'Mở Excel',
    'pdf' => 'Mở PDF',
    _ => 'Mở ứng dụng',
  };

  Widget _fileToolbar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
    child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.insert_drive_file_outlined,
          size: 18, color: Color(0xFF576761)),
        const SizedBox(width: 9),
        Expanded(child: Text(widget.fileName,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5,
            fontWeight: FontWeight.w600, color: _previewInk))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () => OneDoorAttachmentPreview.shareFile(context,
            path: widget.sourcePath, title: widget.fileName),
          icon: const Icon(Icons.ios_share_rounded, size: 18),
          label: const Text('Chia sẻ'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _previewInk,
            side: const BorderSide(color: Color(0xFFCCD9D3)),
            minimumSize: const Size.fromHeight(44),
            textStyle: const TextStyle(fontWeight: FontWeight.w600,
              fontSize: 13)),
        )),
        const SizedBox(width: 10),
        Expanded(child: FilledButton.tonalIcon(
          onPressed: () => OneDoorAttachmentPreview.openInOffice(
            context, widget.sourcePath),
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: Text(_officeLabel),
          style: FilledButton.styleFrom(
            foregroundColor: const Color(0xFF185841),
            backgroundColor: const Color(0xFFE5F1EA),
            minimumSize: const Size.fromHeight(44),
            textStyle: const TextStyle(fontWeight: FontWeight.w700,
              fontSize: 13)),
        )),
      ]),
    ]),
  );

  Widget _accuracyNote() {
    if (widget.extension != 'docx' && widget.extension != 'xlsx') {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: const Color(0xFFFFF8E9),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, size: 16,
          color: Color(0xFF926319)),
        SizedBox(width: 8),
        Expanded(child: Text(
          'Bản xem nhanh có thể khác định dạng gốc. '
          'Với mẫu có bảng, logo hoặc vùng ký, hãy chọn Mở Word/Excel '
          'để kiểm tra bố cục trước khi nộp.',
          style: TextStyle(fontSize: 11.5, height: 1.35,
            color: Color(0xFF795215)))),
      ]),
    );
  }

  Widget _excelPreview() => LayoutBuilder(
    builder: (context, constraints) => FutureBuilder<Uint8List>(
      future: _xlsxBytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Không đọc được Excel: ${snapshot.error}',
            textAlign: TextAlign.center));
        }
        final bytes = snapshot.data;
        if (bytes == null) {
          return const Center(child: CircularProgressIndicator());
        }
        // Excel is a grid; give it a sheet-width canvas, then scroll sideways.
        // This is not used for DOCX (which previously overflowed on mobile).
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(constraints.maxWidth, 1100.0),
            height: constraints.maxHeight,
            child: MicrosoftViewer(bytes, true),
          ),
        );
      },
    ),
  );

  Widget _legacyPreview() => Center(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.description_outlined, size: 44,
        color: Color(0xFF687A72)),
      const SizedBox(height: 12),
      Text(widget.extension == 'doc' ? 'Tài liệu Word định dạng cũ' :
        'Bảng tính Excel định dạng cũ',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Để tránh hiển thị sai nội dung, hãy chọn Mở Word/Excel '
        'hoặc Chia sẻ ở phía trên.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, height: 1.5)),
    ]),
  ));

  Widget _document() => switch (widget.extension) {
    'pdf' => PDFView(
      filePath: widget.sourcePath,
      onError: (error) => OneDoorAttachmentPreview._notice(context,
        'Không xem được PDF: $error'),
    ),
    'jpg' || 'jpeg' || 'png' => Center(child: InteractiveViewer(
      minScale: 0.5, maxScale: 5,
      child: Image.file(File(widget.sourcePath), fit: BoxFit.contain),
    )),
    'docx' => ClipRect(child: DocxViewerWidget(
      key: ValueKey<String>(widget.sourcePath),
      filePath: widget.sourcePath,
      config: DocxViewerConfig(isReadOnly: true),
    )),
    'xlsx' => _excelPreview(),
    _ => _legacyPreview(),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _previewBackground,
    appBar: _previewAppBar(context),
    body: SafeArea(top: false, child: Column(children: [
      _fileToolbar(),
      _accuracyNote(),
      Expanded(child: _document()),
    ])),
  );
}

/// The optional DOCX editor saves as a *new* file, not the source template.
class _OneDoorEditableWordPage extends StatefulWidget {
  const _OneDoorEditableWordPage({
    required this.sourcePath, required this.fileName,
  });
  final String sourcePath;
  final String fileName;

  @override
  State<_OneDoorEditableWordPage> createState() =>
      _OneDoorEditableWordPageState();
}

class _OneDoorEditableWordPageState extends State<_OneDoorEditableWordPage> {
  final _viewerKey = GlobalKey<DocxViewerWidgetState>();
  bool _saving = false;

  Future<void> _saveAsAttachment() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final folder = await getTemporaryDirectory();
      final dest = '${folder.path}${Platform.pathSeparator}'
          'onevnu_docx_${DateTime.now().microsecondsSinceEpoch}.docx';
      final result = await _viewerKey.currentState?.save(outputPath: dest);
      final actual = result ?? dest;
      if (!await File(actual).exists() || await File(actual).length() == 0) {
        throw StateError('Không nhận được file Word đã chỉnh sửa.');
      }
      if (!mounted) return;
      Navigator.of(context).pop(actual);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lưu được Word: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _previewBackground,
    appBar: _previewAppBar(context),
    body: SafeArea(top: false, child: Column(children: [
      Container(color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Expanded(child: Text(widget.fileName,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5,
              color: _previewInk, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: _saving ? null : _saveAsAttachment,
            icon: _saving ? const SizedBox(height: 16, width: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_alt_rounded, size: 18),
            label: const Text('Lưu Word'),
          ),
        ])),
      Container(width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        color: const Color(0xFFEAF4F0),
        child: const Text('Nếu cần chỉnh sửa bố cục phức tạp, '
          'hãy mở tài liệu trong Word. Khi Lưu Word tại đây, '
          'ứng dụng tạo bản DOCX mới để đính kèm.',
          style: TextStyle(fontSize: 12.1, height: 1.4,
            color: StudentServiceUI.ink))),
      Expanded(child: DocxViewerWidget(
        key: _viewerKey,
        filePath: widget.sourcePath,
        config: DocxViewerConfig(isReadOnly: false,
          toolbarPosition: ToolbarPosition.bottom),
      )),
    ])),
  );
}
