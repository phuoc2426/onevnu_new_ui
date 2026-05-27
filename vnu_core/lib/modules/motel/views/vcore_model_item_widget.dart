import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/models/phong_tro_model.dart';
import 'package:vnu_core/services/services_url.dart';

class VcoreMotelItemWidget extends StatefulWidget {
  final PhongTroModel phongTroModel;

  const VcoreMotelItemWidget({super.key, required this.phongTroModel});

  @override
  State<VcoreMotelItemWidget> createState() => _VcoreMotelItemWidgetState();
}

class _VcoreMotelItemWidgetState extends State<VcoreMotelItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          //
          SizedBox(
            // height: 70,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: (widget.phongTroModel.guidFileAnhNhaTros ?? []).isEmpty
                      ? SizedBox(
                          width: 70,
                          height: 70,
                          child: Image.asset(
                            'assets/images/img_no_image.png',
                            package: kPackageName,
                          ),
                        )
                      : CachedNetworkImage(
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          progressIndicatorBuilder: (context, url, progress) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          imageUrl:
                              '${ServicesUrl().baseUrlFileDownload}/${widget.phongTroModel.guidFileAnhNhaTros?.firstOrNull}?$kParamThumbImage',
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
                    Text(widget.phongTroModel.tenChuTro ?? ''),
                    Row(
                      children: [
                        svgAsset('assets/images/ic_motel_price.svg'),
                        spaceWidth(5),
                        Text(
                          'Giá phòng : ${widget.phongTroModel.giaThueFromString()} - ${widget.phongTroModel.giaThueToString()}',
                          style: TextStyles.regular.copyWith(
                              fontSize: 13, color: const Color(0xffFB8500)),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        svgAsset('assets/images/ic_motel_acreage.svg'),
                        spaceWidth(5),
                        Text(
                          'Diện tích: ${widget.phongTroModel.dienTichFrom ?? ''} - ${widget.phongTroModel.dienTichTo ?? ''} m2',
                          style: TextStyles.regular
                              .copyWith(fontSize: 13, color: Color(0xffFB8500)),
                        )
                      ],
                    )
                  ],
                ))
              ],
            ),
          ),
          spaceHeight(15),
          // Adress
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              svgAsset('assets/images/ic_motel_address.svg'),
              spaceWidth(5),
              Expanded(
                child: Text(
                  widget.phongTroModel.diaChi ?? '',
                  style: TextStyles.regular
                      .copyWith(fontSize: 13, color: const Color(0xff2A3556)),
                ),
              )
            ],
          ),
          spaceHeight(8),
          //Time
          Row(
            children: [
              svgAsset('assets/images/ic_motel_time.svg'),
              spaceWidth(5),
              Expanded(
                child: Text(
                  'Ngày đăng:  ${widget.phongTroModel.ngayDangString()}',
                  style: TextStyles.regular
                      .copyWith(fontSize: 13, color: const Color(0xff2A3556)),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
