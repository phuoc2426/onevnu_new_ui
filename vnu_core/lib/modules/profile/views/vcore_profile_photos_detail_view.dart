import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_photos_controller.dart';
import 'package:vnu_core/services/services_url.dart';

class VcoreProfilePhotosDetailView
    extends GetView<VcoreProfilePhotosController> {
  final String guid;
  final VoidCallback? onDelete;
  const VcoreProfilePhotosDetailView(
      {super.key, required this.guid, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreProfilePhotosController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return Scaffold(
          // appBar: AppBar(),
          backgroundColor: Colors.black,
          body: Stack(
            alignment: AlignmentDirectional.bottomCenter,
            children: [
              //
              PhotoView(
                imageProvider: CachedNetworkImageProvider(
                  '${ServicesUrl().baseUrlFileDownload}$guid',
                  headers: Globals().headerToken(),
                ),
              ),
              //
              SafeArea(
                child: Column(
                  children: [
                    IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        icon: Row(
                          children: [
                            svgAsset('assets/images/ic_navi_back.svg',
                                color: Colors.white),
                            spaceWidth(6),
                            Text(
                              '', //ngay thang nam
                              style: TextStyles.semiBold
                                  .copyWith(color: Colors.white, fontSize: AppFontSizes.font17),
                            )
                          ],
                        )),
                    const Spacer(),
                    IconButton(
                        onPressed: () {
                          Utils.showAlertDialog(
                            context,
                            'Xác nhận',
                            'Bạn có chắc chắn muốn xoá ảnh?',
                            okStr: 'Đồng ý',
                            cancelStr: 'Huỷ',
                            callBackOK: () {
                              Get.back();
                              if (onDelete != null) {
                                onDelete!();
                              }
                            },
                          );
                        },
                        icon: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            svgAsset('assets/images/ic_profile_delete.svg'),
                            spaceHeight(6),
                            Text(
                              'Xóa',
                              style: TextStyles.regular
                                  .copyWith(color: Colors.white),
                            )
                          ],
                        ))
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
