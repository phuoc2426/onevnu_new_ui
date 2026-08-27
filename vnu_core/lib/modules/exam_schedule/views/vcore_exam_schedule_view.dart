import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/academic_period_config.dart';
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

enum _TermDateField { start, end }

class VcoreExamScheduleView extends StatelessWidget {
  static const Color _classColor = AppColors.greenAccent;
  static const Color _examColor = Color(0xFFFFB703);
  static const Color _examLightColor = Color(0xFFFFF8E1);
  static const Color _examBorderColor = Color(0xFFFFECB3);
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

    final rangeText =
        '${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}';
    final isPersonal = controller.hasPersonalTermDateOverride.value;

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
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
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
                            'Kho\u1ea3ng ng\u00e0y l\u1ecbch h\u1ecdc',
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
                              'C\u00e1 nh\u00e2n',
                              style: TextStyles.semiBold.copyWith(
                                fontSize: AppFontSizes.font11,
                                color: AppColors.greenAccent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      rangeText,
                      style: TextStyles.bold.copyWith(
                        fontSize: AppFontSizes.mediumSmall,
                        color: AppColors.greenAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPersonal
                          ? 'B\u1ea1n \u0111ang d\u00f9ng m\u1ed1c th\u1eddi gian t\u00f9y ch\u1ec9nh tr\u00ean \u1ee9ng d\u1ee5ng.'
                          : 'M\u1ed1c hi\u1ec7n t\u1ea1i t\u1eeb h\u1ec7 th\u1ed1ng. Ch\u1ea1m \u0111\u1ec3 t\u00f9y ch\u1ec9nh.',
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
    );
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
    DateTime focusedDay = startDate;
    _TermDateField? activeDateField;

    AcademicPeriodConfig draftPeriodConfig = controller.academicPeriodConfig;
    int selectedPeriod = 1;
    bool hasPersonalDateOverride =
        controller.hasPersonalTermDateOverride.value;
    bool hasPersonalPeriodOverride =
        controller.hasPersonalAcademicPeriodOverride.value;
    bool isSaving = false;
    bool isRestoring = false;
    final List<String> actionLogs = <String>[];

    void addActionLog(String message) {
      actionLogs.insert(
        0,
        '${DateFormat('HH:mm:ss').format(DateTime.now())} • $message',
      );
      if (actionLogs.length > 6) {
        actionLogs.removeRange(6, actionLogs.length);
      }
    }

    final firstDay = DateTime(startDate.year - 1, 1, 1);
    final lastDay = DateTime(endDate.year + 1, 12, 31);

    logInfo(
      '[SCHEDULE_ADJUST_UI] action=open '
      'start=${DateFormat('yyyy-MM-dd').format(startDate)} '
      'end=${DateFormat('yyyy-MM-dd').format(endDate)} '
      'personalDate=$hasPersonalDateOverride '
      'personalPeriod=$hasPersonalPeriodOverride',
    );

    Get.bottomSheet(
      StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final rangeText =
              '${DateFormat('dd/MM/yyyy').format(startDate)}  →  ${DateFormat('dd/MM/yyyy').format(endDate)}';
          final totalDays = endDate.difference(startDate).inDays + 1;
          final resolvedPeriods = draftPeriodConfig.resolveAll();
          final selectedRange = resolvedPeriods[selectedPeriod];
          final selectedRule =
              _effectivePeriodRule(draftPeriodConfig, selectedPeriod);
          final selectedAutoStart =
              selectedPeriod > 1 && selectedRule.autoStart;
          final isPersonal =
              hasPersonalDateOverride || hasPersonalPeriodOverride;

          return Container(
            height: MediaQuery.of(sheetContext).size.height * 0.92,
            decoration: const BoxDecoration(
              color: Color(0xFFF7F8FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.greenAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: AppColors.greenAccent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Điều chỉnh thời gian lịch học',
                                style: TextStyles.bold.copyWith(
                                  fontSize: AppFontSizes.large,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Chỉnh khoảng ngày và giờ từng tiết ngay trên ứng dụng.',
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
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                            icon: Icons.date_range_rounded,
                            title: 'Khoảng ngày lịch học',
                            subtitle:
                                'Bấm đúng ô bắt đầu/kết thúc rồi mới chọn ngày.',
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildDateRangeSummaryItem(
                                    icon: Icons.play_circle_outline_rounded,
                                    label: 'Ngày bắt đầu',
                                    value: DateFormat('dd/MM/yyyy')
                                        .format(startDate),
                                    selected:
                                        activeDateField == _TermDateField.start,
                                    accentColor: AppColors.greenAccent,
                                    onTap: () {
                                      logInfo(
                                        '[SCHEDULE_ADJUST_UI] action=select_date_field field=start',
                                      );
                                      setModalState(() {
                                        activeDateField = _TermDateField.start;
                                        focusedDay = startDate;
                                      });
                                    },
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                Expanded(
                                  child: _buildDateRangeSummaryItem(
                                    icon: Icons.flag_outlined,
                                    label: 'Ngày kết thúc',
                                    value:
                                        DateFormat('dd/MM/yyyy').format(endDate),
                                    selected:
                                        activeDateField == _TermDateField.end,
                                    accentColor: const Color(0xFF1976D2),
                                    onTap: () {
                                      logInfo(
                                        '[SCHEDULE_ADJUST_UI] action=select_date_field field=end',
                                      );
                                      setModalState(() {
                                        activeDateField = _TermDateField.end;
                                        focusedDay = endDate;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Row(
                              key: ValueKey(activeDateField),
                              children: [
                                Icon(
                                  activeDateField == null
                                      ? Icons.touch_app_outlined
                                      : Icons.touch_app_rounded,
                                  size: 16,
                                  color: activeDateField == _TermDateField.end
                                      ? const Color(0xFF1976D2)
                                      : activeDateField == _TermDateField.start
                                          ? AppColors.greenAccent
                                          : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    activeDateField == _TermDateField.start
                                        ? 'ĐANG CHỌN NGÀY BẮT ĐẦU • Chạm một ngày trên lịch.'
                                        : activeDateField == _TermDateField.end
                                            ? 'ĐANG CHỌN NGÀY KẾT THÚC • Chạm một ngày từ ngày bắt đầu trở đi.'
                                            : 'Chạm vào ô Ngày bắt đầu hoặc Ngày kết thúc trước khi chọn trên lịch.',
                                    style: TextStyles.semiBold.copyWith(
                                      fontSize: AppFontSizes.font11,
                                      color: activeDateField == _TermDateField.end
                                          ? const Color(0xFF1976D2)
                                          : activeDateField == _TermDateField.start
                                              ? AppColors.greenAccent
                                              : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                            child: TableCalendar<void>(
                              locale: 'vi_VN',
                              firstDay: firstDay,
                              lastDay: lastDay,
                              focusedDay: focusedDay,
                              calendarFormat: CalendarFormat.month,
                              startingDayOfWeek: StartingDayOfWeek.monday,
                              rangeStartDay: startDate,
                              rangeEndDay: endDate,
                              rangeSelectionMode: RangeSelectionMode.toggledOn,
                              availableGestures:
                                  AvailableGestures.horizontalSwipe,
                              enabledDayPredicate: (day) {
                                if (activeDateField == null) return false;
                                if (activeDateField == _TermDateField.end) {
                                  final normalized =
                                      DateTime(day.year, day.month, day.day);
                                  return !normalized.isBefore(startDate);
                                }
                                return true;
                              },
                              rowHeight: 44,
                              daysOfWeekHeight: 30,
                              headerStyle: HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                leftChevronIcon: const Icon(
                                  Icons.chevron_left_rounded,
                                  color: AppColors.greenAccent,
                                ),
                                rightChevronIcon: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.greenAccent,
                                ),
                                titleTextStyle: TextStyles.bold.copyWith(
                                  fontSize: AppFontSizes.medium,
                                  color: Colors.black87,
                                ),
                              ),
                              daysOfWeekStyle: DaysOfWeekStyle(
                                weekdayStyle: TextStyles.semiBold.copyWith(
                                  fontSize: AppFontSizes.font11,
                                  color: Colors.grey.shade600,
                                ),
                                weekendStyle: TextStyles.semiBold.copyWith(
                                  fontSize: AppFontSizes.font11,
                                  color: Colors.redAccent.shade200,
                                ),
                              ),
                              calendarStyle: CalendarStyle(
                                outsideDaysVisible: false,
                                isTodayHighlighted: true,
                                todayDecoration: BoxDecoration(
                                  color:
                                      AppColors.greenAccent.withOpacity(0.10),
                                  shape: BoxShape.circle,
                                ),
                                todayTextStyle: const TextStyle(
                                  color: AppColors.greenAccent,
                                  fontWeight: FontWeight.w800,
                                ),
                                rangeHighlightColor:
                                    AppColors.greenAccent.withOpacity(0.10),
                                rangeStartDecoration: const BoxDecoration(
                                  color: AppColors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                                rangeEndDecoration: const BoxDecoration(
                                  color: Color(0xFF1976D2),
                                  shape: BoxShape.circle,
                                ),
                                rangeStartTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                                rangeEndTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                                withinRangeTextStyle: const TextStyle(
                                  color: AppColors.greenAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                                disabledTextStyle: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontWeight: FontWeight.w500,
                                ),
                                defaultTextStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                                weekendTextStyle: TextStyle(
                                  color: Colors.redAccent.shade200,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPageChanged: (day) {
                                focusedDay = day;
                              },
                              onRangeSelected: (_, __, focused) {
                                if (activeDateField == null) return;

                                final picked = DateTime(
                                  focused.year,
                                  focused.month,
                                  focused.day,
                                );
                                final field = activeDateField!;
                                logInfo(
                                  '[SCHEDULE_ADJUST_UI] action=pick_date '
                                  'field=${field.name} '
                                  'value=${DateFormat('yyyy-MM-dd').format(picked)}',
                                );

                                setModalState(() {
                                  focusedDay = picked;
                                  if (field == _TermDateField.start) {
                                    startDate = picked;
                                    if (endDate.isBefore(startDate)) {
                                      endDate = startDate;
                                    }
                                    activeDateField = _TermDateField.end;
                                  } else {
                                    endDate = picked;
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildSectionTitle(
                            icon: Icons.schedule_rounded,
                            title: 'Giờ tiết học',
                            subtitle:
                                'Chọn tiết, sau đó quyết định tự tính hoặc nhập giờ riêng.',
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMinuteStepper(
                                        label: 'Thời lượng 1 tiết',
                                        value: draftPeriodConfig
                                            .lessonDurationMinutes,
                                        min: 5,
                                        max: 180,
                                        step: 5,
                                        onChanged: (value) {
                                          logInfo(
                                            '[SCHEDULE_ADJUST_UI] action=change_duration value=$value',
                                          );
                                          setModalState(() {
                                            draftPeriodConfig =
                                                draftPeriodConfig.copyWith(
                                              configured: true,
                                              lessonDurationMinutes: value,
                                              updatedAt: DateTime.now(),
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildMinuteStepper(
                                        label: 'Nghỉ mặc định',
                                        value:
                                            draftPeriodConfig.defaultBreakMinutes,
                                        min: 0,
                                        max: 120,
                                        step: 5,
                                        onChanged: (value) {
                                          logInfo(
                                            '[SCHEDULE_ADJUST_UI] action=change_default_break value=$value',
                                          );
                                          setModalState(() {
                                            draftPeriodConfig =
                                                draftPeriodConfig.copyWith(
                                              configured: true,
                                              defaultBreakMinutes: value,
                                              updatedAt: DateTime.now(),
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<int>(
                                  value: selectedPeriod,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Chọn tiết',
                                    prefixIcon: const Icon(
                                      Icons.view_timeline_outlined,
                                      color: AppColors.greenAccent,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAF9),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: AppColors.greenAccent,
                                        width: 1.6,
                                      ),
                                    ),
                                  ),
                                  items: [
                                    for (var period = 1;
                                        period <= draftPeriodConfig.maxPeriods;
                                        period++)
                                      DropdownMenuItem<int>(
                                        value: period,
                                        child: Text('Tiết $period'),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    logInfo(
                                      '[SCHEDULE_ADJUST_UI] action=select_period period=$value',
                                    );
                                    setModalState(() {
                                      selectedPeriod = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAF9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.greenAccent
                                          .withOpacity(0.16),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Tiết $selectedPeriod',
                                              style: TextStyles.bold.copyWith(
                                                fontSize: AppFontSizes.medium,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: selectedAutoStart
                                                  ? AppColors.greenAccent
                                                      .withOpacity(0.10)
                                                  : Colors.orange
                                                      .withOpacity(0.10),
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                            ),
                                            child: Text(
                                              selectedPeriod == 1
                                                  ? 'MỐC GỐC'
                                                  : selectedAutoStart
                                                      ? 'TỰ TÍNH'
                                                      : 'NHẬP TAY',
                                              style: TextStyles.bold.copyWith(
                                                fontSize:
                                                    AppFontSizes.font10_5,
                                                color: selectedAutoStart
                                                    ? AppColors.greenAccent
                                                    : Colors.orange.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (selectedPeriod > 1) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Tự tính giờ vào từ tiết trước',
                                                    style: TextStyles.semiBold
                                                        .copyWith(
                                                      fontSize: AppFontSizes
                                                          .font12_5,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Giờ ra tiết ${selectedPeriod - 1} + thời gian nghỉ.',
                                                    style: TextStyles.regular
                                                        .copyWith(
                                                      fontSize:
                                                          AppFontSizes.font11,
                                                      color: Colors
                                                          .grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Switch.adaptive(
                                              value: selectedAutoStart,
                                              activeColor:
                                                  AppColors.greenAccent,
                                              onChanged: (value) {
                                                final currentResolved =
                                                    draftPeriodConfig
                                                        .resolveAll()[selectedPeriod];
                                                final rule =
                                                    _effectivePeriodRule(
                                                  draftPeriodConfig,
                                                  selectedPeriod,
                                                );
                                                logInfo(
                                                  '[SCHEDULE_ADJUST_UI] action=toggle_auto_start '
                                                  'period=$selectedPeriod value=$value',
                                                );
                                                setModalState(() {
                                                  draftPeriodConfig =
                                                      draftPeriodConfig
                                                          .withPeriodRule(
                                                    AcademicPeriodRule(
                                                      periodNumber:
                                                          selectedPeriod,
                                                      startTime: value
                                                          ? rule.startTime
                                                          : currentResolved
                                                              ?.startTime,
                                                      endTime: rule.endTime,
                                                      autoStart: value,
                                                      // Bật/tắt auto không tự biến nghỉ mặc định
                                                      // thành override riêng của tiết này.
                                                      breakBeforeMinutes:
                                                          rule.breakBeforeMinutes,
                                                      manualOverride:
                                                          rule.manualOverride,
                                                    ),
                                                  );
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        _buildMinuteStepper(
                                          label: 'Nghỉ trước Tiết $selectedPeriod',
                                          value: selectedRule
                                                  .breakBeforeMinutes ??
                                              draftPeriodConfig
                                                  .defaultBreakMinutes,
                                          min: 0,
                                          max: 180,
                                          step: 5,
                                          onChanged: (value) {
                                            final rule =
                                                _effectivePeriodRule(
                                              draftPeriodConfig,
                                              selectedPeriod,
                                            );
                                            logInfo(
                                              '[SCHEDULE_ADJUST_UI] action=change_period_break '
                                              'period=$selectedPeriod value=$value',
                                            );
                                            setModalState(() {
                                              draftPeriodConfig =
                                                  draftPeriodConfig
                                                      .withPeriodRule(
                                                AcademicPeriodRule(
                                                  periodNumber:
                                                      selectedPeriod,
                                                  startTime: rule.startTime,
                                                  endTime: rule.endTime,
                                                  autoStart: rule.autoStart,
                                                  breakBeforeMinutes: value,
                                                  manualOverride:
                                                      rule.manualOverride,
                                                ),
                                              );
                                            });
                                          },
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildClockField(
                                              label: 'Giờ vào',
                                              value:
                                                  selectedRange?.startTime ?? '--:--',
                                              enabled: selectedPeriod == 1 ||
                                                  !selectedAutoStart,
                                              helper: selectedAutoStart
                                                  ? 'Tự tính'
                                                  : 'Chạm để chọn',
                                              onTap: () async {
                                                final current = selectedRange
                                                        ?.startTime ??
                                                    selectedRule.startTime ??
                                                    '07:00';
                                                final picked =
                                                    await _pickClock(
                                                  sheetContext,
                                                  current,
                                                  'Chọn giờ vào Tiết $selectedPeriod',
                                                );
                                                if (picked == null) return;
                                                final rule =
                                                    _effectivePeriodRule(
                                                  draftPeriodConfig,
                                                  selectedPeriod,
                                                );
                                                logInfo(
                                                  '[SCHEDULE_ADJUST_UI] action=change_start_time '
                                                  'period=$selectedPeriod value=$picked',
                                                );
                                                setModalState(() {
                                                  draftPeriodConfig =
                                                      draftPeriodConfig
                                                          .withPeriodRule(
                                                    AcademicPeriodRule(
                                                      periodNumber:
                                                          selectedPeriod,
                                                      startTime: picked,
                                                      endTime: rule.endTime,
                                                      autoStart: false,
                                                      breakBeforeMinutes: rule
                                                          .breakBeforeMinutes,
                                                      manualOverride:
                                                          rule.manualOverride,
                                                    ),
                                                  );
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _buildClockField(
                                              label: 'Giờ ra',
                                              value:
                                                  selectedRange?.endTime ?? '--:--',
                                              enabled: true,
                                              helper: selectedRule.manualOverride
                                                  ? 'Đã nhập riêng'
                                                  : 'Theo thời lượng chung',
                                              onTap: () async {
                                                final current = selectedRange
                                                        ?.endTime ??
                                                    selectedRule.endTime ??
                                                    '07:50';
                                                final picked =
                                                    await _pickClock(
                                                  sheetContext,
                                                  current,
                                                  'Chọn giờ ra Tiết $selectedPeriod',
                                                );
                                                if (picked == null) return;
                                                final rule =
                                                    _effectivePeriodRule(
                                                  draftPeriodConfig,
                                                  selectedPeriod,
                                                );
                                                logInfo(
                                                  '[SCHEDULE_ADJUST_UI] action=change_end_time '
                                                  'period=$selectedPeriod value=$picked',
                                                );
                                                setModalState(() {
                                                  draftPeriodConfig =
                                                      draftPeriodConfig
                                                          .withPeriodRule(
                                                    AcademicPeriodRule(
                                                      periodNumber:
                                                          selectedPeriod,
                                                      startTime: rule.startTime,
                                                      endTime: picked,
                                                      autoStart: rule.autoStart,
                                                      breakBeforeMinutes: rule
                                                          .breakBeforeMinutes,
                                                      manualOverride: true,
                                                    ),
                                                  );
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (selectedRule.manualOverride) ...[
                                        const SizedBox(height: 6),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () {
                                              final rule =
                                                  _effectivePeriodRule(
                                                draftPeriodConfig,
                                                selectedPeriod,
                                              );
                                              logInfo(
                                                '[SCHEDULE_ADJUST_UI] action=clear_end_override period=$selectedPeriod',
                                              );
                                              setModalState(() {
                                                draftPeriodConfig =
                                                    draftPeriodConfig
                                                        .withPeriodRule(
                                                  AcademicPeriodRule(
                                                    periodNumber:
                                                        selectedPeriod,
                                                    startTime: rule.startTime,
                                                    endTime: rule.endTime,
                                                    autoStart: rule.autoStart,
                                                    breakBeforeMinutes: rule
                                                        .breakBeforeMinutes,
                                                    manualOverride: false,
                                                  ),
                                                );
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.auto_fix_high_rounded,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Giờ ra theo thời lượng chung',
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.greenAccent
                                              .withOpacity(0.07),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          selectedRange == null
                                              ? 'Chưa thể tính được giờ Tiết $selectedPeriod.'
                                              : 'Kết quả Tiết $selectedPeriod: ${selectedRange.startTime} → ${selectedRange.endTime}',
                                          style: TextStyles.semiBold.copyWith(
                                            fontSize: AppFontSizes.font12,
                                            color: AppColors.greenAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.greenAccent.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.greenAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '$rangeText • $totalDays ngày. Giờ tiết được dùng trực tiếp để dựng lại lịch học trên app.',
                                    style: TextStyles.medium.copyWith(
                                      fontSize: AppFontSizes.font11_5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Nhật ký thao tác',
                                        style: TextStyles.semiBold.copyWith(
                                          fontSize: AppFontSizes.font12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        actionLogs.isEmpty
                                            ? 'Chưa có thao tác trong lần mở này.'
                                            : actionLogs.take(4).join('\n'),
                                        style: TextStyles.regular.copyWith(
                                          fontSize: AppFontSizes.font11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isPersonal) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Đang có điều chỉnh cá nhân. Khôi phục mặc định sẽ xóa cả khoảng ngày và giờ tiết cá nhân.',
                              style: TextStyles.regular.copyWith(
                                fontSize: AppFontSizes.font11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      MediaQuery.of(sheetContext).padding.bottom + 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isRestoring || isSaving
                                ? null
                                : () async {
                                    logInfo(
                                      '[SCHEDULE_ADJUST_UI] action=restore_pressed',
                                    );
                                    setModalState(() {
                                      isRestoring = true;
                                      addActionLog('Bắt đầu khôi phục mặc định...');
                                    });
                                    try {
                                      final restored = await controller
                                          .restorePersonalScheduleDefaults();
                                      if (!sheetContext.mounted) return;

                                      final restoredStart =
                                          controller.currentTermStartDate;
                                      final restoredEnd =
                                          controller.currentTermEndDate;
                                      setModalState(() {
                                        isRestoring = false;
                                        if (restored &&
                                            restoredStart != null &&
                                            restoredEnd != null) {
                                          startDate = DateTime(
                                            restoredStart.year,
                                            restoredStart.month,
                                            restoredStart.day,
                                          );
                                          endDate = DateTime(
                                            restoredEnd.year,
                                            restoredEnd.month,
                                            restoredEnd.day,
                                          );
                                          focusedDay = startDate;
                                          activeDateField = null;
                                          draftPeriodConfig =
                                              controller.academicPeriodConfig;
                                          if (selectedPeriod >
                                              draftPeriodConfig.maxPeriods) {
                                            selectedPeriod =
                                                draftPeriodConfig.maxPeriods;
                                          }
                                          hasPersonalDateOverride = false;
                                          hasPersonalPeriodOverride = false;
                                          addActionLog(
                                            'Đã khôi phục mặc định và cập nhật lịch ngay.',
                                          );
                                        } else {
                                          addActionLog(
                                            'Khôi phục không thành công.',
                                          );
                                        }
                                      });
                                    } catch (error) {
                                      logError(
                                        '[SCHEDULE_ADJUST_UI] action=restore_failed '
                                        'error=${error.runtimeType}',
                                      );
                                      if (!sheetContext.mounted) return;
                                      setModalState(() {
                                        isRestoring = false;
                                        addActionLog(
                                          'Khôi phục lỗi: ${error.runtimeType}.',
                                        );
                                      });
                                    }
                                  },
                            icon: isRestoring
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.restart_alt_rounded,
                                    size: 19,
                                  ),
                            label: const Text('Khôi phục mặc định'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade800,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isSaving || isRestoring
                                ? null
                                : () async {
                                    logInfo(
                                      '[SCHEDULE_ADJUST_UI] action=save_pressed '
                                      'selectedPeriod=$selectedPeriod',
                                    );
                                    setModalState(() {
                                      isSaving = true;
                                      addActionLog(
                                        'Bắt đầu lưu điều chỉnh (Tiết $selectedPeriod đang được chọn)...',
                                      );
                                    });
                                    try {
                                      final saved = await controller
                                          .savePersonalScheduleAdjustments(
                                        startDate: startDate,
                                        endDate: endDate,
                                        periodConfig: draftPeriodConfig,
                                      );
                                      if (!sheetContext.mounted) return;
                                      setModalState(() {
                                        isSaving = false;
                                        if (saved) {
                                          hasPersonalDateOverride = true;
                                          hasPersonalPeriodOverride = true;
                                          draftPeriodConfig =
                                              controller.academicPeriodConfig;
                                          activeDateField = null;
                                          addActionLog(
                                            'Đã lưu và cập nhật lịch ngay, không cần thoát ra vào lại.',
                                          );
                                        } else {
                                          addActionLog(
                                            'Lưu không thành công.',
                                          );
                                        }
                                      });
                                    } catch (error) {
                                      logError(
                                        '[SCHEDULE_ADJUST_UI] action=save_failed '
                                        'error=${error.runtimeType}',
                                      );
                                      if (!sheetContext.mounted) return;
                                      setModalState(() {
                                        isSaving = false;
                                        addActionLog(
                                          'Lưu lỗi: ${error.runtimeType}.',
                                        );
                                      });
                                    }
                                  },
                            icon: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 19),
                            label: const Text('Lưu điều chỉnh'),
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
                ],
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

  AcademicPeriodRule _effectivePeriodRule(
    AcademicPeriodConfig config,
    int period,
  ) {
    final existing = config.ruleFor(period);
    if (existing != null) return existing;
    final resolved = config.resolveAll()[period];
    return AcademicPeriodRule(
      periodNumber: period,
      startTime: resolved?.startTime,
      endTime: resolved?.endTime,
      autoStart: period > 1,
      // null = dùng defaultBreakMinutes; chỉ ghi số khi người dùng tạo override riêng.
      breakBeforeMinutes: null,
      manualOverride: false,
    );
  }

  Widget _buildMinuteStepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required int step,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.semiBold.copyWith(
              fontSize: AppFontSizes.font11,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              _minuteButton(
                icon: Icons.remove_rounded,
                enabled: value > min,
                onTap: () => onChanged(
                  (value - step).clamp(min, max).toInt(),
                ),
              ),
              Expanded(
                child: Text(
                  '$value phút',
                  textAlign: TextAlign.center,
                  style: TextStyles.bold.copyWith(
                    fontSize: AppFontSizes.font12,
                    color: Colors.black87,
                  ),
                ),
              ),
              _minuteButton(
                icon: Icons.add_rounded,
                enabled: value < max,
                onTap: () => onChanged(
                  (value + step).clamp(min, max).toInt(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _minuteButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.greenAccent.withOpacity(0.10)
              : Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 17,
          color: enabled ? AppColors.greenAccent : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildClockField({
    required String label,
    required String value,
    required bool enabled,
    required String helper,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? AppColors.greenAccent.withOpacity(0.25)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyles.semiBold.copyWith(
                fontSize: AppFontSizes.font11,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyles.bold.copyWith(
                fontSize: AppFontSizes.large,
                color: enabled ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              helper,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.regular.copyWith(
                fontSize: AppFontSizes.font10_5,
                color: enabled
                    ? AppColors.greenAccent
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickClock(
    BuildContext context,
    String current,
    String title,
  ) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 7,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: title,
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      builder: (pickerContext, child) {
        final base = Theme.of(pickerContext);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: AppColors.greenAccent,
              secondary: AppColors.greenAccent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDateRangeSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    bool selected = false,
    Color accentColor = AppColors.greenAccent,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withOpacity(0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accentColor : Colors.transparent,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? accentColor.withOpacity(0.16)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: selected ? accentColor : Colors.grey.shade500,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.regular.copyWith(
                      fontSize: AppFontSizes.font11,
                      color: selected ? accentColor : Colors.grey.shade600,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.bold.copyWith(
                      fontSize: AppFontSizes.small,
                      color: selected ? accentColor : Colors.black87,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'ĐANG CHỌN',
                        style: TextStyles.bold.copyWith(
                          fontSize: 9,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
    final clockRange = _displayTimeRange(event);
    final lessonRange = _formatLessonRange(event);
    final clockParts = clockRange.split(' - ');

    final timelinePrimary = isClass
        ? (lessonRange.isNotEmpty ? lessonRange : 'Tiết học')
        : (clockParts.isNotEmpty ? clockParts[0] : '');
    final timelineSecondary = isClass
        ? clockRange
        : (clockParts.length > 1 ? clockParts[1] : '');

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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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

    final timeRange = _displayTimeRange(event);
    final parts = timeRange.split(' - ');
    if (parts.length < 2) return false;

    final endTimeStr = parts[1].trim();
    final timeParts = endTimeStr.split(':');
    if (timeParts.length != 2) return false;

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return false;

    final eventEndTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    return now.isAfter(eventEndTime);
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

  String _mapTietToTime(String startTime, String endTime) {
    if (startTime.trim().isEmpty && endTime.trim().isEmpty) {
      return 'Chưa có giờ';
    }

    // Exam API may already return a concrete time such as HH:mm.
    if (startTime.contains(':') || endTime.contains(':')) {
      if (endTime.trim().isEmpty || endTime.contains('phút')) {
        return startTime.trim().isEmpty ? 'Chưa có giờ' : startTime.trim();
      }
      return '${startTime.trim()} - ${endTime.trim()}';
    }

    final startLesson = int.tryParse(startTime.replaceAll(RegExp(r'[^0-9]'), ''));
    final endLesson = int.tryParse(endTime.replaceAll(RegExp(r'[^0-9]'), ''));

    if (startLesson == null || endLesson == null) {
      return '$startTime - $endTime';
    }

    const lessonStartTimes = <int, String>{
      1: '07:00',
      2: '08:00',
      3: '09:00',
      4: '10:00',
      5: '11:00',
      6: '13:00',
      7: '14:00',
      8: '15:00',
      9: '16:00',
      10: '17:00',
      11: '18:00',
      12: '19:00',
      13: '20:00',
    };

    const lessonEndTimes = <int, String>{
      1: '07:50',
      2: '08:50',
      3: '09:50',
      4: '10:50',
      5: '11:50',
      6: '13:50',
      7: '14:50',
      8: '15:50',
      9: '16:50',
      10: '17:50',
      11: '18:50',
      12: '19:50',
      13: '20:50',
    };

    final startStr = lessonStartTimes[startLesson] ?? 'Tiết $startLesson';
    final endStr = lessonEndTimes[endLesson] ?? 'Tiết $endLesson';

    return '$startStr - $endStr';
  }

  String _formatLessonRange(ScheduleEvent event) {
    if (event.type != ScheduleType.classSession) return '';

    final startLesson = int.tryParse(
      event.startTime.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final endLesson = int.tryParse(
      event.endTime.replaceAll(RegExp(r'[^0-9]'), ''),
    );

    if (startLesson == null || endLesson == null) return '';
    return 'Tiết $startLesson - $endLesson';
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
    final timeValue = isClass && lessonRange.isNotEmpty
        ? '$lessonRange\n$timeRange\n$displayDate'
        : '$timeRange\n$displayDate';
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

// Time & Date row
              _buildDetailItem(
                icon: Icons.access_time_rounded,
                iconColor: accentColor,
                title: 'Thời gian',
                value: timeValue,
              ),
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
    // Class times are already resolved once in VcoreExamScheduleController.
    // This guarantees Home and Calendar display the same ScheduleEvent clock.
    if (event.type == ScheduleType.classSession) {
      return event.displayTimeRange;
    }

    // Exam payload may contain an HH:mm value or a duration; keep existing
    // exam formatting behavior unchanged.
    return _mapTietToTime(event.startTime, event.endTime);
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
    final timeRange = _displayTimeRange(event);
    final lessonRange = _formatLessonRange(event);

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
            'Thời gian',
            lessonRange.isNotEmpty ? '$lessonRange • $timeRange' : timeRange,
            isWarning: timeRange == 'Chưa có giờ' || timeRange.contains('?'),
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

