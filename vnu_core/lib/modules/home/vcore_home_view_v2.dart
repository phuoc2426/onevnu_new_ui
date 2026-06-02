import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/models/tin_tuc_model.dart';
import 'package:vnu_core/models/top_tin_tuc_model.dart';
import 'package:vnu_core/modules/bookmark/views/vcore_bookmark_view.dart';
import 'package:vnu_core/modules/bookmark/views/vcrore_bookmark_item_widget.dart';
import 'package:vnu_core/modules/browser/views/vcore_html_view.dart';
import 'package:vnu_core/modules/home/vcore_home_controller.dart';
import 'package:vnu_core/modules/home/vcore_home_content_tab_widget_v2.dart';
import 'package:vnu_core/modules/home/vcore_home_service_widget_v2.dart';
import 'package:vnu_core/modules/home/vcore_home_source_news_widget.dart';
import 'package:vnu_core/modules/news/views/vcore_news_detail_view.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

/// ─────────────────────────────────────────────────────────
/// CARD STYLE: giống ảnh (gradient + shadow nhẹ + radius lớn)
/// ─────────────────────────────────────────────────────────
class _CardPalette {
  final List<Color> gradient;
  final Color shadow;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color icon;

  const _CardPalette({
    required this.gradient,
    required this.shadow,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.icon,
  });

  static _CardPalette blue() => const _CardPalette(
        gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)], // giống ảnh
        shadow: Color(0x332563EB),
        border: Color(0x1AFFFFFF),
        textPrimary: Colors.white,
        textSecondary: Color(0xD6FFFFFF),
        icon: Colors.white,
      );

  static _CardPalette purple() => const _CardPalette(
        gradient: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        shadow: Color(0x336D28D9),
        border: Color(0x1AFFFFFF),
        textPrimary: Colors.white,
        textSecondary: Color(0xD6FFFFFF),
        icon: Colors.white,
      );

  static _CardPalette green() => const _CardPalette(
        gradient: [Color(0xFF22C55E), Color(0xFF16A34A)],
        shadow: Color(0x3316A34A),
        border: Color(0x1AFFFFFF),
        textPrimary: Colors.white,
        textSecondary: Color(0xD6FFFFFF),
        icon: Colors.white,
      );

  static _CardPalette orange() => const _CardPalette(
        gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
        shadow: Color(0x33D97706),
        border: Color(0x1AFFFFFF),
        textPrimary: Colors.white,
        textSecondary: Color(0xD6FFFFFF),
        icon: Colors.white,
      );

  static _CardPalette teal() => const _CardPalette(
        gradient: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        shadow: Color(0x330891B2),
        border: Color(0x1AFFFFFF),
        textPrimary: Colors.white,
        textSecondary: Color(0xD6FFFFFF),
        icon: Colors.white,
      );
}

class _GradientCard extends StatelessWidget {
  final _CardPalette palette;
  final double radius;
  final EdgeInsets padding;
  final Widget child;
  final double? height;
  final VoidCallback? onTap;

