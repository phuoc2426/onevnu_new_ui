import 'package:flutter/material.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/common/app_text_styles.dart';

class VCoreSettingScreen extends StatefulWidget {
  const VCoreSettingScreen({super.key});

  @override
  State<VCoreSettingScreen> createState() => _VCoreSettingScreenState();
}

class _VCoreSettingScreenState extends State<VCoreSettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NaviWidget(
        titleStr: 'Cá nhân hoá',
        leftAction: svgAction('assets/images/ic_navi_back.svg', action: () {
          Navigator.pop(context);
        }),
      ),
      backgroundColor: Color.fromRGBO(246, 249, 254, 1),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "Khu vực học tập",
                  style: AppTheme.headline6.copyWith(fontSize: AppFontSizes.extraExtraLarge),
                ),
              ),
              Row(
                children: [
                  Radio<String>(
                    value: Globals().maKhuVuc,
                    onChanged: (valye) {
                      Globals().maKhuVuc = kXuanThuy;
                      Globals().saveMaKhuVuc(kXuanThuy);
                      setState(() {});
                    },
                    groupValue: kXuanThuy,
                  ),
                  const Text(
                    'Xuân Thuỷ',
                    style: AppTheme.body2,
                  )
                ],
              ),
              Row(
                children: [
                  Radio<String>(
                    value: Globals().maKhuVuc,
                    onChanged: (valye) {
                      Globals().maKhuVuc = kHoaLac;
                      Globals().saveMaKhuVuc(kHoaLac);
                      setState(() {});
                    },
                    groupValue: kHoaLac,
                  ),
                  const Text(
                    'Hoà Lạc',
                    style: AppTheme.body2,
                  )
                ],
              ),
              Row(
                children: [
                  Radio<String>(
                    value: Globals().maKhuVuc,
                    onChanged: (valye) {
                      Globals().maKhuVuc = kKhuVucKhac;
                      Globals().saveMaKhuVuc(kKhuVucKhac);
                      setState(() {});
                    },
                    groupValue: kKhuVucKhac,
                  ),
                  const Text(
                    'Khu Vực Khác',
                    style: AppTheme.body2,
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
