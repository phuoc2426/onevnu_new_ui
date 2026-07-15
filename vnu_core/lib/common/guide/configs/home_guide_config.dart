import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_hoc_bong/vnu_hoc_bong.dart';
import 'package:vnu_noi_tru/vnu_noi_tru.dart';

import '../../utils.dart';
import '../../../modules/cam_nang/views/vcore_cam_nang_view.dart';
import '../../../modules/course_points/views/vcore_course_points_view.dart';
import '../../../modules/exam_schedule/views/vcore_exam_schedule_view.dart';
import '../../../modules/inmapz/vcore_immap_view.dart';
import '../../../modules/motel/vcore_motel_webview.dart';
import '../../../modules/news/views/vcore_jobs_view_v2.dart';
import '../../../modules/notify/views/vcore_notify_view_v3.dart';
import '../../../modules/one_door/views/vcore_one_door_view.dart';
import '../../../modules/paht_v2/views/vcore_paht_view_v2.dart';
import '../../../modules/question/views/vcore_question_view.dart';
import '../../../modules/sync/views/vcore_sync_view.dart';
import '../global/app_guide_module_ids.dart';
import '../models/app_guide_group.dart';
import '../models/app_guide_item.dart';
import '../models/app_guide_item_type.dart';
import 'app_guide_module_config.dart';

class HomeGuideConfig implements AppGuideModuleConfig {
  const HomeGuideConfig();

  @override
  String get moduleId => AppGuideModuleIds.home;

  @override
  List<AppGuideItem> get items => [
        ..._homeItems,
        ..._homeOverviewItems,
        ..._homeScheduleItems,
        ..._homeQuickAccessItems,
        ..._homeNoticeItems,
        ..._homeNewsItems,
        ..._homeFunctionItems,
      ];

  @override
  List<AppGuideGroup> get groups => [
        AppGuideGroup(
                  id: 'home.intro',
                  moduleId: AppGuideModuleIds.home,
                  title: 'Hướng dẫn trang chủ',
                  description: 'Giới thiệu các khu vực chính trên trang chủ.',
                  targetIds: [
                    'home.header',
                    'home.search',
                    'home.notification',
                    'home.overview',
                    'home.schedule',
                    'home.quick_access',
                    'home.notice',
                    'home.news',
                  ],
                ),
        AppGuideGroup(
                  id: 'home.overview.group',
                  moduleId: AppGuideModuleIds.home,
                  title: 'Hướng dẫn tổng quan hôm nay',
                  description: 'Giới thiệu các thẻ tổng quan nhanh trên trang chủ.',
                  targetIds: [
                    'home.overview.today_classes',
                    'home.overview.upcoming_exams',
                    'home.overview.unread_notifications',
                    'home.overview.manual_reminder',
                  ],
                ),
        AppGuideGroup(
                  id: 'home.schedule.group',
                  moduleId: AppGuideModuleIds.home,
                  title: 'Hướng dẫn lịch học và lịch thi',
                  description: 'Giới thiệu khối lịch học, lịch thi và các tab liên quan.',
                  targetIds: [
                    'home.schedule.tabs',
                    'home.schedule.cards',
                    'home.schedule.next_study',
                    'home.schedule.study_timeline',
                    'home.schedule.next_exam',
                    'home.schedule.exam_timeline',
                  ],
                ),
        AppGuideGroup(
                  id: 'home.quick_access.group',
                  moduleId: AppGuideModuleIds.home,
                  title: 'Hướng dẫn truy cập nhanh',
                  description: 'Giới thiệu khu vực ghim và mở nhanh chức năng.',
                  targetIds: [
                    'home.quick_access.pin',
                    'home.quick_access.list',
                    'home.function.exam_schedule',
                    'home.function.course_points',
                    'home.function.scholarship',
                    'home.function.jobs',
                    'home.function.sync',
                  ],
                ),
        AppGuideGroup(
                  id: 'home.notice.group',
                  moduleId: AppGuideModuleIds.home,
                  title: 'Hướng dẫn thông báo quan trọng',
                  description: 'Giới thiệu khu vực thông báo đào tạo quan trọng.',
                  targetIds: [
                    'home.notice.header',
                    'home.notice.list',
                  ],
                ),
        AppGuideGroup(
                  id: 'home.news.group',
                  moduleId: AppGuideModuleIds.home,
                  title: 'Hướng dẫn tin tức',
                  description: 'Giới thiệu khu vực tin tức nổi bật.',
                  targetIds: [
                    'home.news.header',
                    'home.news.tabs',
                    'home.news.carousel',
                  ],
                ),
      ];