  const _GradientCard({
    required this.palette,
    required this.child,
    this.radius = 18,
    this.padding = const EdgeInsets.all(14),
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.gradient,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.border, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

// ─────────────────────────────────────────────────────────
// WIDGET CHÍNH: News Tab
// ─────────────────────────────────────────────────────────
class VcoreHomeNewsTabWidgetV2 extends StatefulWidget {
  final List<TopTinTucModel> listTinTucVNU;
  final List<TopTinTucModel> listTinTucBySchool;
  final List<TinTucModel> listTinTuc2;
  final Function(TopTinTucModel) onViewDetailVNU;
  final String schoolName;

  const VcoreHomeNewsTabWidgetV2({
    super.key,
    required this.listTinTucVNU,
    required this.listTinTucBySchool,
    required this.listTinTuc2,
    required this.onViewDetailVNU,
    this.schoolName = 'Trường',
  });

  @override
  State<VcoreHomeNewsTabWidgetV2> createState() =>
      _VcoreHomeNewsTabWidgetV2State();
}

class _VcoreHomeNewsTabWidgetV2State extends State<VcoreHomeNewsTabWidgetV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _shortenSchoolName(String name) => name.length > 12 ? 'Trường' : name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tin tức',
                style: TextStyles.semiBold.copyWith(
                  fontSize: AppFontSizes.large,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),

        // pill tab bar
        _RiotTabBar(
          tabs: [
            'Tin ${_shortenSchoolName(widget.schoolName)}',
            'Tin VNU',
          ],
          selectedIndex: _selectedIndex,
          onTabChanged: (i) => _tabController.animateTo(i),
        ),

        const SizedBox(height: 14),

        SizedBox(
          height: 160,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildNewsList(
                listTopTinTuc: widget.listTinTucBySchool,
                listTinTuc2: widget.listTinTuc2,
                isSchoolNews: true,
              ),
              _buildNewsList(
                listTopTinTuc: widget.listTinTucVNU,
                isSchoolNews: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewsList({
    required List<TopTinTucModel> listTopTinTuc,
    List<TinTucModel>? listTinTuc2,
    required bool isSchoolNews,
  }) {
    final bool hasData =
        listTopTinTuc.isNotEmpty || (listTinTuc2?.isNotEmpty ?? false);
    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined,
                size: 32, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 6),
            Text(
              'Chưa có tin tức',
              style: TextStyles.regular.copyWith(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: AppFontSizes.mediumSmall,
              ),
            ),
          ],
        ),
      );
    }

    return _NewsHorizontalListV3(
      listTopTinTuc: listTopTinTuc,
      listTinTuc2: listTinTuc2,
      isSchoolNews: isSchoolNews,
      onViewDetailVNU: widget.onViewDetailVNU,
    );
  }
}

