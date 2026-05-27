import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/models/lich_thi_hoc_ky_model.dart';
import 'package:vnu_core/modules/time_schedule/views/vcore_time_schedule_detail_widget.dart';

import '../../../common/app_text_styles.dart';
import '../../../common/space_widget.dart';
import '../../../common/utils.dart';

class VcoreTimeScheduleSectionWidget extends StatefulWidget {
  final String date;
  final List<LichThiHocKyModel> lichThi;
  const VcoreTimeScheduleSectionWidget(
      {super.key, required this.date, required this.lichThi});

  @override
  State<VcoreTimeScheduleSectionWidget> createState() =>
      _VcoreTimeScheduleSectionWidgetState();
}

class _VcoreTimeScheduleSectionWidgetState
    extends State<VcoreTimeScheduleSectionWidget> {
  @override
  Widget build(BuildContext context) {
    DateFormat format = DateFormat("dd/MM/yyyy");
    DateTime dateTime = format.parse(widget.date);

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 36,
            color: const Color(0xff003392),
            child: Center(
              child: Text(
                DateTimeUtils.stringFromDateTime(
                  dateTime,
                  DateTimeConst.DATE_FORMAT_WITH_DAY,
                ),
                style: TextStyles.regular.copyWith(color: Colors.white),
              ),
            ),
          ),
          spaceHeight(16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (ctx, index) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Get.dialog(
                      Dialog(
                        insetPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: VcoreTimeScheduleDetailWidget(
                          lichThiHocKyModel: widget.lichThi[index],
                        ),
                      ),
                    );
                  },
                  child: TimeScheduleItemWidget(
                    lichThiHocKyModel: widget.lichThi[index],
                  ),
                );
              },
              separatorBuilder: (ctx, index) => spaceHeight(16),
              itemCount: widget.lichThi.length,
            ),
          )
        ],
      ),
    );
  }
}

class TimeScheduleItemWidget extends StatelessWidget {
  final LichThiHocKyModel lichThiHocKyModel;
  const TimeScheduleItemWidget({super.key, required this.lichThiHocKyModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lichThiHocKyModel.tenHocPhan ?? '',
            style: TextStyles.semiBold.copyWith(fontSize: 15),
          ),
          spaceHeight(10),
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Row(
              children: [
                svgAsset('assets/images/ic_time.svg'),
                spaceWidth(10),
                Expanded(
                    child: Text(
                        'Ca: ${lichThiHocKyModel.caThi}. Bắt đầu thi: ${lichThiHocKyModel.gioBatDauThi}',
                        style: TextStyles.regular.copyWith(
                          fontSize: 13,
                          color: const Color(0xff637392),
                        )))
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget itemDay(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        children: [
          svgAsset('assets/images/ic_time.svg'),
          spaceWidth(10),
          Expanded(
              child: Text('Ca: 1. Bắt đầu thi: 08:00. Thời gian thi: 90 Phút',
                  style: TextStyles.regular.copyWith(
                    fontSize: 13,
                    color: const Color(0xff637392),
                  )))
        ],
      ),
    );
  }
}
