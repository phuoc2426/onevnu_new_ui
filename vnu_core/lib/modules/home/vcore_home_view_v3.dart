import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:vnu_hoc_bong/vnu_hoc_bong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/browser/views/vcore_html_view.dart';
import 'package:vnu_core/modules/cam_nang/views/vcore_cam_nang_view.dart';
import 'package:vnu_core/modules/course_points/views/vcore_course_points_view.dart';
import 'package:vnu_core/modules/exam_schedule/views/vcore_exam_schedule_view.dart';
import 'package:vnu_core/modules/home/vcore_home_controller.dart';
import 'package:vnu_core/modules/inmapz/vcore_immap_view.dart';
import 'package:vnu_core/modules/motel/views/vcore_motel_view.dart';
import 'package:vnu_core/modules/news/views/vcore_news_detail_view.dart';
import 'package:vnu_core/modules/news/views/vcore_news_view_v3.dart';
import 'package:vnu_core/modules/news/views/vcore_jobs_view_v2.dart';
import 'package:vnu_core/modules/notify/views/vcore_notify_detail_view_v3.dart';
import 'package:vnu_core/modules/notify/views/vcore_notify_view_v3.dart';
import 'package:vnu_core/modules/one_door/views/vcore_one_door_view.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_view.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/cupertino.dart';
/* -------------------------------------------------------------------------- */
/*                       LOCAL NOTIFICATION SERVICE                           */
/* -------------------------------------------------------------------------- */

class _LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const String _channelId = 'vnu_calendar_reminder_channel';
  static const String _channelName = 'Nhắc lịch cá nhân';
  static const String _channelDescription =
      'Thông báo nhắc lịch theo ngày giờ sinh viên tự tạo';

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Có thể điều hướng tới màn danh sách lời nhắc ở đây nếu sau này cần.
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await init();

    final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }
}

class VcoreHomeViewV3 extends StatelessWidget {
  const VcoreHomeViewV3({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcoreHomeController>(
      init: VcoreHomeController(),
      tag: 'home_v3',
      builder: (controller) {
        controller.getLienKetDanhDau();

        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: _HomeWireframeBody(controller: controller),
        );
      },
    );
  }
}

class _HomeWireframeBody extends StatefulWidget {
  final VcoreHomeController controller;

  const _HomeWireframeBody({
    required this.controller,
  });

  @override
  State<_HomeWireframeBody> createState() => _HomeWireframeBodyState();
}

class _HomeWireframeBodyState extends State<_HomeWireframeBody> {
  int scheduleTabIndex = 0;
  int newsTabIndex = 0;

  final PageController schedulePageController = PageController(
    viewportFraction: 0.82,
  );

  final PageController newsPageController = PageController(
    initialPage: 1000,
    viewportFraction: 0.82,
  );

  Timer? newsAutoScrollTimer;

  bool get isStudyTab => scheduleTabIndex == 0;

  bool get isSchoolNewsTab => newsTabIndex == 0;

  List<String> _pinnedFunctionLabels = [
    'Lịch học & thi',
    'Điểm',
    'Học bổng',
    'Việc làm',
  ];

  static final List<_FunctionItem> _allAvailableFunctions = [
    _FunctionItem('Lịch học & thi', Colors.blue),
    _FunctionItem('Điểm', Colors.purple),
    _FunctionItem('Đăng ký môn', Colors.orange),
    _FunctionItem('Việc làm', Colors.green),
    _FunctionItem('Học phí', Colors.teal),
    _FunctionItem('Tài liệu', Colors.blue),
    _FunctionItem('Điểm danh', Colors.green),
    _FunctionItem('Học bổng', Colors.purple),
    _FunctionItem('Phản ánh', Colors.orange),
    _FunctionItem('Nội trú', Colors.purple),
    _FunctionItem('Phòng trọ', Colors.teal),
    _FunctionItem('Thủ tục', Colors.green),
    _FunctionItem('Thư viện', Colors.amber),
    _FunctionItem('Bản đồ', Colors.blue),
    _FunctionItem('Khác', Colors.grey),
  ];

  static final Map<String, List<_FunctionItem>> _groupedFunctions = {
    'Học tập': _allAvailableFunctions
        .where(
          (e) => [
        'Lịch học & thi',
        'Điểm',
        'Đăng ký môn',
        'Điểm danh',
      ].contains(e.label),
    )
        .toList(),
    'Dịch vụ': _allAvailableFunctions
        .where(
          (e) => [
        'Học phí',
        'Học bổng',
        'Thủ tục',
        'Nội trú',
        'Phản ánh',
      ].contains(e.label),
    )
        .toList(),
    'Tiện ích': _allAvailableFunctions
        .where(
          (e) => [
        'Tài liệu',
        'Thư viện',
        'Bản đồ',
        'Việc làm',
        'Phòng trọ',
        'Khác',
      ].contains(e.label),
    )
        .toList(),
  };

