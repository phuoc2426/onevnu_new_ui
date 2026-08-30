import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/modules/paht_v2/ktx/repository/ktx_issue_repository.dart';
import 'package:vnu_core/modules/paht_v2/ktx/views/ktx_issue_create_view.dart';
import 'package:vnu_core/modules/paht_v2/ktx/views/ktx_issue_list_view.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_comunitation_view_v2.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_create_view_v2.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_person_view_v2.dart';
import 'package:vnu_core/modules/paht_v2/views/vcore_paht_search_view_v2.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcorePahtViewV2 extends StatefulWidget {
  const VcorePahtViewV2({super.key});

  @override
  State<VcorePahtViewV2> createState() => _VcorePahtViewV2State();
}

class _VcorePahtViewV2State extends State<VcorePahtViewV2> {
  final KtxIssueRepository _ktxRepository = KtxIssueRepository();
  int _sourceIndex = 0;
  int _ktxReloadToken = 0;
  bool _ktxCanCreate = false;
  bool _ktxHasHistory = false;
  bool _checkingKtxEligibility = true;

  bool get _ktxVisible => _ktxCanCreate || _ktxHasHistory;
  bool get _isKtx => _sourceIndex == 1 && _ktxVisible;

  @override
  void initState() {
    super.initState();
    _refreshKtxEligibility();
  }

  Future<void> _refreshKtxEligibility() async {
    if (mounted) setState(() => _checkingKtxEligibility = true);

    bool canCreate = false;
    bool hasHistory = false;

    try {
      canCreate = await _ktxRepository.isKtxResidentEligible();
    } catch (_) {
      canCreate = false;
    }

    // Lịch sử phản ánh là dữ liệu độc lập với trạng thái lưu trú hiện tại.
    // Ví dụ SV từng phản ánh nhưng hồ sơ hiện chuyển về PENDING vẫn phải xem
    // được issue cũ. Production GET /issues yêu cầu student_code/identity_no.
    try {
      final page = await _ktxRepository.getIssues();
      hasHistory = page.items.isNotEmpty || page.total > 0;
    } catch (_) {
      hasHistory = false;
    }

    if (!mounted) return;
    setState(() {
      _ktxCanCreate = canCreate;
      _ktxHasHistory = hasHistory;
      _checkingKtxEligibility = false;
      if (!_ktxVisible && _sourceIndex == 1) _sourceIndex = 0;
    });
  }

  Future<void> _createIssue() async {
    if (_isKtx) {
      if (!_ktxCanCreate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bạn vẫn có thể xem lịch sử phản ánh KTX, nhưng hiện chưa có phòng lưu trú để tạo phản ánh mới.',
            ),
          ),
        );
        return;
      }

      final bool? created = await Get.to<bool>(
        () => const KtxIssueCreateView(),
      );
      if (created == true && mounted) {
        setState(() => _ktxReloadToken++);
      }
      return;
    }

    await Get.to(() => const VcorePahtCreateViewV2());
  }

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Phản ánh hiện trường',
      actions: <Widget>[
        if (!_isKtx)
          IconButton(
            tooltip: 'Tìm kiếm',
            onPressed: () {
              Get.to(() => VcorePahtSearchViewV2());
            },
            icon: svgAsset(
              'assets/images/ic_search.svg',
              color: Colors.black87,
              width: 28,
            ),
          )
        else
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () async {
              setState(() => _ktxReloadToken++);
              await _refreshKtxEligibility();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
      body: Column(
        children: <Widget>[
          if (_ktxVisible)
            _PahtSourceSelector(
              currentIndex: _sourceIndex,
              onChanged: (int value) {
                if (value == _sourceIndex) return;
                setState(() => _sourceIndex = value);
              },
            )
          else if (_checkingKtxEligibility)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _ktxVisible
                ? IndexedStack(
                    index: _sourceIndex,
                    children: <Widget>[
                      const _VnuPahtBody(),
                      KtxIssueListView(reloadToken: _ktxReloadToken),
                    ],
                  )
                : const _VnuPahtBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.colorMain,
        onPressed: _createIssue,
        icon: const Icon(
          Icons.edit_rounded,
          color: Colors.white,
        ),
        label: Text(
          _isKtx ? (_ktxCanCreate ? 'Phản ánh KTX' : 'Chưa thể tạo mới') : 'Tạo phản ánh',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PahtSourceSelector extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _PahtSourceSelector({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEEB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SourceButton(
              selected: currentIndex == 0,
              icon: Icons.account_balance_outlined,
              label: 'ĐHQGHN',
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _SourceButton(
              selected: currentIndex == 1,
              icon: Icons.home_work_outlined,
              label: 'Ký túc xá',
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.colorMain : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 11,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                color: selected
                    ? Colors.white
                    : const Color(0xFF546158),
                size: 18,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : const Color(0xFF354039),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VnuPahtBody extends StatelessWidget {
  const _VnuPahtBody();

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          _PahtV2HeaderTabs(),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                VcorePahtComunitationViewV2(),
                VcorePahtPersonViewV2(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PahtV2HeaderTabs extends StatelessWidget {
  const _PahtV2HeaderTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: AppTheme.colorMain,
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF0B1B44),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const <Widget>[
          Tab(text: 'Cộng đồng'),
          Tab(text: 'Của tôi'),
        ],
      ),
    );
  }
}