  static final List<AppGuideItem> _homeItems = [
      _homeSection(
        id: 'home.header',
        title: 'Thông tin sinh viên',
        description:
            'Khu vực hiển thị tên sinh viên, lớp, khóa học và các thao tác nhanh.',
        icon: Icons.person_rounded,
        keywords: [
          'sinh viên',
          'thông tin',
          'hồ sơ',
          'tên',
          'lớp',
          'khóa học',
          'header',
          'trang chủ',
        ],
        priority: 950,
      ),
      _homeWidget(
        id: 'home.search',
        groupId: 'home.intro',
        title: 'Tìm nhanh chức năng',
        description:
            'Tìm kiếm chức năng, khu vực hoặc hướng dẫn sử dụng trong ứng dụng.',
        icon: Icons.search_rounded,
        keywords: [
          'tìm kiếm',
          'tìm nhanh',
          'search',
          'hướng dẫn',
          'chức năng',
        ],
        fallbackId: 'home.header',
        priority: 920,
      ),
      _homeWidget(
        id: 'home.notification',
        groupId: 'home.intro',
        title: 'Thông báo',
        description: 'Mở danh sách thông báo mới từ hệ thống và đào tạo.',
        icon: Icons.notifications_none_rounded,
        keywords: [
          'thông báo',
          'notification',
          'tin mới',
          'đào tạo',
        ],
        fallbackId: 'home.header',
        priority: 900,
        openAction: () async {
          Get.to(() => const VcoreNotifyViewV3());
        },
      ),
      _homeWidget(
        id: 'home.qr',
        groupId: 'home.intro',
        title: 'Mã QR và tiện ích nhanh',
        description: 'Khu vực dành cho mã QR hoặc tiện ích nhanh trên trang chủ.',
        icon: Icons.qr_code_2_rounded,
        keywords: [
          'qr',
          'mã qr',
          'tiện ích',
        ],
        fallbackId: 'home.header',
        priority: 700,
      ),
      _homeSection(
        id: 'home.overview',
        title: 'Tổng quan hôm nay',
        description:
            'Xem nhanh số tiết học hôm nay, lịch thi sắp tới, thông báo mới và lời nhắc cá nhân.',
        icon: Icons.dashboard_rounded,
        keywords: [
          'tổng quan',
          'hôm nay',
          'tiết học',
          'lịch thi',
          'thông báo',
          'lời nhắc',
        ],
        priority: 890,
      ),
      _homeSection(
        id: 'home.schedule',
        title: 'Lịch học và lịch thi',
        description:
            'Theo dõi lịch học, lịch thi hôm nay và các lịch sắp tới ngay trên trang chủ.',
        icon: Icons.calendar_month_rounded,
        keywords: [
          'lịch học',
          'lịch thi',
          'thời khóa biểu',
          'ca thi',
          'môn học',
        ],
        priority: 880,
      ),
      _homeSection(
        id: 'home.quick_access',
        title: 'Truy cập nhanh',
        description:
            'Khu vực mở nhanh các chức năng thường dùng như điểm, học bổng, việc làm, đồng bộ. Nhấn ghim để chọn hiển thị nhiều chức năng hơn.',
        icon: Icons.apps_rounded,
        keywords: [
          'truy cập nhanh',
          'chức năng',
          'ghim',
          'mở nhanh',
          'tiện ích',
        ],
        priority: 870,
      ),
      _homeSection(
        id: 'home.notice',
        title: 'Thông báo quan trọng',
        description: 'Theo dõi các thông báo đào tạo quan trọng ngay trên trang chủ.',
        icon: Icons.campaign_rounded,
        keywords: [
          'thông báo quan trọng',
          'thông báo đào tạo',
          'tin đào tạo',
        ],
        priority: 860,
      ),
      _homeSection(
        id: 'home.news',
        title: 'Tin tức nổi bật',
        description: 'Xem nhanh tin Trường và tin VNU nổi bật.',
        icon: Icons.newspaper_rounded,
        keywords: [
          'tin tức',
          'tin trường',
          'tin vnu',
          'bài viết',
        ],
        priority: 850,
      ),
    ];

