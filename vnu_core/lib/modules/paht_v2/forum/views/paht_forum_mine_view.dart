import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/modules/paht_v2/forum/models/paht_forum_models.dart';
import 'package:vnu_core/modules/paht_v2/forum/repository/paht_forum_repository.dart';
import 'package:vnu_core/modules/paht_v2/forum/views/paht_forum_detail_view.dart';
import 'package:vnu_core/modules/paht_v2/forum/widgets/paht_forum_card.dart';
import 'package:vnu_core/widgets/vcore_action_dialog.dart';
import 'package:vnu_core/widgets/vcore_notice_toast.dart';

class PahtForumMineView extends StatefulWidget {
  const PahtForumMineView({super.key});

  @override
  State<PahtForumMineView> createState() => _PahtForumMineViewState();
}

class _PahtForumMineViewState extends State<PahtForumMineView> {
  final PahtForumRepository _repository = PahtForumRepository();
  final Map<String, PahtForumDetail> _detailCache = <String, PahtForumDetail>{};
  List<PahtForumItem> _items = <PahtForumItem>[];
  String? _expandedGuid;
  String? _loadingDetailGuid;
  String? _deletingGuid;
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
      final PahtForumPage page = await _repository.getMine();
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _total = page.total;
        _page = page.page;
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
      final PahtForumPage page = await _repository.getMine(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items = <PahtForumItem>[..._items, ...page.items];
        _total = page.total;
        _page = page.page;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      showVcoreNotice(
        context: context,
        title: 'Không tải thêm được phản ánh',
        message: error.toString(),
        tone: VcoreNoticeTone.error,
      );
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
      PahtForumDetail detail = await _repository.getDetail(item.guid);
      if ((item.hasOfficialAnswer || item.responseCount > 0) &&
          detail.responses.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 240));
        detail = await _repository.getDetail(item.guid);
      }
      if (!mounted || _expandedGuid != item.guid) return;
      setState(() => _detailCache[item.guid] = detail);
    } catch (error) {
      if (!mounted || _expandedGuid != item.guid) return;
      showVcoreNotice(
        context: context,
        title: 'Không tải được phản hồi',
        message: error.toString(),
        tone: VcoreNoticeTone.error,
      );
    } finally {
      if (mounted && _loadingDetailGuid == item.guid) {
        setState(() => _loadingDetailGuid = null);
      }
    }
  }

  Future<void> _deleteOwnFeedback(PahtForumItem item) async {
    if (!item.canDelete || _deletingGuid != null || !mounted) return;

    final bool? confirmed = await showVcoreActionDialog<bool>(
      context: context,
      title: 'Xóa phản ánh?',
      content: item.code.trim().isEmpty
          ? 'Phản ánh chưa có người trả lời nên bạn có thể xóa. Sau khi xóa, phản ánh sẽ không còn xuất hiện trong Cộng đồng hoặc Phản ánh của tôi.'
          : 'Phản ánh ${item.code} chưa có người trả lời nên bạn có thể xóa. Sau khi xóa, phản ánh sẽ không còn xuất hiện trong Cộng đồng hoặc Phản ánh của tôi.',
      leadingIcon: Icons.delete_outline_rounded,
      actions: const <VcoreDialogAction<bool>>[
        VcoreDialogAction<bool>(
          label: 'Giữ lại',
          value: false,
          tone: VcoreDialogActionTone.secondary,
        ),
        VcoreDialogAction<bool>(
          label: 'Xóa phản ánh',
          value: true,
          icon: Icons.delete_outline_rounded,
          tone: VcoreDialogActionTone.danger,
        ),
      ],
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingGuid = item.guid);
    try {
      final Map<String, dynamic> result =
          await _repository.deleteOwnFeedback(item.guid);
      if (!mounted) return;
      final String code = (result['code'] ?? item.code).toString().trim();
      setState(() {
        _items = _items.where((PahtForumItem value) => value.guid != item.guid).toList(growable: false);
        _total = _total > 0 ? _total - 1 : 0;
        _detailCache.remove(item.guid);
        if (_expandedGuid == item.guid) _expandedGuid = null;
        _deletingGuid = null;
      });
      showVcoreNotice(
        context: context,
        title: 'Đã xóa phản ánh',
        message: code.isEmpty
            ? 'Phản ánh đã được xóa thành công.'
            : 'Đã xóa phản ánh $code.',
        tone: VcoreNoticeTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _deletingGuid = null);
      showVcoreNotice(
        context: context,
        title: 'Chưa thể xóa phản ánh',
        message: error.toString(),
        tone: VcoreNoticeTone.error,
        duration: const Duration(milliseconds: 3400),
      );
      // Trường hợp đơn vị vừa phản hồi trong lúc người dùng đang mở màn hình,
      // tải lại để canDelete/response_count phản ánh trạng thái server mới nhất.
      await _load();
    }
  }

  Future<void> _openDetail(PahtForumItem item) async {
    await Get.to(() => PahtForumDetailView(guid: item.guid));
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
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8F6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE1E8E3)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.person_outline_rounded, color: Color(0xFF41614E)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _total == 0
                        ? 'Các phản ánh bạn đã gửi sẽ xuất hiện tại đây.'
                        : 'Bạn đã gửi $_total phản ánh. Phản ánh riêng tư chỉ hiển thị với bạn và cán bộ xử lý.',
                    style: const TextStyle(
                      color: Color(0xFF53645A),
                      fontSize: 12.5,
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
                  Icon(Icons.inbox_outlined, size: 40, color: Color(0xFF8B9890)),
                  SizedBox(height: 10),
                  Text('Bạn chưa gửi phản ánh nào', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 5),
                  Text(
                    'Nhấn “Tạo phản ánh” để gửi phản ánh mới.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF748179)),
                  ),
                ],
              ),
            )
          else
            ..._items.map(
              (PahtForumItem item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PahtForumCard(
                  item: item,
                  showVisibility: true,
                  expanded: _expandedGuid == item.guid,
                  detail: _detailCache[item.guid],
                  responseLoading: _loadingDetailGuid == item.guid,
                  onTap: () => _handleCardTap(item),
                  onDetailTap: () => _openDetail(item),
                  onDeleteTap: item.canDelete ? () => _deleteOwnFeedback(item) : null,
                  deleteBusy: _deletingGuid == item.guid,
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
