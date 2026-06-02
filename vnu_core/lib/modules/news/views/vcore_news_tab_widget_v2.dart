import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/tin_tuc_model.dart';
import 'package:vnu_core/models/top_tin_tuc_model.dart';
import 'package:vnu_core/modules/news/views/vcore_news_detail_view.dart';
import 'package:vnu_core/services/services_url.dart';

class VcoreNewsTabWidgetV2 extends StatefulWidget {
  /// Tin tức từ VNU (TopTinTucModel)
  final List<TopTinTucModel> listTinTucVNU;

  /// Tin tức từ Trường (TopTinTucModel) - hiển thị từ listTinTucBySchool
  final List<TopTinTucModel> listTinTucBySchool;

  /// Tin tức chi tiết từ trường (TinTucModel) - dùng để navigate
  final List<TinTucModel> listTinTuc2;

  /// Callback khi xem chi tiết tin VNU
  final Function(TopTinTucModel) onViewDetailVNU;

  /// Tên trường để hiển thị trên tab
  final String schoolName;

  const VcoreNewsTabWidgetV2({
    super.key,
    required this.listTinTucVNU,
    required this.listTinTucBySchool,
    required this.listTinTuc2,
    required this.onViewDetailVNU,
    this.schoolName = 'Trường',
  });

  @override
  State<VcoreNewsTabWidgetV2> createState() => _VcoreNewsTabWidgetV2State();
}

class _VcoreNewsTabWidgetV2State extends State<VcoreNewsTabWidgetV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xffF0F4FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xff003392),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(4),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xff637392),
            labelStyle: TextStyles.medium.copyWith(fontSize: AppFontSizes.medium),
            unselectedLabelStyle: TextStyles.regular.copyWith(fontSize: AppFontSizes.medium),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Tin ${widget.schoolName}'),
              const Tab(text: 'Tin VNU'),
            ],
          ),
        ),
        spaceHeight(16),
        // Tab Content
        SizedBox(
          height: 180,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Tin tức Trường
              _buildNewsList(
                listTopTinTuc: widget.listTinTucBySchool,
                listTinTuc2: widget.listTinTuc2,
                isSchoolNews: true,
              ),
              // Tab 2: Tin tức VNU
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
    if (listTopTinTuc.isEmpty && (listTinTuc2?.isEmpty ?? true)) {
      return Center(
        child: Text(
          'Chưa có tin tức',
          style: TextStyles.regular.copyWith(
            color: const Color(0xff879ABF),
          ),
        ),
      );
    }

    return _NewsHorizontalList(
      listTopTinTuc: listTopTinTuc,
      listTinTuc2: listTinTuc2,
      isSchoolNews: isSchoolNews,
      onViewDetailVNU: widget.onViewDetailVNU,
    );
  }
}

class _NewsHorizontalList extends StatefulWidget {
  final List<TopTinTucModel> listTopTinTuc;
  final List<TinTucModel>? listTinTuc2;
  final bool isSchoolNews;
  final Function(TopTinTucModel) onViewDetailVNU;

  const _NewsHorizontalList({
    required this.listTopTinTuc,
    this.listTinTuc2,
    required this.isSchoolNews,
    required this.onViewDetailVNU,
  });

  @override
  State<_NewsHorizontalList> createState() => _NewsHorizontalListState();
}

class _NewsHorizontalListState extends State<_NewsHorizontalList> {
  final ScrollController _controller = ScrollController();
  double marginLeft = 0.0;

  @override
  Widget build(BuildContext context) {
    // Nếu là tin trường và có listTinTuc2 thì dùng listTinTuc2
    final bool useListTinTuc2 =
        widget.isSchoolNews && (widget.listTinTuc2?.isNotEmpty ?? false);
    final int itemCount = useListTinTuc2
        ? widget.listTinTuc2!.length
        : widget.listTopTinTuc.length;

    return Column(
      children: [
        SizedBox(
          height: 136,
          child: NotificationListener<ScrollUpdateNotification>(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              separatorBuilder: (context, index) => spaceWidth(15),
              controller: _controller,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: itemCount,
              itemBuilder: (ctx, index) {
                if (useListTinTuc2) {
                  // Dùng TinTucModel cho tin trường
                  final TinTucModel tinTuc = widget.listTinTuc2![index];
                  String imageUrl =
                      '${ServicesUrl().baseUrlFileDownload}${tinTuc.guidFileAnhDaiDiens?.first}$kParamThumbImage';
                  String cacheKey =
                      '${ServicesUrl().baseUrlFileDownload}${tinTuc.guidFileAnhDaiDiens?.first}';

                  return _buildNewsItem(
                    imageUrl: imageUrl,
                    cacheKey: cacheKey,
                    title: tinTuc.tieuDe,
                    onTap: () {
                      Get.to(() => VcoreNewsDetailView(tinTucModel: tinTuc));
                    },
                  );
                } else {
                  // Dùng TopTinTucModel cho tin VNU
                  final TopTinTucModel tinTuc = widget.listTopTinTuc[index];
                  String imageUrl = tinTuc.anhDaiDien ?? '';
                  String cacheKey = tinTuc.anhDaiDien ?? '';

                  return _buildNewsItem(
                    imageUrl: imageUrl,
                    cacheKey: cacheKey,
                    title: tinTuc.tieuDe,
                    onTap: () {
                      widget.onViewDetailVNU(tinTuc);
                    },
                  );
                }
              },
            ),
            onNotification: (notification) {
              if (_controller.position.maxScrollExtent > 0) {
                double newMargin = (notification.metrics.pixels /
                        _controller.position.maxScrollExtent) *
                    (2.0 / 3.0) *
                    30.0;
                newMargin = max(0, newMargin);
                newMargin = min(newMargin, 20);
                setState(() {
                  marginLeft = newMargin;
                });
              }
              return true;
            },
          ),
        ),
        // Scroll indicator
        SizedBox(
          width: double.infinity,
          height: 20,
          child: Center(
            child: Stack(
              children: [
                Container(
                  height: 5,
                  width: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xffDDE3EE),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Container(
                  height: 5,
                  width: 10,
                  margin: EdgeInsets.only(left: marginLeft),
                  decoration: BoxDecoration(
                    color: const Color(0xff003392),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsItem({
    required String imageUrl,
    required String cacheKey,
    required String? title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 164,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              width: double.infinity,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xffF0F4FA),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                cacheKey: cacheKey,
                fit: BoxFit.cover,
                httpHeaders: Globals().headerToken(),
                placeholder: (context, url) => Container(
                  color: const Color(0xffF0F4FA),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) {
                  return Container(
                    color: const Color(0xffF0F4FA),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xff879ABF),
                    ),
                  );
                },
              ),
            ),
            spaceHeight(8),
            Text(
              title ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.regular.copyWith(
                fontSize: AppFontSizes.mediumSmall,
                color: const Color(0xff2A3556),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
