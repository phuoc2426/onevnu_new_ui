import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/vnu_module_app_bar.dart';
import 'package:vnu_core/widgets/vnu_chrome_icon.dart';

/// Future chart entry. Do not invent student GPA or render fake semesters.
class VcoreLearningChartPlaceholderView extends StatelessWidget {
  const VcoreLearningChartPlaceholderView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F8F7),
    appBar: const VnuModuleAppBar(title: 'Quá trình học tập'),
    body: const Center(child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        VnuChromeIcon(name: 'chart', size: 80),
        SizedBox(height: 18),
        Text('Biểu đồ quá trình học tập', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
            color: Color(0xFF17241F))),
        SizedBox(height: 8),
        Text('Đang chờ mẫu hiệu ứng và dữ liệu học kỳ để hiển thị '
          'tiến trình học tập chính xác.', textAlign: TextAlign.center,
          style: TextStyle(height: 1.5, fontSize: 14,
            color: Color(0xFF66716D))),
      ]),
    )),
  );
}
