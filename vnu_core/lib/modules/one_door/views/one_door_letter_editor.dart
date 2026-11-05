import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/modules/one_door/data/one_door_letter_pdf.dart';
import 'package:vnu_core/modules/one_door/data/one_door_student_prefill.dart';
import 'package:vnu_core/modules/one_door/views/one_door_attachment_preview.dart';
import 'package:vnu_core/widgets/student_service_ui.dart';

/// The in-app letter is an editable NEW document. It intentionally does not
/// claim to edit an official server-provided DOCX/PDF template in place.
class OneDoorLetterDraft {
  const OneDoorLetterDraft({required this.values, required this.template});
  final Map<String, String> values;
  final String template;

  static const fieldLabels = <String, String>{
    'HoTen': 'Họ và tên',
    'MaSV': 'Mã sinh viên',
    'NgaySinh': 'Ngày sinh',
    'CCCD': 'CCCD',
    'TenLop': 'Tên lớp',
    'SoDienThoai': 'Số điện thoại',
    'Email': 'Email',
    'He': 'Hệ đào tạo',
    'NamHoc': 'Năm học (có thể chỉnh)',
    'Ngay': 'Ngày làm đơn',
    'Thang': 'Tháng làm đơn',
    'Nam': 'Năm làm đơn',
    'MaHoSo': 'Mã hồ sơ sinh viên OneVNU',
    'TenThuTuc': 'Tên thủ tục',
    'YeuCau': 'Nội dung yêu cầu',
    'SoLuongBan': 'Số lượng bản',
    'NgayNop': 'Ngày dự kiến nộp (chỉnh được)',
    'TenKhoa': 'Tên khoa',
    'NganhHoc': 'Ngành học',
    'TenDonVi': 'Đơn vị tiếp nhận',
    'TruongHoc': 'Trường đang học (Thông tin cá nhân)',
    'KhoaHoc': 'Khóa học / Niên khóa (khác tên khoa)',
  };

  /// All 18 requested markers are present on the visible paper, not only
  /// in the insert-data menu. `He` and `TenDonVi` remain extra fields.
  static const requiredFields = <String>[
    'HoTen', 'MaSV', 'NgaySinh', 'CCCD', 'TenLop', 'SoDienThoai',
    'Email', 'NamHoc', 'Ngay', 'Thang', 'Nam', 'MaHoSo',
    'TenThuTuc', 'YeuCau', 'SoLuongBan', 'NgayNop', 'TenKhoa', 'NganhHoc',
  ];

  static const defaultTemplate = '''CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM
Độc lập - Tự do - Hạnh phúc

ĐƠN ĐỀ NGHỊ
(V/v: {TenThuTuc})

Kính gửi: {TenDonVi}

Tôi tên là: {HoTen}
Mã sinh viên: {MaSV}        Ngày sinh: {NgaySinh}
CCCD: {CCCD}
Lớp: {TenLop}        Ngành học: {NganhHoc}
Hệ đào tạo: {He}        Khoa: {TenKhoa}
Năm học: {NamHoc}
Mã hồ sơ sinh viên OneVNU: {MaHoSo}
Số điện thoại: {SoDienThoai}
Email: {Email}

Nay tôi làm đơn này kính đề nghị:
{YeuCau}

Số lượng bản đề nghị: {SoLuongBan}.
Ngày dự kiến nộp hồ sơ: {NgayNop}

Tôi cam kết những thông tin trên là đúng và chịu trách nhiệm về nội dung đề nghị.

Ngày {Ngay} tháng {Thang} năm {Nam}
Người làm đơn
(Ký và ghi rõ họ tên)

{HoTen}''';

  static final RegExp tokenPattern = RegExp(r'\{([A-Za-z][A-Za-z0-9]*)\}');

  Set<String> get missingTokens {
    final missing = <String>{};
    for (final match in tokenPattern.allMatches(template)) {
      final token = match.group(1)!;
      if ((values[token] ?? '').trim().isEmpty) missing.add(token);
    }
    return missing;
  }

  String render({bool showBlanks = true}) =>
      template.replaceAllMapped(tokenPattern, (match) {
        final value = values[match.group(1)!]?.trim() ?? '';
        return value.isNotEmpty ? value : (showBlanks ? '____________' : '');
      });
}

class OneDoorLetterResult {
  const OneDoorLetterResult({required this.path, required this.draft});
  final String path;
  final OneDoorLetterDraft draft;
}

class OneDoorLetterEditorPage extends StatefulWidget {
  const OneDoorLetterEditorPage({super.key, required this.documentName,
    required this.initialDraft, required this.initialPrefillStatus,
    this.onReloadFromOneVnu});

