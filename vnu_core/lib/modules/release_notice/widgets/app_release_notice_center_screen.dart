import 'package:flutter/material.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/modules/release_notice/models/app_release_notice.dart';
import 'package:vnu_core/modules/release_notice/services/app_release_notice_service.dart';

class AppReleaseNoticeCenterScreen extends StatefulWidget {
  const AppReleaseNoticeCenterScreen({
    super.key,
    required this.notices,
  });

  final List<AppReleaseNotice> notices;

  @override
  State<AppReleaseNoticeCenterScreen> createState() =>
      _AppReleaseNoticeCenterScreenState();
}

class _AppReleaseNoticeCenterScreenState
    extends State<AppReleaseNoticeCenterScreen> {
  static const Color _green = Color(0xFF07964B);
  static const Color _greenDark = Color(0xFF075C34);
  static const Color _ink = Color(0xFF101936);
  static const Color _muted = Color(0xFF6F7789);
  static const Color _surface = Color(0xFFF4F7F6);
  static const Color _border = Color(0xFFE0E8E4);

  final Set<String> _acknowledged = <String>{};
  bool _saving = false;

  String _key(AppReleaseNotice notice) =>
      '${notice.code}_${notice.id}_${notice.revision}';

  bool _isAcknowledged(AppReleaseNotice notice) =>
      _acknowledged.contains(_key(notice));

  bool get _requiredComplete => widget.notices
      .where((AppReleaseNotice notice) => notice.requiredAck)
      .every(_isAcknowledged);

  int get _doneCount => widget.notices.where(_isAcknowledged).length;

  Future<void> _openNotice(AppReleaseNotice notice) async {
    final bool? accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => AppReleaseNoticeQuestScreen(notice: notice),
      ),
    );

    if (accepted != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await AppReleaseNoticeService().acknowledge(notice);
      if (!mounted) return;
      setState(() => _acknowledged.add(_key(notice)));
    } catch (error, stackTrace) {
      // acknowledge() already keeps local ack best-effort, but guard this UI
      // too so a logging/network issue never traps the user in the notice hub.
      logError(
        '[RELEASE_NOTICE_CENTER] acknowledge failed '
        'code=${notice.code} revision=${notice.revision} '
        'error=$error\n$stackTrace',
      );
      if (!mounted) return;
      setState(() => _acknowledged.add(_key(notice)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _continue() {
    if (!_requiredComplete || _saving) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final int requiredRemaining = widget.notices
        .where((AppReleaseNotice n) => n.requiredAck && !_isAcknowledged(n))
        .length;

    return PopScope(
      canPop: _requiredComplete,
      onPopInvoked: (bool didPop) {
        if (!didPop && requiredRemaining > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Vui lòng đọc và xác nhận các thông báo bắt buộc trước khi tiếp tục.',
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _ink,
          elevation: 0,
          automaticallyImplyLeading: _requiredComplete,
          titleSpacing: 20,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Trung tâm thông báo',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              Text(
                'Những thay đổi quan trọng của OneVNU',
                style: TextStyle(fontSize: 11.5, color: _muted),
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              _header(requiredRemaining),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
                  itemCount: widget.notices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final AppReleaseNotice notice = widget.notices[index];
                    return _noticeCard(notice, index);
                  },
                ),
              ),
              _footer(requiredRemaining),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(int requiredRemaining) {
    final double progress = widget.notices.isEmpty
        ? 1
        : _doneCount / widget.notices.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _greenDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _greenDark.withOpacity(.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.auto_stories_outlined,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'CẬP NHẬT PHIÊN BẢN',
                      style: TextStyle(
                        color: Color(0xFF8FE0B4),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: .9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      requiredRemaining > 0
                          ? '$requiredRemaining thông báo cần bạn xác nhận'
                          : 'Bạn đã hoàn thành các thông báo bắt buộc',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(.13),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF39D27C),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Đã đọc $_doneCount/${widget.notices.length}',
            style: TextStyle(
              color: Colors.white.withOpacity(.76),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeCard(AppReleaseNotice notice, int index) {
    final bool done = _isAcknowledged(notice);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _saving ? null : () => _openNotice(notice),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: done ? const Color(0xFFBFE9D0) : _border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFFEAF8F0)
                      : const Color(0xFFF0F5F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  done ? Icons.check_circle_outline : Icons.campaign_outlined,
                  color: _green,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        _chip(done ? 'ĐÃ ĐỌC' : 'MỚI', done),
                        if (notice.requiredAck) _chip('BẮT BUỘC', false),
                        _chip('REV ${notice.revision}', false),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      notice.title,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.25,
                      ),
                    ),
                    if (notice.summary.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 7),
                      Text(
                        notice.summary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12.5,
                          height: 1.42,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Text(
                          done ? 'Xem lại nội dung' : 'Xem chi tiết',
                          style: const TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 17, color: _green),
                      ],
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

  Widget _chip(String text, bool done) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFEAF8F0) : const Color(0xFFF1F4F3),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: done ? _greenDark : _muted,
          fontWeight: FontWeight.w800,
          fontSize: 9.5,
          letterSpacing: .3,
        ),
      ),
    );
  }

  Widget _footer(int requiredRemaining) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: _requiredComplete && !_saving ? _continue : null,
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              disabledBackgroundColor: const Color(0xFFD9E2DE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              requiredRemaining > 0
                  ? 'Còn $requiredRemaining thông báo bắt buộc'
                  : 'Tiếp tục đăng nhập',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

class AppReleaseNoticeQuestScreen extends StatefulWidget {
  const AppReleaseNoticeQuestScreen({
    super.key,
    required this.notice,
  });

  final AppReleaseNotice notice;

  @override
  State<AppReleaseNoticeQuestScreen> createState() =>
      _AppReleaseNoticeQuestScreenState();
}

class _AppReleaseNoticeQuestScreenState
    extends State<AppReleaseNoticeQuestScreen> {
  static const Color _green = Color(0xFF07964B);
  static const Color _greenDark = Color(0xFF075C34);
  static const Color _ink = Color(0xFF101936);
  static const Color _muted = Color(0xFF6F7789);
  static const Color _surface = Color(0xFFF4F7F6);
  static const Color _border = Color(0xFFE0E8E4);

  late final PageController _pageController;
  late final List<_QuestPageData> _pages;
  late final List<bool> _readToEnd;
  int _index = 0;
  int _maxVisited = 0;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = _buildPages(widget.notice);
    _readToEnd = List<bool>.filled(_pages.length, false);
    if (!widget.notice.requireScrollEnd && _readToEnd.isNotEmpty) {
      for (int i = 0; i < _readToEnd.length; i++) {
        _readToEnd[i] = true;
      }
    }
    _accepted = !widget.notice.requiredAck;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _currentRead =>
      !widget.notice.requireScrollEnd || _readToEnd[_index];

  bool get _canFinish =>
      _currentRead && (!widget.notice.requiredAck || _accepted);

  Future<void> _goTo(int next) async {
    if (next < 0 || next >= _pages.length) return;
    if (next > _index && !_currentRead) return;
    if (next > _maxVisited + 1) return;
    _maxVisited = next > _maxVisited ? next : _maxVisited;
    await _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _markRead(int pageIndex, bool reached) {
    if (!mounted || !reached || _readToEnd[pageIndex]) return;
    setState(() => _readToEnd[pageIndex] = true);
  }

  void _finish() {
    if (!_canFinish) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final _QuestPageData current = _pages[_index];
    final double progress = (_index + 1) / _pages.length;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Chi tiết cập nhật',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              'Mục ${_index + 1}/${_pages.length}',
              style: const TextStyle(fontSize: 11.5, color: _muted),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Column(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE4EBE7),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_green),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 58,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int i) {
                        final bool active = i == _index;
                        final bool visited = i <= _maxVisited;
                        final bool enabled = i <= _maxVisited + 1 &&
                            (i <= _index || _currentRead);
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: enabled ? () => _goTo(i) : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 116,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFFE9F7EF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF9DD9B7)
                                    : _border,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: visited || active
                                        ? _green
                                        : const Color(0xFFEEF2F0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: visited || active
                                            ? Colors.white
                                            : _muted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    _pages[i].label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: active ? _greenDark : _ink,
                                      fontSize: 10.8,
                                      fontWeight: FontWeight.w700,
                                      height: 1.12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pages.length,
                onPageChanged: (int value) {
                  setState(() {
                    _index = value;
                    if (value > _maxVisited) _maxVisited = value;
                  });
                },
                itemBuilder: (BuildContext context, int pageIndex) {
                  final _QuestPageData page = _pages[pageIndex];
                  return _QuestScrollablePage(
                    key: ValueKey<String>('${widget.notice.code}_$pageIndex'),
                    page: page,
                    requireScrollEnd: widget.notice.requireScrollEnd,
                    onReadStateChanged: (bool reached) =>
                        _markRead(pageIndex, reached),
                    childAfterContent: page.isAcknowledgement
                        ? _acknowledgementBox()
                        : null,
                  );
                },
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 14),
              child: SafeArea(
                top: false,
                child: Row(
                  children: <Widget>[
                    if (_index > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _goTo(_index - 1),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Trước'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _greenDark,
                            side: const BorderSide(color: _border),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    if (_index > 0) const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _index == _pages.length - 1
                            ? (_canFinish ? _finish : null)
                            : (_currentRead
                                ? () => _goTo(_index + 1)
                                : null),
                        icon: Icon(
                          _index == _pages.length - 1
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _index == _pages.length - 1
                              ? widget.notice.primaryActionLabel
                              : 'Tiếp tục',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          disabledBackgroundColor: const Color(0xFFD9E2DE),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
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

  Widget _acknowledgementBox() {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF8F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBE8D7)),
      ),
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: _green,
        value: _accepted,
        onChanged: widget.notice.requiredAck
            ? (bool? value) => setState(() => _accepted = value == true)
            : null,
        title: Text(
          widget.notice.acknowledgementText,
          style: const TextStyle(
            color: _greenDark,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  List<_QuestPageData> _buildPages(AppReleaseNotice notice) {
    final List<_QuestPageData> pages = <_QuestPageData>[];
    pages.add(
      _QuestPageData(
        label: 'Tổng quan',
        kicker: 'BẢN CẬP NHẬT',
        icon: Icons.auto_awesome_outlined,
        title: notice.title,
        content: notice.summary.isEmpty
            ? 'OneVNU có một thay đổi mới cần bạn lưu ý.'
            : notice.summary,
      ),
    );
    _addIfContent(
      pages,
      label: 'Điểm mới',
      kicker: '01 · THAY ĐỔI',
      icon: Icons.new_releases_outlined,
      title: notice.changeTitle,
      content: notice.changeContent,
    );
    _addIfContent(
      pages,
      label: 'Lý do',
      kicker: '02 · VÌ SAO',
      icon: Icons.lightbulb_outline_rounded,
      title: notice.reasonTitle,
      content: notice.reasonContent,
    );
    _addIfContent(
      pages,
      label: 'Ảnh hưởng',
      kicker: '03 · CẦN LƯU Ý',
      icon: Icons.devices_other_outlined,
      title: notice.impactTitle,
      content: notice.impactContent,
    );
    _addIfContent(
      pages,
      label: 'Hướng dẫn',
      kicker: '04 · CÁCH XỬ LÝ',
      icon: Icons.route_outlined,
      title: notice.actionTitle,
      content: notice.actionContent,
    );
    pages.add(
      _QuestPageData(
        label: 'Xác nhận',
        kicker: 'HOÀN THÀNH',
        icon: Icons.verified_user_outlined,
        title: 'Xác nhận bạn đã hiểu',
        content: notice.acknowledgementText,
        isAcknowledgement: true,
      ),
    );
    return pages;
  }

  void _addIfContent(
    List<_QuestPageData> pages, {
    required String label,
    required String kicker,
    required IconData icon,
    required String title,
    required String content,
  }) {
    if (content.trim().isEmpty && title.trim().isEmpty) return;
    pages.add(
      _QuestPageData(
        label: label,
        kicker: kicker,
        icon: icon,
        title: title.trim().isEmpty ? label : title,
        content: content.trim().isEmpty ? 'Không có nội dung bổ sung.' : content,
      ),
    );
  }
}

class _QuestScrollablePage extends StatefulWidget {
  const _QuestScrollablePage({
    super.key,
    required this.page,
    required this.requireScrollEnd,
    required this.onReadStateChanged,
    this.childAfterContent,
  });

  final _QuestPageData page;
  final bool requireScrollEnd;
  final ValueChanged<bool> onReadStateChanged;
  final Widget? childAfterContent;

  @override
  State<_QuestScrollablePage> createState() => _QuestScrollablePageState();
}

class _QuestScrollablePageState extends State<_QuestScrollablePage> {
  final ScrollController _controller = ScrollController();
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_check)
      ..dispose();
    super.dispose();
  }

  void _check() {
    if (_reported || !mounted) return;
    if (!widget.requireScrollEnd) {
      _reported = true;
      widget.onReadStateChanged(true);
      return;
    }
    if (!_controller.hasClients) return;
    final ScrollPosition p = _controller.position;
    if (p.maxScrollExtent <= 6 || p.pixels >= p.maxScrollExtent - 18) {
      _reported = true;
      widget.onReadStateChanged(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
      child: Container(
        constraints: const BoxConstraints(minHeight: 360),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE0E8E4)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF10271D).withOpacity(.07),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F0),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(widget.page.icon, color: const Color(0xFF07964B)),
            ),
            const SizedBox(height: 18),
            Text(
              widget.page.kicker,
              style: const TextStyle(
                color: Color(0xFF07964B),
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.page.title,
              style: const TextStyle(
                color: Color(0xFF101936),
                fontSize: 24,
                height: 1.18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.page.content,
              style: const TextStyle(
                color: Color(0xFF4C586A),
                fontSize: 14,
                height: 1.62,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.childAfterContent != null) widget.childAfterContent!,
            if (widget.requireScrollEnd) ...<Widget>[
              const SizedBox(height: 26),
              const Divider(color: Color(0xFFE0E8E4)),
              const SizedBox(height: 12),
              const Row(
                children: <Widget>[
                  Icon(Icons.keyboard_double_arrow_down_rounded,
                      color: Color(0xFF879187), size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Đọc đến cuối mục này để mở bước tiếp theo.',
                      style: TextStyle(
                        color: Color(0xFF7A847D),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestPageData {
  const _QuestPageData({
    required this.label,
    required this.kicker,
    required this.icon,
    required this.title,
    required this.content,
    this.isAcknowledgement = false,
  });

  final String label;
  final String kicker;
  final IconData icon;
  final String title;
  final String content;
  final bool isAcknowledgement;
}