  @override
  void initState() {
    super.initState();
    _loadPinnedFunctions();
    _startNewsAutoScroll();
    _LocalNotificationService.init();
  }

  @override
  void dispose() {
    newsAutoScrollTimer?.cancel();
    schedulePageController.dispose();
    newsPageController.dispose();
    super.dispose();
  }

  void _startNewsAutoScroll() {
    newsAutoScrollTimer?.cancel();

    newsAutoScrollTimer = Timer.periodic(
      const Duration(seconds: 4),
          (_) {
        if (!mounted || !newsPageController.hasClients) {
          return;
        }

        final currentPage = newsPageController.page ?? 0;

        newsPageController.animateToPage(
          currentPage.round() + 1,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      },
    );
  }

  Future<void> _loadPinnedFunctions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('kPinnedFunctions_v3');

      if (saved != null && saved.isNotEmpty) {
        setState(() {
          _pinnedFunctionLabels = saved;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _savePinnedFunctions(List<String> labels) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('kPinnedFunctions_v3', labels);

      setState(() {
        _pinnedFunctionLabels = labels;
      });
    } catch (e) {
      // ignore
    }
  }

  void _showPinDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _RadialPinOverlay(
          initialPinned: _pinnedFunctionLabels,
          onSave: _savePinnedFunctions,
          groupedFunctions: _groupedFunctions,
          getIconForLabel: _getIconForLabel,
        );
      },
    );
  }

  void _handleFunctionTap(String label) {
    switch (label) {
      case 'Lịch học & thi':
        Get.to(() => const VcoreExamScheduleView());
        break;
      case 'Điểm':
        Get.to(() => const VcoreCoursePointsView());
        break;
      case 'Phản ánh':
        Get.to(() => const VcorePahtView());
        break;
      case 'Nội trú':
        snackBarWarning('Chức năng đang hoàn thiện');
        break;
      case 'Phòng trọ':
        Get.to(() => const VcoreMotelView());
        break;
      case 'Thủ tục':
        Get.to(() => const VcoreOneDoorView());
        break;
      case 'Bản đồ':
        Get.to(() => const VcoreImmapView());
        break;
      case 'Học bổng':
        Get.to(() => VnuHocBong.screen());
        break;
      case 'Khác':
        Get.to(() => const VcoreCamNangView());
        break;
      case 'Việc làm':
        Get.to(() => const VcoreJobsViewV2());
        break;
      default:
        snackBarWarning('Chức năng đang hoàn thiện');
        break;
    }
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Lịch học & thi':
        return Icons.calendar_month_rounded;
      case 'Điểm':
        return Icons.grade_rounded;
      case 'Đăng ký môn':
        return Icons.border_color_rounded;
      case 'Việc làm':
        return Icons.work_outline_rounded;
      case 'Học phí':
        return Icons.account_balance_wallet_rounded;
      case 'Tài liệu':
        return Icons.folder_open_rounded;
      case 'Điểm danh':
        return Icons.how_to_reg_rounded;
      case 'Học bổng':
        return Icons.card_membership_rounded;
      case 'Phản ánh':
        return Icons.rate_review_rounded;
      case 'Nội trú':
        return Icons.home_work_rounded;
      case 'Phòng trọ':
        return Icons.home_outlined;
      case 'Thủ tục':
        return Icons.assignment_turned_in_rounded;
      case 'Thư viện':
        return Icons.local_library_rounded;
      case 'Bản đồ':
        return Icons.map_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }

  void _showCreateCalendarReminderSheet() {
    DateTime focusedDay = DateTime.now();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    CalendarFormat calendarFormat = CalendarFormat.month;

    final noteController = TextEditingController();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          final selectedTimeText =
              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

          final selectedDateText = DateFormat('dd/MM/yyyy').format(selectedDate);

          return Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 14,
              bottom: MediaQuery.of(context).viewInsets.bottom + 18,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.brandGreen.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.edit_calendar_rounded,
                            color: AppColors.brandGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tạo lời nhắc',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.homeTextTitle,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Chọn ngày trên lịch, chọn giờ và nhập nội dung.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.homeTextSub,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.homeCardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.homeCardBorder,
                        ),
                      ),
                      child: TableCalendar(
                        locale: 'vi_VN',
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(
                          const Duration(days: 365 * 2),
                        ),
                        focusedDay: focusedDay,
                        calendarFormat: calendarFormat,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        selectedDayPredicate: (day) {
                          return isSameDay(selectedDate, day);
                        },
                        onDaySelected: (selectedDay, newFocusedDay) {
                          setModalState(() {
                            selectedDate = selectedDay;
                            focusedDay = newFocusedDay;
                          });
                        },
                        onFormatChanged: (format) {
                          setModalState(() {
                            calendarFormat = format;
                          });
                        },
                        onPageChanged: (newFocusedDay) {
                          focusedDay = newFocusedDay;
                        },
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.homeTextTitle,
                          ),
                          leftChevronIcon: Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.brandGreen,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.brandGreen,
                          ),
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.homeTextSub,
                          ),
                          weekendStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.homeRedWeekend,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          todayDecoration: BoxDecoration(
                            color: AppColors.brandGreen.withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: const TextStyle(
                            color: AppColors.brandGreen,
                            fontWeight: FontWeight.w900,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.brandGreen,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                          weekendTextStyle: const TextStyle(
                            color: AppColors.homeRedWeekend,
                            fontWeight: FontWeight.w600,
                          ),
                          defaultTextStyle: const TextStyle(
                            color: AppColors.homeTextTitle,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _reminderPickerTile(
                            icon: Icons.calendar_today_rounded,
                            title: 'Ngày đã chọn',
                            value: selectedDateText,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _reminderPickerTile(
                            icon: Icons.access_time_rounded,
                            title: 'Giờ',
                            value: selectedTimeText,
                            onTap: () {
                              _showPrettyTimePicker(
                                initialTime: selectedTime,
                                onTimeSelected: (pickedTime) {
                                  setModalState(() {
                                    selectedTime = pickedTime;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Nộp bài tập, chuẩn bị tài liệu...',
                        labelText: 'Nội dung nhắc',
                        filled: true,
                        fillColor: AppColors.homeCardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.brandGreen,
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () async {
                          final note = noteController.text.trim();

                          if (note.isEmpty) {
                            snackBarWarning('Vui lòng nhập nội dung nhắc');
                            return;
                          }

                          final scheduledTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          if (!scheduledTime.isAfter(DateTime.now())) {
                            snackBarWarning(
                              'Thời gian nhắc phải lớn hơn thời gian hiện tại',
                            );
                            return;
                          }

                          Get.back();

                          await _createManualCalendarReminder(
                            note: note,
                            scheduledTime: scheduledTime,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Tạo lời nhắc',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
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
    ).whenComplete(() {
      noteController.dispose();
    });
  }

  Widget _reminderPickerTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.homeCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.homeCardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withOpacity(0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: AppColors.brandGreen,
                size: 18,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.homeTextSub,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.homeTextTitle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createManualCalendarReminder({
    required String note,
    required DateTime scheduledTime,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timeText = DateFormat('HH:mm dd/MM/yyyy').format(scheduledTime);

    try {
      await _LocalNotificationService.scheduleReminder(
        id: id,
        title: 'Lời nhắc lịch',
        body: note,
        scheduledTime: scheduledTime,
        payload: jsonEncode({
          'id': id,
          'note': note,
          'scheduledTime': scheduledTime.toIso8601String(),
        }),
      );

      await _saveManualReminderToLocal(
        id: id,
        note: note,
        scheduledTime: scheduledTime,
      );

      snackBarSuccess('Đã tạo lời nhắc lúc $timeText');
    } catch (e) {
      snackBarWarning('Không thể tạo lời nhắc. Vui lòng kiểm tra quyền thông báo');
    }
  }

  Future<void> _saveManualReminderToLocal({
    required int id,
    required String note,
    required DateTime scheduledTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = prefs.getStringList('kManualCalendarReminders') ?? [];

    currentList.add(
      jsonEncode({
        'id': id,
        'note': note,
        'scheduledTime': scheduledTime.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );

    await prefs.setStringList('kManualCalendarReminders', currentList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
              child: Column(
                children: [
                  Obx(() => _buildHeader()),
                  const SizedBox(height: 22),
                  _buildOverview(),
                  const SizedBox(height: 14),
                  _buildScheduleBlock(),
                  const SizedBox(height: 14),
                  _buildQuickAccess(),
                  const SizedBox(height: 14),
                  _buildImportantNotice(),
                  const SizedBox(height: 14),
                  _buildNewsBlock(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg2.png',
            fit: BoxFit.cover,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final student = Globals().thongTinSinhVienModel.value;
    final className = Globals().lopDaoTaoModel.value?.ten;
    
    final nienKhoa = Globals().nienKhoaDaoTaoModel.value;
    String khoaHocText = '';
    if (nienKhoa != null) {
      if (nienKhoa.ten != null && nienKhoa.ten!.isNotEmpty) {
        khoaHocText = nienKhoa.ten!;
      } else if (nienKhoa.namBatDau != null && nienKhoa.namKetThuc != null) {
        khoaHocText = '${nienKhoa.namBatDau} - ${nienKhoa.namKetThuc}';
      }
    }
    if (khoaHocText.isEmpty) {
      khoaHocText = student?.idNienKhoaDaoTao ?? '';
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${student?.hoVaTen ?? 'Sinh viên'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                className ?? 'Khoa / lớp đang cập nhật',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Khóa học: ${khoaHocText.isNotEmpty == true ? khoaHocText : '--'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Get.to(() => const VcoreNotifyViewV3())?.then((_) {
              widget.controller.updateUnreadCounts();
            });
          },
          child: _headerButton(
            Icons.notifications_none_rounded,
            badge: (widget.controller.unreadSystemCount.value + widget.controller.unreadTrainingCount.value) > 0
                ? (widget.controller.unreadSystemCount.value + widget.controller.unreadTrainingCount.value).toString()
                : null,
          ),
        ),
        const SizedBox(width: 8),
        _headerButton(Icons.qr_code_2_rounded),
      ],
    );
  }

  Widget _headerButton(IconData icon, {String? badge}) {
    return Stack(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 4,
                offset: const Offset(-1, -1),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppColors.brandGreen,
            size: 22,
          ),
        ),
        if (badge != null)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 17,
              height: 17,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.homeRedWeekend,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverview() {
    return Obx(() {
      final todayCount = widget.controller.getTodayTotalSubjects().toString();
      final examCount = widget.controller.getUpcomingExamCount().toString();
      final notifyCount =
      (widget.controller.unreadSystemCount.value +
          widget.controller.unreadTrainingCount.value)
          .toString();

      String getVietnameseWeekday() {
        final weekday = DateTime.now().weekday;
        if (weekday == 7) return 'C.Nhật';
        return 'Thứ ${weekday + 1}';
      }

      final dateStr = DateFormat('dd/MM').format(DateTime.now());

      final items = [
        _OverviewItem(
          Icons.menu_book_rounded,
          todayCount,
          'Tiết học\nhôm nay',
          AppColors.overviewGreen,
        ),
        _OverviewItem(
          Icons.event_note_rounded,
          examCount,
          'Lịch thi\nsắp tới',
          AppColors.overviewOrange,
        ),
        _OverviewItem(
          Icons.notifications_active_rounded,
          notifyCount,
          'Thông báo\nmới',
          AppColors.overviewBlue,
        ),
        _OverviewItem(
          Icons.calendar_month_rounded,
          getVietnameseWeekday(),
          '$dateStr\nTạo nhắc',
          AppColors.overviewPurple,
        ),
      ];

      return _whiteBox(
        height: 102,
        radius: 22,
        variant: _BoxVariant.card,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];

            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  border: index == items.length - 1
                      ? null
                      : Border(
                    right: BorderSide(
                      color: Colors.grey.withOpacity(0.18),
                    ),
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    if (index == 0) {
                      // Tiết học hôm nay → mở lịch học & thi, scroll đến hôm nay
                      Get.to(() => VcoreExamScheduleView(
                        initialDate: DateTime.now(),
                      ));
                    } else if (index == 1) {
                      // Lịch thi sắp tới → scroll đến ngày thi gần nhất
                      final upcomingExams =
                          widget.controller.getUpcomingExams();
                      DateTime? targetDate;
                      if (upcomingExams.isNotEmpty) {
                        final ngayThi = upcomingExams.first.ngayThi;
                        if (ngayThi != null && ngayThi.isNotEmpty) {
                          try {
                            final parts = ngayThi.split('/');
                            if (parts.length == 3) {
                              targetDate = DateTime(
                                int.parse(parts[2]),
                                int.parse(parts[1]),
                                int.parse(parts[0]),
                              );
                            }
                          } catch (_) {}
                        }
                      }
                      Get.to(() => VcoreExamScheduleView(
                        initialDate: targetDate ?? DateTime.now(),
                      ));
                    } else if (index == 2) {
                      Get.to(() => const VcoreNotifyViewV3())?.then((_) {
                        widget.controller.updateUnreadCounts();
                      });
                    } else if (index == 3) {
                      _showCreateCalendarReminderSheet();
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.icon,
                              color: item.color,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              item.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.homeTextTitle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.15,
                          color: AppColors.homeTextBody,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  Widget _buildScheduleBlock() {
    return _whiteBox(
      radius: 18,
      variant: _BoxVariant.card,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScheduleTabs(),
          const SizedBox(height: 10),
          SizedBox(
            height: 245,
            child: Obx(() {
              return PageView(
                controller: schedulePageController,
                padEnds: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child:
                    isStudyTab ? _buildNextStudyCard() : _buildNextExamCard(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: isStudyTab
                        ? _buildTodayStudyTimeline()
                        : _buildTodayExamTimeline(),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTabs() {
    return _whiteBox(
      radius: 99,
      variant: _BoxVariant.chip,
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tabButton(
            title: 'Lịch học',
            active: scheduleTabIndex == 0,
            onTap: () => setState(() => scheduleTabIndex = 0),
          ),
          const SizedBox(width: 6),
          _tabButton(
            title: 'Lịch thi',
            active: scheduleTabIndex == 1,
            onTap: () => setState(() => scheduleTabIndex = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStudyCard() {
    final todaySchedule = widget.controller.getTodayClassSchedule();

    if (todaySchedule.isEmpty) {
      return _schedulePanel(
        child: const Center(
          child: Text(
            'Hôm nay không có lịch học',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    final nextClass = todaySchedule.first;

    return _schedulePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle('Tiết học tiếp theo'),
          const SizedBox(height: 12),
          _timeBadge(
            'Tiết ${nextClass.tietBatDau ?? ''} - ${nextClass.tietKetThuc ?? ''}',
            AppColors.brandGreen,
          ),
          const SizedBox(height: 10),
          Text(
            nextClass.tenHocPhan ?? 'Lớp học',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.darkNavy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          _infoLine('Phòng: ${nextClass.tenPhong ?? '--'}'),
          const SizedBox(height: 8),
          _infoLine('GV: ${nextClass.giangVien1 ?? 'Chưa cập nhật'}'),
          const Spacer(),
          _statusPill('Hôm nay', AppColors.brandGreen),
        ],
      ),
    );
  }

  Widget _buildNextExamCard() {
    final upcomingExams = widget.controller.getUpcomingExams();

    if (upcomingExams.isEmpty) {
      return _schedulePanel(
        child: const Center(
          child: Text(
            'Không có lịch thi sắp tới',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    final nextExam = upcomingExams.first;

    return _schedulePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle('Ca thi tiếp theo'),
          const SizedBox(height: 12),
          _timeBadge(
            nextExam.gioBatDauThi ?? '--:--',
            const Color(0xFF2563EB),
          ),
          const SizedBox(height: 10),
          Text(
            nextExam.tenHocPhan ?? 'Môn thi',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.darkNavy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          _infoLine('Phòng: ${nextExam.phongThi ?? '--'}'),
          const SizedBox(height: 8),
          _infoLine('Ngày thi: ${nextExam.ngayThi ?? '--'}'),
          const Spacer(),
          _statusPill('Sắp thi', const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _buildTodayStudyTimeline() {
    final todaySchedule = widget.controller.getTodayClassSchedule();

    return _schedulePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle('Lịch học hôm nay', hasArrow: true),
          const SizedBox(height: 12),
          Expanded(
            child: todaySchedule.isEmpty
                ? const Center(
              child: Text(
                'Không có lịch học hôm nay',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
                : ListView.builder(
              itemCount: min(todaySchedule.length, 3),
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = todaySchedule[index];

                return _timelineItem(
                  time: 'Tiết ${item.tietBatDau ?? '--'}',
                  title: item.tenHocPhan ?? '',
                  room: item.tenPhong ?? '--',
                  color: index == 0
                      ? const Color(0xFF059669)
                      : index == 1
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFF59E0B),
                  isLast: index == min(todaySchedule.length, 3) - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayExamTimeline() {
    final todayExams = widget.controller.getTodayExamSchedule();

    return _schedulePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle('Lịch thi hôm nay', hasArrow: true),
          const SizedBox(height: 12),
          Expanded(
            child: todayExams.isEmpty
                ? const Center(
              child: Text(
                'Không có lịch thi hôm nay',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
                : ListView.builder(
              itemCount: min(todayExams.length, 3),
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = todayExams[index];

                return _timelineItem(
                  time: item.gioBatDauThi ?? '--:--',
                  title: item.tenHocPhan ?? '',
                  room: item.phongThi ?? '--',
                  color: index == 0
                      ? const Color(0xFF2563EB)
                      : index == 1
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFF97316),
                  isLast: index == min(todayExams.length, 3) - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    final pinnedItems = _allAvailableFunctions
        .where((item) => _pinnedFunctionLabels.contains(item.label))
        .toList();

    final orderedPinned = <_FunctionItem>[];

    for (final label in _pinnedFunctionLabels) {
      final matches = pinnedItems.where((item) => item.label == label);
      if (matches.isNotEmpty) {
        orderedPinned.add(matches.first);
      }
    }

    return _whiteBox(
      radius: 18,
      variant: _BoxVariant.card,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Truy cập nhanh',
            'Ghim',
            onTap: _showPinDialog,
          ),
          const SizedBox(height: 14),
          orderedPinned.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Chưa có chức năng nào được ghim.\nNhấn "Ghim" để thêm.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
              : SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: orderedPinned.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return _functionItem(orderedPinned[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllFunctions() {
    return const SizedBox.shrink();
  }

  Widget _buildImportantNotice() {
    return _whiteBox(
      radius: 18,
      variant: _BoxVariant.card,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _sectionHeader(
            'Thông báo quan trọng',
            'Xem tất cả',
            onTap: () {
              Get.to(() => const VcoreNotifyViewV3())?.then((_) {
                widget.controller.updateUnreadCounts();
              });
            },
          ),
          const SizedBox(height: 8),
          Obx(() {
            final list = widget.controller.listThongBaoDaoTao;

            if (list.isEmpty) {
              return const SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    'Chưa có thông báo đào tạo',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              );
            }

            return Column(
              children: list.take(3).map((item) {
                return _noticeItem(
                  title: item.tieuDe ?? 'Thông báo',
                  subtitle: 'Thông báo đào tạo',
                  time: 'Xem',
                  color: Colors.red,
                  onTap: () {
                    Get.to(
                      () => VcoreNotifyDetailViewV3(
                        title: item.tieuDe ?? 'Thông báo đào tạo',
                        htmlContent: item.noiDung ?? '',
                        sender: 'Phòng Đào tạo',
                        date: DateTime.now(),
                        category: 'Tin đào tạo',
                        showMetadata: false,
                      ),
                    );
                  },
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNewsBlock() {
    return _whiteBox(
      radius: 18,
      variant: _BoxVariant.card,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Tin tức nổi bật',
            'Xem tất cả',
            onTap: () {
              Get.to(() => const VcoreNewsViewV3());
            },
          ),
          const SizedBox(height: 12),
          _whiteBox(
            radius: 99,
            variant: _BoxVariant.chip,
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tabButton(
                  title: 'Tin Trường',
                  active: newsTabIndex == 0,
                  onTap: () {
                    setState(() => newsTabIndex = 0);

                    if (newsPageController.hasClients) {
                      newsPageController.jumpToPage(1000);
                    }
                  },
                ),
                const SizedBox(width: 6),
                _tabButton(
                  title: 'Tin VNU',
                  active: newsTabIndex == 1,
                  onTap: () {
                    setState(() => newsTabIndex = 1);

                    if (newsPageController.hasClients) {
                      newsPageController.jumpToPage(1000);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final schoolItems = widget.controller.listTinTuc2;
            final vnuItems = widget.controller.listTinTuc;
            final count = isSchoolNewsTab ? schoolItems.length : vnuItems.length;

            if (count == 0) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    'Chưa có tin tức',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 165,
              child: PageView.builder(
                controller: newsPageController,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final realIndex = index % count;

                  if (isSchoolNewsTab) {
                    final tinTuc = schoolItems[realIndex];
                    final guid = tinTuc.guidFileAnhDaiDiens?.isNotEmpty == true
                        ? tinTuc.guidFileAnhDaiDiens!.first
                        : '';

                    final imageUrl = guid.isNotEmpty
                        ? '${ServicesUrl().baseUrlFileDownload}$guid'
                        : '';

                    final cacheKey = 'school_${tinTuc.guid ?? realIndex}_$guid';

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _newsCard(
                        title: tinTuc.tieuDe ?? '',
                        imageUrl: imageUrl,
                        cacheKey: cacheKey,
                        accentColor: const Color(0xFF059669),
                        onTap: () {
                          Get.to(
                                () => VcoreNewsDetailView(tinTucModel: tinTuc),
                          );
                        },
                      ),
                    );
                  }

                  final tinTuc = vnuItems[realIndex];

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _newsCard(
                      title: tinTuc.tieuDe ?? '',
                      imageUrl: tinTuc.anhDaiDien ?? '',
                      cacheKey: tinTuc.anhDaiDien ?? 'vnu_$realIndex',
                      accentColor: const Color(0xFF2563EB),
                      onTap: () {
                        widget.controller.viewDetailTopTinTucModel(tinTuc);
                      },
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE7F5EE) : Colors.white,
          borderRadius: BorderRadius.circular(99),
          boxShadow: active
              ? [
            BoxShadow(
              color: AppColors.brandGreen.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? AppColors.brandGreen : Colors.grey.shade700,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _schedulePanel({required Widget child}) {
    return _whiteBox(
      radius: 16,
      variant: _BoxVariant.panel,
      padding: const EdgeInsets.all(13),
      child: child,
    );
  }

  Widget _panelTitle(String title, {bool hasArrow = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.brandGreen,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (hasArrow)
          const Icon(
            Icons.chevron_right,
            color: AppColors.brandGreen,
            size: 18,
          ),
      ],
    );
  }

  Widget _timeBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _infoLine(String text) {
    return Row(
      children: [
        const Text(
          '○',
          style: TextStyle(
            color: AppColors.homeTextSub,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.homeTextSub,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _timelineItem({
    required String time,
    required String title,
    required String room,
    required Color color,
    bool isLast = false,
  }) {
    return SizedBox(
      height: 47,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            height: 47,
            child: Stack(
              children: [
                if (!isLast)
                  Positioned(
                    top: 13,
                    left: 5,
                    bottom: -13,
                    child: Container(
                      width: 1,
                      color: Colors.grey.withOpacity(0.35),
                    ),
                  ),
                Positioned(
                  top: 4,
                  left: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 55,
            child: Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.homeTextSub,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkNavy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  room,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.homeTextSub,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
      String title,
      String action, {
        VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.brandGreen,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            action,
            style: const TextStyle(
              color: AppColors.brandGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 16,
            color: AppColors.brandGreen,
          ),
        ],
      ),
    );
  }

  Widget _functionItem(_FunctionItem item) {
    return SizedBox(
      width: 82,
      child: GestureDetector(
        onTap: () => _handleFunctionTap(item.label),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.color.withOpacity(0.08),
                    item.color.withOpacity(0.18),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 6,
                    offset: const Offset(-2, -2),
                  ),
                  BoxShadow(
                    color: item.color.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(3, 5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _getIconForLabel(item.label),
                  size: 26,
                  color: item.color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.darkNavy,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noticeItem({
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.12),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.campaign_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.darkNavy,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.homeTextSub,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: const TextStyle(
                color: AppColors.homeTextSub,
                fontSize: 10.5,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _newsCard({
    required String title,
    required String imageUrl,
    required String cacheKey,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _WhiteBox(
        radius: 10,
        variant: _BoxVariant.newsCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  cacheKey: cacheKey,
                  fit: BoxFit.cover,
                  httpHeaders: Globals().headerToken(),
                  placeholder: (_, __) => Container(
                    color: Colors.grey.shade200,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFD9E5E2),
                    child: const Icon(
                      Icons.article_outlined,
                      color: Colors.grey,
                    ),
                  ),
                )
                    : Container(
                  color: const Color(0xFFD9E5E2),
                  child: const Icon(
                    Icons.article_outlined,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.darkNavy,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 52,
                      height: 4,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(4),
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
  }

  Widget _whiteBox({
    double? width,
    double? height,
    double radius = 18,
    EdgeInsetsGeometry? padding,
    _BoxVariant variant = _BoxVariant.card,
    required Widget child,
  }) {
    return _WhiteBox(
      width: width,
      height: height,
      radius: radius,
      padding: padding,
      variant: variant,
      child: child,
    );
  }

  void _showPrettyTimePicker({
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onTimeSelected,
  }) {
    DateTime tempDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      initialTime.hour,
      initialTime.minute,
    );

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.brandGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chọn giờ nhắc',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.homeTextTitle,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Cuộn để chọn giờ và phút.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.homeTextSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Container(
                height: 190,
                decoration: BoxDecoration(
                  color: AppColors.homeCardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.homeCardBorder,
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: tempDateTime,
                  minuteInterval: 1,
                  onDateTimeChanged: (DateTime value) {
                    tempDateTime = value;
                  },
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(
                          color: AppColors.homeCardBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          color: AppColors.homeTextSub,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onTimeSelected(
                          TimeOfDay(
                            hour: tempDateTime.hour,
                            minute: tempDateTime.minute,
                          ),
                        );
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Chọn giờ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            WHITE BOX CHUNG                                 */
/* -------------------------------------------------------------------------- */

enum _BoxVariant {
  card,
  panel,
  chip,
  icon,
  newsCard,
}

class _WhiteBox extends StatelessWidget {
  const _WhiteBox({
    required this.child,
    this.width,
    this.height,
    this.radius = 18,
    this.padding,
    this.variant = _BoxVariant.card,
  });

  final Widget child;
  final double? width;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final _BoxVariant variant;

  @override
  Widget build(BuildContext context) {
    final config = _WhiteBoxConfig.fromVariant(variant);

    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: config.borderColor,
          width: config.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(config.shadowOpacity),
            blurRadius: config.shadowBlur,
            offset: config.shadowOffset,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WhiteBoxConfig {
  const _WhiteBoxConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.shadowOpacity,
    required this.shadowBlur,
    required this.shadowOffset,
  });

  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double shadowOpacity;
  final double shadowBlur;
  final Offset shadowOffset;

  factory _WhiteBoxConfig.fromVariant(_BoxVariant variant) {
    switch (variant) {
      case _BoxVariant.card:
        return const _WhiteBoxConfig(
          backgroundColor: Colors.white,
          borderColor: Colors.transparent,
          borderWidth: 0,
          shadowOpacity: 0.08,
          shadowBlur: 16,
          shadowOffset: Offset(0, 6),
        );

      case _BoxVariant.panel:
        return const _WhiteBoxConfig(
          backgroundColor: Colors.white,
          borderColor: Colors.transparent,
          borderWidth: 0,
          shadowOpacity: 0.06,
          shadowBlur: 14,
          shadowOffset: Offset(0, 5),
        );

      case _BoxVariant.chip:
        return _WhiteBoxConfig(
          backgroundColor: Colors.white,
          borderColor: const Color(0xFFF0F0F0),
          borderWidth: 0.5,
          shadowOpacity: 0.04,
          shadowBlur: 8,
          shadowOffset: const Offset(0, 2),
        );

      case _BoxVariant.icon:
        return const _WhiteBoxConfig(
          backgroundColor: Colors.white,
          borderColor: Colors.transparent,
          borderWidth: 0,
          shadowOpacity: 0.08,
          shadowBlur: 12,
          shadowOffset: Offset(0, 4),
        );

      case _BoxVariant.newsCard:
        return const _WhiteBoxConfig(
          backgroundColor: Colors.white,
          borderColor: Colors.transparent,
          borderWidth: 0,
          shadowOpacity: 0.07,
          shadowBlur: 14,
          shadowOffset: Offset(0, 5),
        );
    }
  }
}

class _OverviewItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  _OverviewItem(
      this.icon,
      this.value,
      this.label,
      this.color,
      );
}

class _FunctionItem {
  final String label;
  final Color color;

  _FunctionItem(
      this.label,
      this.color,
      );
}

class _RadialPinOverlay extends StatefulWidget {
  final List<String> initialPinned;
  final Function(List<String>) onSave;
  final Map<String, List<_FunctionItem>> groupedFunctions;
  final IconData Function(String) getIconForLabel;

  const _RadialPinOverlay({
    required this.initialPinned,
    required this.onSave,
    required this.groupedFunctions,
    required this.getIconForLabel,
  });

  @override
  State<_RadialPinOverlay> createState() => _RadialPinOverlayState();
}

class _RadialPinOverlayState extends State<_RadialPinOverlay>
    with SingleTickerProviderStateMixin {
  late List<String> tempPinned;
  int activeCategoryIndex = 0;
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    tempPinned = List.from(widget.initialPinned);
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCategoryName =
    widget.groupedFunctions.keys.elementAt(activeCategoryIndex);
    final items = widget.groupedFunctions[activeCategoryName] ?? [];

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final dimOpacity = _entryController.value * 0.85;
        final blurValue = _entryController.value * 8.0;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(dimOpacity),
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: 48,
                    left: 20,
                    right: 20,
                    child: Opacity(
                      opacity: _entryController.value,
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              widget.groupedFunctions.length,
                                  (idx) {
                                final catName =
                                widget.groupedFunctions.keys.elementAt(idx);
                                final isActive = activeCategoryIndex == idx;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      activeCategoryIndex = idx;
                                      _entryController.forward(from: 0.0);
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFF07964B)
                                          : Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isActive
                                            ? Colors.transparent
                                            : Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      catName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: isActive
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 340,
                      height: 340,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ...List.generate(items.length, (index) {
                            final item = items[index];
                            final isPinned = tempPinned.contains(item.label);

                            final double start = index * 0.08;
                            final double end = (start + 0.6).clamp(0.0, 1.0);
                            final double scaleVal = CurvedAnimation(
                              parent: _entryController,
                              curve: Interval(
                                start,
                                end,
                                curve: Curves.easeOutBack,
                              ),
                            ).value;

                            final double angle =
                                (2 * pi * index / items.length) - (pi / 2);
                            final double radius = scaleVal * 112.0;

                            final double x = 170 + radius * cos(angle) - 40;
                            final double y = 170 + radius * sin(angle) - 45;

                            return Positioned(
                              left: x,
                              top: y,
                              child: Opacity(
                                opacity: scaleVal.clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: scaleVal,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isPinned) {
                                          tempPinned.remove(item.label);
                                        } else {
                                          tempPinned.add(item.label);
                                        }
                                        widget.onSave(tempPinned);
                                      });
                                    },
                                    child: SizedBox(
                                      width: 80,
                                      height: 90,
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                width: 56,
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isPinned
                                                      ? item.color
                                                      .withOpacity(0.2)
                                                      : Colors.white
                                                      .withOpacity(0.12),
                                                  border: Border.all(
                                                    color: isPinned
                                                        ? item.color
                                                        : Colors.white
                                                        .withOpacity(0.25),
                                                    width: isPinned ? 2.5 : 1.5,
                                                  ),
                                                  boxShadow: isPinned
                                                      ? [
                                                    BoxShadow(
                                                      color: item.color
                                                          .withOpacity(0.4),
                                                      blurRadius: 12,
                                                      spreadRadius: 1,
                                                    )
                                                  ]
                                                      : [],
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    widget.getIconForLabel(
                                                      item.label,
                                                    ),
                                                    color: isPinned
                                                        ? item.color
                                                        : Colors.white
                                                        .withOpacity(0.9),
                                                    size: 24,
                                                  ),
                                                ),
                                              ),
                                              if (isPinned)
                                                Positioned(
                                                  top: -2,
                                                  right: -2,
                                                  child: Container(
                                                    width: 18,
                                                    height: 18,
                                                    decoration:
                                                    const BoxDecoration(
                                                      color: Color(0xFF07964B),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 11,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item.label,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isPinned
                                                  ? Colors.white
                                                  : Colors.white.withOpacity(0.85),
                                              fontSize: 11,
                                              fontWeight: isPinned
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              shadows: const [
                                                Shadow(
                                                  color: Colors.black45,
                                                  offset: Offset(1, 1),
                                                  blurRadius: 2,
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 32,
                    right: 20,
                    child: Opacity(
                      opacity: _entryController.value,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.12),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
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
    );
  }
}

