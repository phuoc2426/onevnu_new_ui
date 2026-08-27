import 'package:flutter/material.dart';

import '../flow/app_guide_flow.dart';
import '../models/app_guide_item_type.dart';
import '../models/app_guide_search_result.dart';
import '../services/app_guide_search_service.dart';
import 'package:vnu_core/widgets/field/vnu_text_field.dart';

class AppGuideSearchSheet extends StatefulWidget {
  const AppGuideSearchSheet({
    super.key,
    required this.searchService,
    required this.onOpenGuide,
    this.manualFlows = const <AppGuideFlow>[],
    this.onOpenFlow,
    this.moduleId,
  });

  final AppGuideSearchService searchService;
  final Future<void> Function(AppGuideSearchResult result) onOpenGuide;
  final List<AppGuideFlow> manualFlows;
  final Future<void> Function(AppGuideFlow flow)? onOpenFlow;
  final String? moduleId;

  @override
  State<AppGuideSearchSheet> createState() => _AppGuideSearchSheetState();
}

class _AppGuideSearchSheetState extends State<AppGuideSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _loading = false;
  List<AppGuideSearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();

    setState(() => _loading = true);

    final results = await widget.searchService.search(
      query,
      moduleId: widget.moduleId,
    );

    if (!mounted) return;

    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    final normalizedFlowQuery = _controller.text.trim().toLowerCase();
    final manualFlows = widget.manualFlows.where((flow) {
      if (normalizedFlowQuery.isEmpty) return true;
      final haystack = [
        flow.id,
        flow.title,
        flow.description ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(normalizedFlowQuery);
    }).toList();

    final navigationResults = _results.where((result) {
      return result.item.type == AppGuideItemType.page ||
          result.item.type == AppGuideItemType.function;
    }).toList();

    final sectionResults = _results.where((result) {
      return result.item.type == AppGuideItemType.section;
    }).toList();

    final widgetResults = _results.where((result) {
      return result.item.type == AppGuideItemType.widget;
    }).toList();

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: bottom + 16,
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
              decoration: TextDecoration.none,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tìm chức năng / hướng dẫn',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                VnuFloatingTextFieldAdapter(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: const Color(0xFF047747),
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: xem điểm, lịch thi, hồ sơ, thông báo...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF047747),
                    ),
                    suffixIcon: IconButton(
                      onPressed: _search,
                      icon: const Icon(
                        Icons.manage_search_rounded,
                        color: Color(0xFF047747),
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF047747),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const LinearProgressIndicator(
                    color: Color(0xFF047747),
                    backgroundColor: Color(0xFFE5E7EB),
                  ),
                if (!_loading && _results.isEmpty && manualFlows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Nhập chức năng hoặc khu vực bạn cần. Kết quả mở màn hình sẽ nằm phía trên, kết quả chỉ highlight khu vực sẽ nằm phía dưới.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        height: 1.35,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (manualFlows.isNotEmpty && widget.onOpenFlow != null)
                        _FlowSection(
                          flows: manualFlows,
                          onOpenFlow: widget.onOpenFlow!,
                        ),
                      if (navigationResults.isNotEmpty)
                        _ResultSection(
                          title: 'Đi tới chức năng',
                          icon: Icons.open_in_new_rounded,
                          results: navigationResults,
                          onOpenGuide: widget.onOpenGuide,
                        ),
                      if (sectionResults.isNotEmpty)
                        _ResultSection(
                          title: 'Hướng dẫn khu vực',
                          icon: Icons.dashboard_customize_rounded,
                          results: sectionResults,
                          onOpenGuide: widget.onOpenGuide,
                        ),
                      if (widgetResults.isNotEmpty)
                        _ResultSection(
                          title: 'Chi tiết liên quan',
                          icon: Icons.ads_click_rounded,
                          results: widgetResults,
                          onOpenGuide: widget.onOpenGuide,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlowSection extends StatelessWidget {
  const _FlowSection({
    required this.flows,
    required this.onOpenFlow,
  });

  final List<AppGuideFlow> flows;
  final Future<void> Function(AppGuideFlow flow) onOpenFlow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.route_rounded,
                size: 17,
                color: Color(0xFF047747),
              ),
              SizedBox(width: 6),
              Text(
                'Kịch bản hướng dẫn',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF047747),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...flows.map(
            (flow) => InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onOpenFlow(flow),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF047747).withOpacity(0.11),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.play_circle_outline_rounded,
                        color: Color(0xFF047747),
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            flow.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            flow.description ??
                                '${flow.steps.length} bước · ${flow.id}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFF047747),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.title,
    required this.icon,
    required this.results,
    required this.onOpenGuide,
  });

  final String title;
  final IconData icon;
  final List<AppGuideSearchResult> results;
  final Future<void> Function(AppGuideSearchResult result) onOpenGuide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: const Color(0xFF047747)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF047747),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...results.map((result) {
            return _ResultTile(
              result: result,
              onTap: () => onOpenGuide(result),
            );
          }),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.result,
    required this.onTap,
  });

  final AppGuideSearchResult result;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final item = result.item;
    final isNavigationItem = item.type == AppGuideItemType.page ||
        item.type == AppGuideItemType.function;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isNavigationItem
              ? const Color(0xFFECFDF5)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isNavigationItem
                ? const Color(0xFFA7F3D0)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF047747).withOpacity(0.11),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                item.icon,
                color: const Color(0xFF047747),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isNavigationItem
                  ? Icons.arrow_forward_rounded
                  : Icons.center_focus_strong_rounded,
              color: const Color(0xFF047747),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

