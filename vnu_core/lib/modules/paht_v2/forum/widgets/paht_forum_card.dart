import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/modules/paht_v2/forum/models/paht_forum_models.dart';
import 'package:vnu_core/modules/paht_v2/forum/widgets/paht_heart_toggle.dart';
import 'package:vnu_core/modules/paht_v2/forum/widgets/paht_topic_visual.dart';
import 'package:vnu_core/services/services_url.dart';

class PahtForumCard extends StatelessWidget {
  final PahtForumItem item;
  final VoidCallback onTap;
  final VoidCallback? onInterestTap;
  final VoidCallback? onDetailTap;
  final VoidCallback? onDeleteTap;
  final bool deleteBusy;
  final bool? interested;
  final int? careCountOverride;
  final bool interestBusy;
  final bool showVisibility;
  final bool expanded;
  final bool responseLoading;
  final PahtForumDetail? detail;

  const PahtForumCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onInterestTap,
    this.onDetailTap,
    this.onDeleteTap,
    this.deleteBusy = false,
    this.interested,
    this.careCountOverride,
    this.interestBusy = false,
    this.showVisibility = false,
    this.expanded = false,
    this.responseLoading = false,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final PahtTopicRef primaryTopic = _primaryTopic(item);
    final PahtTopicVisual primaryVisual = pahtTopicVisual(
      topicId: primaryTopic.id == 0 ? item.topicId : primaryTopic.id,
      topicName: primaryTopic.name.isEmpty ? item.topicName : primaryTopic.name,
    );
    // Chỉ OFFICIAL_ANSWER công khai mới được coi là "đã trả lời".
    final bool answered = item.hasOfficialAnswer;
    final int careCount = careCountOverride ?? item.careCount;
    final bool following = interested ?? item.interested;
    final int responseCount = detail?.responses.length ?? item.responseCount;

