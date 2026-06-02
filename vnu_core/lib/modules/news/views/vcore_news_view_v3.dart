import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/vcore_green_brand_v3.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/models/tin_tuc_model.dart';
import 'package:vnu_core/models/top_tin_tuc_model.dart';
import 'package:vnu_core/modules/browser/views/vcore_browser_view.dart';
import 'package:vnu_core/modules/news/views/vcore_news_category_widget_v2.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

import 'package:vnu_core/modules/news/views/vcore_news_detail_view.dart';
import 'package:vnu_core/common/app_text_styles.dart';

const kCacheKeyListTinTucBySchoolV3 = 'listTinTucBySchool.json';

class VcoreNewsViewV3 extends StatefulWidget {
  const VcoreNewsViewV3({super.key});

  @override
  State<VcoreNewsViewV3> createState() => _VcoreNewsViewV3State();
}

class _VcoreNewsViewV3State extends State<VcoreNewsViewV3> {
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();
  late final PageController _pageController;

  NewsCategory _selectedCategory = NewsCategory.all;
  List<TopTinTucModel> _listSliderVNU = []; // For Carousel slider (Top 10 VNU)
  List<TopTinTucModel> _listAll = []; // For Mới nhất list
  List<TinTucModel> _listSchool = []; // For Tin Trường list
  List<TopTinTucModel> _listVNU = []; // For Tin VNU list
  
  String _schoolName = 'Trường';
  bool _isLoading = true;

