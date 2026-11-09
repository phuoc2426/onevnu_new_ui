import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:vnu_core/modules/one_door/data/one_door_form_api.dart';
import 'package:vnu_core/modules/one_door/data/one_door_api_debug.dart';
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

// V29.3 SUBMITTED ATTACHMENT PREVIEW: GET stored file by record/paper ID.
// V29.1 LOCAL OTHER OPTION: app appends "Khác" when needed; no invented IdLyDo.
// V29 REASON UX: only "Khac" reveals request entry; Word and POST agree.
// V28 REASON TO DOCX PREVIEW: selected lyDos.tenLyDo fills {YeuCau}.
/// Native One Door. Exchange ONEVNU session for a One Door token on entry.
/// Debug may fall back to mock UI. Release never displays fabricated records.
class VcoreOneDoorView extends StatefulWidget {
  const VcoreOneDoorView({super.key});

  @override
  State<VcoreOneDoorView> createState() => _VcoreOneDoorViewState();
}

enum _DoorPage { overview, procedure, form, record, supplement }

enum _DoorFormStep { request, attachments, review }

// V26 custom bottom sheet sources. Existing project image_picker is reused.
enum _DoorAttachmentSource { camera, gallery, files }

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


// V30: one editable supplementary field plus its previously submitted value.
class _OneDoorSupplementField {
  const _OneDoorSupplementField({
    required this.key,
    required this.label,
    required this.type,
    required this.hint,
    required this.currentValue,
  });
  final String key;
  final String label;
  final String type;
  final String hint;
  final String currentValue;
}

class _OneDoorSupplementNotice {
  const _OneDoorSupplementNotice({
    required this.message,
    required this.author,
    required this.date,
    required this.answered,
  });
  final String message;
  final String author;
  final String date;
  final bool answered;
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

  // V30: Supplement works on the SUBMITTED record, never the draft.
  bool _supplementLoading = false;
  String? _supplementError;
  bool _recordCanSupplement = false;
  int _supplementRequestSerial = 0;
  String _supplementSavedRequest = '';
  // V30.1: Supplement shows the complete submitted application, not only
  // editable Word template variables. Non-editable values are read-only
  // because POST /bo-sung does not accept these fixed form properties.
  String _supplementSavedReason = '';
  String _supplementSavedDelivery = '';
  int? _supplementSavedQuantity;
  String _supplementCode = '';
  String _supplementSubmittedAt = '';
  int? _supplementPaidAmount;
  String _supplementProcedureId = '';
  List<_OneDoorSupplementField> _supplementFields =
      <_OneDoorSupplementField>[];
  final Map<String, TextEditingController> _supplementInputs =
      <String, TextEditingController>{};
  Map<String, String> _supplementCurrentValues = <String, String>{};
  List<_OneDoorSupplementNotice> _supplementNotices =
      <_OneDoorSupplementNotice>[];
  List<OneDoorPaper> _supplementPapers = <OneDoorPaper>[];
  final Map<String, String> _supplementCurrentFiles = <String, String>{};
  final Set<String> _supplementMissingRequiredPapers = <String>{};
  final Set<String> _supplementAutoPaperIds = <String>{};
  final Map<String, String> _supplementReviewedDigests = <String, String>{};
  final Map<String, String> _supplementGeneratedFingerprints =
      <String, String>{};


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
  // V29.3: Load submitted attachments from the server, not from draft paths.
  bool _recordDetailLoading = false;
  bool _recordDetailFailed = false;
  final Set<String> _submittedPaperBusy = <String>{};
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
  final Set<String> _managedPhotoPaths = <String>{};
  final Map<String, String> _editedWordWizardContext = <String, String>{};
  final Set<String> _paperBusy = <String>{};

  // V24: API-sourced form schema, temporary attachments, and preview receipt.
  OneDoorLiveApi? _oneDoorApi;
  OneDoorFormApi? _formApi;
  OneDoorFormConfiguration _formConfig = const OneDoorFormConfiguration();
  bool _formConfigLoading = false;
  String? _formConfigError;
  int? _selectedReasonId;
  // A UI-only choice; never assign a fabricated backend IdLyDo.
  bool _localOtherSelected = false;
  int _formRequestSerial = 0;
  int _generatedRequestSerial = 0;
  final Map<String, TextEditingController> _extraInputs =
      <String, TextEditingController>{};
  Map<String, String> _savedFormValues = <String, String>{};
  Map<String, String> _studentFormValues = <String, String>{};
  final Set<String> _autoAttachedIds = <String>{};
  final Set<String> _reviewedIds = <String>{};
  // V26 REVIEW ONCE per exact bytes version. Hash when the student confirms,
  // and validate the same digest before advancing/submitting.
  final Map<String, String> _reviewedDigests = <String, String>{};
  final Map<String, String> _generatedFingerprints = <String, String>{};
  final Map<String, String> _failedAutoPapers = <String, String>{};

  void _invalidatePreviewReceipts() {
    // Only app-generated documents depend on form fields. Manual files must
    // not lose a valid review merely because the student edits delivery mode.
    final affected = <String>{
      ..._autoAttachedIds,
      ..._letterDrafts.keys,
      ..._editedWordWizardContext.keys,
    };
    if (affected.isEmpty) return;
    setState(() {
      for (final id in affected) {
        _reviewedIds.remove(id);
        _reviewedDigests.remove(id);
      }
    });
  }

  Future<String> _digestFile(String path) async {
    final file = File(path);
    if (!await file.exists()) throw StateError('Không tìm thấy tệp.');
    final size = await file.length();
    if (size < 1 || size > 10 * 1024 * 1024) {
      throw StateError('Tệp trống hoặc vượt quá 10 MB.');
    }
    return (await sha256.bind(file.openRead()).first).toString();
  }

  Future<bool> _checkReviewedFileVersions() async {
    if (_selectedProcedure == null) return false;
    for (final entry in _files.entries.toList()) {
      final id = entry.key;
      final path = _filePaths[id];
      if (path == null) {
        if (_live) return false;
        continue;
      }
      String current;
      try {
        current = await _digestFile(path);
      } catch (_) {
        if (mounted) _message('Tệp không còn hợp lệ. Vui lòng đính kèm lại.',
          tone: VcoreNoticeTone.warning);
        return false;
      }
      if (_reviewedDigests[id] != current) {
        if (mounted) {
          setState(() {
            _reviewedIds.remove(id);
            _reviewedDigests.remove(id);
          });
          _message('Tệp đã thay đổi sau khi xem. Hãy mở kiểm tra lại.',
            tone: VcoreNoticeTone.warning);
        }
        return false;
      }
    }
    return true;
  }

  void _previousFormStep() {
    if (_submitting || _page != _DoorPage.form || _formStep <= 0) return;
    ++_generatedRequestSerial;
    setState(() => _formStep--);
  }

