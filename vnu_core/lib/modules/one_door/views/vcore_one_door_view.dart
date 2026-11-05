import 'dart:async';
import 'dart:ui' show FontFeature;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:vnu_core/modules/one_door/views/one_door_letter_editor.dart';
import 'package:vnu_core/modules/one_door/data/one_door_student_prefill.dart';
import 'package:vnu_core/modules/one_door/views/one_door_attachment_preview.dart';
import 'package:vnu_core/modules/one_door/views/one_door_attachment_review.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/one_door/data/one_door_live_api.dart';
import 'package:vnu_core/modules/one_door/data/one_door_live_repository.dart';
import 'package:vnu_core/widgets/vnu_loading.dart';
import 'package:intl/intl.dart';
import 'package:vnu_core/modules/one_door/data/one_door_demo_repository.dart';
import 'package:vnu_core/widgets/module_detail_icon.dart';
import 'package:vnu_core/widgets/student_service_ui.dart';
import 'package:vnu_core/widgets/vcore_action_dialog.dart';
import 'package:vnu_core/widgets/select/vnu_select.dart';
import 'package:vnu_core/widgets/vcore_notice_toast.dart';
import 'package:vnu_core/widgets/vnu_press_motion.dart';

/// Native One Door. Exchange ONEVNU session for a One Door token on entry.
/// Debug may fall back to mock UI. Release never displays fabricated records.
class VcoreOneDoorView extends StatefulWidget {
  const VcoreOneDoorView({super.key});

  @override
  State<VcoreOneDoorView> createState() => _VcoreOneDoorViewState();
}

enum _DoorPage { overview, procedure, form, record, supplement }

enum _DoorFormStep { request, attachments, review }

/// Flattened section + row model for lazy ListView.builder rendering.
class _OneDoorListEntry {
  const _OneDoorListEntry.section(this.title, this.count, this.group)
      : procedure = null;
  const _OneDoorListEntry.item(this.procedure)
      : title = '', count = 0, group = null;
  final String title;
  final int count;
  final OneDoorProcedureGroup? group;
  final OneDoorProcedure? procedure;
}

class _VcoreOneDoorViewState extends State<VcoreOneDoorView> {
  OneDoorRepository _repo = OneDoorDemoRepository.instance;
  bool _authResolved = false;
  bool _live = false;
  String? _connectionError;
  static const bool _forceMockInDebug = bool.fromEnvironment(
    'ONEVNU_ONE_DOOR_MOCK', defaultValue:false);
  final Map<String,String> _filePaths=<String,String>{};
  final Map<String,String> _supplementPaths=<String,String>{};
  final TextEditingController _search = TextEditingController();
  final TextEditingController _request = TextEditingController();
  final TextEditingController _supplementNote = TextEditingController();
  List<OneDoorProcedure> _procedures = const <OneDoorProcedure>[];
  List<OneDoorRecord> _records = const <OneDoorRecord>[];
  _DoorPage _page = _DoorPage.overview;
  bool _myRecordsTab = false;
  bool _loading = true;
  bool _submitting = false;
  String _domain = 'Tất cả';
  String _statusFilter = 'Tất cả';
  /// All means only MY school + ĐHQGHN, never all other schools.
  String _scopeFilter = 'all';
  int? _mySchoolId;
  String? _mySchoolName;
  OneDoorScopeCatalog? _scopeCatalog;
  String? _scopeWarning;
  bool _schoolCollapsed = false;
  bool _universityCollapsed = false;
  bool _unclassifiedCollapsed = false;
  String _delivery = '';
  int _quantity = 1;
  int _formStep = 0;
  OneDoorProcedure? _selectedProcedure;
  OneDoorRecord? _selectedRecord;
  bool _procedureLoading = false;
  bool _procedureReady = false;
  String? _procedureError;
  bool _deliveryFromLookup = false;
  String? _deliveryWarning;
  int? _confirmedLargeQuantity;
  int _procedureRequestSerial = 0;

  List<_DoorFormStep> get _formSteps => <_DoorFormStep>[
    _DoorFormStep.request,
    if (_selectedProcedure?.papers.isNotEmpty ?? false)
      _DoorFormStep.attachments,
    _DoorFormStep.review,
  ];

  _DoorFormStep get _currentStep => _formSteps[_formStep];
  final Map<String, String> _files = <String, String>{};
  final Map<String, String> _supplementFiles = <String, String>{};
  final Map<String, OneDoorLetterDraft> _letterDrafts = <String, OneDoorLetterDraft>{};
  final Set<String> _generatedPdfPaths = <String>{};
  final Set<String> _generatedWordPaths = <String>{};
  final Map<String, String> _editedWordWizardContext = <String, String>{};
  final Set<String> _paperBusy = <String>{};

  // Step 2 notice must stay visible for ten seconds before proceeding.
  // The countdown starts on ENTERING the attachment step, not on page load.
  static const int _attachmentReadDurationSeconds = 10;
  int _attachmentSecondsRemaining = _attachmentReadDurationSeconds;
  Timer? _attachmentReadTimer;

