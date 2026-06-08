import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
// import 'package:vnu_core/modules/admission/widgets/cinematic_3d_book_widget.dart';
import 'package:vnu_core/modules/browser/views/vcore_browser_view.dart';
import 'package:vnu_core/modules/cam_nang/views/vcore_cam_nang_view.dart';
import 'package:vnu_core/modules/inmapz/vcore_immap_view.dart';
import 'package:vnu_core/modules/motel/views/vcore_motel_view.dart';
import 'package:vnu_core/modules/tabbar/views/vcore_tabbar_view.dart';
import 'package:vnu_core/screens/vcore_splash_screen.dart';
import 'package:vnu_core/screens/vcore_login_screen_v3.dart';

class VcoreAdmissionView extends StatefulWidget {
  const VcoreAdmissionView({super.key});

  @override
  State<VcoreAdmissionView> createState() => _VcoreAdmissionViewState();
}

class _VcoreAdmissionViewState extends State<VcoreAdmissionView> {
  static const Color primaryGreen = Color(0xFF006B36);
  static const Color lightGreen = Color(0xFFEFF9F1);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color pageBg = Color(0xFFF6F7FB);

  static const String _defaultMobileApiBase =
      'https://onevnu-mobile-api.vnu.edu.vn';

  static const String _tinTucPath = '/api/cmsvnu/tin-tuc';
  static const String _viecLamPath = '/api/cmsvnu/viec-lam';

  static const String _allNewsUrl = 'https://www.vnu.edu.vn';
  static const String _allJobsUrl = 'https://www.vnu.edu.vn';

  final ScrollController _scrollController = ScrollController();

  List<_CmsVnuItem> _listTinTucVNU = [];
  List<_CmsVnuItem> _listJobs = [];

  bool _isLoadingTinTucVNU = true;
  bool _isLoadingJobs = true;

  @override
  void initState() {
    super.initState();
    _loadTinTucVNU();
    _loadJobs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _getMobileApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString('domain');

    if (domain == null || domain.trim().isEmpty) {
      return _defaultMobileApiBase;
    }

    return domain.trim();
  }

  Future<List<_CmsVnuItem>> _getCmsPublicItems(
      String path, {
        Map<String, dynamic>? queryParameters,
      }) async {
    final baseUrl = await _getMobileApiBaseUrl();

    final response = await Dio().get(
      '$baseUrl$path',
      queryParameters: queryParameters,
    );

    final raw = response.data;

    List<dynamic> items = [];

    if (raw is List) {
      items = raw;
    } else if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['content'] ?? raw['items'];
      if (data is List) {
        items = data;
      }
    }

