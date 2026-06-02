import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/tin_tuc_model.dart';
import 'package:vnu_core/services/services_url.dart';

class VcoreNewsItemWidget extends StatefulWidget {
  final TinTucModel tinTucModel;
  const VcoreNewsItemWidget({super.key, required this.tinTucModel});

  @override
  State<VcoreNewsItemWidget> createState() => _VcoreNewsItemWidgetState();
}

class _VcoreNewsItemWidgetState extends State<VcoreNewsItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, top: 8, right: 20, bottom: 15),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              //
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  imageUrl:
                      '${ServicesUrl().baseUrlFileDownload}${widget.tinTucModel.guidFileAnhDaiDiens?.first}$kParamThumbImage',
                  cacheKey:
                      '${ServicesUrl().baseUrlFileDownload}${widget.tinTucModel.guidFileAnhDaiDiens?.first}',
                  httpHeaders: Globals().headerToken(),
                ),
              ),
              spaceWidth(8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //
                    Text(
                      widget.tinTucModel.tieuDe ?? '',
                      style: TextStyles.regular,
                    ),
                    spaceHeight(8),
                    Row(
                      children: [
                        Text(
                          widget.tinTucModel.tenChuyenMuc ?? '',
                          style: TextStyles.regular.copyWith(
                              fontSize: AppFontSizes.mediumSmall, color: const Color(0xff003392)),
                        ),
                        const Spacer(),
                        Text(
                          DateTimeUtils.stringFromDateTime(
                              widget.tinTucModel.thoiGianTao,
                              DateTimeConst.DATE_FORMAT),
                          style: TextStyles.regular.copyWith(
                              fontSize: AppFontSizes.mediumSmall, color: const Color(0xff8E8E8E)),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
          spaceHeight(8),
          Text(
            widget.tinTucModel.donViXuatBan ?? '',
            style: TextStyles.regular
                .copyWith(fontSize: AppFontSizes.mediumSmall, color: const Color(0xff118A40)),
          )
        ],
      ),
    );
  }
}
