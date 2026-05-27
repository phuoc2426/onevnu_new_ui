import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_datefield_widget.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import '../controllers/vcore_system_news_controller.dart';

class VcoreSystemNewsFilterWidget extends StatefulWidget {
  final VcoreSystemNewsController controller;
  const VcoreSystemNewsFilterWidget({
    super.key,
    required this.controller,
  });

  @override
  State<VcoreSystemNewsFilterWidget> createState() =>
      _VcoreSystemNewsFilterWidgetState();
}

class _VcoreSystemNewsFilterWidgetState
    extends State<VcoreSystemNewsFilterWidget> {
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  void initState() {
    super.initState();
    selectedStartDate = widget.controller.startDate.value;
    selectedEndDate = widget.controller.endDate.value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        spaceHeight(14),
        Text(
          'Tìm kiếm nâng cao',
          style: TextStyles.bold
              .copyWith(fontSize: 18, color: const Color(0xff003392)),
        ),
        spaceHeight(18),

        // - Ngay
        Row(children: [
          Expanded(
              child: VcoreProfileDatefieldWidget(
            title: 'Thời gian phát hành',
            hintText: 'Từ ngày',
            value: selectedStartDate,
            onChangeDate: (selectedDate) {
              setState(() {
                selectedStartDate = selectedDate;
              });
            },
          )),
          spaceWidth(10),
          Expanded(
              child: VcoreProfileDatefieldWidget(
            title: '',
            hintText: 'Đến ngày',
            value: selectedEndDate,
            onChangeDate: (selectedDate) {
              setState(() {
                selectedEndDate = selectedDate;
              });
            },
          )),
        ]),

        //
        spaceHeight(24),
        Row(
          children: [
            Expanded(
              child: WhiteButton(
                title: 'Đóng',
                action: () {
                  Get.back();
                },
              ),
            ),
            spaceWidth(8),
            Expanded(
              child: BlueButton(
                title: 'Áp dụng',
                action: () {
                  widget.controller.startDate.value = selectedStartDate;
                  widget.controller.endDate.value = selectedEndDate;

                  widget.controller.refreshData();
                  Get.back(closeOverlays: true);
                },
              ),
            )
          ],
        ),
        spaceHeight(26),
      ],
    );
  }
}
