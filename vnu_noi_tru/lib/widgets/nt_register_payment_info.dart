import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_noi_tru/widgets/nt_register_infrastructure_widget.dart';
import 'package:vnu_noi_tru/widgets/nt_register_price_widget.dart';

import '../models/model.dart';

class NTRegisterPaymentInfoWidget extends StatefulWidget {
  final DanhSachLoaiPhong? loaiPhong;
  const NTRegisterPaymentInfoWidget({super.key, required this.loaiPhong});

  @override
  State<NTRegisterPaymentInfoWidget> createState() =>
      _NTRegisterPaymentInfoWidgetState();
}

class _NTRegisterPaymentInfoWidgetState
    extends State<NTRegisterPaymentInfoWidget>
    with SingleTickerProviderStateMixin {
  late PageController controller;
  late TabController tabController;

  List<DanhSachLoaiPhi> danhSachLoaiPhi = [];

  @override
  void initState() {
    super.initState();
    controller = PageController();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    danhSachLoaiPhi = List.of(widget.loaiPhong?.danhSachLoaiPhi ?? []);

    var totalPrice = 0.0;
    for (var item in danhSachLoaiPhi) {
      totalPrice += item.soTien?.parseDouble() ?? 0.0;
    }
    DanhSachLoaiPhi total =
        DanhSachLoaiPhi(tenLoaiPhi: 'Tổng cộng', soTien: '$totalPrice');

    danhSachLoaiPhi.add(total);

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 50,
            color: const Color(0xffF6F9FE),
            child: TabBar(
              labelColor: AppTheme.colorMain,
              unselectedLabelColor: const Color(0xff879ABF),
              indicatorColor: const Color(0xff003392),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: AppTheme.body1.copyWith(fontWeight: FontWeight.w600),
              controller: tabController,
              onTap: (value) {
                controller.animateToPage(value,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.ease);
              },
              tabs: const [
                Tab(
                  text: 'Loại phí',
                ),
                Tab(
                  text: 'Cơ sở vật chất',
                ),
              ],
            ),
          ),
          ExpandablePageView(
            onPageChanged: (value) {
              tabController.animateTo(value);
            },
            controller: controller,
            children: [
              NTRegisterPriceWidget(
                danhSachLoaiPhi: danhSachLoaiPhi,
              ),
              NTRegisterInfrastructureWidget(
                  danhSachLoaiCoSoVatChat:
                      widget.loaiPhong?.danhSachLoaiCoSoVatChat ?? []),
            ],
          ),
        ],
      ),
    );
  }
}