  static final List<AppGuideItem> _homeOverviewItems = [
      _homeWidget(
        id: 'home.overview.today_classes',
        groupId: 'home.overview.group',
        title: 'Tiết học hôm nay',
        description: 'Thẻ hiển thị số tiết học trong ngày hiện tại.',
        icon: Icons.menu_book_rounded,
        keywords: [
          'tiết học',
          'hôm nay',
          'lịch học hôm nay',
        ],
        fallbackId: 'home.overview',
        priority: 500,
        openAction: () async {
          Get.to(() => VcoreExamScheduleView(initialDate: DateTime.now()));
        },
      ),
      _homeWidget(
        id: 'home.overview.upcoming_exams',
        groupId: 'home.overview.group',
        title: 'Lịch thi sắp tới',
        description: 'Thẻ hiển thị số lịch thi sắp diễn ra.',
        icon: Icons.event_note_rounded,
        keywords: [
          'lịch thi',
          'sắp tới',
          'thi',
          'ca thi',
        ],
        fallbackId: 'home.overview',
        priority: 500,
        openAction: () async {
          Get.to(() => VcoreExamScheduleView(initialDate: DateTime.now()));
        },
      ),
      _homeWidget(
        id: 'home.overview.unread_notifications',
        groupId: 'home.overview.group',
        title: 'Thông báo mới',
        description: 'Thẻ hiển thị số thông báo mới chưa đọc.',
        icon: Icons.notifications_active_rounded,
        keywords: [
          'thông báo mới',
          'chưa đọc',
          'notification',
        ],
        fallbackId: 'home.overview',
        priority: 500,
        openAction: () async {
          Get.to(() => const VcoreNotifyViewV3());
        },
      ),
      _homeWidget(
        id: 'home.overview.manual_reminder',
        groupId: 'home.overview.group',
        title: 'Tạo lời nhắc',
        description: 'Tạo lời nhắc cá nhân theo ngày giờ.',
        icon: Icons.calendar_month_rounded,
        keywords: [
          'lời nhắc',
          'nhắc lịch',
          'calendar',
          'reminder',
        ],
        fallbackId: 'home.overview',
        priority: 480,
      ),
    ];

  static final List<AppGuideItem> _homeScheduleItems = [
      _homeWidget(
        id: 'home.schedule.tabs',
        groupId: 'home.schedule.group',
        title: 'Chuyển lịch học và lịch thi',
        description: 'Chuyển giữa tab Lịch học và tab Lịch thi.',
        icon: Icons.tab_rounded,
        keywords: [
          'tab',
          'lịch học',
          'lịch thi',
          'chuyển tab',
        ],
        fallbackId: 'home.schedule',
        priority: 520,
      ),
      _homeWidget(
        id: 'home.schedule.cards',
        groupId: 'home.schedule.group',
        title: 'Thẻ lịch học và lịch thi',
        description: 'Khu vực hiển thị thẻ lịch học hoặc lịch thi gần nhất.',
        icon: Icons.view_carousel_rounded,
        keywords: [
          'thẻ lịch',
          'card lịch',
          'lịch học',
          'lịch thi',
        ],
        fallbackId: 'home.schedule',
        priority: 510,
      ),
      _homeWidget(
        id: 'home.schedule.next_study',
        groupId: 'home.schedule.group',
        title: 'Lịch học hôm nay',
        description: 'Thẻ hiển thị lớp học hôm nay, tiết học, phòng học và giảng viên.',
        icon: Icons.menu_book_rounded,
        keywords: [
          'lịch học hôm nay',
          'môn học',
          'phòng học',
          'giảng viên',
        ],
        fallbackId: 'home.schedule',
        beforeHighlightActionId: 'home.show_study_tab',
        priority: 500,
      ),
      _homeWidget(
        id: 'home.schedule.study_timeline',
        groupId: 'home.schedule.group',
        title: 'Lịch học sắp tới',
        description: 'Danh sách các buổi học sắp tới trong những ngày gần nhất.',
        icon: Icons.timeline_rounded,
        keywords: [
          'lịch học sắp tới',
          'timeline',
          'buổi học',
        ],
        fallbackId: 'home.schedule',
        beforeHighlightActionId: 'home.show_study_tab',
        priority: 490,
      ),
      _homeWidget(
        id: 'home.schedule.next_exam',
        groupId: 'home.schedule.group',
        title: 'Lịch thi hôm nay',
        description: 'Chuyển sang tab Lịch thi và xem ca thi gần nhất trong ngày.',
        icon: Icons.quiz_rounded,
        keywords: [
          'lịch thi hôm nay',
          'ca thi',
          'môn thi',
          'phòng thi',
          'giờ thi',
        ],
        fallbackId: 'home.schedule',
        beforeHighlightActionId: 'home.show_exam_tab',
        priority: 500,
      ),
      _homeWidget(
        id: 'home.schedule.exam_timeline',
        groupId: 'home.schedule.group',
        title: 'Lịch thi sắp tới',
        description: 'Danh sách các ca thi sắp tới trong những ngày gần nhất.',
        icon: Icons.fact_check_rounded,
        keywords: [
          'lịch thi sắp tới',
          'timeline thi',
          'môn thi',
          'phòng thi',
        ],
        fallbackId: 'home.schedule',
        beforeHighlightActionId: 'home.show_exam_tab',
        priority: 490,
      ),
    ];

