import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/widgets/navi_widget.dart';

class VcoreCamNangDetailView extends StatefulWidget {
  const VcoreCamNangDetailView({super.key});

  @override
  State<VcoreCamNangDetailView> createState() => _VcoreCamNangDetailViewState();
}

class _VcoreCamNangDetailViewState extends State<VcoreCamNangDetailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NaviWidget(
        titleStr: 'Đối tượng ưu đãi vào ở KTX',
      ),
      backgroundColor: AppColor.bgColor,
      body: Container(
        child: Center(
          child: Text('Detail'),
        ),
      ),
    );
  }
}
