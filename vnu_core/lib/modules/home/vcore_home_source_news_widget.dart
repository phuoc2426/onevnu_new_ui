import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/nguon_tin_model.dart';
import 'package:vnu_core/modules/browser/views/vcore_browser_view.dart';
import 'package:vnu_core/services/services_url.dart';

class VcoreHomeSourceNewsWidget extends StatefulHookWidget {
  final List<NguonTinModel> listNguonTin;

  const VcoreHomeSourceNewsWidget({super.key, required this.listNguonTin});

  @override
  State<VcoreHomeSourceNewsWidget> createState() =>
      _VcoreHomeSourceNewsWidgetState();
}

class _VcoreHomeSourceNewsWidgetState extends State<VcoreHomeSourceNewsWidget> {
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final marginLeft = useState(0.0);
    return Column(
      children: [
        SizedBox(
          height: 210,
          width: double.infinity,
          child: NotificationListener<ScrollUpdateNotification>(
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.listNguonTin.length,
              controller: _controller,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (BuildContext context, int index) {
                NguonTinModel nguonTinModel = widget.listNguonTin[index];
                return InkWell(
                  onTap: () {
                    Get.to(
                      () => VcoreBrowserView(
                        title: nguonTinModel.tieuDe ?? '',
                        url: nguonTinModel.linkLienKet ?? '',
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(6),
                        child: CachedNetworkImage(
                          imageUrl:
                              '${ServicesUrl().baseUrlFileDownload}${nguonTinModel.guidFileLogoNguonTins?.first}',
                          cacheKey:
                              '${ServicesUrl().baseUrlFileDownload}${nguonTinModel.guidFileLogoNguonTins?.first}',
                          httpHeaders: Globals().headerToken(),
                        ),
                      ),
                      Text(
                        nguonTinModel.tieuDe ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyles.regular.copyWith(fontSize: 13),
                        maxLines: 2,
                      )
                    ],
                  ),
                );
              },
            ),
            onNotification: (notification) {
              double newMargin = (notification.metrics.pixels /
                      _controller.position.maxScrollExtent) *
                  (2.0 / 3.0) *
                  30.0;
              newMargin = max(0, newMargin);

              newMargin = min(newMargin, 20);
              marginLeft.value = newMargin;
              return true;
            },
          ),
        ),

        // Scroll indicator
        SizedBox(
          width: double.infinity,
          height: 20,
          child: Center(
            child: Stack(
              children: [
                Container(
                  height: 5,
                  width: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xffDDE3EE),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Container(
                  height: 5,
                  width: 10,
                  margin: EdgeInsets.only(left: marginLeft.value),
                  decoration: BoxDecoration(
                    color: const Color(0xff003392),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