  static final List<AppGuideItem> _homeQuickAccessItems = [
      _homeWidget(
        id: 'home.quick_access.pin',
        groupId: 'home.quick_access.group',
        title: 'Ghim chức năng',
        description: 'Tùy chỉnh các chức năng thường dùng trong khu vực truy cập nhanh.',
        icon: Icons.push_pin_rounded,
        keywords: [
          'ghim',
          'pin',
          'tùy chỉnh',
          'truy cập nhanh',
        ],
        fallbackId: 'home.quick_access',
        priority: 520,
      ),
      _homeWidget(
        id: 'home.quick_access.list',
        groupId: 'home.quick_access.group',
        title: 'Danh sách chức năng ghim',
        description: 'Các chức năng được ghim để mở nhanh trên trang chủ.',
        icon: Icons.apps_rounded,
        keywords: [
          'danh sách chức năng',
          'truy cập nhanh',
          'ghim',
        ],
        fallbackId: 'home.quick_access',
        priority: 510,
      ),
    ];

  static final List<AppGuideItem> _homeNoticeItems = [
      _homeWidget(
        id: 'home.notice.header',
        groupId: 'home.notice.group',
        title: 'Tiêu đề thông báo quan trọng',
        description: 'Mở toàn bộ danh sách thông báo quan trọng.',
        icon: Icons.campaign_rounded,
        keywords: [
          'thông báo quan trọng',
          'xem tất cả',
          'tin đào tạo',
        ],
        fallbackId: 'home.notice',
        priority: 500,
        openAction: () async {
          Get.to(() => const VcoreNotifyViewV3());
        },
      ),
      _homeWidget(
        id: 'home.notice.list',
        groupId: 'home.notice.group',
        title: 'Danh sách thông báo quan trọng',
        description: 'Các thông báo đào tạo mới nhất được hiển thị trên trang chủ.',
        icon: Icons.list_alt_rounded,
        keywords: [
          'danh sách thông báo',
          'thông báo đào tạo',
          'tin đào tạo',
        ],
        fallbackId: 'home.notice',
        priority: 490,
      ),
    ];

  static final List<AppGuideItem> _homeNewsItems = [
      _homeWidget(
        id: 'home.news.header',
        groupId: 'home.news.group',
        title: 'Tiêu đề tin tức nổi bật',
        description: 'Mở màn danh sách tin tức đầy đủ.',
        icon: Icons.newspaper_rounded,
        keywords: [
          'tin tức nổi bật',
          'xem tất cả',
          'tin trường',
          'tin vnu',
        ],
        fallbackId: 'home.news',
        priority: 500,
      ),
      _homeWidget(
        id: 'home.news.tabs',
        groupId: 'home.news.group',
        title: 'Chọn nguồn tin',
        description: 'Chuyển giữa Tin Trường và Tin VNU.',
        icon: Icons.tab_rounded,
        keywords: [
          'tin trường',
          'tin vnu',
          'tab tin tức',
        ],
        fallbackId: 'home.news',
        priority: 500,
      ),
      _homeWidget(
        id: 'home.news.carousel',
        groupId: 'home.news.group',
        title: 'Carousel tin tức',
        description: 'Khu vực hiển thị các tin tức nổi bật dạng thẻ trượt.',
        icon: Icons.view_carousel_rounded,
        keywords: [
          'carousel',
          'tin tức',
          'tin nổi bật',
          'bài viết',
        ],
        fallbackId: 'home.news',
        priority: 490,
      ),
    ];

