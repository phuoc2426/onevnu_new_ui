import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/modules/release_notice/models/app_release_notice.dart';

class AppReleaseNoticeDialog extends StatefulWidget {
  const AppReleaseNoticeDialog({
    super.key,
    required this.notice,
  });

  final AppReleaseNotice notice;

  @override
  State<AppReleaseNoticeDialog> createState() =>
      _AppReleaseNoticeDialogState();
}

class _AppReleaseNoticeDialogState extends State<AppReleaseNoticeDialog> {
  final ScrollController _scrollController = ScrollController();
  bool _reachedEnd = false;
  bool _accepted = false;

  static const Color _green = Color(0xFF07964B);
  static const Color _greenDark = Color(0xFF008A43);
  static const Color _textDark = Color(0xFF101936);
  static const Color _textMuted = Color(0xFF7B849A);
  static const Color _border = Color(0xFFE3E7EE);

  @override
  void initState() {
    super.initState();
    _reachedEnd = !widget.notice.requireScrollEnd;
    _accepted = !widget.notice.requiredAck;
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollable());
  }

  void _checkScrollable() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent <= 8) {
      setState(() => _reachedEnd = true);
    }
  }

  void _handleScroll() {
    if (_reachedEnd || !_scrollController.hasClients) return;
    final ScrollPosition position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 20) {
      setState(() => _reachedEnd = true);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _reachedEnd && (!widget.notice.requiredAck || _accepted);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.notice.requiredAck,
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.campaign_outlined, color: _green),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Thông báo phiên bản',
                    style: TextStyle(
                      color: _greenDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.notice.title,
                    style: const TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: AppFontSizes.mediumLarge,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (widget.notice.summary.isNotEmpty) ...<Widget>[
                Text(
                  widget.notice.summary,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: AppFontSizes.small,
                    height: 1.42,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.notice.requireScrollEnd)
                const Text(
                  'Vui lòng đọc hết nội dung bên dưới. Nút xác nhận sẽ được bật sau khi bạn cuộn đến cuối thông báo.',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (widget.notice.requireScrollEnd) const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.48,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _section(
                            widget.notice.changeTitle,
                            widget.notice.changeContent,
                          ),
                          _section(
                            widget.notice.reasonTitle,
                            widget.notice.reasonContent,
                          ),
                          _section(
                            widget.notice.impactTitle,
                            widget.notice.impactContent,
                          ),
                          _section(
                            widget.notice.actionTitle,
                            widget.notice.actionContent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!_reachedEnd)
                const Row(
                  children: <Widget>[
                    Icon(Icons.south_rounded, size: 18, color: _green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cuộn xuống hết nội dung để tiếp tục.',
                        style: TextStyle(
                          color: _greenDark,
                          fontSize: AppFontSizes.small,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              if (widget.notice.requiredAck)
                CheckboxListTile(
                  value: _accepted,
                  onChanged: !_reachedEnd
                      ? null
                      : (bool? value) {
                          setState(() => _accepted = value ?? false);
                        },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: _green,
                  title: Text(
                    widget.notice.acknowledgementText,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: AppFontSizes.small,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Xác nhận được lưu theo phiên bản nội dung. Nếu thông báo được cập nhật quan trọng, OneVNU có thể yêu cầu bạn đọc lại.',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: <Widget>[
          if (!widget.notice.requiredAck)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Để sau'),
            ),
          FilledButton(
            onPressed: _canContinue
                ? () => Navigator.of(context).pop(true)
                : null,
            style: FilledButton.styleFrom(backgroundColor: _green),
            child: Text(
              widget.notice.primaryActionLabel.isEmpty
                  ? 'Tôi đã đọc và hiểu'
                  : widget.notice.primaryActionLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title.trim().isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                color: _textDark,
                fontSize: AppFontSizes.small,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (title.trim().isNotEmpty) const SizedBox(height: 5),
          Text(
            body,
            style: const TextStyle(
              color: _textDark,
              fontSize: AppFontSizes.small,
              height: 1.48,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
