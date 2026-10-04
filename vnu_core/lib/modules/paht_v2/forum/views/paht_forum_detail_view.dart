import 'package:flutter/material.dart';
import 'package:vnu_core/modules/paht_v2/forum/models/paht_forum_models.dart';
import 'package:vnu_core/modules/paht_v2/forum/repository/paht_forum_repository.dart';
import 'package:vnu_core/modules/paht_v2/forum/widgets/paht_heart_toggle.dart';
import 'package:vnu_core/modules/paht_v2/forum/widgets/paht_topic_visual.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/vcore_action_dialog.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/vcore_notice_toast.dart';

class PahtForumDetailView extends StatefulWidget {
  final String guid;
  final bool publicOnly;

  const PahtForumDetailView({
    super.key,
    required this.guid,
    this.publicOnly = false,
  });

  @override
  State<PahtForumDetailView> createState() => _PahtForumDetailViewState();
}

class _PahtForumDetailViewState extends State<PahtForumDetailView> {
  final PahtForumRepository _repository = PahtForumRepository();
  PahtForumDetail? _detail;
  bool _loading = true;
  bool _interestLoading = false;
  bool _deleteLoading = false;
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
      final PahtForumDetail detail = widget.publicOnly
          ? await _repository.getPublicDetail(widget.guid)
          : await _repository.getDetail(widget.guid);
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  Future<void> _toggleInterest() async {
    final PahtForumDetail? current = _detail;
    if (current == null || _interestLoading) return;
    setState(() => _interestLoading = true);
    try {
      final PahtInterestResult result = await _repository.setInterest(
        current.item.guid,
        interested: !current.interested,
      );
      if (!mounted) return;
      setState(() {
        _detail = current.copyWithInterest(
          interested: result.interested,
          careCount: result.careCount,
        );
        _interestLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _interestLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _deleteOwnFeedback() async {
    final PahtForumDetail? current = _detail;
    if (current == null ||
        widget.publicOnly ||
        !current.item.canDelete ||
        _deleteLoading ||
        !mounted) {
      return;
    }

    final String code = current.item.code.trim();
    final bool? confirmed = await showVcoreActionDialog<bool>(
      context: context,
      title: 'Xóa phản ánh?',
      content: code.isEmpty
          ? 'Xóa phản ánh này khỏi OneVNU? Phản ánh và toàn bộ phần trao đổi sẽ không còn hiển thị cho người dùng. Hệ thống vẫn giữ dữ liệu xử lý nội bộ để đối soát.'
          : 'Xóa phản ánh $code khỏi OneVNU? Phản ánh và toàn bộ phần trao đổi sẽ không còn hiển thị cho người dùng. Hệ thống vẫn giữ dữ liệu xử lý nội bộ để đối soát.',
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

    setState(() => _deleteLoading = true);
    try {
      final Map<String, dynamic> result =
          await _repository.deleteOwnFeedback(current.item.guid);
      if (!mounted) return;
      final String deletedCode =
          (result['code'] ?? current.item.code).toString().trim();
      showVcoreNotice(
        context: context,
        title: 'Đã xóa phản ánh',
        message: deletedCode.isEmpty
            ? 'Phản ánh đã được xóa thành công.'
            : 'Đã xóa phản ánh $deletedCode.',
        tone: VcoreNoticeTone.success,
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleteLoading = false);
      showVcoreNotice(
        context: context,
        title: 'Chưa thể xóa phản ánh',
        message: error.toString(),
        tone: VcoreNoticeTone.error,
        duration: const Duration(milliseconds: 3400),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Chi tiết phản ánh',
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty && _detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, size: 42, color: Color(0xFFA84444)),
              const SizedBox(height: 12),
              Text(_error, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final PahtForumDetail detail = _detail!;
    final PahtForumItem item = detail.item;
    final bool isPublic = item.visibility != 'PRIVATE';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE3E9E5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.code.isEmpty ? 'Phản ánh, góp ý' : item.code,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF738078),
                        ),
                      ),
                    ),
                    _StatusPill(status: _effectiveDetailStatus(item)),
                  ],
                ),
                const SizedBox(height: 11),
                Text(
                  item.title.isEmpty ? item.content : item.title,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17221C),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ...item.topics.map(
                      (PahtTopicRef topic) => _TopicMetaPill(topic: topic),
                    ),
                    _MetaPill(
                      icon: isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                      text: pahtVisibilityLabel(item.visibility),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Text(
                  item.content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF334139),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Icon(
                      item.hasOfficialAnswer ? Icons.mark_chat_read_rounded : Icons.schedule_rounded,
                      size: 18,
                      color: item.hasOfficialAnswer
                          ? const Color(0xFF237A40)
                          : const Color(0xFF7B6A32),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.hasOfficialAnswer
                            ? 'Đã có phản hồi chính thức'
                            : 'Đang chờ cập nhật phản hồi',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (item.createdAt != null)
                      Text(
                        pahtFormatDate(item.createdAt),
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF819087)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (detail.attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _SectionHeader(
              icon: Icons.photo_library_outlined,
              title: 'Ảnh hiện trường',
              count: detail.attachments.length,
            ),
            const SizedBox(height: 9),
            _AttachmentGallery(items: detail.attachments),
          ],
          if (isPublic) ...<Widget>[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE0E7E3)),
                ),
                child: PahtHeartToggle(
                  active: detail.interested,
                  count: item.careCount,
                  busy: _interestLoading,
                  iconSize: 22,
                  onTap: _interestLoading ? null : _toggleInterest,
                ),
              ),
            ),
          ],
          if (!widget.publicOnly && item.canDelete) ...<Widget>[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _deleteLoading ? null : _deleteOwnFeedback,
                icon: _deleteLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 1.8),
                      )
                    : const Icon(Icons.delete_outline_rounded),
                label: Text(_deleteLoading ? 'Đang xóa...' : 'Xóa phản ánh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFA44444),
                  side: const BorderSide(color: Color(0xFFE4BABA)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _SectionHeader(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Phản hồi chính thức',
            count: detail.responses.length,
          ),
          const SizedBox(height: 9),
          if (detail.responses.isEmpty)
            const _EmptyBlock(
              text: 'Chưa có phản hồi chính thức. Bạn có thể kéo xuống để xem tiến trình xử lý.',
            )
          else
            ...detail.responses.map(
              (PahtResponseItem response) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDDEDE2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.verified_outlined, size: 18, color: Color(0xFF237A40)),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              response.sourceSystem == 'KTX'
                                  ? "KTX · ${response.unit.isEmpty ? 'Cán bộ KTX' : response.unit}"
                                  : (response.unit.isEmpty ? 'Đơn vị xử lý' : response.unit),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF28573A)),
                            ),
                          ),
                          if (response.createdAt != null)
                            Text(
                              pahtFormatDate(response.createdAt),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF7B897F)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        response.content,
                        style: const TextStyle(height: 1.55, color: Color(0xFF34443A)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          _SectionHeader(
            icon: Icons.timeline_rounded,
            title: 'Tiến trình xử lý',
            count: detail.timeline.length,
          ),
          const SizedBox(height: 9),
          if (detail.timeline.isEmpty)
            const _EmptyBlock(text: 'Chưa có cập nhật tiến trình công khai.')
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE3E9E5)),
              ),
              child: Column(
                children: detail.timeline
                    .map(
                      (PahtTimelineItem event) => _TimelineRow(event: event),
                    )
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentGallery extends StatelessWidget {
  final List<PahtAttachmentItem> items;

  const _AttachmentGallery({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final PahtAttachmentItem item = items[index];
          final String key = item.storageKey.trim();
          final bool canRenderImage = item.mediaKind.toUpperCase() == 'IMAGE' &&
              key.isNotEmpty &&
              !key.contains('/');
          if (!canRenderImage) {
            return Container(
              width: 118,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE3E9E5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF6B7971)),
                  const SizedBox(height: 6),
                  Text(
                    item.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ],
              ),
            );
          }
          final String url = '${ServicesUrl().baseUrlFileDownload}$key';
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              url,
              width: 118,
              height: 118,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 118,
                height: 118,
                color: const Color(0xFFF1F4F2),
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined, color: Color(0xFF7B877F)),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _effectiveDetailStatus(PahtForumItem item) {
  final String status = item.workflowStatus.toUpperCase();
  if (status == 'ANSWERED' && !item.hasOfficialAnswer) return 'PROCESSING';
  return status;
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        pahtStatusLabel(status),
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF385544)),
      ),
    );
  }
}

