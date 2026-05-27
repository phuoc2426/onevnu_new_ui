import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:octo_image/octo_image.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/models/model.dart';

class VcoreHomeNotifyDaoTaoWidget extends StatefulWidget {
  final List<ThongBaoDaoTaoModel> listThongBao;
  final void Function(ThongBaoDaoTaoModel thongbao) onViewDetail;

  const VcoreHomeNotifyDaoTaoWidget(
      {super.key, required this.listThongBao, required this.onViewDetail});

  @override
  State<VcoreHomeNotifyDaoTaoWidget> createState() =>
      _VcoreHomeNotifyDaoTaoWidgetState();
}

class _VcoreHomeNotifyDaoTaoWidgetState
    extends State<VcoreHomeNotifyDaoTaoWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (context, index) => spaceHeight(15),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: widget.listThongBao.length,
      itemBuilder: (ctx, index) {
        ThongBaoDaoTaoModel thongbao = widget.listThongBao[index];
        return thongbao.tieuDe?.isNotEmpty == true
            ? InkWell(
                onTap: () {
                  widget.onViewDetail(thongbao);
                },
                child: itemNotify(thongbao.tieuDe!),
              )
            : const SizedBox.shrink();
      },
    );
  }

  Widget itemNotify(String content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: Html(
              data: content,
              extensions: [
                TagExtension(
                  tagsToExtend: {"img"},
                  builder: (context) => CssBoxWidget(
                    style: context.styledElement!.style,
                    child: CachedNetworkImage(
                      imageUrl:
                          '${context.attributes['src'] ?? ''}$kParamThumbImage',
                      cacheKey: context.attributes['src'] ?? '',
                      imageBuilder: (context, imageProvider) {
                        return OctoImage(image: imageProvider);
                      },
                      placeholder: (context, url) => Container(
                        height: 250,
                        width: 164,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
          svgAction('assets/images/ic_new.svg')
        ],
      ),
    );
  }
}
