import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/modules/paht_v2/forum/models/paht_forum_models.dart';
import 'package:vnu_core/modules/paht_v2/forum/repository/paht_forum_repository.dart';
import 'package:vnu_core/modules/paht_v2/forum/views/paht_forum_detail_view.dart';
import 'package:vnu_core/modules/paht_v2/forum/widgets/paht_forum_card.dart';

class PahtForumFollowingView extends StatefulWidget {
  const PahtForumFollowingView({super.key});

  @override
  State<PahtForumFollowingView> createState() => _PahtForumFollowingViewState();
}

class _PahtForumFollowingViewState extends State<PahtForumFollowingView> {
  final PahtForumRepository _repository = PahtForumRepository();
  final Map<String, PahtForumDetail> _detailCache = <String, PahtForumDetail>{};
  final Map<String, int> _careCounts = <String, int>{};
  final Set<String> _interestBusy = <String>{};

  List<PahtForumItem> _items = <PahtForumItem>[];
  String? _expandedGuid;
  String? _loadingDetailGuid;
  int _total = 0;
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }
    try {
      final PahtForumPage page = await _repository.getFollowing();
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _total = page.total;
        _page = page.page;
        _careCounts
          ..clear()
          ..addEntries(page.items.map((PahtForumItem e) => MapEntry(e.guid, e.careCount)));
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _items.length >= _total) return;
    setState(() => _loadingMore = true);
    try {
      final PahtForumPage page = await _repository.getFollowing(page: _page + 1);
      if (!mounted) return;
      final Set<String> existing = _items.map((PahtForumItem e) => e.guid).toSet();
      final List<PahtForumItem> incoming = page.items
          .where((PahtForumItem e) => existing.add(e.guid))
          .toList(growable: false);
      setState(() {
        _items = <PahtForumItem>[..._items, ...incoming];
        for (final PahtForumItem item in incoming) {
          _careCounts[item.guid] = item.careCount;
        }
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

  Future<void> _toggleInterest(PahtForumItem item) async {
    if (_interestBusy.contains(item.guid)) return;
    final int oldCare = _careCounts[item.guid] ?? item.careCount;
    setState(() {
      _interestBusy.add(item.guid);
      _careCounts[item.guid] = (oldCare - 1).clamp(0, 1 << 30).toInt();
    });
    try {
      final PahtInterestResult result = await _repository.setInterest(
        item.guid,
        interested: false,
      );
      if (!mounted) return;
      setState(() {
        _careCounts[item.guid] = result.careCount;
        if (!result.interested) {
          _items = _items.where((PahtForumItem e) => e.guid != item.guid).toList(growable: false);
          _total = result.followingCount;
          _detailCache.remove(item.guid);
          if (_expandedGuid == item.guid) _expandedGuid = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _careCounts[item.guid] = oldCare);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _interestBusy.remove(item.guid));
    }
  }

  Future<void> _handleCardTap(PahtForumItem item) async {
    if (_expandedGuid == item.guid) {
      setState(() => _expandedGuid = null);
      return;
    }
    setState(() {
      _expandedGuid = item.guid;
      if (!_detailCache.containsKey(item.guid)) _loadingDetailGuid = item.guid;
    });
    try {
      PahtForumDetail detail = await _repository.getPublicDetail(item.guid);
      if (item.hasOfficialAnswer && detail.responses.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 240));
        detail = await _repository.getPublicDetail(item.guid);
      }
      if (!mounted || _expandedGuid != item.guid) return;
      setState(() {
        _detailCache[item.guid] = detail;
        _careCounts[item.guid] = detail.item.careCount;
      });
    } catch (error) {
      if (!mounted || _expandedGuid != item.guid) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted && _loadingDetailGuid == item.guid) {
        setState(() => _loadingDetailGuid = null);
      }
    }
  }

  Future<void> _openDetail(PahtForumItem item) async {
    await Get.to(() => PahtForumDetailView(guid: item.guid, publicOnly: true));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F9F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDE9E0)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.favorite_rounded, color: Color(0xFFE24B63)),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _total == 0
                        ? 'Nhấn biểu tượng tim ở phản ánh cộng đồng để theo dõi.'
                        : 'Bạn đang theo dõi $_total phản ánh. Nhấn tim lần nữa để bỏ theo dõi.',
                    style: const TextStyle(
                      color: Color(0xFF53645A),
                      fontSize: 12.3,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFA84444)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error)),
                  TextButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (_items.isEmpty && !_loading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7ECE9)),
              ),
              child: const Column(
                children: <Widget>[
                  Icon(Icons.favorite_border_rounded, size: 40, color: Color(0xFF8B9890)),
                  SizedBox(height: 10),
                  Text('Chưa theo dõi phản ánh nào', style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            )
          else
            ..._items.map(
              (PahtForumItem item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PahtForumCard(
                  item: item,
                  interested: true,
                  careCountOverride: _careCounts[item.guid] ?? item.careCount,
                  interestBusy: _interestBusy.contains(item.guid),
                  expanded: _expandedGuid == item.guid,
                  detail: _detailCache[item.guid],
                  responseLoading: _loadingDetailGuid == item.guid,
                  onInterestTap: () => _toggleInterest(item),
                  onTap: () => _handleCardTap(item),
                  onDetailTap: () => _openDetail(item),
                ),
              ),
            ),
          if (_items.length < _total) ...<Widget>[
            const SizedBox(height: 4),
            Center(
              child: OutlinedButton.icon(
                onPressed: _loadingMore ? null : _loadMore,
                icon: _loadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
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
}
