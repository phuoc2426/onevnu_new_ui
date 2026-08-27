import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/attachment_preview.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/error/app_feedback.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/models/tin_tuc_model.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcoreJobDetailViewV2 extends StatefulWidget {
  const VcoreJobDetailViewV2({
    super.key,
    required this.initialJob,
  });

  final TinTucModel initialJob;

  @override
  State<VcoreJobDetailViewV2> createState() => _VcoreJobDetailViewV2State();
}

class _VcoreJobDetailViewV2State extends State<VcoreJobDetailViewV2> {
  final ScrollController _scrollController = ScrollController();

  late TinTucModel _job;
  List<TinTucModel> _relatedJobs = <TinTucModel>[];
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _job = widget.initialJob;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJob(widget.initialJob.guid ?? '');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadJob(String guid) async {
    final cleanGuid = guid.trim();
    if (cleanGuid.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final detail = await ApiRepository().getDetailTinTuc(cleanGuid);
      if (!mounted) return;

      setState(() => _job = detail);
      await _loadRelatedJobs(_job.guidChuyenMucTinTuc);

      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    } catch (error, stackTrace) {
      logError('[JOB_DETAIL] load error=$error\n$stackTrace');
      if (mounted) {
        setState(() => _errorMessage = 'Không thể tải đầy đủ thông tin việc làm.');
        AppFeedback.showError(error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadRelatedJobs(String? categoryGuid) async {
    final cleanGuid = categoryGuid?.trim() ?? '';
    if (cleanGuid.isEmpty) {
      if (mounted) setState(() => _relatedJobs = <TinTucModel>[]);
      return;
    }

    try {
      final response = await ApiRepository().getTinTucCungChuyenMuc(
        1,
        10,
        'created,desc',
        cleanGuid,
      );
      final currentGuid = _job.guid;
      final items = (response.data ?? <TinTucModel>[])
          .where((item) => item.guid != currentGuid)
          .toList();
      if (mounted) setState(() => _relatedJobs = items);
    } catch (error, stackTrace) {
      logError('[JOB_DETAIL] related error=$error\n$stackTrace');
      if (mounted) setState(() => _relatedJobs = <TinTucModel>[]);
    }
  }

  String _attachmentName(int index) {
    final configured = _job.tenFileDinhKem?.trim() ?? '';
    if (index == 0 && configured.isNotEmpty) return configured;
    return 'Tài liệu tuyển dụng ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final images = _job.guidFileAnhDaiDiens ?? <String>[];
    final attachments = _job.guidFileDinhKems ?? <String>[];

    return VcoreModuleScaffold(
      title: 'Chi tiết việc làm',
      showBackButton: true,
      body: Stack(
        children: <Widget>[
          ColoredBox(
            color: const Color(0xFFF5F7F6),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildMainCard(context, images, attachments),
                      if (_relatedJobs.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 16),
                        _buildRelatedSection(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2.5,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.08),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainCard(
    BuildContext context,
    List<String> images,
    List<String> attachments,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7ECE9)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D18392A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (images.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 8.2,
              child: CachedNetworkImage(
                imageUrl: '${ServicesUrl().baseUrlFileDownload}${images.first}',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: const Color(0xFFF1F5F3),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (_, __, ___) => _buildHeroFallback(),
              ),
            )
          else
            _buildHeroFallback(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'CƠ HỘI VIỆC LÀM',
                    style: TextStyle(
                      color: Color(0xFF078B4A),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _job.tieuDe?.trim().isNotEmpty == true
                      ? _job.tieuDe!.trim()
                      : 'Thông tin tuyển dụng',
                  style: const TextStyle(
                    color: Color(0xFF151A17),
                    fontSize: 23,
                    height: 1.28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 14),
                _buildMetadata(),
                if (_errorMessage != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFF9A3412),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFE9EEEB)),
                const SizedBox(height: 18),
                Html(
                  data: _job.htmlNoiDungTinBai ?? '',
                  onLinkTap: (url, attributes, element) async {
                    if (url == null || url.trim().isEmpty) return;
                    final uri = Uri.tryParse(url);
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  style: <String, Style>{
                    'body': Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(15),
                      lineHeight: const LineHeight(1.6),
                      color: const Color(0xFF343B37),
                    ),
                    'p': Style(margin: Margins.only(bottom: 14)),
                    'li': Style(margin: Margins.only(bottom: 7)),
                    'a': Style(
                      color: const Color(0xFF078B4A),
                      textDecoration: TextDecoration.underline,
                    ),
                  },
                ),
                if (attachments.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Color(0xFFE9EEEB)),
                  const SizedBox(height: 18),
                  const Text(
                    'Tài liệu đính kèm',
                    style: TextStyle(
                      color: Color(0xFF1F2923),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List<Widget>.generate(attachments.length, (index) {
                    final guid = attachments[index];
                    final fileName = _attachmentName(index);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Material(
                        color: const Color(0xFFF2F7F4),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => VnuAttachmentPreview.open(
                            context: context,
                            guid: guid,
                            fileName: fileName,
                            title: fileName,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    color: Color(0xFF078B4A),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        fileName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          color: Color(0xFF243029),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Chạm để xem trước',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF718078),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Chia sẻ',
                                  onPressed: () => VnuAttachmentPreview.share(
                                    context: context,
                                    guid: guid,
                                    fileName: fileName,
                                  ),
                                  icon: const Icon(
                                    Icons.ios_share_rounded,
                                    color: Color(0xFF078B4A),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroFallback() {
    return Container(
      height: 116,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF057642),
            Color(0xFF0EAD63),
          ],
        ),
      ),
      child: const Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: 22),
          child: Icon(
            Icons.work_outline_rounded,
            size: 58,
            color: Color(0x66FFFFFF),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    final publisher = _job.donViXuatBan?.trim() ?? '';
    final date = _job.thoiGianTao;

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: <Widget>[
        if (publisher.isNotEmpty)
          _MetadataChip(
            icon: Icons.business_rounded,
            text: publisher,
          ),
        if (date != null)
          _MetadataChip(
            icon: Icons.calendar_today_rounded,
            text: DateTimeUtils.stringFromDateTime(
              date,
              DateTimeConst.DATE_FORMAT,
            ),
          ),
      ],
    );
  }

  Widget _buildRelatedSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Việc làm liên quan',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A211D),
            ),
          ),
          const SizedBox(height: 10),
          ...List<Widget>.generate(_relatedJobs.length, (index) {
            final item = _relatedJobs[index];
            return Column(
              children: <Widget>[
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 2),
                  title: Text(
                    item.tieuDe ?? 'Thông tin tuyển dụng',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    item.donViXuatBan ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _loadJob(item.guid ?? ''),
                ),
                if (index != _relatedJobs.length - 1)
                  const Divider(height: 1, color: Color(0xFFEEF1EF)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: const Color(0xFF6B7770)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5B665F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