    // Không dùng IntrinsicHeight ở trong ListView/SliverList. Rail được stretch bằng
    // Positioned theo chính chiều cao thật của card + phần phản hồi mở rộng.
    return Stack(
      children: <Widget>[
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: _FeedbackRail(
            color: primaryVisual.color,
            answered: answered,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 31),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 11, 11, 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFDDE5E0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _FeedbackThumbnail(item: item, visual: primaryVisual),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Expanded(child: _RoundRobinTagStrip(item: item)),
                                      const SizedBox(width: 7),
                                      Text(
                                        _compactDate(item.createdAt),
                                        style: const TextStyle(
                                          fontSize: 10.4,
                                          color: Color(0xFF7A867F),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          item.title.isEmpty ? item.content : item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF17201B),
                                            fontSize: 14.3,
                                            height: 1.25,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      if (answered) ...<Widget>[
                                        const SizedBox(width: 5),
                                        Tooltip(
                                          message: 'Đã có trả lời chính thức',
                                          child: Icon(
                                            Icons.mark_chat_read_rounded,
                                            size: 17,
                                            color: primaryVisual.color,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (item.content.trim().isNotEmpty &&
                                      item.content.trim() != item.title.trim()) ...<Widget>[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.content.trim(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF536159),
                                        fontSize: 12.0,
                                        height: 1.38,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (showVisibility) ...<Widget>[
                          const SizedBox(height: 5),
                          Row(
                            children: <Widget>[
                              Icon(
                                item.visibility == 'PRIVATE'
                                    ? Icons.lock_outline_rounded
                                    : Icons.public_rounded,
                                size: 13,
                                color: const Color(0xFF7A867F),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pahtVisibilityLabel(item.visibility),
                                style: const TextStyle(
                                  fontSize: 10.8,
                                  color: Color(0xFF7A867F),
                                ),
                              ),
                              const Spacer(),
                              if (item.canDelete && onDeleteTap != null)
                                _DeleteAction(
                                  busy: deleteBusy,
                                  onTap: deleteBusy ? null : onDeleteTap,
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        const Divider(height: 1, color: Color(0xFFE7ECE9)),
                        const SizedBox(height: 3),
                        Row(
                          children: <Widget>[
                            PahtHeartToggle(
                              active: following,
                              count: careCount,
                              busy: interestBusy,
                              iconSize: 17,
                              onTap: item.visibility != 'PRIVATE' && !interestBusy
                                  ? onInterestTap
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            _Metric(
                              icon: responseCount > 0
                                  ? Icons.mark_chat_read_rounded
                                  : Icons.chat_bubble_outline_rounded,
                              text: '$responseCount phản hồi',
                              color: responseCount > 0
                                  ? primaryVisual.color
                                  : const Color(0xFF718078),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                reverseDuration: const Duration(milliseconds: 230),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                clipBehavior: Clip.hardEdge,
                child: expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            final Animation<Offset> slide = Tween<Offset>(
                              begin: const Offset(0, -0.035),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ));
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(position: slide, child: child),
                            );
                          },
                          child: _InlineResponses(
                            key: ValueKey<String>('responses-${item.guid}-$responseLoading-${detail?.responses.length ?? -1}'),
                            visual: primaryVisual,
                            detail: detail,
                            loading: responseLoading,
                            onDetailTap: onDetailTap,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeleteAction extends StatelessWidget {
  final bool busy;
  final VoidCallback? onTap;

  const _DeleteAction({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Xóa phản ánh',
      child: Material(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 27,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (busy)
                    const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 1.7),
                    )
                  else
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 15,
                      color: Color(0xFFA44444),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    busy ? 'Đang xóa' : 'Xóa',
                    style: const TextStyle(
                      color: Color(0xFFA44444),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackRail extends StatelessWidget {
  final Color color;
  final bool answered;

  const _FeedbackRail({required this.color, required this.answered});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 31,
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Positioned(
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: const Color(0xFFDDE5E0)),
          ),
          Positioned(
            top: 17,
            child: answered
                ? Container(
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: color.withOpacity(.16),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mark_chat_read_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  )
                : Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2.2),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackThumbnail extends StatelessWidget {
  final PahtForumItem item;
  final PahtTopicVisual visual;

  const _FeedbackThumbnail({required this.item, required this.visual});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = _thumbnailUrl(item);
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox(
        width: 68,
        height: 68,
        child: imageUrl.isEmpty
            ? _fallback()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, __, ___) => _fallback(),
              ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: visual.softColor,
      alignment: Alignment.center,
      child: Icon(visual.icon, size: 28, color: visual.color.withOpacity(.72)),
    );
  }

  String _thumbnailUrl(PahtForumItem item) {
    final String externalId = item.thumbnailExternalFileId.trim();
    if (externalId.isNotEmpty) {
      return '${ServicesUrl().baseUrlFileDownload}$externalId$kParamThumbImage';
    }
    final String storageKey = item.thumbnailStorageKey.trim();
    if (storageKey.startsWith('http://') || storageKey.startsWith('https://')) {
      return storageKey;
    }
    if (storageKey.isNotEmpty) {
      return '${ServicesUrl().baseUrlFileDownload}$storageKey$kParamThumbImage';
    }
    return '';
  }
}

/// Hashtag chạy tuần hoàn. Nhiều bản sao của cùng một chu kỳ được render, viewport
/// luôn được giữ ở chu kỳ giữa. Khi đi hết một chu kỳ, offset được dịch lại đúng
/// một chu kỳ nên người dùng không thấy điểm kết thúc/nhảy về đầu.
class _RoundRobinTagStrip extends StatefulWidget {
  final PahtForumItem item;

  const _RoundRobinTagStrip({required this.item});

  @override
  State<_RoundRobinTagStrip> createState() => _RoundRobinTagStripState();
}

class _RoundRobinTagStripState extends State<_RoundRobinTagStrip> {
  static const int _cycleCopies = 9;
  static const int _middleCycle = 4;
  final ScrollController _controller = ScrollController();
  final GlobalKey _cycleKey = GlobalKey();
  Timer? _ticker;
  Timer? _resumeTimer;
  double _cycleWidth = 0;
  bool _userScrolling = false;

  List<PahtTopicRef> get _topics {
    if (widget.item.topics.isNotEmpty) return widget.item.topics;
    return <PahtTopicRef>[
      PahtTopicRef(
        id: widget.item.topicId ?? 0,
        code: '',
        name: widget.item.topicName.isEmpty ? 'Phản ánh' : widget.item.topicName,
        primary: true,
        displayOrder: 0,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareLoop());
  }

  @override
  void didUpdateWidget(covariant _RoundRobinTagStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_topicSignature(oldWidget.item) != _topicSignature(widget.item)) {
      _ticker?.cancel();
      _resumeTimer?.cancel();
      _cycleWidth = 0;
      _userScrolling = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepareLoop());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _resumeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _prepareLoop() {
    if (!mounted || !_controller.hasClients || _topics.length <= 1) return;
    final RenderObject? object = _cycleKey.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepareLoop());
      return;
    }
    _cycleWidth = object.size.width + 8;
    if (_cycleWidth <= 1 || !_controller.hasClients) return;
    final double max = _controller.position.maxScrollExtent;
    if (max <= _cycleWidth) return;
    final double initial = (_cycleWidth * _middleCycle).clamp(0.0, max).toDouble();
    if ((_controller.offset - initial).abs() > 1) {
      _controller.jumpTo(initial);
    }
    _startTicker();
  }

  void _pauseAutoScroll() {
    _resumeTimer?.cancel();
    _ticker?.cancel();
    _userScrolling = true;
  }

  void _resumeAutoScrollLater() {
    _resumeTimer?.cancel();
    _userScrolling = false;
    _normalizeToMiddleCycle();
    _resumeTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted || _userScrolling) return;
      _startTicker();
    });
  }

  void _normalizeToMiddleCycle() {
    if (!_controller.hasClients || _cycleWidth <= 1) return;
    final double max = _controller.position.maxScrollExtent;
    if (max <= _cycleWidth) return;
    final double remainder = _controller.offset % _cycleWidth;
    final double target = (_cycleWidth * _middleCycle + remainder)
        .clamp(0.0, max)
        .toDouble();
    if ((_controller.offset - target).abs() <= 1) return;
    try {
      _controller.jumpTo(target);
    } catch (_) {
      // Card có thể vừa rời khỏi tree trong frame hiện tại.
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification && notification.dragDetails != null) {
      _pauseAutoScroll();
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      if (!_userScrolling) _pauseAutoScroll();
    } else if (notification is ScrollEndNotification && _userScrolling) {
      _resumeAutoScrollLater();
    }
    return false;
  }

  void _startTicker() {
    _ticker?.cancel();
    if (_userScrolling || _topics.length <= 1 || _cycleWidth <= 1) return;
    // Tự chạy chậm khi người dùng không chạm. Khi người dùng vuốt, ticker dừng
    // ngay và tiếp tục sau một khoảng nghỉ ngắn.
    _ticker = Timer.periodic(const Duration(milliseconds: 32), (_) {
      if (!mounted ||
          _userScrolling ||
          !_controller.hasClients ||
          _cycleWidth <= 1) return;
      final double max = _controller.position.maxScrollExtent;
      if (max <= 1) return;
      double next = _controller.offset + 0.72;
      final double lower = _cycleWidth * (_middleCycle - 1);
      final double upper = _cycleWidth * (_middleCycle + 1);
      if (next >= upper) next -= _cycleWidth;
      if (next < lower) next += _cycleWidth;
      next = next.clamp(0.0, max).toDouble();
      try {
        _controller.jumpTo(next);
      } catch (_) {
        // Card có thể vừa rời khỏi tree trong frame hiện tại.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<PahtTopicRef> topics = _topics;

    Widget cycle({Key? key}) {
      return Row(
        key: key,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < topics.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 5),
            _TopicPill(topic: topics[i]),
          ],
        ],
      );
    }

    // Luôn đặt hashtag trong viewport cuộn ngang, kể cả chỉ có 1 chủ đề.
    // Như vậy tên chủ đề dài không bao giờ ép Row của card và gây RIGHT OVERFLOW.
    // Với nhiều chủ đề, nhiều cycle được ghép liên tiếp để auto-scroll round-robin.
    return SizedBox(
      height: 25,
      width: double.infinity,
      child: ClipRect(
        clipBehavior: Clip.hardEdge,
        child: ScrollConfiguration(
          behavior: const _PahtHorizontalScrollBehavior(),
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              clipBehavior: Clip.hardEdge,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (topics.length == 1)
                    _TopicPill(topic: topics.first)
                  else
                    for (int i = 0; i < _cycleCopies; i++) ...<Widget>[
                      if (i > 0) const SizedBox(width: 8),
                      cycle(key: i == _middleCycle ? _cycleKey : null),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _topicSignature(PahtForumItem item) {
    if (item.topics.isEmpty) {
      return '${item.topicId ?? 0}:${item.topicName}';
    }
    return item.topics
        .map((PahtTopicRef e) => '${e.id}:${e.name}:${e.primary}')
        .join(',');
  }
}

class _PahtHorizontalScrollBehavior extends MaterialScrollBehavior {
  const _PahtHorizontalScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _TopicPill extends StatelessWidget {
  final PahtTopicRef topic;

  const _TopicPill({required this.topic});

  @override
  Widget build(BuildContext context) {
    final PahtTopicVisual visual = pahtTopicVisual(
      topicId: topic.id,
      topicName: topic.name,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: visual.softColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(visual.icon, size: 12, color: visual.color),
          const SizedBox(width: 4),
          Text(
            topic.name.isEmpty ? 'Phản ánh' : topic.name,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 10.15,
              color: visual.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineResponses extends StatelessWidget {
  final PahtTopicVisual visual;
  final PahtForumDetail? detail;
  final bool loading;
  final VoidCallback? onDetailTap;

  const _InlineResponses({
    super.key,
    required this.visual,
    required this.detail,
    required this.loading,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: _ResponseShell(
          visual: visual,
          child: const Row(
            children: <Widget>[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(
                'Đang lấy phản hồi...',
                style: TextStyle(fontSize: 11.8, color: Color(0xFF65736B)),
              ),
            ],
          ),
        ),
      );
    }

    final List<PahtResponseItem> responses =
        detail?.responses ?? <PahtResponseItem>[];
    if (responses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: _ResponseShell(
          visual: visual,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Chưa có phản hồi công khai từ đơn vị xử lý.',
                style: TextStyle(
                  fontSize: 11.8,
                  color: Color(0xFF536159),
                  height: 1.4,
                ),
              ),
              _DetailLink(onTap: onDetailTap, label: 'Xem tiến trình'),
            ],
          ),
        ),
      );
    }

    return Column(
      children: responses
          .map(
            (PahtResponseItem response) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _InlineResponseEntry(
                response: response,
                visual: visual,
                onDetailTap: onDetailTap,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _InlineResponseEntry extends StatelessWidget {
  final PahtResponseItem response;
  final PahtTopicVisual visual;
  final VoidCallback? onDetailTap;

  const _InlineResponseEntry({
    required this.response,
    required this.visual,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final String responseType = response.responseType.toUpperCase();
    final bool official =
        responseType == 'OFFICIAL_ANSWER' || responseType == 'KTX_REPLY';
    return Stack(
      children: <Widget>[
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: 31,
            child: Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                Positioned(
                  top: 0,
                  bottom: 0,
                  child: Container(width: 1, color: const Color(0xFFDDE5E0)),
                ),
                Positioned(
                  top: 11,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: official ? visual.color : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: visual.color, width: 1.8),
                    ),
                    child: Icon(
                      official
                          ? Icons.mark_chat_read_rounded
                          : Icons.chat_bubble_outline_rounded,
                      size: 11,
                      color: official ? Colors.white : visual.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 31),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onDetailTap,
              borderRadius: BorderRadius.circular(12),
              child: _ResponseShell(
                visual: visual,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            response.sourceSystem == 'KTX'
                                ? "KTX · ${response.unit.trim().isNotEmpty ? response.unit.trim() : 'Cán bộ KTX'}"
                                : (response.unit.trim().isNotEmpty
                                    ? response.unit.trim()
                                    : 'Đơn vị xử lý'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF264235),
                              fontSize: 11.7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _compactDate(response.createdAt),
                          style: const TextStyle(
                            fontSize: 10.1,
                            color: Color(0xFF7A867F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      response.content,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF536159),
                        fontSize: 11.75,
                        height: 1.42,
                      ),
                    ),
                    _DetailLink(onTap: onDetailTap),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResponseShell extends StatelessWidget {
  final PahtTopicVisual visual;
  final Widget child;

  const _ResponseShell({required this.visual, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 10, 7),
      decoration: BoxDecoration(
        color: visual.softColor.withOpacity(.66),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: visual.color.withOpacity(.10)),
      ),
      child: child,
    );
  }
}

class _DetailLink extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;

  const _DetailLink({this.onTap, this.label = 'Xem chi tiết'});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.only(top: 2),
        minimumSize: const Size(0, 27),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: const Color(0xFF246A48),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 11.7, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_rounded, size: 14),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Metric({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10.4,
              color: Color(0xFF7A867F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

PahtTopicRef _primaryTopic(PahtForumItem item) {
  for (final PahtTopicRef topic in item.topics) {
    if (topic.primary) return topic;
  }
  if (item.topics.isNotEmpty) return item.topics.first;
  return PahtTopicRef(
    id: item.topicId ?? 0,
    code: '',
    name: item.topicName,
    primary: true,
    displayOrder: 0,
  );
}

String _compactDate(DateTime? value) {
  if (value == null) return '';
  final DateTime local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}';
}