  void _advanceFormStep() {
    if (_page != _DoorPage.form || _formStep + 1 >= _formSteps.length) return;
    setState(() => _formStep++);
    if (_currentStep == _DoorFormStep.attachments) {
      _syncAutoDocuments();
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

  void _forgetManagedPhoto(String? path) {
    if (path == null || !_managedPhotoPaths.remove(path)) return;
    // Delete ONLY temporary photos created by our picker, never gallery files.
    File(path).delete().catchError((Object _) => File(path));
  }

  void _clearGeneratedPdfs() {
    for (final path in _generatedPdfPaths.toList()) {
      _forgetGeneratedPdf(path);
    }
    for (final path in _generatedWordPaths.toList()) {
      _forgetGeneratedWord(path);
    }
    for (final path in _managedPhotoPaths.toList()) {
      _forgetManagedPhoto(path);
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
      if (!supplement) {
        _reviewedIds.remove(paper.id);
        _reviewedDigests.remove(paper.id);
        _autoAttachedIds.remove(paper.id);
        _generatedFingerprints.remove(paper.id);
      }
      _generatedWordPaths.add(path);
      (supplement ? _supplementPaths : _filePaths)[paper.id] = path;
      (supplement ? _supplementFiles : _files)[paper.id] =
          path.split(Platform.pathSeparator).last;
      if (!supplement) {
        _letterDrafts.remove(paper.id);
        _editedWordWizardContext[paper.id] =
          '${_quantity}::${_wordYeuCau}';
      }
      if (supplement) {
        _supplementReviewedDigests.remove(paper.id);
        _supplementGeneratedFingerprints.remove(paper.id);
      }
      if (previous != path) {
        _forgetGeneratedPdf(previous);
        _forgetGeneratedWord(previous);
        _forgetManagedPhoto(previous);
      }
    });
  }

  @override
  void dispose() {
    // Avoid deleting a file while Dio may still be uploading it.
    if (!_submitting) _clearGeneratedPdfs();
    _search.removeListener(_onSearch);
    _search.dispose();
    _request.dispose();
    _supplementNote.dispose();
    ++_supplementRequestSerial;
    for (final c in _supplementInputs.values) { c.dispose(); }
    ++_formRequestSerial;
    ++_generatedRequestSerial;
    for (final input in _extraInputs.values) { input.dispose(); }
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
            _oneDoorApi = api;
            _formApi = OneDoorFormApi(oneDoorSession,
              refreshSession: () async {
                final current = Globals().token.trim();
                if (current.isEmpty || current != token) {
                  throw StateError('ONEVNU login session has changed');
                }
                return auth.exchange(oneVnuJwt: current);
              });
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
        _connectionError = 'Chưa thể mở Thủ tục hành chính. '
          'Vui lòng kiểm tra kết nối mạng rồi thử lại.';
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
        ++_generatedRequestSerial;
        _page = _DoorPage.procedure;
      } else if (_page == _DoorPage.supplement) {
        if (_submitting) return;
        ++_supplementRequestSerial;
        _clearSupplementDraft();
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
    final repository = _repo;
    final fetchDetail = repository is OneDoorLiveRepository;
    setState(() {
      _selectedRecord = record;
      _page = _DoorPage.record;
      _myRecordsTab = true;
      _recordDetailLoading = fetchDetail;
      _recordDetailFailed = false;
      _recordCanSupplement = false;
    });
    if (repository is! OneDoorLiveRepository) return;
    try {
      final detail = await repository.detailRecord(
        record.id, procedure: record.procedure);
      if (mounted && _selectedRecord?.id == record.id) {
        final raw = _oneDoorApi?.recordSnapshot(record.id);
        setState(() {
          _selectedRecord = detail;
          _recordCanSupplement = raw?['coTheBoSung'] == true;
        });
      }
    } catch (_) {
      if (mounted && _selectedRecord?.id == record.id) {
        setState(() => _recordDetailFailed = true);
        _message('Không tải được thông tin hồ sơ. Vui lòng thử lại.',
          tone: VcoreNoticeTone.warning);
      }
    } finally {
      if (mounted && _selectedRecord?.id == record.id) {
        setState(() => _recordDetailLoading = false);
      }
    }
  }

  // V29.3: Never use locally generated form files for submitted-record view.
  // Always GET the stored upload for (idDangKy, idGiayTo).
  Future<void> _openSubmittedPaper(String paperId, String fileName,
      {bool share = false}) async {
    final record = _selectedRecord;
    final api = _oneDoorApi;
    if (record == null || api == null || !_live) {
      _message('Chưa thể mở giấy tờ này.', tone: VcoreNoticeTone.warning);
      return;
    }
    final busyKey = '${record.id}|$paperId';
    if (_submittedPaperBusy.contains(busyKey)) return;
    setState(() => _submittedPaperBusy.add(busyKey));
    try {
      final submitted = await api.submittedPaperFile(
        registrationId: record.id,
        paperId: paperId,
        fileName: fileName,
      );
      final base = await getTemporaryDirectory();
      final folder = Directory('${base.path}/onevnu_submitted_papers');
      if (!await folder.exists()) await folder.create(recursive: true);
      // Keep private downloads in app cache; retire stale files after a day.
      try {
        await for (final entry in folder.list()) {
          if (entry is! File) continue;
          final lastUpdate = (await entry.stat()).modified;
          if (DateTime.now().difference(lastUpdate) >
              const Duration(hours: 24)) {
            await entry.delete();
          }
        }
      } catch (_) { /* Cache cleanup must not block preview. */ }
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final path = '${folder.path}/submitted_${stamp}.${submitted.extension}';
      await File(path).writeAsBytes(submitted.bytes, flush: true);
      if (!mounted || _selectedRecord?.id != record.id ||
          (_page != _DoorPage.record &&
           _page != _DoorPage.supplement)) return;
      if (share) {
        await OneDoorAttachmentPreview.shareFile(context,
          path: path, title: fileName);
      } else {
        await OneDoorAttachmentPreview.openForReview(context,
          path: path,
          title: fileName.trim().isEmpty ? 'Giấy tờ đã nộp' : fileName,
        );
      }
    } catch (_) {
      if (mounted && _selectedRecord?.id == record.id) {
        _message('Không mở được tệp đã nộp. Vui lòng thử lại.',
          tone: VcoreNoticeTone.error);
      }
    } finally {
      if (mounted) setState(() => _submittedPaperBusy.remove(busyKey));
    }
  }

  Widget _submittedPaperRow(String paperId, String fileName) {
    final record = _selectedRecord;
    final busyKey = '${record?.id ?? ''}|$paperId';
    final busy = _submittedPaperBusy.contains(busyKey);
    final available = _live && _oneDoorApi != null && !busy;
    final name = fileName.trim().isNotEmpty
        ? fileName.trim() : 'Giấy tờ đã nộp';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(border: Border(
        bottom: BorderSide(color: StudentServiceUI.line))),
      child: Row(children: [
        const ModuleDetailIcon(name: 'procedure_attachment', size: 27),
        const SizedBox(width: 12),
        Expanded(child: Text(name, maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13.5,
            color: StudentServiceUI.ink))),
        const SizedBox(width: 4),
        if (busy)
          const SizedBox(width: 40, height: 40,
            child: Center(child: SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))))
        else
          IconButton(
            tooltip: 'Xem tệp đã nộp',
            icon: const Icon(Icons.visibility_outlined, size: 21),
            color: StudentServiceUI.green,
            onPressed: available
              ? () => _openSubmittedPaper(paperId, name)
              : null,
          ),
        IconButton(
          tooltip: 'Chia sẻ tệp đã nộp',
          icon: const Icon(Icons.ios_share_outlined, size: 19),
          color: StudentServiceUI.ink,
          onPressed: available
            ? () => _openSubmittedPaper(paperId, name, share: true)
            : null,
        ),
      ]),
    );
  }

  // V24: fields in Bước 1 come from bienCanNhaps; never fabricate a schema.
  Future<void> _loadFormConfiguration() async {
    final api = _formApi;
    final procedure = _selectedProcedure;
    if (!_live || api == null || procedure == null) return;
    final serial = ++_formRequestSerial;
    setState(() {
      _formConfigLoading = true;
      _formConfigError = null;
    });
    try {
      final config = await api.load(procedure.id);
      Map<String, String> saved = <String, String>{};
      try { saved = await api.savedValues(); } catch (_) {
        // Previously saved values are optional; the form schema is not.
      }
      Map<String, String> student = <String, String>{};
      if (Globals().token.trim().isNotEmpty) {
        try {
          final data = await const OneDoorStudentPrefillService().load();
          student = Map<String, String>.from(data.values);
        } catch (_) { /* Manual input remains possible. */ }
      }
      if (!mounted || serial != _formRequestSerial ||
          _selectedProcedure?.id != procedure.id ||
          _page != _DoorPage.form) return;
      for (final input in _extraInputs.values) { input.dispose(); }
      _extraInputs.clear();
      const predefined = <String>{'yeucau', 'soluongban',
        'idhinhthucnhanketqua', 'idthutuc'};
      for (final field in config.fields) {
        if (predefined.contains(field.key.toLowerCase())) continue;
        final value = field.previousValue.trim().isNotEmpty
          ? field.previousValue
          : (saved[field.key] ?? student[field.key] ?? '');
        _extraInputs[field.key] = TextEditingController(text: value);
      }
      setState(() {
        _formConfig = config;
        _savedFormValues = saved;
        _studentFormValues = student;
        _formConfigLoading = false;
      });
      if (config.tuitionBlocked) {
        _message('Bạn chưa đáp ứng điều kiện học phí của thủ tục.',
          tone: VcoreNoticeTone.warning);
      }
    } catch (_) {
      if (!mounted || serial != _formRequestSerial ||
          _page != _DoorPage.form) return;
      setState(() {
        _formConfigLoading = false;
        _formConfigError = 'Chưa thể chuẩn bị các thông tin cần điền. '
            'Vui lòng thử lại.';
      });
    }
  }

  // The app adds "Khác" to the visible dropdown when the catalog has no
  // equivalent option. This is UI state only, NOT an API reason ID.
  String get _selectedReasonLabel {
    if (_localOtherSelected) return 'Khác';
    final selectedId = _selectedReasonId;
    if (selectedId == null) return '';
    for (final reason in _formConfig.reasons) {
      if (reason.id == selectedId) return reason.label.trim();
    }
    return '';
  }

  bool get _hasReasonChoices => _live && _formConfig.reasons.isNotEmpty;

  // Covers "Khác", "Khác (ghi rõ)", "Lý do khác", "Mục đích khác" and
  // equivalents without accents, without falsely matching "Khác nhau".
  static bool _isOtherReason(String label) => RegExp(
    r'^(?:(?:lý do|li do|mục đích|muc dich)\s+)?(?:khác|khac)(?:$|\s*[:(.,/-]|\s+ghi\s+rõ(?:$|\s))',
    caseSensitive: false,
  ).hasMatch(label.trim());

  // Avoid duplicate "Khác" if the procedure already provides one.
  bool get _appendLocalOtherChoice => _hasReasonChoices &&
      !_formConfig.reasons.any((reason) => _isOtherReason(reason.label));

  bool get _otherReasonSelected => _hasReasonChoices &&
      (_localOtherSelected || (_selectedReasonId != null &&
          _isOtherReason(_selectedReasonLabel)));

  // With no preset choices, the student writes the request directly.
  // With preset choices, only "Khác" exposes an editable request field.
  bool get _requestNeedsText => !_hasReasonChoices || _otherReasonSelected;

  // A single authoritative text is used in the Word draft, Step 3 summary,
  // GiaTriBieuMau.YeuCau, AND the fixed ho-so.YeuCau multipart field.
  // Hidden text from an earlier "Khác" choice must never be submitted after
  // switching to a fixed reason, nor when no reason has yet been selected.
  String get _effectiveRequest => _requestNeedsText
      ? _request.text.trim()
      : (_selectedReasonId == null ? '' : _selectedReasonLabel);

  String get _wordYeuCau => _effectiveRequest;

  String get _requestSourceForDebug =>
      _requestNeedsText ? 'noi_dung_de_nghi' : 'lyDos.tenLyDo';

  bool _validateRequestDetails() {
    if (_hasReasonChoices && _selectedReasonId == null &&
        !_localOtherSelected) {
      _message('Vui lòng chọn lý do hoặc mục đích.',
        tone: VcoreNoticeTone.warning);
      return false;
    }
    final content = _effectiveRequest;
    if (content.isEmpty) {
      _message(_otherReasonSelected
          ? 'Bạn đã chọn Khác. Vui lòng ghi rõ nội dung yêu cầu.'
          : 'Vui lòng nhập nội dung yêu cầu.',
        tone: VcoreNoticeTone.warning);
      return false;
    }
    if (content.length > 500) {
      _message('Nội dung yêu cầu tối đa 500 ký tự.',
        tone: VcoreNoticeTone.warning);
      return false;
    }
    return true;
  }

  Map<String, String> _formVariables() {
    final now = DateTime.now();
    final values = <String, String>{
      ..._studentFormValues,
      ..._savedFormValues,
      'TenThuTuc': _selectedProcedure?.name ?? '',
      'TenDonVi': _selectedProcedure?.unitName ?? '',
      'Ngay': '${now.day}', 'Thang': '${now.month}', 'Nam': '${now.year}',
      'NgayNop': DateFormat('dd/MM/yyyy').format(now),
    };
    for (final entry in _extraInputs.entries) {
      values[entry.key] = entry.value.text.trim();
    }
    // Never let old saved values override these fresh form values.
    // The same effective content is sent to Word, GiaTriBieuMau.YeuCau,
    // and the official ho-so.YeuCau field when the student submits.
    values['YeuCau'] = _wordYeuCau;
    values['SoLuongBan'] = '$_quantity';
    if (_selectedReasonId != null && _selectedReasonLabel.isNotEmpty) {
      values['IdLyDo'] = '$_selectedReasonId';
    } else {
      values.remove('IdLyDo');
    }
    return values;
  }

  String _formFingerprint() {
    final values = _formVariables();
    final keys = values.keys.toList()..sort();
    return jsonEncode(<String, String>{for (final k in keys) k: values[k]!});
  }

  bool _validateDynamicFields() {
    if (_formConfigLoading || (_live && _formConfigError != null)) {
      _message('Thông tin hồ sơ chưa sẵn sàng. Vui lòng thử lại.',
        tone: VcoreNoticeTone.warning);
      return false;
    }
    if (_formConfig.tuitionBlocked) {
      _message('Bạn chưa đáp ứng điều kiện nộp hồ sơ cho thủ tục này.',
        tone: VcoreNoticeTone.warning);
      return false;
    }
    for (final field in _formConfig.fields) {
      final control = _extraInputs[field.key];
      if (control != null && field.required && control.text.trim().isEmpty) {
        _message('Vui lòng nhập ${field.label}.',
          tone: VcoreNoticeTone.warning);
        return false;
      }
    }
    return true;
  }

  Widget _requestEntryWidget() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _formLabel('Nội dung yêu cầu *'),
      if (_otherReasonSelected) ...[
        const Padding(
          padding: EdgeInsets.only(bottom: 9),
          child: Text('Vui lòng ghi rõ lý do hoặc mục đích của bạn.',
            style: TextStyle(color: StudentServiceUI.secondary, fontSize: 12.5)),
        ),
      ],
      TextField(
        controller: _request,
        maxLength: 500,
        minLines: 4,
        maxLines: 7,
        onChanged: (_) => _invalidatePreviewReceipts(),
        style: const TextStyle(fontSize: 14),
        decoration: StudentServiceUI.field(
          _otherReasonSelected
              ? 'Nhập lý do hoặc mục đích cụ thể'
              : 'Trình bày nội dung bạn cần giải quyết',
        ),
      ),
    ],
  );

  Widget _selectedRequestWidget() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _formLabel('Nội dung yêu cầu'),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5EF),
          border: Border.all(color: const Color(0xFFC9E5D4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
              color: StudentServiceUI.green, size: 19),
            const SizedBox(width: 10),
            Expanded(child: Text(_selectedReasonLabel,
              style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w600,
                color: StudentServiceUI.ink, height: 1.45))),
          ],
        ),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text('Nội dung này sẽ được ghi vào giấy tờ của bạn.',
          style: TextStyle(color: StudentServiceUI.secondary, fontSize: 12)),
      ),
    ],
  );

  Widget _dynamicFieldsWidget() {
    // Mock mode retains the regular free-text request workflow.
    if (!_live) return _requestEntryWidget();
    if (_formConfigLoading) return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Row(children: [
        SizedBox(width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 12),
        Expanded(child: Text('Đang chuẩn bị thông tin...')),
      ]));
    if (_formConfigError != null) return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_formConfigError!, style: const TextStyle(
          color: StudentServiceUI.caution, fontSize: 13)),
        TextButton.icon(onPressed: _loadFormConfiguration,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Thử lại')),
      ]));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_hasReasonChoices) ...[
        _formLabel('Lý do / Mục đích *'),
        // Use string-tagged values so the UI-only "Khác" cannot collide
        // with any integer ID from the backend.
        VnuSingleSelect<String>(
          items: [
            for (final reason in _formConfig.reasons)
              VnuSelectItem<String>(
                value: 'reason:${reason.id}', label: reason.label),
            if (_appendLocalOtherChoice)
              const VnuSelectItem<String>(
                value: 'local:other', label: 'Khác'),
          ],
          value: _localOtherSelected ? 'local:other'
              : (_selectedReasonId == null ? null
                  : 'reason:$_selectedReasonId'),
          hintText: 'Chọn lý do hoặc mục đích',
          sheetTitle: 'Lý do / Mục đích',
          enabled: !_submitting,
          requiredField: true,
          onChanged: (value) {
            if (value == null) return;
            final localOther = value == 'local:other';
            final reasonId = value.startsWith('reason:')
                ? int.tryParse(value.substring('reason:'.length))
                : null;
            if (_localOtherSelected == localOther &&
                _selectedReasonId == reasonId) return;
            setState(() {
              _localOtherSelected = localOther;
              _selectedReasonId = reasonId;
            });
            _invalidatePreviewReceipts();
          },
        ),
      ],
      if (_requestNeedsText)
        _requestEntryWidget()
      else if (_selectedReasonId != null)
        _selectedRequestWidget(),
      if (_extraInputs.isNotEmpty) ...[
        const SizedBox(height: 16),
        const Text('THÔNG TIN BỔ SUNG', style: TextStyle(
          color: StudentServiceUI.green,
          fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        const Text('Vui lòng kiểm tra và điền đầy đủ các mục có dấu *.',
          style: TextStyle(color: StudentServiceUI.secondary, fontSize: 12)),
      ],
      for (final field in _formConfig.fields)
        if (_extraInputs.containsKey(field.key)) ...[
          _formLabel('${field.label}${field.required ? ' *' : ''}'),
          TextField(
            controller: _extraInputs[field.key],
            onChanged: (_) => _invalidatePreviewReceipts(),
            minLines: field.type.contains('textarea') ? 3 : 1,
            maxLines: field.type.contains('textarea') ? 6 : 1,
            keyboardType: field.type.contains('number') ||
                field.type.contains('int') ? TextInputType.number
                : field.type.contains('date') ? TextInputType.datetime
                : TextInputType.text,
            decoration: StudentServiceUI.field(
              field.hint.isNotEmpty ? field.hint : 'Nhập ${field.label}'),
          ),
        ],
    ]);
  }

  Future<void> _syncAutoDocuments() async {
    final api = _formApi;
    final procedure = _selectedProcedure;
    if (!_live || api == null || procedure == null ||
        _currentStep != _DoorFormStep.attachments) return;
    final serial = ++_generatedRequestSerial;
    final fingerprint = _formFingerprint();
    final variables = _formVariables();
    for (final paper in procedure.papers) {
      if (serial != _generatedRequestSerial || !mounted ||
          _page != _DoorPage.form ||
          _currentStep != _DoorFormStep.attachments) return;
      if (!_formConfig.autoPaperIds.contains(paper.id)) continue;
      // A student-chosen replacement is authoritative: do not overwrite it.
      if (_files.containsKey(paper.id) &&
          !_autoAttachedIds.contains(paper.id)) continue;
      if (_filePaths.containsKey(paper.id) &&
          _generatedFingerprints[paper.id] == fingerprint) continue;
      setState(() {
        _paperBusy.add(paper.id);
        _failedAutoPapers.remove(paper.id);
        _reviewedIds.remove(paper.id);
        _reviewedDigests.remove(paper.id);
      });
      try {
        OneDoorApiDebug.instance.note('Tự điền giấy tờ ở Bước 2',
          <String, dynamic>{
            'idGiayTo': paper.id,
            'YeuCau': variables['YeuCau'] ?? '',
            'YeuCauSource': _requestSourceForDebug,
            'SelectedReasonId': _selectedReasonId,
            'LocalOtherSelected': _localOtherSelected,
            'keys': variables.keys.toList()..sort(),
            'api': 'POST /api/v1/files/giay-to-mau/{idGiayTo}/da-dien',
          });
        final result = await api.generate(paper.id, variables);
        final directory = await getTemporaryDirectory();
        final safeId = paper.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        // Keep a readable filename for the student, not an internal API tag.
        final paperLabel = paper.name
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
        final shortLabel = paperLabel.length > 38
          ? paperLabel.substring(0, 38) : paperLabel;
        final path = '${directory.path}${Platform.pathSeparator}'
          'Ban_da_dien_${shortLabel.isEmpty ? 'giay_to' : shortLabel}_'
          '${DateTime.now().microsecondsSinceEpoch}.${result.extension}';
        final file = File(path);
        await file.writeAsBytes(result.bytes, flush: true);
        if (!mounted || serial != _generatedRequestSerial ||
            _page != _DoorPage.form ||
            _currentStep != _DoorFormStep.attachments) {
          await file.delete().catchError((Object _) => file);
          return;
        }
        final previous = _filePaths[paper.id];
        setState(() {
          _filePaths[paper.id] = path;
          _files[paper.id] = path.split(Platform.pathSeparator).last;
          _autoAttachedIds.add(paper.id);
          _generatedFingerprints[paper.id] = fingerprint;
          _failedAutoPapers.remove(paper.id);
          // Every regenerated document must be previewed again.
          _reviewedIds.remove(paper.id);
          _reviewedDigests.remove(paper.id);
          if (result.extension == 'pdf') {
            _generatedPdfPaths.add(path);
          } else {
            _generatedWordPaths.add(path);
          }
        });
        if (previous != null && previous != path) {
          _forgetGeneratedPdf(previous);
          _forgetGeneratedWord(previous);
          _forgetManagedPhoto(previous);
        }
      } catch (error) {
        if (!mounted || serial != _generatedRequestSerial) return;
        OneDoorApiDebug.instance.note('V28 Không xác minh được Word đã điền',
          <String, dynamic>{'paperId': paper.id,
            'errorType': error.runtimeType.toString()});
        final previous = _filePaths[paper.id];
        setState(() {
          _filePaths.remove(paper.id);
          _files.remove(paper.id);
          _autoAttachedIds.remove(paper.id);
          _generatedFingerprints.remove(paper.id);
          _reviewedIds.remove(paper.id);
          _reviewedDigests.remove(paper.id);
          _failedAutoPapers[paper.id] =
            'Không xác minh được nội dung bản Word đã điền. '
            'Vui lòng thử tạo lại hoặc đính kèm bản hoàn chỉnh.';
        });
        _forgetGeneratedPdf(previous);
        _forgetGeneratedWord(previous);
      } finally {
        if (mounted) setState(() => _paperBusy.remove(paper.id));
      }
    }
  }

  /// V26: A verified *version* is acknowledged only ONCE. Reopening the same
  /// file never triggers another confirmation. Native Office is preferred for
  /// DOC/DOCX because the mobile HTML renderer can reflow official templates.
  Future<void> _previewAndConfirm(OneDoorPaper paper,
      {bool supplement = false}) async {
    final path = (supplement ? _supplementPaths : _filePaths)[paper.id];
    if (path == null || path.isEmpty || !mounted) return;
    if (supplement) {
      await _reviewSupplementPaper(paper);
      return;
    }
    final formVersion = _autoAttachedIds.contains(paper.id)
        ? _formFingerprint() : null;
    try {
      final before = await _digestFile(path);
      if (!mounted || _filePaths[paper.id] != path) return;
      final opened = await OneDoorAttachmentPreview.openForReview(context,
        path: path, title: paper.name);
      if (!mounted || !opened || _filePaths[paper.id] != path) return;
      final after = await _digestFile(path);
      if (!mounted || before != after || _filePaths[paper.id] != path ||
          (formVersion != null && formVersion != _formFingerprint())) {
        _message('Nội dung tài liệu đã thay đổi. Vui lòng mở lại bản mới.',
          tone: VcoreNoticeTone.warning);
        return;
      }
      if (_reviewedIds.contains(paper.id) &&
          _reviewedDigests[paper.id] == after) {
        // Already acknowledged this exact file version; no second popup.
        return;
      }
      final confirmed = await showVcoreActionDialog<bool>(
        context: context,
        title: 'Xác nhận đã kiểm tra',
        content: 'Bạn đã xem và đối chiếu nội dung "${paper.name}" '
          'với thông tin đăng ký? Chỉ xác nhận nếu tài liệu đã hiển thị đúng.',
        leadingIcon: Icons.fact_check_outlined,
        actions: const <VcoreDialogAction<bool>>[
          VcoreDialogAction<bool>(label: 'Xem lại', value: false,
            tone: VcoreDialogActionTone.secondary),
          VcoreDialogAction<bool>(label: 'Đã kiểm tra', value: true,
            tone: VcoreDialogActionTone.primary),
        ],
      );
      if (confirmed != true || !mounted || _filePaths[paper.id] != path) return;
      if (await _digestFile(path) != after) {
        _message('Tệp đã thay đổi. Bạn cần kiểm tra bản mới.',
          tone: VcoreNoticeTone.warning);
        return;
      }
      setState(() {
        _reviewedIds.add(paper.id);
        _reviewedDigests[paper.id] = after;
      });
    } catch (_) {
      if (mounted) _message('Không mở được bản xem trước. '
        'Hãy thử mở bằng ứng dụng Office hoặc gắn tệp khác.',
        tone: VcoreNoticeTone.warning);
    }
  }

  bool _canContinueAttachments() {
    final procedure = _selectedProcedure;
    if (procedure == null || _paperBusy.isNotEmpty) return false;
    if (procedure.papers.any((paper) =>
        paper.isRequired && !_files.containsKey(paper.id))) return false;
    for (final id in _files.keys) {
      if (!_reviewedIds.contains(id)) return false;
      if (_live && (_filePaths[id] ?? '').isEmpty) return false;
      if (_autoAttachedIds.contains(id) &&
          _generatedFingerprints[id] != _formFingerprint()) return false;
    }
    return true;
  }

  void _startForm() {
    ++_formRequestSerial;
    ++_generatedRequestSerial;
    for (final input in _extraInputs.values) { input.dispose(); }
    _extraInputs.clear();
    _formConfig = const OneDoorFormConfiguration();
    _formConfigError = null;
    _formConfigLoading = _live;
    _savedFormValues = <String, String>{};
    _studentFormValues = <String, String>{};
    _selectedReasonId = null;
    _localOtherSelected = false;
    _autoAttachedIds.clear();
    _reviewedIds.clear();
    _reviewedDigests.clear();
    _generatedFingerprints.clear();
    _failedAutoPapers.clear();
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
    if (_live) _loadFormConfiguration();
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
    if (mounted) {
      setState(() => _quantity = next);
      _invalidatePreviewReceipts();
    }
  }

  Future<void> _editQuantity() async {
    final input = TextEditingController(text: '$_quantity');
    try {
      final approved = await showVcoreActionDialog<bool>(
        context: context,
        title: 'Số lượng bản',
        content: 'Nhập số bản kết quả bạn cần nhận (tối thiểu 1).',
        leadingIcon: Icons.copy_all_outlined,
        extraContent: TextField(
          controller: input,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: StudentServiceUI.field('Nhập số bản'),
        ),
        actions: const <VcoreDialogAction<bool>>[
          VcoreDialogAction<bool>(label: 'Quay lại', value: false,
            tone: VcoreDialogActionTone.secondary),
          VcoreDialogAction<bool>(label: 'Áp dụng', value: true,
            tone: VcoreDialogActionTone.primary),
        ],
      );
      if (approved != true || !mounted) return;
      final selected = int.tryParse(input.text.trim());
      if (selected == null || selected < 1) {
        _message('Số lượng bản phải là số nguyên lớn hơn 0.',
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
            warnings: <String>['Chưa có đủ thông tin cá nhân; vui lòng kiểm tra và bổ sung.'],
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
        'YeuCau': _wordYeuCau,
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
      merged['YeuCau'] = _wordYeuCau;
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
              'Cập nhật tờ đơn nếu muốn tạo lại với thông tin mới.'
            : prefill.usedLiveProfile ? '$summary Vui lòng kiểm tra thông tin của bạn.'
              : (prefill.values['MaSV'] ?? '').trim().isNotEmpty
                ? '$summary Bạn có thể kiểm tra và cập nhật thông tin.'
                : '$summary Một số thông tin còn thiếu; vui lòng bổ sung.',
          onReloadFromOneVnu: Globals().token.trim().isNotEmpty
            ? () => const OneDoorStudentPrefillService().load() : null,
        )),
      );
      if (!mounted || result == null) return;
      setState(() {
        final previous = _filePaths[paper.id];
        _letterDrafts[paper.id] = result.draft;
        _reviewedIds.remove(paper.id);
        _reviewedDigests.remove(paper.id);
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
      // A GET /da-dien does not include the student's current form values.
      // For a filled preview, POST the exact draft values used in Step 1.
      final List<int> documentBytes;
      final String documentExtension;
      if (prefilled) {
        final formApi = _formApi;
        if (formApi == null) throw StateError(
          'Chưa thể tạo tài liệu lúc này. Vui lòng thử lại.');
        final values = _formVariables();
        OneDoorApiDebug.instance.note('Kiểm tra dữ liệu điền Word',
          <String, dynamic>{
            'idGiayTo': paper.id,
            'YeuCau': values['YeuCau'] ?? '',
            'YeuCauSource': _requestSourceForDebug,
            'SelectedReasonId': _selectedReasonId,
            'LocalOtherSelected': _localOtherSelected,
            'keys': values.keys.toList()..sort(),
            'api': 'POST /api/v1/files/giay-to-mau/{idGiayTo}/da-dien',
          });
        final generated = await formApi.generate(paper.id, values);
        documentBytes = generated.bytes;
        documentExtension = generated.extension;
      } else {
        final original = await repo.downloadPaperTemplate(paper.id);
        documentBytes = original.bytes;
        documentExtension = original.extension;
      }
      final directory = await getTemporaryDirectory();
      final safeId = paper.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${directory.path}${Platform.pathSeparator}'
          'Ban_${prefilled ? 'da_dien' : 'mau'}_${safeId}_${DateTime.now().microsecondsSinceEpoch}.${documentExtension}');
      await file.writeAsBytes(documentBytes, flush: true);
      if (!mounted) return;
      if (saveCopy) {
        // Must not delete the temp copy immediately: the native share target
        // may still be importing it, and saving a copy is not an upload.
        await OneDoorAttachmentPreview.shareFile(context,
          path: file.path, title: paper.name);
      } else {
        // Reliable read-only preview first; full Word edits belong in Office.
        await OneDoorAttachmentPreview.open(context, path: file.path,
          title: '${prefilled ? 'Bản đã điền' : 'Mẫu'}: ${paper.name}',
          allowDocxEditing: false);
        if (!<String>{'doc', 'xls'}.contains(documentExtension)) {
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

  /// V26 attachment source sheet, styled like the other ONEVNU sheets.
  Future<void> _chooseAttachmentSource(String paperId,
      {bool supplement = false}) async {
    if (!mounted || _submitting) return;
    final choice = await showModalBottomSheet<_DoorAttachmentSource>(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 38, height: 4,
            decoration: BoxDecoration(color: StudentServiceUI.line,
              borderRadius: BorderRadius.circular(3)))),
          const SizedBox(height: 18),
          const Text('Đính kèm giấy tờ', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: StudentServiceUI.ink)),
          const SizedBox(height: 5),
          const Text('Chụp ảnh, chọn ảnh có sẵn hoặc chọn tệp hoàn chỉnh.',
            style: TextStyle(fontSize: 13,
              color: StudentServiceUI.secondary)),
          const SizedBox(height: 14),
          for (final entry in <(_DoorAttachmentSource, IconData, String)>[
            (_DoorAttachmentSource.camera, Icons.camera_alt_outlined,
              'Chụp ảnh giấy tờ'),
            (_DoorAttachmentSource.gallery, Icons.photo_library_outlined,
              'Chọn ảnh từ thư viện'),
            (_DoorAttachmentSource.files, Icons.folder_open_rounded,
              'Chọn PDF / Word / Excel / ảnh'),
          ])
            Padding(padding: const EdgeInsets.only(bottom: 7),
              child: Material(color: const Color(0xFFF3F8F5),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(sheetContext, entry.$1),
                  child: Padding(padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                    child: Row(children: [
                      Icon(entry.$2, color: StudentServiceUI.green, size: 23),
                      const SizedBox(width: 13),
                      Expanded(child: Text(entry.$3,
                        style: const TextStyle(fontSize: 14,
                          color: StudentServiceUI.ink,
                          fontWeight: FontWeight.w600))),
                      const Icon(Icons.chevron_right_rounded,
                        color: StudentServiceUI.secondary),
                    ])),
                ),
              ),
            ),
        ]),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _DoorAttachmentSource.camera:
        await _pickPhoto(paperId, ImageSource.camera, supplement: supplement);
        break;
      case _DoorAttachmentSource.gallery:
        await _pickPhoto(paperId, ImageSource.gallery, supplement: supplement);
        break;
      case _DoorAttachmentSource.files:
        await _pickFile(paperId, supplement: supplement);
        break;
      case null:
        break;
    }
  }

  Future<void> _pickPhoto(String paperId, ImageSource source,
      {bool supplement = false}) async {
    if (_submitting || _paperBusy.contains(paperId)) return;
    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        imageQuality: 92,
        requestFullMetadata: false,
      );
      if (!mounted || photo == null) return;
      final file = File(photo.path);
      if (!await file.exists()) throw StateError('Không tìm thấy ảnh.');
      final size = await file.length();
      if (size < 1 || size > 10 * 1024 * 1024) {
        _message('Ảnh trống hoặc vượt quá 10 MB. Chọn ảnh nhỏ hơn.',
          tone: VcoreNoticeTone.warning);
        return;
      }
      // Detect actual content, do not falsely label a HEIC photo as JPEG.
      final reader = await file.open();
      late final List<int> signature;
      try {
        signature = await reader.read(12);
      } finally {
        await reader.close();
      }
      final jpeg = signature.length >= 3 && signature[0] == 0xff &&
          signature[1] == 0xd8 && signature[2] == 0xff;
      final png = signature.length >= 8 && signature[0] == 0x89 &&
          signature[1] == 0x50 && signature[2] == 0x4e &&
          signature[3] == 0x47;
      if (!jpeg && !png) {
        _message('Định dạng ảnh chưa hỗ trợ. Hãy chọn JPG/PNG hoặc tệp PDF.',
          tone: VcoreNoticeTone.warning);
        return;
      }
      final directory = await getTemporaryDirectory();
      final safeId = paperId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final name = 'onevnu_anh_${safeId}_'
          '${DateTime.now().microsecondsSinceEpoch}.${jpeg ? 'jpg' : 'png'}';
      final staged = File('${directory.path}${Platform.pathSeparator}$name');
      await file.copy(staged.path);
      if (!mounted) {
        await staged.delete().catchError((Object _) => staged);
        return;
      }
      final oldPath = (supplement ? _supplementPaths : _filePaths)[paperId];
      setState(() {
        if (!supplement) {
          _reviewedIds.remove(paperId);
          _reviewedDigests.remove(paperId);
          _autoAttachedIds.remove(paperId);
          _generatedFingerprints.remove(paperId);
          _failedAutoPapers.remove(paperId);
          _letterDrafts.remove(paperId);
          _editedWordWizardContext.remove(paperId);
        }
        _managedPhotoPaths.add(staged.path);
        if (supplement) {
          _supplementReviewedDigests.remove(paperId);
          _supplementGeneratedFingerprints.remove(paperId);
        }
        (supplement ? _supplementFiles : _files)[paperId] = name;
        (supplement ? _supplementPaths : _filePaths)[paperId] = staged.path;
      });
      if (oldPath != staged.path) {
        _forgetGeneratedPdf(oldPath);
        _forgetGeneratedWord(oldPath);
        _forgetManagedPhoto(oldPath);
      }
    } catch (_) {
      if (mounted) _message('Không thể gắn ảnh. Kiểm tra quyền Camera/Ảnh '
        'trong cài đặt thiết bị rồi thử lại.', tone: VcoreNoticeTone.warning);
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
        _reviewedIds.remove(paperId);
        _reviewedDigests.remove(paperId);
        _autoAttachedIds.remove(paperId);
        _generatedFingerprints.remove(paperId);
        _failedAutoPapers.remove(paperId);
        _forgetGeneratedPdf(_filePaths[paperId]);
        _forgetGeneratedWord(_filePaths[paperId]);
        _forgetManagedPhoto(_filePaths[paperId]);
        _editedWordWizardContext.remove(paperId);
      }
      setState(() {
        if (supplement) {
          _supplementReviewedDigests.remove(paperId);
          _supplementGeneratedFingerprints.remove(paperId);
        }
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

  /// No artificial timer or second confirmation sheet. Preview/acknowledgement
  /// happens on each file row and is invalidated whenever the file changes.
  Future<void> _confirmAttachmentStep() async {
    if (_submitting || _currentStep != _DoorFormStep.attachments) return;
    if (!_canContinueAttachments()) {
      _message('Hãy đính kèm đủ giấy tờ và xem trước, xác nhận từng tệp '
        'trước khi tiếp tục.', tone: VcoreNoticeTone.warning);
      return;
    }
    for (final paper in _selectedProcedure!.papers) {
      final path = _filePaths[paper.id];
      if (!_files.containsKey(paper.id)) continue;
      if (_live && (path == null || path.isEmpty)) return;
      if (path == null) continue; // Mock entries use their display name.
      try {
        final file = File(path);
        final bytes = await file.length();
        if (bytes < 1 || bytes > 10 * 1024 * 1024) {
          throw StateError('size');
        }
      } catch (_) {
        _message('Không đọc được tệp ${paper.name}. Hãy chọn lại.',
          tone: VcoreNoticeTone.warning);
        return;
      }
    }
    if (!mounted || !_canContinueAttachments()) return;
    if (!await _checkReviewedFileVersions()) return;
    if (mounted && _canContinueAttachments()) _advanceFormStep();
  }

  Future<void> _submit() async {
    if (_submitting || _selectedProcedure == null) return;
    final p = _selectedProcedure!;
    if (!_validateDynamicFields()) return;
    if (p.papers.isNotEmpty && !_canContinueAttachments()) {
      _message('Vui lòng xem trước và xác nhận tất cả tệp đã đính kèm.',
        tone: VcoreNoticeTone.warning);
      return;
    }
    if (_files.isNotEmpty && !await _checkReviewedFileVersions()) return;
    if (!_validateRequestDetails()) return;
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
      entry.value != '${_quantity}::${_wordYeuCau}');
    if (staleWord) {
      _message('Yêu cầu hoặc số lượng đã thay đổi sau khi sửa file Word. '
        'Hãy mở lại Word và lưu bản cập nhật trước khi nộp.',
        tone: VcoreNoticeTone.warning);
      return;
    }
    final staleLetter = _letterDrafts.entries.any((entry) =>
      _filePaths.containsKey(entry.key) &&
      (entry.value.values['SoLuongBan'] != '$_quantity' ||
       entry.value.values['YeuCau'] != _wordYeuCau ||
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
      if (_live) {
        // API submit reads this snapshot when building multipart FormData.
        _oneDoorApi?.submissionFormValues = _formVariables();
        _oneDoorApi?.submissionReasonId = _selectedReasonId;
      }
      final record = await _repo.submit(
        procedure: p, requestText: _effectiveRequest, deliveryMethod: _delivery,
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
    } finally {
      _oneDoorApi?.submissionFormValues = <String, String>{};
      _oneDoorApi?.submissionReasonId = null;
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


  // The form API returns a wrapped JSON object. Validate its shape instead
  // of assuming a particular client-side cache or training DB model.
  Map<String, dynamic> _supplementObject(dynamic raw) {
    if (raw is! Map) throw const FormatException('Invalid record detail');
    var value = Map<String, dynamic>.from(raw);
    for (var i = 0; i < 2; i++) {
      final next = value['data'] ?? value['result'];
      if (next is! Map) break;
      value = Map<String, dynamic>.from(next);
    }
    return value;
  }

  List<Map<String, dynamic>> _supplementList(dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw.whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item)).toList();
  }

  void _clearSupplementDraft() {
    for (final control in _supplementInputs.values) {
      control.dispose();
    }
    _supplementInputs.clear();
    for (final path in _supplementPaths.values) {
      _forgetGeneratedPdf(path);
      _forgetGeneratedWord(path);
      _forgetManagedPhoto(path);
    }
    _supplementPaths.clear();
    _supplementFiles.clear();
    _supplementReviewedDigests.clear();
    _supplementGeneratedFingerprints.clear();
    _supplementMissingRequiredPapers.clear();
    _supplementCurrentFiles.clear();
    _supplementAutoPaperIds.clear();
    _supplementFields = <_OneDoorSupplementField>[];
    _supplementCurrentValues = <String, String>{};
    _supplementPapers = <OneDoorPaper>[];
    _supplementNotices = <_OneDoorSupplementNotice>[];
    _supplementSavedRequest = '';
    _supplementSavedReason = '';
    _supplementSavedDelivery = '';
    _supplementSavedQuantity = null;
    _supplementCode = '';
    _supplementSubmittedAt = '';
    _supplementPaidAmount = null;
    _supplementProcedureId = '';
    _supplementNote.clear();
  }

  // Do not send unchanged/empty fields: the backend preserves submitted
  // values for fields not present in GiaTriBieuMau on /bo-sung.
  Map<String, String> _supplementChangedValues() {
    final changed = <String, String>{};
    for (final field in _supplementFields) {
      final replacement = _supplementInputs[field.key]?.text.trim() ?? '';
      if (replacement.isNotEmpty && replacement != field.currentValue.trim()) {
        changed[field.key] = replacement;
      }
    }
    return changed;
  }

  Future<void> _openSupplement() async {
    final record = _selectedRecord;
    if (record == null || _submitting) return;
    final serial = ++_supplementRequestSerial;
    _clearSupplementDraft();
    setState(() {
      _page = _DoorPage.supplement;
      _supplementLoading = _live;
      _supplementError = null;
    });
    if (!_live) {
      setState(() {
        _supplementPapers = record.procedure.papers;
        _supplementSavedRequest = record.requestText;
        _supplementSavedDelivery = record.deliveryMethod;
        _supplementSavedQuantity = record.quantity;
        _supplementCode = record.id;
        _supplementSubmittedAt = _date(record.createdAt);
        _supplementLoading = false;
      });
      return;
    }
    final api = _oneDoorApi;
    if (api == null) {
      setState(() {
        _supplementLoading = false;
        _supplementError = 'Kh\u00f4ng m\u1edf \u0111\u01b0\u1ee3c h\u1ed3 s\u01a1. Vui l\u00f2ng th\u1eed l\u1ea1i.';
      });
      return;
    }
    try {
      // Get the CURRENT submitted values and pending requests, not the draft
      // or global /bien-bieu-mau/cua-toi values of another procedure.
      final data = _supplementObject(await api.record(record.id));
      if (data['coTheBoSung'] != true) {
        throw StateError('NOT_ALLOWED');
      }
      final procedureId = (data['idThuTuc'] ?? record.procedure.id)
          .toString().trim();
      OneDoorFormConfiguration? config;
      if (_formApi != null && procedureId.isNotEmpty) {
        try {
          config = await _formApi!.load(procedureId);
        } catch (_) {
          // Submitted values in the record remain authoritative. No guessed
          // input schema or other procedure's cached values are substituted.
        }
      }
      if (!mounted || serial != _supplementRequestSerial ||
          _selectedRecord?.id != record.id ||
          _page != _DoorPage.supplement) return;

      const reserved = <String>{'yeucau', 'idhinhthucnhanketqua',
        'idthutuc', 'soluongban', 'idlydo'};
      final submitted = <String, String>{};
      final fieldInfo = <String, _OneDoorSupplementField>{};
      for (final entry in _supplementList(data['giaTriBieuMaus'])) {
        final key = (entry['key'] ?? '').toString().trim();
        if (key.isEmpty || reserved.contains(key.toLowerCase())) continue;
        final value = (entry['giaTri'] ?? '').toString();
        submitted[key] = value;
        fieldInfo[key.toLowerCase()] = _OneDoorSupplementField(
          key: key,
          label: (entry['nhan'] ?? key).toString().trim().isEmpty
              ? key : (entry['nhan'] ?? key).toString().trim(),
          type: (entry['loai'] ?? 'text').toString().toLowerCase(),
          hint: '',
          currentValue: value,
        );
      }
      for (final field in config?.fields ?? const <OneDoorDynamicField>[]) {
        final id = field.key.toLowerCase();
        if (field.key.isEmpty || reserved.contains(id)) continue;
        final saved = fieldInfo[id];
        final key = saved?.key ?? field.key;
        fieldInfo[id] = _OneDoorSupplementField(
          key: key,
          label: field.label.isNotEmpty ? field.label
              : saved?.label ?? key,
          type: field.type.isNotEmpty ? field.type
              : saved?.type ?? 'text',
          hint: field.hint,
          currentValue: saved?.currentValue ?? '',
        );
      }
      final papers = <OneDoorPaper>[];
      final existingFiles = <String, String>{};
      final requiredMissing = <String>{};
      final docxPapers = <String>{...?(config?.autoPaperIds)};
      for (final paper in _supplementList(data['giayToNops'])) {
        final id = (paper['idGiayTo'] ?? '').toString().trim();
        if (id.isEmpty) continue;
        final title = (paper['tenGiayTo'] ?? '').toString().trim();
        final required = paper['batBuoc'] == true;
        final uploaded = paper['daNop'] == true;
        final fileName = (paper['tenFile'] ?? '').toString().trim();
        papers.add(OneDoorPaper(id, title.isEmpty ? 'Gi\u1ea5y t\u1edd' : title,
          isRequired: required));
        if (uploaded && fileName.isNotEmpty) existingFiles[id] = fileName;
        if (required && !uploaded) requiredMissing.add(id);
        if (paper['tuDienBieuMau'] == true) docxPapers.add(id);
      }
      final notices = <_OneDoorSupplementNotice>[];
      for (final entry in _supplementList(data['yeuCauBoSungs'])) {
        final message = (entry['noiDung'] ?? '').toString().trim();
        if (message.isEmpty) continue;
        notices.add(_OneDoorSupplementNotice(
          message: message,
          author: (entry['nguoiYeuCau'] ?? '').toString().trim(),
          date: (entry['ngayYeuCau'] ?? '').toString().trim(),
          answered: (entry['ngayBoSung'] ?? '').toString().trim().isNotEmpty,
        ));
      }
      for (final field in fieldInfo.values) {
        _supplementInputs[field.key] = TextEditingController();
      }
      setState(() {
        _supplementCurrentValues = submitted;
        _supplementFields = fieldInfo.values.toList();
        _supplementPapers = papers;
        _supplementCurrentFiles.addAll(existingFiles);
        _supplementMissingRequiredPapers.addAll(requiredMissing);
        _supplementAutoPaperIds.addAll(docxPapers);
        _supplementNotices = notices.reversed.toList();
        _supplementSavedRequest =
            (data['yeuCau'] ?? record.requestText).toString().trim();
        _supplementSavedReason = (data['lyDo'] ?? '').toString().trim();
        final submittedDelivery =
            (data['hinhThucNhanKetQua'] ?? '').toString().trim();
        _supplementSavedDelivery = submittedDelivery.isNotEmpty
            ? submittedDelivery : record.deliveryMethod;
        final quantityRaw = data['soLuongBan'];
        _supplementSavedQuantity = quantityRaw is num
            ? quantityRaw.toInt()
            : int.tryParse('${quantityRaw ?? ''}') ?? record.quantity;
        _supplementCode = (data['maDangKy'] ?? '').toString().trim();
        final submittedDate = (data['ngayDangKy'] ?? '').toString().trim();
        _supplementSubmittedAt = submittedDate.isNotEmpty
            ? _supplementDate(submittedDate) : _date(record.createdAt);
        final amountRaw = data['thanhTien'];
        _supplementPaidAmount = amountRaw is num
            ? amountRaw.toInt() : int.tryParse('${amountRaw ?? ''}');
        _supplementProcedureId = procedureId;
        _supplementLoading = false;
        _supplementError = null;
      });
    } catch (error) {
      if (!mounted || serial != _supplementRequestSerial ||
          _selectedRecord?.id != record.id ||
          _page != _DoorPage.supplement) return;
      setState(() {
        _supplementLoading = false;
        _supplementError = error is StateError && error.message == 'NOT_ALLOWED'
            ? 'H\u1ed3 s\u01a1 hi\u1ec7n kh\u00f4ng \u0111\u01b0\u1ee3c ph\u00e9p b\u1ed5 sung.'
            : 'Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c th\u00f4ng tin b\u1ed5 sung. Vui l\u00f2ng th\u1eed l\u1ea1i.';
      });
    }
  }

  Future<void> _reviewSupplementPaper(OneDoorPaper paper) async {
    final path = _supplementPaths[paper.id];
    if (path == null || path.isEmpty || _submitting) return;
    try {
      final before = await _digestFile(path);
      if (!mounted || _supplementPaths[paper.id] != path) return;
      final viewed = await OneDoorAttachmentPreview.openForReview(context,
        path: path, title: paper.name);
      if (!mounted || !viewed || _supplementPaths[paper.id] != path) return;
      final after = await _digestFile(path);
      if (before != after) {
        _message('T\u1ec7p \u0111\u00e3 thay \u0111\u1ed5i. H\u00e3y m\u1edf xem l\u1ea1i.',
          tone: VcoreNoticeTone.warning);
        return;
      }
      if (_supplementReviewedDigests[paper.id] == after) return;
      final confirmed = await showVcoreActionDialog<bool>(
        context: context,
        title: 'X\u00e1c nh\u1eadn \u0111\u00e3 ki\u1ec3m tra',
        content: 'B\u1ea1n \u0111\u00e3 ki\u1ec3m tra n\u1ed9i dung t\u1ec7p m\u1edbi \u0111\u00ednh k\u00e8m?',
        leadingIcon: Icons.fact_check_outlined,
        actions: const <VcoreDialogAction<bool>>[
          VcoreDialogAction<bool>(label: 'Xem l\u1ea1i', value: false,
            tone: VcoreDialogActionTone.secondary),
          VcoreDialogAction<bool>(label: '\u0110\u00e3 ki\u1ec3m tra', value: true,
            tone: VcoreDialogActionTone.primary),
        ],
      );
      if (confirmed != true || !mounted ||
          _supplementPaths[paper.id] != path) return;
      if (await _digestFile(path) != after) return;
      setState(() => _supplementReviewedDigests[paper.id] = after);
    } catch (_) {
      if (mounted) _message('Kh\u00f4ng m\u1edf \u0111\u01b0\u1ee3c t\u1ec7p. Vui l\u00f2ng ch\u1ecdn l\u1ea1i.',
        tone: VcoreNoticeTone.warning);
    }
  }

  // Optional: only an explicit tap creates a new document. Changing values
  // NEVER silently replaces the officially submitted attachment.
  Future<void> _regenerateSupplementWord(OneDoorPaper paper) async {
    final record = _selectedRecord;
    final formApi = _formApi;
    if (record == null || formApi == null || _submitting ||
        _paperBusy.contains(paper.id)) return;
    final serial = _supplementRequestSerial;
    final changedFingerprint = jsonEncode(_supplementChangedValues());
    setState(() => _paperBusy.add(paper.id));
    try {
      final values = <String, String>{};
      try {
        final profile = await const OneDoorStudentPrefillService().load();
        values.addAll(profile.values);
      } catch (_) { /* The submitted values remain authoritative. */ }
      values.addAll(_supplementCurrentValues);
      values.addAll(_supplementChangedValues());
      // Provider rule: when a reason is selected, it fills {YeuCau} in Word.
      // Keep the originally submitted request separately in the application.
      values['YeuCau'] = _supplementSavedReason.isNotEmpty &&
          !_isOtherReason(_supplementSavedReason)
          ? _supplementSavedReason : _supplementSavedRequest;
      values['SoLuongBan'] =
          '${_supplementSavedQuantity ?? record.quantity}';
      values['TenThuTuc'] = record.procedure.name;
      if (record.procedure.unitName.trim().isNotEmpty) {
        values['TenDonVi'] = record.procedure.unitName;
      }
      if (_supplementProcedureId.isEmpty) {
        throw const FormatException('Missing procedure ID');
      }
      final result = await formApi.generate(paper.id, values);
      if (!mounted || serial != _supplementRequestSerial ||
          _page != _DoorPage.supplement ||
          _selectedRecord?.id != record.id) return;
      final root = await getTemporaryDirectory();
      final safeId = paper.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final target = File('${root.path}${Platform.pathSeparator}'
        'onevnu_bo_sung_${safeId}_${DateTime.now().microsecondsSinceEpoch}'
        '.${result.extension}');
      await target.writeAsBytes(result.bytes, flush: true);
      if (!mounted || serial != _supplementRequestSerial ||
          _page != _DoorPage.supplement) {
        await target.delete();
        return;
      }
      final previous = _supplementPaths[paper.id];
      setState(() {
        _supplementPaths[paper.id] = target.path;
        _supplementFiles[paper.id] = target.path.split(Platform.pathSeparator).last;
        _supplementReviewedDigests.remove(paper.id);
        _supplementGeneratedFingerprints[paper.id] = changedFingerprint;
        if (result.extension == 'pdf') {
          _generatedPdfPaths.add(target.path);
        } else {
          _generatedWordPaths.add(target.path);
        }
      });
      _forgetGeneratedWord(previous);
      _forgetGeneratedPdf(previous);
      _forgetManagedPhoto(previous);
      await _reviewSupplementPaper(paper);
    } catch (_) {
      if (mounted && serial == _supplementRequestSerial) {
        _message('Ch\u01b0a th\u1ec3 t\u1ea1o l\u1ea1i gi\u1ea5y t\u1edd. Vui l\u00f2ng ch\u1ecdn t\u1ec7p kh\u00e1c.',
          tone: VcoreNoticeTone.warning);
      }
    } finally {
      if (mounted) setState(() => _paperBusy.remove(paper.id));
    }
  }

  Future<void> _sendSupplement() async {
    final record = _selectedRecord;
    if (record == null || _submitting || _supplementLoading ||
        _supplementError != null) return;
    final note = _supplementNote.text.trim();
    final changes = _supplementChangedValues();
    if (note.isEmpty && changes.isEmpty && _supplementPaths.isEmpty) {
      _message('H\u00e3y c\u1eadp nh\u1eadt th\u00f4ng tin, ch\u1ecdn t\u1ec7p ho\u1eb7c nh\u1eadp ghi ch\u00fa.',
        tone: VcoreNoticeTone.warning);
      return;
    }
    if (note.length > 1000 || jsonEncode(changes).length > 100000) {
      _message('N\u1ed9i dung b\u1ed5 sung qu\u00e1 d\u00e0i.',
        tone: VcoreNoticeTone.warning);
      return;
    }
    for (final paperId in _supplementMissingRequiredPapers) {
      if (!_supplementPaths.containsKey(paperId)) {
        _message('Vui l\u00f2ng g\u1eafn gi\u1ea5y t\u1edd b\u1eaft bu\u1ed9c c\u00f2n thi\u1ebfu.',
          tone: VcoreNoticeTone.warning);
        return;
      }
    }
    if (_live && _supplementFiles.keys.any((id) =>
        !_supplementPaths.containsKey(id))) {
      _message('Vui l\u00f2ng ch\u1ecdn l\u1ea1i t\u1ec7p b\u1ed5 sung.',
        tone: VcoreNoticeTone.warning);
      return;
    }
    final changedSignature = jsonEncode(changes);
    for (final entry in _supplementGeneratedFingerprints.entries) {
      if (_supplementPaths.containsKey(entry.key) &&
          entry.value != changedSignature) {
        _message('Th\u00f4ng tin \u0111\u00e3 thay \u0111\u1ed5i. H\u00e3y t\u1ea1o l\u1ea1i Word m\u1edbi.',
          tone: VcoreNoticeTone.warning);
        return;
      }
    }
    for (final entry in _supplementPaths.entries) {
      try {
        final digest = await _digestFile(entry.value);
        if (_supplementReviewedDigests[entry.key] != digest) {
          _message('H\u00e3y xem v\u00e0 x\u00e1c nh\u1eadn t\u1ec7p m\u1edbi tr\u01b0\u1edbc khi g\u1eedi.',
            tone: VcoreNoticeTone.warning);
          return;
        }
      } catch (_) {
        _message('T\u1ec7p b\u1ed5 sung kh\u00f4ng c\u00f2n h\u1ee3p l\u1ec7.',
          tone: VcoreNoticeTone.warning);
        return;
      }
    }
    setState(() => _submitting = true);
    var accepted = false;
    try {
      if (_live) {
        final api = _oneDoorApi;
        if (api == null) throw StateError('Missing One Door session');
        // Only changed form fields + newly selected files. Unchanged old
        // attachments remain stored on the server and are NOT re-uploaded.
        await api.supplement(record.id,
          note: note,
          changedValues: changes,
          filesByPaperId: Map<String, String>.from(_supplementPaths));
      } else {
        await _repo.supplement(record, note, _supplementFiles);
      }
      accepted = true;
    } catch (_) {
      if (mounted) {
        _message('Kh\u00f4ng th\u1ec3 g\u1eedi b\u1ed5 sung. Vui l\u00f2ng th\u1eed l\u1ea1i.',
          tone: VcoreNoticeTone.error);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!accepted || !mounted) return;
    ++_supplementRequestSerial;
    _clearSupplementDraft();
    setState(() => _page = _DoorPage.record);
    _message('\u0110\u00e3 g\u1eedi th\u00f4ng tin b\u1ed5 sung.', tone: VcoreNoticeTone.success);
    // A successful POST is final even if this GET or list refresh fails.
    // Never retry the write automatically and risk duplicate submissions.
    try {
      final refreshed = await _repo.myRecords();
      if (mounted) setState(() => _records = refreshed);
    } catch (_) { /* Keep the accepted state. */ }
    if (mounted && _selectedRecord?.id == record.id) {
      await _openRecord(record);
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

  // V29.2 MAX WIDTH NAVBAR: do not modify the shared headers of other modules.
  PreferredSizeWidget _oneDoorFullTitleBar(String title) {
    const double height = 68;
    const double reserve = 56;
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.black,
      elevation: 0.5,
      shadowColor: StudentServiceUI.line,
      toolbarHeight: height,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      centerTitle: false,
      title: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: reserve),
                child: Center(
                  child: Semantics(
                    header: true,
                    label: title,
                    excludeSemantics: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0, top: 0, bottom: 0, width: reserve,
              child: Align(
                alignment: Alignment.centerLeft,
                child: VnuPressMotion(
                  child: BackButton(color: Colors.black, onPressed: _back),
                ),
              ),
            ),
            if (_page == _DoorPage.overview)
              Positioned(
                right: 4, top: 0, bottom: 0, width: reserve - 4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: VnuPressMotion(
                    child: IconButton(
                      onPressed: _load,
                      tooltip: 'Tải lại',
                      icon: const Icon(Icons.refresh,
                        color: Colors.black, size: 23),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
        // V29.2: true-centred, maximum safe title width, with no debug action.
        // A FittedBox shows the whole module title on compact phones instead
        // of letting the action reserve clip "Thủ tục hành chính".
        appBar: _oneDoorFullTitleBar(pageTitle),
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
                    ? 'Chưa thể hiển thị đầy đủ danh sách đơn vị. '
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
              child: Text('Các hình thức nhận kết quả đang áp dụng cho thủ tục này.',
                style: TextStyle(fontSize: 12,
                  color: StudentServiceUI.secondary))),
          if (_live && deliveryNames.isEmpty)
            Padding(padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Row(children: [
                Expanded(child: Text(
                  _deliveryWarning ?? 'Chưa có hình thức nhận kết quả hợp lệ. '
                  'Vui lòng thử tải lại.',
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

  // V25: Preserve the original four-part student guidance above the new
  // preview requirement. Old action names are updated to the compact row.
  Widget _documentEditingAdvice() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E9),
      border: Border.all(color: const Color(0xFFE8C77D)),
      borderRadius: BorderRadius.circular(12),
    ),
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
          Text('1. Kiểm tra thông tin: Một số thông tin có thể đã được '
            'điền sẵn trên giấy tờ. Bạn cần đối chiếu '
            'họ tên, mã sinh viên, ngày sinh, CCCD, lớp, khoa, ngành, '
            'email và số điện thoại; bổ sung hoặc sửa ngay thông tin '
            'còn thiếu hoặc chưa chính xác.',
            style: TextStyle(fontSize: 12.7, height: 1.5,
              color: Color(0xFF795215))),
          SizedBox(height: 9),
          Text('2. Sửa và chia sẻ: Tài liệu Word/Excel có thể khó chỉnh sửa '
            'trên điện thoại, nhất là biểu mẫu có bảng. Bạn có thể sử dụng '
            'biểu tượng Chia sẻ ngay cạnh tệp để gửi qua Zalo hoặc máy tính, '
            'mở bằng phần mềm Office để sửa. Sau đó dùng biểu tượng kẹp giấy '
            'trên cùng hàng để gắn lại BẢN HOÀN CHỈNH. Việc chia sẻ không '
            'tự thay thế tệp đang đính kèm trong OneVNU.',
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

  // The second, short warning stays BELOW the original warning (not replacing it).
  Widget _mandatoryPreviewWarning() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF9E7),
      border: Border.all(color: const Color(0xFFF5D68B)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline_rounded,
        size: 21, color: Color(0xFF9B6713)),
      SizedBox(width: 9),
      Expanded(child: Text(
        'Bạn cần mở tệp đã gắn ít nhất một lần và xác nhận nội dung '
        'trước khi tiếp tục.',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          height: 1.42, color: Color(0xFF795215)),
      )),
    ]),
  );

  /// V26 COMPACT FILE ROW + photo/camera/gallery source sheet.
  /// V25 COMPACT FILE ROW: one file line, four adjacent actions, one status.
  /// The same widget is also used by the supplement flow (without gating it).
  Widget _paperPicker(OneDoorPaper paper, Map<String, String> selected,
      VoidCallback pick) {
    final isMainForm = identical(selected, _files);
    final hasFile = selected.containsKey(paper.id);
    final loading = _paperBusy.contains(paper.id);
    final path = (isMainForm ? _filePaths : _supplementPaths)[paper.id];
    final reviewed = isMainForm && _reviewedIds.contains(paper.id);
    final canEdit = !_submitting && !loading;
    final fallback = isMainForm ? _failedAutoPapers[paper.id] : null;
    final attached = hasFile && path != null && path.isNotEmpty;

    void removeFile() {
      if (!canEdit) return;
      setState(() {
        selected.remove(paper.id);
        if (isMainForm) {
          _forgetGeneratedPdf(_filePaths[paper.id]);
          _forgetGeneratedWord(_filePaths[paper.id]);
          _forgetManagedPhoto(_filePaths[paper.id]);
          _filePaths.remove(paper.id);
          _autoAttachedIds.remove(paper.id);
          _generatedFingerprints.remove(paper.id);
          _reviewedIds.remove(paper.id);
          _reviewedDigests.remove(paper.id);
          _failedAutoPapers.remove(paper.id);
          _letterDrafts.remove(paper.id);
          _editedWordWizardContext.remove(paper.id);
        } else {
          _forgetManagedPhoto(_supplementPaths[paper.id]);
          _supplementPaths.remove(paper.id);
          _supplementReviewedDigests.remove(paper.id);
          _supplementGeneratedFingerprints.remove(paper.id);
        }
      });
    }

    Widget actionIcon(IconData icon, String tooltip,
        VoidCallback? onPressed, {Color? color}) => SizedBox(
      width: 37,
      height: 43,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        color: color ?? StudentServiceUI.green,
        disabledColor: StudentServiceUI.secondary,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 37, minHeight: 43),
        visualDensity: VisualDensity.compact,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 11),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: StudentServiceUI.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const Icon(Icons.attach_file_rounded,
              color: StudentServiceUI.green, size: 20),
            const SizedBox(width: 6),
            Expanded(child: Text(paper.name,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: StudentServiceUI.ink))),
            const SizedBox(width: 6),
            Text(paper.isRequired ? 'Bắt buộc' : 'Không bắt buộc',
              style: const TextStyle(fontSize: 10.5,
                color: StudentServiceUI.secondary)),
          ]),
          const SizedBox(height: 9),
          Material(
            color: const Color(0xFFF4F8F6),
            borderRadius: BorderRadius.circular(10),
            child: Row(children: [
              Expanded(child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: canEdit ? (hasFile
                  ? () => _previewAndConfirm(paper, supplement: !isMainForm)
                  : pick) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 12),
                  child: Row(children: [
                    Icon(hasFile ? Icons.description_outlined
                        : Icons.add_circle_outline_rounded,
                      size: 18, color: StudentServiceUI.green),
                    const SizedBox(width: 7),
                    Expanded(child: Text(
                      loading ? 'Đang chuẩn bị tệp...'
                        : hasFile ? selected[paper.id]!
                        : 'Chụp ảnh / chọn ảnh / chọn tệp',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.8,
                        color: hasFile ? StudentServiceUI.ink
                          : StudentServiceUI.secondary,
                        fontWeight: hasFile ? FontWeight.w500
                          : FontWeight.w400),
                    )),
                  ]),
                ),
              )),
              if (loading)
                const Padding(padding: EdgeInsets.symmetric(horizontal: 9),
                  child: SizedBox(width: 17, height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2)))
              else if (hasFile) ...[
                actionIcon(Icons.visibility_outlined, 'Xem trước tệp',
                  canEdit && attached
                    ? () => _previewAndConfirm(paper, supplement: !isMainForm)
                    : null),
                actionIcon(Icons.attach_file_rounded, 'Thay ảnh / gắn lại tệp',
                  canEdit ? pick : null),
                actionIcon(Icons.ios_share_outlined, 'Chia sẻ tệp',
                  canEdit && attached
                    ? () => OneDoorAttachmentPreview.shareFile(context,
                        path: path!, title: paper.name)
                    : null),
                actionIcon(Icons.close_rounded, 'Bỏ tệp',
                  canEdit ? removeFile : null,
                  color: StudentServiceUI.danger),
              ],
              const SizedBox(width: 3),
            ]),
          ),
          if (isMainForm && hasFile) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(reviewed ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
                color: reviewed ? StudentServiceUI.green
                  : const Color(0xFF9B6713), size: 15),
              const SizedBox(width: 5),
              Expanded(child: Text(reviewed
                  ? 'Đã xem trước và xác nhận'
                  : 'Chưa xem · Chạm tên tệp hoặc biểu tượng mắt để xem trước',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.2,
                  fontWeight: reviewed ? FontWeight.w600 : FontWeight.w400,
                  color: reviewed ? StudentServiceUI.green
                    : StudentServiceUI.secondary))),
            ]),
          ] else if (!hasFile && fallback != null) ...[
            const SizedBox(height: 6),
            Text(fallback, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.3,
                color: StudentServiceUI.caution)),
          ],
        ]),
      ),
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
              _DoorFormStep.attachments => 'Kiểm tra giấy tờ',
              _DoorFormStep.review => 'Kiểm tra thông tin',
            }, p.name),
          if (_currentStep == _DoorFormStep.request) ...[
            _dynamicFieldsWidget(),
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
                  if (value != null) setState(() {
                    _delivery = value;
                  });
                },
              )