  static final List<AppGuideItem> _homeFunctionItems = [
      _homeFunction(
        id: 'home.function.exam_schedule',
        title: 'Lịch học & thi',
        description: 'Mở màn lịch học và lịch thi chi tiết.',
        icon: Icons.calendar_month_rounded,
        keywords: [
          'lịch học',
          'lịch thi',
          'thời khóa biểu',
        ],
        openAction: () async {
          Get.to(() => const VcoreExamScheduleView());
        },
      ),
      _homeFunction(
        id: 'home.function.course_points',
        title: 'Điểm',
        description: 'Mở màn điểm học tập và kết quả học tập.',
        icon: Icons.grade_rounded,
        keywords: [
          'điểm',
          'bảng điểm',
          'gpa',
          'kết quả học tập',
        ],
        openAction: () async {
          Get.to(() => const VcoreCoursePointsView());
        },
      ),
      _homeFunction(
        id: 'home.function.course_register',
        title: 'Đăng ký môn',
        description: 'Chức năng đăng ký học phần.',
        icon: Icons.border_color_rounded,
        keywords: [
          'đăng ký môn',
          'đăng ký học phần',
          'học phần',
        ],
      ),
      _homeFunction(
        id: 'home.function.jobs',
        title: 'Việc làm',
        description: 'Mở thông tin việc làm và cơ hội nghề nghiệp.',
        icon: Icons.work_outline_rounded,
        keywords: [
          'việc làm',
          'tuyển dụng',
          'nghề nghiệp',
        ],
        openAction: () async {
          Get.to(() => const VcoreJobsViewV2());
        },
      ),
      _homeFunction(
        id: 'home.function.sync',
        title: 'Đồng bộ',
        description: 'Mở chức năng đồng bộ dữ liệu.',
        icon: Icons.sync_rounded,
        keywords: [
          'đồng bộ',
          'sync',
          'vneid',
        ],
        openAction: () async {
          Get.to(() => VcoreSyncView());
        },
      ),
      _homeFunction(
        id: 'home.function.tuition',
        title: 'Học phí',
        description: 'Theo dõi học phí và các khoản cần nộp.',
        icon: Icons.account_balance_wallet_rounded,
        keywords: [
          'học phí',
          'tài chính',
          'khoản nộp',
        ],
      ),
      _homeFunction(
        id: 'home.function.documents',
        title: 'Tài liệu',
        description: 'Truy cập tài liệu học tập.',
        icon: Icons.folder_open_rounded,
        keywords: [
          'tài liệu',
          'file',
          'học tập',
        ],
      ),
      _homeFunction(
        id: 'home.function.attendance',
        title: 'Điểm danh',
        description: 'Theo dõi hoặc thực hiện điểm danh.',
        icon: Icons.how_to_reg_rounded,
        keywords: [
          'điểm danh',
          'attendance',
        ],
      ),
      _homeFunction(
        id: 'home.function.scholarship',
        title: 'Học bổng',
        description: 'Mở chức năng học bổng.',
        icon: Icons.card_membership_rounded,
        keywords: [
          'học bổng',
          'scholarship',
          'hồ sơ học bổng',
        ],
        openAction: () async {
          Get.to(() => VnuHocBong.screen());
        },
      ),
      _homeFunction(
        id: 'home.function.paht',
        title: 'Phản ánh',
        description: 'Gửi và theo dõi phản ánh hiện trường.',
        icon: Icons.rate_review_rounded,
        keywords: [
          'phản ánh',
          'phản ánh hiện trường',
          'góp ý',
        ],
        openAction: () async {
          Get.to(() => const VcorePahtViewV2());
        },
      ),
      _homeFunction(
        id: 'home.function.boarding',
        title: 'Nội trú',
        description: 'Mở chức năng đăng ký hoặc theo dõi nội trú.',
        icon: Icons.home_work_rounded,
        keywords: [
          'nội trú',
          'ký túc xá',
          'dormitory',
        ],
        openAction: () async {
          Get.to(() => const DRMyRegistrationScreen());
        },
      ),
      _homeFunction(
        id: 'home.function.motel',
        title: 'Phòng trọ',
        description: 'Mở thông tin phòng trọ tham khảo.',
        icon: Icons.home_outlined,
        keywords: [
          'phòng trọ',
          'nhà trọ',
          'motel',
        ],
        openAction: () async {
          openMotelWebView();
        },
      ),
      _homeFunction(
        id: 'home.function.one_door',
        title: 'Thủ tục',
        description: 'Mở chức năng thủ tục một cửa.',
        icon: Icons.assignment_turned_in_rounded,
        keywords: [
          'thủ tục',
          'một cửa',
          'hành chính',
        ],
        openAction: () async {
          Get.to(() => const VcoreOneDoorView());
        },
      ),
      _homeFunction(
        id: 'home.function.library',
        title: 'Thư viện',
        description: 'Truy cập tiện ích thư viện.',
        icon: Icons.local_library_rounded,
        keywords: [
          'thư viện',
          'library',
          'sách',
        ],
      ),
      _homeFunction(
        id: 'home.function.map',
        title: 'Bản đồ',
        description: 'Mở bản đồ số trong trường.',
        icon: Icons.map_rounded,
        keywords: [
          'bản đồ',
          'map',
          'đường đi',
          'vị trí',
        ],
        openAction: () async {
          Get.to(() => const VcoreImmapView());
        },
      ),
      _homeFunction(
        id: 'home.function.question',
        title: 'Hỏi đáp',
        description: 'Mở chức năng hỏi đáp sinh viên.',
        icon: Icons.question_answer_rounded,
        keywords: [
          'hỏi đáp',
          'câu hỏi',
          'trao đổi',
        ],
        openAction: () async {
          Get.to(() => VcoreQuestionView());
        },
      ),
      _homeFunction(
        id: 'home.function.handbook',
        title: 'Cẩm nang',
        description: 'Mở cẩm nang sinh viên.',
        icon: Icons.menu_book_rounded,
        keywords: [
          'cẩm nang',
          'hướng dẫn',
          'sinh viên',
        ],
        openAction: () async {
          Get.to(() => const VcoreCamNangView());
        },
      ),
    ];

