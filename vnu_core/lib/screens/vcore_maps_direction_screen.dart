import 'package:flutter/material.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VcoreMapsDirectionScreen extends StatefulWidget {
  final DiaDiemBanDoSo diaDiemBanDoSo;
  const VcoreMapsDirectionScreen({super.key, required this.diaDiemBanDoSo});

  @override
  State<VcoreMapsDirectionScreen> createState() =>
      _VcoreMapsDirectionScreenState();
}

class _VcoreMapsDirectionScreenState extends State<VcoreMapsDirectionScreen> {
  final controler = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('https://www.youtube.com/')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    String url =
        "https://www.google.com/maps/dir//${widget.diaDiemBanDoSo.toaDo?.replaceAll(' ', '')}";
    controler.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NaviWidget(
        titleStr: 'Bản đồ số',
        leftAction: svgAction('assets/images/ic_navi_back.svg', action: () {
          Navigator.pop(context);
        }),
      ),
      body: WebViewWidget(
        controller: controler,
      ),
    );
  }
}