  void _startAttachmentCountdown() {
    _attachmentReadTimer?.cancel();
    _attachmentSecondsRemaining = _attachmentReadDurationSeconds;
    _attachmentReadTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _page != _DoorPage.form ||
          _currentStep != _DoorFormStep.attachments) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_attachmentSecondsRemaining > 0) _attachmentSecondsRemaining--;
      });
      if (_attachmentSecondsRemaining == 0) timer.cancel();
    });
  }

  void _previousFormStep() {
    if (_submitting || _page != _DoorPage.form || _formStep <= 0) return;
    setState(() => _formStep--);
    if (_currentStep == _DoorFormStep.attachments) {
      _startAttachmentCountdown();
    } else {
      _attachmentReadTimer?.cancel();
    }
  }

  void _advanceFormStep() {
    if (_page != _DoorPage.form || _formStep + 1 >= _formSteps.length) return;
    setState(() => _formStep++);
    if (_currentStep == _DoorFormStep.attachments) {
      _startAttachmentCountdown();
    } else {
      _attachmentReadTimer?.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
    _load();
  }

  // Only app-generated temporary PDFs are deleted. Never delete user files.
  void _forgetGeneratedPdf(String? path) {
    if (path == null || !_generatedPdfPaths.remove(path)) return;
    File(path).delete().catchError((Object _) => File(path));
  }

  void _forgetGeneratedWord(String? path) {
    if (path == null || !_generatedWordPaths.remove(path)) return;
    File(path).delete().catchError((Object _) => File(path));
  }

  void _clearGeneratedPdfs() {
    for (final path in _generatedPdfPaths.toList()) {
      _forgetGeneratedPdf(path);
    }
    for (final path in _generatedWordPaths.toList()) {
      _forgetGeneratedWord(path);
    }
    _editedWordWizardContext.clear();
  }

  /// A local edited DOCX becomes the actual attachment, never the unchanged
  /// downloaded template. Preserve backend paper ID for multipart upload.
  void _rememberEditedWord(OneDoorPaper paper, String path,
      {bool supplement = false}) {
    if (!mounted || _submitting) return;
    setState(() {
      final previous = (supplement ? _supplementPaths : _filePaths)[paper.id];
      _generatedWordPaths.add(path);
      (supplement ? _supplementPaths : _filePaths)[paper.id] = path;
      (supplement ? _supplementFiles : _files)[paper.id] =
          path.split(Platform.pathSeparator).last;
      if (!supplement) {
        _letterDrafts.remove(paper.id);
        _editedWordWizardContext[paper.id] =
          '${_quantity}::${_request.text.trim()}';
      }
      if (previous != path) {
        _forgetGeneratedPdf(previous);
        _forgetGeneratedWord(previous);
      }
    });
  }

  @override
  void dispose() {
    _attachmentReadTimer?.cancel();
    // Avoid deleting a file while Dio may still be uploading it.
    if (!_submitting) _clearGeneratedPdfs();
    _search.removeListener(_onSearch);
    _search.dispose();
    _request.dispose();
    _supplementNote.dispose();
    super.dispose();
  }

  void _onSearch() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    setState(() { _loading = true; _connectionError = null; });
    try {
      if (!_authResolved) {
        if (kDebugMode && _forceMockInDebug) {
          _repo = OneDoorDemoRepository.instance;
          _live = false;
        } else {
          try {
            final token=Globals().token.trim();
            if (token.isEmpty) throw StateError('Chưa có phiên ONEVNU');
            final auth = OneDoorOneVnuAuthApi();
            final oneDoorSession=await auth.exchange(oneVnuJwt:token);
            final api=OneDoorLiveApi(oneDoorSession,
              refreshSession: () async {
                final current=Globals().token.trim();
                if (current.isEmpty || current != token) {
                  throw StateError('ONEVNU login session has changed');
                }
                return auth.exchange(oneVnuJwt:current);
              });
            // Verify the new One Door session before loading private cases.
            await api.currentUser();
            _repo=OneDoorLiveRepository(api);
            _live=true;
          } catch (_) {
            // Never silently turn real API errors into fabricated records.
            // Explicit --dart-define=ONEVNU_ONE_DOOR_MOCK=true enables UI-only demo.
            rethrow;
          }
        }
        _authResolved=true;
      }
      final procedures = await _repo.listProcedures();
      final records = await _repo.myRecords();
      OneDoorScopeCatalog? catalog;
      OneDoorUnitOption? currentSchool;
      String? scopeWarning;
      if (_repo is OneDoorLiveRepository) {
        final liveRepo = _repo as OneDoorLiveRepository;
        try {
          catalog = await liveRepo.procedureCatalog();
        } catch (_) {
          scopeWarning = 'Chưa tải được phân cấp thủ tục. Kéo xuống để thử lại.';
        }
        if (catalog != null) {
          try {
            currentSchool = await liveRepo.currentSchool(catalog);
            if (currentSchool == null) {
              scopeWarning = 'Chưa xác định được trường của tài khoản từ '
                  'ngành học đang chọn. Chỉ hiển thị thủ tục cấp ĐHQGHN.';
            }
          } catch (_) {
            scopeWarning = 'Không tra cứu được trường của tài khoản. '
                'Chỉ hiển thị thủ tục cấp ĐHQGHN; kéo xuống để thử lại.';
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _procedures = procedures;
        _records = records;
        _scopeCatalog = catalog;
        _mySchoolId = currentSchool?.id;
        _mySchoolName = currentSchool?.name;
        _scopeWarning = scopeWarning;
        if (catalog == null ||
            (_scopeFilter == 'school' && _mySchoolId == null)) {
          _scopeFilter = 'all';
        }
        // Recompute from the selected scope, not from ALL schools.
        if (!_availableDomains(_scopeFilter).contains(_domain)) {
          _domain = 'Tất cả';
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _connectionError = 'Không lấy được phiên Một cửa hoặc dữ liệu hồ sơ thật. '
          'Kiểm tra xác thực ONEVNU, kết nối API và thử lại.';
        _authResolved=false;
      });
    }
  }

  void _message(String text, {VcoreNoticeTone tone = VcoreNoticeTone.info}) {
    if (!mounted) return;
    showVcoreNotice(
      context: context,
      title: switch (tone) {
        VcoreNoticeTone.success => 'Thành công',
        VcoreNoticeTone.warning => 'Lưu ý',
        VcoreNoticeTone.error => 'Lỗi',
        VcoreNoticeTone.info => 'Thông báo',
      },
      message: text,
      tone: tone,
    );
  }

  /// Called both by AppBar and Android/iOS system back.
  /// Inner pages are state-driven and therefore MUST consume system back
  /// instead of popping this module's single Navigator route.
  void _back() {
    if (_page == _DoorPage.overview) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_page == _DoorPage.form && _formStep > 0) {
      _previousFormStep();
      return;
    }
    setState(() {
      if (_page == _DoorPage.procedure) _procedureRequestSerial++;
      if (_page == _DoorPage.form) {
        if (_submitting) return;
        _attachmentReadTimer?.cancel();
        _page = _DoorPage.procedure;
      } else if (_page == _DoorPage.supplement) {
        _page = _DoorPage.record;
      } else {
        _page = _DoorPage.overview;
      }
    });
  }

  Future<void> _openProcedure(OneDoorProcedure p) async {
    final serial = ++_procedureRequestSerial;
    final repository = _repo;
    final isLive = repository is OneDoorLiveRepository;
    setState(() {
      _selectedProcedure = p;
      _page = _DoorPage.procedure;
      _procedureLoading = isLive;
      _procedureReady = !isLive;
      _procedureError = null;
      _deliveryFromLookup = false;
      _deliveryWarning = null;
      _delivery = p.deliveryMethods.length == 1
          ? p.deliveryMethods.keys.first : '';
    });

    if (!isLive) return;
    try {
      // Exactly one procedure detail request. Lookup runs only for
      // an explicit hinhThucs: [] in the real detail response.
      final resolved = await repository.detailProcedureResolved(p.id);
      if (!mounted || serial != _procedureRequestSerial ||
          _page != _DoorPage.procedure || _selectedProcedure?.id != p.id) return;
      final detail = resolved.procedure;
      setState(() {
        _selectedProcedure = detail;
        _procedureLoading = false;
        _procedureReady = true;
        _deliveryFromLookup = resolved.deliveryFromLookup;
        _deliveryWarning = resolved.deliveryWarning;
        _delivery = detail.deliveryMethods.length == 1
            ? detail.deliveryMethods.keys.first : '';
      });
    } catch (_) {
      if (!mounted || serial != _procedureRequestSerial ||
          _page != _DoorPage.procedure || _selectedProcedure?.id != p.id) return;
      setState(() {
        _procedureLoading = false;
        _procedureReady = false;
        _procedureError = 'Không thể tải dữ liệu chi tiết hợp lệ. Vui lòng thử lại.';
      });
      _message('Không tải được chi tiết thủ tục.', tone: VcoreNoticeTone.error);
    }
  }

  void _retryProcedure() {
    final p = _selectedProcedure;
    if (p != null && !_procedureLoading) _openProcedure(p);
  }

  Future<void> _openRecord(OneDoorRecord record) async {
    setState(() {
      _selectedRecord = record;
      _page = _DoorPage.record;
      _myRecordsTab = true;
    });
    final repository=_repo;
    if (repository is OneDoorLiveRepository) {
      try {
        final detail=await repository.detailRecord(record.id,procedure:record.procedure);
        if (mounted && _selectedRecord?.id==record.id) {
          setState(() => _selectedRecord=detail);
        }
      } catch (_) {
        if (mounted) _message('Không tải được thông tin xử lý hồ sơ.', tone: VcoreNoticeTone.error);
      }
    }
  }

  void _startForm() {
    _attachmentReadTimer?.cancel();
    _attachmentSecondsRemaining = _attachmentReadDurationSeconds;
    if (!_submitting) _clearGeneratedPdfs();
    if (_procedureLoading || !_procedureReady) {
      _message('Vui lòng tải chi tiết thủ tục trước khi nộp.',
        tone: VcoreNoticeTone.warning);
      return;
    }
    if (_live && _selectedProcedure!.deliveryMethods.isEmpty) {
      _message(_deliveryWarning ?? 'Chưa có hình thức nhận kết quả hợp lệ. '
        'Vui lòng tải lại thủ tục.', tone: VcoreNoticeTone.warning);
      return;
    }
    setState(() {
      _page = _DoorPage.form;
      _formStep = 0;
      _request.clear();
      _files.clear();
      _filePaths.clear();
      _letterDrafts.clear();
      _delivery = _live
        ? (_selectedProcedure!.deliveryMethods.length == 1
            ? _selectedProcedure!.deliveryMethods.keys.first : '')
        : 'Nhận trực tiếp'; // Mock-only fallback, never used for live POST.
      _quantity = 1;
      _confirmedLargeQuantity = null;
    });
  }

  Future<bool> _confirmLargeQuantity(int count) async {
    if (!mounted) return false;
    final bool? accepted = await showVcoreActionDialog<bool>(
      context: context,
      title: 'Xác nhận số lượng bản',
      content: 'Bạn có chắc chắn muốn đăng ký cấp $count bản kết quả? '
          'Số lượng lớn có thể làm tăng lệ phí theo quy định.',
      leadingIcon: Icons.copy_all_outlined,
      actions: const <VcoreDialogAction<bool>>[
        VcoreDialogAction<bool>(label: 'Quay lại', value: false,
          tone: VcoreDialogActionTone.secondary),
        VcoreDialogAction<bool>(label: 'Xác nhận', value: true,
          tone: VcoreDialogActionTone.primary),
      ],
    );
    return mounted && accepted == true;
  }

  Future<void> _setQuantity(int next) async {
    if (_submitting || next < 1 || next == _quantity) return;
    if (next > 10 && _quantity <= 10) {
      if (!await _confirmLargeQuantity(next)) return;
      _confirmedLargeQuantity = next;
    } else if (next <= 10) {
      _confirmedLargeQuantity = null;
    }
    if (mounted) setState(() => _quantity = next);
  }

  Future<void> _editQuantity() async {
    final input = TextEditingController(text: '$_quantity');
    try {
      final int? selected = await showDialog<int>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Nhập số lượng bản'),
          content: TextField(
            controller: input,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Số bản',
              helperText: 'Tối thiểu 1 bản'),
            onSubmitted: (_) => Navigator.of(dialogContext).pop(
              int.tryParse(input.text)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Quay lại')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(
              int.tryParse(input.text)), child: const Text('Áp dụng')),
          ],
        ),
      );
      if (selected == null) return;
      if (selected < 1) {
        _message('Số lượng bản phải lớn hơn hoặc bằng 1.',
          tone: VcoreNoticeTone.warning);
        return;
      }
      await _setQuantity(selected);
    } finally {
      input.dispose();
    }
  }

  /// A paper can be uploaded as-is, or a new editable application letter can
  /// be produced in-app. Official server templates remain view-only here.
  bool _supportsLetterEditor(OneDoorPaper paper) {
    final name = paper.name.toLowerCase();
    return name.contains('đơn') || name.contains('đề nghị') ||
        name.contains('tờ khai') || name.contains('biểu mẫu') ||
        name.contains('phiếu');
  }

  Future<void> _openLetterEditor(OneDoorPaper paper) async {
    if (_submitting || _paperBusy.contains(paper.id)) return;
    final procedure = _selectedProcedure;
    if (procedure == null) return;
    setState(() => _paperBusy.add(paper.id));
    try {
      final saved = _letterDrafts[paper.id];
      OneDoorStudentPrefill prefill = const OneDoorStudentPrefill(
        values: <String, String>{}, usedLiveProfile: false,
        warnings: <String>[],
      );
      // OneVNU student data is independent of the One Door API session.
      // Also load it when a debug One Door mock is being used.
      if (Globals().token.trim().isNotEmpty) {
        try {
          prefill = await const OneDoorStudentPrefillService().load();
        } catch (_) {
          prefill = const OneDoorStudentPrefill(
            values: <String, String>{}, usedLiveProfile: false,
            warnings: <String>['OneVNU student API unavailable.'],
          );
        }
      }
      final now = DateTime.now();
      final values = <String, String>{
        ...prefill.values,
        'Ngay': '${now.day}', 'Thang': '${now.month}', 'Nam': '${now.year}',
        // A OneVNU student profile can contain its own maHoSo. Never
        // confuse that field with the One Door idDangKy returned after POST.
        'MaHoSo': prefill.values['MaHoSo'] ?? '',
        'TenThuTuc': procedure.name,
        'YeuCau': _request.text.trim(),
        'SoLuongBan': '$_quantity',
        // This is the planned submission date on the current device, not
        // the backend's eventual receivedAt value.
        'NgayNop': DateFormat('dd/MM/yyyy').format(now),
        'TenDonVi': procedure.unitName,
        // Optional Profile labels are intentionally not used as faculty.
        'KhoaHoc': prefill.values['KhoaHoc'] ?? '',
        'TruongHoc': prefill.values['TruongHoc'] ?? '',
      };
      // Do not substitute One Door's academic lookup for Profile values.
      // They may belong to a different selected enrollment/unit.
      if (!mounted || _selectedProcedure?.id != procedure.id) return;
      // Merge a previously edited draft with newly loaded OneVNU fields:
      // preserve explicit user edits; only fill blanks from the live APIs.
      final merged = <String, String>{...values};
      if (saved != null) {
        for (final entry in saved.values.entries) {
          if (entry.value.trim().isNotEmpty) merged[entry.key] = entry.value;
        }
      }
      merged['TenThuTuc'] = procedure.name;
      merged['YeuCau'] = _request.text.trim();
      merged['SoLuongBan'] = '$_quantity';
      final missingFields = OneDoorLetterDraft.requiredFields
        .where((key) => (merged[key] ?? '').trim().isEmpty).toList();
      final summary = 'Đã có ${18 - missingFields.length}/18 trường. '
        '${missingFields.isEmpty ? 'Có thể kiểm tra và xuất đơn.' :
            'Cần bổ sung: ${missingFields.map((key) => OneDoorLetterDraft.fieldLabels[key] ?? key).join(', ')}.'}';
      final draft = saved == null
        ? OneDoorLetterDraft(values: merged,
            template: OneDoorLetterDraft.defaultTemplate)
        : OneDoorLetterDraft(values: merged, template: saved.template);
      final result = await Navigator.of(context).push<OneDoorLetterResult>(
        MaterialPageRoute(builder: (_) => OneDoorLetterEditorPage(
          documentName: paper.name, initialDraft: draft,
          initialPrefillStatus: saved != null
            ? '$summary Đang giữ bản bạn đã soạn; chọn Dữ liệu → '
              'Đồng bộ tờ đơn nếu muốn tạo lại từ API.'
            : prefill.usedLiveProfile ? '$summary Dữ liệu từ Thông tin cá nhân OneVNU.'
              : (prefill.values['MaSV'] ?? '').trim().isNotEmpty
                ? '$summary Dữ liệu lưu trong phiên Thông tin cá nhân; có thể tải lại.'
                : '$summary Không có hồ sơ sinh viên; hãy kiểm tra dữ liệu.',
          onReloadFromOneVnu: Globals().token.trim().isNotEmpty
            ? () => const OneDoorStudentPrefillService().load() : null,
        )),
      );
      if (!mounted || result == null) return;
      setState(() {
        final previous = _filePaths[paper.id];
        _letterDrafts[paper.id] = result.draft;
        _files[paper.id] = result.path.split(Platform.pathSeparator).last;
        _filePaths[paper.id] = result.path;
        _generatedPdfPaths.add(result.path);
        if (previous != result.path) {
          _forgetGeneratedPdf(previous);
          _forgetGeneratedWord(previous);
        }
      });
    } finally {
      if (mounted) setState(() => _paperBusy.remove(paper.id));
    }
  }

  Future<void> _openPaperTemplate(OneDoorPaper paper,
      {bool prefilled = false, bool saveCopy = false}) async {
    if (_repo is! OneDoorLiveRepository || !paper.hasTemplate ||
        _paperBusy.contains(paper.id)) return;
    setState(() { _paperBusy.add(paper.id); });
    try {
      final repo = _repo as OneDoorLiveRepository;
      final response = prefilled
          ? await repo.downloadPrefilledPaper(paper.id)
          : await repo.downloadPaperTemplate(paper.id);
      final directory = await getTemporaryDirectory();
      final safeId = paper.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${directory.path}${Platform.pathSeparator}'
          'onevnu_${prefilled ? 'da_dien' : 'mau'}_${safeId}_${DateTime.now().microsecondsSinceEpoch}.${response.extension}');
      await file.writeAsBytes(response.bytes, flush: true);
      if (!mounted) return;
      if (saveCopy) {
        // Must not delete the temp copy immediately: the native share target
        // may still be importing it, and saving a copy is not an upload.
        await OneDoorAttachmentPreview.shareFile(context,
          path: file.path, title: paper.name);
      } else {
        // Reliable read-only preview first; full Word edits belong in Office.
        await OneDoorAttachmentPreview.open(context, path: file.path,
          title: '${prefilled ? 'Bản API đã điền' : 'Mẫu'}: ${paper.name}',
          allowDocxEditing: false);
        if (!<String>{'doc', 'xls'}.contains(response.extension)) {
          try { await file.delete(); } catch (_) {}
        }
      }
    } catch (_) {
      if (mounted) _message(prefilled
          ? 'Một cửa chưa trả được bản đã điền cho giấy tờ này. '
            'Bạn vẫn có thể tự soạn đơn trên tờ giấy hoặc đính kèm tệp.'
          : 'Không tải được file mẫu từ Một cửa. '
            'Vui lòng thử lại hoặc liên hệ đơn vị quản lý mẫu.',
          tone: VcoreNoticeTone.error);
    } finally {
      if (mounted) setState(() { _paperBusy.remove(paper.id); });
    }
  }

  Future<void> _openSelectedPaper(OneDoorPaper paper,
      {bool supplement = false}) async {
    final path = (supplement ? _supplementPaths : _filePaths)[paper.id];
    if (path == null || path.isEmpty) {
      _message('Tệp này không có đường dẫn hợp lệ. Vui lòng chọn lại.',
          tone: VcoreNoticeTone.warning);
      return;
    }
    final edited = await OneDoorAttachmentPreview.open(context, path: path,
        title: paper.name, allowDocxEditing: false);
    if (edited != null && mounted && !_submitting) {
      _rememberEditedWord(paper, edited, supplement: supplement);
      _message('Đã thay bản Word đã chỉnh sửa trong giấy tờ đính kèm.',
        tone: VcoreNoticeTone.success);
    }
  }

  Future<void> _pickFile(String paperId, {bool supplement = false}) async {
    try {
      // file_picker 11: FilePickerResult?; file_picker 12/13: List<PlatformFile>.
      // Không truyền allowMultiple vì tham số này đã bị bỏ ở bản 13.
      // Nếu trình chọn cho phép nhiều tệp, chỉ sử dụng tệp đầu tiên.
      final Object? selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>[
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png',
        ],
      );
      if (!mounted || selection == null) return;

      late final PlatformFile file;
      final int? fileSize;
      if (selection is List<PlatformFile>) {
        // Từ file_picker 12 trở đi: kết quả là danh sách PlatformFile.
        if (selection.isEmpty) return;
        file = selection.first;
        // file_picker 12 trả về int, file_picker 13 trả về int?.
        fileSize = (await (file as dynamic).length()) as int?;
      } else {
        // file_picker 11: kết quả là FilePickerResult với trường files.
        final dynamic legacySelection = selection;
        final List<PlatformFile> files =
        legacySelection.files as List<PlatformFile>;
        if (files.isEmpty) return;
        file = files.first;
        fileSize = (file as dynamic).size as int;
      }

      if (!mounted) return;
      if (fileSize == null) {
        _message('Không xác định được dung lượng tệp. Vui lòng chọn lại.', tone: VcoreNoticeTone.warning);
        return;
      }
      if (fileSize > 10 * 1024 * 1024) {
        _message('Dung lượng tệp tối đa là 10 MB.', tone: VcoreNoticeTone.warning);
        return;
      }
      final path = file.path;
      if (_live && (path == null || path.isEmpty)) {
        _message('Không thể đọc nội dung tệp đã chọn. Hãy chọn file lưu trên thiết bị.',
          tone: VcoreNoticeTone.warning);
        return;
      }
      if (!supplement) {
        _forgetGeneratedPdf(_filePaths[paperId]);
        _forgetGeneratedWord(_filePaths[paperId]);
        _editedWordWizardContext.remove(paperId);
      }
      setState(() {
        (supplement ? _supplementFiles : _files)[paperId] = file.name;
        if (path != null && path.isNotEmpty) {
          (supplement ? _supplementPaths : _filePaths)[paperId]=path;
        }
        if (!supplement) {
          _letterDrafts.remove(paperId);
          _editedWordWizardContext.remove(paperId);
        }
      });
    } catch (_) {
      if (mounted) _message('Không chọn được tệp. Vui lòng thử lại.', tone: VcoreNoticeTone.error);
    }
  }

  /// Step 2 is a deliberate hand-off: user must review each actual local file
  /// and explicitly confirm the attachment set before seeing final review.
  Future<void> _confirmAttachmentStep() async {
    if (_submitting || _paperBusy.isNotEmpty ||
        _currentStep != _DoorFormStep.attachments) return;
    if (_attachmentSecondsRemaining > 0) {
      _message('Vui lòng đọc lưu ý tại bước 2 trong '
        '${_attachmentSecondsRemaining} giây trước khi tiếp tục.',
        tone: VcoreNoticeTone.warning);
      return;
    }
    final procedure = _selectedProcedure;
    if (procedure == null) return;
    final missing = procedure.papers.where(
      (paper) => paper.isRequired && !_files.containsKey(paper.id));
    if (missing.isNotEmpty) {
      _message('Vui lòng đính kèm đủ giấy tờ bắt buộc.',
        tone: VcoreNoticeTone.warning);
      return;
    }
    final staleWord = _editedWordWizardContext.entries.any((entry) =>
      _filePaths.containsKey(entry.key) &&
      entry.value != '${_quantity}::${_request.text.trim()}');
    final staleLetter = _letterDrafts.entries.any((entry) =>
      _filePaths.containsKey(entry.key) &&
      (entry.value.values['SoLuongBan'] != '$_quantity' ||
       entry.value.values['YeuCau'] != _request.text.trim() ||
       entry.value.values['NgayNop'] !=
         DateFormat('dd/MM/yyyy').format(DateTime.now())));
    if (staleWord || staleLetter) {
      _message('Bạn đã thay đổi yêu cầu, số lượng bản hoặc ngày làm đơn. '
        'Hãy mở lại tài liệu và lưu bản mới trước khi tiếp tục.',
        tone: VcoreNoticeTone.warning);
      return;
    }
    final List<OneDoorReviewFile> reviewFiles = <OneDoorReviewFile>[];
    for (final paper in procedure.papers) {
      if (!_files.containsKey(paper.id)) continue;
      final path = _filePaths[paper.id];
      if (path == null || path.isEmpty) {
        _message('Tệp ${paper.name} chưa có đường dẫn hợp lệ. '
          'Vui lòng chọn lại tệp.', tone: VcoreNoticeTone.warning);
        return;
      }
      try {
        final file = File(path);
        if (!await file.exists()) throw StateError('missing');
        final bytes = await file.length();
        if (bytes < 1 || bytes > 10 * 1024 * 1024) {
          throw StateError('invalid size');
        }
        reviewFiles.add(OneDoorReviewFile(
          id: paper.id, paperName: paper.name,
          fileName: _files[paper.id]!, path: path,
          bytes: bytes, isRequired: paper.isRequired));
      } catch (_) {
        if (mounted) _message('Không đọc được tệp ${paper.name} hoặc '
          'tệp rỗng/quá 10 MB. Hãy chọn lại tệp từ thiết bị.',
          tone: VcoreNoticeTone.warning);
        return;
      }
    }
    if (!mounted) return;
    final snapshotFiles = Map<String, String>.of(_files);
    final snapshotPaths = Map<String, String>.of(_filePaths);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.89,
        child: OneDoorAttachmentReviewSheet(
          files: reviewFiles,
          onPreview: (entry) async {
            await OneDoorAttachmentPreview.open(context,
              path: entry.path, title: entry.paperName,
              allowDocxEditing: false);
          },
          onOpenOffice: (entry) =>
            OneDoorAttachmentPreview.openInOffice(context, entry.path),
          onShare: (entry) => OneDoorAttachmentPreview.shareFile(context,
            path: entry.path, title: entry.paperName),
        ),
      ),
    );
    if (!mounted || confirmed != true || _submitting) return;
    if (_currentStep != _DoorFormStep.attachments ||
        !mapEquals(snapshotFiles, _files) ||
        !mapEquals(snapshotPaths, _filePaths)) {
      _message('Danh sách tài liệu đã thay đổi. Hãy kiểm tra lại.',
        tone: VcoreNoticeTone.warning);
      return;
    }
    _advanceFormStep();
  }

  Future<void> _submit() async {
    if (_submitting || _selectedProcedure == null) return;
    final p = _selectedProcedure!;
    if (_request.text.trim().isEmpty) { _message('Vui lòng nhập nội dung yêu cầu.', tone: VcoreNoticeTone.warning); return; }
    if (_request.text.trim().length > 500) { _message('Nội dung yêu cầu tối đa 500 ký tự.', tone: VcoreNoticeTone.warning); return; }
    final missing = p.papers.where((f) => f.isRequired && !_files.containsKey(f.id));
    if (missing.isNotEmpty) { _message('Vui lòng đính kèm đủ giấy tờ bắt buộc.', tone: VcoreNoticeTone.warning); return; }
    if (_live && p.deliveryMethods[_delivery] == null) {
      _message('Vui lòng chọn hình thức nhận kết quả hợp lệ.', tone: VcoreNoticeTone.warning); return;
    }
    if (_quantity > 10 && _confirmedLargeQuantity != _quantity) {
      if (!await _confirmLargeQuantity(_quantity)) return;
      _confirmedLargeQuantity = _quantity;
    }
    if (_live && _files.keys.any((id) => !_filePaths.containsKey(id))) {
      _message('Không có đường dẫn tệp đính kèm. Vui lòng chọn lại.', tone: VcoreNoticeTone.warning);return;
    }
    // Do not upload a letter with stale quantities or request details if the
    // student changed step one AFTER generating the PDF in step two.
    final staleWord = _editedWordWizardContext.entries.any((entry) =>
      _filePaths.containsKey(entry.key) &&
      entry.value != '${_quantity}::${_request.text.trim()}');
    if (staleWord) {
      _message('Yêu cầu hoặc số lượng đã thay đổi sau khi sửa file Word. '
        'Hãy mở lại Word và lưu bản cập nhật trước khi nộp.',
        tone: VcoreNoticeTone.warning);
      return;
    }
    final staleLetter = _letterDrafts.entries.any((entry) =>
      _filePaths.containsKey(entry.key) &&
      (entry.value.values['SoLuongBan'] != '$_quantity' ||
       entry.value.values['YeuCau'] != _request.text.trim() ||
       entry.value.values['NgayNop'] !=
           DateFormat('dd/MM/yyyy').format(DateTime.now())));
    if (staleLetter) {
      _message('Nội dung đề nghị hoặc số lượng bản đã thay đổi sau khi soạn đơn. '
          'Vui lòng quay lại bước tài liệu, chọn Sửa đơn và tạo PDF mới.',
        tone: VcoreNoticeTone.warning);
      return;
    }
    setState(() => _submitting = true);
    try {
      final record = await _repo.submit(
        procedure: p, requestText: _request.text.trim(), deliveryMethod: _delivery,
        quantity: _quantity, papers: _live ? _filePaths : _files,
      );
      List<OneDoorRecord> list;
      try {
        list = await _repo.myRecords();
      } catch (_) {
        // A refresh failure must not turn an accepted POST into a failed POST.
        list = <OneDoorRecord>[record, ..._records];
      }
      if (!mounted) return;
      _clearGeneratedPdfs(); // Server POST has completed.
      setState(() {
        _submitting = false;
        _records = list;
        _selectedRecord = record;
        _myRecordsTab = true;
        _page = _DoorPage.record;
      });
      _message(_live ? 'Hồ sơ đã được hệ thống tiếp nhận.' : 'Yêu cầu đã được lưu.', tone: VcoreNoticeTone.success);
    } on OneDoorSubmittedButDetailUnavailable catch (accepted) {
      if (!mounted) return;
      _clearGeneratedPdfs(); // Accepted by server, avoid a duplicate POST.
      setState(() { _submitting=false; _page=_DoorPage.overview;
        _myRecordsTab=true; });
      _message('Hồ sơ đã được tiếp nhận: ${accepted.registrationId}. '
        'Vui lòng tải lại danh sách hồ sơ; không nộp lại để tránh trùng.', tone: VcoreNoticeTone.success);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
      _message(_live ? 'Không thể nộp hồ sơ. Vui lòng kiểm tra thông tin và thử lại.' : 'Không thể lưu hồ sơ.', tone: VcoreNoticeTone.error);
    }
  }

  Future<void> _cancelRecord() async {
    final record = _selectedRecord;
    if (record == null) return;
    final bool? confirmed = await showVcoreActionDialog<bool>(
      context: context,
      title: 'Hủy hồ sơ?',
      content: 'Bạn có chắc chắn muốn hủy hồ sơ này?',
      leadingIcon: Icons.delete_outline_rounded,
      actions: const <VcoreDialogAction<bool>>[
        VcoreDialogAction<bool>(
          label: 'Quay lại', value: false,
          tone: VcoreDialogActionTone.secondary,
        ),
        VcoreDialogAction<bool>(
          label: 'Hủy hồ sơ', value: true,
          icon: Icons.delete_outline_rounded,
          tone: VcoreDialogActionTone.danger,
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repo.cancel(record);
      if (mounted) {
        setState(() {});
        _message('Đã hủy hồ sơ.', tone: VcoreNoticeTone.success);
      }
    } catch (_) {
      if (mounted) _message('Không thể hủy hồ sơ. Vui lòng thử lại.', tone: VcoreNoticeTone.error);
    }
  }

  Future<void> _sendSupplement() async {
    final record = _selectedRecord;
    if (record == null) return;
    if (_supplementNote.text.trim().isEmpty && _supplementFiles.isEmpty) {
      _message('Vui lòng nhập ghi chú hoặc chọn tệp bổ sung.', tone: VcoreNoticeTone.warning);
      return;
    }
    if (_live && _supplementFiles.keys.any((id)=>!_supplementPaths.containsKey(id))) {
      _message('Vui lòng chọn lại tệp bổ sung.', tone: VcoreNoticeTone.warning); return;
    }
    try {
      await _repo.supplement(record,_supplementNote.text.trim(),
        _live ? _supplementPaths : _supplementFiles);
      if (!mounted) return;
      setState(() { _page=_DoorPage.record; _supplementFiles.clear();
        _supplementPaths.clear(); _supplementNote.clear(); });
      _message(_live ? 'Đã gửi bổ sung hồ sơ.' : 'Đã lưu nội dung bổ sung.', tone: VcoreNoticeTone.success);
    } catch (_) {
      if (mounted) _message('Không thể bổ sung hồ sơ. Vui lòng thử lại.', tone: VcoreNoticeTone.error);
    }
  }

  String _money(int amount) => amount == 0 ? 'Miễn phí' : '${NumberFormat.decimalPattern('vi_VN').format(amount)} đ';
  // Same typographic hierarchy as the PAHT community card.
  static const TextStyle _doorListTitleStyle = TextStyle(
    color: Color(0xFF17201B),
    fontSize: 14.3,
    height: 1.25,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle _doorListMetaStyle = TextStyle(
    color: Color(0xFF536159),
    fontSize: 12.0,
    height: 1.4,
  );
  static const TextStyle _doorWorkDaysStyle = TextStyle(
    color: Color(0xFF264235),
    fontWeight: FontWeight.w800,
  );
  // Exactly the CSS metallic-gold stops supplied by the designer.
  // Vertical-only shader: width has no visual effect. The text retains
  // OpenSans from the application's theme (no new external font dependency).
  static final TextStyle _doorFeeStyle = TextStyle(
    fontWeight: FontWeight.w800,
    foreground: Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color(0xFFDAA520), // 0%  rgba(218,165,32,1)
        Color(0xFFD5AD6D), // 26% rgba(213,173,109,1)
        Color(0xFFE2BA78), // 35% rgba(226,186,120,1)
        Color(0xFFA37E43), // 45% rgba(163,126,67,1)
        Color(0xFFD4AF37), // 61% rgba(212,175,55,1)
        Color(0xFFD5AD6D), // 100% rgba(213,173,109,1)
      ],
      stops: <double>[0.0, 0.26, 0.35, 0.45, 0.61, 1.0],
    ).createShader(const Rect.fromLTWH(0, 0, 1, 19)),
    shadows: const <Shadow>[
      Shadow(color: Color(0x80D4AF37), blurRadius: 20),
    ],
  );

  Widget _highlightInfoLine({
    required String label,
    required String value,
    required bool fee,
    bool borders = true,
  }) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      border: borders
        ? const Border(bottom: BorderSide(color: StudentServiceUI.line))
        : null,
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 4, child: Text(label,
        style: const TextStyle(color: Color(0xFF536159),
          fontSize: 13.5, height: 1.4))),
      const SizedBox(width: 12),
      Expanded(flex: 6, child: Text(value, textAlign: TextAlign.end,
        style: (fee ? _doorFeeStyle : _doorWorkDaysStyle)
          .copyWith(fontSize: 13.5, height: 1.4))),
    ]),
  );

  String _date(DateTime d) => DateFormat('dd/MM/yyyy HH:mm').format(d);

  Color _recordStatusColor(OneDoorRecordStatus status) => switch (status) {
    OneDoorRecordStatus.processing => const Color(0xFF2269AA),
    OneDoorRecordStatus.supplement => StudentServiceUI.caution,
    OneDoorRecordStatus.completed => StudentServiceUI.green,
    OneDoorRecordStatus.rejected => StudentServiceUI.danger,
    OneDoorRecordStatus.cancelled => StudentServiceUI.secondary,
  };

  @override
  Widget build(BuildContext context) {
    final pageTitle = switch (_page) {
      _DoorPage.overview => 'Thủ tục hành chính',
      _DoorPage.procedure => 'Chi tiết thủ tục',
      _DoorPage.form => 'Nộp hồ sơ',
      _DoorPage.record => 'Chi tiết hồ sơ',
      _DoorPage.supplement => 'Bổ sung hồ sơ',
    };
    return StudentServiceUI.withoutTapHighlight(context, PopScope<Object?>(
      canPop: _page == _DoorPage.overview,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && mounted) _back();
      },
      child: Scaffold(
        backgroundColor: StudentServiceUI.background,
        appBar: StudentServiceUI.appBar(title: pageTitle, onBack: _back,
          actions: _page == _DoorPage.overview ? <Widget>[
            VnuPressMotion(child: IconButton(
              onPressed: _load, tooltip: 'Tải lại',
              icon: const Icon(Icons.refresh, color: Colors.black, size: 23),
            )),
            const SizedBox(width: 8),
          ] : const <Widget>[]),
        body: _loading
          ? Center(child: VnuLoading.inline(size: 28))
          : _connectionError != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_connectionError!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(onPressed:_load,child:const Text('Thử lại')),
              ])))
          : StudentViewSwitch(
              pageKey: '${_page.name}:${_page == _DoorPage.form ? _formStep : 0}',
              child: switch (_page) {
                _DoorPage.overview => _overview(),
                _DoorPage.procedure => _procedureDetail(),
                _DoorPage.form => _applicationForm(),
                _DoorPage.record => _recordDetail(),
                _DoorPage.supplement => _supplementPage(),
              },
            ),
      ),
    ));
  }

  // The My Records status filter remains completely independent.
  Future<void> _openFilterSheet(List<String> choices) async {
    final chosen = _statusFilter;
    final selected = await VnuSelectSheet.show<String>(
      context: context,
      title: 'Lọc trạng thái hồ sơ',
      bodyBuilder: (sheetContext) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 22),
        children: choices.map((value) => VnuSelectOptionTile(
          title: value,
          selected: chosen == value,
          onTap: () => Navigator.pop(sheetContext, value),
        )).toList(),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() => _statusFilter = selected);
  }

  bool _matchesScope(OneDoorProcedure p, String scope) {
    final catalog = _scopeCatalog;
    // Demo has no unit metadata. In live mode fail closed, never expose
    // another school's procedures when catalog retrieval failed.
    if (catalog == null) return !_live && scope == 'all';
    final group = catalog.groupOf(p);
    final belongsToMySchool = _mySchoolId != null &&
        group == OneDoorProcedureGroup.school && p.unitId == _mySchoolId;
    final belongsToUniversity = group == OneDoorProcedureGroup.university;
    if (scope == 'school') return belongsToMySchool;
    if (scope == 'university') return belongsToUniversity;
    return belongsToMySchool || belongsToUniversity;
  }

  /// The LĨNH VỰC choices are dynamically restricted to the selected scope.
  /// Selecting the school shows only that school's actual tenLinhVuc values;
  /// selecting ĐHQGHN shows only ĐHQGHN's values. No hardcoded subjects.
  List<String> _availableDomains(String scope) {
    final domains = <String>{};
    for (final p in _procedures) {
      if (_matchesScope(p, scope) && p.domain.trim().isNotEmpty) {
        domains.add(p.domain.trim());
      }
    }
    final ordered = domains.toList()..sort((a, b) =>
        a.toLowerCase().compareTo(b.toLowerCase()));
    return <String>['Tất cả', ...ordered];
  }

  int _domainCount(String scope, String domain) => _procedures.where((p) =>
    _matchesScope(p, scope) &&
    (domain == 'Tất cả' || p.domain.trim() == domain)).length;

  /// Two layers only: (1) All / My school / ĐHQGHN, (2) real domains within
  /// the selected scope. There is NO picker for another university/school.
  Future<void> _openProcedureFilters() async {
    final catalog = _scopeCatalog;
    var draftScope = catalog == null ? 'all' : _scopeFilter;
    var draftDomain = _domain;
    await VnuSelectSheet.show<bool>(
      context: context,
      title: 'Bộ lọc thủ tục',
      subtitle: 'Phạm vi thủ tục → Lĩnh vực tương ứng',
      bodyBuilder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) {
          final domains = _availableDomains(draftScope);
          void changeScope(String scope) => updateSheet(() {
            draftScope = scope;
            if (!domains.contains(draftDomain) ||
                !_availableDomains(scope).contains(draftDomain)) {
              draftDomain = 'Tất cả';
            }
          });
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
            children: [
              const Text('PHẠM VI THỦ TỤC', style: TextStyle(
                color: StudentServiceUI.secondary, fontSize: 11.5,
                fontWeight: FontWeight.w800, letterSpacing: .6)),
              const SizedBox(height: 7),
              VnuSelectOptionTile(
                title: 'Tất cả',
                subtitle: 'Trường của tôi trước, ĐHQGHN sau',
                selected: draftScope == 'all',
                onTap: () => changeScope('all')),
              VnuSelectOptionTile(
                title: 'Trường của tôi',
                subtitle: _mySchoolName ?? 'Chưa xác định được trường',
                enabled: catalog != null && _mySchoolId != null,
                selected: draftScope == 'school',
                onTap: () => changeScope('school')),
              VnuSelectOptionTile(
                title: 'Cấp Đại học Quốc gia Hà Nội',
                enabled: catalog != null,
                selected: draftScope == 'university',
                onTap: () => changeScope('university')),
              if (catalog == null || _mySchoolId == null) ...[
                const SizedBox(height: 8),
                Text(catalog == null
                    ? 'Chưa tải được phân cấp đơn vị từ API. '
                        'Kéo xuống để thử lại.'
                    : 'Không xác định được trường từ ngành đang chọn. '
                        'Không hiển thị thủ tục của trường khác.',
                  style: const TextStyle(fontSize: 12,
                    color: StudentServiceUI.secondary)),
              ],
              const Divider(height: 26, color: StudentServiceUI.line),
              const Text('LĨNH VỰC TRONG PHẠM VI ĐÃ CHỌN', style: TextStyle(
                color: StudentServiceUI.secondary, fontSize: 11.5,
                fontWeight: FontWeight.w800, letterSpacing: .6)),
              const SizedBox(height: 7),
              ...domains.map((name) => VnuSelectOptionTile(
                title: name == 'Tất cả' ? 'Tất cả lĩnh vực' : name,
                subtitle: '${_domainCount(draftScope, name)} thủ tục',
                selected: draftDomain == name,
                onTap: () => updateSheet(() => draftDomain = name),
              )),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => updateSheet(() {
                    draftScope = 'all';
                    draftDomain = 'Tất cả';
                  }),
                  child: const Text('Đặt lại'),
                )),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(
                  onPressed: () {
                    setState(() {
                      _scopeFilter = draftScope;
                      _domain = _availableDomains(draftScope).contains(draftDomain)
                          ? draftDomain : 'Tất cả';
                    });
                    Navigator.of(sheetContext).pop(true);
                  },
                  child: const Text('Áp dụng'),
                )),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback clear) => InputChip(
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: const EdgeInsets.symmetric(horizontal: 5),
    backgroundColor: const Color(0xFFEAF5EF),
    side: BorderSide(color: StudentServiceUI.green.withOpacity(.22)),
    shape: const StadiumBorder(),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 11.5, color: StudentServiceUI.green,
        fontWeight: FontWeight.w700)),
    onPressed: _openProcedureFilters,
    onDeleted: clear,
  );

  List<_OneDoorListEntry> _procedureEntries(List<OneDoorProcedure> procedures) {
    final entries = <_OneDoorListEntry>[];
    if (procedures.isEmpty) return entries;
    final catalog = _scopeCatalog;
    if (catalog == null) {
      entries.add(_OneDoorListEntry.section('Danh sách thủ tục',
        procedures.length, null));
      for (final p in procedures) {
        entries.add(_OneDoorListEntry.item(p));
      }
      return entries;
    }
    final schools = <OneDoorProcedure>[];
    final university = <OneDoorProcedure>[];
    for (final p in procedures) {
      switch (catalog.groupOf(p)) {
        case OneDoorProcedureGroup.school:
          schools.add(p);
          break;
        case OneDoorProcedureGroup.university:
          university.add(p);
          break;
        case OneDoorProcedureGroup.unclassified:
          break;
      }
    }
    schools.sort((a, b) {
      final left = (a.unitName.isNotEmpty ? a.unitName :
        catalog.nameOfUnit(a.unitId) ?? '').toLowerCase();
      final right = (b.unitName.isNotEmpty ? b.unitName :
        catalog.nameOfUnit(b.unitId) ?? '').toLowerCase();
      final unitOrder = left.compareTo(right);
      return unitOrder == 0 ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
        : unitOrder;
    });
    university.sort((a, b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    void append(String title, OneDoorProcedureGroup group,
        List<OneDoorProcedure> items, bool collapsed) {
      if (items.isEmpty) return;
      entries.add(_OneDoorListEntry.section(title, items.length, group));
      if (!collapsed) {
        for (final p in items) {
          entries.add(_OneDoorListEntry.item(p));
        }
      }
    }
    // School rows always precede central university rows in All mode.
    append(_mySchoolName == null ? 'Thủ tục của trường tôi'
        : 'Thủ tục của ${_mySchoolName!}',
      OneDoorProcedureGroup.school, schools, _schoolCollapsed);
    append('Thủ tục cấp ĐHQGHN',
      OneDoorProcedureGroup.university, university, _universityCollapsed);
    return entries;
  }

  bool _isCollapsed(OneDoorProcedureGroup? group) => switch (group) {
    OneDoorProcedureGroup.school => _schoolCollapsed,
    OneDoorProcedureGroup.university => _universityCollapsed,
    OneDoorProcedureGroup.unclassified => _unclassifiedCollapsed,
    null => false,
  };

  Widget _sectionHeader(_OneDoorListEntry entry) {
    final group = entry.group;
    final collapsed = _isCollapsed(group);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: VnuPressMotion(
        onTap: group == null ? null : () => setState(() {
          switch (group) {
            case OneDoorProcedureGroup.school:
              _schoolCollapsed = !collapsed;
              break;
            case OneDoorProcedureGroup.university:
              _universityCollapsed = !collapsed;
              break;
            case OneDoorProcedureGroup.unclassified:
              _unclassifiedCollapsed = !collapsed;
              break;
            case null:
              break;
          }
        }),
        child: Row(children: [
          Icon(switch (group) {
            OneDoorProcedureGroup.school => Icons.school_outlined,
            OneDoorProcedureGroup.university => Icons.account_balance_outlined,
            _ => Icons.folder_open_outlined,
          }, size: 20, color: StudentServiceUI.green),
          const SizedBox(width: 8),
          Expanded(child: Text(entry.title,
            softWrap: true,
            style: const TextStyle(fontWeight: FontWeight.w800,
              fontSize: 14.5, color: StudentServiceUI.ink))),
          Text('${entry.count}',
            style: const TextStyle(fontSize: 12.5,
              color: StudentServiceUI.secondary)),
          if (group != null) ...[
            const SizedBox(width: 6),
            AnimatedRotation(
              turns: collapsed ? .5 : 0,
              duration: MediaQuery.maybeOf(context)?.disableAnimations == true
                ? Duration.zero : const Duration(milliseconds: 170),
              child: const Icon(Icons.expand_less_rounded,
                size: 20, color: StudentServiceUI.secondary),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _overview() {
    final q = _search.text.trim().toLowerCase();
    final filteredProcedures = _procedures.where((p) {
      if (!_matchesScope(p, _scopeFilter)) return false;
      if (_domain != 'Tất cả' && p.domain.trim() != _domain) return false;
      return p.name.toLowerCase().contains(q) ||
          p.domain.toLowerCase().contains(q) ||
          p.unitName.toLowerCase().contains(q) ||
          (_scopeCatalog?.nameOfUnit(p.unitId) ?? '').toLowerCase().contains(q) ||
          p.audience.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
    final rows = _procedureEntries(filteredProcedures);
    final records = _records.where((r) =>
      (_statusFilter == 'Tất cả' || r.status.label == _statusFilter) &&
      (r.procedure.name.toLowerCase().contains(q) ||
        r.id.toLowerCase().contains(q))).toList();
    const recordFilters = <String>[
      'Tất cả', 'Đang xử lý', 'Cần bổ sung',
      'Đã hoàn thành', 'Từ chối', 'Đã hủy',
    ];
    final tags = <Widget>[];
    if (_myRecordsTab) {
      if (_statusFilter != 'Tất cả') {
        tags.add(_filterChip(_statusFilter,
          () => setState(() => _statusFilter = 'Tất cả')));
      }
    } else {
      if (_scopeFilter != 'all') {
        final label = _scopeFilter == 'university' ? 'ĐHQGHN' :
            'Trường của tôi';
        tags.add(_filterChip(label, () => setState(() {
          _scopeFilter = 'all';
          if (!_availableDomains('all').contains(_domain)) {
            _domain = 'Tất cả';
          }
        })));
      }
      if (_domain != 'Tất cả') {
        tags.add(_filterChip(_domain,
          () => setState(() => _domain = 'Tất cả')));
      }
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: StudentSegment(
          labels: const <String>['Danh sách thủ tục', 'Hồ sơ của tôi'],
          selected: _myRecordsTab ? 'Hồ sơ của tôi' : 'Danh sách thủ tục',
          onSelected: (value) => setState(() {
            _myRecordsTab = value == 'Hồ sơ của tôi';
            _search.clear();
          }),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 14.5,
            color: StudentServiceUI.ink),
          decoration: StudentServiceUI.field(
            _myRecordsTab ? 'Tìm theo tên thủ tục' :
              'Bạn cần thực hiện thủ tục gì?',
            prefix: const Icon(Icons.search, size: 20,
              color: StudentServiceUI.secondary)),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 3, 20, 10),
        child: Row(children: [
          Expanded(child: Text(_myRecordsTab
              ? '${records.length} hồ sơ' :
              '${filteredProcedures.length} thủ tục',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: StudentServiceUI.secondary,
              fontSize: 13, fontWeight: FontWeight.w500))),
          VnuPressMotion(pressedScale: .93, child: IconButton(
            tooltip: 'Lọc danh sách',
            icon: Icon(Icons.filter_alt_outlined,
              size: 23,
              color: tags.isEmpty ? StudentServiceUI.ink :
                StudentServiceUI.green),
            onPressed: _myRecordsTab
              ? () => _openFilterSheet(recordFilters)
              : _openProcedureFilters,
          )),
        ]),
      ),
      AnimatedSize(
        duration: MediaQuery.maybeOf(context)?.disableAnimations == true
          ? Duration.zero : const Duration(milliseconds: 210),
        child: tags.isEmpty ? const SizedBox.shrink() :
          SizedBox(height: 44, child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 16, bottom: 4),
            children: [for (final tag in tags) Padding(
              padding: const EdgeInsets.only(right: 7), child: tag)],
          )),
      ),
      const Divider(height: 1, color: StudentServiceUI.line),
      if (!_myRecordsTab && _scopeWarning != null)
        Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
              size: 17, color: StudentServiceUI.secondary),
            const SizedBox(width: 7),
            Expanded(child: Text(_scopeWarning!,
              style: const TextStyle(fontSize: 12,
                color: StudentServiceUI.secondary))),
          ])),
      Expanded(child: StudentViewSwitch(
        pageKey: '${_myRecordsTab ? 'records' : 'procedures'}:'
          '$_scopeFilter:${_mySchoolId ?? -1}:$_domain:$_statusFilter',
        child: RefreshIndicator(
          color: StudentServiceUI.green,
          onRefresh: _load,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 30),
            itemCount: _myRecordsTab
              ? (records.isEmpty ? 1 : records.length)
              : (rows.isEmpty ? 1 : rows.length),
            itemBuilder: (_, index) {
              if (_myRecordsTab) {
                if (records.isEmpty) {
                  return _emptyList('Không có hồ sơ phù hợp.');
                }
                return _recordRow(records[index]);
              }
              if (rows.isEmpty) {
                return _emptyList('Không tìm thấy thủ tục phù hợp.');
              }
              final item = rows[index];
              if (item.procedure == null) return _sectionHeader(item);
              return _procedureRow(item.procedure!);
            },
          ),
        ),
      )),
    ]);
  }

  Widget _emptyList(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 44),
    child: Center(child: Text(message,
      style: const TextStyle(fontSize: 13.5,
        color: StudentServiceUI.secondary))),
  );

  // Full multi-line title, followed by unit, domain/audience and true fee.
  Widget _procedureRow(OneDoorProcedure p) {
    final unitName = p.unitName.trim().isNotEmpty ? p.unitName.trim() :
      (_scopeCatalog?.nameOfUnit(p.unitId) ?? 'Đơn vị chưa cập nhật');
    final meta = <String>[
      if (p.domain.trim().isNotEmpty) p.domain.trim(),
      if (p.audience.trim().isNotEmpty && p.audience != p.domain)
        p.audience.trim(),
    ];
    return _listRow(
      title: p.name,
      subtitle: '',
      subtitleContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(unitName,
            softWrap: true,
            style: _doorListMetaStyle.copyWith(fontWeight: FontWeight.w600)),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(meta.join(' · '), softWrap: true,
              style: _doorListMetaStyle),
          ],
          if (p.description.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(p.description.trim(), softWrap: true,
              style: _doorListMetaStyle),
          ],
          const SizedBox(height: 5),
          Text.rich(TextSpan(style: _doorListMetaStyle, children: <InlineSpan>[
            TextSpan(text: p.hasProcessingDays
                ? '${p.processingDays} ngày làm việc' : 'Chưa rõ thời gian',
              style: _doorWorkDaysStyle),
            const TextSpan(text: '  ·  '),
            TextSpan(text: p.hasFee ? _money(p.fee) : 'Chưa công bố lệ phí',
              style: p.hasFee ? _doorFeeStyle : _doorListMetaStyle),
          ]), softWrap: true),
        ],
      ),
      onTap: () => _openProcedure(p),
      showFullText: true,
    );
  }

  Widget _recordRow(OneDoorRecord record) => _listRow(
    iconName: 'procedure_folder',
    title: record.procedure.name,
    subtitle: 'Ngày nộp: ${DateFormat('dd/MM/yyyy').format(record.createdAt)}',
    end: StudentStatus(record.status.label, color: _recordStatusColor(record.status)),
    onTap: () => _openRecord(record),
  );

  Widget _listRow({required String title, required String subtitle,
      String? iconName, required VoidCallback onTap,
      String? endText, Widget? end, Widget? subtitleContent,
      bool showFullText = false}) => VnuPressMotion(
    onTap: onTap,
    child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(border: Border(
          bottom: BorderSide(color: StudentServiceUI.line))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          if (iconName != null) ...[
            ModuleDetailIcon(name: iconName, size: 38),
            const SizedBox(width: 14),
          ],
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                softWrap: true,
                maxLines: showFullText ? null : 2,
                overflow: showFullText ? TextOverflow.visible : TextOverflow.ellipsis,
                style: _doorListTitleStyle),
              const SizedBox(height: 6),
              subtitleContent ?? Text(subtitle,
                softWrap: true,
                maxLines: showFullText ? null : 2,
                overflow: showFullText ? TextOverflow.visible : TextOverflow.ellipsis,
                style: _doorListMetaStyle),
              if (end != null) ...[const SizedBox(height: 7), end],
            ])),
          if (endText != null) ...[
            const SizedBox(width: 10),
            Text(endText, style: const TextStyle(color: StudentServiceUI.secondary,
              fontSize: 12, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
            size: 19, color: StudentServiceUI.secondary),
        ]),
      ),
  );

  Widget _detailHeading(String title, String subtitle, {String? iconName}) =>
    Padding(padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (iconName != null) ...[
          Padding(padding: const EdgeInsets.only(top: 2),
            child: ModuleDetailIcon(name: iconName, size: 42)),
          const SizedBox(width: 14),
        ],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: StudentServiceUI.ink,
              fontSize: 19, height: 1.3, fontWeight: FontWeight.w700,
              letterSpacing: -0.35)),
            const SizedBox(height: 7),
            Text(subtitle, style: const TextStyle(
              color: StudentServiceUI.secondary, fontSize: 13, height: 1.4)),
          ])),
      ]),
    );

  Widget _documentRow(OneDoorPaper paper) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(border: Border(bottom:
      BorderSide(color: StudentServiceUI.line))),
    child: Row(children: [
      const ModuleDetailIcon(name: 'procedure_document', size: 27),
      const SizedBox(width: 12),
      Expanded(child: Text(paper.name,
        style: const TextStyle(fontSize: 13.5, color: StudentServiceUI.ink,
          height: 1.35, fontWeight: FontWeight.w500))),
      const SizedBox(width: 7),
      Text(paper.isRequired ? 'Bắt buộc' : 'Tùy chọn',
        style: TextStyle(fontSize: 11.5,
          color: paper.isRequired ? StudentServiceUI.caution : StudentServiceUI.faint)),
    ]),
  );

  Widget _timelineItem(int index, String title, String subtitle, {bool last = false}) =>
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 35, child: Column(children: [
        Text(index.toString().padLeft(2, '0'),
          style: const TextStyle(color: StudentServiceUI.green, fontSize: 12.5,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        if (!last) Container(width: 1, height: 43,
          color: StudentServiceUI.line),
      ])),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, color: StudentServiceUI.ink,
            fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(fontSize: 12.5,
            height: 1.45, color: StudentServiceUI.secondary)),
        ]),
      )),
    ]);

  Widget _procedureDetail() {
    if (_procedureLoading) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min,
        children: [
          VnuLoading.inline(size: 26),
          const SizedBox(height: 14),
          const Text('Đang tải chi tiết thủ tục...'),
        ],
      ));
    }
    if (!_procedureReady) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.info_outline, size: 34,
            color: StudentServiceUI.caution),
          const SizedBox(height: 12),
          Text(_procedureError ?? 'Chưa có dữ liệu chi tiết thủ tục.',
            textAlign: TextAlign.center),
          const SizedBox(height: 12),
          VnuPressMotion(pressedScale: 0.965,
            child: FilledButton.icon(onPressed: _retryProcedure,
              icon: const Icon(Icons.refresh), label: const Text('Tải lại chi tiết'))),
        ]),
      ));
    }
    final p = _selectedProcedure!;
    final deliveryNames = p.deliveryMethods.keys.toList();
    final deliverySummary = deliveryNames.isEmpty
      ? 'Chưa có hình thức nhận hợp lệ'
      : deliveryNames.length == 1
        ? deliveryNames.first
        : '${deliveryNames.length} hình thức nhận';
    return Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        children: [
          _detailHeading(p.name, p.domain, iconName: 'procedure_certificate'),
          const Divider(height: 22, color: StudentServiceUI.line),
          _highlightInfoLine(label: 'Thời gian xử lý', value: '${p.processingDays} ngày làm việc', fee: false),
          _highlightInfoLine(label: 'Lệ phí',
            value: p.hasFee ? _money(p.fee) : 'Chưa công bố lệ phí', fee: p.hasFee),
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hình thức nhận',
                  style: TextStyle(fontSize: 13.5,
                    color: StudentServiceUI.secondary)),
                const SizedBox(height: 5),
                Text(_live ? deliverySummary : 'Theo hướng dẫn của đơn vị',
                  style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: StudentServiceUI.ink)),
              ],
            ),
          ),
          if (_live && _deliveryFromLookup && deliveryNames.isNotEmpty)
            const Padding(padding: EdgeInsets.only(top: 5),
              child: Text('Hình thức nhận lấy từ danh mục chung của hệ thống.',
                style: TextStyle(fontSize: 12,
                  color: StudentServiceUI.secondary))),
          if (_live && deliveryNames.isEmpty)
            Padding(padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Row(children: [
                Expanded(child: Text(
                  _deliveryWarning ?? 'Chưa có hình thức nhận kết quả hợp lệ. '
                  'Hãy thử tải lại hoặc kiểm tra danh mục từ hệ thống.',
                  style: const TextStyle(fontSize: 12.5,
                    color: StudentServiceUI.caution))),
                VnuPressMotion(pressedScale: 0.965,
                  child: TextButton(onPressed: _retryProcedure,
                    child: const Text('Tải lại'))),
              ])),
          if (p.description.trim().isNotEmpty) ...[
            const StudentSection('Giới thiệu'),
            Text(p.description, style: const TextStyle(color: StudentServiceUI.secondary,
              fontSize: 14, height: 1.55)),
          ],
          StudentSection('Thành phần hồ sơ', trailing: Text(
            p.papers.isEmpty ? 'Không yêu cầu' : '${p.papers.length} giấy tờ',
            style: const TextStyle(fontSize: 12.5,
              color: StudentServiceUI.secondary))),
          if (p.papers.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 8),
              child: Text('Thủ tục này không yêu cầu tài liệu đính kèm.',
                style: TextStyle(fontSize: 13.5,
                  color: StudentServiceUI.secondary))),
          ...p.papers.map(_documentRow),
          const StudentSection('Quy trình thực hiện'),
          _timelineItem(1, 'Nộp hồ sơ', p.papers.isEmpty
            ? 'Khai thông tin yêu cầu' : 'Khai thông tin và đính kèm giấy tờ'),
          _timelineItem(2, 'Tiếp nhận và xử lý', 'Đơn vị phụ trách kiểm tra, giải quyết'),
          _timelineItem(3, 'Nhận kết quả', 'Theo hình thức đã đăng ký', last: true),
        ],
      )),
      StudentActionBar(text: _live && deliveryNames.isEmpty
          ? 'Chưa thể nộp hồ sơ' : 'Bắt đầu nộp hồ sơ',
        onPressed: _live && deliveryNames.isEmpty ? null : _startForm),
    ]);
  }

  Widget _formProgress() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BƯỚC ${_formStep + 1} / ${_formSteps.length}',
        style: const TextStyle(fontSize: 11.5, color: StudentServiceUI.green,
          fontWeight: FontWeight.w800, letterSpacing: 0.6)),
      const SizedBox(height: 10),
      Row(children: List<Widget>.generate(_formSteps.length, (i) => Expanded(
        child: AnimatedContainer(
          duration: MediaQuery.maybeOf(context)?.disableAnimations == true
            ? Duration.zero : const Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
          margin: EdgeInsets.only(right: i == _formSteps.length - 1 ? 0 : 5),
          height: 3,
          decoration: BoxDecoration(
            color: _formStep >= i ? StudentServiceUI.green : StudentServiceUI.line,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ))),
    ]),
  );

  Widget _formLabel(String label) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(label, style: const TextStyle(color: StudentServiceUI.ink,
      fontSize: 14, fontWeight: FontWeight.w600)),
  );

  Widget _documentEditingAdvice() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFFFF8E9),
      border: Border.all(color: const Color(0xFFE8C77D)),
      borderRadius: BorderRadius.circular(12)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.warning_amber_rounded,
        color: Color(0xFF9B6713), size: 23),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Vui lòng đọc kỹ trước khi tiếp tục',
            style: TextStyle(fontWeight: FontWeight.w700,
              fontSize: 14, color: Color(0xFF795215))),
          SizedBox(height: 8),
          Text('1. Tự điền và kiểm tra: Ở bước này, OneVNU hỗ trợ '
            'điền thông tin cá nhân đã có trong cơ sở dữ liệu đào tạo '
            'vào các biểu mẫu tương thích. Bạn cần đối chiếu họ tên, '
            'mã sinh viên, ngày sinh, CCCD, lớp, khoa, ngành, email, '
            'số điện thoại và tự bổ sung hoặc sửa mọi thông tin chưa đúng.',
            style: TextStyle(fontSize: 12.7, height: 1.5,
              color: Color(0xFF795215))),
          SizedBox(height: 9),
          Text('2. Sửa và chia sẻ: Các biểu mẫu Word/Excel có bảng, '
            'hình ảnh thường khó chỉnh sửa trên điện thoại. Hãy chọn '
            '“Chia sẻ bản đã điền” để gửi qua Zalo hoặc ứng dụng nhắn '
            'tin cho chính mình, rồi tải về máy tính để chỉnh sửa trong '
            'Word/Excel. Bạn cũng có thể chọn “Mở Word/Excel” trên điện '
            'thoại. Sau khi sửa xong, quay lại OneVNU và chọn “Đính kèm” '
            'hoặc “Thay tệp” để tải BẢN HOÀN CHỈNH lên. Tệp đã chia sẻ '
            'không tự được đính kèm vào hồ sơ.',
            style: TextStyle(fontSize: 12.7, height: 1.5,
              color: Color(0xFF795215))),
          SizedBox(height: 9),
          Text('3. Số bản và lệ phí: Khi số bản kết quả tăng, '
            'tổng lệ phí có thể tăng. Mức thu, hệ số và cách tính thực tế '
            'do trường/đơn vị giải quyết quy định. Số tiền dự kiến trên '
            'ứng dụng chỉ để tham khảo; vui lòng kiểm tra trước khi nộp.',
            style: TextStyle(fontSize: 12.7, height: 1.5,
              color: Color(0xFF795215))),
          SizedBox(height: 9),
          Text('4. Xác nhận: Hãy xem trước từng tệp, xác nhận thông '
            'tin đã đầy đủ và chính xác rồi mới sang bước 3. '
            'Nhấn Tiếp tục không đồng nghĩa với nộp hồ sơ.',
            style: TextStyle(fontSize: 12.7, height: 1.5,
              color: Color(0xFF795215))),
        ])),
    ]),
  );

  Widget _paperPicker(OneDoorPaper paper, Map<String, String> selected,
      VoidCallback pick) {
    final isMainForm = identical(selected, _files);
    final hasFile = selected.containsKey(paper.id);
    final loading = _paperBusy.contains(paper.id);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(border: Border(bottom:
        BorderSide(color: StudentServiceUI.line))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const ModuleDetailIcon(name: 'procedure_attachment', size: 28),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(paper.name, style: const TextStyle(fontSize: 13.5,
                fontWeight: FontWeight.w600, color: StudentServiceUI.ink)),
              const SizedBox(height: 4),
              Text(selected[paper.id] ??
                (paper.isRequired ? 'Giấy tờ bắt buộc' : 'Giấy tờ không bắt buộc'),
                maxLines: 3, style: const TextStyle(
                  color: StudentServiceUI.secondary, fontSize: 12)),
            ])),
          if (hasFile)
            IconButton(tooltip: 'Bỏ tệp', icon: const Icon(Icons.close, size: 19),
              onPressed: _submitting ? null : () {
                setState(() {
                  selected.remove(paper.id);
                  if (isMainForm) {
                    _forgetGeneratedPdf(_filePaths[paper.id]);
                    _forgetGeneratedWord(_filePaths[paper.id]);
                    _filePaths.remove(paper.id);
                    _letterDrafts.remove(paper.id);
                    _editedWordWizardContext.remove(paper.id);
                  } else {
                    _supplementPaths.remove(paper.id);
                  }
                });
              }),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 2, runSpacing: 0, children: [
          if (isMainForm && paper.hasTemplate && _live)
            TextButton.icon(
              onPressed: loading || _submitting ? null :
                () => _openPaperTemplate(paper),
              icon: loading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.description_outlined, size: 17),
              label: const Text('Xem mẫu', style: TextStyle(fontSize: 12.5)),
            ),
          if (isMainForm && paper.hasTemplate && _live)
            TextButton.icon(
              onPressed: loading || _submitting ? null :
                () => _openPaperTemplate(paper, prefilled: true),
              icon: const Icon(Icons.auto_awesome_outlined, size: 17),
              label: const Text('Xem bản đã điền',
                style: TextStyle(fontSize: 12.5)),
            ),
          if (isMainForm && paper.hasTemplate && _live)
            TextButton.icon(
              onPressed: loading || _submitting ? null :
                () => _openPaperTemplate(paper,
                  prefilled: true, saveCopy: true),
              icon: const Icon(Icons.ios_share_outlined, size: 17),
              label: const Text('Chia sẻ bản đã điền',
                style: TextStyle(fontSize: 12.5)),
            ),
          if (isMainForm && _supportsLetterEditor(paper))
            TextButton.icon(
              onPressed: loading || _submitting ? null :
                () => _openLetterEditor(paper),
              icon: loading ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)) :
                const Icon(Icons.edit_note_rounded, size: 19),
              label: Text(_letterDrafts.containsKey(paper.id)
                ? 'Sửa đơn' : 'Soạn đơn',
                style: const TextStyle(fontSize: 12.5)),
            ),
          if (hasFile)
            TextButton.icon(
              onPressed: _submitting ? null :
                () => _openSelectedPaper(paper, supplement: !isMainForm),
              icon: const Icon(Icons.visibility_outlined, size: 17),
              label: const Text('Xem tệp', style: TextStyle(fontSize: 12.5)),
            ),
          if (hasFile && isMainForm && _filePaths[paper.id] != null)
            TextButton.icon(
              onPressed: _submitting ? null : () =>
                OneDoorAttachmentPreview.shareFile(context,
                  path: _filePaths[paper.id]!, title: paper.name),
              icon: const Icon(Icons.ios_share_outlined, size: 17),
              label: Text(_letterDrafts.containsKey(paper.id)
                ? 'Chia sẻ đơn đã điền (Zalo)'
                : 'Chia sẻ tệp (Zalo / máy tính)',
                style: const TextStyle(fontSize: 12.5)),
            ),
          TextButton.icon(
            onPressed: _submitting ? null : pick,
            icon: const Icon(Icons.attach_file_rounded, size: 17),
            label: Text(hasFile ? 'Thay tệp' : 'Đính kèm',
              style: const TextStyle(fontSize: 12.5)),
          ),
        ]),
      ]),
    );
  }

  Widget _applicationForm() {
    final p = _selectedProcedure!;
    final deliveryOptions = _live ? p.deliveryMethods.keys.toList()
        : <String>['Nhận trực tiếp', 'Nhận trực tuyến', 'Nhận qua bưu điện'];
    return Column(children: [
      _formProgress(),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        children: [
          _detailHeading(switch (_currentStep) {
              _DoorFormStep.request => 'Thông tin yêu cầu',
              _DoorFormStep.attachments => 'Tài liệu đính kèm',
              _DoorFormStep.review => 'Kiểm tra thông tin',
            }, p.name),
          if (_currentStep == _DoorFormStep.request) ...[
            _formLabel('Nội dung đề nghị *'),
            TextField(controller: _request, maxLength: 500, minLines: 4,
              maxLines: 7, style: const TextStyle(fontSize: 14),
              decoration: StudentServiceUI.field('Trình bày nội dung cần giải quyết')),
            _formLabel('Hình thức nhận kết quả'),
            if (deliveryOptions.length == 1)
              Container(width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(color: const Color(0xFFEAF5EF),
                  borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline_rounded,
                    color: StudentServiceUI.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(deliveryOptions.single,
                    style: const TextStyle(fontSize: 14,
                      color: StudentServiceUI.ink))),
                ]),
              )
            else if (deliveryOptions.isNotEmpty)
              VnuSingleSelect<String>(
                items: deliveryOptions.map((method) => VnuSelectItem<String>(
                      value: method, label: method)).toList(),
                value: deliveryOptions.contains(_delivery) ? _delivery : null,
                hintText: 'Chọn hình thức nhận',
                sheetTitle: 'Hình thức nhận kết quả',
                enabled: !_submitting,
                requiredField: true,
                searchable: deliveryOptions.length > 5,
                onChanged: (value) {
                  if (value != null) setState(() => _delivery = value);
                },
              )
            else
              const Padding(padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Theo hướng dẫn của đơn vị. Chưa có lựa chọn '
                  'hình thức nhận hợp lệ từ hệ thống Một cửa.',
                  style: TextStyle(fontSize: 13,
                    color: StudentServiceUI.caution))),
            _formLabel('Số lượng bản'),
            _OneDoorNumberStepper(
              value: _quantity,
              enabled: !_submitting,
              onDecrement: _quantity > 1 ? () => _setQuantity(_quantity - 1) : null,
              onIncrement: () => _setQuantity(_quantity + 1),
              onEdit: _editQuantity,
            ),
          ] else if (_currentStep == _DoorFormStep.attachments) ...[
            _documentEditingAdvice(),
            const SizedBox(height: 12),
            const Text('Để gửi qua Zalo, chọn “Chia sẻ bản đã điền” '
              'rồi chọn Zalo trong bảng chia sẻ của điện thoại. '
              'Mỗi tệp PDF, Word, Excel hoặc ảnh được chọn tối đa 10 MB. '
              'Bạn phải xem và xác nhận từng file trước bước 3.',
              style: TextStyle(fontSize: 12.7,
                height: 1.45, color: StudentServiceUI.secondary)),
            const SizedBox(height: 8),
            ...p.papers.map((paper) => _paperPicker(paper, _files,
                () => _pickFile(paper.id))),
          ] else ...[
            StudentInfoLine(label: 'Thủ tục', value: p.name),
            StudentInfoLine(label: 'Nội dung', value: _request.text.trim()),
            StudentInfoLine(label: 'Nhận kết quả', value: _delivery),
            StudentInfoLine(label: 'Số lượng', value: '$_quantity bản'),
            StudentInfoLine(label: 'Tệp đính kèm', value: '${_files.length} tệp'),
            _highlightInfoLine(label: 'Tạm tính theo số bản',
              value: p.hasFee ? _money(p.fee * _quantity) : 'Chưa công bố lệ phí',
              fee: p.hasFee, borders: false),
            const Padding(padding: EdgeInsets.only(top: 6),
              child: Text('Mức tạm tính bằng lệ phí đang công bố nhân số bản. '
                'Lệ phí chính thức và hệ số áp dụng theo quy định của '
                'trường/đơn vị giải quyết.',
                style: TextStyle(fontSize: 12,
                  color: StudentServiceUI.secondary, height: 1.4))),
          ],
        ],
      )),
      SafeArea(top: false, child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        decoration: const BoxDecoration(border: Border(top:
          BorderSide(color: StudentServiceUI.line))),
        child: Row(children: [
          if (_formStep > 0) ...[
            Expanded(child: VnuPressMotion(enabled: !_submitting,
              pressedScale: 0.962,
              child: SizedBox(height: 52, child: OutlinedButton(
                onPressed: _submitting ? null : _previousFormStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: StudentServiceUI.green,
                  side: const BorderSide(color: StudentServiceUI.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                child: const Text('Quay lại',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              )),
            )),
            const SizedBox(width: 12),
          ],
          Expanded(child: VnuPressMotion(
            enabled: !_submitting && !(_currentStep == _DoorFormStep.attachments &&
              _attachmentSecondsRemaining > 0),
            pressedScale: 0.962,
            child: SizedBox(height: 52, child: FilledButton(
            style: FilledButton.styleFrom(
              overlayColor: Colors.transparent,
              backgroundColor: StudentServiceUI.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _submitting ||
                (_currentStep == _DoorFormStep.attachments &&
                  _attachmentSecondsRemaining > 0) ? null : () {
              if (_currentStep == _DoorFormStep.request) {
                if (_request.text.trim().isEmpty) {
                  _message('Vui lòng nhập nội dung đề nghị.',
                    tone: VcoreNoticeTone.warning);
                  return;
                }
                if (_live && p.deliveryMethods[_delivery] == null) {
                  _message('Chưa có hình thức nhận kết quả hợp lệ.',
                    tone: VcoreNoticeTone.warning);
                  return;
                }
              }
              if (_currentStep == _DoorFormStep.attachments &&
                  p.papers.any((paper) => paper.isRequired &&
                    !_files.containsKey(paper.id))) {
                _message('Vui lòng đính kèm đủ giấy tờ bắt buộc.',
                  tone: VcoreNoticeTone.warning);
                return;
              }
              if (_currentStep == _DoorFormStep.attachments) {
                _confirmAttachmentStep();
              } else if (_currentStep != _DoorFormStep.review) {
                _advanceFormStep();
              } else {
                _submit();
              }
            },
            child: _submitting ? VnuLoading.inline(color: Colors.white, size: 17)
              : Text(_currentStep == _DoorFormStep.review
                ? 'Nộp hồ sơ'
                : _currentStep == _DoorFormStep.attachments &&
                    _attachmentSecondsRemaining > 0
                  ? 'Tiếp tục (${_attachmentSecondsRemaining}s)'
                  : 'Tiếp tục',
                style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w600)),
          )))),
        ]),
      )),
    ]);
  }

  Widget _recordDetail() {
    final r = _selectedRecord!;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
      children: [
        _detailHeading(r.procedure.name, 'Ngày nộp: ${_date(r.createdAt)}', iconName: 'procedure_folder'),
        Padding(padding: const EdgeInsets.only(bottom: 4),
          child: Align(alignment: Alignment.centerLeft,
            child: StudentStatus(r.status.label, color: _recordStatusColor(r.status)))),
        if (r.reason.trim().isNotEmpty) ...[
          const SizedBox(height: 15),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(border: Border(
              left: BorderSide(color: StudentServiceUI.caution, width: 2))),
            child: Text(r.reason, style: const TextStyle(color: StudentServiceUI.ink,
              fontSize: 13.5, height: 1.5))),
        ],
        const StudentSection('Tiến trình xử lý'),
        for (int i = 0; i < r.history.length; i++)
          _timelineItem(i + 1, r.history[i].title,
            '${_date(r.history[i].time)}${r.history[i].note.isEmpty ? '' : '\n${r.history[i].note}'}',
            last: i == r.history.length - 1 &&
              r.status != OneDoorRecordStatus.processing),
        if (r.status == OneDoorRecordStatus.processing)
          _timelineItem(r.history.length + 1, 'Đang chờ bước tiếp theo',
            'Thông tin được cập nhật khi hồ sơ được xử lý', last: true),
        const StudentSection('Thông tin hồ sơ'),
        StudentInfoLine(label: 'Ngày nộp', value: _date(r.createdAt)),
        StudentInfoLine(label: 'Nội dung đề nghị', value: r.requestText),
        StudentInfoLine(label: 'Nhận kết quả', value: r.deliveryMethod),
        _highlightInfoLine(label: 'Lệ phí dự kiến', value: _money(r.totalFee), fee: true, borders: false),
        const StudentSection('Tệp đính kèm'),
        if (r.paperFileNames.isEmpty)
          const Text('Chưa có tệp đính kèm.',
            style: TextStyle(fontSize: 13, color: StudentServiceUI.secondary)),
        for (final file in r.paperFileNames.values)
          Container(padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: const BoxDecoration(border: Border(bottom:
              BorderSide(color: StudentServiceUI.line))),
            child: Row(children: [
              const ModuleDetailIcon(name: 'procedure_attachment', size: 27),
              const SizedBox(width: 12),
              Expanded(child: Text(file, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, color: StudentServiceUI.ink))),
            ])),
        if (r.status == OneDoorRecordStatus.supplement) ...[
          const SizedBox(height: 24),
          VnuPressMotion(child: SizedBox(height: 46, child: FilledButton(
            onPressed: () => setState(() { _page = _DoorPage.supplement;
              _supplementFiles.clear(); _supplementNote.clear(); }),
            style: FilledButton.styleFrom(overlayColor: Colors.transparent,
              backgroundColor: StudentServiceUI.green),
            child: const Text('Bổ sung hồ sơ')))),
        ],
        if (r.status == OneDoorRecordStatus.processing ||
            r.status == OneDoorRecordStatus.supplement) ...[
          const SizedBox(height: 12),
          VnuPressMotion(child: TextButton(onPressed: _cancelRecord,
            child: const Text('Hủy hồ sơ',
              style: TextStyle(color: StudentServiceUI.danger)))),
        ],
      ],
    );
  }

  Widget _supplementPage() {
    final r = _selectedRecord!;
    return Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          _detailHeading('Bổ sung tài liệu', r.procedure.name),
          _formLabel('Nội dung bổ sung'),
          TextField(controller: _supplementNote, minLines: 3, maxLines: 6,
            style: const TextStyle(fontSize: 14),
            decoration: StudentServiceUI.field('Nhập nội dung cần bổ sung')),
          const StudentSection('Giấy tờ'),
          ...r.procedure.papers.map((paper) => _paperPicker(paper,
              _supplementFiles, () => _pickFile(paper.id, supplement: true))),
        ],
      )),
      StudentActionBar(text: 'Gửi bổ sung', onPressed: _sendSupplement),
    ]);
  }
}