  final String documentName;
  final OneDoorLetterDraft initialDraft;
  final String initialPrefillStatus;
  final Future<OneDoorStudentPrefill> Function()? onReloadFromOneVnu;

  @override
  State<OneDoorLetterEditorPage> createState() => _OneDoorLetterEditorPageState();
}

class _OneDoorLetterEditorPageState extends State<OneDoorLetterEditorPage> {
  /// The editable A4 paper is the source of truth. No separate read-only
  /// preview with an unrelated text-entry form is used in V13.
  final GlobalKey _documentKey = GlobalKey();
  final FocusNode _paperFocus = FocusNode();
  late final TextEditingController _paperController;
  late final String _originalTemplate;
  late final Map<String, String> _fieldValues;
  late String _prefillStatus;
  bool _editedOnPaper = false;
  bool _readOnly = false;
  bool _saving = false;
  bool _refreshing = false;

  static const _paperTextStyle = TextStyle(
    fontSize: 15, height: 1.55, color: Color(0xFF17232B),
  );

  @override
  void initState() {
    super.initState();
    _originalTemplate = widget.initialDraft.template;
    _fieldValues = <String, String>{...widget.initialDraft.values};
    _paperController = TextEditingController(text: widget.initialDraft.render());
    _prefillStatus = widget.initialPrefillStatus;
  }

  @override
  void dispose() {
    _paperFocus.dispose();
    _paperController.dispose();
    super.dispose();
  }

