import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/model.dart';

class VcoreHomeNotifyWidget extends StatefulWidget {
  final List<TopThongBaoModel> listThongBao;
  final void Function(TopThongBaoModel thongbao) onViewDetail;

  const VcoreHomeNotifyWidget(
      {super.key, required this.listThongBao, required this.onViewDetail});

  @override
  State<VcoreHomeNotifyWidget> createState() => _VcoreHomeNotifyWidgetState();
}

class _VcoreHomeNotifyWidgetState extends State<VcoreHomeNotifyWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (context, index) => spaceHeight(15),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: widget.listThongBao.length,
      itemBuilder: (ctx, index) {
        TopThongBaoModel thongbao = widget.listThongBao[index];
        return InkWell(
            onTap: () {
              widget.onViewDetail(thongbao);
            },
            child: itemNotify(thongbao.tieuDe ?? ''));
      },
    );
  }

  Widget itemNotify(String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyles.regular,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          svgAction('assets/images/ic_new.svg')
        ],
      ),
    );
  }
}
