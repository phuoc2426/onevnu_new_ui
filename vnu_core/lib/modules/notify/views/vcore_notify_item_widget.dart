import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/models/thong_bao_model.dart';
import 'package:vnu_core/services/services_url.dart';

import '../../../common/space_widget.dart';

class VcoreNotifyItemWidget extends StatefulWidget {
  final ThongBaoModel thongBaoModel;

  const VcoreNotifyItemWidget({super.key, required this.thongBaoModel});

  @override
  State<VcoreNotifyItemWidget> createState() => _VcoreNotifyItemWidgetState();
}

class _VcoreNotifyItemWidgetState extends State<VcoreNotifyItemWidget> {
  @override
  Widget build(BuildContext context) {
    bool isReaded = widget.thongBaoModel.isRead ?? true;
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CachedNetworkImage(
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              imageUrl:
                  '${ServicesUrl().baseUrlFileDownload}${widget.thongBaoModel.guidAnhHienThi}$kParamThumbImage',
              cacheKey:
                  '${ServicesUrl().baseUrlFileDownload}${widget.thongBaoModel.guidAnhHienThi}',
              errorWidget: (context, url, error) =>
                  svgAsset('assets/images/ic_logo_vnu_green.svg'),
            ),
          ),
          spaceWidth(8),
          //
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.thongBaoModel.tieuDe ?? '',
                  style: isReaded
                      ? TextStyles.regular
                          .copyWith(fontSize: AppFontSizes.mediumLarge, color: Colors.black)
                      : TextStyles.semiBold
                          .copyWith(fontSize: AppFontSizes.mediumLarge, color: Colors.black),
                ),
                spaceHeight(10),
                Text(
                  widget.thongBaoModel.noiDung ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: isReaded
                      ? TextStyles.regular.copyWith(
                          fontSize: AppFontSizes.medium, color: AppTheme.textColor)
                      : TextStyles.semiBold.copyWith(
                          fontSize: AppFontSizes.medium, color: AppTheme.textColor),
                ),
                spaceHeight(10),
                Row(
                  children: [
                    Text(
                      widget.thongBaoModel.tenNguoiGui ?? '',
                      style: isReaded
                          ? TextStyles.regular.copyWith(
                              fontSize: AppFontSizes.small, color: AppColors.darkBlueAccent)
                          : TextStyles.semiBold.copyWith(
                              fontSize: AppFontSizes.small, color: AppColors.darkBlueAccent),
                    ),
                    const Spacer(),
                    Text(
                      DateTimeUtils.stringFromDateTime(
                          widget.thongBaoModel.ngayGui?.toLocal(),
                          DateTimeConst.U_SECOND_FORMAT),
                      style: isReaded
                          ? TextStyles.regular.copyWith(
                              fontSize: AppFontSizes.small, color: AppColors.slateText)
                          : TextStyles.semiBold.copyWith(
                              fontSize: AppFontSizes.small, color: AppColors.slateText),
                    )
                  ],
                )
              ],
            ),
          )
          //
        ],
      ),
    );
  }
}
