import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/browser/views/vcore_browser_view.dart';
import 'package:vnu_core/modules/cam_nang/views/vcore_cam_nang_view.dart';
import 'package:vnu_core/modules/inmapz/vcore_immap_view.dart';
import 'package:vnu_core/modules/motel/vcore_motel_webview.dart';
import 'package:vnu_core/modules/admission/views/applicant_login_with_zalo.dart';
import 'package:vnu_core/screens/vcore_login_screen_v3.dart';
import 'package:vnu_core/services/app_config_service.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/widgets/zalo_chat_bubble.dart';

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

    AppConfigService().ensureLoaded();
    _loadTinTucVNU();
    _loadJobs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _getMobileApiBaseUrl() async {
    // Core API is fixed; never read the legacy `domain` preference.
    return ServicesUrl.defaultBaseUrl;
  }

  Future<List<_CmsVnuItem>> _getCmsPublicItems(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final String baseUrl = await _getMobileApiBaseUrl();

    final dio.Response<dynamic> response = await dio.Dio().get(
      '$baseUrl$path',
      queryParameters: queryParameters,
    );

    final dynamic raw = response.data;
    List<dynamic> items = [];

    if (raw is List) {
      items = raw;
    } else if (raw is Map) {
      final dynamic data = raw['data'] ?? raw['content'] ?? raw['items'];

      if (data is List) {
        items = data;
      }
    }

    return items
        .whereType<Map>()
        .map(
          (Map item) => _CmsVnuItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> _loadTinTucVNU() async {
    try {
      final List<_CmsVnuItem> data = await _getCmsPublicItems(
        _tinTucPath,
        queryParameters: <String, dynamic>{'limit': 20},
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
      final List<_CmsVnuItem> data = await _getCmsPublicItems(
        _viecLamPath,
        queryParameters: <String, dynamic>{'pageIndex': 1, 'pageSize': 20},
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

  void _goToStudentLogin() {
    Get.to(() => const VCoreLoginScreenV3());
  }

  void _goToNewStudentLogin() {
    Get.to(() => const ApplicantLoginWithZalo());
  }

  void _openWebUrl(String title, String url) {
    if (url.trim().isEmpty) return;

    Get.to(() => VcoreBrowserView(title: title, url: url));
  }

  void _openAdmissionUnit(_AdmissionUnit item) {
    _openWebUrl(item.fullName, item.url);
  }

  void _openCmsItem(_CmsVnuItem item, String fallbackTitle) {
    final String url = item.openUrl;

    if (url.isEmpty) return;

    _openWebUrl(item.tieuDe.isNotEmpty ? item.tieuDe : fallbackTitle, url);
  }

  String _resolveImageUrl(_CmsVnuItem item) {
    final String image = item.imageUrl;

    if (image.isEmpty) {
      return '';
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }

    final String baseUrl = ServicesUrl.defaultBaseUrl;
    return image.startsWith('/') ? '$baseUrl$image' : '$baseUrl/$image';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: primaryGreen,
              onRefresh: () async {
                await Future.wait<void>(<Future<void>>[
                  AppConfigService().ensureLoaded(forceRefresh: true),
                  _loadTinTucVNU(),
                  _loadJobs(),
                ]);
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: <Widget>[
                  SliverToBoxAdapter(child: _buildHero()),
                  SliverToBoxAdapter(child: _buildAdmissionUnits()),
                  SliverToBoxAdapter(child: _buildUtilities()),
                  SliverToBoxAdapter(
                    child: _buildCmsSection(
                      title: 'Tin tức VNU',
                      fallbackTitle: 'Tin tức VNU',
                      tag: 'VNU',
                      isLoading: _isLoadingTinTucVNU,
                      emptyText: 'Chưa có tin tức VNU',
                      items: _listTinTucVNU,
                      onViewAll: () {
                        _openWebUrl('Tin tức VNU', _allNewsUrl);
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildCmsSection(
                      title: 'Cơ hội việc làm',
                      fallbackTitle: 'Cơ hội việc làm',
                      tag: 'VIỆC LÀM',
                      isLoading: _isLoadingJobs,
                      emptyText: 'Chưa có tin tuyển dụng',
                      items: _listJobs,
                      onViewAll: () {
                        _openWebUrl('Cơ hội việc làm', _allJobsUrl);
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ),
          const ZaloChatBubble(edgeInsets: EdgeInsets.fromLTRB(12, 12, 16, 24)),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      height: 270,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/admission_bg.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              lightGreen.withOpacity(0.97),
              lightGreen.withOpacity(0.84),
              lightGreen.withOpacity(0.16),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 13,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Trang thông tin sinh viên',
                    style: TextStyles.bold.copyWith(
                      fontSize: 19.5,
                      height: 1.1,
                      color: primaryGreen,
                    ),
                  ),
                  spaceHeight(8),
                  const Text(
                    'Đăng nhập dành cho sinh viên '
                    'và tân sinh viên trúng tuyển',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 150,
                        height: 92,
                        child: _buildActionCard(
                          icon: Icons.school_rounded,
                          title: 'Đăng nhập',
                          subtitle: 'Hệ thống OneVNU',
                          gradientColors: const <Color>[
                            Color(0xFF2E7D32),
                            Color(0xFF4CAF50),
                          ],
                          onTap: _goToStudentLogin,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Expanded(flex: 3, child: SizedBox()),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 82,
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: gradientColors.first.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 22, color: Colors.white),
              const SizedBox(height: 5),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdmissionUnits() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Column(
        children: <Widget>[
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
              itemBuilder: (BuildContext context, int index) {
                final _AdmissionUnit item = _admissionUnits[index];

                return _AdmissionUnitCard(
                  item: item,
                  onTap: () {
                    _openAdmissionUnit(item);
                  },
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
    final List<_UtilityItem> utilities = <_UtilityItem>[
      _UtilityItem(
        title: 'Cẩm nang tân sinh viên',
        description:
            'Hành trang vững vàng '
            'cho hành trình đại học',
        image: 'assets/images/state_0_manual.png',
        onTap: () {
          Get.to(() => const VcoreCamNangView());
        },
        showBook: true,
      ),
      _UtilityItem(
        title: 'Tin tức VNU',
        description:
            'Cập nhật nhanh chóng '
            'tin tức & sự kiện mới nhất',
        image: 'assets/images/state_0_news.png',
        onTap: () {
          _openWebUrl('Tin tức VNU', _allNewsUrl);
        },
      ),
      _UtilityItem(
        title: 'Nhà trọ',
        description:
            'Tìm kiếm nhà trọ '
            'an toàn, tiện lợi',
        image: 'assets/images/state_0_dormitory.png',
        onTap: openMotelWebView,
      ),
      _UtilityItem(
        title: 'Bản đồ số',
        description:
            'Khám phá bản đồ số '
            'các cơ sở VNU',
        image: 'assets/images/state_0_map.png',
        onTap: () {
          Get.to(() => const VcoreImmapView());
        },
      ),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Column(
        children: <Widget>[
          const _SectionTitle(title: 'Tiện ích nổi bật'),
          spaceHeight(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double gap = 10;
                final double itemWidth = (constraints.maxWidth - gap) / 2;
                final double itemHeight = itemWidth / 1.16;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: utilities.map((_UtilityItem item) {
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

  Widget _buildCmsSection({
    required String title,
    required String fallbackTitle,
    required String tag,
    required bool isLoading,
    required String emptyText,
    required List<_CmsVnuItem> items,
    required VoidCallback onViewAll,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Column(
        children: <Widget>[
          _SectionTitle(
            title: title,
            actionText: 'Xem tất cả',
            onTapAction: onViewAll,
          ),
          spaceHeight(12),
          if (isLoading)
            const _LoadingHorizontalSection()
          else if (items.isEmpty)
            _EmptyHorizontalSection(text: emptyText)
          else
            SizedBox(
              height: 172,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => spaceWidth(10),
                itemBuilder: (BuildContext context, int index) {
                  final _CmsVnuItem item = items[index];

                  return _AdmissionNewsCard(
                    tag: tag,
                    imageUrl: _resolveImageUrl(item),
                    title: item.tieuDe,
                    description: item.description,
                    onTap: () {
                      _openCmsItem(item, fallbackTitle);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  static final List<_AdmissionUnit> _admissionUnits = <_AdmissionUnit>[
    const _AdmissionUnit(
      shortName: 'HUS',
      name: 'Khoa học\nTự nhiên',
      fullName: 'Trường Đại học Khoa học Tự nhiên',
      url: 'https://tuyensinh.hus.vnu.edu.vn/',
      logoUrl:
          'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/logo-hus-final-01-1.png?w=1920&dpi=72',
    ),
    const _AdmissionUnit(
      shortName: 'USSH',
      name: 'KHXH &\nNhân văn',
      fullName: 'Trường Đại học Khoa học Xã hội & Nhân văn',
      url: 'https://tuyensinh.ussh.edu.vn/',
      logoUrl:
          'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/vnu-ussh-1-s.png?w=1920&dpi=72',
    ),
    const _AdmissionUnit(
      shortName: 'ULIS',
      name: 'Đại học\nNgoại ngữ',
      fullName: 'Trường Đại học Ngoại ngữ',
      url: 'https://ulis.vnu.edu.vn/tuyensinh2026/',
      logoUrl:
          'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/vnu-ulis.png?w=1920&dpi=72',
    ),
    const _AdmissionUnit(
      shortName: 'UET',
      name: 'Đại học\nCông nghệ',
      fullName: 'Trường Đại học Công nghệ',
      url: 'https://uet.vnu.edu.vn/category/tuyen-sinh/',
      logoUrl:
          'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/vnu-uet.png?w=1920&dpi=72',
    ),
    const _AdmissionUnit(
      shortName: 'UEB',
      name: 'Đại học\nKinh tế',
      fullName: 'Trường Đại học Kinh tế',
      url: 'https://ueb.vnu.edu.vn/Tuyen-Sinh',
      logoUrl:
          'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/truong-dh-kinh-te.png?w=1920&dpi=72',
    ),
    const _AdmissionUnit(
      shortName: 'UEd',
      name: 'Đại học\nGiáo dục',
      fullName: 'Trường Đại học Giáo dục',
      url: 'https://education.vnu.edu.vn/',
      logoUrl:
          'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/logo-vnu-ued-1.png?w=1920&dpi=72',
    ),
    const _AdmissionUnit(
      shortName: 'VJU',
      name: 'Đại học\nViệt - Nhật',
      fullName: 'Trường Đại học Việt - Nhật',
      url: 'https://vju.ac.vn/tuyensinhdaihoc/thong-tin-tuyen-sinh-2026/',
      logoUrl:
          'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/1200px-logo-vju-svg.png?w=1920&dpi=72',
    ),
    const _AdmissionUnit(
      shortName: 'UMP',
      name: 'Đại học\nY Dược',
      fullName: 'Trường Đại học Y Dược',
      url: 'https://ump.vnu.edu.vn/index.html',
      logoUrl:
          'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/vnu-ump-1.png?w=1920&dpi=72',
    ),
    const _AdmissionUnit(
      shortName: 'UL',
      name: 'Đại học\nLuật',
      fullName: 'Trường Đại học Luật',
      url: 'https://law.vnu.edu.vn/tuyen-sinh/',
      logoUrl:
          'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/vnu-ul-1.png?w=1920&dpi=72',
    ),
    const _AdmissionUnit(
      shortName: 'HSB',
      name: 'Quản trị &\nKinh doanh',
      fullName: 'Trường Quản trị và Kinh doanh',
      url: 'https://www.hsb.edu.vn/admissions',
      logoUrl:
          'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/z3820263481061-a5913e95067524e958b051f5ac42e874.jpg?w=1920&dpi=72',
    ),
    const _AdmissionUnit(
      shortName: 'IS',
      name: 'Trường\nQuốc tế',
      fullName: 'Trường Quốc tế',
      url:
          'https://www.is.vnu.edu.vn/chuyen-trang-tuyen-sinh-dai-hoc-nam-2026/',
      logoUrl:
          'https://cdnportal.vnu.edu.vn/data/0/images/2025/06/16/upload_2/vnu-is.png?w=1920&dpi=72',
    ),
    const _AdmissionUnit(
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

  const _SectionTitle({required this.title, this.actionText, this.onTapAction});

  @override
  Widget build(BuildContext context) {
    final String? action = actionText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: <Widget>[
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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

  const _AdmissionUnitCard({required this.item, required this.onTap});

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
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CachedNetworkImage(
              imageUrl: item.logoUrl,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              placeholder: (_, __) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              },
              errorWidget: (_, __, ___) {
                return _LogoFallback(text: item.shortName);
              },
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

class _UtilityCard extends StatelessWidget {
  final _UtilityItem item;

  const _UtilityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isBookCard = item.showBook;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDEBDD)),
          boxShadow: <BoxShadow>[
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
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Colors.white.withOpacity(0.02),
                      Colors.black.withOpacity(isBookCard ? 0.42 : 0.56),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Padding(
                padding: const EdgeInsets.only(right: 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.bold.copyWith(
                        fontSize: isBookCard ? 13 : 12,
                        color: Colors.white,
                        shadows: const <Shadow>[
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
                        shadows: const <Shadow>[
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
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
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
    final bool hasImage = imageUrl.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 204,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _VcoreAdmissionViewState.borderColor),
          borderRadius: BorderRadius.circular(14),
          boxShadow: <BoxShadow>[
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
          children: <Widget>[
            SizedBox(
              height: 86,
              width: double.infinity,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: hasImage
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) {
                              return _buildImageFallback();
                            },
                            errorWidget: (_, __, ___) {
                              return _buildImageFallback();
                            },
                          )
                        : _buildImageFallback(),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
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
                  children: <Widget>[
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
          colors: <Color>[Color(0xFFEAF7EF), Color(0xFFD6EBDD)],
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

  const _EmptyHorizontalSection({required this.text});

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
    final String fallbackText = text.isNotEmpty ? text.substring(0, 1) : 'V';

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
    if (redirectUrl.isNotEmpty) {
      return redirectUrl;
    }

    if (externalLink.isNotEmpty) {
      return externalLink;
    }

    if (canonical.isNotEmpty) {
      return canonical;
    }

    return '';
  }

  String get imageUrl {
    if (anhDaiDien.isNotEmpty) {
      return anhDaiDien;
    }

    if (memberThumbnail.isNotEmpty) {
      return memberThumbnail;
    }

    return '';
  }

  String get description {
    if (tomTat.isNotEmpty) {
      return tomTat;
    }

    if (memberName.isNotEmpty && memberDomain.isNotEmpty) {
      return '$memberName - $memberDomain';
    }

    if (memberName.isNotEmpty) {
      return memberName;
    }

    if (ngayDang.isNotEmpty) {
      return ngayDang;
    }

    return '';
  }
}
