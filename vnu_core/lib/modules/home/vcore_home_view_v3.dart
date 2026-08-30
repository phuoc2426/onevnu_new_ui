import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:vnu_hoc_bong/vnu_hoc_bong.dart';
// import 'package:vnu_noi_tru/modules/boarding/views/nt_boading_register_view.dart';
import 'package:vnu_noi_tru/vnu_noi_tru.dart';
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
import 'package:vnu_core/modules/motel/vcore_motel_webview.dart';
import 'package:vnu_core/modules/news/views/vcore_news_detail_view.dart';
import 'package:vnu_core/modules/news/views/vcore_news_view_v3.dart';
import 'package:vnu_core/modules/news/views/vcore_jobs_view_v2.dart';
import 'package:vnu_core/modules/notify/views/vcore_notify_detail_view_v3.dart';
import 'package:vnu_core/modules/notify/views/vcore_notify_view_v3.dart';
import 'package:vnu_core/modules/one_door/views/vcore_one_door_view.dart';
import 'package:vnu_core/modules/qr/views/vcore_qr_scanner_view.dart';
// import 'package:vnu_core/modules/paht/views/vcore_paht_view.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_view_v2.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_person_info_view.dart';
import 'package:vnu_core/modules/sync/views/vcore_sync_view.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/responsive/responsive.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/widgets/zalo_chat_bubble.dart';
import 'package:vnu_core/modules/question/views/vcore_question_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vnu_core/modules/shapeshifter/models/shapeshifter_feature.dart';
import 'package:vnu_core/modules/shapeshifter/repository/shapeshifter_repository.dart';
import 'package:vnu_core/modules/shapeshifter/services/shapeshifter_launcher.dart';

import 'package:vnu_core/common/guide/guide.dart';
import 'package:vnu_core/common/guide/configs/home_guide_config.dart';
import 'package:vnu_core/widgets/field/vnu_text_field.dart';
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
          AndroidFlutterLocalNotificationsPlugin
        >()
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
  const VcoreHomeViewV3({super.key, this.isActive = true});

  final bool isActive;

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
          child: _HomeWireframeBody(
            controller: controller,
            isActive: isActive,
          ),
        );
      },
    );
  }
}

class _HomeWireframeBody extends StatefulWidget {
  final VcoreHomeController controller;
  final bool isActive;

  const _HomeWireframeBody({
    required this.controller,
    required this.isActive,
  });

  @override
  State<_HomeWireframeBody> createState() => _HomeWireframeBodyState();
}

class _HomeWireframeBodyState extends State<_HomeWireframeBody> {
  int scheduleTabIndex = 0;
  int newsTabIndex = 0;

  bool _startedFirstGuide = false;
  bool _guideActionsRegistered = false;
  AppGuideRegistry? _guideRegistryForActions;

  final PageController newsPageController = PageController(
    initialPage: 1000,
    viewportFraction: 0.82,
  );

  Timer? newsAutoScrollTimer;

  bool get isStudyTab => scheduleTabIndex == 0;

  bool get isSchoolNewsTab => newsTabIndex == 0;

  static const String _temporaryAddressFunctionLabel = 'Cập nhật tạm trú';

  // P4.4-A: pin bằng stable key thay vì label để admin có thể đổi tên
  // Shapeshifter feature mà không làm mất cấu hình người dùng.
  static const String _allFunctionsPinnedMigrationKey =
      'kPinnedFunctions_v3_all_default_v1';
  static const String _stablePinMigrationKey =
      'kPinnedFunctions_v3_stable_key_v1';
  static const String _seenShapeFeaturesKey =
      'kShapeshifterSeenFeatures_v1';

  List<String> _pinnedFunctionKeys = [
    'native:Lịch học & thi',
    'native:Điểm',
    'native:Đăng ký môn',
    'native:Việc làm',
    'native:Đồng bộ',
    'native:Học phí',
    'native:Tài liệu',
    'native:Điểm danh',
    'native:Học bổng',
    'native:Phản ánh',
    'native:Nội trú',
    'native:$_temporaryAddressFunctionLabel',
    'native:Phòng trọ',
    'native:Thủ tục',
    'native:Thư viện',
    'native:Bản đồ',
    'native:Hỏi đáp',
    'native:Cẩm nang',
  ];

  List<ShapeshifterFeature> _dynamicFeatures = const <ShapeshifterFeature>[];
  bool _reloadingFunctionRegistry = false;

  static final List<_FunctionItem> _nativeFunctions = [
    _FunctionItem(
      'Lịch học & thi',
      Color.fromRGBO(0, 122, 255, 1),
    ), // Xanh dương
    _FunctionItem('Điểm', Color.fromRGBO(175, 82, 222, 1)), // Tím
    _FunctionItem('Đăng ký môn', Color.fromRGBO(255, 149, 0, 1)), // Cam
    _FunctionItem('Việc làm', Color.fromRGBO(48, 209, 88, 1)), // Xanh lá
    _FunctionItem('Đồng bộ', Color.fromRGBO(90, 200, 250, 1)), // Xanh ngọc
    _FunctionItem('Học phí', Color.fromRGBO(255, 45, 85, 1)), // Hồng đỏ
    _FunctionItem('Tài liệu', Color.fromRGBO(94, 92, 230, 1)), // Indigo
    _FunctionItem('Điểm danh', Color.fromRGBO(52, 199, 89, 1)), // Emerald
    _FunctionItem('Học bổng', Color.fromRGBO(255, 55, 95, 1)), // Rose
    _FunctionItem('Phản ánh', Color.fromRGBO(255, 204, 0, 1)), // Vàng
    _FunctionItem('Nội trú', Color.fromRGBO(191, 90, 242, 1)), // Lavender
    _FunctionItem(
      _temporaryAddressFunctionLabel,
      Color.fromRGBO(0, 122, 255, 1),
    ),
    _FunctionItem('Phòng trọ', Color.fromRGBO(0, 199, 190, 1)), // Turquoise
    _FunctionItem('Thủ tục', Color.fromRGBO(118, 214, 78, 1)), // Lime
    _FunctionItem('Thư viện', Color.fromRGBO(255, 159, 10, 1)), // Gold
    _FunctionItem('Bản đồ', Color.fromRGBO(50, 173, 230, 1)), // Ocean
    _FunctionItem('Hỏi đáp', Color.fromRGBO(255, 55, 145, 1)), // Magenta
    _FunctionItem('Cẩm nang', Color.fromRGBO(142, 142, 147, 1)), // Gray
  ];