// ─────────────────────────────────────────────────────────
// Riot-style Tab Bar
// ─────────────────────────────────────────────────────────
class _RiotTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const _RiotTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            left: selectedIndex == 0
                ? 3
                : MediaQuery.of(context).size.width / 2 - 16,
            top: 3,
            bottom: 3,
            child: const _SlidingPill(),
          ),
          Row(
            children: List.generate(tabs.length, (i) {
              final bool active = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: active
                        ? TextStyles.semiBold.copyWith(
                            fontSize: AppFontSizes.mediumSmall,
                            color: Colors.white,
                          )
                        : TextStyles.regular.copyWith(
                            fontSize: AppFontSizes.mediumSmall,
                            color: AppColors.textSecondary,
                          ),
                    child: Center(
                      child: Text(
                        tabs[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SlidingPill extends StatelessWidget {
  const _SlidingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 22,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// News Horizontal List
// ─────────────────────────────────────────────────────────
class _NewsHorizontalListV3 extends StatefulWidget {
  final List<TopTinTucModel> listTopTinTuc;
  final List<TinTucModel>? listTinTuc2;
  final bool isSchoolNews;
  final Function(TopTinTucModel) onViewDetailVNU;

  const _NewsHorizontalListV3({
    required this.listTopTinTuc,
    this.listTinTuc2,
    required this.isSchoolNews,
    required this.onViewDetailVNU,
  });

  @override
  State<_NewsHorizontalListV3> createState() => _NewsHorizontalListV3State();
}

class _NewsHorizontalListV3State extends State<_NewsHorizontalListV3> {
  final ScrollController _controller = ScrollController();
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.maxScrollExtent > 0) {
        setState(() {
          _progress =
              (_controller.offset / _controller.position.maxScrollExtent)
                  .clamp(0.0, 1.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool useListTinTuc2 =
        widget.isSchoolNews && (widget.listTinTuc2?.isNotEmpty ?? false);
    final int itemCount = useListTinTuc2
        ? widget.listTinTuc2!.length
        : widget.listTopTinTuc.length;

    return Column(
      children: [
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            controller: _controller,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: itemCount,
            itemBuilder: (ctx, index) {
              if (useListTinTuc2) {
                final TinTucModel tinTuc = widget.listTinTuc2![index];
                final imageUrl =
                    '${ServicesUrl().baseUrlFileDownload}${tinTuc.guidFileAnhDaiDiens?.first}$kParamThumbImage';
                final cacheKey =
                    '${ServicesUrl().baseUrlFileDownload}${tinTuc.guidFileAnhDaiDiens?.first}';
                return _NewsCard(
                  palette: _CardPalette.teal(),
                  imageUrl: imageUrl,
                  cacheKey: cacheKey,
                  title: tinTuc.tieuDe,
                  onTap: () =>
                      Get.to(() => VcoreNewsDetailView(tinTucModel: tinTuc)),
                );
              } else {
                final TopTinTucModel tinTuc = widget.listTopTinTuc[index];
                return _NewsCard(
                  palette: _CardPalette.purple(),
                  imageUrl: tinTuc.anhDaiDien ?? '',
                  cacheKey: tinTuc.anhDaiDien ?? '',
                  title: tinTuc.tieuDe,
                  onTap: () => widget.onViewDetailVNU(tinTuc),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 10),
        _ScrollDot(progress: _progress),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// News Card: đổi sang kiểu gradient giống ảnh, mỗi loại tin 1 màu
// ─────────────────────────────────────────────────────────
class _NewsCard extends StatelessWidget {
  final _CardPalette palette;
  final String imageUrl;
  final String cacheKey;
  final String? title;
  final VoidCallback onTap;

  const _NewsCard({
    required this.palette,
    required this.imageUrl,
    required this.cacheKey,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GradientCard(
      palette: palette,
      radius: 18,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (giữ như cũ)
            SizedBox(
              height: 88,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    cacheKey: cacheKey,
                    fit: BoxFit.cover,
                    httpHeaders: Globals().headerToken(),
                    placeholder: (_, __) => Container(
                      color: Colors.white.withOpacity(0.15),
                      child: const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.white.withOpacity(0.12),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  // Overlay tối nhẹ để title nổi hơn
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title (chữ trắng)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Text(
                  title ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.semiBold.copyWith(
                    fontSize: AppFontSizes.font12_8,
                    color: palette.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Scroll dot indicator (giữ, chỉ chỉnh nhẹ)
/// ─────────────────────────────────────────────────────────
class _ScrollDot extends StatelessWidget {
  final double progress;
  const _ScrollDot({required this.progress});

  @override
  Widget build(BuildContext context) {
    const trackWidth = 32.0;
    const dotWidth = 12.0;
    final dotOffset = progress * (trackWidth - dotWidth);

    return SizedBox(
      height: 6,
      width: trackWidth,
      child: Stack(
        children: [
          Container(
            height: 5,
            width: trackWidth,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 80),
            left: dotOffset,
            top: 0,
            child: Container(
              height: 5,
              width: dotWidth,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TRANG CHỦ V2 - Main View
// ─────────────────────────────────────────────────────────
const kCacheKeyListTinTucBySchoolV2 = 'listTinTucBySchool.json';

class VcoreHomeViewV2 extends GetView<VcoreHomeController> {
  const VcoreHomeViewV2({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreHomeController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        controller.getLienKetDanhDau();
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              child: Obx(
                () => Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _boxUserProfile(controller),
                      ),
                    ),
                    spaceHeight(12),
                    _buildRightInfoPanel(controller),
                    spaceHeight(16),
                    _hasNewsOrNotify(controller)
                        ? _boxContentTabsV2(controller)
                        : const SizedBox.shrink(),
                    spaceHeight(_hasNewsOrNotify(controller) ? 20 : 0),
                    controller.listLienKetDanhDau.isNotEmpty
                        ? _boxBookmark(controller.listLienKetDanhDau)
                        : const SizedBox.shrink(),
                    spaceHeight(
                        controller.listLienKetDanhDau.isNotEmpty ? 20 : 0),
                    controller.listNguonTin.isNotEmpty
                        ? _boxSourceNewsVNU(controller.listNguonTin)
                        : const SizedBox.shrink(),
                    SizedBox(
                      height: floatingNavBottomPadding(context),
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

  bool _hasNews(VcoreHomeController controller) {
    return controller.listTinTuc.isNotEmpty ||
        controller.listTinTucBySchool.isNotEmpty;
  }

  bool _hasNotify(VcoreHomeController controller) {
    return controller.listThongBaoDaoTao.isNotEmpty ||
        controller.listTop10ThongBao.isNotEmpty;
  }

  bool _hasNewsOrNotify(VcoreHomeController controller) {
    return _hasNews(controller) || _hasNotify(controller);
  }

  /// USER PROFILE CARD: đổi sang gradient kiểu ảnh (màu xanh)
  Widget _boxUserProfile(VcoreHomeController controller) {
    final palette = _CardPalette.blue();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: _GradientCard(
        palette: palette,
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final rankImage = controller.getRankImageAsset();
          final credits =
              controller.tongKetModel.value?.tongSoTinChiTichLuy ?? '';
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Globals().thongTinSinhVienModel.value?.hoVaTen ?? '',
                      style: TextStyles.bold.copyWith(
                        fontSize: AppFontSizes.large,
                        color: palette.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    spaceHeight(4),
                    _profileInfoRow(
                        palette,
                        'MSV',
                        Globals().thongTinSinhVienModel.value?.maSinhVien ??
                            ''),
                    spaceHeight(2),
                    _profileInfoRow(palette, 'Lớp',
                        Globals().lopDaoTaoModel.value?.ten ?? ''),
                    if (credits.isNotEmpty) ...[
                      spaceHeight(2),
                      _profileInfoRow(palette, 'Tín chỉ', credits),
                    ],
                  ],
                ),
              ),
              spaceWidth(12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  rankImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 0.8),
                    ),
                    child:
                        const Icon(Icons.star, size: 28, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _profileInfoRow(_CardPalette p, String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyles.regular.copyWith(
            color: p.textSecondary,
            fontSize: AppFontSizes.small,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyles.semiBold.copyWith(
              color: p.textPrimary,
              fontSize: AppFontSizes.small,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRightInfoPanel(VcoreHomeController controller) {
    return _HomeScheduleCards(controller: controller);
  }

  /// Tin tức + Thông báo V2
  Widget _boxContentTabsV2(VcoreHomeController controller) {
    return FutureBuilder<String>(
      future: _getSchoolNameFromCache(),
      builder: (context, snapshot) {
        String schoolName = snapshot.data ?? 'Trường';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _header('Tin tức & Thông báo', null),
              spaceHeight(12),
              VcoreHomeContentTabWidgetV2(
                listTinTucVNU: controller.listTinTuc,
                listTinTucBySchool: controller.listTinTucBySchool,
                listTinTuc2: controller.listTinTuc2,
                onViewDetailNewsVNU: (tinTuc) {
                  controller.viewDetailTopTinTucModel(tinTuc);
                },
                schoolName: schoolName,
                listThongBaoDaoTao: controller.listThongBaoDaoTao,
                listThongBaoVNU: controller.listTop10ThongBao.length > 5
                    ? controller.listTop10ThongBao.sublist(0, 5)
                    : controller.listTop10ThongBao,
                onViewDetailDaoTao: (thongbao) {
                  Get.to(
                    VcoreHtmlView(
                      title: 'Thông báo Đào tạo',
                      html: thongbao.noiDung ?? '',
                    ),
                  );
                },
                onViewDetailThongBaoVNU: (thongbao) {
                  controller.viewDetailTopThongBaoModel(thongbao);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _boxBookmark(List<LienKetDanhDauModel> listLienKetDanhDau) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header('Liên kết đánh dấu', () {
            Get.to(() => const VcoreBookmarkView());
          }),
          spaceHeight(12),
          ListView.separated(
            separatorBuilder: (context, index) => spaceHeight(12),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: listLienKetDanhDau.length,
            itemBuilder: (ctx, index) {
              return VcoreBookmarkItemWidget(
                lienKetDanhDauModel: listLienKetDanhDau[index],
                onEdit: () {},
                onDelete: () {},
                isShowMore: false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _boxSourceNewsVNU(List<NguonTinModel> listNguonTin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header('Nguồn tin VNU', null),
          spaceHeight(12),
          VcoreHomeSourceNewsWidget(listNguonTin: listNguonTin),
        ],
      ),
    );
  }

  Widget _header(String title, VoidCallback? action) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyles.bold.copyWith(
                fontSize: AppFontSizes.mediumLarge,
                color: AppColors.textTitle,
              ),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          action != null
              ? GestureDetector(
                  onTap: action,
                  child: Text(
                    'Xem thêm',
                    style: TextStyles.regular.copyWith(
                      fontSize: AppFontSizes.small,
                      color: AppColors.secondary,
                    ),
                  ),
                )
              : const SizedBox(),
        ],
      ),
    );
  }

  Future<String> _getSchoolNameFromCache() async {
    try {
      String? cachedData = await VnuCacheFileManager()
          .getCacheFile(kCacheKeyListTinTucBySchoolV2);
      if (cachedData != null && cachedData.isNotEmpty) {
        var jsonData = jsonDecode(cachedData);
        return jsonData["guild"] ?? "Trường";
      }
    } catch (e) {
      debugPrint("Lỗi khi lấy dữ liệu cache: ${e.toString()}");
    }
    return "Trường";
  }
}

// ─────────────────────────────────────────────────────────
// Schedule Cards: Lịch học & Lịch thi
// -> đổi hẳn sang gradient kiểu ảnh + 2 màu khác nhau
// ─────────────────────────────────────────────────────────
class _HomeScheduleCards extends StatefulWidget {
  final VcoreHomeController controller;
  const _HomeScheduleCards({required this.controller});

  @override
  State<_HomeScheduleCards> createState() => _HomeScheduleCardsState();
}

class _HomeScheduleCardsState extends State<_HomeScheduleCards> {
  final PageController _classPageController = PageController();
  int _classPage = 0;

  @override
  void dispose() {
    _classPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return Obx(() {
      final _ = ctrl.isLoadingSchedule.value;
      final __ = ctrl.listThoiKhoaBieu.length;
      final ___ = ctrl.listLichThi.length;

      if (ctrl.isLoadingSchedule.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        );
      }

      final todayClass = ctrl.getTodayClassSchedule();
      final todayExam = ctrl.getTodayExamSchedule();
      final nextDayClass = ctrl.getNextDayClassSchedule();
      final nextDayExam = ctrl.getNextDayExamSchedule();
      final upcomingExams = ctrl.getUpcomingExams();

      // mỗi card 1 màu
      final classPalette = _CardPalette.blue();
      final examPalette = _CardPalette.purple();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _GradientCard(
                palette: classPalette,
                height: 120,
                onTap: () {
                  final isToday = _classPage == 0;
                  _showScheduleBottomSheet(
                    context,
                    isToday ? 'Hôm nay' : 'Ngày mai',
                    isToday ? todayClass : nextDayClass,
                    isToday ? todayExam : nextDayExam,
                  );
                },
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_rounded,
                            size: 16, color: classPalette.icon),
                        spaceWidth(6),
                        Text(
                          'Lịch học',
                          style: TextStyles.bold.copyWith(
                            fontSize: AppFontSizes.mediumSmall,
                            color: classPalette.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        _buildDots(2, _classPage, classPalette.textPrimary),
                      ],
                    ),
                    spaceHeight(6),
                    Expanded(
                      child: PageView(
                        controller: _classPageController,
                        onPageChanged: (i) => setState(() => _classPage = i),
                        children: [
                          _classContent(classPalette, 'Hôm nay', todayClass),
                          _classContent(classPalette, 'Ngày mai', nextDayClass),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            spaceWidth(10),
            Expanded(
              child: _GradientCard(
                palette: examPalette,
                height: 120,
                onTap: () => _showScheduleBottomSheet(
                    context, 'Lịch thi sắp tới', const [], upcomingExams),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 16, color: examPalette.icon),
                        spaceWidth(6),
                        Text(
                          'Lịch thi',
                          style: TextStyles.bold.copyWith(
                            fontSize: AppFontSizes.mediumSmall,
                            color: examPalette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    spaceHeight(6),
                    Expanded(child: _examContent(examPalette, upcomingExams)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _classContent(
      _CardPalette p, String label, List<ThoiKhoaBieuModel> classList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.medium.copyWith(
            fontSize: AppFontSizes.font11,
            color: p.textSecondary,
          ),
        ),
        spaceHeight(4),
        if (classList.isNotEmpty) ...[
          Text(
            classList.first.tenHocPhan ?? '',
            style: TextStyles.semiBold.copyWith(
              fontSize: AppFontSizes.font12_5,
              color: p.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          spaceHeight(2),
          Text(
            'Tiết ${classList.first.tietBatDau ?? ''}-${classList.first.tietKetThuc ?? ''} | ${classList.first.tenPhong ?? ''}',
            style: TextStyles.regular.copyWith(
              fontSize: AppFontSizes.font10_5,
              color: p.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '${classList.length} môn',
            style: TextStyles.bold.copyWith(
              fontSize: AppFontSizes.font11,
              color: p.textPrimary,
            ),
          ),
        ] else
          Expanded(
            child: Center(
              child: Text(
                'Không có lịch',
                style: TextStyles.regular.copyWith(
                  fontSize: AppFontSizes.font11,
                  color: p.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _examContent(_CardPalette p, List<LichThiHocKyModel> exams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (exams.isNotEmpty) ...[
          Text(
            exams.first.tenHocPhan ?? '',
            style: TextStyles.semiBold.copyWith(
              fontSize: AppFontSizes.font12_5,
              color: p.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          spaceHeight(2),
          Text(
            '${exams.first.ngayThi ?? ''} | ${exams.first.gioBatDauThi ?? ''}',
            style: TextStyles.regular.copyWith(
              fontSize: AppFontSizes.font10_5,
              color: p.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          spaceHeight(2),
          Text(
            exams.first.phongThi ?? '',
            style: TextStyles.regular.copyWith(
              fontSize: AppFontSizes.font10_5,
              color: p.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '${exams.length} môn sắp thi',
            style: TextStyles.bold.copyWith(
              fontSize: AppFontSizes.font11,
              color: p.textPrimary,
            ),
          ),
        ] else
          Expanded(
            child: Center(
              child: Text(
                'Không có lịch thi',
                style: TextStyles.regular.copyWith(
                  fontSize: AppFontSizes.font11,
                  color: p.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDots(int total, int current, Color activeColor) {
    return Row(
      children: List.generate(total, (i) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: current == i ? activeColor : activeColor.withOpacity(0.25),
          ),
        );
      }),
    );
  }

  void _showScheduleBottomSheet(
    BuildContext context,
    String dayLabel,
    List<ThoiKhoaBieuModel> classList,
    List<LichThiHocKyModel> examList,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _DayScheduleDetailSheet(
          dayLabel: dayLabel,
          classList: classList,
          examList: examList,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Day Schedule Detail Bottom Sheet (giữ logic, polish nhẹ)
/// ─────────────────────────────────────────────────────────
class _DayScheduleDetailSheet extends StatelessWidget {
  final String dayLabel;
  final List<ThoiKhoaBieuModel> classList;
  final List<LichThiHocKyModel> examList;

  const _DayScheduleDetailSheet({
    required this.dayLabel,
    required this.classList,
    required this.examList,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = classList.length + examList.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 20, color: AppColors.primary),
                spaceWidth(8),
                Text(
                  'Lịch $dayLabel',
                  style: TextStyles.bold.copyWith(
                    fontSize: AppFontSizes.extraLarge,
                    color: AppColors.textTitle,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalCount môn',
                    style: TextStyles.medium.copyWith(
                      fontSize: AppFontSizes.small,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: totalCount == 0
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available,
                              size: 48, color: Colors.grey[300]),
                          spaceHeight(12),
                          Text(
                            'Không có lịch $dayLabel',
                            style: TextStyles.regular.copyWith(
                              fontSize: AppFontSizes.medium,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    shrinkWrap: true,
                    children: [
                      if (examList.isNotEmpty) ...[
                        _sectionTitle('Lịch thi', Icons.assignment,
                            AppColors.examCardText),
                        ...examList.map((exam) => _examCard(exam)),
                        spaceHeight(12),
                      ],
                      if (classList.isNotEmpty) ...[
                        _sectionTitle(
                            'Lịch học', Icons.menu_book, AppColors.primary),
                        ...classList.map((cls) => _classCard(cls)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          spaceWidth(6),
          Text(
            title,
            style: TextStyles.bold.copyWith(
              fontSize: AppFontSizes.medium,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _examCard(LichThiHocKyModel exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.examCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.examCardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exam.tenHocPhan ?? '',
            style: TextStyles.medium.copyWith(
              fontSize: AppFontSizes.mediumSmall,
              color: AppColors.textTitle,
            ),
          ),
          spaceHeight(4),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 12, color: AppColors.examCardText),
              spaceWidth(4),
              Text(
                '${exam.ngayThi ?? ''} | ${exam.gioBatDauThi ?? ''} | ${exam.thoiLuong ?? ''} phút',
                style: TextStyles.regular.copyWith(
                  fontSize: AppFontSizes.font11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          spaceHeight(2),
          Row(
            children: [
              const Icon(Icons.room, size: 12, color: AppColors.examCardText),
              spaceWidth(4),
              Flexible(
                child: Text(
                  '${exam.phongThi ?? ''} - ${exam.diaChi ?? ''}',
                  style: TextStyles.regular.copyWith(
                    fontSize: AppFontSizes.font11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (exam.hinhThucThi != null && exam.hinhThucThi!.isNotEmpty) ...[
            spaceHeight(2),
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 12, color: AppColors.examCardText),
                spaceWidth(4),
                Text(
                  exam.hinhThucThi!,
                  style: TextStyles.regular.copyWith(
                    fontSize: AppFontSizes.font11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _classCard(ThoiKhoaBieuModel cls) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.classCardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cls.tenHocPhan ?? '',
            style: TextStyles.medium.copyWith(
              fontSize: AppFontSizes.mediumSmall,
              color: AppColors.textTitle,
            ),
          ),
          spaceHeight(4),
          Row(
            children: [
              const Icon(Icons.schedule, size: 12, color: AppColors.primary),
              spaceWidth(4),
              Text(
                'Tiết ${cls.tietBatDau ?? ''} - ${cls.tietKetThuc ?? ''}',
                style: TextStyles.regular.copyWith(
                  fontSize: AppFontSizes.font11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          spaceHeight(2),
          Row(
            children: [
              const Icon(Icons.room, size: 12, color: AppColors.primary),
              spaceWidth(4),
              Flexible(
                child: Text(
                  '${cls.tenPhong ?? ''} - ${cls.diaChi ?? ''}',
                  style: TextStyles.regular.copyWith(
                    fontSize: AppFontSizes.font11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (cls.giangVien1 != null && cls.giangVien1!.isNotEmpty) ...[
            spaceHeight(2),
            Row(
              children: [
                const Icon(Icons.person, size: 12, color: AppColors.primary),
                spaceWidth(4),
                Flexible(
                  child: Text(
                    cls.giangVien1!,
                    style: TextStyles.regular.copyWith(
                      fontSize: AppFontSizes.font11,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
