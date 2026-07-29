import 'package:get/get.dart';
import 'package:vnu_core/modules/browser/views/vcore_browser_view.dart';

const String kMotelWebUrl = 'https://hostel.mytourvietnam.com/';
const String kMotelWebTitle = 'Ph\u00f2ng tr\u1ecd';

void openMotelWebView() {
  Get.to(
    () => const VcoreBrowserView(
      title: kMotelWebTitle,
      url: kMotelWebUrl,
      useFloatingBackButton: true,
    ),
  );
}