else
              const Padding(padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Theo hướng dẫn của đơn vị. Chưa có lựa chọn '
                  'hình thức nhận kết quả cho thủ tục này.',
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
            _mandatoryPreviewWarning(),
            const SizedBox(height: 20),
            const Text('Tài liệu cần kiểm tra',
              style: TextStyle(color: StudentServiceUI.ink,
                fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 5),
            ...p.papers.map((paper) => _paperPicker(paper, _files,
                () => _chooseAttachmentSource(paper.id))),
          ] else ...[
            StudentInfoLine(label: 'Thủ tục', value: p.name),
            if (_hasReasonChoices &&
                (_selectedReasonId != null || _localOtherSelected))
              StudentInfoLine(label: 'Lý do / Mục đích',
                value: _selectedReasonLabel),
            StudentInfoLine(label: 'Nội dung yêu cầu',
              value: _effectiveRequest),
            StudentInfoLine(label: 'Nhận kết quả', value: _delivery),
            StudentInfoLine(label: 'Số lượng', value: '$_quantity bản'),
            StudentInfoLine(label: 'Tệp đính kèm', value: '${_files.length} tệp'),
            ..._formConfig.fields.where((f) => _extraInputs.containsKey(f.key))
              .map((f) => StudentInfoLine(label: f.label,
                value: _extraInputs[f.key]!.text.trim())),
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
            enabled: !_submitting && (_currentStep != _DoorFormStep.attachments ||
              _canContinueAttachments()),
            pressedScale: 0.962,
            child: SizedBox(height: 52, child: FilledButton(
            style: FilledButton.styleFrom(
              overlayColor: Colors.transparent,
              backgroundColor: StudentServiceUI.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _submitting ||
                (_currentStep == _DoorFormStep.attachments &&
                  !_canContinueAttachments()) ? null : () {
              if (_currentStep == _DoorFormStep.request) {
                if (!_validateDynamicFields()) return;
                if (!_validateRequestDetails()) return;
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
                ? 'Nộp hồ sơ' : 'Tiếp tục',
                style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w600)),
          )))),
        ]),
      )),
    ]);
  }

  Widget _recordDetail() {
    final r = _selectedRecord!;
    final snapshot = _oneDoorApi?.recordSnapshot(r.id);
    final recordedReason = (snapshot?['lyDo'] ?? '').toString().trim();
    final recordedQuantity = snapshot?['soLuongBan'];
    final quantity = recordedQuantity is num
        ? recordedQuantity.toInt()
        : int.tryParse('${recordedQuantity ?? ''}') ?? r.quantity;
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
        StudentInfoLine(label: 'Nội dung yêu cầu', value: r.requestText),
        if (recordedReason.isNotEmpty)
          StudentInfoLine(label: 'Lý do / Mục đích', value: recordedReason),
        StudentInfoLine(label: 'Hình thức nhận kết quả',
          value: r.deliveryMethod),
        if (quantity > 0)
          StudentInfoLine(label: 'Số lượng bản', value: '$quantity bản'),
        _highlightInfoLine(label: 'Lệ phí dự kiến', value: _money(r.totalFee), fee: true, borders: false),
        const StudentSection('Tệp đính kèm'),
        if (_recordDetailLoading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              SizedBox(width: 17, height: 17,
                child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Đang tải giấy tờ đã nộp...'),
            ]))
        else if (_recordDetailFailed) ...[
          const Text('Chưa tải được giấy tờ đã nộp.',
            style: TextStyle(fontSize: 13,
              color: StudentServiceUI.secondary)),
          Align(alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openRecord(r),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            )),
        ] else if (r.paperFileNames.isEmpty)
          const Text('Hồ sơ chưa có tệp đính kèm.',
            style: TextStyle(fontSize: 13,
              color: StudentServiceUI.secondary))
        else ...[
          for (final entry in r.paperFileNames.entries)
            _submittedPaperRow(entry.key, entry.value),
        ],
        if (!_recordDetailLoading && !_recordDetailFailed &&
            (_recordCanSupplement ||
             r.status == OneDoorRecordStatus.supplement)) ...[
          const SizedBox(height: 24),
          VnuPressMotion(child: SizedBox(height: 46, child: FilledButton(
            onPressed: _submitting ? null : _openSupplement,
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

  Widget _supplementFieldWidget(_OneDoorSupplementField field) {
    final controller = _supplementInputs[field.key];
    if (controller == null) return const SizedBox.shrink();
    final multiline = field.type.contains('textarea') ||
        field.type.contains('multiline');
    final numeric = field.type.contains('number') ||
        field.type.contains('int') || field.type.contains('decimal');
    final date = field.type.contains('date');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _formLabel(field.label),
        if (field.currentValue.trim().isNotEmpty) ...[
          Text('Gi\u00e1 tr\u1ecb \u0111\u00e3 khai: ${field.currentValue}',
            style: const TextStyle(fontSize: 12,
              color: StudentServiceUI.secondary, height: 1.4)),
          const SizedBox(height: 7),
        ],
        TextField(
          controller: controller,
          enabled: !_submitting,
          onChanged: (_) => setState(() {
            for (final id in _supplementGeneratedFingerprints.keys) {
              _supplementReviewedDigests.remove(id);
            }
          }),
          maxLength: multiline ? 1000 : 500,
          minLines: multiline ? 3 : 1,
          maxLines: multiline ? 6 : 1,
          keyboardType: multiline ? TextInputType.multiline
              : numeric ? TextInputType.number
              : date ? TextInputType.datetime : TextInputType.text,
          style: const TextStyle(fontSize: 14),
          decoration: StudentServiceUI.field(field.hint.isNotEmpty
              ? field.hint : 'Nh\u1eadp gi\u00e1 tr\u1ecb m\u1edbi n\u1ebfu c\u1ea7n'),
        ),
      ]),
    );
  }

  // V30.1: One full-width field per row, with the original submitted value.
  // The submission contract has no update for these fixed fields.
  Widget _supplementReadonlyField(String label, String value) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: const BoxDecoration(border: Border(
      bottom: BorderSide(color: StudentServiceUI.line))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12,
        fontWeight: FontWeight.w600, color: StudentServiceUI.secondary)),
      const SizedBox(height: 5),
      Text(value.trim().isNotEmpty ? value.trim()
          : 'Ch\u01b0a c\u00f3 th\u00f4ng tin',
        softWrap: true,
        style: const TextStyle(fontSize: 14, height: 1.4,
          color: StudentServiceUI.ink, fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _supplementRegistrationSummary() {
    final quantity = _supplementSavedQuantity;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const StudentSection('Th\u00f4ng tin \u0111\u0103ng k\u00fd'),
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('C\u00e1c th\u00f4ng tin \u0111\u00e3 ghi nh\u1eadn khi n\u1ed9p h\u1ed3 s\u01a1. '
          'Ph\u1ea7n n\u00e0y ch\u1ec9 \u0111\u1ec3 \u0111\u1ed1i chi\u1ebfu; n\u1ebfu c\u1ea7n '
          '\u0111i\u1ec1u ch\u1ec9nh, h\u00e3y ghi r\u00f5 trong Ghi ch\u00fa g\u1eedi c\u00e1n b\u1ed9.',
          style: TextStyle(fontSize: 12.4, height: 1.45,
            color: StudentServiceUI.secondary)),
      ),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: StudentServiceUI.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_supplementCode.isNotEmpty)
            _supplementReadonlyField('M\u00e3 h\u1ed3 s\u01a1', _supplementCode),
          if (_supplementSubmittedAt.isNotEmpty)
            _supplementReadonlyField('Ng\u00e0y n\u1ed9p', _supplementSubmittedAt),
          _supplementReadonlyField('N\u1ed9i dung y\u00eau c\u1ea7u',
              _supplementSavedRequest),
          if (_supplementSavedReason.isNotEmpty)
            _supplementReadonlyField('L\u00fd do / M\u1ee5c \u0111\u00edch',
                _supplementSavedReason),
          _supplementReadonlyField('H\u00ecnh th\u1ee9c nh\u1eadn k\u1ebft qu\u1ea3',
              _supplementSavedDelivery),
          _supplementReadonlyField('S\u1ed1 l\u01b0\u1ee3ng b\u1ea3n',
              quantity != null && quantity > 0 ? '$quantity b\u1ea3n' : ''),
          if (_supplementPaidAmount != null)
            _supplementReadonlyField('S\u1ed1 ti\u1ec1n \u0111\u00e3 ghi nh\u1eadn',
                _money(_supplementPaidAmount!)),
        ]),
      ),
    ]);
  }

  Widget _supplementPage() {
    final record = _selectedRecord!;
    return Column(children: [
      Expanded(child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          _detailHeading('B\u1ed5 sung h\u1ed3 s\u01a1', record.procedure.name),
          if (_supplementLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_supplementError != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(_supplementError!,
                style: const TextStyle(color: StudentServiceUI.caution)),
            ),
            Align(alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _openSupplement,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Th\u1eed l\u1ea1i'))),
          ] else ...[
            if (_supplementNotices.isNotEmpty) ...[
              const StudentSection('Y\u00eau c\u1ea7u b\u1ed5 sung'),
              for (final notice in _supplementNotices) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9EB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0E4C3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notice.author.isNotEmpty || notice.date.isNotEmpty)
                        Text([
                          if (notice.author.isNotEmpty) notice.author,
                          if (notice.date.isNotEmpty)
                            _supplementDate(notice.date),
                        ].join(' \u00b7 '),
                          style: const TextStyle(fontSize: 11.7,
                            color: StudentServiceUI.secondary)),
                      const SizedBox(height: 5),
                      Text(notice.message, style: const TextStyle(
                        fontSize: 13.5, height: 1.45,
                        color: StudentServiceUI.ink)),
                      if (notice.answered) ...[
                        const SizedBox(height: 5),
                        const Text('\u0110\u00e3 b\u1ed5 sung',
                          style: TextStyle(fontSize: 11.5,
                            color: StudentServiceUI.green)),
                      ],
                    ],
                  ),
                ),
              ],
            ],
            _supplementRegistrationSummary(),
            if (_supplementFields.isNotEmpty) ...[
              const StudentSection('Th\u00f4ng tin c\u1ea7n c\u1eadp nh\u1eadt'),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Ch\u1ec9 nh\u1eadp c\u00e1c m\u1ee5c c\u1ea7n s\u1eeda. '
                  '\u0110\u1ec3 tr\u1ed1ng n\u1ebfu mu\u1ed1n gi\u1eef nguy\u00ean gi\u00e1 tr\u1ecb \u0111\u00e3 khai.',
                  style: TextStyle(fontSize: 12.4,
                    color: StudentServiceUI.secondary, height: 1.4)),
              ),
              for (final field in _supplementFields)
                _supplementFieldWidget(field),
            ],
            if (_supplementPapers.isNotEmpty) ...[
              const StudentSection('Gi\u1ea5y t\u1edd \u0111\u00ednh k\u00e8m'),
              const Padding(padding: EdgeInsets.only(bottom: 10),
                child: Text('Ch\u1ec9 thay t\u1ec7p c\u1ea7n s\u1eeda. Gi\u1ea5y t\u1edd kh\u00f4ng '
                  'ch\u1ecdn t\u1ec7p m\u1edbi v\u1eabn \u0111\u01b0\u1ee3c gi\u1eef nguy\u00ean.',
                  style: TextStyle(fontSize: 12.4,
                    color: StudentServiceUI.secondary, height: 1.4)),
              ),
              for (final paper in _supplementPapers) ...[
                if (_supplementCurrentFiles.containsKey(paper.id))
                  Padding(
                    padding: const EdgeInsets.only(top: 9, bottom: 3),
                    child: Row(children: [
                      const Icon(Icons.history_rounded,
                        size: 18, color: StudentServiceUI.green),
                      const SizedBox(width: 7),
                      Expanded(child: Text(
                        '\u0110\u00e3 n\u1ed9p: ${_supplementCurrentFiles[paper.id]}',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.3,
                          color: StudentServiceUI.secondary))),
                      IconButton(
                        tooltip: 'Xem t\u1ec7p \u0111\u00e3 n\u1ed9p',
                        onPressed: _submitting ? null : () =>
                          _openSubmittedPaper(paper.id,
                            _supplementCurrentFiles[paper.id]!),
                        icon: const Icon(Icons.visibility_outlined,
                          color: StudentServiceUI.green)),
                    ]),
                  ),
                _paperPicker(paper, _supplementFiles,
                  () => _chooseAttachmentSource(paper.id, supplement: true)),
                if (_supplementAutoPaperIds.contains(paper.id)) ...[
                  Align(alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _submitting ? null
                        : () => _regenerateSupplementWord(paper),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('T\u1ea1o l\u1ea1i b\u1ea3n Word \u0111\u00e3 \u0111i\u1ec1n'),
                    ),
                  ),
                ],
                if (_supplementPaths.containsKey(paper.id))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(children: [
                      Icon(_supplementReviewedDigests.containsKey(paper.id)
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                        size: 15, color: StudentServiceUI.green),
                      const SizedBox(width: 6),
                      Expanded(child: Text(
                        _supplementReviewedDigests.containsKey(paper.id)
                            ? '\u0110\u00e3 ki\u1ec3m tra t\u1ec7p m\u1edbi'
                            : 'M\u1edf t\u1ec7p v\u00e0 x\u00e1c nh\u1eadn tr\u01b0\u1edbc khi g\u1eedi',
                        style: const TextStyle(fontSize: 11.7,
                          color: StudentServiceUI.secondary)),
                      ),
                    ]),
                  ),
              ],
            ],
            const StudentSection('Ghi ch\u00fa g\u1eedi c\u00e1n b\u1ed9'),
            TextField(
              controller: _supplementNote,
              maxLength: 1000,
              minLines: 3,
              maxLines: 6,
              enabled: !_submitting,
              style: const TextStyle(fontSize: 14),
              decoration: StudentServiceUI.field('Kh\u00f4ng b\u1eaft bu\u1ed9c'),
            ),
            if (_supplementChangedValues().isNotEmpty &&
                _supplementAutoPaperIds.isNotEmpty &&
                _supplementPaths.isEmpty) ...[
              const SizedBox(height: 10),
              const Text('Th\u00f4ng tin \u0111\u00e3 s\u1eeda kh\u00f4ng t\u1ef1 thay '
                'n\u1ed9i dung t\u1ec7p c\u0169. N\u1ebfu c\u1ea7n s\u1eeda b\u1ea3n Word, '
                'h\u00e3y t\u1ea1o l\u1ea1i v\u00e0 ki\u1ec3m tra tr\u01b0\u1edbc khi g\u1eedi.',
                style: TextStyle(fontSize: 12.2,
                  color: StudentServiceUI.secondary)),
            ],
          ],
        ],
      )),
      if (!_supplementLoading && _supplementError == null)
        StudentActionBar(text: _submitting ? '\u0110ang g\u1eedi...'
            : 'G\u1eedi b\u1ed5 sung', onPressed: _sendSupplement),
    ]);
  }

  String _supplementDate(String raw) {
    final date = DateTime.tryParse(raw);
    return date == null ? raw
      : DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
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

