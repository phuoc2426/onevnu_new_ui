import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/models/lich_thi_hoc_ky_model.dart';

class VcoreTimeScheduleDetailWidget extends StatefulWidget {
  final LichThiHocKyModel lichThiHocKyModel;
  const VcoreTimeScheduleDetailWidget(
      {super.key, required this.lichThiHocKyModel});

  @override
  State<VcoreTimeScheduleDetailWidget> createState() =>
      _VcoreTimeScheduleDetailWidgetState();
}

class _VcoreTimeScheduleDetailWidgetState
    extends State<VcoreTimeScheduleDetailWidget> {
  @override
  Widget build(BuildContext context) {
    DateTime? dateTime;
    try {
      DateFormat format = DateFormat("dd/MM/yyyy");
      dateTime = format.parse(widget.lichThiHocKyModel.ngayThi ?? '');
    } catch (e) {
      logError('VcoreTimeScheduleDetailWidget build err -> ${e.toString()}');
    }
    String diadiemThi =
        '${widget.lichThiHocKyModel.phongThi}, ${widget.lichThiHocKyModel.diaChi}';
    String soBaoDanh = "SBD: ${widget.lichThiHocKyModel.sobaodanh ?? "Không xác định"}";
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Thông tin chi tiết lịch thi',
            style: TextStyles.semiBold
                .copyWith(fontSize: 18, color: const Color(0xff003392)),
          ),
          spaceHeight(30),
          Text(
            soBaoDanh,
            style: TextStyles.semiBold
                .copyWith(fontSize: 19,fontWeight: FontWeight.w800,color: Colors.black),
          ),
          Text(
            DateTimeUtils.stringFromDateTime(
              dateTime,
              DateTimeConst.DATE_FORMAT_WITH_DAY,
            ),
            style: TextStyles.semiBold
                .copyWith(fontSize: 18, color: const Color(0xff2F9E44)),
          ),
          spaceHeight(30),

          //for (var i in [2, 3, 4, 5]) rowInfo(i),
          if ((widget.lichThiHocKyModel.phongThi ?? '').isNotEmpty ||
              (widget.lichThiHocKyModel.diaChi ?? '').isNotEmpty) ...[
            rowInfo('Địa điểm thi:', diadiemThi),
            spaceHeight(12),
          ],
          rowInfo('Thời gian:',
              'Ca ${widget.lichThiHocKyModel.caThi}, Bắt đầu thi: ${widget.lichThiHocKyModel.gioBatDauThi}'),
          spaceHeight(12),
          if ((widget.lichThiHocKyModel.thoiLuong ?? '').isNotEmpty) ...[
            rowInfo(
                'Thời gian thi: ', widget.lichThiHocKyModel.thoiLuong ?? ''),
            spaceHeight(12),
          ],
          rowInfo('Mã học phần:', widget.lichThiHocKyModel.maHocPhan ?? ''),
          spaceHeight(12),
          rowInfo('Tên học phần:', widget.lichThiHocKyModel.tenHocPhan ?? ''),
          spaceHeight(12),
          rowInfo('Số tín chỉ:', widget.lichThiHocKyModel.soTinChi ?? ''),
          spaceHeight(12),
          rowInfo('Hình thức thi:', widget.lichThiHocKyModel.hinhThucThi ?? ''),
          spaceHeight(12),

          spaceHeight(60),
          // Close button
          OutlinedButton(
            onPressed: () {
              Get.back();
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(width: 1.0, color: Color(0xff003392)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                'Đóng',
                style: TextStyles.semiBold
                    .copyWith(fontSize: 16, color: const Color(0xff003392)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget rowInfo(String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: Text(
          title,
          style: TextStyles.regular.copyWith(fontSize: 15, color: Colors.black),
        )),
        Expanded(
            child: Text(
          content,
          style:
              TextStyles.semiBold.copyWith(fontSize: 15, color: Colors.black),
        )),
      ],
    );
  }
}
