import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/guide/guide.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/responsive/responsive.dart';

import '../controllers/vcore_exam_schedule_controller.dart';
import '../widgets/academic_period_select.dart';
import '../../../models/model.dart';

class VcoreExamScheduleView extends StatelessWidget {
  static const Color _classColor = AppColors.greenAccent;
  static const Color _examColor = Color(0xFFFFB703);
  static const Color _examLightColor = Color(0xFFFFF8E1);
  static const Color _examBorderColor = Color(0xFFFFECB3);
  static const String _termStartWarningText =
      'Ngày bắt đầu học kỳ của mỗi trường/đơn vị đào tạo có thể khác nhau. '
      'Đây là ngày bắt đầu học kỳ, không phải ngày bắt đầu năm học. '
      'Nếu mốc đang hiển thị chưa đúng với thông báo chính thức của trường, '
      'hãy chỉnh lại theo đúng thời gian trường đã thông báo.';
  static const String _termStartWarningAckKey =
      'schedule_term_start_warning_v1_acknowledged';
  static bool _termStartWarningDialogScheduled = false;
  /// Optional context: Home có thể truyền đúng ngày + học kỳ + loại trường
  /// đang hiển thị để màn lịch mở đúng cùng một dataset.
  final DateTime? initialDate;
  final String? initialHocKyId;
  final String? initialKieuTruong;