  OneDoorLetterDraft get _draft => OneDoorLetterDraft(
    values: <String, String>{..._fieldValues},
    // The exact A4 text the student edited is the file we save. Do not
    // regenerate from stale placeholders after editing the actual document.
    template: _paperController.text,
  );

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reloadStudentFields() async {
    final callback = widget.onReloadFromOneVnu;
    if (_refreshing || _saving || callback == null) return;
    setState(() => _refreshing = true);
    try {
      final update = await callback();
      if (!mounted) return;
      // Never reset procedure data (request, copies, dates) when refreshing
      // the student's personal information.
      const profileKeys = <String>{
        'HoTen', 'MaSV', 'NgaySinh', 'CCCD', 'TenLop',
        'SoDienThoai', 'Email', 'He', 'MaHoSo', 'NganhHoc', 'TenKhoa',
      };
      final incoming = <String, String>{};
      for (final key in profileKeys) {
        final newValue = (update.values[key] ?? '').trim();
        if (newValue.isNotEmpty) incoming[key] = newValue;
      }
      final conflicting = incoming.keys.where((key) {
        final previous = (_fieldValues[key] ?? '').trim();
        return previous.isNotEmpty && previous != incoming[key];
      }).toList();
      var overwrite = false;
      if (conflicting.isNotEmpty) {
        final answer = await showDialog<bool>(context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('C\u1eadp nh\u1eadt th\u00f4ng tin OneVNU?'),
            content: Text('C\u00f3 ${conflicting.length} tr\u01b0\u1eddng kh\u00e1c v\u1edbi th\u00f4ng tin '
              'c\u00e1 nh\u00e2n hi\u1ec7n t\u1ea1i. '
              'B\u1ea1n mu\u1ed1n gi\u1eef gi\u00e1 tr\u1ecb \u0111\u00e3 s\u1eeda hay c\u1eadp nh\u1eadt t\u1eeb h\u1ed3 s\u01a1?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext),
                child: const Text('H\u1ee7y')),
              TextButton(onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Ch\u1ec9 \u0111i\u1ec1n \u00f4 tr\u1ed1ng')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('D\u00f9ng d\u1eef li\u1ec7u OneVNU')),
            ],
          ),
        );
        if (!mounted || answer == null) return;
        overwrite = answer;
      }
      var changed = 0;
      for (final entry in incoming.entries) {
        final old = (_fieldValues[entry.key] ?? '').trim();
        if ((old.isEmpty || overwrite) && old != entry.value) {
          _fieldValues[entry.key] = entry.value;
          changed++;
        }
      }
      setState(() {
        _prefillStatus = changed == 0
          ? 'Kh\u00f4ng c\u00f3 th\u00f4ng tin m\u1edbi \u0111\u1ec3 \u0111i\u1ec1n v\u00e0o \u0111\u01a1n.'
          : '\u0110\u00e3 l\u1ea5y $changed tr\u01b0\u1eddng t\u1eeb Th\u00f4ng tin c\u00e1 nh\u00e2n OneVNU. '
            'B\u1ea3n gi\u1ea5y c\u1ea7n \u0111\u1ed3ng b\u1ed9 \u0111\u1ec3 hi\u1ec3n th\u1ecb gi\u00e1 tr\u1ecb m\u1edbi.';
      });
      if (changed > 0) {
        // _applyFieldsToPaper asks before discarding direct on-paper edits.
        // This also updates previously saved drafts with flattened tokens.
        await _applyFieldsToPaper(fromRefresh: true);
      }
    } catch (_) {
      if (mounted) _notify('Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c h\u1ed3 s\u01a1 OneVNU. \u0110\u01a1n \u0111\u01b0\u1ee3c gi\u1eef nguy\u00ean.');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _insertStudentValue(String token) async {
    var value = (_fieldValues[token] ?? '').trim();
    if (value.isEmpty) {
      final input = TextEditingController();
      try {
        final answer = await showDialog<String>(context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(OneDoorLetterDraft.fieldLabels[token] ?? token),
            content: TextField(controller: input, autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Nhập giá trị để điền vào tờ đơn'),
              onSubmitted: (text) => Navigator.of(dialogContext).pop(text)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, input.text),
                child: const Text('Điền vào đơn')),
            ],
          ),
        );
        if (answer == null || answer.trim().isEmpty || !mounted) return;
        value = answer.trim();
        _fieldValues[token] = value;
      } finally {
        // Do not dispose a controller before its dialog closing animation.
        await Future<void>.delayed(const Duration(milliseconds: 250));
        input.dispose();
      }
    }
    if (!mounted) return;
    setState(() {
      _readOnly = false;
      final old = _paperController.text;
      final selection = _paperController.selection;
      final begin = selection.isValid ? selection.start : old.length;
      final end = selection.isValid ? selection.end : old.length;
      _paperController.value = TextEditingValue(
        text: old.replaceRange(begin, end, value),
        selection: TextSelection.collapsed(offset: begin + value.length),
      );
      _editedOnPaper = true;
    });
    _paperFocus.requestFocus();
  }

  int get _filledFields => OneDoorLetterDraft.requiredFields
      .where((key) => (_fieldValues[key] ?? '').trim().isNotEmpty).length;

  Future<void> _applyFieldsToPaper({bool fromRefresh = false}) async {
    if (_saving || (_refreshing && !fromRefresh)) return;
    // A previously saved, flattened draft can contain manual customizations
    // even if the student has not typed again in this editor session.
    if (_editedOnPaper || (fromRefresh &&
        !_originalTemplate.contains('{HoTen}'))) {
      final confirm = await showDialog<bool>(context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Tạo lại đơn từ dữ liệu?'),
          content: const Text('Bạn đã sửa chữ trực tiếp trên giấy. '
            'Tạo lại mẫu sẽ thay nội dung đã gõ bằng các trường hiện tại. '
            'Chọn Hủy nếu muốn giữ nguyên bản đã sửa.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Giữ bản hiện tại')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Tạo lại đơn')),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }
    final updated = OneDoorLetterDraft(
      values: _fieldValues,
      template: OneDoorLetterDraft.defaultTemplate,
    ).render();
    setState(() {
      _readOnly = false;
      _editedOnPaper = false;
      _paperController.value = TextEditingValue(text: updated,
        selection: TextSelection.collapsed(offset: updated.length));
    });
    _notify('Đã cập nhật đầy đủ các biến vào nội dung tờ đơn.');
  }

  Future<void> _editField(String token) async {
    if (_saving || _refreshing) return;
    if (<String>{'TenThuTuc', 'YeuCau', 'SoLuongBan'}.contains(token)) {
      _notify('Trường này lấy từ bước Thông tin yêu cầu. Hãy sửa ở bước trước.');
      return;
    }
    final controller = TextEditingController(text: _fieldValues[token] ?? '');
    try {
      final result = await showDialog<String>(context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(OneDoorLetterDraft.fieldLabels[token] ?? token),
          content: TextField(controller: controller, autofocus: true,
            maxLines: token == 'TenKhoa' ? 2 : 1,
            decoration: InputDecoration(
              hintText: 'Nhập ${OneDoorLetterDraft.fieldLabels[token] ?? token}'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Lưu dữ liệu')),
          ],
        ),
      );
      if (result == null || !mounted) return;
      setState(() => _fieldValues[token] = result.trim());
      if (!_editedOnPaper && _originalTemplate.contains('{' + token + '}')) {
        final updated = OneDoorLetterDraft(values: _fieldValues,
          template: _originalTemplate).render();
        setState(() => _paperController.text = updated);
      } else {
        _notify('Đã lưu giá trị. Chọn Đồng bộ tờ đơn để cập nhật chữ trên giấy.');
      }
    } finally {
      // Dialog can have a reverse transition using the controller.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      controller.dispose();
    }
  }

  void _showInsertSheet() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(context: context, isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(heightFactor: .73,
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('Thông tin đơn • $_filledFields/18 trường',
                  style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w700))),
            ),
            const Divider(height: 1),
            Expanded(child: ListView.builder(
              itemCount: OneDoorLetterDraft.fieldLabels.length,
              itemBuilder: (_, index) {
                final token = OneDoorLetterDraft.fieldLabels.keys.elementAt(index);
                final label = OneDoorLetterDraft.fieldLabels[token]!;
                final value = (_fieldValues[token] ?? '').trim();
                return ListTile(dense: true, title: Text(label),
                  subtitle: Text(value.isEmpty ? 'Cần bổ sung – chạm để nhập' : value,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    tooltip: 'Chèn giá trị tại con trỏ',
                    icon: const Icon(Icons.add_circle_outline, size: 21),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _insertStudentValue(token);
                    }),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _editField(token);
                  },
                );
              },
            )),
            Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: SizedBox(width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _applyFieldsToPaper();
                  },
                  icon: const Icon(Icons.autorenew_rounded),
                  label: const Text('Đồng bộ tờ đơn từ 18 trường dữ liệu'),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<bool> _confirmBlanks() async {
    final body = _paperController.text;
    final unfilled = OneDoorLetterDraft.requiredFields
      .where((key) => (_fieldValues[key] ?? '').trim().isEmpty).toList();
    final containsBlanks = body.contains('____________') ||
        OneDoorLetterDraft.tokenPattern.hasMatch(body);
    if (!containsBlanks && unfilled.isEmpty) return true;
    final missingText = unfilled.isEmpty ? '' :
      'Dữ liệu cần kiểm tra: ${unfilled.map((key) => OneDoorLetterDraft.fieldLabels[key] ?? key).join(', ')}.\n\n';
    final approved = await showDialog<bool>(context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kiểm tra thông tin đơn'),
        content: Text('$missingText'
          'Tờ đơn có thể còn trường trống hoặc nội dung người dùng chưa xác nhận. '
          'Bạn có muốn tiếp tục xuất PDF không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Sửa tiếp')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xuất PDF')),
        ],
      ),
    );
    return approved == true;
  }

  Future<void> _export({bool previewOnly = false,
      bool shareOnly = false}) async {
    if (_saving || _paperController.text.trim().isEmpty) return;
    if (!await _confirmBlanks()) return;
    if (!mounted) return;
    _paperFocus.unfocus();
    // TextField has selection handles/cursor which must never appear in an
    // administrative document. Paint the SAME text as static Text for export.
    setState(() => _saving = true);
    String? filePath;
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      filePath = await exportOneDoorLetterPdf(_documentKey);
      if (!mounted) return;
      if (previewOnly) {
        await OneDoorAttachmentPreview.open(context,
          path: filePath, title: widget.documentName);
      } else if (shareOnly) {
        // SharePlus shows Android/iOS native share targets (Zalo if installed).
        // The exported PDF is the very same editable A4 content, including
        // user corrections; sharing never counts as an uploaded attachment.
        final dir = await getTemporaryDirectory();
        final friendly = File('${dir.path}${Platform.pathSeparator}'
          'Don_da_dien_OneVNU_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await File(filePath).copy(friendly.path);
        await OneDoorAttachmentPreview.shareFile(context,
          path: friendly.path, title: '${widget.documentName} - bản đã điền');
        // The share target may still need its cache copy. OS cache cleanup
        // will remove it later; never mark sharing as an uploaded document.
        try { await File(filePath).delete(); } catch (_) {}
        filePath = null;
      } else {
        Navigator.of(context).pop(OneDoorLetterResult(
          path: filePath, draft: _draft));
        filePath = null; // handed off to the upload wizard
      }
    } catch (error) {
      if (mounted) _notify('Không tạo được PDF: $error');
    } finally {
      if (previewOnly && filePath != null) {
        try { await File(filePath).delete(); } catch (_) {}
      }
      if (mounted) setState(() => _saving = false);
    }
  }

  /// A true WYSIWYG *text letter*: the same A4 widget is edited, previewed
  /// and exported. This is not a DOCX/XLSX/PDF arbitrary-layout file editor.
  Widget _a4Paper(double displayWidth) => Center(
    child: SizedBox(width: displayWidth,
      child: FittedBox(fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: RepaintBoundary(key: _documentKey,
          child: Container(
            width: 595,
            constraints: const BoxConstraints(minHeight: 842),
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(58, 58, 54, 56),
            child: (_saving || _readOnly)
              ? Text(_paperController.text, style: _paperTextStyle,
                  textAlign: TextAlign.left)
              : TextField(
                  controller: _paperController,
                  focusNode: _paperFocus,
                  maxLines: null,
                  minLines: 25,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  scrollPhysics: const NeverScrollableScrollPhysics(),
                  textCapitalization: TextCapitalization.sentences,
                  style: _paperTextStyle,
                  cursorColor: StudentServiceUI.green,
                  decoration: const InputDecoration(
                    border: InputBorder.none, isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) { _editedOnPaper = true; },
                ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F5F7),
    appBar: AppBar(
      title: Text(widget.documentName, maxLines: 1,
        overflow: TextOverflow.ellipsis),
      backgroundColor: Colors.white,
      actions: [
        if (widget.onReloadFromOneVnu != null)
          IconButton(
            onPressed: _refreshing || _saving ? null : _reloadStudentFields,
            tooltip: 'Lấy thông tin từ OneVNU',
            icon: _refreshing
              ? const SizedBox(height: 17, width: 17,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.sync_rounded),
          ),
      ],
    ),
    body: SafeArea(child: Column(children: [
      Container(width: double.infinity, color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_readOnly ? Icons.visibility_outlined : Icons.edit_note_outlined,
              color: StudentServiceUI.green, size: 19),
            const SizedBox(width: 8),
            Expanded(child: Text(_readOnly
              ? 'Đang xem bản in — nhấn Sửa trên giấy để tiếp tục'
              : 'Chạm vào chữ trên tờ đơn để sửa ngay tại vị trí đó',
              style: const TextStyle(color: StudentServiceUI.ink,
                fontSize: 12.6, fontWeight: FontWeight.w600))),
            TextButton.icon(
              onPressed: _saving ? null : () {
                _paperFocus.unfocus();
                setState(() => _readOnly = !_readOnly);
              },
              icon: Icon(_readOnly ? Icons.edit_note : Icons.visibility,
                size: 18),
              label: Text(_readOnly ? 'Sửa trên giấy' : 'Bản in',
                style: const TextStyle(fontSize: 12)),
            ),
          ]),
          Text(_prefillStatus, maxLines: 3, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.7,
              color: StudentServiceUI.secondary)),
        ]),
      ),
      Expanded(child: LayoutBuilder(builder: (context, constraints) =>
        SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 28),
          child: Column(children: [
            const Text('Đơn đang hiển thị là nội dung sẽ xuất ra PDF.',
              style: TextStyle(fontSize: 11.8,
                color: StudentServiceUI.secondary)),
            const SizedBox(height: 10),
            DecoratedBox(decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .09),
                blurRadius: 18, offset: const Offset(0, 6))]),
              child: _a4Paper(math.min(595.0, math.max(200.0,
                constraints.maxWidth - 16))),
            ),
            const SizedBox(height: 16),
            const Text('Biểu mẫu tạo trong OneVNU; file mẫu Word/PDF/Excel '
                'chính thức được xem riêng và không bị ghi đè.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5,
                color: StudentServiceUI.secondary)),
          ]),
        ),
      )),
      Container(padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
        decoration: const BoxDecoration(color: Colors.white,
          border: Border(top: BorderSide(color: StudentServiceUI.line))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            OutlinedButton.icon(
              onPressed: _saving ? null : _showInsertSheet,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text('Dữ liệu ($_filledFields/18)',
                style: const TextStyle(fontSize: 12)),
            ),
            const Spacer(),
            IconButton.outlined(
              onPressed: _saving ? null : () => _export(previewOnly: true),
              tooltip: 'Xem bản PDF đã điền',
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: _saving ? null : () => _export(shareOnly: true),
              tooltip: 'Chia sẻ bản đã điền qua Zalo hoặc máy tính',
              icon: const Icon(Icons.ios_share_outlined),
            ),
          ]),
          const SizedBox(height: 7),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _saving ? null : _export,
            icon: const Icon(Icons.check_rounded, size: 19),
            style: FilledButton.styleFrom(
              backgroundColor: StudentServiceUI.green,
              minimumSize: const Size.fromHeight(48)),
            label: _saving
              ? const SizedBox(height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2,
                    color: Colors.white))
              : const Text('Lưu & đính kèm vào hồ sơ',
                  style: TextStyle(fontSize: 13.5)),
          )),
        ]),
      ),
    ])),
  );
}
