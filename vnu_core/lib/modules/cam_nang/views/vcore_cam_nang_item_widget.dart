import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/cam_nang_model.dart';
import 'package:vnu_core/services/services_url.dart';

class VcoreCamNangItemWidget extends StatefulWidget {
  final CamNangModel camNangModel;

  const VcoreCamNangItemWidget({super.key, required this.camNangModel});

  @override
  State<VcoreCamNangItemWidget> createState() => _VcoreCamNangItemWidgetState();
}

class _VcoreCamNangItemWidgetState extends State<VcoreCamNangItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Cover
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            child: AspectRatio(
              aspectRatio: 343 / 246,
              child: CachedNetworkImage(
                imageUrl:
                    '${ServicesUrl().baseUrlFileDownload}${widget.camNangModel.guidFileAnhDaiDiens?.first ?? ''}$kParamThumbImage',
                cacheKey:
                    '${ServicesUrl().baseUrlFileDownload}${widget.camNangModel.guidFileAnhDaiDiens?.first ?? ''}',
                httpHeaders: Globals().headerToken(),
                progressIndicatorBuilder: (context, url, progress) {
                  return const Center(child: CircularProgressIndicator());
                },
                // imageBuilder: (context, imageProvider) {
                //   return Image
                // },
              ),
            ),
          ),
          spaceHeight(16),
          //INfo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.camNangModel.tieuDe ?? '',
                  style: TextStyles.semiBold.copyWith(fontSize: 15),
                ),
                spaceHeight(10),
                Text(
                  widget.camNangModel.tomTat ?? '',
                  style: TextStyles.regular,
                ),
                spaceHeight(10),
                Row(
                  children: [
                    Text(
                      widget.camNangModel.tenChuyenMuc ?? '',
                      style: TextStyles.regular.copyWith(
                          fontSize: 13, color: const Color(0xff003392)),
                    ),
                    const Spacer(),
                    Text(
                      DateTimeUtils.stringFromDateTime(
                          widget.camNangModel.thoiGianTao,
                          DateTimeConst.DATE_FORMAT),
                      style: TextStyles.regular.copyWith(
                          fontSize: 13, color: const Color(0xff637392)),
                    ),
                  ],
                ),
                spaceHeight(8),
                Text(
                  widget.camNangModel.donViXuatBan ?? '',
                  style: TextStyles.regular
                      .copyWith(fontSize: 13, color: const Color(0xff118A40)),
                ),
              ],
            ),
          ),
          spaceHeight(10),
        ],
      ),
    );
  }
}
