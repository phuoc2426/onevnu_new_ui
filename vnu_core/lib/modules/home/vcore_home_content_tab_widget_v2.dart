import 'package:flutter/material.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/news/views/vcore_news_tab_widget_v2.dart';
import 'package:vnu_core/modules/home/vcore_home_notify_tab_widget_v2.dart';

/// Widget wrapper that integrates both VcoreNewsTabWidgetV2 and VcoreHomeNotifyTabWidgetV2
/// to display news and notification tabs seamlessly in VcoreHomeViewV2.
class VcoreHomeContentTabWidgetV2 extends StatelessWidget {
  final List<TopTinTucModel> listTinTucVNU;
  final List<TopTinTucModel> listTinTucBySchool;
  final List<TinTucModel> listTinTuc2;
  final Function(TopTinTucModel) onViewDetailNewsVNU;
  final String schoolName;
  final List<ThongBaoDaoTaoModel> listThongBaoDaoTao;
  final List<TopThongBaoModel> listThongBaoVNU;
  final Function(ThongBaoDaoTaoModel) onViewDetailDaoTao;
  final Function(TopThongBaoModel) onViewDetailThongBaoVNU;

  const VcoreHomeContentTabWidgetV2({
    super.key,
    required this.listTinTucVNU,
    required this.listTinTucBySchool,
    required this.listTinTuc2,
    required this.onViewDetailNewsVNU,
    required this.schoolName,
    required this.listThongBaoDaoTao,
    required this.listThongBaoVNU,
    required this.onViewDetailDaoTao,
    required this.onViewDetailThongBaoVNU,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VcoreNewsTabWidgetV2(
          listTinTucVNU: listTinTucVNU,
          listTinTucBySchool: listTinTucBySchool,
          listTinTuc2: listTinTuc2,
          onViewDetailVNU: onViewDetailNewsVNU,
          schoolName: schoolName,
        ),
        spaceHeight(16),
        VcoreHomeNotifyTabWidgetV2(
          listThongBaoDaoTao: listThongBaoDaoTao,
          listThongBaoVNU: listThongBaoVNU,
          onViewDetailDaoTao: onViewDetailDaoTao,
          onViewDetailVNU: onViewDetailThongBaoVNU,
        ),
      ],
    );
  }
}