  static AppGuideItem _homeSection({
      required String id,
      required String title,
      required String description,
      required IconData icon,
      required List<String> keywords,
      required int priority,
    }) {
      return AppGuideItem(
        id: id,
        moduleId: AppGuideModuleIds.home,
        groupId: 'home.intro',
        pageId: 'home',
        type: AppGuideItemType.section,
        priority: priority,
        title: title,
        description: description,
        icon: icon,
        keywords: keywords,
      );
    }

  static AppGuideItem _homeWidget({
      required String id,
      required String groupId,
      required String title,
      required String description,
      required IconData icon,
      required List<String> keywords,
      String? fallbackId,
      String? beforeHighlightActionId,
      Future<void> Function()? openAction,
      int priority = 100,
    }) {
      return AppGuideItem(
        id: id,
        moduleId: AppGuideModuleIds.home,
        groupId: groupId,
        pageId: 'home',
        type: AppGuideItemType.widget,
        priority: priority,
        fallbackId: fallbackId,
        beforeHighlightActionId: beforeHighlightActionId,
        title: title,
        description: description,
        icon: icon,
        keywords: keywords,
        openAction: openAction,
      );
    }

  static AppGuideItem _homeFunction({
      required String id,
      required String title,
      required String description,
      required IconData icon,
      required List<String> keywords,
      Future<void> Function()? openAction,
    }) {
      return AppGuideItem(
        id: id,
        moduleId: AppGuideModuleIds.home,
        groupId: 'home.quick_access.group',
        pageId: 'home',
        type: AppGuideItemType.function,
        priority: 750,
        preferInSearch: true,
        fallbackId: 'home.quick_access',
        title: title,
        description: description,
        icon: icon,
        keywords: keywords,
        openAction: openAction,
      );
    }
}
