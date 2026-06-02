import 'package:flutter/material.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import '../models/model.dart';
import 'package:vnu_core/common/app_text_styles.dart';

class NTRegisterPriceWidget extends StatefulWidget {
  final List<DanhSachLoaiPhi> danhSachLoaiPhi;
  const NTRegisterPriceWidget({super.key, required this.danhSachLoaiPhi});

  @override
  State<NTRegisterPriceWidget> createState() => _NTRegisterPriceWidgetState();
}

class _NTRegisterPriceWidgetState extends State<NTRegisterPriceWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.danhSachLoaiPhi.length,
          itemBuilder: (context, index) {
            return itemPrice(widget.danhSachLoaiPhi[index], false);
          }),
    );
  }

  Widget itemPrice(DanhSachLoaiPhi chiphi, bool? font) {
    return Container(
      margin: const EdgeInsets.only(top: 15, bottom: 8),
      padding: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 0.2))),
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child: Text(
                chiphi.tenLoaiPhi ?? '',
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
                  chiphi.soTien?.formNum() ?? '',
                  style: AppTheme.body2
                      .copyWith(fontSize: AppFontSizes.medium, fontWeight: FontWeight.w600),
                ),
              )),
        ],
      ),
    );
  }
}
