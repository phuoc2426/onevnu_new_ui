import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/modules/paht_v2/forum/models/paht_forum_models.dart';
import 'package:vnu_core/modules/paht_v2/forum/repository/paht_forum_repository.dart';
import 'package:vnu_core/modules/paht_v2/forum/views/paht_forum_detail_view.dart';
import 'package:vnu_core/modules/paht_v2/forum/widgets/paht_forum_card.dart';
import 'package:vnu_core/modules/paht_v2/forum/widgets/paht_topic_visual.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_avatar_widget.dart';
import 'package:vnu_core/themes/app_theme.dart';

class PahtForumCommunityView extends StatefulWidget {
  final String avatarUrl;
  final bool showKtxResidence;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onKtxTap;

  const PahtForumCommunityView({
    super.key,
    required this.avatarUrl,
    this.showKtxResidence = false,
    this.onAvatarTap,
    this.onFollowingTap,
    this.onKtxTap,
  });

  @override
  State<PahtForumCommunityView> createState() => _PahtForumCommunityViewState();
}

class _PahtForumCommunityViewState extends State<PahtForumCommunityView>
    with WidgetsBindingObserver {
  static const Duration _liveInterval = Duration(seconds: 8);

  final PahtForumRepository _repository = PahtForumRepository();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _interested = <String, bool>{};
  final Map<String, int> _careCounts = <String, int>{};
  final Set<String> _interestBusy = <String>{};
  final Map<String, PahtForumDetail> _detailCache = <String, PahtForumDetail>{};
  final Set<String> _newArrivalGuids = <String>{};

  String? _expandedGuid;
  String? _expandingGuid;

  Timer? _debounce;
  Timer? _liveTimer;
  PahtBootstrap? _bootstrap;
  List<PahtForumItem> _items = <PahtForumItem>[];
  int _total = 0;
  int _followingCount = 0;
  int _page = 0;
  int? _topicId;
  String _status = '';
  String _sort = 'recent';
  bool _loading = true;
  bool _loadingMore = false;
  bool _filterBusy = false;
  bool _backgroundSyncing = false;
  int _queryEpoch = 0;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitial();
    _startLiveSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _liveTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncSilently();
      _startLiveSync();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _liveTimer?.cancel();
      _liveTimer = null;
    }
  }

  void _startLiveSync() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(_liveInterval, (_) => _syncSilently());
  }

  Future<void> _loadInitial() async {
    final int epoch = ++_queryEpoch;
    final String searchSnapshot = _searchController.text;
    final int? topicSnapshot = _topicId;
    final String statusSnapshot = _status;
    final String sortSnapshot = _sort;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }
    try {
      final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
        _repository.getBootstrap(),
        _repository.getCommunity(
          search: searchSnapshot,
          topicId: topicSnapshot,
          status: statusSnapshot,
          sort: sortSnapshot,
          page: 0,
        ),
      ]);
      if (!mounted || epoch != _queryEpoch) return;
      final PahtBootstrap bootstrap = results[0] as PahtBootstrap;
      final PahtForumPage page = results[1] as PahtForumPage;
      _syncInterestState(page.items);
      setState(() {
        _bootstrap = bootstrap;
        _items = page.items;
        _total = page.total;
        _followingCount = bootstrap.followingCount;
        _page = page.page;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || epoch != _queryEpoch) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _reloadList() async {
    if (!mounted) return;
    final int epoch = ++_queryEpoch;
    setState(() {
      _filterBusy = true;
      _error = '';
    });
    try {
      final PahtForumPage page = await _repository.getCommunity(
        search: _searchController.text,
        topicId: _topicId,
        status: _status,
        sort: _sort,
        page: 0,
      );
      if (!mounted || epoch != _queryEpoch) return;
      _syncInterestState(page.items);
      setState(() {
        _items = page.items;
        _total = page.total;
        _page = page.page;
        _loading = false;
        _filterBusy = false;
      });
    } catch (error) {
      if (!mounted || epoch != _queryEpoch) return;
      setState(() {
        _loading = false;
        _filterBusy = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _syncSilently() async {
    if (_backgroundSyncing || !mounted) return;
    _backgroundSyncing = true;
    final String searchSnapshot = _searchController.text;
    final int? topicSnapshot = _topicId;
    final String statusSnapshot = _status;
    final String sortSnapshot = _sort;
    try {
      final PahtForumPage page = await _repository.getCommunity(
        search: searchSnapshot,
        topicId: topicSnapshot,
        status: statusSnapshot,
        sort: sortSnapshot,
        page: 0,
      );
      if (!mounted ||
          searchSnapshot != _searchController.text ||
          topicSnapshot != _topicId ||
          statusSnapshot != _status ||
          sortSnapshot != _sort) return;

      final List<PahtForumItem> nextItems;
      if (_page == 0) {
        nextItems = page.items;
      } else {
        final Map<String, PahtForumItem> merged = <String, PahtForumItem>{};
        for (final PahtForumItem item in page.items) {
          merged[item.guid] = item;
        }
        for (final PahtForumItem item in _items) {
          merged.putIfAbsent(item.guid, () => item);
        }
        nextItems = merged.values.toList(growable: false);
      }

      final Set<String> oldGuids = _items.map((PahtForumItem e) => e.guid).toSet();
      final List<String> arrivals = nextItems
          .where((PahtForumItem item) => !oldGuids.contains(item.guid))
          .map((PahtForumItem item) => item.guid)
          .toList(growable: false);
      final bool listChanged = !_sameForumList(_items, nextItems) || _total != page.total;

      _syncInterestState(nextItems);
      if (listChanged) {
        setState(() {
          _items = nextItems;
          _total = page.total;
          _newArrivalGuids.addAll(arrivals);
        });
        if (arrivals.isNotEmpty) {
          Future<void>.delayed(const Duration(milliseconds: 950), () {
            if (!mounted) return;
            setState(() => _newArrivalGuids.removeAll(arrivals));
          });
        }
      }

      final String? expandedGuid = _expandedGuid;
      if (expandedGuid != null) {
        try {
          final PahtForumDetail detail = await _repository.getPublicDetail(expandedGuid);
          if (!mounted || _expandedGuid != expandedGuid) return;
          final PahtForumDetail? oldDetail = _detailCache[expandedGuid];
          final bool detailChanged = oldDetail == null ||
              _detailSignature(oldDetail) != _detailSignature(detail);
          if (detailChanged) {
            setState(() {
              _detailCache[expandedGuid] = detail;
              _interested[expandedGuid] = detail.interested;
              _careCounts[expandedGuid] = detail.item.careCount;
            });
          }
        } catch (_) {
          // Giữ dữ liệu cũ nếu đồng bộ nền tạm lỗi; tuyệt đối không chớp loader.
        }
      }
    } catch (_) {
      // Đồng bộ nền không che dữ liệu đang có và không làm phiền người dùng.
    } finally {
      _backgroundSyncing = false;
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _items.length >= _total) return;
    final String searchSnapshot = _searchController.text;
    final int? topicSnapshot = _topicId;
    final String statusSnapshot = _status;
    final String sortSnapshot = _sort;
    setState(() => _loadingMore = true);
    try {
      final PahtForumPage page = await _repository.getCommunity(
        search: searchSnapshot,
        topicId: topicSnapshot,
        status: statusSnapshot,
        sort: sortSnapshot,
        page: _page + 1,
      );
      if (!mounted ||
          searchSnapshot != _searchController.text ||
          topicSnapshot != _topicId ||
          statusSnapshot != _status ||
          sortSnapshot != _sort) {
        if (mounted) setState(() => _loadingMore = false);
        return;
      }
      _syncInterestState(page.items);
      final Set<String> existing = _items.map((PahtForumItem e) => e.guid).toSet();
      setState(() {
        _items = <PahtForumItem>[
          ..._items,
          ...page.items.where((PahtForumItem item) => existing.add(item.guid)),
        ];
        _total = page.total;
        _page = page.page;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), _reloadList);
  }

  Future<void> _handleCardTap(PahtForumItem item) async {
    if (_expandedGuid == item.guid) {
      setState(() => _expandedGuid = null);
      return;
    }

    setState(() {
      _expandedGuid = item.guid;
      if (!_detailCache.containsKey(item.guid)) _expandingGuid = item.guid;
    });

    try {
      PahtForumDetail detail = await _repository.getPublicDetail(item.guid);
      // Nếu list vừa nhận metadata có phản hồi nhưng detail đến đúng thời điểm DB đang
      // commit dở, thử lại một lần ngắn. Không bao giờ đánh dấu "đã trả lời" chỉ dựa
      // vào workflow status.
      if ((item.hasOfficialAnswer || item.responseCount > 0) &&
          detail.responses.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 240));
        detail = await _repository.getPublicDetail(item.guid);
      }
      if (!mounted || _expandedGuid != item.guid) return;
      setState(() {
        _detailCache[item.guid] = detail;
        _interested[item.guid] = detail.interested;
        _careCounts[item.guid] = detail.item.careCount;
      });
    } catch (error) {
      if (!mounted || _expandedGuid != item.guid) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted && _expandingGuid == item.guid) {
        setState(() => _expandingGuid = null);
      }
    }
  }

  Future<void> _openDetail(PahtForumItem item) async {
    await Get.to(() => PahtForumDetailView(guid: item.guid, publicOnly: true));
    await _syncSilently();
  }

  Future<void> _toggleInterest(PahtForumItem item) async {
    if (_interestBusy.contains(item.guid)) return;
    final bool current = _interested[item.guid] ?? item.interested;
    final bool target = !current;
    final int oldCare = _careCounts[item.guid] ?? item.careCount;
    final int oldFollowing = _followingCount;

    // Optimistic UI cho tim + số đang theo dõi; API trả lại số thật từ DB.
    setState(() {
      _interestBusy.add(item.guid);
      _interested[item.guid] = target;
      _careCounts[item.guid] =
          (oldCare + (target ? 1 : -1)).clamp(0, 1 << 30).toInt();
      _followingCount =
          (oldFollowing + (target ? 1 : -1)).clamp(0, 1 << 30).toInt();
    });
    try {
      final PahtInterestResult result = await _repository.setInterest(
        item.guid,
        interested: target,
      );
      if (!mounted) return;
      setState(() {
        _interested[item.guid] = result.interested;
        _careCounts[item.guid] = result.careCount;
        _followingCount = result.followingCount;
        final PahtForumDetail? cached = _detailCache[item.guid];
        if (cached != null) {
          _detailCache[item.guid] = cached.copyWithInterest(
            interested: result.interested,
            careCount: result.careCount,
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _interested[item.guid] = current;
        _careCounts[item.guid] = oldCare;
        _followingCount = oldFollowing;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _interestBusy.remove(item.guid));
    }
  }

  void _syncInterestState(List<PahtForumItem> items) {
    for (final PahtForumItem item in items) {
      if (_interestBusy.contains(item.guid)) continue;

      // New backend nodes always return `interested`. During a rolling deploy,
      // an older node may omit it; in that case do not replace a known heart
      // state with PahtForumItem's parser default (false).
      if (item.interestStateProvided || !_interested.containsKey(item.guid)) {
        _interested[item.guid] = item.interested;
      }

      // care_count is server-authoritative and is shown directly on the card.
      _careCounts[item.guid] = item.careCount;
    }
  }


  Future<void> _showFilters() async {
    String tempStatus = _status;
    String tempSort = _sort;
    final bool? apply = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Lọc phản ánh',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
                  const Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _SheetChoice(label: 'Tất cả', selected: tempStatus.isEmpty, onTap: () => setSheetState(() => tempStatus = '')),
                      _SheetChoice(label: 'Đã tiếp nhận', selected: tempStatus == 'RECEIVED', onTap: () => setSheetState(() => tempStatus = 'RECEIVED')),
                      _SheetChoice(label: 'Đang xử lý', selected: tempStatus == 'PROCESSING', onTap: () => setSheetState(() => tempStatus = 'PROCESSING')),
                      _SheetChoice(label: 'Đã trả lời', selected: tempStatus == 'ANSWERED', onTap: () => setSheetState(() => tempStatus = 'ANSWERED')),
                      _SheetChoice(label: 'Đã hoàn tất', selected: tempStatus == 'RESOLVED', onTap: () => setSheetState(() => tempStatus = 'RESOLVED')),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Sắp xếp', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _SheetChoice(label: 'Mới nhất', selected: tempSort == 'recent', onTap: () => setSheetState(() => tempSort = 'recent')),
                      _SheetChoice(label: 'Quan tâm nhiều', selected: tempSort == 'care', onTap: () => setSheetState(() => tempSort = 'care')),
                      _SheetChoice(label: 'Cũ nhất', selected: tempSort == 'oldest', onTap: () => setSheetState(() => tempSort = 'oldest')),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: () => setSheetState(() {
                          tempStatus = '';
                          tempSort = 'recent';
                        }),
                        child: const Text('Đặt lại'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(true),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Áp dụng'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (apply == true && mounted) {
      setState(() {
        _status = tempStatus;
        _sort = tempSort;
      });
      _reloadList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<PahtTopic> topics = _bootstrap?.topics ?? <PahtTopic>[];

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 92),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _buildSearch()),
              const SizedBox(width: 8),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _showFilters,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E6E2)),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        const Icon(Icons.tune_rounded, color: Color(0xFF344139)),
                        if (_status.isNotEmpty || _sort != 'recent')
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              width: 17,
                              height: 17,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFF009B5A),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${(_status.isNotEmpty ? 1 : 0) + (_sort != 'recent' ? 1 : 0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (topics.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _RoundRobinTopicFilter(
              topics: topics,
              selectedTopicId: _topicId,
              onSelected: (int? topicId) {
                setState(() => _topicId = topicId);
                _reloadList();
              },
            ),
          ],
          if (_filterBusy) ...<Widget>[
            const SizedBox(height: 6),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(999)),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          ],
          const SizedBox(height: 10),
          _buildAccountStrip(),
          if (_error.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _ErrorPanel(message: _error, onRetry: _loadInitial),
          ],
          const SizedBox(height: 9),
          if (_items.isEmpty && !_loading)
            const _EmptyPanel()
          else
            ..._items.map(
              (PahtForumItem item) => _IncomingFeedbackTile(
                key: ValueKey<String>('paht-feed-${item.guid}'),
                animateArrival: _newArrivalGuids.contains(item.guid),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PahtForumCard(
                    item: item,
                    interested: _interested[item.guid] ?? item.interested,
                    careCountOverride: _careCounts[item.guid] ?? item.careCount,
                    interestBusy: _interestBusy.contains(item.guid),
                    expanded: _expandedGuid == item.guid,
                    detail: _detailCache[item.guid],
                    responseLoading: _expandingGuid == item.guid,
                    onInterestTap: () => _toggleInterest(item),
                    onTap: () => _handleCardTap(item),
                    onDetailTap: () => _openDetail(item),
                  ),
                ),
              ),
            ),
          if (_items.length < _total) ...<Widget>[
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: _loadingMore ? null : _loadMore,
                icon: _loadingMore
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(_loadingMore ? 'Đang tải...' : 'Xem thêm'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountStrip() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        if (widget.showKtxResidence) ...<Widget>[
          Material(
            color: const Color(0xFFEAF8F0),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: widget.onKtxTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFBCE6CE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.home_work_outlined, size: 16, color: Color(0xFF168A52)),
                    SizedBox(width: 4),
                    Text(
                      'Ở KTX',
                      style: TextStyle(
                        fontSize: 10.8,
                        color: Color(0xFF146E43),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
        ],
        Material(
          color: const Color(0xFFF1F8F3),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: widget.onFollowingTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFD4E8DB)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 16,
                    color: Color(0xFF275F42),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_followingCount đang theo dõi',
                    style: const TextStyle(
                      fontSize: 10.8,
                      color: Color(0xFF275F42),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Phản ánh của tôi',
          child: InkWell(
            onTap: widget.onAvatarTap,
            borderRadius: BorderRadius.circular(999),
            child: VcoreProfileAvatarWidget(
              url: widget.avatarUrl,
              size: 36,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Tìm phản ánh...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xóa',
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                  _reloadList();
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E6E2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E6E2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.colorMain.withOpacity(.55)),
        ),
      ),
    );
  }
}


bool _sameForumList(List<PahtForumItem> a, List<PahtForumItem> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (_itemSignature(a[i]) != _itemSignature(b[i])) return false;
  }
  return true;
}

String _itemSignature(PahtForumItem item) {
  final String topics = item.topics
      .map((PahtTopicRef topic) => '${topic.id}:${topic.name}:${topic.primary}')
      .join('|');
  return <Object?>[
    item.guid,
    item.title,
    item.content,
    item.workflowStatus,
    item.careCount,
    item.responseCount,
    item.interested,
    item.hasOfficialAnswer,
    item.thumbnailExternalFileId,
    item.thumbnailStorageKey,
    topics,
  ].join('~');
}

String _detailSignature(PahtForumDetail detail) {
  final String responses = detail.responses
      .map((PahtResponseItem item) =>
          '${item.responseType}:${item.unit}:${item.createdAt?.millisecondsSinceEpoch}:${item.content}')
      .join('|');
  return '${_itemSignature(detail.item)}#$responses#${detail.interested}';
}

class _IncomingFeedbackTile extends StatefulWidget {
  final Widget child;
  final bool animateArrival;

  const _IncomingFeedbackTile({
    super.key,
    required this.child,
    required this.animateArrival,
  });

  @override
  State<_IncomingFeedbackTile> createState() => _IncomingFeedbackTileState();
}

class _IncomingFeedbackTileState extends State<_IncomingFeedbackTile>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<Offset>? _slide;
  Animation<double>? _fade;

  @override
  void initState() {
    super.initState();
    if (widget.animateArrival) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 460),
      );
      final CurvedAnimation curve = CurvedAnimation(
        parent: _controller!,
        curve: Curves.easeOutCubic,
      );
      _slide = Tween<Offset>(
        begin: const Offset(.30, 0),
        end: Offset.zero,
      ).animate(curve);
      _fade = Tween<double>(begin: .25, end: 1).animate(curve);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller?.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) return widget.child;
    return SlideTransition(
      position: _slide!,
      child: FadeTransition(opacity: _fade!, child: widget.child),
    );
  }
}


