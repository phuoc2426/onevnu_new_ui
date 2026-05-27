import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/models/hoi_dap_model.dart';

class VcoreQuestionItemWidget extends StatefulWidget {
  final HoiDapModel question;
  const VcoreQuestionItemWidget({super.key, required this.question});

  @override
  State<VcoreQuestionItemWidget> createState() =>
      _VcoreQuestionItemWidgetState();
}

class _VcoreQuestionItemWidgetState extends State<VcoreQuestionItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question.cauHoi ?? '',
              style: TextStyles.semiBold.copyWith(fontSize: 16),
              maxLines: 2,
            ),
            spaceHeight(12),
            Row(
              children: [
                SizedBox(
                  width: 83,
                  child: Text(
                    'Chủ đề:',
                    style: TextStyles.regular
                        .copyWith(color: const Color(0xff003392)),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.question.tenChuDe ?? '',
                    style: TextStyles.regular
                        .copyWith(color: const Color(0xff637392)),
                  ),
                )
              ],
            ),
            spaceHeight(8),
            Row(
              children: [
                SizedBox(
                  width: 83,
                  child: Text(
                    'Ngày gửi:',
                    style: TextStyles.regular
                        .copyWith(color: const Color(0xff003392)),
                  ),
                ),
                Expanded(
                  child: Text(
                    DateTimeUtils.stringFromDateTime(
                        widget.question.thoiGianGui,
                        DateTimeConst.U_SECOND_FORMAT),
                    style: TextStyles.regular
                        .copyWith(color: const Color(0xff637392)),
                  ),
                )
              ],
            ),
          ],
        ));
  }
}