  int _pageIndexAll = 1;
  int _pageIndexSchool = 1;
  int _pageIndexVNU = 1;
  bool _hasMoreAll = true;
  bool _hasMoreSchool = true;
  bool _hasMoreVNU = true;
  final int _pageSize = 10;

  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _loadCacheData();
    Future.delayed(Duration.zero, _loadAllData);
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    if (_listSliderVNU.isEmpty) return;
    final topNews = _listSliderVNU.take(10).toList();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && topNews.isNotEmpty) {
        final nextPage = (_currentCarouselIndex + 1) % topNews.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _getTopTinTucImageUrl(TopTinTucModel item) {
    final path = item.anhDaiDien;
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return 'https://vnu.edu.vn$path';
    }
    return 'https://vnu.edu.vn/$path';
  }

  Future<void> _loadCacheData() async {
    try {
      final cachedData = await VnuCacheFileManager()
          .getCacheFile(kCacheKeyListTinTucBySchoolV3);
      if (cachedData == null || cachedData.isEmpty) {
        return;
      }
      final jsonData = jsonDecode(cachedData);
      _schoolName = jsonData['guild'] ?? 'Trường';
      if (jsonData['data'] != null) {
        final listObj = <TinTucModel>[];
        for (final element in jsonData['data']) {
          if (element is Map<String, dynamic>) {
            listObj.add(TinTucModel.fromJson(element));
          }
        }
        if (mounted) {
          setState(() {
            _listSchool = listObj;
          });
        }
      }
    } catch (e) {
      logError('load cache news v3: $e');
    }
  }

  Future<void> _loadSchoolName() async {
    try {
      final currentUser = await ApiRepository().getCurrentUser();
      final guildDonVi = currentUser.guidDonVi.toString();
      final donVi = await ApiRepository().getDonVi(guildDonVi);
      final tenDonVi = donVi.tenDonVi.toString();
      if (mounted) {
        setState(() {
          _schoolName = tenDonVi;
        });
      }
    } catch (e) {
      logError('load school name: $e');
    }
  }

  Future<void> _loadAllData() async {
    try {
      await _loadSchoolName();
      // Load top slider news (always top 10 VNU news)
      final sliderResponse = await ApiRepository().getTop10TinTuc(220, 220, 10);
      
      // Load current tab data
      if (_selectedCategory == NewsCategory.all) {
        await _loadAllNews(true);
      } else if (_selectedCategory == NewsCategory.newsSchool) {
        await _loadSchoolNews(true);
      } else if (_selectedCategory == NewsCategory.newsVNU) {
        await _loadVNUNews(true);
      }

      if (mounted) {
        setState(() {
          _listSliderVNU = sliderResponse;
          _isLoading = false;
        });
        _startCarouselTimer();
      }
    } catch (e) {
      logError('load news v3 error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAllNews(bool isRefresh) async {
    if (isRefresh) {
      _pageIndexAll = 1;
      _hasMoreAll = true;
    }
    if (!_hasMoreAll) return;
    try {
      final int limit = _pageIndexAll * _pageSize;
      final response = await ApiRepository().getTop10TinTuc(220, 220, limit);
      setState(() {
        _listAll = response;
        _hasMoreAll = response.length >= limit;
        if (_hasMoreAll) {
          _pageIndexAll++;
        }
      });
    } catch (e) {
      logError('load all VNU news: $e');
    }
  }

  Future<void> _loadSchoolNews(bool isRefresh) async {
    if (isRefresh) {
      _pageIndexSchool = 1;
      _hasMoreSchool = true;
    }
    if (!_hasMoreSchool) return;
    try {
      final currentUser = await ApiRepository().getCurrentUser();
      final guildDonVi = currentUser.guidDonVi.toString();
      final donVi = await ApiRepository().getDonVi(guildDonVi);
      final tenDonVi = donVi.tenDonVi.toString();

      final response = await ApiRepository().getTinTuc(
        _pageIndexSchool,
        50, // Fetch more to ensure we get enough filtered items
        'created,desc',
        _searchController.text.trim(),
        '', // Pass empty instead of guildDonVi
        '',
        '',
        '',
      );
      final rawData = response.data ?? [];
      final newData = rawData.where((e) {
        return e.donViXuatBan != null && e.donViXuatBan!.contains(tenDonVi);
      }).toList();

      setState(() {
        if (isRefresh) {
          _listSchool = newData;
          _schoolName = tenDonVi;
        } else {
          _listSchool.addAll(newData);
        }
        _hasMoreSchool = rawData.length >= 50;
        if (_hasMoreSchool) {
          _pageIndexSchool++;
        }
      });
      
      if (isRefresh && newData.isNotEmpty) {
        await VnuCacheFileManager().saveCacheFile(
          kCacheKeyListTinTucBySchoolV3,
          jsonEncode({
            'guild': _schoolName,
            'data': _listSchool.map((e) => e.toJson()).toList(),
          }),
        );
      }
    } catch (e) {
      logError('load school news: $e');
    }
  }

  Future<void> _loadVNUNews(bool isRefresh) async {
    if (isRefresh) {
      _pageIndexVNU = 1;
      _hasMoreVNU = true;
    }
    if (!_hasMoreVNU) return;
    try {
      final int limit = _pageIndexVNU * _pageSize;
      final response = await ApiRepository().getTop10TinTuc(220, 220, limit);
      setState(() {
        _listVNU = response;
        _hasMoreVNU = response.length >= limit;
        if (_hasMoreVNU) {
          _pageIndexVNU++;
        }
      });
    } catch (e) {
      logError('load VNU news: $e');
    }
  }

  void _onCategoryChanged(NewsCategory category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
    });

    bool hasMore = true;
    if (category == NewsCategory.all) {
      hasMore = _hasMoreAll;
    } else if (category == NewsCategory.newsSchool) {
      hasMore = _hasMoreSchool;
    } else if (category == NewsCategory.newsVNU) {
      hasMore = _hasMoreVNU;
    }

    if (hasMore) {
      _refreshController.resetNoData();
    } else {
      _refreshController.loadNoData();
    }

    _onRefresh();
  }

  void _onRefresh() async {
    try {
      _refreshController.resetNoData();
      if (_selectedCategory == NewsCategory.all) {
        final sliderResponse = await ApiRepository().getTop10TinTuc(220, 220, 10);
        if (mounted) {
          setState(() {
            _listSliderVNU = sliderResponse;
          });
        }
        await _loadAllNews(true);
      } else if (_selectedCategory == NewsCategory.newsSchool) {
        await _loadSchoolNews(true);
      } else if (_selectedCategory == NewsCategory.newsVNU) {
        await _loadVNUNews(true);
      }
    } catch (e) {
      logError('refresh news error: $e');
    } finally {
      _refreshController.refreshCompleted();
    }
  }

  void _onLoadMore() async {
    try {
      bool hasMore = true;
      if (_selectedCategory == NewsCategory.all) {
        await _loadAllNews(false);
        hasMore = _hasMoreAll;
      } else if (_selectedCategory == NewsCategory.newsSchool) {
        await _loadSchoolNews(false);
        hasMore = _hasMoreSchool;
      } else if (_selectedCategory == NewsCategory.newsVNU) {
        await _loadVNUNews(false);
        hasMore = _hasMoreVNU;
      }

      if (hasMore) {
        _refreshController.loadComplete();
      } else {
        _refreshController.loadNoData();
      }
    } catch (e) {
      logError('load more news error: $e');
      _refreshController.loadFailed();
    }
  }

  void _viewDetailTopTinTuc(TopTinTucModel tinTuc) {
    if (tinTuc.redirectUrl != null && tinTuc.redirectUrl!.isNotEmpty) {
      Get.to(
        () => VcoreBrowserView(
          title: tinTuc.tieuDe ?? 'Tin tức',
          url: tinTuc.redirectUrl!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHubWidget(
      contextComplete: (_) {},
      child: VcoreModuleScaffold(
        title: 'Tin tức',
        showBackButton: Navigator.canPop(context),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SmartRefresher(
                controller: _refreshController,
                enablePullUp: true,
                onRefresh: _onRefresh,
                onLoading: _onLoadMore,
                header: const WaterDropHeader(),
                footer: const RefreshFooterWidget(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSearchBox(),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryRow(),
                    const SizedBox(height: 16),
                    ..._buildContent(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) {
                _onRefresh();
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                hintText: 'Tìm kiếm tin tức, chủ đề, nguồn...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: AppFontSizes.medium,
                  fontFamily: 'OpenSans',
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
              onPressed: () {
                _searchController.clear();
                _onRefresh();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow() {
    final items = [
      {'category': NewsCategory.all, 'label': 'Mới nhất'},
      {'category': NewsCategory.newsSchool, 'label': 'Tin $_schoolName'},
      {'category': NewsCategory.newsVNU, 'label': 'Tin VNU'},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = items[index]['category'] as NewsCategory;
          final label = items[index]['label'] as String;
          final selected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => _onCategoryChanged(category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? Colors.black87 : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? Colors.black87 : const Color(0xFFE5E7EB),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF4D4D4F),
                  fontSize: AppFontSizes.mediumSmall,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'OpenSans',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildContent() {
    switch (_selectedCategory) {
      case NewsCategory.all:
        final keyword = _searchController.text.trim().toLowerCase();
        final displayList = keyword.isEmpty
            ? _listAll
            : _listAll.where((item) {
                final title = item.tieuDe?.toLowerCase() ?? '';
                final summary = item.tomTat?.toLowerCase() ?? '';
                return title.contains(keyword) || summary.contains(keyword);
              }).toList();
        return [
          _buildTopStoriesCarousel(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mới nhất',
                  style: TextStyle(
                    fontSize: AppFontSizes.extraExtraLarge,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    fontFamily: 'OpenSans',
                  ),
                ),
                Text(
                  'Xem thêm',
                  style: TextStyle(
                    fontSize: AppFontSizes.mediumSmall,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).primaryColor,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (displayList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: displayList.map(_buildTileFromTopNews).toList(),
              ),
            )
          else
            _emptyState(),
        ];
      case NewsCategory.newsSchool:
        if (_listSchool.isEmpty) {
          return [_emptyState()];
        }
        return [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _listSchool.map(_buildLatestNewsTile).toList(),
            ),
          )
        ];
      case NewsCategory.newsVNU:
        final keyword = _searchController.text.trim().toLowerCase();
        final displayList = keyword.isEmpty
            ? _listVNU
            : _listVNU.where((item) {
                final title = item.tieuDe?.toLowerCase() ?? '';
                final summary = item.tomTat?.toLowerCase() ?? '';
                return title.contains(keyword) || summary.contains(keyword);
              }).toList();
        if (displayList.isEmpty) {
          return [_emptyState()];
        }
        return [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: displayList.map(_buildTileFromTopNews).toList(),
            ),
          )
        ];
    }
  }

  Widget _buildTopStoriesCarousel() {
    if (_listSliderVNU.isEmpty) return const SizedBox.shrink();

    final topNews = _listSliderVNU.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tin nổi bật',
                style: TextStyle(
                  fontSize: AppFontSizes.extraExtraLarge,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  fontFamily: 'OpenSans',
                ),
              ),
              Text(
                'Tự trượt',
                style: TextStyle(
                  fontSize: AppFontSizes.mediumSmall,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).primaryColor,
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 310,
          child: PageView.builder(
            controller: _pageController,
            itemCount: topNews.length,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final item = topNews[index];
              return _buildHeroCard(item);
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildCarouselDots(topNews.length),
      ],
    );
  }

  Widget _buildHeroCard(TopTinTucModel item) {
    final imageUrl = _getTopTinTucImageUrl(item);
    final hasImage = imageUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
        onTap: () => _viewDetailTopTinTuc(item),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              httpHeaders: Globals().headerToken(),
                              errorWidget: (context, error, stackTrace) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF374151), Color(0xFF1F2937)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF374151), Color(0xFF1F2937)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.08), Colors.black.withOpacity(0.4)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'NỔI BẬT',
                          style: TextStyle(
                            fontSize: AppFontSizes.extraSmall,
                            fontWeight: FontWeight.w800,
                            color: Colors.redAccent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tin VNU',
                          style: TextStyle(
                            fontSize: AppFontSizes.font11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.tieuDe ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSizes.mediumLarge,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        height: 1.25,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (item.tomTat != null && item.tomTat!.isNotEmpty)
                      Text(
                        item.tomTat!.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppFontSizes.small,
                          color: Colors.grey.shade600,
                          height: 1.3,
                          fontFamily: 'OpenSans',
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

  Widget _buildCarouselDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == _currentCarouselIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.black87 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildLatestNewsTile(TinTucModel item) {
    final hasImage = item.guidFileAnhDaiDiens?.isNotEmpty == true;
    final imageUrl = hasImage
        ? '${ServicesUrl().baseUrlFileDownload}${item.guidFileAnhDaiDiens!.first}'
        : '';

    String timeStr = 'Vừa xong';
    if (item.thoiGianTao != null) {
      final diff = DateTime.now().difference(item.thoiGianTao!);
      if (diff.inMinutes < 60) {
        timeStr = '${diff.inMinutes} phút trước';
      } else if (diff.inHours < 24) {
        timeStr = '${diff.inHours} giờ trước';
      } else {
        timeStr = DateTimeUtils.stringFromDateTime(
            item.thoiGianTao, DateTimeConst.DATE_FORMAT);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => Get.to(
          () => VcoreNewsDetailView(
            tinTucModel: item,
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.donViXuatBan?.toUpperCase() ?? 'TIN TỨC'} • $timeStr',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppFontSizes.extraSmall,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.tieuDe ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSizes.medium,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.3,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (item.tenChuyenMuc != null && item.tenChuyenMuc!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.tenChuyenMuc!,
                          style: TextStyle(
                            fontSize: AppFontSizes.extraSmall,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    imageUrl: '$imageUrl$kParamThumbImage',
                    cacheKey: imageUrl,
                    httpHeaders: Globals().headerToken(),
                    errorWidget: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.newspaper, size: 24, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTileFromTopNews(TopTinTucModel item) {
    final imageUrl = _getTopTinTucImageUrl(item);
    final hasImage = imageUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _viewDetailTopTinTuc(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIN VNU • NỔI BẬT',
                      style: TextStyle(
                        fontSize: AppFontSizes.extraSmall,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.tieuDe ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSizes.medium,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.3,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (item.tomTat != null && item.tomTat!.isNotEmpty)
                      Text(
                        item.tomTat!.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppFontSizes.small,
                          color: Colors.grey.shade500,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    imageUrl: imageUrl,
                    cacheKey: imageUrl,
                    httpHeaders: Globals().headerToken(),
                    errorWidget: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.newspaper, size: 24, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: const Center(
        child: Text(
          'Không có tin tức',
          style: TextStyle(
            color: VcoreGreenBrandV3.muted,
            fontSize: AppFontSizes.medium,
            height: 1.35,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
    );
  }
}
