import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/modules/paht_v2/ktx/models/ktx_issue_models.dart';
import 'package:vnu_core/modules/paht_v2/ktx/repository/ktx_issue_repository.dart';
import 'package:vnu_core/modules/paht_v2/ktx/views/ktx_issue_detail_view.dart';
import 'package:vnu_core/modules/paht_v2/ktx/widgets/ktx_issue_card.dart';

class KtxIssueListView extends StatefulWidget {
  final int reloadToken;

  const KtxIssueListView({
    super.key,
    this.reloadToken = 0,
  });

  @override
  State<KtxIssueListView> createState() => _KtxIssueListViewState();
}

class _KtxIssueListViewState extends State<KtxIssueListView>
    with AutomaticKeepAliveClientMixin<KtxIssueListView> {
  final KtxIssueRepository _repository = KtxIssueRepository();
  final ScrollController _scrollController = ScrollController();

  List<KtxIssue> _items = <KtxIssue>[];
  KtxIssueMeta? _meta;
  String? _nextPageUrl;
  String? _errorMessage;

  bool _loading = true;
  bool _loadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void didUpdateWidget(covariant KtxIssueListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) {
      _load(reset: true);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _loading ||
        _loadingMore ||
        _nextPageUrl == null) {
      return;
    }

    if (_scrollController.position.extentAfter < 280) {
      _loadMore();
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    KtxIssueMeta? meta = _meta;
    try {
      meta ??= await _repository.getMeta();
    } catch (_) {
      // Danh sách vẫn có thể sử dụng nếu metadata tạm thời lỗi.
    }

    try {
      final KtxIssuePage page = await _repository.getIssues();

      if (!mounted) return;
      setState(() {
        _meta = meta;
        _items = page.items;
        _nextPageUrl = page.nextPageUrl;
        _loading = false;
        _errorMessage = null;
      });
    } on KtxIssueApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _meta = meta;
        _loading = false;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _meta = meta;
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    final String? next = _nextPageUrl;
    if (next == null || _loadingMore) return;

    setState(() => _loadingMore = true);

    try {
      final KtxIssuePage page =
          await _repository.getIssues(nextPageUrl: next);

      if (!mounted) return;

      final Map<int, KtxIssue> merged = <int, KtxIssue>{
        for (final KtxIssue item in _items) item.id: item,
        for (final KtxIssue item in page.items) item.id: item,
      };

      setState(() {
        _items = merged.values.toList();
        _nextPageUrl = page.nextPageUrl;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _openIssue(KtxIssue issue) async {
    await Get.to(
      () => KtxIssueDetailView(issueId: issue.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF078B3E)),
      );
    }

    final String? error = _errorMessage;
    if (error != null && _items.isEmpty) {
      return _ErrorState(
        message: error,
        onRetry: () => _load(reset: true),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF078B3E),
      onRefresh: () => _load(reset: true),
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: <Widget>[
          const _KtxIntroCard(),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Phản ánh của tôi',
                  style: TextStyle(
                    color: Color(0xFF17201A),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${_items.length}',
                style: const TextStyle(
                  color: Color(0xFF078B3E),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (error != null) ...<Widget>[
            _InlineWarning(
              message: error,
              onRetry: () => _load(reset: true),
            ),
            const SizedBox(height: 10),
          ],
          if (_items.isEmpty)
            const _EmptyState()
          else
            ..._items.expand(
              (KtxIssue issue) sync* {
                yield KtxIssueCard(
                  issue: issue,
                  meta: _meta,
                  onTap: () => _openIssue(issue),
                );
                yield const SizedBox(height: 10);
              },
            ),
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF078B3E),
                  strokeWidth: 2.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KtxIntroCard extends StatelessWidget {
  const _KtxIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFFE8F6ED),
            Color(0xFFF7FBF8),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5EBDD)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.home_work_outlined,
            color: Color(0xFF078B3E),
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Khu vực này chỉ hiển thị phản ánh gửi tới hệ thống Ký túc xá. '
              'Dữ liệu không trộn với phản ánh ĐHQGHN.',
              style: TextStyle(
                color: Color(0xFF45604E),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E8E5)),
      ),
      child: const Column(
        children: <Widget>[
          Icon(
            Icons.mark_chat_unread_outlined,
            color: Color(0xFF829087),
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'Chưa có phản ánh KTX',
            style: TextStyle(
              color: Color(0xFF263029),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Nhấn nút + ở góc dưới để gửi phản ánh mới.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7A857E),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SizedBox(height: 60),
        const Icon(
          Icons.cloud_off_rounded,
          color: Color(0xFF9AA39E),
          size: 52,
        ),
        const SizedBox(height: 14),
        const Text(
          'Không tải được phản ánh KTX',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF253029),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF748078),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF078B3E),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineWarning extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineWarning({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0DCAA)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFB47700),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7B5B16),
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }
}
