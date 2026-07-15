import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/vcore_browser_controller.dart';

class VcoreBrowserView extends GetView<VcoreBrowserController> {
  final String title;
  final String? url;
  final String? html;
  const VcoreBrowserView({
    super.key,
    required this.title,
    this.url,
    this.html,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreBrowserController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        if (url != null) {
          controller.loadUrl(url!);
        } else if (html != null) {
          controller.loadHtml(html!);
        }
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: VcoreModuleScaffold(
            title: title,
            showBackButton: true,
            body: Column(
              children: [
                // StreamBuilder(
                //     stream: controller.progessController.stream,
                //     builder: (context, snapshot) {
                //       if ((snapshot.data ?? 0) >= 100) {
                //         return const SizedBox();
                //       }
                //       return LinearProgressIndicator(
                //         value: (snapshot.data ?? 0) / 100,
                //         backgroundColor: const Color(0xffC7C7C7),
                //         color: const Color(0xff00B247),
                //       );
                //     }),
                Expanded(
                  child: WebViewWidget(controller: controller.webController),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