class _RoundRobinTopicFilter extends StatelessWidget {
  final List<PahtTopic> topics;
  final int? selectedTopicId;
  final ValueChanged<int?> onSelected;

  const _RoundRobinTopicFilter({
    required this.topics,
    required this.selectedTopicId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = <Widget>[
      _TopicChip(
        label: 'Tất cả',
        selected: selectedTopicId == null,
        visual: const PahtTopicVisual(
          color: Color(0xFF009B5A),
          softColor: Color(0xFFE8F7F0),
          icon: Icons.apps_rounded,
        ),
        onTap: () {
          if (selectedTopicId != null) onSelected(null);
        },
      ),
    ];
    for (final PahtTopic topic in topics) {
      final PahtTopicVisual visual = pahtTopicVisual(
        topicId: topic.id,
        topicName: topic.name,
      );
      chips.add(
        Padding(
          padding: const EdgeInsets.only(left: 7),
          child: _TopicChip(
            label: topic.name,
            selected: selectedTopicId == topic.id,
            visual: visual,
            onTap: () => onSelected(
              selectedTopicId == topic.id ? null : topic.id,
            ),
          ),
        ),
      );
    }

    // Thanh chọn chủ đề phía trên chỉ cuộn bằng tay, không tự chạy/không lặp.
    return SizedBox(
      height: 38,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(mainAxisSize: MainAxisSize.min, children: chips),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  final bool selected;
  final PahtTopicVisual visual;
  final VoidCallback onTap;

  const _TopicChip({
    required this.label,
    required this.selected,
    required this.visual,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? visual.softColor : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? visual.color.withOpacity(.7) : const Color(0xFFE0E6E2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(visual.icon, size: 14, color: visual.color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? visual.color : const Color(0xFF46534C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFE8F7F0),
      side: BorderSide(
        color: selected ? const Color(0xFF65B98D) : const Color(0xFFE1E6E3),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, color: Color(0xFFA84444), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis)),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E9E6)),
      ),
      child: const Column(
        children: <Widget>[
          Icon(Icons.forum_outlined, size: 36, color: Color(0xFF8B9790)),
          SizedBox(height: 9),
          Text('Chưa có phản ánh phù hợp', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