    return items
        .whereType<Map>()
        .map((e) => _CmsVnuItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _loadTinTucVNU() async {
    try {
      final data = await _getCmsPublicItems(
        _tinTucPath,
        queryParameters: {'limit': 20},
      );

      if (!mounted) return;

      setState(() {
        _listTinTucVNU = data;
        _isLoadingTinTucVNU = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingTinTucVNU = false;
      });
    }
  }

  Future<void> _loadJobs() async {
    try {
      final data = await _getCmsPublicItems(
        _viecLamPath,
        queryParameters: {
          'pageIndex': 1,
          'pageSize': 20,
        },
      );

      if (!mounted) return;

      setState(() {
        _listJobs = data;
        _isLoadingJobs = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingJobs = false;
      });
    }
  }

  void _goToLogin() {
    Get.to(() => const VCoreLoginScreenV3());
  }

  void _openWebUrl(String title, String url) {
    Get.to(
          () => VcoreBrowserView(
        title: title,
        url: url,
      ),
    );
  }

  void _openAdmissionUnit(_AdmissionUnit item) {
    _openWebUrl(item.fullName, item.url);
  }

  void _openCmsItem(_CmsVnuItem item, String fallbackTitle) {
    final url = item.openUrl;

    if (url.isEmpty) return;

    _openWebUrl(
      item.tieuDe.isNotEmpty ? item.tieuDe : fallbackTitle,
      url,
    );
  }

  void _scrollToAdmissionUnits() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      330,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
    );
  }

  String _resolveImageUrl(_CmsVnuItem item) {
    final image = item.imageUrl;

    if (image.isEmpty) return '';
    if (image.startsWith('http')) return image;

    return '$_defaultMobileApiBase$image';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(child: _buildAdmissionUnits()),
            SliverToBoxAdapter(child: _buildUtilities()),
            SliverToBoxAdapter(child: _buildTinTucVNUSection()),
            SliverToBoxAdapter(child: _buildJobsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      height: 252,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/admission_bg.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              lightGreen.withOpacity(0.96),
              lightGreen.withOpacity(0.70),
              lightGreen.withOpacity(0.06),
            ],
            stops: const [0.0, 0.44, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 265,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tuyển sinh VNU',
                    style: TextStyles.bold.copyWith(
                      fontSize: 22,
                      height: 1.12,
                      color: primaryGreen,
                    ),
                  ),
                  spaceHeight(6),
                  Text(
                    'Đại học & Sau đại học',
                    style: TextStyles.bold.copyWith(
                      fontSize: 12,
                      height: 1.2,
                      color: primaryGreen,
                    ),
                  ),
                  spaceHeight(12),
                  Text(
                    'Khám phá thông tin tuyển sinh, tin tức và tiện ích dành cho tân sinh viên.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.regular.copyWith(
                      fontSize: 12,
                      height: 1.42,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  spaceHeight(8),
                  InkWell(
                    onTap: _scrollToAdmissionUnits,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        'Xem các đơn vị tuyển sinh  ›',
                        style: TextStyles.semiBold.copyWith(
                          color: primaryGreen,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  spaceHeight(10),
                  InkWell(
                    onTap: _goToLogin,
                    borderRadius: BorderRadius.circular(26),
                    child: Container(
                      width: 180,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withOpacity(0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        'Đăng nhập hệ thống',
                        style: TextStyles.semiBold.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  Widget _buildAdmissionUnits() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Column(
        children: [
          const _SectionTitle(
            title: 'Đơn vị tuyển sinh',
            actionText: 'Xem tất cả',
          ),
          spaceHeight(12),
          SizedBox(
            height: 112,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _admissionUnits.length,
              separatorBuilder: (_, __) => spaceWidth(8),
              itemBuilder: (context, index) {
                final item = _admissionUnits[index];

                return _AdmissionUnitCard(
                  item: item,
                  onTap: () => _openAdmissionUnit(item),
                );
              },
            ),
          ),
          spaceHeight(8),
          Container(
            width: 100,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilities() {
    final utilities = [
      _UtilityItem(
        title: 'Cẩm nang tân sinh viên',
        description: 'Hành trang vững vàng cho hành trình đại học',
        image: 'assets/images/state_0_manual.png',
        // onTap: (){},
        onTap: () => Get.to(() => const VcoreCamNangView()),
        showBook: true,
      ),
      _UtilityItem(
        title: 'Tin tức VNU',
        description: 'Cập nhật nhanh chóng tin tức & sự kiện mới nhất',
        image: 'assets/images/state_0_news.png',
        onTap: () => _openWebUrl('Tin tức VNU', _allNewsUrl),
      ),
      _UtilityItem(
        title: 'Nhà trọ',
        description: 'Tìm kiếm nhà trọ an toàn, tiện lợi',
        image: 'assets/images/state_0_dormitory.png',
        onTap: () => Get.to(() => const VcoreMotelView()),
      ),
      _UtilityItem(
        title: 'Bản đồ số',
        description: 'Khám phá bản đồ số các cơ sở VNU',
        image: 'assets/images/state_0_map.png',
        onTap: () => Get.to(() => const VcoreImmapView()),
      ),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Column(
        children: [
          const _SectionTitle(title: 'Tiện ích nổi bật'),
          spaceHeight(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = 10.0;
                final itemWidth = (constraints.maxWidth - gap) / 2;
                final itemHeight = itemWidth / 1.16;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: utilities.map((item) {
                    return SizedBox(
                      width: itemWidth,
                      height: itemHeight,
                      child: _UtilityCard(item: item),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTinTucVNUSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Column(
        children: [
          _SectionTitle(
            title: 'Tin tức VNU',
            actionText: 'Xem tất cả',
            onTapAction: () => _openWebUrl('Tin tức VNU', _allNewsUrl),
          ),
          spaceHeight(12),
          if (_isLoadingTinTucVNU)
            const _LoadingHorizontalSection()
          else if (_listTinTucVNU.isEmpty)
            const _EmptyHorizontalSection(text: 'Chưa có tin tức VNU')
          else
            SizedBox(
              height: 172,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _listTinTucVNU.length,
                separatorBuilder: (_, __) => spaceWidth(10),
                itemBuilder: (context, index) {
                  final item = _listTinTucVNU[index];

                  return _AdmissionNewsCard(
                    tag: 'VNU',
                    imageUrl: _resolveImageUrl(item),
                    title: item.tieuDe,
                    description: item.description,
                    onTap: () => _openCmsItem(item, 'Tin tức VNU'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJobsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Column(
        children: [
          _SectionTitle(
            title: 'Cơ hội việc làm',
            actionText: 'Xem tất cả',
            onTapAction: () => _openWebUrl('Cơ hội việc làm', _allJobsUrl),
          ),
          spaceHeight(12),
          if (_isLoadingJobs)
            const _LoadingHorizontalSection()
          else if (_listJobs.isEmpty)
            const _EmptyHorizontalSection(text: 'Chưa có tin tuyển dụng')
          else
            SizedBox(
              height: 172,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _listJobs.length,
                separatorBuilder: (_, __) => spaceWidth(10),
                itemBuilder: (context, index) {
                  final item = _listJobs[index];

                  return _AdmissionNewsCard(
                    tag: 'VIỆC LÀM',
                    imageUrl: _resolveImageUrl(item),
                    title: item.tieuDe,
                    description: item.description,
                    onTap: () => _openCmsItem(item, 'Cơ hội việc làm'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  static final List<_AdmissionUnit> _admissionUnits = [
    _AdmissionUnit(
      shortName: 'HUS',
      name: 'Khoa học\nTự nhiên',
      fullName: 'Trường Đại học Khoa học Tự nhiên',
      url: 'https://tuyensinh.hus.vnu.edu.vn/',
      logoUrl:
      'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/logo-hus-final-01-1.png?w=1920&dpi=72',
    ),
    _AdmissionUnit(
      shortName: 'USSH',
      name: 'KHXH &\nNhân văn',
      fullName: 'Trường Đại học Khoa học Xã hội & Nhân văn',
      url: 'https://tuyensinh.ussh.edu.vn/',
      logoUrl:
      'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/vnu-ussh-1-s.png?w=1920&dpi=72',
    ),
    _AdmissionUnit(
      shortName: 'ULIS',
      name: 'Đại học\nNgoại ngữ',
      fullName: 'Trường Đại học Ngoại ngữ',
      url: 'https://ulis.vnu.edu.vn/tuyensinh2026/',
      logoUrl:
      'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/vnu-ulis.png?w=1920&dpi=72',
    ),
    _AdmissionUnit(
      shortName: 'UET',
      name: 'Đại học\nCông nghệ',
      fullName: 'Trường Đại học Công nghệ',
      url: 'https://uet.vnu.edu.vn/category/tuyen-sinh/',
      logoUrl:
      'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/vnu-uet.png?w=1920&dpi=72',
    ),
    _AdmissionUnit(
      shortName: 'UEB',
      name: 'Đại học\nKinh tế',
      fullName: 'Trường Đại học Kinh tế',
      url: 'https://ueb.vnu.edu.vn/Tuyen-Sinh',
      logoUrl:
      'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/truong-dh-kinh-te.png?w=1920&dpi=72',
    ),
    _AdmissionUnit(
      shortName: 'UEd',
      name: 'Đại học\nGiáo dục',
      fullName: 'Trường Đại học Giáo dục',
      url: 'https://education.vnu.edu.vn/',
      logoUrl:
      'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/logo-vnu-ued-1.png?w=1920&dpi=72',
    ),
    _AdmissionUnit(
      shortName: 'VJU',
      name: 'Đại học\nViệt - Nhật',
      fullName: 'Trường Đại học Việt - Nhật',
      url: 'https://vju.ac.vn/tuyensinhdaihoc/thong-tin-tuyen-sinh-2026/',
      logoUrl:
      'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/1200px-logo-vju-svg.png?w=1920&dpi=72',
    ),
    _AdmissionUnit(
      shortName: 'UMP',
      name: 'Đại học\nY Dược',
      fullName: 'Trường Đại học Y Dược',
      url: 'https://ump.vnu.edu.vn/index.html',
      logoUrl:
      'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/vnu-ump-1.png?w=1920&dpi=72',
    ),
    _AdmissionUnit(
      shortName: 'UL',
      name: 'Đại học\nLuật',
      fullName: 'Trường Đại học Luật',
      url: 'https://law.vnu.edu.vn/tuyen-sinh/',
      logoUrl:
      'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/vnu-ul-1.png?w=1920&dpi=72',
    ),
    _AdmissionUnit(
      shortName: 'HSB',
      name: 'Quản trị &\nKinh doanh',
      fullName: 'Trường Quản trị và Kinh doanh',
      url: 'https://www.hsb.edu.vn/admissions',
      logoUrl:
      'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/z3820263481061-a5913e95067524e958b051f5ac42e874.jpg?w=1920&dpi=72',
    ),
    _AdmissionUnit(
      shortName: 'IS',
      name: 'Trường\nQuốc tế',
      fullName: 'Trường Quốc tế',
      url:
      'https://www.is.vnu.edu.vn/chuyen-trang-tuyen-sinh-dai-hoc-nam-2026/',
      logoUrl:
      'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/vnu-is.png?w=1920&dpi=72',
    ),
    _AdmissionUnit(
      shortName: 'SIS',
      name: 'Liên ngành &\nNghệ thuật',
      fullName: 'Trường Khoa học liên ngành và Nghệ thuật',
      url:
      'https://sis.vnu.edu.vn/Tuyen-sinh-bac-Dai-hoc/danh-sach-tin-tuc_146.html',
      logoUrl:
      'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/logo-vnu-sis-2024.png?w=1920&dpi=72',
    ),
  ];
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onTapAction;

  const _SectionTitle({
    required this.title,
    this.actionText,
    this.onTapAction,
  });

  @override
  Widget build(BuildContext context) {
    final action = actionText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyles.bold.copyWith(
                fontSize: 17,
                color: _VcoreAdmissionViewState.textDark,
              ),
            ),
          ),
          if (action != null)
            InkWell(
              onTap: onTapAction,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                child: Text(
                  '$action  ›',
                  style: TextStyles.semiBold.copyWith(
                    fontSize: 11,
                    color: _VcoreAdmissionViewState.primaryGreen,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdmissionUnitCard extends StatelessWidget {
  final _AdmissionUnit item;
  final VoidCallback onTap;

  const _AdmissionUnitCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 82,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _VcoreAdmissionViewState.borderColor),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: item.logoUrl,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              placeholder: (_, __) => Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              errorWidget: (_, __, ___) => _LogoFallback(text: item.shortName),
            ),
            spaceHeight(6),
            Text(
              item.shortName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.bold.copyWith(
                fontSize: 12,
                color: _VcoreAdmissionViewState.textDark,
              ),
            ),
            spaceHeight(3),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.regular.copyWith(
                fontSize: 9,
                height: 1.22,
                color: const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UtilityCard extends StatefulWidget {
  final _UtilityItem item;

  const _UtilityCard({
    required this.item,
  });

  @override
  State<_UtilityCard> createState() => _UtilityCardState();
}

class _UtilityCardState extends State<_UtilityCard> {
  // final GlobalKey<CinematicBookState> _bookKey =
  // GlobalKey<CinematicBookState>();

  void _handleTap() {
    // if (widget.item.showBook) {
    //   _bookKey.currentState?.openBook();
    //   return;
    // }

    widget.item.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isBookCard = item.showBook;

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDEBDD)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
          image: DecorationImage(
            image: AssetImage(item.image),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.02),
                      Colors.black.withOpacity(isBookCard ? 0.42 : 0.56),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // if (isBookCard)
            //   Positioned(
            //     top: 12,
            //     left: 0,
            //     right: 0,
            //     bottom: 22,
            //     child: Center(
            //       child: SizedBox(
            //         width: 64,
            //         height: 82,
            //         child: FittedBox(
            //           fit: BoxFit.contain,
            //           child: CinematicBook(
            //             key: _bookKey,
            //             scale: 0.24,
            //             coverAsset: 'assets/images/cover.png',
            //             spineAsset: 'assets/images/spine.png',
            //             pages: const [
            //               BookPage(
            //                 title: 'Cẩm nang tân sinh viên',
            //                 content: 'Chào mừng bạn đến với Đại học Quốc gia Hà Nội. '
            //                     'Cuốn cẩm nang này tổng hợp những thông tin quan trọng giúp tân sinh viên làm quen với môi trường học tập, sinh hoạt và các dịch vụ hỗ trợ trong trường.',
            //               ),
            //               BookPage(
            //                 title: 'Hành trang nhập học',
            //                 content: 'Sinh viên cần theo dõi thông báo chính thức của đơn vị đào tạo, chuẩn bị hồ sơ nhập học, tài khoản hệ thống, lịch học, lịch sinh hoạt công dân và các kênh liên hệ cần thiết.',
            //               ),
            //               BookPage(
            //                 title: 'Tiện ích dành cho sinh viên',
            //                 content: 'Bạn có thể sử dụng các tiện ích như bản đồ số, thông tin nhà trọ, tin tức VNU, cơ hội việc làm và các dịch vụ hỗ trợ học tập để bắt đầu hành trình đại học thuận lợi hơn.',
            //               ),
            //             ],
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),

            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Padding(
                padding: const EdgeInsets.only(right: 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.bold.copyWith(
                        fontSize: isBookCard ? 13 : 12,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    spaceHeight(3),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.regular.copyWith(
                        fontSize: 9,
                        height: 1.25,
                        color: Colors.white.withOpacity(0.92),
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              right: 10,
              bottom: 10,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _handleTap,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.16),
                        blurRadius: 7,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: _VcoreAdmissionViewState.primaryGreen,
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

class _AdmissionNewsCard extends StatelessWidget {
  final String tag;
  final String imageUrl;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AdmissionNewsCard({
    required this.tag,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 204,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _VcoreAdmissionViewState.borderColor),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 86,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: hasImage
                        ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildImageFallback(),
                      errorWidget: (_, __, ___) => _buildImageFallback(),
                    )
                        : _buildImageFallback(),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.02),
                            Colors.black.withOpacity(0.34),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _VcoreAdmissionViewState.primaryGreen,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        tag,
                        style: TextStyles.bold.copyWith(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.semiBold.copyWith(
                        fontSize: 11,
                        height: 1.25,
                        color: _VcoreAdmissionViewState.textDark,
                      ),
                    ),
                    spaceHeight(5),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.regular.copyWith(
                        fontSize: 9,
                        height: 1.25,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFEAF7EF),
            Color(0xFFD6EBDD),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.article_outlined,
          color: _VcoreAdmissionViewState.primaryGreen,
          size: 28,
        ),
      ),
    );
  }
}

class _LoadingHorizontalSection extends StatelessWidget {
  const _LoadingHorizontalSection();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 100,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }
}

class _EmptyHorizontalSection extends StatelessWidget {
  final String text;

  const _EmptyHorizontalSection({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyles.regular.copyWith(
              fontSize: 11,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  final String text;

  const _LogoFallback({required this.text});

  @override
  Widget build(BuildContext context) {
    final fallbackText = text.isNotEmpty ? text.substring(0, 1) : 'V';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7E3F0)),
      ),
      alignment: Alignment.center,
      child: Text(
        fallbackText,
        style: TextStyles.bold.copyWith(
          color: _VcoreAdmissionViewState.primaryGreen,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _AdmissionUnit {
  final String shortName;
  final String name;
  final String fullName;
  final String url;
  final String logoUrl;

  const _AdmissionUnit({
    required this.shortName,
    required this.name,
    required this.fullName,
    required this.url,
    required this.logoUrl,
  });
}

class _UtilityItem {
  final String title;
  final String description;
  final String image;
  final VoidCallback onTap;
  final bool showBook;

  const _UtilityItem({
    required this.title,
    required this.description,
    required this.image,
    required this.onTap,
    this.showBook = false,
  });
}

class _CmsVnuItem {
  final String id;
  final String anhDaiDien;
  final String tieuDe;
  final String tomTat;
  final String redirectUrl;
  final String ngayDang;
  final String canonical;
  final String externalLink;
  final String memberName;
  final String memberDomain;
  final String memberThumbnail;

  const _CmsVnuItem({
    required this.id,
    required this.anhDaiDien,
    required this.tieuDe,
    required this.tomTat,
    required this.redirectUrl,
    required this.ngayDang,
    required this.canonical,
    required this.externalLink,
    required this.memberName,
    required this.memberDomain,
    required this.memberThumbnail,
  });

  factory _CmsVnuItem.fromJson(Map<String, dynamic> json) {
    return _CmsVnuItem(
      id: _readString(json, 'id'),
      anhDaiDien: _readString(json, 'anhDaiDien'),
      tieuDe: _readString(json, 'tieuDe'),
      tomTat: _readString(json, 'tomTat'),
      redirectUrl: _readString(json, 'redirectUrl'),
      ngayDang: _readString(json, 'ngayDang'),
      canonical: _readString(json, 'canonical'),
      externalLink: _readString(json, 'externalLink'),
      memberName: _readString(json, 'memberName'),
      memberDomain: _readString(json, 'memberDomain'),
      memberThumbnail: _readString(json, 'memberThumbnail'),
    );
  }

  static String _readString(Map<String, dynamic> json, String key) {
    return json[key]?.toString().trim() ?? '';
  }

  String get openUrl {
    if (redirectUrl.isNotEmpty) return redirectUrl;
    if (externalLink.isNotEmpty) return externalLink;
    if (canonical.isNotEmpty) return canonical;
    return '';
  }

  String get imageUrl {
    if (anhDaiDien.isNotEmpty) return anhDaiDien;
    if (memberThumbnail.isNotEmpty) return memberThumbnail;
    return '';
  }

  String get description {
    if (tomTat.isNotEmpty) return tomTat;
    if (memberName.isNotEmpty && memberDomain.isNotEmpty) {
      return '$memberName - $memberDomain';
    }
    if (memberName.isNotEmpty) return memberName;
    if (ngayDang.isNotEmpty) return ngayDang;
    return '';
  }
}