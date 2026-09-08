import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/guide/guide.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

import '../../../models/model.dart';
import '../controllers/vcore_exam_schedule_controller.dart';
import '../widgets/academic_period_select.dart';

/// Màn Lịch học & Lịch thi ở chế độ LIST-ONLY.
///
/// Chủ đích thiết kế:
/// - Không dựng calendar tháng.
/// - Không hiển thị / không suy diễn ngày học từ ngày bắt đầu-kết thúc học kỳ.
/// - Lịch học hiển thị trực tiếp dữ liệu lớp theo thứ + tiết + phòng + giảng viên.
/// - Lịch thi vẫn hiển thị ngày thi do API trả trực tiếp trên từng record.
/// - Không quy đổi số tiết sang giờ đồng hồ vào/ra nếu API không có giờ thực tế.
/// - Cảnh báo có 4 trạng thái: compact -> summary -> detail, và initial detail.
class VcoreExamScheduleView extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialHocKyId;
  final String? initialKieuTruong;

  /// Khi true, lần đầu tiên người dùng mở chức năng sẽ vào state 3 và tự mở
  /// phần giải thích đầy đủ. Sau khi đã kéo đến cuối và đóng bằng X, cờ đã đọc
  /// được lưu cục bộ; những lần sau chỉ còn cảnh báo thu gọn state 0.
  final bool showInitialNotice;

  const VcoreExamScheduleView({
    super.key,
    this.initialDate,
    this.initialHocKyId,
    this.initialKieuTruong,
    this.showInitialNotice = true,
  });

  @override
  State<VcoreExamScheduleView> createState() =>
      _VcoreExamScheduleViewState();
}

class _VcoreExamScheduleViewState extends State<VcoreExamScheduleView> {
  static const Color _warningColor = Color(0xFFB42318);
  static const Color _warningBackground = Color(0xFFFFF1F0);
  static const Color _warningBorder = Color(0xFFFDA29B);
  static const Color _examColor = Color(0xFFFFB703);

  int _selectedTab = 0;

  /// Warning state machine:
  /// 0 = một dòng thu gọn.
  /// 1 = mở rộng phần giải thích ngắn ngay trên màn.
  /// 2 = mở sheet chi tiết do người dùng chủ động nhấn lần 2.
  /// 3 = sheet chi tiết chỉ tự mở ở lần đầu + banner nhắc đọc kỹ 10 giây.
  int _noticeState = 0;

  static const String _noticeSeenKey = 'onevnu_tkb_notice_v5_read';

