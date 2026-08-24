import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/error/app_error.dart';
import 'package:vnu_core/common/error/app_error_mapper.dart';
import 'package:vnu_core/common/error/app_error_reporter.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/models/hoc_ky_model.dart';
import 'package:vnu_core/widgets/select/vnu_select.dart';

class AcademicPeriodSelection {
  const AcademicPeriodSelection({
    required this.school,
    required this.year,
    required this.semester,
    required this.catalog,
  });

  final String school;
  final String year;
  final HocKyModel semester;
  final List<HocKyModel> catalog;
}

class AcademicPeriodSelect extends StatelessWidget {
  const AcademicPeriodSelect({
    super.key,
    required this.schools,
    required this.currentSchool,
    required this.currentCatalog,
    required this.currentYear,
    required this.currentSemester,
    required this.loadCatalogForSchool,
    required this.onSelected,
    this.guideTargetId = 'schedule.academic_period',
    this.label = 'Cơ sở, năm học & học kỳ',
    this.compact = false,
  });

  final List<String> schools;
  final String? currentSchool;
  final List<HocKyModel> currentCatalog;
  final String? currentYear;
  final HocKyModel? currentSemester;
  final Future<List<HocKyModel>> Function(String school) loadCatalogForSchool;
  final ValueChanged<AcademicPeriodSelection> onSelected;
  final String? guideTargetId;
  final String? label;
  final bool compact;

  String get _displayText {
    final parts = <String>[];
    final school = currentSchool;
    if (school != null && school.trim().isNotEmpty) {
      parts.add(school.toDisplayName());
    }
    final year = currentYear;
    if (year != null && year.trim().isNotEmpty) {
      parts.add(year);
    }
    final semesterName = currentSemester?.ten?.trim();
    if (semesterName != null && semesterName.isNotEmpty) {
      parts.add('Học kỳ $semesterName');
    }
    return parts.join(' · ');
  }

  Future<void> _open(BuildContext context) async {
    logInfo(
      '[SELECT_OPEN] id=academic_period mode=drillDown '
      'school=${currentSchool ?? '-'} year=${currentYear ?? '-'} '
      'semester=${currentSemester?.id ?? currentSemester?.ten ?? '-'}',
    );

    final selection = await showModalBottomSheet<AcademicPeriodSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AcademicPeriodPicker(
        schools: schools,
        initialSchool: currentSchool,
        initialCatalog: currentCatalog,
        initialYear: currentYear,
        initialSemester: currentSemester,
        loadCatalogForSchool: loadCatalogForSchool,
      ),
    );

    if (selection == null) {
      logInfo('[SELECT_CANCEL] id=academic_period');
      return;
    }

    logInfo(
      '[SELECT_COMMIT] id=academic_period '
      'school=${selection.school} year=${selection.year} '
      'semester=${selection.semester.id ?? selection.semester.ten ?? '-'}',
    );
    onSelected(selection);
  }

  @override
  Widget build(BuildContext context) {
    return VnuSelectField(
      label: label,
      displayText: _displayText,
      placeholder: 'Chọn cơ sở, năm học và học kỳ',
      onTap: schools.isEmpty ? null : () => _open(context),
      enabled: schools.isNotEmpty,
      guideTargetId: guideTargetId,
      leading: const Icon(
        Icons.school_outlined,
        color: AppColors.greenAccent,
        size: 20,
      ),
      compact: compact,
    );
  }
}

enum _AcademicStep { school, year, semester }

class _AcademicPeriodPicker extends StatefulWidget {
  const _AcademicPeriodPicker({
    required this.schools,
    required this.initialSchool,
    required this.initialCatalog,
    required this.initialYear,
    required this.initialSemester,
    required this.loadCatalogForSchool,
  });

  final List<String> schools;
  final String? initialSchool;
  final List<HocKyModel> initialCatalog;
  final String? initialYear;
  final HocKyModel? initialSemester;
  final Future<List<HocKyModel>> Function(String school) loadCatalogForSchool;

  @override
  State<_AcademicPeriodPicker> createState() => _AcademicPeriodPickerState();
}

class _AcademicPeriodPickerState extends State<_AcademicPeriodPicker> {
  late _AcademicStep _step;
  String? _draftSchool;
  String? _draftYear;
  List<HocKyModel> _catalog = const [];
  bool _loading = false;
  AppError? _error;
  String? _failedSchool;

  bool get _hasSchoolStep => widget.schools.length > 1;

