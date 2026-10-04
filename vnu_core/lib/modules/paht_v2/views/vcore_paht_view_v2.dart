import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/modules/paht_v2/forum/views/paht_forum_community_view.dart';
import 'package:vnu_core/modules/paht_v2/forum/views/paht_forum_create_view.dart';
import 'package:vnu_core/modules/paht_v2/forum/views/paht_forum_following_page.dart';
import 'package:vnu_core/modules/paht_v2/forum/views/paht_forum_mine_page.dart';
import 'package:vnu_core/modules/paht_v2/ktx/repository/ktx_issue_repository.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcorePahtViewV2 extends StatefulWidget {
  const VcorePahtViewV2({super.key});

  @override
  State<VcorePahtViewV2> createState() => _VcorePahtViewV2State();
}

class _VcorePahtViewV2State extends State<VcorePahtViewV2> {
  static const String _fallbackAvatar =
      'https://vnu.edu.vn/upload/2014/11/17202/image/Logo-VNU-1995.jpg';

  final KtxIssueRepository _ktxRepository = KtxIssueRepository();

  bool _ktxCanCreate = false;
  int _vnuReloadToken = 0;
  String _avatarUrl = _fallbackAvatar;

  @override
  void initState() {
    super.initState();
    _refreshHeaderState();
  }

  Future<void> _refreshHeaderState() async {
    await Future.wait<void>(<Future<void>>[
      _refreshKtxEligibility(),
      _loadAvatar(),
    ]);
  }

  Future<void> _refreshKtxEligibility() async {
    bool canCreate = false;
    try {
      // Giữ nguyên logic KTX đã có của app: chỉ true khi sinh viên có
      // accommodation/room ở trạng thái assigned, active, staying... hoặc
      // assignedRoom/room_id hợp lệ.
      canCreate = await _ktxRepository.isKtxResidentEligible();
    } catch (_) {
      canCreate = false;
    }
    if (!mounted) return;
    setState(() {
      _ktxCanCreate = canCreate;
    });
  }

  Future<void> _loadAvatar() async {
    try {
      final items = await ApiRepository().getAllAnhCanNhan();
      final String guid = items.isEmpty ? '' : (items.first.guid ?? '').trim();
      final String url = guid.isEmpty
          ? _fallbackAvatar
          : '${ServicesUrl().baseUrlFileDownload}$guid$kParamThumbImage';
      if (!mounted) return;
      setState(() => _avatarUrl = url);
    } catch (_) {
      // Giữ avatar mặc định, không chặn màn phản ánh nếu API ảnh lỗi.
    }
  }

  Future<void> _createVnuFeedback({String? preselectTopicCode}) async {
    final bool? created = await Get.to<bool>(
      () => PahtForumCreateView(
        preselectTopicCode: preselectTopicCode,
        ktxEligible: _ktxCanCreate,
      ),
    );
    if (created == true && mounted) {
      setState(() => _vnuReloadToken++);
    }
  }

  Future<void> _createKtxFeedback() async {
    if (!_ktxCanCreate) return;
    await _createVnuFeedback(preselectTopicCode: 'KTX');
  }

  Future<void> _openMine() async {
    await Get.to(() => const PahtForumMinePage());
    if (mounted) setState(() => _vnuReloadToken++);
  }

  Future<void> _openFollowing() async {
    await Get.to(() => const PahtForumFollowingPage());
    if (mounted) setState(() => _vnuReloadToken++);
  }

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Phản ánh góp ý',
      body: PahtForumCommunityView(
        key: ValueKey<String>('paht-community-$_vnuReloadToken'),
        avatarUrl: _avatarUrl,
        showKtxResidence: _ktxCanCreate,
        onAvatarTap: _openMine,
        onFollowingTap: _openFollowing,
        onKtxTap: _createKtxFeedback,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'paht-create-feedback',
        backgroundColor: AppTheme.colorMain,
        foregroundColor: Colors.white,
        onPressed: () => _createVnuFeedback(),
        tooltip: 'Tạo phản ánh',
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}