/// Local One Door stepper. Matches the horizontal transition of the reference:
/// increment pushes the old value left and brings the new value from right;
/// decrement reverses both directions. No HTML or extra packages.
class _OneDoorNumberStepper extends StatefulWidget {
  const _OneDoorNumberStepper({required this.value, required this.enabled,
    required this.onDecrement, required this.onIncrement, required this.onEdit});
  final int value;
  final bool enabled;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onEdit;

  @override
  State<_OneDoorNumberStepper> createState() => _OneDoorNumberStepperState();
}

class _OneDoorNumberStepperState extends State<_OneDoorNumberStepper>
    with SingleTickerProviderStateMixin {
  static const double _numberLaneWidth = 78;
  // Move farther than the entire lane, not one glyph width. This prevents the
  // departing and arriving numbers from overlapping at the midpoint.
  static const double _numberTravel = 94;
  late final AnimationController _controller;
  late int _settledValue;
  late int _outgoingValue;
  late int _incomingValue;
  int? _queuedValue;
  bool _transitioning = false;
  bool _increasing = true;

  @override
  void initState() {
    super.initState();
    _settledValue = widget.value;
    _outgoingValue = widget.value;
    _incomingValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final next = _queuedValue ?? widget.value;
    setState(() {
      _settledValue = _incomingValue;
      _transitioning = false;
      _queuedValue = null;
    });
    if (next != _settledValue) _animateTo(next);
  }

  void _animateTo(int next) {
    if (next == _settledValue) return;
    _outgoingValue = _settledValue;
    _incomingValue = next;
    _increasing = next > _settledValue;
    _transitioning = true;
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _OneDoorNumberStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    if (_transitioning) {
      // Coalesce rapid +/- taps into the latest value; at most two texts are
      // painted, and the parent remains the source of truth.
      _queuedValue = widget.value;
    } else {
      _animateTo(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _numberText(int value) => Text(
    '$value',
    maxLines: 1,
    softWrap: false,
    style: const TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: StudentServiceUI.ink,
      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    ),
  );

  Widget _numberTrack(bool reduceMotion) => SizedBox(
    width: _numberLaneWidth,
    height: 50,
    child: ClipRect(
      child: reduceMotion
          ? Center(child: _numberText(widget.value))
          : AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (!_transitioning) {
                  return Center(child: _numberText(_settledValue));
                }
                final progress = Curves.easeInOutCubic.transform(
                  _controller.value,
                );
                final sign = _increasing ? 1.0 : -1.0;
                return Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: <Widget>[
                    Transform.translate(
                      offset: Offset(-sign * _numberTravel * progress, 0),
                      child: Center(child: _numberText(_outgoingValue)),
                    ),
                    Transform.translate(
                      offset: Offset(sign * _numberTravel * (1 - progress), 0),
                      child: Center(child: _numberText(_incomingValue)),
                    ),
                  ],
                );
              },
            ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations == true;
    return Row(children: [
      Expanded(child: Text('Chọn số bản cần cấp',
        style: const TextStyle(fontSize: 12.5,
          color: StudentServiceUI.secondary))),
      Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8F5),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: StudentServiceUI.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          VnuPressMotion(enabled: widget.enabled && widget.onDecrement != null,
            pressedScale: 0.94,
            child: IconButton(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: widget.enabled ? widget.onDecrement : null,
              tooltip: 'Giảm số bản',
              icon: const Icon(Icons.remove_rounded,
                color: StudentServiceUI.green),
            )),
          InkWell(
            onTap: widget.enabled ? widget.onEdit : null,
            borderRadius: BorderRadius.circular(8),
            child: _numberTrack(reduceMotion),
          ),
          VnuPressMotion(enabled: widget.enabled, pressedScale: 0.94,
            child: IconButton(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: widget.enabled ? widget.onIncrement : null,
              tooltip: 'Tăng số bản',
              icon: const Icon(Icons.add_rounded,
                color: StudentServiceUI.green),
            )),
        ]),
      ),
    ]);
  }
}
