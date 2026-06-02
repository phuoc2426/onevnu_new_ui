import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/models/phan_anh_hien_truong_model.dart';
import 'package:vnu_core/services/services_url.dart';

import 'vcore_paht_detail_view.dart';

class VcorePahtItemWidget extends StatefulWidget {
  final PhanAnhHienTruongModel phanAnhHienTruongModel;
  const VcorePahtItemWidget({
    super.key,
    required this.phanAnhHienTruongModel,
  });

  @override
  State<VcorePahtItemWidget> createState() => _VcorePahtItemWidgetState();
}

class _VcorePahtItemWidgetState extends State<VcorePahtItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          //
          SizedBox(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: widget.phanAnhHienTruongModel.getThumbId() == null
                      ? SizedBox(
                          width: 110,
                          height: 80,
                          child: Image.asset(
                            'assets/images/img_no_image.png',
                            package: kPackageName,
                          ),
                        )
                      : CachedNetworkImage(
                          width: 110,
                          height: 80,
                          fit: BoxFit.cover,
                          progressIndicatorBuilder: (context, url, progress) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          imageUrl:
                              '${ServicesUrl().baseUrlFileDownload}/${widget.phanAnhHienTruongModel.getThumbId()}?width=220&height=220&quality=100',
                          errorWidget: (context, url, error) {
                            return Image.asset(
                              'assets/images/img_no_image.png',
                              package: kPackageName,
                            );
                          },
                        ),
                ),
                spaceWidth(8),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.phanAnhHienTruongModel.tieuDePhanAnh ?? '',
                      style: TextStyles.semiBold.copyWith(fontSize: AppFontSizes.mediumLarge),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    spaceHeight(10),
                    Text(
                      widget.phanAnhHienTruongModel.diaDiemPhanAnh ?? '',
                      style: TextStyles.regular.copyWith(fontSize: AppFontSizes.mediumSmall),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    spaceHeight(2),
                    Text(
                      DateTimeUtils.stringFromDateTime(
                          widget.phanAnhHienTruongModel.thoiGianGui,
                          DateTimeConst.U_MINUTE_AFTER_FORMAT),
                      style: TextStyles.regular.copyWith(fontSize: AppFontSizes.mediumSmall),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
