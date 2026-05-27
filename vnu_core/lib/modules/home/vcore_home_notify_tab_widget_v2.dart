import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/thong_bao_dao_tao_model.dart';
import 'package:vnu_core/models/top_thong_bao_model.dart';

/// Widget hiển thị thông báo dạng tabs ở trang chủ
/// Tab 1: Thông báo Đào tạo
/// Tab 2: Thông báo VNU
class VcoreHomeNotifyTabWidgetV2 extends StatefulWidget {
  /// Danh sách thông báo đào tạo
  final List<ThongBaoDaoTaoModel> listThongBaoDaoTao;

  /// Danh sách thông báo VNU (Top 10)
  final List<TopThongBaoModel> listThongBaoVNU;

  /// Callback khi xem chi tiết thông báo đào tạo
  final Function(ThongBaoDaoTaoModel) onViewDetailDaoTao;

  /// Callback khi xem chi tiết thông báo VNU
  final Function(TopThongBaoModel) onViewDetailVNU;

  const VcoreHomeNotifyTabWidgetV2({
    super.key,
    required this.listThongBaoDaoTao,
    required this.listThongBaoVNU,
    required this.onViewDetailDaoTao,
    required this.onViewDetailVNU,
  });

  @override
  State<VcoreHomeNotifyTabWidgetV2> createState() =>
      _VcoreHomeNotifyTabWidgetV2State();
}

class _VcoreHomeNotifyTabWidgetV2State extends State<VcoreHomeNotifyTabWidgetV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xffF0F4FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xff003392),
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(4),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xff637392),
            labelStyle: TextStyles.medium.copyWith(fontSize: 13),
            unselectedLabelStyle: TextStyles.regular.copyWith(fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'TB Đào tạo'),
              Tab(text: 'TB VNU'),
            ],
          ),
        ),
        spaceHeight(12),
        // Tab Content - Không có chiều cao cố định, tự động theo nội dung
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, child) {
            return IndexedStack(
              index: _tabController.index,
              children: [
                // Tab 1: Thông báo Đào tạo
                _buildThongBaoDaoTaoList(),
                // Tab 2: Thông báo VNU
                _buildThongBaoVNUList(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildThongBaoDaoTaoList() {
    if (widget.listThongBaoDaoTao.isEmpty) {
      return _buildEmptyState('Chưa có thông báo đào tạo');
    }

    return ListView.separated(
      separatorBuilder: (context, index) => spaceHeight(10),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: widget.listThongBaoDaoTao.length > 5
          ? 5
          : widget.listThongBaoDaoTao.length,
      itemBuilder: (ctx, index) {
        ThongBaoDaoTaoModel thongbao = widget.listThongBaoDaoTao[index];
        return thongbao.tieuDe?.isNotEmpty == true
            ? InkWell(
                onTap: () => widget.onViewDetailDaoTao(thongbao),
                child: _buildNotifyItemDaoTao(thongbao.tieuDe!),
              )
            : const SizedBox.shrink();
      },
    );
  }

  Widget _buildThongBaoVNUList() {
    if (widget.listThongBaoVNU.isEmpty) {
      return _buildEmptyState('Chưa có thông báo VNU');
    }

    return ListView.separated(
      separatorBuilder: (context, index) => spaceHeight(10),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount:
          widget.listThongBaoVNU.length > 5 ? 5 : widget.listThongBaoVNU.length,
      itemBuilder: (ctx, index) {
        TopThongBaoModel thongbao = widget.listThongBaoVNU[index];
        return InkWell(
          onTap: () => widget.onViewDetailVNU(thongbao),
          child: _buildNotifyItemVNU(thongbao.tieuDe ?? ''),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          message,
          style: TextStyles.regular.copyWith(
            color: const Color(0xff879ABF),
          ),
        ),
      ),
    );
  }

  Widget _buildNotifyItemDaoTao(String content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Icon thông báo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xffFFF4E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: Color(0xffFF9500),
              size: 20,
            ),
          ),
          spaceWidth(12),
          // Nội dung
          Expanded(
            child: Html(
              data: content,
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(13),
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                ),
              },
            ),
          ),
          // Icon mới
          svgAsset('assets/images/ic_new.svg', width: 20, height: 20),
        ],
      ),
    );
  }

  Widget _buildNotifyItemVNU(String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Icon thông báo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xffE8F4FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xff003392),
              size: 20,
            ),
          ),
          spaceWidth(12),
          // Nội dung
          Expanded(
            child: Text(
              title,
              style: TextStyles.regular.copyWith(
                fontSize: 13,
                color: const Color(0xff2A3556),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Icon mới
          svgAsset('assets/images/ic_new.svg', width: 20, height: 20),
        ],
      ),
    );
  }
}