  @override
  void initState() {
    super.initState();
    _draftSchool = widget.initialSchool ??
        (widget.schools.isNotEmpty ? widget.schools.first : null);
    _draftYear = widget.initialYear;
    _catalog = List<HocKyModel>.from(widget.initialCatalog);

    if (_hasSchoolStep) {
      _step = _AcademicStep.school;
    } else if (_catalog.isNotEmpty) {
      _step = _AcademicStep.year;
    } else {
      _step = _AcademicStep.school;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final school = _draftSchool;
        if (school != null) _chooseSchool(school);
      });
    }
  }

  List<String> get _years {
    final years = _catalog
        .map((item) => item.nam?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  List<HocKyModel> get _semestersForDraftYear {
    final year = _draftYear;
    if (year == null) return const [];
    final result = _catalog.where((item) => item.nam == year).toList();
    result.sort((a, b) => (a.ten ?? '').compareTo(b.ten ?? ''));
    return result;
  }

  String get _title {
    switch (_step) {
      case _AcademicStep.school:
        return _hasSchoolStep ? 'Chọn cơ sở đào tạo' : 'Đang tải học kỳ';
      case _AcademicStep.year:
        return 'Chọn năm học';
      case _AcademicStep.semester:
        return 'Chọn học kỳ';
    }
  }

  bool get _canGoBack {
    switch (_step) {
      case _AcademicStep.school:
        return false;
      case _AcademicStep.year:
        return _hasSchoolStep;
      case _AcademicStep.semester:
        return true;
    }
  }

  void _goBack() {
    if (_step == _AcademicStep.semester) {
      setState(() => _step = _AcademicStep.year);
      return;
    }
    if (_step == _AcademicStep.year && _hasSchoolStep) {
      setState(() => _step = _AcademicStep.school);
    }
  }

  Future<void> _chooseSchool(String school) async {
    if (_loading) return;

    logInfo('[SELECT_DRAFT] id=academic_period level=school value=$school');
    setState(() {
      _draftSchool = school;
      _draftYear = null;
      _error = null;
      _failedSchool = null;
    });

    if (school == widget.initialSchool && widget.initialCatalog.isNotEmpty) {
      setState(() {
        _catalog = List<HocKyModel>.from(widget.initialCatalog);
        _draftYear = widget.initialYear;
        _step = _AcademicStep.year;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final catalog = await widget.loadCatalogForSchool(school);
      if (!mounted || _draftSchool != school) return;
      setState(() {
        _catalog = List<HocKyModel>.from(catalog);
        _loading = false;
        _step = _AcademicStep.year;
      });
    } catch (error, stackTrace) {
      final mapped = AppErrorMapper.map(error, stackTrace: stackTrace);
      await AppErrorReporter.report(mapped, stackTrace: stackTrace);
      if (!mounted || _draftSchool != school) return;
      setState(() {
        _loading = false;
        _error = mapped;
        _failedSchool = school;
      });
    }
  }

  void _chooseYear(String year) {
    logInfo('[SELECT_DRAFT] id=academic_period level=year value=$year');
    setState(() {
      _draftYear = year;
      _step = _AcademicStep.semester;
    });
  }

  void _commitSemester(HocKyModel semester) {
    final school = _draftSchool;
    final year = _draftYear;
    if (school == null || year == null) return;
    Navigator.of(context).pop(
      AcademicPeriodSelection(
        school: school,
        year: year,
        semester: semester,
        catalog: List<HocKyModel>.from(_catalog),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenAccent),
              ),
              SizedBox(height: 14),
              Text('Đang tải danh sách học kỳ...'),
            ],
          ),
        ),
      );
    }

    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.textSecondary,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                error.displayMessage,
                textAlign: TextAlign.center,
                style: TextStyles.regular.copyWith(
                  fontSize: AppFontSizes.mediumSmall,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _failedSchool == null
                    ? null
                    : () => _chooseSchool(_failedSchool!),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    switch (_step) {
      case _AcademicStep.school:
        if (!_hasSchoolStep) {
          return const SizedBox.shrink();
        }
        return ListView(
          padding: VnuSelectTheme.sheetBodyPadding,
          children: [
            for (final school in widget.schools)
              VnuSelectOptionTile(
                title: school.toDisplayName(),
                selected: school == widget.initialSchool,
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
                onTap: () => _chooseSchool(school),
              ),
          ],
        );
      case _AcademicStep.year:
        final years = _years;
        if (years.isEmpty) {
          return _empty('Chưa có năm học cho cơ sở đã chọn.');
        }
        return ListView(
          padding: VnuSelectTheme.sheetBodyPadding,
          children: [
            for (final year in years)
              VnuSelectOptionTile(
                title: year,
                selected: year == widget.initialYear &&
                    _draftSchool == widget.initialSchool,
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
                onTap: () => _chooseYear(year),
              ),
          ],
        );
      case _AcademicStep.semester:
        final semesters = _semestersForDraftYear;
        if (semesters.isEmpty) {
          return _empty('Chưa có học kỳ trong năm học này.');
        }
        return ListView(
          padding: VnuSelectTheme.sheetBodyPadding,
          children: [
            for (final semester in semesters)
              VnuSelectOptionTile(
                title: semester.ten?.trim().isNotEmpty == true
                    ? 'Học kỳ ${semester.ten}'
                    : 'Học kỳ',
                subtitle: _semesterSubtitle(semester),
                selected: _isInitialSemester(semester),
                onTap: () => _commitSemester(semester),
              ),
          ],
        );
    }
  }

  Widget _empty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyles.regular.copyWith(
            fontSize: AppFontSizes.mediumSmall,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  bool _isInitialSemester(HocKyModel semester) {
    final initial = widget.initialSemester;
    if (initial == null || _draftSchool != widget.initialSchool) return false;
    final semesterId = semester.id?.trim();
    final initialId = initial.id?.trim();
    if (semesterId != null && semesterId.isNotEmpty && initialId != null) {
      return semesterId == initialId;
    }
    return semester.ten == initial.ten && semester.nam == initial.nam;
  }

  String? _semesterSubtitle(HocKyModel semester) {
    final start = semester.ngayBatDau?.trim() ?? '';
    final end = semester.ngayKetThuc?.trim() ?? '';
    if (start.isEmpty && end.isEmpty) return null;
    if (start.isNotEmpty && end.isNotEmpty) return '$start → $end';
    return start.isNotEmpty ? 'Từ $start' : 'Đến $end';
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _step == _AcademicStep.school || _draftSchool == null
        ? null
        : [
            _draftSchool!.toDisplayName(),
            if (_draftYear != null) _draftYear!,
          ].join(' · ');

    return VnuSelectSheetFrame(
      title: _title,
      subtitle: subtitle,
      showBack: _canGoBack,
      onBack: _canGoBack ? _goBack : null,
      child: _body(),
    );
  }
}
