import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/don_vi_model.dart';
import 'package:vnu_core/modules/news/controllers/vcore_news_controller.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_datefield_widget.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import '../../profile/views/widget/vcore_profile_dropdownfield_widget.dart';

class VcoreNewsFilterWidget extends StatefulWidget {
  final VcoreNewsController controller;
  // final List<DonViModel> listDonVi;
  // final DonViModel? currentDonVi;
  // final DateTime? startDate;
  // final DateTime? endDate;
  const VcoreNewsFilterWidget({
    super.key,
    required this.controller,
    // required this.listDonVi,
    // required this.currentDonVi,
    // required this.startDate,
    // required this.endDate,
  });

  @override
  State<VcoreNewsFilterWidget> createState() => _VcoreNewsFilterWidgetState();
}

class _VcoreNewsFilterWidgetState extends State<VcoreNewsFilterWidget> {
  DonViModel? selectedDonvi;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  void initState() {
    super.initState();
    selectedDonvi = widget.controller.currentDonVi.value;
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
        VcoreProfileDropdownfieldWidget(
          title: 'Đơn vị phát hành',
          hintText: 'Chọn đơn vị phát hành',
          value: selectedDonvi?.tenDonVi,
          items:
              widget.controller.listDonVi.map((e) => e.tenDonVi ?? '').toList(),
          onSelected: (value) {
            DonViModel? donvi =
                widget.controller.listDonVi.firstWhereOrNull((e) {
              return e.tenDonVi == value;
            });
            if (donvi != null) {
              setState(() {
                selectedDonvi = donvi;
              });
            }
          },
        ),
        spaceHeight(12),

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
                  widget.controller.currentDonVi.value = selectedDonvi;
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
