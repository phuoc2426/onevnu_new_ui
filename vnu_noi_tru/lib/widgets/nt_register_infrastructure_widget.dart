import 'package:flutter/material.dart';
import 'package:vnu_core/themes/app_theme.dart';

import '../models/model.dart';
import 'package:vnu_core/common/app_text_styles.dart';

class NTRegisterInfrastructureWidget extends StatefulWidget {
  final List<DanhSachLoaiCoSoVatChat> danhSachLoaiCoSoVatChat;

  const NTRegisterInfrastructureWidget(
      {super.key, required this.danhSachLoaiCoSoVatChat});

  @override
  State<NTRegisterInfrastructureWidget> createState() =>
      _NTRegisterInfrastructureWidgetState();
}

class _NTRegisterInfrastructureWidgetState
    extends State<NTRegisterInfrastructureWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.danhSachLoaiCoSoVatChat.length,
          itemBuilder: (context, index) {
            return itemPrice(widget.danhSachLoaiCoSoVatChat[index], false);
          }),
    );
  }

  Widget itemPrice(DanhSachLoaiCoSoVatChat chiphi, bool? font) {
    return Container(
      margin: const EdgeInsets.only(top: 15, bottom: 8),
      padding: const EdgeInsets.only(bottom: 15),
      decoration:
          const BoxDecoration(border: Border(bottom: BorderSide(width: 0.2))),
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child: Text(
                chiphi.tenLoaiCsvc ?? '',
                style: AppTheme.body2.copyWith(
                    fontSize: AppFontSizes.mediumLarge,
                    fontWeight:
                        font == true ? FontWeight.bold : FontWeight.normal),
              )),
          Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${chiphi.soLuong}',
                  style: AppTheme.body2
                      .copyWith(fontSize: AppFontSizes.medium, fontWeight: FontWeight.bold),
                ),
              )),
        ],
      ),
    );
  }
}
