import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/models/phan_anh_hien_truong_model.dart';
import 'package:vnu_core/services/services_url.dart';

class VcorePahtItemWidgetV2 extends StatelessWidget {
  final PhanAnhHienTruongModel phanAnhHienTruongModel;

  const VcorePahtItemWidgetV2({
    super.key,
    required this.phanAnhHienTruongModel,
  });

  @override
  Widget build(BuildContext context) {
    final thumbId = phanAnhHienTruongModel.getThumbId();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE4EAF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: thumbId == null
                ? Image.asset(
                    'assets/images/img_no_image.png',
                    package: kPackageName,
                    width: 96,
                    height: 86,
                    fit: BoxFit.cover,
                  )
                : CachedNetworkImage(
                    width: 96,
                    height: 86,
                    fit: BoxFit.cover,
                    imageUrl: '${ServicesUrl().baseUrlFileDownload}/$thumbId?width=220&height=220&quality=100',
                    progressIndicatorBuilder: (context, url, progress) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/img_no_image.png',
                      package: kPackageName,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phanAnhHienTruongModel.tieuDePhanAnh ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xff071A44)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: Color(0xff637392)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        phanAnhHienTruongModel.diaDiemPhanAnh ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xff637392)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 15, color: Color(0xff637392)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateTimeUtils.stringFromDateTime(
                          phanAnhHienTruongModel.thoiGianGui,
                          DateTimeConst.U_MINUTE_AFTER_FORMAT,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xff637392)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
