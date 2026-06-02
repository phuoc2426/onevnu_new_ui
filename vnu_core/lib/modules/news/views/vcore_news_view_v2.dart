import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/extensions/map_ext.dart';
import 'package:vnu_core/models/tin_tuc_model.dart';
import 'package:vnu_core/models/top_tin_tuc_model.dart';
import 'package:vnu_core/modules/browser/views/vcore_browser_view.dart';
import 'package:vnu_core/modules/news/views/vcore_news_category_widget_v2.dart';
import 'package:vnu_core/modules/news/views/vcore_news_tab_widget_v2.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/widgets/container_dissmis.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

import 'vcore_news_detail_view.dart';
import 'vcore_news_item_widget.dart';

const kCacheKeyListTinTucBySchool = 'listTinTucBySchool.json';
const kCacheKeyListTinTuc = 'listTinTuc.json';

class VcoreNewsViewV2 extends StatefulWidget {
  const VcoreNewsViewV2({super.key});

  @override
  State<VcoreNewsViewV2> createState() => _VcoreNewsViewV2State();
}

class _VcoreNewsViewV2State extends State<VcoreNewsViewV2> {
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();

  NewsCategory _selectedCategory = NewsCategory.all;

  // Data lists
  List<TopTinTucModel> _listTinTucVNU = [];
  List<TopTinTucModel> _listTinTucBySchool = [];
  List<TinTucModel> _listTinTuc2 = [];
  List<TinTucModel> _listTinTucFiltered = [];

  String _schoolName = 'Trường';
  bool _isLoading = true;
  bool _showFilterDialog = false;

  // Pagination
  int _pageIndex = 1;
  final int _pageSize = 10;

  BuildContext? _hubContext;

