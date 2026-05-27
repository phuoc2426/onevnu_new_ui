import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/themes/app_theme.dart';

import '../models/nt_tin_tuc_model.dart';

class NTNoiTruItemWidget extends StatelessWidget {
  final VoidCallback? onSelected;
  final NtTinTucModel tinTucModel;

  const NTNoiTruItemWidget(
      {Key? key, required this.tinTucModel, this.onSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onSelected != null) {
          onSelected!();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(left: 0, right: 15),
                child: CachedNetworkImage(
                  imageUrl: tinTucModel.anhDaiDien ?? '',
                  cacheKey: tinTucModel.anhDaiDien ?? '',
                  errorWidget: ((context, url, error) {
                    return svgAsset('assets/images/ic_logo_vnu_green.svg');
                  }),
                )),

            // info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tinTucModel.tieuDe ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body2.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff181E39)),
                  ),
                  // const SizedBox(
                  //   height: 8,
                  // ),
                  // Text(
                  //   (tinTucModel.noiDung ?? '').noHtml(),
                  //   maxLines: 1,
                  //   overflow: TextOverflow.ellipsis,
                  //   style: AppTheme.body2
                  //       .copyWith(fontSize: 14, color: const Color(0xFF2A3556)),
                  // ),
                  const SizedBox(
                    height: 8,
                  ),
                  RichText(
                    text: TextSpan(
                      text: '',
                      style: AppTheme.body2.copyWith(
                          fontSize: 12, color: const Color(0xff003392)),
                      children: <TextSpan>[
                        TextSpan(
                          text: tinTucModel.thoiGianXuatBan ?? '',
                          style: AppTheme.body2.copyWith(
                              fontSize: 12, color: const Color(0xff637392)),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
