import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/modules/news/views/vcore_news_detail_view.dart';
import 'package:get/get.dart';

import '../../common/app_text_styles.dart';
import '../../common/space_widget.dart';
import '../../models/top_tin_tuc_model.dart';
import '../../models/tin_tuc_model.dart';
import 'package:vnu_core/constants/config.dart';

class VcoreHomeNewsWidget extends StatefulWidget {
  final List<TopTinTucModel> listTinTuc;
  final void Function(TopTinTucModel tintuc) onViewDetail;
  final int type;
  final List<TinTucModel> ? listTinTuc2;
  const VcoreHomeNewsWidget(
      {super.key, required this.listTinTuc, required this.onViewDetail,this.type=1,this.listTinTuc2});

  @override
  State<VcoreHomeNewsWidget> createState() => _VcoreHomeNewsWidgetState();
}

class _VcoreHomeNewsWidgetState extends State<VcoreHomeNewsWidget> {
  final ScrollController _controller = ScrollController();
  double marginLeft = 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 136,
          child: NotificationListener<ScrollUpdateNotification>(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              separatorBuilder: (context, index) => spaceWidth(15),
              controller: _controller,
              itemCount: widget.type == 1
                  ? widget.listTinTuc.length
                  : (widget.listTinTuc2?.length ?? 0),
              itemBuilder: (ctx, index) {
                if (widget.type == 1) {
                  // Trường hợp type == 1 => dùng TopTinTucModel
                  TopTinTucModel tinTucModel = widget.listTinTuc[index];

                  String imageUrl = tinTucModel.anhDaiDien ??'';
                  String cacheKey = tinTucModel.anhDaiDien ??'';

                  return _buildNewsItem(
                    imageUrl: imageUrl,
                    cacheKey: cacheKey,
                    title: tinTucModel.tieuDe,
                    onTap: () {
                      widget.onViewDetail(tinTucModel);
                    },
                  );
                } else {
                  // Trường hợp type != 1 => dùng TinTucModel
                  if (widget.listTinTuc2 == null ||
                      widget.listTinTuc2!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  TinTucModel tinTucModel = widget.listTinTuc2![index];

                  String imageUrl =
                      '${ServicesUrl().baseUrlFileDownload}${tinTucModel.guidFileAnhDaiDiens?.first}$kParamThumbImage';

                  String cacheKey =
                      '${ServicesUrl().baseUrlFileDownload}${tinTucModel.guidFileAnhDaiDiens?.first}';

                  return _buildNewsItem(
                    imageUrl: imageUrl,
                    cacheKey: cacheKey,
                    title: tinTucModel.tieuDe,
                    onTap: () {
                      Get.to(
                            () => VcoreNewsDetailView(tinTucModel: tinTucModel),
                      );
                    },
                  );
                }
              },
            ),
            onNotification: (notification) {
              double newMargin = (notification.metrics.pixels /
                  _controller.position.maxScrollExtent) *
                  (2.0 / 3.0) *
                  30.0;
              newMargin = max(0, newMargin);
              newMargin = min(newMargin, 20);
              setState(() {
                marginLeft = newMargin;
              });
              return true;
            },
          ),
        ),
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
                      borderRadius: BorderRadius.circular(5)),
                ),
                Container(
                  height: 5,
                  width: 10,
                  margin: EdgeInsets.only(left: marginLeft),
                  decoration: BoxDecoration(
                      color: const Color(0xff003392),
                      borderRadius: BorderRadius.circular(5)),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildNewsItem({
    required String imageUrl,
    required String cacheKey,
    required String? title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 164,
        child: Column(
          children: [
            Container(
              height: 90,
              width: double.infinity,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                cacheKey: cacheKey,
                fit: BoxFit.cover,
                httpHeaders: Globals().headerToken(),
                errorWidget: (context, url, error) {
                  return const SizedBox.shrink(); // Ảnh rỗng nếu lỗi
                },
              ),
            ),
            spaceHeight(6),
            Text(
              title ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.regular.copyWith(
                  fontSize: 13, color: const Color(0xff2A3556)),
            ),
          ],
        ),
      ),
    );
  }
}