  const VcoreExamScheduleView({
    super.key,
    this.initialDate,
    this.initialHocKyId,
    this.initialKieuTruong,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcoreExamScheduleController>(
      init: VcoreExamScheduleController(),
      builder: (controller) {
        if (initialDate != null ||
            initialHocKyId != null ||
            initialKieuTruong != null) {
          controller.setInitialContext(
            date: initialDate,
            hocKyId: initialHocKyId,
            kieuTruongValue: initialKieuTruong,
          );
        }
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            if (controller.danhSachKieuTruong.isEmpty) {
              controller.getDanhSachKieuTruong();
            }
          },
          child: AppGuideAnchor(
            id: 'exam_schedule.page',
            child: VcoreModuleScaffold(
            title: 'Lịch học & lịch thi',
            pageWidth: VnuPageWidth.content,
            body: Container(
              color: const Color(0xFFF6F7FB),
              child: Obx(() {
                if (controller.danhSachHocKy.isEmpty &&
                    controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenAccent),
                    ),
                  );
                }

                return SmartRefresher(
                  controller: controller.refreshController,
                  onRefresh: () => controller.refreshData(),
                  enablePullDown: true,
                  header: const WaterDropHeader(
                    waterDropColor: AppColors.greenAccent,
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _buildAcademicPeriodSelector(context, controller),

                      if (controller.hocKySelected.value != null) ...[
                        const SizedBox(height: 8),
                        _buildTermDateRangeCard(context, controller),
                      ],

                      const SizedBox(height: 8),

                      _buildCalendar(context, controller),

                      const SizedBox(height: 12),

                      AppGuideAnchor(
                        id: 'exam_schedule.list',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (controller.showExtraTermCourses.value)
                              _buildExtraTermCoursesList(context, controller)
                            else if (controller.showIncompleteExams.value)
                              _buildIncompleteExamsList(controller)
                            else ...[
                              _buildEventsHeader(context, controller),
                              _buildEventsList(context, controller),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              }),
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildAcademicPeriodSelector(
    BuildContext context,
    VcoreExamScheduleController controller,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: AcademicPeriodSelect(
        schools: controller.danhSachKieuTruong.toList(),
        currentSchool: controller.kieuTruong.value,
        currentCatalog: controller.danhSachHocKy.toList(),
        currentYear: controller.namHocSelected.value,
        currentSemester: controller.hocKySelected.value,
        loadCatalogForSchool: controller.previewHocKyCatalog,
        onSelected: (selection) {
          controller.commitAcademicPeriodSelection(
            school: selection.school,
            year: selection.year,
            catalog: selection.catalog,
            semester: selection.semester,
          );
        },
      ),
    );
  }

  Widget _buildTermDateRangeCard(
    BuildContext context,
    VcoreExamScheduleController controller,
  ) {
    final start = controller.currentTermStartDate;
    final end = controller.currentTermEndDate;
    if (start == null || end == null) return const SizedBox.shrink();

    final isPersonal = controller.hasPersonalTermDateOverride.value;
    _scheduleTermStartWarning(context, controller);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPersonal
              ? AppColors.greenAccent.withOpacity(0.45)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => _showTermDateRangeBottomSheet(context, controller),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.greenAccent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.date_range_rounded,
                      color: AppColors.greenAccent,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Thời gian học kỳ',
                                style: TextStyles.semiBold.copyWith(
                                  fontSize: AppFontSizes.medium,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (isPersonal)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.greenAccent.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Cá nhân',
                                  style: TextStyles.semiBold.copyWith(
                                    fontSize: AppFontSizes.font11,
                                    color: AppColors.greenAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bắt đầu học kỳ: ${DateFormat('dd/MM/yyyy').format(start)}',
                          style: TextStyles.bold.copyWith(
                            fontSize: AppFontSizes.mediumSmall,
                            color: AppColors.greenAccent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kết thúc: ${DateFormat('dd/MM/yyyy').format(end)}',
                          style: TextStyles.regular.copyWith(
                            fontSize: AppFontSizes.font11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_calendar_outlined,
                    size: 21,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.amber.shade100),
          InkWell(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            onTap: () => _showTermDateRangeBottomSheet(context, controller),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
              decoration: BoxDecoration(
                color: Colors.amber.shade50.withOpacity(0.72),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _termStartWarningText,
                      style: TextStyles.medium.copyWith(
                        fontSize: AppFontSizes.font11,
                        height: 1.35,
                        color: const Color(0xFF7A5200),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleTermStartWarning(
    BuildContext context,
    VcoreExamScheduleController controller,
  ) {
    if (_termStartWarningDialogScheduled) return;
    final start = controller.currentTermStartDate;
    if (controller.hocKySelected.value == null || start == null) return;

    _termStartWarningDialogScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_termStartWarningAckKey) == true) return;
      if (!context.mounted) {
        _termStartWarningDialogScheduled = false;
        return;
      }
      await _showTermStartWarningDialog(
        context,
        controller,
        currentStart: start,
      );
    });
  }

  Future<void> _showTermStartWarningDialog(
    BuildContext context,
    VcoreExamScheduleController controller, {
    required DateTime currentStart,
  }) async {
    var remainingSeconds = 10;
    var timerStarted = false;
    Timer? timer;

    final semester = controller.hocKySelected.value;
    final semesterLabel = [semester?.ten, semester?.nam]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' • ');
    final schoolLabel = controller.kieuTruong.value?.trim() ?? '';

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return PopScope(
            canPop: false,
            child: StatefulBuilder(
              builder: (dialogContext, setDialogState) {
                if (!timerStarted) {
                  timerStarted = true;
                  timer = Timer.periodic(const Duration(seconds: 1), (ticker) {
                    if (!dialogContext.mounted) {
                      ticker.cancel();
                      return;
                    }
                    if (remainingSeconds <= 1) {
                      ticker.cancel();
                      setDialogState(() => remainingSeconds = 0);
                    } else {
                      setDialogState(() => remainingSeconds--);
                    }
                  });
                }

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Lưu ý về ngày bắt đầu học kỳ',
                          style: TextStyles.bold.copyWith(
                            fontSize: AppFontSizes.large,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _termStartWarningText,
                        style: TextStyles.regular.copyWith(
                          fontSize: AppFontSizes.small,
                          height: 1.45,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (schoolLabel.isNotEmpty)
                              Text(
                                'Trường/loại đào tạo: $schoolLabel',
                                style: TextStyles.medium.copyWith(
                                  fontSize: AppFontSizes.font11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            if (semesterLabel.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Học kỳ: $semesterLabel',
                                style: TextStyles.medium.copyWith(
                                  fontSize: AppFontSizes.font11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 5),
                            Text(
                              'Ngày bắt đầu đang dùng: ${DateFormat('dd/MM/yyyy').format(currentStart)}',
                              style: TextStyles.bold.copyWith(
                                fontSize: AppFontSizes.font12,
                                color: AppColors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: remainingSeconds == 0
                            ? () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool(
                                  _termStartWarningAckKey,
                                  true,
                                );
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          remainingSeconds > 0
                              ? 'Vui lòng đọc kỹ ($remainingSeconds giây)'
                              : 'Tôi đã hiểu và xác nhận',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    } finally {
      timer?.cancel();
    }
  }

  void _showTermDateRangeBottomSheet(
    BuildContext context,
    VcoreExamScheduleController controller,
  ) {
    final currentStart = controller.currentTermStartDate;
    final currentEnd = controller.currentTermEndDate;
    if (currentStart == null || currentEnd == null) return;

    DateTime startDate = DateTime(
      currentStart.year,
      currentStart.month,
      currentStart.day,
    );
    DateTime endDate = DateTime(
      currentEnd.year,
      currentEnd.month,
      currentEnd.day,
    );
    bool isSaving = false;
    bool isRestoring = false;
    bool hasPersonalDateOverride =
        controller.hasPersonalTermDateOverride.value;

    logInfo(
      '[SCHEDULE_ADJUST_UI] action=open_term_dates_only '
      'start=${DateFormat('yyyy-MM-dd').format(startDate)} '
      'end=${DateFormat('yyyy-MM-dd').format(endDate)} '
      'personalDate=$hasPersonalDateOverride',
    );

    Get.bottomSheet(
      StatefulBuilder(
        builder: (sheetContext, setModalState) {
          Future<void> pickStartDate() async {
            final picked = await showDatePicker(
              context: sheetContext,
              initialDate: startDate,
              firstDate: DateTime(startDate.year - 1, 1, 1),
              lastDate: DateTime(endDate.year + 1, 12, 31),
              helpText: 'Chọn ngày bắt đầu học kỳ',
              cancelText: 'Hủy',
              confirmText: 'Chọn',
            );
            if (picked == null || !sheetContext.mounted) return;
            setModalState(() {
              startDate = DateTime(picked.year, picked.month, picked.day);
              if (endDate.isBefore(startDate)) {
                endDate = startDate;
              }
            });
          }

          Future<void> pickEndDate() async {
            final picked = await showDatePicker(
              context: sheetContext,
              initialDate: endDate.isBefore(startDate) ? startDate : endDate,
              firstDate: startDate,
              lastDate: DateTime(endDate.year + 1, 12, 31),
              helpText: 'Chọn ngày kết thúc học kỳ',
              cancelText: 'Hủy',
              confirmText: 'Chọn',
            );
            if (picked == null || !sheetContext.mounted) return;
            setModalState(() {
              endDate = DateTime(picked.year, picked.month, picked.day);
            });
          }

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F8FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.greenAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.edit_calendar_rounded,
                            color: AppColors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Điều chỉnh thời gian học kỳ',
                                style: TextStyles.bold.copyWith(
                                  fontSize: AppFontSizes.large,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Chỉ điều chỉnh ngày bắt đầu và ngày kết thúc học kỳ. Không có cấu hình giờ học trong màn này.',
                                style: TextStyles.regular.copyWith(
                                  fontSize: AppFontSizes.small,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Đóng',
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber.shade800,
                            size: 20,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              _termStartWarningText,
                              style: TextStyles.medium.copyWith(
                                fontSize: AppFontSizes.font11_5,
                                height: 1.4,
                                color: const Color(0xFF7A5200),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildDateRangePickerTile(
                      label: 'Ngày bắt đầu học kỳ (theo thông báo của trường)',
                      value: startDate,
                      icon: Icons.play_circle_outline_rounded,
                      onTap: pickStartDate,
                    ),
                    const SizedBox(height: 10),
                    _buildDateRangePickerTile(
                      label: 'Ngày kết thúc học kỳ',
                      value: endDate,
                      icon: Icons.flag_outlined,
                      onTap: pickEndDate,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lưu ý: ngày bắt đầu học kỳ không phải ngày bắt đầu năm học.',
                      style: TextStyles.semiBold.copyWith(
                        fontSize: AppFontSizes.font11,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    if (hasPersonalDateOverride) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isSaving || isRestoring
                              ? null
                              : () async {
                                  setModalState(() => isRestoring = true);
                                  try {
                                    await controller.clearPersonalTermDateRange();
                                    final restoredStart =
                                        controller.currentTermStartDate;
                                    final restoredEnd = controller.currentTermEndDate;
                                    if (!sheetContext.mounted) return;
                                    setModalState(() {
                                      isRestoring = false;
                                      hasPersonalDateOverride = false;
                                      if (restoredStart != null) {
                                        startDate = restoredStart;
                                      }
                                      if (restoredEnd != null) {
                                        endDate = restoredEnd;
                                      }
                                    });
                                  } catch (error) {
                                    logError(
                                      '[SCHEDULE_ADJUST_UI] action=restore_term_dates_failed '
                                      'error=${error.runtimeType}',
                                    );
                                    if (!sheetContext.mounted) return;
                                    setModalState(() => isRestoring = false);
                                  }
                                },
                          icon: isRestoring
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.restart_alt_rounded),
                          label: const Text('Khôi phục ngày từ hệ thống'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSaving || isRestoring
                            ? null
                            : () async {
                                setModalState(() => isSaving = true);
                                try {
                                  final saved =
                                      await controller.savePersonalTermDateRange(
                                    startDate,
                                    endDate,
                                  );
                                  if (!sheetContext.mounted) return;
                                  setModalState(() {
                                    isSaving = false;
                                    if (saved) {
                                      hasPersonalDateOverride = true;
                                    }
                                  });
                                  if (saved && sheetContext.mounted) {
                                    Get.back();
                                  }
                                } catch (error) {
                                  logError(
                                    '[SCHEDULE_ADJUST_UI] action=save_term_dates_failed '
                                    'error=${error.runtimeType}',
                                  );
                                  if (!sheetContext.mounted) return;
                                  setModalState(() => isSaving = false);
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: const Text('Lưu ngày học kỳ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.greenAccent.withOpacity(0.45),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.greenAccent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.greenAccent, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.bold.copyWith(
                  fontSize: AppFontSizes.medium,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyles.regular.copyWith(
                  fontSize: AppFontSizes.font11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangePickerTile({
    required String label,
    required DateTime value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.greenAccent, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyles.medium.copyWith(
                      fontSize: AppFontSizes.font11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('dd/MM/yyyy').format(value),
                    style: TextStyles.bold.copyWith(
                      fontSize: AppFontSizes.medium,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_month_outlined, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    VcoreExamScheduleController controller,
  ) {
    final range = controller.calendarDisplayRange;
    final safeFocusedDay = controller.clampToCalendarRange(
      controller.focusedDay.value,
    );

    return AppGuideAnchor(
      id: 'exam_schedule.calendar',
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TableCalendar<ScheduleEvent>(
            firstDay: range.start,
            lastDay: range.end,
            focusedDay: safeFocusedDay,
            selectedDayPredicate: (day) =>
                isSameDay(controller.selectedDay.value, day),
            locale: 'vi_VN',
            calendarFormat: CalendarFormat.month,
            availableGestures: AvailableGestures.horizontalSwipe,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: AppFontSizes.large,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              leftChevronIcon: Icon(
                  Icons.chevron_left, color: AppColors.greenAccent),
              rightChevronIcon: Icon(
                  Icons.chevron_right, color: AppColors.greenAccent),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyles.medium.copyWith(
                  fontSize: AppFontSizes.small, color: Colors.grey.shade800),
              weekendStyle: TextStyles.medium.copyWith(
                  fontSize: AppFontSizes.small, color: Colors.red.shade700),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: TextStyles.regular.copyWith(
                  fontSize: AppFontSizes.medium, color: Colors.black87),
              weekendTextStyle: TextStyles.regular.copyWith(
                  fontSize: AppFontSizes.medium, color: Colors.red.shade700),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              controller.selectCalendarDay(selectedDay, focusedDay);
            },
            onPageChanged: controller.setCalendarFocusedDay,
            eventLoader: (day) {
              final key = DateTime(day.year, day.month, day.day);
              return controller.eventsMap[key] ?? [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox.shrink();

                final hasClass = events.any((e) =>
                e.type == ScheduleType.classSession);
                final hasExam = events.any((e) => e.type == ScheduleType.exam);

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasClass)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.greenAccent,
                          ),
                        ),
                      if (hasExam)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _examColor,
                          ),
                        ),
                    ],
                  ),
                );
              },
              selectedBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.greenAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.greenAccentShadow,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyles.bold.copyWith(
                        color: Colors.white, fontSize: AppFontSizes.medium),
                  ),
                );
              },
              todayBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.todayBlueBg,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyles.bold.copyWith(
                        color: AppColors.blueAccent, fontSize: AppFontSizes.medium),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
          _buildCalendarLegend(),
          _buildModeSelector(context, controller),
        ],
      ),
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 8,
        children: [
          _buildLegendItem(AppColors.greenAccent, 'Có lớp học'),
          _buildLegendItem(_examColor, 'Có lịch thi'),
          _buildLegendItem(AppColors.blueAccent, 'Hôm nay'),
          _buildLegendItem(
            AppColors.blueAccent,
            'Sắp diễn ra',
            icon: Icons.access_time_rounded,
          ),
          _buildLegendItem(
            _classColor,
            'Đã học',
            icon: Icons.check_circle_outline_rounded,
          ),
          _buildLegendItem(
            _examColor,
            'Đã diễn ra',
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      Color color,
      String text, {
        IconData? icon,
      }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon == null)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          )
        else
          Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyles.medium.copyWith(
            fontSize: AppFontSizes.font11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEventsHeader(
    BuildContext context,
    VcoreExamScheduleController controller,
  ) {
    final rawDate = controller.selectedDay.value;
    final dayOfWeek = _getVietnameseDayOfWeek(rawDate.weekday);
    final dateStr = DateFormat('dd/MM/yyyy').format(rawDate);
    final displayDate = '$dayOfWeek, ngày $dateStr';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(
            Icons.event_note_rounded,
            size: 18,
            color: AppColors.greenAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayDate,
              style: TextStyles.bold.copyWith(
                fontSize: AppFontSizes.medium,
                color: AppColors.greenAccent,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getVietnameseDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Thứ Hai';
      case 2:
        return 'Thứ Ba';
      case 3:
        return 'Thứ Tư';
      case 4:
        return 'Thứ Năm';
      case 5:
        return 'Thứ Sáu';
      case 6:
        return 'Thứ Bảy';
      case 7:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }

  Widget _buildEventsList(BuildContext context,
      VcoreExamScheduleController controller) {
    if (controller.selectedEvents.isEmpty) {
      return Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery
              .of(context)
              .size
              .height * 0.35,
        ),
        padding: const EdgeInsets.only(bottom: 40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'Không có lịch học & lịch thi',
                style: TextStyles.regular.copyWith(
                  fontSize: AppFontSizes.medium,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: Column(
        children: List.generate(controller.selectedEvents.length, (index) {
          final event = controller.selectedEvents[index];
          final isFirst = index == 0;
          final isLast = index == controller.selectedEvents.length - 1;

          return _buildTimelineEventRow(context, event, isFirst, isLast);
        }),
      ),
    );
  }

  Widget _buildTimelineEventRow(
    BuildContext context,
    ScheduleEvent event,
    bool isFirst,
    bool isLast,
  ) {
    final isClass = event.type == ScheduleType.classSession;
    final examTimeRange = isClass ? '' : _displayTimeRange(event);
    final examParts = examTimeRange.split(' - ');
    final lessonRange = _formatLessonRange(event);

    // Lịch học: dòng chính chỉ hiển thị Tiết X - Y.
    // Không hiển thị giờ quy đổi bên dưới.
    final timelinePrimary = isClass
        ? (lessonRange.isNotEmpty ? lessonRange : 'Tiết học')
        : (examParts.isNotEmpty ? examParts[0] : '');
    final timelineSecondary = isClass
        ? ''
        : (examParts.length > 1 ? examParts[1] : '');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 75,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  timelinePrimary,
                  style: TextStyles.bold.copyWith(
                    fontSize: AppFontSizes.mediumSmall,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (timelineSecondary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      timelineSecondary,
                      style: TextStyles.regular.copyWith(
                        fontSize: AppFontSizes.font11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 16,
            child: _buildTimelineIndicator(isClass, isFirst, isLast),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showEventDetailBottomSheet(context, event),
                child: _buildEventCard(event),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator(bool isClass, bool isFirst, bool isLast) {
    final accentColor = isClass ? _classColor : _examColor;

    return Column(
      children: [
        Expanded(
          child: Container(
            width: 1,
            color: isFirst ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            width: 1,
            color: isLast ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(ScheduleEvent event) {
    final isClass = event.type == ScheduleType.classSession;
    final borderColor = isClass ? AppColors.calendarBorder : _examBorderColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isClass
                ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.greenAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                color: AppColors.greenAccent,
                size: 20,
              ),
            )
                : Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _examLightColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: _examColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyles.bold.copyWith(
                      fontSize: AppFontSizes.medium,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 14,
                          color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location.isNotEmpty
                              ? event.location
                              : 'Học trực tuyến / Chưa có phòng',
                          style: TextStyles.regular.copyWith(
                            fontSize: AppFontSizes.small,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isClass ? Icons.person_outline : Icons
                            .assignment_ind_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isClass
                              ? (event.teacher.isNotEmpty
                              ? event.teacher
                              : 'Giảng viên: Đang cập nhật')
                              : (event.teacher.startsWith('SBD:') ? event
                              .teacher : 'Hình thức: ${event.teacher}'),
                          style: TextStyles.regular.copyWith(
                            fontSize: AppFontSizes.small,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(event),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ScheduleEvent event) {
    final color = _getStatusColor(event);
    final icon = _getStatusIcon(event);
    final text = _getStatusText(event);

    return Tooltip(
      message: text,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }

  bool _isEventPast(ScheduleEvent event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
    );

    if (eventDate.isBefore(today)) return true;
    if (eventDate.isAfter(today)) return false;

    // Không có giờ học đáng tin cậy để suy đoán trạng thái trong ngày hiện tại.
    if (event.type == ScheduleType.classSession) return false;

    final timeRange = _displayTimeRange(event);
    final parts = timeRange.split(' - ');
    final endTimeStr = parts.length >= 2 ? parts[1].trim() : parts.first.trim();
    final timeParts = endTimeStr.split(':');
    if (timeParts.length != 2) return false;

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return false;

    return now.isAfter(DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ));
  }

  String _getStatusText(ScheduleEvent event) {
    final isClass = event.type == ScheduleType.classSession;
    final isPast = _isEventPast(event);

    if (!isPast) return 'Sắp diễn ra';
    return isClass ? 'Đã học' : 'Đã diễn ra';
  }

  Color _getStatusColor(ScheduleEvent event) {
    final isClass = event.type == ScheduleType.classSession;
    final isPast = _isEventPast(event);

    if (!isPast) return AppColors.blueAccent;
    return isClass ? _classColor : _examColor;
  }

  IconData _getStatusIcon(ScheduleEvent event) {
    final isPast = _isEventPast(event);

    return isPast
        ? Icons.check_circle_outline_rounded
        : Icons.access_time_rounded;
  }

  String _mapExamTime(String startTime, String endTime) {
    // Chỉ dùng cho lịch thi với giờ thật do API trả về.
    final start = startTime.trim();
    final end = endTime.trim();
    if (start.isEmpty && end.isEmpty) return 'Chưa có giờ';
    if (start.isEmpty) return end;
    if (end.isEmpty || end.contains('phút')) return start;
    return '$start - $end';
  }

  String _formatLessonRange(ScheduleEvent event) {
    if (event.type != ScheduleType.classSession) return '';

    String normalize(String value) {
      final text = value.trim();
      if (text.isEmpty || text == '?') return '';
      return text.replaceFirst(RegExp(r'^Tiết\s*', caseSensitive: false), '').trim();
    }

    final start = normalize(event.startTime);
    final end = normalize(event.endTime);

    if (start.isEmpty && end.isEmpty) return '';
    if (start.isEmpty) return 'Tiết $end';
    if (end.isEmpty || start == end) return 'Tiết $start';
    return 'Tiết $start - $end';
  }

  void _showEventDetailBottomSheet(BuildContext context, ScheduleEvent event) {
    final isClass = event.type == ScheduleType.classSession;
    final accentColor = isClass ? _classColor : _examColor;
    final bgLightColor = isClass ? AppColors.classCardBg : _examLightColor;
    final borderLightColor = isClass ? AppColors.classCardBorder : _examBorderColor;

    final rawDate = event.date;
    final dayOfWeek = _getVietnameseDayOfWeek(rawDate.weekday);
    final dateStr = DateFormat('dd/MM/yyyy').format(rawDate);
    final displayDate = '$dayOfWeek, $dateStr';

    final timeRange = _displayTimeRange(event);
    final lessonRange = _formatLessonRange(event);
    final timeValue = isClass ? displayDate : '$timeRange\n$displayDate';
    final sourceLabel = isClass
        ? 'Nguồn: Thời khóa biểu học kỳ'
        : 'Nguồn: Lịch thi học kỳ';

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgLightColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderLightColor, width: 0.5),
                    ),
                    child: Text(
                      isClass ? 'LỊCH HỌC' : 'LỊCH THI',
                      style: TextStyles.bold.copyWith(
                        fontSize: AppFontSizes.extraSmall,
                        color: accentColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                style: TextStyles.bold.copyWith(
                  fontSize: AppFontSizes.extraLarge,
                  color: AppColors.textTitle,
                ),
              ),
              if (event.hocPhanCode != null && event.hocPhanCode!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Mã học phần: ${event.hocPhanCode}',
                  style: TextStyles.medium.copyWith(
                    fontSize: AppFontSizes.mediumSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 20),

              // Time & Date row
              Text(
                sourceLabel,
                style: TextStyles.medium.copyWith(
                  fontSize: AppFontSizes.small,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 12),

// Tiết học / Thời gian thi
              if (isClass) ...[
                _buildDetailItem(
                  icon: Icons.view_timeline_outlined,
                  iconColor: accentColor,
                  title: 'Tiết học',
                  value: lessonRange.isNotEmpty ? lessonRange : 'Chưa cập nhật tiết học',
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.calendar_today_rounded,
                  iconColor: accentColor,
                  title: 'Ngày học',
                  value: displayDate,
                ),
              ] else ...[
                _buildDetailItem(
                  icon: Icons.access_time_rounded,
                  iconColor: accentColor,
                  title: 'Thời gian',
                  value: timeValue,
                ),
              ],
              const SizedBox(height: 16),

// Location row
              _buildDetailItem(
                icon: Icons.location_on_rounded,
                iconColor: accentColor,
                title: 'Địa điểm / Phòng',
                value: event.location.isNotEmpty ? event.location : 'Chưa cập nhật địa điểm',
              ),
              const SizedBox(height: 16),

              if (isClass) ...[
                // Lecturer row
                _buildDetailItem(
                  icon: Icons.person_rounded,
                  iconColor: AppColors.greenAccent,
                  title: 'Giảng viên',
                  value: event.teacher.isNotEmpty ? event.teacher : 'Chưa có thông tin giảng viên',
                ),

              ] else ...[
                // Exam details
                if (event.soBaoDanh != null && event.soBaoDanh!.isNotEmpty) ...[
                  _buildDetailItem(
                    icon: Icons.badge_rounded,
                    iconColor: AppColors.greenAccent,
                    title: 'Số báo danh',
                    value: event.soBaoDanh!,
                  ),
                  const SizedBox(height: 16),
                ],
                if (event.hinhThucThi != null && event.hinhThucThi!.isNotEmpty) ...[
                  _buildDetailItem(
                    icon: Icons.assignment_rounded,
                    iconColor: _examColor,
                    title: 'Hình thức thi',
                    value: event.hinhThucThi!,
                  ),
                  const SizedBox(height: 16),
                ],
                if (event.caThi != null && event.caThi!.isNotEmpty) ...[
                  _buildDetailItem(
                    icon: Icons.calendar_today_rounded,
                    iconColor: _examColor,
                    title: 'Ca thi',
                    value: 'Ca ${event.caThi}',
                  ),
                  const SizedBox(height: 16),
                ],
              ],
              if (event.soTinChi != null && event.soTinChi!.isNotEmpty) ...[
                _buildDetailItem(
                  icon: Icons.class_outlined,
                  iconColor: AppColors.textHint,
                  title: 'Số tín chỉ',
                  value: '${event.soTinChi} tín chỉ',
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Get.back(),
                  child: Text(
                    'Đóng',
                    style: TextStyles.bold.copyWith(fontSize: AppFontSizes.mediumLarge,color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.medium.copyWith(
                  fontSize: AppFontSizes.small,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyles.semiBold.copyWith(
                  fontSize: AppFontSizes.medium,
                  color: AppColors.textTitle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(
    BuildContext context,
    VcoreExamScheduleController controller,
  ) {
    return Obx(() {
      final incompleteCount = controller.incompleteExams.length;
      final extraTermCount = controller.extraTermCourses.length;

      final hasExtraTerm = extraTermCount > 0;
      final tabCount = hasExtraTerm ? 3 : 2;

      final isTheoNgay = !controller.showIncompleteExams.value &&
          !controller.showExtraTermCourses.value;
      final isChuaCapNhat = controller.showIncompleteExams.value;
      final isHocKyHe = controller.showExtraTermCourses.value;

      final responsive = VnuResponsiveContext.of(context);
      final selectorHeight = responsive.isVeryLargeText
          ? 76.0
          : responsive.isLargeText
              ? 64.0
              : 52.0;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        height: selectorHeight,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / tabCount;

            Alignment selectedAlignment;
            if (isTheoNgay) {
              selectedAlignment = Alignment.centerLeft;
            } else if (isChuaCapNhat && hasExtraTerm) {
              selectedAlignment = Alignment.center;
            } else {
              selectedAlignment = Alignment.centerRight;
            }

            return Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: selectedAlignment,
                  child: SizedBox(
                    width: itemWidth,
                    height: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeButton(
                        label: 'Theo ngày',
                        selected: isTheoNgay,
                        onTap: () {
                          controller.showIncompleteExams.value = false;
                          controller.showExtraTermCourses.value = false;
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildModeButton(
                        label: 'Chưa cập nhật',
                        selected: isChuaCapNhat,
                        count: incompleteCount,
                        onTap: () {
                          controller.showIncompleteExams.value = true;
                          controller.showExtraTermCourses.value = false;
                        },
                      ),
                    ),
                    if (hasExtraTerm)
                      Expanded(
                        child: _buildModeButton(
                          label: 'Học kỳ hè',
                          selected: isHocKyHe,
                          count: extraTermCount,
                          onTap: () {
                            controller.showIncompleteExams.value = false;
                            controller.showExtraTermCourses.value = true;
                          },
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    });
  }

  String _displayTimeRange(ScheduleEvent event) {
    if (event.type == ScheduleType.classSession) {
      return '';
    }

    // Lịch thi giữ nguyên giờ do API lịch thi cung cấp.
    return _mapExamTime(event.startTime, event.endTime);
  }
  Widget _buildModeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    int? count,
  }) {
    final hasCount = count != null && count > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? const Color(0xFF18A957) : Colors.grey.shade600,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasCount) ...[
                  const SizedBox(width: 5),
                  Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E6),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFFFE8CC),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: _examColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncompleteExamsList(VcoreExamScheduleController controller) {
    final list = controller.incompleteExams;

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF18A957)),
              const SizedBox(height: 12),
              Text(
                'Tất cả lịch thi đã được cập nhật đầy đủ',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE8CC), width: 1),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_rounded, color: _examColor, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Các lịch thi này đã có học phần nhưng chưa được cập nhật đủ ngày, giờ, phòng thi hoặc SBD.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF8A6500),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...list.map((exam) => _buildIncompleteExamCard(exam)),
      ],
    );
  }

  Widget _buildIncompleteExamCard(LichThiHocKyModel exam) {
    final subjectName = exam.tenHocPhan ?? 'Học phần chưa cập nhật tên';
    final subjectCode = exam.maHocPhan ?? 'Mã HP';
    final credits = exam.soTinChi ?? '0';
    final examType = exam.hinhThucThi ?? 'Chưa cập nhật';

    final date = exam.ngayThi != null && exam.ngayThi!.isNotEmpty ? exam.ngayThi! : 'Chưa cập nhật';
    final time = exam.gioBatDauThi != null && exam.gioBatDauThi!.isNotEmpty ? exam.gioBatDauThi! : 'Chưa cập nhật';
    final room = exam.phongThi != null && exam.phongThi!.isNotEmpty ? exam.phongThi! : 'Chưa cập nhật';
    final sbd = exam.sobaodanh != null && exam.sobaodanh!.isNotEmpty ? exam.sobaodanh! : 'Chưa cập nhật';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subjectName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212529),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$subjectCode • $credits tín chỉ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _examLightColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Hình thức: $examType',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _examColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          _buildInfoRow('Ngày thi', date, isWarning: date == 'Chưa cập nhật'),
          const SizedBox(height: 6),
          _buildInfoRow('Giờ thi', time, isWarning: time == 'Chưa cập nhật'),
          const SizedBox(height: 6),
          _buildInfoRow('Phòng thi', room, isWarning: room == 'Chưa cập nhật'),
          const SizedBox(height: 6),
          _buildInfoRow('SBD', sbd, isWarning: sbd == 'Chưa cập nhật'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isWarning = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isWarning ? FontWeight.bold : FontWeight.w600,
            color: isWarning ? _examColor : const Color(0xFF212529),
          ),
        ),
      ],
    );
  }

  Widget _buildExtraTermCoursesList(
      BuildContext context,
      VcoreExamScheduleController controller,
      ) {
    final list = controller.extraTermCourses;

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'Không có học phần học kỳ hè',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.greenAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.greenAccent.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_rounded,
                color: AppColors.greenAccent,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Các học phần học kỳ hè/kỳ phụ được liệt kê riêng vì thời gian học chưa đủ chắc chắn để hiển thị theo lịch ngày.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF137A3A),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...list.map((event) => _buildExtraTermCourseCard(context, event)),
      ],
    );
  }

  Widget _buildExtraTermCourseCard(
      BuildContext context,
      ScheduleEvent event,
      ) {
    final subjectName = event.title.trim().isNotEmpty ? event.title : '?';
    final subjectCode = event.hocPhanCode?.trim().isNotEmpty == true
        ? event.hocPhanCode!
        : '?';
    final credits = event.soTinChi?.trim().isNotEmpty == true
        ? event.soTinChi!
        : '?';
    final group = event.nhom?.trim().isNotEmpty == true ? event.nhom! : '?';
    final location = event.location.trim().isNotEmpty ? event.location : '?';
    final teacher = event.teacher.trim().isNotEmpty ? event.teacher : '?';
    final lessonRange = _formatLessonRange(event);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.calendarBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.greenAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.greenAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectName,
                      style: TextStyles.bold.copyWith(
                        fontSize: AppFontSizes.medium,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subjectCode • $credits tín chỉ • Nhóm $group',
                      style: TextStyles.regular.copyWith(
                        fontSize: AppFontSizes.small,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Tiết học',
            lessonRange.isNotEmpty ? lessonRange : '?',
            isWarning: lessonRange.isEmpty,
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            'Phòng học',
            location,
            isWarning: location == '?',
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            'Giảng viên',
            teacher,
            isWarning: teacher == '?',
          ),
        ],
      ),
    );
  }
}