class _TopicMetaPill extends StatelessWidget {
  final PahtTopicRef topic;

  const _TopicMetaPill({required this.topic});

  @override
  Widget build(BuildContext context) {
    final PahtTopicVisual visual = pahtTopicVisual(
      topicId: topic.id,
      topicName: topic.name,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: visual.softColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(visual.icon, size: 15, color: visual.color),
          const SizedBox(width: 5),
          Text(
            topic.name,
            style: TextStyle(
              fontSize: 11.5,
              color: visual.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: const Color(0xFF68776F)),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionHeader({required this.icon, required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: AppTheme.colorMain),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4F1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final PahtTimelineItem event;

  const _TimelineRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final String label = event.newStatus.isNotEmpty
        ? pahtStatusLabel(event.newStatus)
        : event.note.isNotEmpty
            ? event.note
            : 'Cập nhật tiến trình';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: AppTheme.colorMain, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                if (event.note.isNotEmpty && event.note != label) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(event.note, style: const TextStyle(fontSize: 12, color: Color(0xFF66756C))),
                ],
              ],
            ),
          ),
          if (event.createdAt != null)
            Text(
              pahtFormatDate(event.createdAt),
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF87938C)),
            ),
        ],
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final String text;

  const _EmptyBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF738078), height: 1.4)),
    );
  }
}
