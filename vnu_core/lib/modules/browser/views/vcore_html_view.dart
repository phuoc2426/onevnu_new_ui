import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:octo_image/octo_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/widgets/navi_widget.dart';

class VcoreHtmlView extends StatefulWidget {
  final String title;
  final String html;

  const VcoreHtmlView({super.key, required this.title, required this.html});

  @override
  State<VcoreHtmlView> createState() => _VcoreHtmlViewState();
}

class _VcoreHtmlViewState extends State<VcoreHtmlView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NaviWidget(
        titleStr: widget.title,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Html(
            data: widget.html,
            onLinkTap: (url, attributes, element) {
              logSuccess('Tap url --> $url');
              if (url != null) {
                launchUrl(Uri.parse(url));
              }
            },
            extensions: [
              TagExtension(
                tagsToExtend: {"img"},
                builder: (context) => CssBoxWidget(
                  style: context.styledElement!.style,
                  child: CachedNetworkImage(
                    imageUrl: context.attributes['src'] ?? '',
                    cacheKey: context.attributes['src'] ?? '',
                    imageBuilder: (context, imageProvider) {
                      return OctoImage(image: imageProvider);
                    },
                    placeholder: (context, url) => Container(
                      height: 250,
                      width: 164,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
