import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vnu_core/modules/paht_v2/ktx/models/ktx_issue_models.dart';
import 'package:vnu_core/modules/paht_v2/ktx/repository/ktx_issue_repository.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class KtxIssueDetailView extends StatefulWidget {
  final int issueId;

  const KtxIssueDetailView({
    super.key,
    required this.issueId,
  });

  @override
  State<KtxIssueDetailView> createState() => _KtxIssueDetailViewState();
}

class _KtxIssueDetailViewState extends State<KtxIssueDetailView> {
  final KtxIssueRepository _repository = KtxIssueRepository();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  KtxIssue? _issue;
  KtxIssueMeta? _meta;
  String? _errorMessage;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      KtxIssueMeta? meta;
      try {
        meta = await _repository.getMeta();
      } catch (_) {}

      final KtxIssue issue =
          await _repository.getIssue(widget.issueId);

      if (!mounted) return;
      setState(() {
        _meta = meta;
        _issue = issue;
        _loading = false;
      });
    } on KtxIssueApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _sendComment() async {
    if (_sending) return;

    final String text = _commentController.text.trim();
    if (text.isEmpty) return;

    final KtxIssue? current = _issue;
    if (current == null) return;

    setState(() => _sending = true);

    try {
      final KtxIssueComment comment =
          await _repository.sendComment(
        issueId: current.id,
        comment: text,
      );

      if (!mounted) return;

      _commentController.clear();
      setState(() {
        _issue = KtxIssue(
          id: current.id,
          dormitoryId: current.dormitoryId,
          studentId: current.studentId,
          roomId: current.roomId,
          title: current.title,
          description: current.description,
          type: current.type,
          typeLabel: current.typeLabel,
          priority: current.priority,
          priorityLabel: current.priorityLabel,
          status: current.status,
          statusLabel: current.statusLabel,
          assignedTo: current.assignedTo,
          latitude: current.latitude,
          longitude: current.longitude,
          address: current.address,
          mapUrl: current.mapUrl,
          images: current.images,
          createdAt: current.createdAt,
          updatedAt: current.updatedAt,
          comments: <KtxIssueComment>[
            ...current.comments,
            comment,
          ],
        );
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    } on KtxIssueApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message, warning: true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString(), warning: true);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _openMap(KtxIssue issue) async {
    String raw = issue.mapUrl.trim();

    if (raw.isEmpty && issue.hasLocation) {
      raw = 'https://maps.google.com/?q='
          '${issue.latitude},${issue.longitude}';
    }

    final Uri? uri = Uri.tryParse(raw);
    if (uri == null) {
      _showMessage('Không có liên kết bản đồ hợp lệ.', warning: true);
      return;
    }

    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      _showMessage('Không thể mở ứng dụng bản đồ.', warning: true);
    }
  }

  void _showMessage(String message, {bool warning = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              warning ? const Color(0xFF9B6B00) : const Color(0xFF078B3E),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Chi tiết phản ánh KTX',
      actions: <Widget>[
        IconButton(
          tooltip: 'Tải lại',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF078B3E)),
      );
    }

    final String? error = _errorMessage;
    if (error != null && _issue == null) {
      return _ErrorState(
        message: error,
        onRetry: _load,
      );
    }

    final KtxIssue? issue = _issue;
    if (issue == null) {
      return const Center(
        child: Text('Không có dữ liệu phản ánh.'),
      );
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF078B3E),
            onRefresh: _load,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: <Widget>[
                _buildSummary(issue),
                const SizedBox(height: 12),
                _buildDescription(issue),
                if (issue.images.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _buildImages(issue),
                ],
                if (issue.address.isNotEmpty ||
                    issue.mapUrl.isNotEmpty ||
                    issue.hasLocation) ...<Widget>[
                  const SizedBox(height: 12),
                  _buildLocation(issue),
                ],
                const SizedBox(height: 16),
                _buildConversation(issue),
              ],
            ),
          ),
        ),
        _CommentComposer(
          controller: _commentController,
          sending: _sending,
          onSend: _sendComment,
        ),
      ],
    );
  }

  Widget _buildSummary(KtxIssue issue) {
    final String createdAt = issue.createdAt == null
        ? 'Chưa có thời gian'
        : DateFormat('dd/MM/yyyy HH:mm').format(issue.createdAt!);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.home_work_outlined,
                  color: Color(0xFF078B3E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  issue.title.isEmpty
                      ? 'Phản ánh #${issue.id}'
                      : issue.title,
                  style: const TextStyle(
                    color: Color(0xFF17201A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _Chip(
                icon: Icons.timelapse_rounded,
                text: issue.displayStatus,
                accent: true,
              ),
              _Chip(
                icon: Icons.category_outlined,
                text: issue.displayType(_meta),
              ),
              _Chip(
                icon: Icons.flag_outlined,
                text: issue.displayPriority(_meta),
              ),
              if (issue.roomId != null)
                _Chip(
                  icon: Icons.meeting_room_outlined,
                  text: 'Phòng #${issue.roomId}',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tạo lúc $createdAt',
            style: const TextStyle(
              color: Color(0xFF7C877F),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(KtxIssue issue) {
    return _SectionCard(
      title: 'Nội dung phản ánh',
      icon: Icons.subject_rounded,
      child: Text(
        issue.description.isEmpty
            ? 'Không có mô tả.'
            : issue.description,
        style: const TextStyle(
          color: Color(0xFF455149),
          fontSize: 13.5,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _buildImages(KtxIssue issue) {
    final List<String> urls = issue.images
        .map(_repository.absoluteMediaUrl)
        .where((String url) => url.isNotEmpty)
        .toList();

    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: 'Hình ảnh',
      icon: Icons.photo_library_outlined,
      child: SizedBox(
        height: 116,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          separatorBuilder: (_, __) => const SizedBox(width: 9),
          itemBuilder: (BuildContext context, int index) {
            final String url = urls[index];
            return InkWell(
              onTap: () => _showImage(url),
              borderRadius: BorderRadius.circular(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  url,
                  width: 116,
                  height: 116,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 116,
                    height: 116,
                    color: const Color(0xFFF0F3F1),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF87928B),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocation(KtxIssue issue) {
    return _SectionCard(
      title: 'Vị trí',
      icon: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (issue.address.isNotEmpty)
            Text(
              issue.address,
              style: const TextStyle(
                color: Color(0xFF455149),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          if (issue.hasLocation) ...<Widget>[
            const SizedBox(height: 5),
            Text(
              '${issue.latitude!.toStringAsFixed(6)}, '
              '${issue.longitude!.toStringAsFixed(6)}',
              style: const TextStyle(
                color: Color(0xFF7B867F),
                fontSize: 11.5,
              ),
            ),
          ],
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: () => _openMap(issue),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Mở trên bản đồ'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversation(KtxIssue issue) {
    final List<KtxIssueComment> comments = issue.comments;

    return _SectionCard(
      title: 'Trao đổi với KTX',
      icon: Icons.forum_outlined,
      child: comments.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Chưa có tin nhắn trao đổi.',
                style: TextStyle(
                  color: Color(0xFF7B867F),
                  fontSize: 12.5,
                ),
              ),
            )
          : Column(
              children: comments
                  .map(
                    (KtxIssueComment comment) =>
                        _CommentBubble(comment: comment),
                  )
                  .toList(),
            ),
    );
  }

  void _showImage(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(14),
          child: Stack(
            children: <Widget>[
              InteractiveViewer(
                minScale: 0.7,
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 260,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget child;

  const _SectionCard({
    required this.child,
    this.title,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E5)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Row(
              children: <Widget>[
                if (icon != null)
                  Icon(
                    icon,
                    color: const Color(0xFF078B3E),
                    size: 20,
                  ),
                if (icon != null) const SizedBox(width: 8),
                Text(
                  title!,
                  style: const TextStyle(
                    color: Color(0xFF26312A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool accent;

  const _Chip({
    required this.icon,
    required this.text,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color background =
        accent ? const Color(0xFFE7F6EC) : const Color(0xFFF4F6F5);
    final Color foreground =
        accent ? const Color(0xFF078B3E) : const Color(0xFF5F6B63);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final KtxIssueComment comment;

  const _CommentBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    final bool mine = comment.fromStudent;
    final String time = comment.createdAt == null
        ? ''
        : DateFormat('dd/MM HH:mm').format(comment.createdAt!);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xFFE8F6ED)
              : const Color(0xFFF3F5F4),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(mine ? 15 : 4),
            bottomRight: Radius.circular(mine ? 4 : 15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              comment.senderName,
              style: TextStyle(
                color: mine
                    ? const Color(0xFF078B3E)
                    : const Color(0xFF5D6961),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              comment.comment,
              style: const TextStyle(
                color: Color(0xFF303A33),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (time.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  color: Color(0xFF89938D),
                  fontSize: 9.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _CommentComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        9,
        12,
        MediaQuery.of(context).viewPadding.bottom + 9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE4E9E6)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Nhắn thêm cho cán bộ KTX...',
                filled: true,
                fillColor: const Color(0xFFF5F7F6),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFF078B3E),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Gửi',
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                    ),
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFF909A94),
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Không tải được chi tiết phản ánh',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF26312A),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF78837C),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF078B3E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