  static const List<_ScheduleNoticeItem> _noticeItems = [
    _ScheduleNoticeItem(
      '1. Vì sao lịch học không còn hiện ngày cụ thể như trước?',
      'Ở bản trước, ứng dụng có thể ghép “Thứ 2”, “Thứ 3”… với khoảng thời gian của học kỳ để hiện thành các ngày cụ thể. Cách này dễ khiến sinh viên nghĩ đó là ngày học đã được chốt, trong khi lịch thực tế của từng trường, từng môn hoặc từng đợt học có thể khác. Vì vậy bản này không còn tự hiện ngày cụ thể cho lịch học.',
    ),
    _ScheduleNoticeItem(
      '2. Vì sao không còn giờ vào tiết và giờ ra tiết?',
      'Ở bản trước, ứng dụng có thể đổi “Tiết 1-3”, “Tiết 4-6”… thành giờ đồng hồ. Tuy nhiên cùng một số tiết có thể bắt đầu và kết thúc ở giờ khác nhau giữa các trường, cơ sở, học kỳ hoặc loại môn. Nếu tự đổi thành giờ, sinh viên có thể hiểu nhầm giờ vào lớp. Vì vậy bản này chỉ giữ số tiết.',
    ),
    _ScheduleNoticeItem(
      '3. Số tiết vẫn được giữ nguyên',
      'Nếu lịch học có “Tiết 4-6”, OneVNU vẫn hiển thị “Tiết 4-6”. Đây là thông tin giúp sinh viên biết ca học của môn. Phần bị bỏ chỉ là ngày cụ thể và giờ đồng hồ do ứng dụng tự tính thêm.',
    ),
    _ScheduleNoticeItem(
      '4. Mỗi trường có thể có thời gian học kỳ khác nhau',
      'Cùng là Học kỳ 1 nhưng trường này có thể bắt đầu sớm hơn hoặc kết thúc muộn hơn trường khác. Vì vậy không thể dùng một khoảng thời gian chung để tính ngày học cho tất cả sinh viên trong ĐHQGHN.',
    ),
    _ScheduleNoticeItem(
      '5. Một học kỳ có thể chia thành nhiều đợt hoặc có tuần nghỉ',
      'Có môn học theo nửa học kỳ, theo từng đợt hoặc có thời gian nghỉ ở giữa. Nếu chỉ nhìn ngày bắt đầu và ngày kết thúc của cả học kỳ, ứng dụng có thể hiện những ngày mà thực tế môn đó không học.',
    ),
    _ScheduleNoticeItem(
      '6. Có thể có nghỉ lễ, đổi lịch và học bù',
      'Một buổi học theo lịch tuần có thể được nghỉ, chuyển sang ngày khác hoặc học bù. Vì vậy chỉ biết môn học vào “Thứ 2” chưa đủ để khẳng định chắc chắn một ngày cụ thể trong tháng.',
    ),
    _ScheduleNoticeItem(
      '7. Mỗi môn có thể bắt đầu và kết thúc ở thời điểm khác nhau',
      'Có môn học cả học kỳ, có môn chỉ học vài tuần, có môn bắt đầu muộn hoặc kết thúc sớm. Vì vậy OneVNU không lấy thời gian của cả học kỳ để tự tính ngày cho từng môn.',
    ),
    _ScheduleNoticeItem(
      '8. Sinh viên có thể học môn do trường hoặc đơn vị khác tổ chức',
      'Sinh viên thuộc một trường vẫn có thể học môn do trường hoặc đơn vị khác trong ĐHQGHN tổ chức. Khi đó lịch học, lịch nghỉ và giờ vào tiết có thể theo nơi tổ chức môn học chứ không theo trường của sinh viên.',
    ),
    _ScheduleNoticeItem(
      '9. Học kỳ hè, học kỳ phụ hoặc đợt học mùa đông có thể khác học kỳ chính',
      'Ngay trong cùng một trường, các đợt học đặc biệt có thể dùng thời gian bắt đầu, thời lượng tiết và giờ nghỉ khác với học kỳ chính. Vì vậy không nên dùng một khung giờ cố định cho tất cả các kỳ học.',
    ),
    _ScheduleNoticeItem(
      '10. Một số môn có thời gian học riêng',
      'Thực hành, thí nghiệm, giáo dục thể chất, học trực tuyến hoặc môn học theo ca có thể có giờ học khác với các môn học trên lớp thông thường.',
    ),
    _ScheduleNoticeItem(
      '11. Lịch học có thể thay đổi sau khi đã công bố',
      'Trong quá trình học, thứ, số tiết, phòng học, hình thức học hoặc giảng viên có thể được điều chỉnh. Sinh viên nên theo dõi thêm thông báo của trường hoặc đơn vị tổ chức môn học.',
    ),
    _ScheduleNoticeItem(
      '12. Lịch học ở Trang chủ cũng thay đổi',
      'Phần “Lịch học sắp tới” trên Trang chủ không còn gắn ngày như 09/09, 10/09… cho lịch học. Thay vào đó, OneVNU hiển thị “Thứ 2”, “Thứ 3”… cùng số tiết để tránh sinh viên hiểu nhầm một ngày chưa được xác nhận.',
    ),
    _ScheduleNoticeItem(
      '13. Lịch thi vẫn giữ ngày và giờ khi có thông tin',
      'Lịch thi khác với lịch học tuần. Khi nhà trường đã cung cấp ngày thi hoặc giờ thi cho từng môn, OneVNU vẫn hiển thị những thông tin đó như trước.',
    ),
    _ScheduleNoticeItem(
      '14. Cách xem lịch học từ bản này',
      'Hãy xem lịch học theo “Thứ + Tiết + Phòng + Giảng viên”. Ví dụ: “Thứ 2 • Tiết 4-6 • Phòng 203-B”. Đây là cách hiển thị phù hợp hơn khi chưa có lịch theo từng ngày cụ thể.',
    ),
    _ScheduleNoticeItem(
      '15. Khi có thông báo điều chỉnh lịch, nên xem thông tin của nhà trường',
      'OneVNU giúp bạn xem nhanh lịch đang được cung cấp. Nếu trường hoặc đơn vị tổ chức môn học có thông báo đổi ngày, đổi giờ, đổi phòng hoặc học bù, hãy ưu tiên thông báo mới nhất của đơn vị đó.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openInitialNoticeIfNeeded());
    });
  }

  Future<void> _openInitialNoticeIfNeeded() async {
    if (!mounted || !widget.showInitialNotice) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyRead = prefs.getBool(_noticeSeenKey) ?? false;
    if (!mounted || alreadyRead) {
      debugPrint('[TKB_NOTICE][STATE_0] initial detail already read');
      return;
    }

    debugPrint('[TKB_NOTICE][STATE_3] first entry -> open full explanation');
    final readComplete = await _showScheduleNoticeDetails(
      context,
      initialMode: true,
    );

    if (readComplete) {
      await prefs.setBool(_noticeSeenKey, true);
      debugPrint('[TKB_NOTICE] first-entry explanation marked as read');
    }
  }

  void _setNoticeState(int state, String reason) {
    if (!mounted || _noticeState == state) return;
    debugPrint('[TKB_NOTICE] state=$_noticeState -> $state reason=$reason');
    setState(() => _noticeState = state);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcoreExamScheduleController>(
      init: VcoreExamScheduleController(),
      builder: (controller) {
        if (widget.initialDate != null ||
            widget.initialHocKyId != null ||
            widget.initialKieuTruong != null) {
          controller.setInitialContext(
            date: widget.initialDate,
            hocKyId: widget.initialHocKyId,
            kieuTruongValue: widget.initialKieuTruong,
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
              body: Container(
                color: const Color(0xFFF6F7FB),
                child: Stack(
                  children: [
                    SmartRefresher(
                      controller: controller.refreshController,
                      onRefresh: () => controller.refreshData(),
                      enablePullDown: true,
                      header: const WaterDropHeader(
                        waterDropColor: AppColors.greenAccent,
                      ),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 32),
                        children: [
                          Obx(() => _buildAcademicPeriodSelector(controller)),
                          const SizedBox(height: 10),
                          _buildScheduleWarningCard(context),
                          const SizedBox(height: 12),
                          _buildTabSelector(controller),
                          const SizedBox(height: 4),
                          AppGuideAnchor(
                            id: 'exam_schedule.list',
                            child: Obx(() {
                              if (controller.hocKySelected.value == null) {
                                return _buildEmptyState(
                                  icon: Icons.school_outlined,
                                  title: 'Chưa chọn học kỳ',
                                  message:
                                      'Vui lòng chọn đơn vị, năm học và học kỳ để xem dữ liệu.',
                                );
                              }

                              if (_selectedTab == 0) {
                                return _buildClassScheduleList(
                                  context,
                                  controller.listThoiKhoaBieu.toList(),
                                );
                              }
                              return _buildExamScheduleList(
                                context,
                                controller.listLichThi.toList(),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Obx(() {
                        if (!controller.isLoading.value) {
                          return const SizedBox.shrink();
                        }
                        return const LinearProgressIndicator(
                          minHeight: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.greenAccent,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcademicPeriodSelector(
    VcoreExamScheduleController controller,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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

  Widget _buildScheduleWarningCard(BuildContext context) {
    final expanded = _noticeState == 1;

    return Semantics(
      button: true,
      label: expanded
          ? 'Lưu ý lịch học đang mở rộng. Nhấn lần nữa để xem chi tiết.'
          : 'Lưu ý quan trọng về lịch học. Nhấn để mở rộng.',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _warningBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _warningBorder),
          boxShadow: [
            BoxShadow(
              color: _warningColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (!expanded) {
                _setNoticeState(1, 'compact_tap');
                return;
              }
              unawaited(
                _showScheduleNoticeDetails(
                  context,
                  initialMode: false,
                ).then<void>((_) {}),
              );
            },
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  13,
                  expanded ? 13 : 11,
                  13,
                  expanded ? 13 : 11,
                ),
                child: expanded
                    ? _buildExpandedWarningSummary()
                    : _buildCompactWarningLine(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactWarningLine() {
    return const Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: _warningColor,
          size: 21,
        ),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Lưu ý: cách xem ngày và giờ học đã thay đổi — chạm để xem',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF7A271A),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 6),
        Icon(
          Icons.expand_more_rounded,
          color: _warningColor,
          size: 21,
        ),
      ],
    );
  }

  Widget _buildExpandedWarningSummary() {
    Widget bullet(String text) {
      return Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                color: _warningColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyles.regular.copyWith(
                  color: const Color(0xFF7A271A),
                  fontSize: AppFontSizes.small,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _warningColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: _warningColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Có gì khác so với bản trước?',
                    style: TextStyles.bold.copyWith(
                      color: _warningColor,
                      fontSize: AppFontSizes.mediumSmall,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Một số ngày và giờ từng thấy ở bản trước có thể khiến sinh viên hiểu đó là lịch đã được chốt. Bản này thay đổi cách hiển thị để hạn chế nhầm ngày học hoặc giờ vào tiết.',
                    style: TextStyles.regular.copyWith(
                      color: const Color(0xFF7A271A),
                      fontSize: AppFontSizes.small,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bullet(
          'Bản trước: lịch học có thể hiện ngày cụ thể và giờ vào/ra do ứng dụng tính thêm từ lịch học kỳ và số tiết.',
        ),
        bullet(
          'Bản này: lịch học hiển thị Thứ + số tiết + phòng + giảng viên; không tự thêm ngày cụ thể hoặc giờ đồng hồ.',
        ),
        bullet(
          'Lý do: mỗi trường, cơ sở, học kỳ hè, đợt học mùa đông và một số môn có thể có lịch hoặc giờ vào tiết khác nhau.',
        ),
        bullet(
          'Lịch thi vẫn giữ ngày và giờ khi nhà trường đã cung cấp thông tin cụ thể cho từng môn.',
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _warningBorder.withOpacity(0.75)),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  'Nhấn thêm lần nữa để xem đầy đủ lý do và những thay đổi so với bản trước',
                  style: TextStyle(
                    color: _warningColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_right_rounded,
                size: 19,
                color: _warningColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector(VcoreExamScheduleController controller) {
    return Obx(() {
      final classCount = controller.listThoiKhoaBieu.length;
      final examCount = controller.listLichThi.length;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDF3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                selected: _selectedTab == 0,
                icon: Icons.menu_book_rounded,
                label: 'Lịch học',
                count: classCount,
                onTap: () {
                  if (_selectedTab != 0) {
                    setState(() => _selectedTab = 0);
                  }
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildTabButton(
                selected: _selectedTab == 1,
                icon: Icons.assignment_rounded,
                label: 'Lịch thi',
                count: examCount,
                selectedColor: _examColor,
                onTap: () {
                  if (_selectedTab != 1) {
                    setState(() => _selectedTab = 1);
                  }
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabButton({
    required bool selected,
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
    Color selectedColor = AppColors.greenAccent,
  }) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? selectedColor : Colors.grey.shade600,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.semiBold.copyWith(
                    fontSize: AppFontSizes.small,
                    color: selected ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? selectedColor.withOpacity(0.10)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? selectedColor : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassScheduleList(
    BuildContext context,
    List<ThoiKhoaBieuModel> source,
  ) {
    final items = List<ThoiKhoaBieuModel>.from(source)
      ..sort(_compareClassRows);

    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Chưa có dữ liệu lịch học',
        message:
            'Kéo xuống để làm mới hoặc kiểm tra lại học kỳ/đơn vị đã chọn.',
      );
    }

    final groups = <String, List<ThoiKhoaBieuModel>>{};
    for (final item in items) {
      final key = _weekdayLabel(item.ngayTrongTuan);
      groups.putIfAbsent(key, () => <ThoiKhoaBieuModel>[]).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        ...groups.entries.map(
          (entry) => _buildClassDaySection(
            context,
            entry.key,
            entry.value,
          ),
        ),
      ],
    );
  }

  Widget _buildClassDaySection(
    BuildContext context,
    String weekday,
    List<ThoiKhoaBieuModel> items,
  ) {
    final isUnknown = weekday == 'Chưa cập nhật thứ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isUnknown
                      ? _warningBackground
                      : AppColors.greenAccent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  isUnknown
                      ? Icons.help_outline_rounded
                      : Icons.calendar_view_week_rounded,
                  size: 17,
                  color: isUnknown ? _warningColor : AppColors.greenAccent,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  weekday,
                  style: TextStyles.bold.copyWith(
                    fontSize: AppFontSizes.medium,
                    color: isUnknown ? _warningColor : Colors.black87,
                  ),
                ),
              ),
              Text(
                '${items.length} học phần',
                style: TextStyles.medium.copyWith(
                  fontSize: AppFontSizes.font11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildClassCard(context, item)),
      ],
    );
  }

  Widget _buildClassCard(
    BuildContext context,
    ThoiKhoaBieuModel item,
  ) {
    final title = _textOrFallback(item.tenHocPhan, 'Học phần chưa cập nhật tên');
    final code = _textOrFallback(item.maHocPhan, 'Chưa có mã HP');
    final credits = _textOrFallback(item.soTinChi, '?');
    final group = _textOrFallback(item.nhom, '?');
    final weekday = _weekdayLabel(item.ngayTrongTuan);
    final lesson = _lessonRange(item.tietBatDau, item.tietKetThuc);
    final room = _textOrFallback(item.tenPhong, 'Chưa cập nhật');
    final address = item.diaChi?.trim() ?? '';
    final teachers = _teacherNames(item);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.greenAccent.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.greenAccent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.bold.copyWith(
                        fontSize: AppFontSizes.medium,
                        color: Colors.black87,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$code  •  $credits tín chỉ  •  Nhóm $group',
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
          const SizedBox(height: 13),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.event_repeat_rounded,
            label: 'Lịch học',
            value: '$weekday • $lesson',
            warning: weekday == 'Chưa cập nhật thứ' ||
                lesson == 'Chưa cập nhật tiết học',
          ),
          const SizedBox(height: 9),
          _buildInfoRow(
            icon: Icons.meeting_room_outlined,
            label: 'Phòng học',
            value: address.isEmpty ? room : '$room\n$address',
            warning: room == 'Chưa cập nhật',
          ),
          const SizedBox(height: 9),
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Giảng viên',
            value: teachers.isEmpty ? 'Chưa cập nhật' : teachers,
            warning: teachers.isEmpty,
          ),
        ],
      ),
    );
  }

  Widget _buildExamScheduleList(
    BuildContext context,
    List<LichThiHocKyModel> source,
  ) {
    final items = List<LichThiHocKyModel>.from(source)
      ..sort(_compareExamRows);

    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_outlined,
        title: 'Chưa có dữ liệu lịch thi',
        message:
            'Kéo xuống để làm mới hoặc kiểm tra lại học kỳ/đơn vị đã chọn.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          child: Text(
            'Danh sách lịch thi',
            style: TextStyles.bold.copyWith(
              fontSize: AppFontSizes.medium,
              color: Colors.black87,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Ngày và giờ thi chỉ hiển thị khi đơn vị đào tạo đã cung cấp. Thông tin chưa có sẽ được ghi rõ là “Chưa cập nhật”.',
            style: TextStyles.regular.copyWith(
              fontSize: AppFontSizes.small,
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),
        ),
        ...items.map((exam) => _buildExamCard(context, exam)),
      ],
    );
  }

  Widget _buildExamCard(
    BuildContext context,
    LichThiHocKyModel exam,
  ) {
    final title = _textOrFallback(exam.tenHocPhan, 'Học phần chưa cập nhật tên');
    final code = _textOrFallback(exam.maHocPhan, 'Chưa có mã HP');
    final credits = _textOrFallback(exam.soTinChi, '?');
    final date = _formatExamDate(exam.ngayThi);
    final time = _textOrFallback(exam.gioBatDauThi, 'Chưa cập nhật');
    final room = _textOrFallback(exam.phongThi, 'Chưa cập nhật');
    final address = exam.diaChi?.trim() ?? '';
    final type = _textOrFallback(exam.hinhThucThi, 'Chưa cập nhật');
    final examShift = _textOrFallback(exam.caThi, 'Chưa cập nhật');
    final duration = exam.thoiLuong?.trim().isNotEmpty == true
        ? '${exam.thoiLuong!.trim()} phút'
        : 'Chưa cập nhật';
    final candidateNumber =
        _textOrFallback(exam.sobaodanh, 'Chưa cập nhật');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFFE3A3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: _examColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.bold.copyWith(
                        fontSize: AppFontSizes.medium,
                        color: Colors.black87,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$code  •  $credits tín chỉ',
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
          const SizedBox(height: 13),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.event_rounded,
            label: 'Ngày thi',
            value: date,
            warning: date == 'Chưa cập nhật',
            accentColor: _examColor,
          ),
          const SizedBox(height: 9),
          _buildInfoRow(
            icon: Icons.schedule_rounded,
            label: 'Giờ / ca',
            value: '$time • Ca $examShift • $duration',
            warning: time == 'Chưa cập nhật',
            accentColor: _examColor,
          ),
          const SizedBox(height: 9),
          _buildInfoRow(
            icon: Icons.meeting_room_outlined,
            label: 'Phòng thi',
            value: address.isEmpty ? room : '$room\n$address',
            warning: room == 'Chưa cập nhật',
            accentColor: _examColor,
          ),
          const SizedBox(height: 9),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'SBD',
            value: candidateNumber,
            warning: candidateNumber == 'Chưa cập nhật',
            accentColor: _examColor,
          ),
          const SizedBox(height: 9),
          _buildInfoRow(
            icon: Icons.fact_check_outlined,
            label: 'Hình thức',
            value: type,
            warning: type == 'Chưa cập nhật',
            accentColor: _examColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool warning,
    Color accentColor = AppColors.greenAccent,
  }) {
    final valueColor = warning ? _warningColor : const Color(0xFF344054);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: warning
                ? _warningBackground
                : accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: warning ? _warningColor : accentColor,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 76,
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              label,
              style: TextStyles.medium.copyWith(
                fontSize: AppFontSizes.font11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              value,
              style: TextStyles.semiBold.copyWith(
                fontSize: AppFontSizes.small,
                color: valueColor,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
      child: Column(
        children: [
          Icon(icon, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyles.bold.copyWith(
              fontSize: AppFontSizes.medium,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyles.regular.copyWith(
              fontSize: AppFontSizes.small,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showScheduleNoticeDetails(
    BuildContext context, {
    required bool initialMode,
  }) async {
    _setNoticeState(
      initialMode ? 3 : 2,
      initialMode ? 'initial_detail_open' : 'manual_detail_open',
    );

    final readComplete = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.48),
      builder: (sheetContext) {
        return _ScheduleNoticeSheet(
          items: _noticeItems,
          initialMode: initialMode,
        );
      },
    );

    if (mounted) {
      debugPrint('[TKB_NOTICE][STATE_0] detail closed -> compact');
      _setNoticeState(0, 'detail_closed');
    }
    return readComplete == true;
  }


  int _compareClassRows(ThoiKhoaBieuModel a, ThoiKhoaBieuModel b) {
    final aw = int.tryParse(a.ngayTrongTuan?.trim() ?? '') ?? 99;
    final bw = int.tryParse(b.ngayTrongTuan?.trim() ?? '') ?? 99;
    if (aw != bw) return aw.compareTo(bw);

    final ap = int.tryParse(a.tietBatDau?.trim() ?? '') ?? 999;
    final bp = int.tryParse(b.tietBatDau?.trim() ?? '') ?? 999;
    if (ap != bp) return ap.compareTo(bp);

    return (a.tenHocPhan ?? '').compareTo(b.tenHocPhan ?? '');
  }

  int _compareExamRows(LichThiHocKyModel a, LichThiHocKyModel b) {
    final ad = _parseExamDate(a.ngayThi);
    final bd = _parseExamDate(b.ngayThi);

    if (ad != null && bd != null) {
      final cmp = ad.compareTo(bd);
      if (cmp != 0) return cmp;
    } else if (ad != null) {
      return -1;
    } else if (bd != null) {
      return 1;
    }

    final at = a.gioBatDauThi?.trim() ?? '';
    final bt = b.gioBatDauThi?.trim() ?? '';
    final timeCmp = at.compareTo(bt);
    if (timeCmp != 0) return timeCmp;

    return (a.tenHocPhan ?? '').compareTo(b.tenHocPhan ?? '');
  }

  String _weekdayLabel(String? value) {
    switch (value?.trim()) {
      case '1':
        return 'Thứ 2';
      case '2':
        return 'Thứ 3';
      case '3':
        return 'Thứ 4';
      case '4':
        return 'Thứ 5';
      case '5':
        return 'Thứ 6';
      case '6':
        return 'Thứ 7';
      case '7':
        return 'Chủ nhật';
      default:
        return 'Chưa cập nhật thứ';
    }
  }

  String _lessonRange(String? start, String? end) {
    final s = start?.trim() ?? '';
    final e = end?.trim() ?? '';
    if (s.isEmpty && e.isEmpty) return 'Chưa cập nhật tiết học';
    if (s.isNotEmpty && e.isNotEmpty) return 'Tiết $s - $e';
    return 'Tiết ${s.isNotEmpty ? s : e}';
  }

  String _teacherNames(ThoiKhoaBieuModel item) {
    final values = <String?>[
      item.giangVien1,
      item.giangVien2,
      item.giangVien3,
      item.giangVien4,
    ];
    final seen = <String>{};
    final result = <String>[];

    for (final raw in values) {
      final value = raw?.trim() ?? '';
      if (value.isEmpty) continue;
      final normalized = value.toLowerCase();
      if (seen.add(normalized)) {
        result.add(value);
      }
    }
    return result.join(', ');
  }

  String _textOrFallback(String? value, String fallback) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  DateTime? _parseExamDate(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    final direct = DateTime.tryParse(value);
    if (direct != null) return direct;

    const formats = <String>['dd/MM/yyyy', 'dd-MM-yyyy', 'yyyy/MM/dd'];
    for (final pattern in formats) {
      try {
        return DateFormat(pattern).parseStrict(value);
      } catch (_) {
        // Try the next known format.
      }
    }
    return null;
  }

  String _formatExamDate(String? raw) {
    final date = _parseExamDate(raw);
    if (date == null) {
      final text = raw?.trim() ?? '';
      return text.isEmpty ? 'Chưa cập nhật' : text;
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

class _ScheduleNoticeSheet extends StatefulWidget {
  final List<_ScheduleNoticeItem> items;
  final bool initialMode;

  const _ScheduleNoticeSheet({
    required this.items,
    required this.initialMode,
  });

  @override
  State<_ScheduleNoticeSheet> createState() => _ScheduleNoticeSheetState();
}

class _ScheduleNoticeSheetState extends State<_ScheduleNoticeSheet>
    with SingleTickerProviderStateMixin {
  static const Color _warningColor = Color(0xFFB42318);
  static const Color _warningBackground = Color(0xFFFFF1F0);
  static const Color _warningBorder = Color(0xFFFDA29B);

  Timer? _attentionTimer;
  late final ScrollController _scrollController;
  late final AnimationController _guideController;
  late final Animation<double> _guideOpacity;
  late final Animation<Offset> _guideSlide;

  bool _showAttention = false;
  bool _hasReachedEnd = false;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()..addListener(_handleScroll);
    _guideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _guideOpacity = Tween<double>(begin: 0.28, end: 0.82).animate(
      CurvedAnimation(parent: _guideController, curve: Curves.easeInOut),
    );
    _guideSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 0.18),
    ).animate(
      CurvedAnimation(parent: _guideController, curve: Curves.easeInOut),
    );

    _showAttention = widget.initialMode;
    if (_showAttention) {
      debugPrint('[TKB_NOTICE][STATE_3] friendly attention banner start 10s');
      _attentionTimer = Timer(const Duration(seconds: 10), () {
        if (!mounted) return;
        debugPrint('[TKB_NOTICE][STATE_3] friendly attention banner expired');
        setState(() => _showAttention = false);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 1) {
        _markReachedEnd();
      }
    });
  }

  @override
  void dispose() {
    _attentionTimer?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _guideController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_hasReachedEnd || !_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter <= 12) {
      _markReachedEnd();
    }
  }

  void _markReachedEnd() {
    if (!mounted || _hasReachedEnd) return;
    debugPrint('[TKB_NOTICE] user reached end -> close X enabled');
    _guideController.stop();
    setState(() => _hasReachedEnd = true);
  }

  void _closeAfterRead() {
    if (!_hasReachedEnd) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final heightFactor = media.size.height < 650 ? 0.97 : 0.93;

    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: WillPopScope(
        // Phần giải thích chỉ được đóng bằng nút X sau khi đã kéo tới cuối.
        onWillPop: () async => false,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 9),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D5DD),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _warningBackground,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: _warningColor,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initialMode
                                ? 'Thông tin quan trọng về cách xem lịch học'
                                : 'Vì sao ngày và giờ học được hiển thị khác trước?',
                            style: TextStyles.bold.copyWith(
                              fontSize: AppFontSizes.medium,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hãy kéo xuống đọc hết để biết phần nào đã thay đổi so với bản trước, vì sao thay đổi và cách xem lịch học từ bản này.',
                            style: TextStyles.regular.copyWith(
                              fontSize: AppFontSizes.small,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _hasReachedEnd
                            ? IconButton(
                                key: const ValueKey<String>('close-enabled'),
                                tooltip: 'Đóng',
                                onPressed: _closeAfterRead,
                                icon: const Icon(Icons.close_rounded),
                              )
                            : const SizedBox(
                                key: ValueKey<String>('close-hidden'),
                                width: 48,
                                height: 48,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        72,
                        16,
                        max(112.0, media.padding.bottom + 96.0),
                      ),
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _showAttention
                              ? _buildTenSecondAttention()
                              : const SizedBox.shrink(),
                        ),
                        if (_showAttention) const SizedBox(height: 12),
                        _buildWhatChangedCard(),
                        const SizedBox(height: 16),
                        Text(
                          'Vì sao cần thay đổi cách hiển thị?',
                          style: TextStyles.bold.copyWith(
                            fontSize: AppFontSizes.mediumSmall,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Trước đây, một số bạn có thể nhìn ngày hoặc giờ trên ứng dụng và nghĩ đó là lịch chắc chắn. Trong thực tế, lịch giữa các trường, cơ sở, kỳ học và từng loại môn có thể khác nhau. Vì vậy bản này không tự thêm ngày hoặc giờ nếu những thông tin đó chưa được xác nhận cho từng buổi học.',
                          style: TextStyles.regular.copyWith(
                            fontSize: AppFontSizes.small,
                            color: Colors.grey.shade600,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...widget.items.map(_buildDetailItem),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: Color(0xFF15803D),
                                size: 19,
                              ),
                              SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'Bạn vẫn xem được Thứ, số tiết, phòng học và giảng viên. Lịch thi vẫn có ngày và giờ khi nhà trường đã cung cấp. Nếu có thông báo đổi lịch hoặc học bù, hãy ưu tiên thông báo mới nhất của trường hoặc đơn vị tổ chức môn học.',
                                  style: TextStyle(
                                    color: Color(0xFF166534),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.done_all_rounded,
                                color: Color(0xFF475569),
                                size: 19,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bạn đã đọc đến cuối. Nút X ở góc trên sẽ xuất hiện để bạn đóng phần hướng dẫn.',
                                  style: TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!_hasReachedEnd)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 10,
                        child: IgnorePointer(
                          child: Center(
                            child: FadeTransition(
                              opacity: _guideOpacity,
                              child: SlideTransition(
                                position: _guideSlide,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.94),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFD0D5DD),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Kéo xuống để đọc hết',
                                        style: TextStyle(
                                          color: Color(0xFF475467),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 1),
                                      Icon(
                                        Icons.keyboard_double_arrow_down_rounded,
                                        color: Color(0xFF667085),
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildTenSecondAttention() {
    return Container(
      key: const ValueKey<String>('tkb-attention-10s'),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E0),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.priority_high_rounded,
                  color: _warningColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hướng dẫn này chỉ tự mở ở lần đầu bạn vào Lịch học & lịch thi. Trước đây, ngày học hoặc giờ vào tiết do ứng dụng tính thêm có thể khiến sinh viên hiểu nhầm đó là lịch đã được chốt. Hãy kéo xuống đọc hết để biết rõ điều gì đã thay đổi và cách xem lịch mới.',
                    style: TextStyles.semiBold.copyWith(
                      color: const Color(0xFF7A271A),
                      fontSize: AppFontSizes.small,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1, end: 0),
            duration: const Duration(seconds: 10),
            builder: (context, value, _) {
              return LinearProgressIndicator(
                minHeight: 3,
                value: value,
                backgroundColor: _warningBorder.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(_warningColor),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWhatChangedCard() {
    Widget changeRow({
      required IconData icon,
      required String title,
      required String before,
      required String now,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _warningColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: _warningColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF7A271A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bản trước: $before',
                    style: const TextStyle(
                      color: Color(0xFF9A3412),
                      fontSize: 12.3,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bản này: $now',
                    style: const TextStyle(
                      color: Color(0xFF7A271A),
                      fontSize: 12.3,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 1),
      decoration: BoxDecoration(
        color: _warningBackground,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Điều gì khác so với bản trước?',
            style: TextStyles.bold.copyWith(
              color: _warningColor,
              fontSize: AppFontSizes.mediumSmall,
            ),
          ),
          const SizedBox(height: 10),
          changeRow(
            icon: Icons.calendar_month_outlined,
            title: 'Ngày học cụ thể',
            before:
                'có thể thấy ngày như 09/09, 10/09… do ứng dụng ghép từ thứ trong tuần và khoảng thời gian học kỳ.',
            now:
                'lịch học chỉ hiển thị “Thứ 2”, “Thứ 3”… để tránh hiểu nhầm một ngày cụ thể là lịch đã được chốt.',
          ),
          changeRow(
            icon: Icons.schedule_outlined,
            title: 'Giờ vào và giờ ra',
            before:
                'có thể thấy giờ vào/ra do ứng dụng đổi từ số tiết, ví dụ từ “Tiết 4-6” sang một khung giờ cố định.',
            now:
                'không tự đổi số tiết thành giờ đồng hồ; vẫn giữ “Tiết 4-6” để bạn biết ca học.',
          ),
          changeRow(
            icon: Icons.format_list_numbered_rounded,
            title: 'Số tiết',
            before:
                'vẫn có số tiết của môn, đồng thời ứng dụng có thể hiện thêm giờ đồng hồ được tính từ số tiết đó.',
            now:
                'số tiết vẫn được giữ nguyên. Chỉ phần giờ đồng hồ tự tính thêm được bỏ để tránh nhầm giờ vào lớp.',
          ),
          changeRow(
            icon: Icons.home_outlined,
            title: 'Lịch học trên Trang chủ',
            before:
                'mục “Lịch học sắp tới” có thể gắn ngày như 09/09, 10/09… cho môn học.',
            now:
                'hiển thị theo Thứ và số tiết; chạm vào sẽ mở Lịch học & lịch thi để xem đầy đủ.',
          ),
          changeRow(
            icon: Icons.assignment_outlined,
            title: 'Lịch thi',
            before: 'hiển thị ngày và giờ thi khi có thông tin.',
            now:
                'vẫn giữ nguyên ngày và giờ thi khi nhà trường đã cung cấp cụ thể.',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(_ScheduleNoticeItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: _warningColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyles.semiBold.copyWith(
                    fontSize: AppFontSizes.small,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: TextStyles.regular.copyWith(
                    fontSize: AppFontSizes.small,
                    color: Colors.grey.shade600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleNoticeItem {
  final String title;
  final String description;

  const _ScheduleNoticeItem(this.title, this.description);
}
