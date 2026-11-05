import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/student_service_ui.dart';

/// Final document-by-document review before leaving One Door step 2.
/// A file is never marked verified merely because an external viewer opened.
class OneDoorReviewFile {
  const OneDoorReviewFile({
    required this.id,
    required this.paperName,
    required this.fileName,
    required this.path,
    required this.bytes,
    required this.isRequired,
  });
  final String id;
  final String paperName;
  final String fileName;
  final String path;
  final int bytes;
  final bool isRequired;

  String get extension =>
      fileName.toLowerCase().split('.').last;
  bool get isOffice => <String>{'doc', 'docx', 'xls', 'xlsx'}
      .contains(extension);
}

class OneDoorAttachmentReviewSheet extends StatefulWidget {
  const OneDoorAttachmentReviewSheet({super.key, required this.files,
      required this.onPreview, required this.onOpenOffice,
      required this.onShare});

  final List<OneDoorReviewFile> files;
  final Future<void> Function(OneDoorReviewFile file) onPreview;
  final Future<void> Function(OneDoorReviewFile file) onOpenOffice;
  final Future<void> Function(OneDoorReviewFile file) onShare;

  @override
  State<OneDoorAttachmentReviewSheet> createState() =>
      _OneDoorAttachmentReviewSheetState();
}

class _OneDoorAttachmentReviewSheetState
    extends State<OneDoorAttachmentReviewSheet> {
  final Set<String> _reviewed = <String>{};
  bool _confirmed = false;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được tệp. Hãy thử mở bằng '
          'ứng dụng Office hoặc chọn lại file đã lưu trên thiết bị.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _fileCard(OneDoorReviewFile file) {
    final checked = _reviewed.contains(file.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white,
        border: Border.all(color: StudentServiceUI.line),
        borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.insert_drive_file_outlined, size: 22,
            color: StudentServiceUI.green),
          const SizedBox(width: 9),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(file.paperName, style: const TextStyle(fontSize: 13.5,
                  fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(file.fileName, style: const TextStyle(fontSize: 12.5,
                  color: StudentServiceUI.secondary)),
              const SizedBox(height: 3),
              Text('${(file.bytes / 1024).toStringAsFixed(1)} KB · '
                  '${file.extension.toUpperCase()}${file.isRequired ? ' · Bắt buộc' : ''}',
                style: const TextStyle(fontSize: 11.5,
                  color: StudentServiceUI.secondary)),
            ],
          )),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 4, runSpacing: 0, children: [
          TextButton.icon(
            onPressed: _busy ? null : () => _run(() => widget.onPreview(file)),
            icon: const Icon(Icons.visibility_outlined, size: 17),
            label: const Text('Xem lại tệp')),
          if (file.isOffice)
            TextButton.icon(
              onPressed: _busy ? null : () => _run(() => widget.onOpenOffice(file)),
              icon: const Icon(Icons.open_in_new, size: 17),
              label: const Text('Mở Office')),
          TextButton.icon(
            onPressed: _busy ? null : () => _run(() => widget.onShare(file)),
            icon: const Icon(Icons.ios_share_outlined, size: 17),
            label: const Text('Lưu / chia sẻ')),
        ]),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero, dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          value: checked,
          title: const Text('Tôi đã xem và kiểm tra nội dung tệp này',
            style: TextStyle(fontSize: 12.5)),
          onChanged: _busy ? null : (value) => setState(() {
            if (value == true) {
              _reviewed.add(file.id);
            } else {
              _reviewed.remove(file.id);
            }
          }),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allReviewed = widget.files.every((file) => _reviewed.contains(file.id));
    final canContinue = allReviewed && _confirmed && !_busy;
    return SafeArea(top: false, child: Column(children: [
      const SizedBox(height: 14),
      Container(width: 42, height: 4,
        decoration: BoxDecoration(color: const Color(0xFFD1D6D8),
          borderRadius: BorderRadius.circular(4))),
      Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        child: Row(children: [
          const Icon(Icons.fact_check_outlined, color: StudentServiceUI.green),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kiểm tra trước khi tiếp tục', style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
              SizedBox(height: 5),
              Text('Bạn có chắc chắn thông tin trong các tài liệu đã đúng? '
                'Hãy xem lại từng tệp, rồi xác nhận.',
                style: TextStyle(fontSize: 12.5,
                  color: StudentServiceUI.secondary)),
            ])),
          IconButton(tooltip: 'Đóng', onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close)),
        ])),
      const Divider(height: 1),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        children: [
          if (widget.files.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Chưa đính kèm tệp nào. Chỉ tiếp tục nếu thủ tục '
                'không yêu cầu giấy tờ bắt buộc.',
                style: TextStyle(color: StudentServiceUI.secondary))),
          ...widget.files.map(_fileCard),
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF8E8),
              border: Border.all(color: const Color(0xFFFFE0A2)),
              borderRadius: BorderRadius.circular(10)),
            child: const Text('Nếu vừa sửa bằng Word/Excel bên ngoài, '
              'hãy quay lại bước Tài liệu đính kèm và chọn Thay tệp. '
              'OneVNU không tự nhận bản bạn lưu trong ứng dụng Office.',
              style: TextStyle(fontSize: 12.5,
                color: Color(0xFF7D581E)))),
        ])),
      Container(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: const BoxDecoration(color: Colors.white,
          border: Border(top: BorderSide(color: StudentServiceUI.line))),
        child: Column(children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero, dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: _confirmed,
            title: const Text('Tôi xác nhận đây là các bản cuối cùng '
              'đúng thông tin và đồng ý chuyển sang bước kiểm tra hồ sơ.',
              style: TextStyle(fontSize: 12.8,
                fontWeight: FontWeight.w600)),
            onChanged: _busy ? null : (value) => setState(
              () => _confirmed = value == true),
          ),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: const Text('Quay lại sửa'))),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: FilledButton.icon(
              onPressed: canContinue ? () => Navigator.of(context).pop(true) : null,
              icon: const Icon(Icons.check_circle_outline, size: 19),
              label: const Text('Xác nhận & tiếp tục'),
              style: FilledButton.styleFrom(backgroundColor: StudentServiceUI.green,
                foregroundColor: Colors.white))),
          ]),
        ])),
    ]));
  }
}