  @override
  void initState() {
    super.initState();
    _loadCacheData();
    Future.delayed(Duration.zero, () => _loadAllData());
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Load cache data
  Future<void> _loadCacheData() async {
    try {
      // Load tin tức trường từ cache
      String? cachedData =
          await VnuCacheFileManager().getCacheFile(kCacheKeyListTinTucBySchool);
      if (cachedData != null && cachedData.isNotEmpty) {
        var jsonData = jsonDecode(cachedData);
        _schoolName = jsonData["guild"] ?? "Trường";

        if (jsonData['data'] != null) {
          List<TopTinTucModel> listObj = [];
          for (var element in jsonData['data']) {
            if (element is Map<String, dynamic>) {
              listObj.add(TopTinTucModel.fromJson(element));
            }
          }
          if (mounted) {
            setState(() {
              _listTinTucBySchool = listObj;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cache: $e');
    }
  }

  // Load all data from API
  Future<void> _loadAllData() async {
    Utils.showProgress(_hubContext);

    try {
      // Load tin tức VNU (Top 10)
      final tinTucVNUResponse = await ApiRepository().getTop10TinTuc(220, 220);

      // Load tin tức trường
      await _loadTinTucBySchool();

      // Load tin tức filtered (full list)
      await _loadFilteredData();

      if (mounted) {
        setState(() {
          _listTinTucVNU = tinTucVNUResponse;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    Utils.dismissProgress(_hubContext);
  }

  /// Load tin tức theo trường - tương tự logic trong vcore_home_controller
  Future<void> _loadTinTucBySchool() async {
    try {
      var currentUser = await ApiRepository().getCurrentUser();
      String guildDonVi = currentUser.guidDonVi.toString();
      var donVi = await ApiRepository().getDonVi(guildDonVi);
      String tenDonVi = donVi.tenDonVi.toString();

      var response =
          await ApiRepository().getTinTuc(1, 50, "", "", "", "", "", "");
      if (response.data != null && response.data!.isNotEmpty) {
        List<TinTucModel> filteredData = response.data!.where((e) {
          return e.donViXuatBan != null && e.donViXuatBan!.contains(tenDonVi);
        }).toList();

        _listTinTuc2 = filteredData;

        if (filteredData.isNotEmpty) {
          List<TopTinTucModel> listTopTinTuc = filteredData.map((e) {
            return TopTinTucModel(
              id: e.guid,
              anhDaiDien: e.guidFileAnhDaiDiens?.first,
              tieuDe: e.tieuDe,
              tomTat: e.htmlNoiDungTinBai,
            );
          }).toList();

          if (mounted) {
            setState(() {
              _listTinTucBySchool = listTopTinTuc;
              _schoolName = tenDonVi;
            });
          }

          // Save to cache
          try {
            var data = listTopTinTuc.map((e) => e.toJson()).toList();
            await VnuCacheFileManager().saveCacheFile(
                kCacheKeyListTinTucBySchool,
                jsonEncode({
                  "guild": tenDonVi,
                  "data": data,
                }));
          } catch (e) {
            logError(e.toString());
          }
        }
      }
    } catch (e) {
      logError('Error loading tin tuc by school: $e');
    }
  }

  Future<void> _loadFilteredData() async {
    try {
      final response = await ApiRepository().getTinTuc(
        _pageIndex,
        _pageSize,
        'created,desc',
        _searchController.text.trim(),
        '', // guidDonVi
        '', // startDate
        '', // endDate
        '', // additional param
      );

      if (mounted) {
        setState(() {
          if (_pageIndex == 1) {
            _listTinTucFiltered = response.data ?? [];
          } else {
            _listTinTucFiltered.addAll(response.data ?? []);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading filtered data: $e');
    }
  }

  void _onRefresh() async {
    _pageIndex = 1;
    await _loadAllData();
    _refreshController.refreshCompleted();
  }

  void _onLoadMore() async {
    _pageIndex++;
    await _loadFilteredData();
    _refreshController.loadComplete();
  }

  void _onCategorySelected(NewsCategory category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSearch() {
    _pageIndex = 1;
    _loadFilteredData();
  }

  void _viewDetailTopTinTuc(TopTinTucModel tinTuc) {
    // Navigate to browser with redirect URL
    if (tinTuc.redirectUrl != null && tinTuc.redirectUrl!.isNotEmpty) {
      Get.to(() => VcoreBrowserView(
            title: tinTuc.tieuDe ?? 'Tin tức',
            url: tinTuc.redirectUrl!,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    const normalColor = Color(0xff637392);
    const activeColor = Color(0xff003392);

    return ProgressHubWidget(
      contextComplete: (hubContext) {
        _hubContext = hubContext;
      },
      child: VcoreModuleScaffold(
        title: 'Tin tức',
        body: ContainerAutoDissmis(
          child: Column(
            children: [
              // Search bar
              Container(
                height: 64,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xff879ABF)),
                    ),
                    child: Row(
                      children: [
                        spaceWidth(10),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'Nhập tiêu đề tin',
                              hintStyle: TextStyles.regular
                                  .copyWith(color: Colors.black),
                              labelStyle: TextStyles.regular
                                  .copyWith(color: Colors.black),
                            ),
                            controller: _searchController,
                            onSubmitted: (value) => _onSearch(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0.0),
                          child: svgAsset('assets/images/ic_search.svg'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: svgAction(
                            'assets/images/ic_filter.svg',
                            color:
                                _showFilterDialog ? activeColor : normalColor,
                            action: () {
                              Utils.hideKeyboard();
                              setState(() {
                                _showFilterDialog = !_showFilterDialog;
                              });
                              // Show filter dialog - có thể mở rộng sau
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Category widget (menu row)
              Padding(
                padding: const EdgeInsets.all(16),
                child: VcoreNewsCategoryWidgetV2(
                  selectedCategory: _selectedCategory,
                  onCategorySelected: _onCategorySelected,
                ),
              ),

              // Content based on selected category
              Expanded(
                child: SmartRefresher(
                  controller: _refreshController,
                  enablePullUp: true,
                  onRefresh: _onRefresh,
                  onLoading: _onLoadMore,
                  header: const WaterDropHeader(),
                  footer: const RefreshFooterWidget(),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedCategory) {
      case NewsCategory.all:
        return _buildAllNewsContent();
      case NewsCategory.newsVNU:
        return _buildNewsListContent(_listTinTucVNU, isVNU: true);
      case NewsCategory.newsSchool:
        return _buildNewsListContent(_listTinTucBySchool, isVNU: false);
    }
  }

  Widget _buildAllNewsContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs section for news
          if (_listTinTucVNU.isNotEmpty || _listTinTucBySchool.isNotEmpty)
            VcoreNewsTabWidgetV2(
              listTinTucVNU: _listTinTucVNU,
              listTinTucBySchool: _listTinTucBySchool,
              listTinTuc2: _listTinTuc2,
              onViewDetailVNU: _viewDetailTopTinTuc,
              schoolName: _schoolName,
            ),

          spaceHeight(24),

          // Latest news section (list)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tin mới nhất',
              style: TextStyles.bold.copyWith(
                fontSize: AppFontSizes.mediumLarge,
                color: const Color(0xff181E39),
              ),
            ),
          ),
          spaceHeight(12),

          // List of filtered news
          _buildFilteredNewsList(),
        ],
      ),
    );
  }

  Widget _buildFilteredNewsList() {
    if (_listTinTucFiltered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Không có tin tức',
            style: TextStyles.regular.copyWith(
              color: const Color(0xff879ABF),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _listTinTucFiltered.length,
      separatorBuilder: (_, __) => spaceHeight(10),
      itemBuilder: (context, index) {
        final tinTuc = _listTinTucFiltered[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Utils.hideKeyboard();
            Get.to(() => VcoreNewsDetailView(tinTucModel: tinTuc));
          },
          child: VcoreNewsItemWidget(tinTucModel: tinTuc),
        );
      },
    );
  }

  Widget _buildNewsListContent(List<TopTinTucModel> listNews,
      {required bool isVNU}) {
    if (listNews.isEmpty) {
      return Center(
        child: Text(
          'Không có tin tức',
          style: TextStyles.regular.copyWith(
            color: const Color(0xff879ABF),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: listNews.length,
      separatorBuilder: (_, __) => spaceHeight(10),
      itemBuilder: (context, index) {
        final tinTuc = listNews[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (isVNU) {
              _viewDetailTopTinTuc(tinTuc);
            }
          },
          child: _buildTopTinTucItem(tinTuc),
        );
      },
    );
  }

  Widget _buildTopTinTucItem(TopTinTucModel tinTuc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 80,
            height: 80,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xffF0F4FA),
            ),
            child: tinTuc.anhDaiDien != null && tinTuc.anhDaiDien!.isNotEmpty
                ? Image.network(
                    tinTuc.anhDaiDien!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xff879ABF),
                    ),
                  )
                : const Icon(
                    Icons.article_outlined,
                    color: Color(0xff879ABF),
                  ),
          ),
          spaceWidth(12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tinTuc.tieuDe ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.medium.copyWith(
                    fontSize: AppFontSizes.medium,
                    color: const Color(0xff181E39),
                    height: 1.3,
                  ),
                ),
                spaceHeight(6),
                Text(
                  tinTuc.tomTat ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.regular.copyWith(
                    fontSize: AppFontSizes.small,
                    color: const Color(0xff637392),
                    height: 1.3,
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