  List<_FunctionItem> get _allAvailableFunctions => <_FunctionItem>[
        ..._nativeFunctions,
        ..._dynamicFeatures.map(_FunctionItem.fromShapeshifter),
      ];

  Map<String, List<_FunctionItem>> get _groupedFunctions {
    final result = <String, List<_FunctionItem>>{
      'Học tập': <_FunctionItem>[],
      'Dịch vụ': <_FunctionItem>[],
      'Tiện ích': <_FunctionItem>[],
    };

    for (final item in _allAvailableFunctions) {
      String group;
      final shape = item.shapeshifterFeature;
      if (shape != null) {
        switch (shape.groupCode.toUpperCase()) {
          case 'HOC_TAP':
            group = 'Học tập';
            break;
          case 'TIEN_ICH':
            group = 'Tiện ích';
            break;
          case 'DICH_VU':
          default:
            group = 'Dịch vụ';
            break;
        }
      } else if (<String>{
        'Lịch học & thi',
        'Điểm',
        'Đăng ký môn',
        'Điểm danh',
      }.contains(item.label)) {
        group = 'Học tập';
      } else if (<String>{
        'Học phí',
        'Học bổng',
        'Thủ tục',
        'Nội trú',
        _temporaryAddressFunctionLabel,
        'Phản ánh',
        'Đồng bộ',
        'Hỏi đáp',
      }.contains(item.label)) {
        group = 'Dịch vụ';
      } else {
        group = 'Tiện ích';
      }
      result[group]!.add(item);
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_initializeFunctionRegistry());
    _startNewsAutoScroll();
    _LocalNotificationService.init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runHomeInitialGuide();
    });
  }

  @override
  void didUpdateWidget(covariant _HomeWireframeBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isActive && !widget.isActive) {
      unawaited(AppGuideFlowController.instance.cancel(context: context));
      return;
    }

    if (!oldWidget.isActive && widget.isActive && !_startedFirstGuide) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runHomeInitialGuide();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerGuideActionsIfNeeded();
  }

  void _registerGuideActionsIfNeeded() {
    if (_guideActionsRegistered) return;
    _guideActionsRegistered = true;

    final registry = AppGuideRegistryScope.of(context);
    _guideRegistryForActions = registry;

    registry.registerAction(
      id: 'home.show_study_tab',
      action: () async {
        await registry.runAction(HomeGuideConfig.actionOpenHomeTab);
        if (!mounted) return;

        if (scheduleTabIndex != 0) {
          setState(() => scheduleTabIndex = 0);
        }

        await _waitGuideUiReady();
      },
    );

    registry.registerAction(
      id: 'home.show_exam_tab',
      action: () async {
        await registry.runAction(HomeGuideConfig.actionOpenHomeTab);
        if (!mounted) return;

        if (scheduleTabIndex != 1) {
          setState(() => scheduleTabIndex = 1);
        }

        await _waitGuideUiReady();
      },
    );

    registry.registerAction(
      id: 'home.show_school_news_tab',
      action: () async {
        await registry.runAction(HomeGuideConfig.actionOpenHomeTab);
        if (!mounted) return;

        if (newsTabIndex != 0) {
          setState(() => newsTabIndex = 0);
        }

        if (newsPageController.hasClients) {
          newsPageController.jumpToPage(1000);
        }

        await _waitGuideUiReady();
      },
    );

    registry.registerAction(
      id: 'home.show_vnu_news_tab',
      action: () async {
        await registry.runAction(HomeGuideConfig.actionOpenHomeTab);
        if (!mounted) return;

        if (newsTabIndex != 1) {
          setState(() => newsTabIndex = 1);
        }

        if (newsPageController.hasClients) {
          newsPageController.jumpToPage(1000);
        }

        await _waitGuideUiReady();
      },
    );
  }

  Future<void> _waitGuideUiReady() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _runHomeInitialGuide() async {
    if (_startedFirstGuide || !widget.isActive) return;

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted || !widget.isActive || _startedFirstGuide) return;

    final startup = const AppGuideStartupService();
    final flow = await startup.resolveFirstOpenHomeFlow();

    // P5 regression guard must be checked again AFTER remote/cache resolution.
    // A network delay must never allow the Home spotlight to appear over a
    // different IndexedStack tab selected by the user in the meantime.
    if (!mounted || !widget.isActive || _startedFirstGuide) return;

    if (flow == null) {
      _startedFirstGuide = true;
      debugPrint('[GUIDE_STARTUP] HOME_FIRST_OPEN disabled by manifest');
      return;
    }

    final hasSeen = await startup.hasSeenFirstOpenHome(flow);
    if (!mounted || !widget.isActive || _startedFirstGuide) return;

    if (hasSeen) {
      _startedFirstGuide = true;
      debugPrint('[GUIDE_STARTUP] ${flow.seenCacheKey} already seen');
      return;
    }

    _startedFirstGuide = true;

    final started = await AppGuideFlowController.instance.start(
      context: context,
      flow: flow,
    );

    if (!mounted || !widget.isActive) {
      if (mounted) {
        await AppGuideFlowController.instance.cancel(context: context);
      }
      _startedFirstGuide = false;
      return;
    }

    debugPrint(
      '[GUIDE_STARTUP] flow=${flow.id} revision=${flow.revision} started=$started',
    );

    if (!started) {
      // Target may not have rendered yet. Allow another attempt when Home is
      // active again; run-once state is only written by FlowController.finish.
      _startedFirstGuide = false;
    }
  }

  Future<void> _previewHomeGuide() async {
    if (!mounted) return;

    final registry = AppGuideRegistryScope.of(context);

    final ok = await const AppGuideNavigationService().openGroup(
      context: context,
      registry: registry,
      groupId: 'home.intro',
    );

    if (!ok) {
      snackBarWarning('Không chạy được onboarding Home');
      return;
    }

    snackBarSuccess('Đang chạy preview onboarding Home');
  }

  Future<void> _debugHomeGuideCache() async {
    final cache = const AppGuideCacheService();
    final hasSeen = await cache.hasSeenGroup('home.intro');

    snackBarWarning('Guide cache:\nhome.intro hasSeen = $hasSeen');

    debugPrint('[GUIDE_CACHE] home.intro hasSeen = $hasSeen');
  }

  Future<void> _previewHomeIntroGroup() async {
    if (!mounted) return;

    final registry = AppGuideRegistryScope.of(context);

    await const AppGuideNavigationService().openGroup(
      context: context,
      registry: registry,
      groupId: 'home.intro',
    );
  }

  Future<void> _previewGuideItem(String itemId) async {
    if (!mounted) return;

    final registry = AppGuideRegistryScope.of(context);
    final item = registry.itemById(itemId);

    if (item == null) {
      snackBarWarning('Không tìm thấy guide item: $itemId');
      return;
    }

    await const AppGuideNavigationService().openItem(
      context: context,
      registry: registry,
      item: item,
    );
  }

  Widget _guidePreviewTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Future<void> Function() onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.brandGreen.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.brandGreen, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: AppFontSizes.mediumSmall,
          fontWeight: FontWeight.w800,
          color: AppColors.homeTextTitle,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: AppFontSizes.font11_5,
          color: AppColors.homeTextSub,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.brandGreen,
      ),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _guideRegistryForActions?.unregisterAction('home.show_study_tab');
    _guideRegistryForActions?.unregisterAction('home.show_exam_tab');
    _guideRegistryForActions?.unregisterAction('home.show_school_news_tab');
    _guideRegistryForActions?.unregisterAction('home.show_vnu_news_tab');

    newsAutoScrollTimer?.cancel();
    newsPageController.dispose();
    super.dispose();
  }

  Future<void> _showFeatureSearch() async {
    final pageContext = context;
    final registry = AppGuideRegistryScope.of(pageContext);

    final searchService = AppGuideSearchService(
      items: registry.items,
      predictor: const AppGuideLightAiPredictor(),
    );

    await showModalBottomSheet<void>(
      context: pageContext,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (sheetContext) {
        return AppGuideSearchSheet(
          searchService: searchService,
          onOpenGuide: (result) async {
            Navigator.of(sheetContext, rootNavigator: true).pop();

            await Future<void>.delayed(const Duration(milliseconds: 120));

            if (!mounted || !pageContext.mounted) return;

            await const AppGuideNavigationService().openItem(
              context: pageContext,
              registry: registry,
              item: result.item,
            );
          },
        );
      },
    );
  }

  String _overviewGuideId(int index) {
    switch (index) {
      case 0:
        return 'home.overview.today_classes';
      case 1:
        return 'home.overview.upcoming_exams';
      case 2:
        return 'home.overview.unread_notifications';
      case 3:
        return 'home.overview.manual_reminder';
      default:
        return 'home.overview';
    }
  }

  String _homeFunctionGuideId(String label) {
    switch (label) {
      case 'Lịch học & thi':
        return 'home.function.exam_schedule';
      case 'Điểm':
        return 'home.function.course_points';
      case 'Đăng ký môn':
        return 'home.function.course_register';
      case 'Việc làm':
        return 'home.function.jobs';
      case 'Đồng bộ':
        return 'home.function.sync';
      case 'Học phí':
        return 'home.function.tuition';
      case 'Tài liệu':
        return 'home.function.documents';
      case 'Điểm danh':
        return 'home.function.attendance';
      case 'Học bổng':
        return 'home.function.scholarship';
      case 'Phản ánh':
        return 'home.function.paht';
      case 'Nội trú':
        return 'home.function.boarding';
      case _temporaryAddressFunctionLabel:
        return 'home.function.profile_temp_address';
      case 'Phòng trọ':
        return 'home.function.motel';
      case 'Thủ tục':
        return 'home.function.one_door';
      case 'Thư viện':
        return 'home.function.library';
      case 'Bản đồ':
        return 'home.function.map';
      case 'Hỏi đáp':
        return 'home.function.question';
      case 'Cẩm nang':
        return 'home.function.handbook';
      default:
        return 'home.quick_access';
    }
  }

  void _startNewsAutoScroll() {
    newsAutoScrollTimer?.cancel();

    newsAutoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !newsPageController.hasClients) {
        return;
      }

      final currentPage = newsPageController.page ?? 0;

      newsPageController.animateToPage(
        currentPage.round() + 1,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _initializeFunctionRegistry() async {
    try {
      final features = await ShapeshifterRepository().getFeatures(
        placement: ShapeshifterPlacement.home,
      );
      if (mounted) {
        setState(() => _dynamicFeatures = features);
      } else {
        _dynamicFeatures = features;
      }
    } catch (_) {
      // Fail-safe: Home native vẫn hoạt động nếu registry API tạm lỗi.
      // Stable shape:* pin keys được giữ lại trong local prefs để tự hồi phục
      // khi API hoạt động trở lại.
    }

    await _loadPinnedFunctions();
  }

  Future<void> _reloadFunctionRegistry() async {
    if (_reloadingFunctionRegistry) return;

    if (mounted) {
      setState(() => _reloadingFunctionRegistry = true);
    }

    try {
      final features = await ShapeshifterRepository().getFeatures(
        placement: ShapeshifterPlacement.home,
      );
      if (!mounted) return;

      setState(() => _dynamicFeatures = features);

      // Re-run pin normalization after fetching the newest registry. Existing
      // user pin choices are preserved; a brand-new dynamic feature with
      // defaultPinned=true is pinned exactly once by the seen-feature logic.
      await _loadPinnedFunctions();
      if (!mounted) return;

      snackBarSuccess('Đã tải lại danh sách chức năng mới nhất.');
    } catch (error) {
      debugPrint('[SHAPE-HOME-RELOAD] $error');
      if (mounted) {
        snackBarWarning('Không tải lại được chức năng. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) {
        setState(() => _reloadingFunctionRegistry = false);
      }
    }
  }

  Future<void> _loadPinnedFunctions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('kPinnedFunctions_v3');
      final bool allFunctionsDefaultApplied =
          prefs.getBool(_allFunctionsPinnedMigrationKey) ?? false;
      final bool stableMigrationApplied =
          prefs.getBool(_stablePinMigrationKey) ?? false;

      List<String> loaded;
      if (!allFunctionsDefaultApplied || saved == null) {
        loaded = _nativeFunctions.map((item) => item.key).toList();
      } else {
        loaded = List<String>.from(saved);
      }

      // Migrate legacy label values such as "Điểm" -> "native:Điểm".
      // Also accepts a dynamic label once, but from now on shape:<code> is used.
      final List<String> migrated = <String>[];
      for (final raw in loaded) {
        final value = raw.trim();
        if (value.isEmpty) continue;
        String? key;
        if (value.startsWith('native:') || value.startsWith('shape:')) {
          key = value;
        } else {
          final native = _nativeFunctions.where((item) => item.label == value);
          if (native.isNotEmpty) {
            key = native.first.key;
          } else {
            final dynamic = _dynamicFeatures.where((item) => item.label == value);
            if (dynamic.isNotEmpty) key = dynamic.first.stableKey;
          }
        }
        if (key != null && !migrated.contains(key)) migrated.add(key);
      }

      // Feature động có defaultPinned=true chỉ được tự ghim đúng lần đầu nó
      // xuất hiện trong registry của tài khoản. Sau đó tôn trọng thao tác bỏ ghim.
      final seenCodes = (prefs.getStringList(_seenShapeFeaturesKey) ?? const <String>[])
          .toSet();
      bool seenChanged = false;
      for (final feature in _dynamicFeatures) {
        if (!seenCodes.contains(feature.code)) {
          if (feature.defaultPinned && !migrated.contains(feature.stableKey)) {
            migrated.add(feature.stableKey);
          }
          seenCodes.add(feature.code);
          seenChanged = true;
        }
      }

      // Chỉ loại native key không tồn tại. shape:* key chưa tải được từ server
      // vẫn được giữ để tránh mất pin khi mạng lỗi / feature tạm disable.
      final validNativeKeys = _nativeFunctions.map((item) => item.key).toSet();
      final List<String> normalized = <String>[];
      for (final key in migrated) {
        final keep = key.startsWith('shape:') || validNativeKeys.contains(key);
        if (keep && !normalized.contains(key)) normalized.add(key);
      }

      await prefs.setStringList('kPinnedFunctions_v3', normalized);
      if (!allFunctionsDefaultApplied) {
        await prefs.setBool(_allFunctionsPinnedMigrationKey, true);
      }
      if (!stableMigrationApplied) {
        await prefs.setBool(_stablePinMigrationKey, true);
      }
      if (seenChanged) {
        await prefs.setStringList(_seenShapeFeaturesKey, seenCodes.toList()..sort());
      }

      if (!mounted) return;
      setState(() => _pinnedFunctionKeys = normalized);
    } catch (_) {
      // Giữ native defaults nếu local prefs lỗi.
    }
  }

  Future<void> _savePinnedFunctions(List<String> keys) async {
    try {
      final normalized = <String>[];
      for (final key in keys) {
        if (key.trim().isNotEmpty && !normalized.contains(key)) {
          normalized.add(key);
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('kPinnedFunctions_v3', normalized);

      if (!mounted) return;
      setState(() => _pinnedFunctionKeys = normalized);
    } catch (_) {
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
          initialPinned: _pinnedFunctionKeys,
          onSave: _savePinnedFunctions,
          groupedFunctions: _groupedFunctions,
          getIconForLabel: _getIconForLabel,
        );
      },
    );
  }

  void _handleFunctionTap(_FunctionItem item) {
    final shape = item.shapeshifterFeature;
    if (shape != null) {
      unawaited(ShapeshifterLauncher().open(context, shape));
      return;
    }

    final label = item.label;
    switch (label) {
      case 'Lịch học & thi':
        Get.to(() => const VcoreExamScheduleView())?.then((_) {
          widget.controller.fetchScheduleData();
        });
        break;
      case 'Điểm':
        Get.to(() => const VcoreCoursePointsView());
        break;
      case 'Phản ánh':
        Get.to(() => const VcorePahtViewV2());
        break;
      case 'Nội trú':
        // snackBarWarning('Chức năng đang hoàn thiện');
        Get.to(() => const DRMyRegistrationScreen());
        break;
      case _temporaryAddressFunctionLabel:
        Get.to(
          () => const VcoreProfilePersonInfoView(
            scrollToTemporaryAddress: true,
          ),
        );
        break;
      case 'Phòng trọ':
        openMotelWebView();
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
      case 'Cẩm nang':
        Get.to(() => const VcoreCamNangView());
        break;
      case 'Việc làm':
        Get.to(() => const VcoreJobsViewV2());
        break;
      case 'Đồng bộ':
        // snackBarWarning('Chức năng đang hoàn thiện');
        Get.to(() => VcoreSyncView());
        break;
      case 'Hỏi đáp':
        Get.to(() => VcoreQuestionView());
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
      case 'Đồng bộ':
        return Icons.sync_rounded;
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
      case _temporaryAddressFunctionLabel:
        return Icons.location_on_rounded;
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

          final selectedDateText = DateFormat(
            'dd/MM/yyyy',
          ).format(selectedDate);

          return Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 14,
              bottom: MediaQuery.of(context).viewInsets.bottom + 18,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                                  fontSize: AppFontSizes.extraLarge,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.homeTextTitle,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Chọn ngày trên lịch, chọn giờ và nhập nội dung.',
                                style: TextStyle(
                                  fontSize: AppFontSizes.font12_5,
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
                        border: Border.all(color: AppColors.homeCardBorder),
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
                            fontSize: AppFontSizes.mediumLarge,
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
                            fontSize: AppFontSizes.font11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.homeTextSub,
                          ),
                          weekendStyle: TextStyle(
                            fontSize: AppFontSizes.font11,
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

                    VnuFloatingTextFieldAdapter(
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
                          style: TextStyle(fontWeight: FontWeight.w800),
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
          border: Border.all(color: AppColors.homeCardBorder),
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
              child: Icon(icon, color: AppColors.brandGreen, size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppFontSizes.font11,
                      color: AppColors.homeTextSub,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSizes.font12_5,
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
      snackBarWarning(
        'Không thể tạo lời nhắc. Vui lòng kiểm tra quyền thông báo',
      );
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
                  AppGuideAnchor(
                    id: 'home.header',
                    child: Obx(() => _buildHeader()),
                  ),
                  const SizedBox(height: 22),
                  AppGuideAnchor(id: 'home.overview', child: _buildOverview()),
                  const SizedBox(height: 14),
                  AppGuideAnchor(
                    id: 'home.schedule',
                    child: _buildScheduleBlock(),
                  ),
                  const SizedBox(height: 14),
                  AppGuideAnchor(
                    id: 'home.quick_access',
                    child: _buildQuickAccess(),
                  ),
                  const SizedBox(height: 14),
                  AppGuideAnchor(
                    id: 'home.notice',
                    child: _buildImportantNotice(),
                  ),
                  const SizedBox(height: 14),
                  AppGuideAnchor(id: 'home.news', child: _buildNewsBlock()),
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
        children: [Image.asset('assets/images/bg2.png', fit: BoxFit.cover)],
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
                student?.hoVaTen ?? 'Sinh viên',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: AppFontSizes.mediumSmall,
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
                  fontSize: AppFontSizes.font12_5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Khóa học: ${khoaHocText.isNotEmpty ? khoaHocText : '--'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: AppFontSizes.small,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        AppGuideAnchor(
          id: 'home.search',
          child: GestureDetector(
            onTap: _showFeatureSearch,
            child: _headerButton(Icons.search_rounded),
          ),
        ),

        const SizedBox(width: 8),

        AppGuideAnchor(
          id: 'home.notification',
          child: GestureDetector(
            onTap: () {
              Get.to(() => const VcoreNotifyViewV3())?.then((_) {
                widget.controller.updateUnreadCounts();
              });
            },
            child: _headerButton(
              Icons.notifications_none_rounded,
              badge:
                  (widget.controller.unreadSystemCount.value +
                          widget.controller.unreadTrainingCount.value) >
                      0
                  ? (widget.controller.unreadSystemCount.value +
                            widget.controller.unreadTrainingCount.value)
                        .toString()
                  : null,
            ),
          ),
        ),

        const SizedBox(width: 8),

        AppGuideAnchor(
          id: 'home.qr',
          child: GestureDetector(
            onTap: () {
              Get.to(() => const VcoreQrScannerView());
            },
            child: _headerButton(Icons.qr_code_2_rounded),
          ),
        ),
      ],
    );
  }

  void _debugGuideState() {
    try {
      final registry = AppGuideRegistryScope.of(context);

      final homeHeader = registry.anchorById('home.header');
      final homeSchedule = registry.anchorById('home.schedule');
      final homeIntro = registry.groupById('home.intro');
      final homeHeaderItem = registry.itemById('home.header');
      final homeScheduleItem = registry.itemById('home.schedule');
      final nextExamItem = registry.itemById('home.schedule.next_exam');
      final newsCarouselItem = registry.itemById('home.news.carousel');
      final profileHeaderItem = registry.itemById('profile.header');

      final message = [
        'Guide debug:',
        'items = ${registry.items.length}',
        'groups = ${registry.groups.length}',
        'home.intro exists = ${homeIntro != null}',
        'home.intro targets = ${homeIntro?.targetIds.length ?? 0}',
        '',
        'home.header item = ${homeHeaderItem != null}',
        'home.header anchor = ${homeHeader != null}',
        'home.header key context = ${homeHeader?.key.currentContext != null}',
        'home.header stored context mounted = ${homeHeader?.context.mounted}',
        '',
        'home.schedule item = ${homeScheduleItem != null}',
        'home.schedule anchor = ${homeSchedule != null}',
        'home.schedule key context = ${homeSchedule?.key.currentContext != null}',
        'home.schedule stored context mounted = ${homeSchedule?.context.mounted}',
        '',
        'home.schedule.next_exam item = ${nextExamItem != null}',
        'home.news.carousel item = ${newsCarouselItem != null}',
        'profile.header item = ${profileHeaderItem != null}',
      ].join('\n');

      debugPrint(message);
      snackBarWarning(message);
    } catch (e) {
      debugPrint('Guide debug error: $e');
      snackBarWarning('Guide debug error: $e');
    }
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
          child: Icon(icon, color: AppColors.brandGreen, size: 22),
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
                  fontSize: AppFontSizes.extraSmall,
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
      // Cùng nguồn eventsMap với màn "Lịch học & lịch thi".
      final todayClassCount =
          widget.controller.getTodayClassEvents().length.toString();
      final todayExamCount =
          widget.controller.getTodayExamEvents().length.toString();
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
          todayClassCount,
          'Tiết học\nhôm nay',
          AppColors.overviewGreen,
        ),
        _OverviewItem(
          Icons.event_note_rounded,
          todayExamCount,
          'Lịch thi\nhôm nay',
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
              child: AppGuideAnchor(
                id: _overviewGuideId(index),
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
                        // Nếu hôm nay thực sự có lịch thì mở đúng hôm nay.
                        // Nếu không có, đưa sinh viên tới buổi học gần nhất thay vì
                        // mở một ngày trống trên calendar.
                        final hasClassToday = widget.controller
                            .getTodayClassEvents()
                            .isNotEmpty;
                        final targetDate = hasClassToday
                            ? DateTime.now()
                            : widget.controller
                                    .getNearestUpcomingClassEventDate() ??
                                DateTime.now();

                        Get.to(
                          () => VcoreExamScheduleView(
                            initialDate: targetDate,
                            initialHocKyId:
                                widget.controller.currentScheduleHocKyId,
                            initialKieuTruong:
                                widget.controller.currentScheduleKieuTruong,
                          ),
                        )?.then((_) {
                          // Có thể sinh viên vừa chỉnh khoảng ngày học trong màn lịch.
                          // Tải lại để phần Home dùng cùng một mốc thời gian.
                          widget.controller.fetchScheduleData();
                        });
                      } else if (index == 1) {
                        // Tương tự lịch học: nếu hôm nay không thi thì mở kỳ thi
                        // gần nhất, tránh đưa người dùng vào một ngày calendar trống.
                        final hasExamToday = widget.controller
                            .getTodayExamEvents()
                            .isNotEmpty;
                        final targetDate = hasExamToday
                            ? DateTime.now()
                            : widget.controller
                                    .getNearestUpcomingExamEventDate() ??
                                DateTime.now();

                        Get.to(
                          () => VcoreExamScheduleView(
                            initialDate: targetDate,
                            initialHocKyId:
                                widget.controller.currentScheduleHocKyId,
                            initialKieuTruong:
                                widget.controller.currentScheduleKieuTruong,
                          ),
                        )?.then((_) {
                          widget.controller.fetchScheduleData();
                        });
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
                                  fontSize: AppFontSizes.font15_5,
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
                            fontSize: AppFontSizes.font10_5,
                            height: 1.15,
                            color: AppColors.homeTextBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
    final responsive = VnuResponsiveContext.of(context);
    final scheduleHeight = responsive.isVeryLargeText
        ? 350.0
        : responsive.isLargeText
            ? 300.0
            : responsive.isCompact
                ? 270.0
                : 245.0;

    return _whiteBox(
      radius: 18,
      variant: _BoxVariant.card,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppGuideAnchor(id: 'home.schedule.tabs', child: _buildScheduleTabs()),
          const SizedBox(height: 10),
          AppGuideAnchor(
            id: 'home.schedule.cards',
            child: SizedBox(
              height: scheduleHeight,
              child: Obx(() {
                // Card lớn chỉ hiển thị lịch SẮP TỚI.
                // Thông tin hôm nay đã nằm ở khối tổng quan ngay dưới header.
                return isStudyTab
                    ? AppGuideAnchor(
                        // Giữ ID guide cũ để không làm hỏng onboarding hiện tại.
                        id: 'home.schedule.next_study',
                        child: AppGuideAnchor(
                          id: 'home.schedule.study_timeline',
                          child: _buildUpcomingStudyTimeline(),
                        ),
                      )
                    : AppGuideAnchor(
                        // Giữ ID guide cũ để không làm hỏng onboarding hiện tại.
                        id: 'home.schedule.next_exam',
                        child: AppGuideAnchor(
                          id: 'home.schedule.exam_timeline',
                          child: _buildUpcomingExamTimeline(),
                        ),
                      );
              }),
            ),
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

  Widget _buildUpcomingStudyTimeline() {
    // Không tự suy luận weekday/ngày nữa. Danh sách này lấy trực tiếp từ
    // eventsMap mà chính màn Lịch học & lịch thi dùng để vẽ calendar.
    final upcomingSchedule =
        widget.controller.getUpcomingClassEvents(days: 120);

    return _schedulePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle('Lịch học sắp tới', hasArrow: true),
          const SizedBox(height: 12),
          Expanded(
            child: upcomingSchedule.isEmpty
                ? const Center(
                    child: Text(
                      'Không có lịch học sắp tới',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: AppFontSizes.small,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: min(upcomingSchedule.length, 3),
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final event = upcomingSchedule[index];

                      return _timelineItem(
                        time:
                            '${DateFormat('dd/MM').format(event.date)} • ${event.displayStartTime}',
                        title: event.title,
                        room: event.location,
                        color: index == 0
                            ? const Color(0xFF059669)
                            : index == 1
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFF59E0B),
                        isLast: index == min(upcomingSchedule.length, 3) - 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingExamTimeline() {
    // Cùng eventsMap với calendar; event nào không có trên calendar thì Home
    // cũng tuyệt đối không tự sinh ra.
    final upcomingExams =
        widget.controller.getUpcomingExamEvents(days: 180);

    return _schedulePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle('Lịch thi sắp tới', hasArrow: true),
          const SizedBox(height: 12),
          Expanded(
            child: upcomingExams.isEmpty
                ? const Center(
                    child: Text(
                      'Không có lịch thi sắp tới',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: AppFontSizes.small,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: min(upcomingExams.length, 3),
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final event = upcomingExams[index];

                      return _timelineItem(
                        time:
                            '${DateFormat('dd/MM').format(event.date)} • ${event.displayStartTime}',
                        title: event.title,
                        room: event.location,
                        color: index == 0
                            ? const Color(0xFF2563EB)
                            : index == 1
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFFF97316),
                        isLast: index == min(upcomingExams.length, 3) - 1,
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
        .where((item) => _pinnedFunctionKeys.contains(item.key))
        .toList();

    final orderedPinned = <_FunctionItem>[];

    for (final key in _pinnedFunctionKeys) {
      final matches = pinnedItems.where((item) => item.key == key);
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
          AppGuideAnchor(
            id: 'home.quick_access.pin',
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'TRUY CẬP NHANH',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.brandGreen,
                      fontSize: AppFontSizes.mediumSmall,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Tải lại chức năng mới nhất',
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      splashRadius: 18,
                      onPressed: _reloadingFunctionRegistry
                          ? null
                          : () => unawaited(_reloadFunctionRegistry()),
                      icon: _reloadingFunctionRegistry
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brandGreen,
                              ),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              size: 20,
                              color: AppColors.brandGreen,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _showPinDialog,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ghim',
                          style: TextStyle(
                            color: AppColors.brandGreen,
                            fontSize: AppFontSizes.font11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.brandGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppGuideAnchor(
            id: 'home.quick_access.list',
            child: orderedPinned.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Chưa có chức năng nào được ghim.\nNhấn "Ghim" để thêm.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: AppFontSizes.mediumSmall,
                        ),
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 108,
                    ),
                    itemCount: orderedPinned.length,
                    itemBuilder: (BuildContext context, int index) {
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
          AppGuideAnchor(
            id: 'home.notice.header',
            child: _sectionHeader(
              'Thông báo quan trọng',
              'Xem tất cả',
              onTap: () {
                Get.to(() => const VcoreNotifyViewV3())?.then((_) {
                  widget.controller.updateUnreadCounts();
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          AppGuideAnchor(
            id: 'home.notice.list',
            child: Obx(() {
              final list = widget.controller.listThongBaoDaoTao;

              if (list.isEmpty) {
                return const SizedBox(
                  height: 80,
                  child: Center(
                    child: Text(
                      'Chưa có thông báo đào tạo',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: AppFontSizes.mediumSmall,
                      ),
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
          ),
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
          AppGuideAnchor(
            id: 'home.news.header',
            child: _sectionHeader(
              'Tin tức nổi bật',
              'Xem tất cả',
              onTap: () {
                Get.to(() => const VcoreNewsViewV3());
              },
            ),
          ),
          const SizedBox(height: 12),
          AppGuideAnchor(
            id: 'home.news.tabs',
            child: _whiteBox(
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
          ),
          const SizedBox(height: 12),
          AppGuideAnchor(
            id: 'home.news.carousel',
            child: Obx(() {
              final schoolItems = widget.controller.listTinTuc2;
              final vnuItems = widget.controller.listTinTuc;
              final count = isSchoolNewsTab
                  ? schoolItems.length
                  : vnuItems.length;

              if (count == 0) {
                return const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Chưa có tin tức',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: AppFontSizes.mediumSmall,
                      ),
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
                      final guid =
                          tinTuc.guidFileAnhDaiDiens?.isNotEmpty == true
                          ? tinTuc.guidFileAnhDaiDiens!.first
                          : '';

                      final imageUrl = guid.isNotEmpty
                          ? '${ServicesUrl().baseUrlFileDownload}$guid'
                          : '';

                      final cacheKey =
                          'school_${tinTuc.guid ?? realIndex}_$guid';

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
          ),
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
            fontSize: AppFontSizes.font11_5,
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
              fontSize: AppFontSizes.small,
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

  String _formatShortDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '--/--';

    try {
      final date = DateFormat('dd/MM/yyyy').parseStrict(rawDate.trim());
      return DateFormat('dd/MM').format(date);
    } catch (_) {
      return rawDate;
    }
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
          fontSize: AppFontSizes.font17,
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
            fontSize: AppFontSizes.small,
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
              fontSize: AppFontSizes.small,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: AppFontSizes.small,
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 47),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 16,
              child: Stack(
                fit: StackFit.expand,
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
            width: 86,
            child: Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.homeTextSub,
                fontSize: AppFontSizes.font11,
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
                    fontSize: AppFontSizes.small,
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
                    fontSize: AppFontSizes.font11,
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

  Widget _sectionHeader(String title, String action, {VoidCallback? onTap}) {
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
                fontSize: AppFontSizes.mediumSmall,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            action,
            style: const TextStyle(
              color: AppColors.brandGreen,
              fontSize: AppFontSizes.font11,
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
    return AppGuideAnchor(
      id: item.shapeshifterFeature == null
          ? _homeFunctionGuideId(item.label)
          : 'home.shapeshifter.${item.shapeshifterFeature!.code}',
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: () => _handleFunctionTap(item),
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
                  child: _functionIcon(item, size: 26),
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
                  fontSize: AppFontSizes.font11_5,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _functionIcon(_FunctionItem item, {double size = 26}) {
    final iconUrl = item.shapeshifterFeature?.iconUrl?.trim() ?? '';
    if (iconUrl.isEmpty) {
      return Icon(
        item.shapeshifterFeature == null
            ? _getIconForLabel(item.label)
            : Icons.language_rounded,
        size: size,
        color: item.color,
      );
    }

    if (iconUrl.toLowerCase().split('?').first.endsWith('.svg')) {
      return SvgPicture.network(
        iconUrl,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(item.color, BlendMode.srcIn),
        placeholderBuilder: (_) => Icon(
          Icons.language_rounded,
          size: size,
          color: item.color,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: iconUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorWidget: (_, __, ___) => Icon(
        Icons.language_rounded,
        size: size,
        color: item.color,
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
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.12)),
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
              child: Icon(Icons.campaign_rounded, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
                      fontSize: AppFontSizes.font11_5,
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
                      fontSize: AppFontSizes.font10_5,
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
                fontSize: AppFontSizes.font10_5,
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
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
                        placeholder: (_, __) =>
                            Container(color: Colors.grey.shade200),
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
                      fontSize: AppFontSizes.font10_5,
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                            fontSize: AppFontSizes.font17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.homeTextTitle,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Cuộn để chọn giờ và phút.',
                          style: TextStyle(
                            fontSize: AppFontSizes.font12_5,
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
                  border: Border.all(color: AppColors.homeCardBorder),
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
                        side: const BorderSide(color: AppColors.homeCardBorder),
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
                        style: TextStyle(fontWeight: FontWeight.w800),
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

enum _BoxVariant { card, panel, chip, icon, newsCard }

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

  _OverviewItem(this.icon, this.value, this.label, this.color);
}

class _FunctionItem {
  final String label;
  final Color color;
  final String key;
  final ShapeshifterFeature? shapeshifterFeature;

  _FunctionItem(
    this.label,
    this.color, {
    String? key,
    this.shapeshifterFeature,
  }) : key = key ?? 'native:$label';

  factory _FunctionItem.fromShapeshifter(ShapeshifterFeature feature) {
    return _FunctionItem(
      feature.label,
      feature.primaryColor,
      key: feature.stableKey,
      shapeshifterFeature: feature,
    );
  }
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
    final activeCategoryName = widget.groupedFunctions.keys.elementAt(
      activeCategoryIndex,
    );
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
                                final catName = widget.groupedFunctions.keys
                                    .elementAt(idx);
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
                                        fontSize: AppFontSizes.mediumSmall,
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
                            final isPinned = tempPinned.contains(item.key);

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
                                          tempPinned.remove(item.key);
                                        } else {
                                          tempPinned.add(item.key);
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
                                                      ? item.color.withOpacity(
                                                          0.2,
                                                        )
                                                      : Colors.white
                                                            .withOpacity(0.12),
                                                  border: Border.all(
                                                    color: isPinned
                                                        ? item.color
                                                        : Colors.white
                                                              .withOpacity(
                                                                0.25,
                                                              ),
                                                    width: isPinned ? 2.5 : 1.5,
                                                  ),
                                                  boxShadow: isPinned
                                                      ? [
                                                          BoxShadow(
                                                            color: item.color
                                                                .withOpacity(
                                                                  0.4,
                                                                ),
                                                            blurRadius: 12,
                                                            spreadRadius: 1,
                                                          ),
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
                                                          color: Color(
                                                            0xFF07964B,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
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
                                                  : Colors.white.withOpacity(
                                                      0.85,
                                                    ),
                                              fontSize: AppFontSizes.font11,
                                              fontWeight: isPinned
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              shadows: const [
                                                Shadow(
                                                  color: Colors.black45,
                                                  offset: Offset(1, 1),
                                                  blurRadius: 2,
                                                ),
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
