import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

import '../controllers/vcore_exam_schedule_controller.dart';
import '../../../models/model.dart';

class VcoreExamScheduleView extends StatelessWidget {
  /// Optional: jump calendar to this date on open
  final DateTime? initialDate;

  const VcoreExamScheduleView({
    super.key,
    this.initialDate,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcoreExamScheduleController>(
      init: VcoreExamScheduleController(),
      builder: (controller) {
        if (initialDate != null) {
          controller.setInitialDate(initialDate!);
        }
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            if (controller.danhSachKieuTruong.isEmpty) {
              controller.getDanhSachKieuTruong();
            }
          },
          child: VcoreModuleScaffold(
            title: 'Lịch học & lịch thi',
            body: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
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
                      _buildSelectedFilterIndicator(controller),

                      const SizedBox(height: 8),

                      _buildCalendar(controller),

                      const SizedBox(height: 12),

                      _buildEventsHeader(context, controller),

                      _buildEventsList(context, controller),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedFilterIndicator(VcoreExamScheduleController controller) {
    final year = controller.namHocSelected.value ?? '';
    final sem = controller.hocKySelected.value?.ten != null
        ? 'Học kỳ ${controller.hocKySelected.value!.ten}'
        : '';
    final school = controller.kieuTruong.value?.toDisplayName() ?? '';

    if (year.isEmpty && sem.isEmpty && school.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.greenAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đang xem: $school • $year • $sem',
              style: TextStyles.medium.copyWith(
                  fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(VcoreExamScheduleController controller) {
    return Container(
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
            firstDay: DateTime.now().subtract(const Duration(days: 365 * 3)),
            lastDay: DateTime.now().add(const Duration(days: 365 * 3)),
            focusedDay: controller.focusedDay.value,
            selectedDayPredicate: (day) =>
                isSameDay(controller.selectedDay.value, day),
            locale: 'vi_VN',
            calendarFormat: CalendarFormat.month,
            availableGestures: AvailableGestures.horizontalSwipe,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
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
                  fontSize: 12, color: Colors.grey.shade800),
              weekendStyle: TextStyles.medium.copyWith(
                  fontSize: 12, color: Colors.red.shade700),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: TextStyles.regular.copyWith(
                  fontSize: 14, color: Colors.black87),
              weekendTextStyle: TextStyles.regular.copyWith(
                  fontSize: 14, color: Colors.red.shade700),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              controller.selectedDay.value = selectedDay;
              controller.focusedDay.value = focusedDay;
              controller.updateSelectedEvents();
            },
            onPageChanged: (focusedDay) {
              controller.focusedDay.value = focusedDay;
            },
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
                            color: AppColors.orangeAccent,
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
                        color: Colors.white, fontSize: 14),
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
                        color: AppColors.blueAccent, fontSize: 14),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(AppColors.greenAccent, 'Có lớp học'),
          const SizedBox(width: 24),
          _buildLegendItem(AppColors.orangeAccent, 'Có lịch thi'),
          const SizedBox(width: 24),
          _buildLegendItem(AppColors.blueAccent, 'Hôm nay'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyles.medium.copyWith(
              fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildEventsHeader(BuildContext context,
      VcoreExamScheduleController controller) {
    final rawDate = controller.selectedDay.value;
    final dayOfWeek = _getVietnameseDayOfWeek(rawDate.weekday);
    final dateStr = DateFormat('dd/MM/yyyy').format(rawDate);
    final displayDate = '$dayOfWeek, ngày $dateStr';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              displayDate,
              style: TextStyles.bold.copyWith(
                  fontSize: 14, color: AppColors.greenAccent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showFilterBottomSheet(context, controller),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greenAccent, width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.greenAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Xem lịch khác',
                    style: TextStyles.semiBold.copyWith(
                      fontSize: 12,
                      color: AppColors.greenAccent,
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
                  fontSize: 14,
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

  Widget _buildTimelineEventRow(BuildContext context, ScheduleEvent event, bool isFirst,
      bool isLast) {
    final isClass = event.type == ScheduleType.classSession;
    final timeRange = _mapTietToTime(event.startTime, event.endTime);
    final parts = timeRange.split(' - ');
    final start = parts.isNotEmpty ? parts[0] : '';
    final end = parts.length > 1 ? parts[1] : '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 45,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  start,
                  style: TextStyles.bold.copyWith(
                      fontSize: 13, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  end,
                  style: TextStyles.regular.copyWith(
                      fontSize: 11, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
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
    final accentColor = isClass ? AppColors.greenAccent : AppColors.orangeAccent;

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
    final borderColor = isClass ? AppColors.calendarBorder : AppColors.calendarExamBorder;

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
                color: AppColors.orangeAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppColors.orangeAccent,
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
                      fontSize: 14,
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
                            fontSize: 12,
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
                            fontSize: 12,
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(
        event.date.year, event.date.month, event.date.day);

    bool isPast = false;
    if (eventDate.isBefore(today)) {
      isPast = true;
    } else if (eventDate.isAtSameMomentAs(today)) {
      final timeRange = _mapTietToTime(event.startTime, event.endTime);
      final parts = timeRange.split(' - ');
      if (parts.length > 1) {
        final endTimeStr = parts[1];
        final timeParts = endTimeStr.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]);
          final minute = int.tryParse(timeParts[1]);
          if (hour != null && minute != null) {
            final eventEndTime = DateTime(
                now.year, now.month, now.day, hour, minute);
            if (now.isAfter(eventEndTime)) {
              isPast = true;
            }
          }
        }
      }
    }

    final isClass = event.type == ScheduleType.classSession;
    final text = isPast
        ? (isClass ? 'Đã vào học' : 'Đã diễn ra')
        : 'Sắp diễn ra';
    final color = isPast ? AppColors.greenAccent : (isClass ? AppColors.blueAccent : AppColors.orangeAccent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPast ? Icons.check_circle_outline : Icons.access_time,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyles.semiBold.copyWith(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }

  String _mapTietToTime(String startTime, String endTime) {
    if (startTime.contains(':') || endTime.contains(':')) {
      return '$startTime - $endTime';
    }

    final startNum = int.tryParse(startTime.replaceAll(RegExp(r'[^0-9]'), ''));
    final endNum = int.tryParse(endTime.replaceAll(RegExp(r'[^0-9]'), ''));

    if (startNum == null || endNum == null) {
      if (startTime.isEmpty && endTime.isEmpty) return 'Chưa có giờ';
      return '$startTime - $endTime';
    }

    final startTimes = {
      1: '07:00',
      2: '07:55',
      3: '08:50',
      4: '09:55',
      5: '10:50',
      6: '13:00',
      7: '13:55',
      8: '14:50',
      9: '15:55',
      10: '16:50',
      11: '17:45',
      12: '18:40',
    };

    final endTimes = {
      1: '07:50',
      2: '08:45',
      3: '09:40',
      4: '10:45',
      5: '11:40',
      6: '13:50',
      7: '14:45',
      8: '15:40',
      9: '16:45',
      10: '17:40',
      11: '18:35',
      12: '19:30',
    };

    final startStr = startTimes[startNum] ?? '07:00';
    final endStr = endTimes[endNum] ?? '11:50';

    return '$startStr - $endStr';
  }

  void _showFilterBottomSheet(BuildContext context,
      VcoreExamScheduleController controller) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(
            left: 20, right: 20, top: 16, bottom: 30),
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
                  Text(
                    'Chọn thời gian hiển thị',
                    style: TextStyles.bold.copyWith(
                        fontSize: 16, color: Colors.black87),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (controller.danhSachKieuTruong.isNotEmpty) ...[
                Text(
                  'Cơ sở đào tạo',
                  style: TextStyles.bold.copyWith(
                      fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: Obx(() {
                      final selectedSchool = controller.kieuTruong.value;
                      final schools = controller.danhSachKieuTruong.toList();

                      return DropdownButton<String>(
                        value: schools.contains(selectedSchool)
                            ? selectedSchool
                            : null,
                        isExpanded: true,
                        items: schools.map((kt) {
                          return DropdownMenuItem<String>(
                            value: kt,
                            child: Text(
                              kt.toDisplayName(),
                              style: TextStyles.medium.copyWith(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            controller.kieuTruong.value = val;
                            controller.kieuTruong.refresh();
                            controller.getDanhSachHocKy();
                          }
                        },
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text(
                'Năm học',
                style: TextStyles.bold.copyWith(
                    fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: Obx(() {
                  final selectedYear = controller.namHocSelected.value;
                  final years = controller.danhSachNamHoc.toList();

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: years.length,
                    itemBuilder: (context, index) {
                      final year = years[index];
                      final isSelected = selectedYear == year;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildBottomSheetChip(
                          label: year,
                          isSelected: isSelected,
                          onTap: () {
                            controller.namHocSelected.value = year;
                            controller.namHocSelected.refresh();

                            controller.selectYear(year);

                            controller.namHocSelected.value = year;
                            controller.namHocSelected.refresh();
                            controller.resetToToday();
                          },
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),

              Text(
                'Học kỳ',
                style: TextStyles.bold.copyWith(
                    fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: Obx(() {
                  final selectedSemId = controller.hocKySelected.value?.id;
                  final selectedSemTen = controller.hocKySelected.value?.ten;
                  final semesters = controller.danhSachHocKyFilter.toList();

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: semesters.length,
                    itemBuilder: (context, index) {
                      final sem = semesters[index];
                      final isSelected = sem.id != null ? selectedSemId ==
                          sem.id : selectedSemTen == sem.ten;
                      final label = sem.ten != null
                          ? 'Học kỳ ${sem.ten}'
                          : 'Học kỳ';

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildBottomSheetChip(
                          label: label,
                          isSelected: isSelected,
                          onTap: () {
                            controller.hocKySelected.value = sem;
                            controller.hocKySelected.refresh();

                            controller.selectSemester(sem);

                            controller.hocKySelected.value = sem;
                            controller.hocKySelected.refresh();
                            controller.resetToToday();
                          },
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.greenAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Get.back(),
                  child: Text(
                    'Xác nhận',
                    style: TextStyles.bold.copyWith(fontSize: 15,color: Colors.white),
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

  Widget _buildBottomSheetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenAccent : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.greenAccentDark : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.greenAccentDark.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyles.semiBold.copyWith(
              fontSize: 13,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  void _showEventDetailBottomSheet(BuildContext context, ScheduleEvent event) {
    final isClass = event.type == ScheduleType.classSession;
    final accentColor = isClass ? AppColors.greenAccent : AppColors.orangeAccent;
    final bgLightColor = isClass ? AppColors.classCardBg : AppColors.examCardBg;
    final borderLightColor = isClass ? AppColors.classCardBorder : AppColors.examCardBorder;

    final rawDate = event.date;
    final dayOfWeek = _getVietnameseDayOfWeek(rawDate.weekday);
    final dateStr = DateFormat('dd/MM/yyyy').format(rawDate);
    final displayDate = '$dayOfWeek, $dateStr';

    final timeRange = _mapTietToTime(event.startTime, event.endTime);

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
                        fontSize: 10,
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
                  fontSize: 18,
                  color: AppColors.textTitle,
                ),
              ),
              if (event.hocPhanCode != null && event.hocPhanCode!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Mã học phần: ${event.hocPhanCode}',
                  style: TextStyles.medium.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 20),
              
              // Time & Date row
              _buildDetailItem(
                icon: Icons.access_time_rounded,
                iconColor: AppColors.blueAccent,
                title: 'Thời gian',
                value: '$timeRange\n$displayDate',
              ),
              const SizedBox(height: 16),

              // Location row
              _buildDetailItem(
                icon: Icons.location_on_rounded,
                iconColor: AppColors.error,
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
                    iconColor: AppColors.orangeAccent,
                    title: 'Hình thức thi',
                    value: event.hinhThucThi!,
                  ),
                  const SizedBox(height: 16),
                ],
                if (event.caThi != null && event.caThi!.isNotEmpty) ...[
                  _buildDetailItem(
                    icon: Icons.calendar_today_rounded,
                    iconColor: AppColors.blueAccent,
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
                    style: TextStyles.bold.copyWith(fontSize: 15,color: Colors.white),
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
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyles.semiBold.copyWith(
                  fontSize: 14,
                  color: AppColors.textTitle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

