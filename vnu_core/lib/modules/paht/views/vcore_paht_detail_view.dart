import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/screens/vcore_video_preview_screen.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/photo_gallery_view.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

import '../controllers/vcore_paht_detail_controller.dart';

class VcorePahtDetailView extends GetView<VcorePahtDetailController> {
  final PhanAnhHienTruongModel phanAnhHienTruongModel;
  final bool isChuaXuLy;
  const VcorePahtDetailView(
      {super.key,
      required this.phanAnhHienTruongModel,
      required this.isChuaXuLy});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcorePahtDetailController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        controller.configWithModel(phanAnhHienTruongModel);
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: Scaffold(
            appBar: NaviWidget(
              titleStr: 'Thông tin chi tiết',
            ),
            backgroundColor: Colors.white,
            body: Obx(
              () => SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                Row(
                                  // crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    svgAsset(
                                        'assets/images/ic_question_person.svg'),
                                    spaceWidth(20),
                                    Flexible(
                                      child: Text(
                                        controller.model.value?.tieuDePhanAnh ??
                                            '',
                                        style: TextStyles.semiBold.copyWith(
                                            fontSize: 15,
                                            color:
                                                AppTheme.backgroundBlueColor),
                                      ),
                                    )
                                  ],
                                ),
                                spaceHeight(8),
                                _builtItemInfo('Chủ đề:',
                                    controller.model.value?.tenChuDe ?? ''),
                                spaceHeight(8),
                                _builtItemInfo(
                                  'Ngày gửi:',
                                  DateTimeUtils.stringFromDateTime(
                                      controller.model.value?.thoiGianGui,
                                      DateTimeConst.U_MINUTE_AFTER_FORMAT),
                                ),
                                //'15/01/2024 18:00'),
                                spaceHeight(8),
                                GestureDetector(
                                  onTap: () {
                                    if (controller.model.value
                                            ?.containtMapLocation() ==
                                        true) {
                                      String map =
                                          'https://maps.google.com/?q=${controller.model.value?.mapDiaDiemPhanAnh}&z=8';
                                      Utils.openUrl(map);
                                    }
                                  },
                                  child: _builtItemInfo(
                                      'Địa điểm:',
                                      controller.model.value?.diaDiemPhanAnh ??
                                          '',
                                      textColor: controller.model.value
                                                  ?.containtMapLocation() ==
                                              true
                                          ? AppTheme.backgroundBlueColor
                                          : null),
                                ),

                                spaceHeight(20),

                                // Detail
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    controller.model.value?.noiDungPhanAnh ??
                                        '',
                                    style: TextStyles.regular
                                        .copyWith(fontSize: 15),
                                  ),
                                ),

                                //Files attach
                                if ((controller
                                            .model.value?.fileDinhKemsPhanAnh ??
                                        [])
                                    .isNotEmpty) ...[
                                  spaceHeight(20),
                                  _buildAttacFiles(
                                      controller,
                                      controller.model.value
                                              ?.fileDinhKemsPhanAnh ??
                                          [])
                                ],

                                //Result
                                if (controller.xylyModel.value != null) ...[
                                  _builtResultProcess(controller),
                                  spaceHeight(20),
                                  _builtItemInfo(
                                    'Ngày trả lời:',
                                    DateTimeUtils.stringFromDateTime(
                                        controller
                                            .xylyModel.value?.thoiGianTraLoi,
                                        DateTimeConst.U_MINUTE_AFTER_FORMAT),
                                  ),
                                  //Files attach
                                  if ((controller.xylyModel.value
                                              ?.fileDinhKemsXuLy ??
                                          [])
                                      .isNotEmpty) ...[
                                    spaceHeight(20),
                                    _buildAttacFiles(
                                        controller,
                                        controller.xylyModel.value
                                                ?.fileDinhKemsXuLy ??
                                            [])
                                  ]
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Xoá
                    if (controller.enableDelete.value == true &&
                        isChuaXuLy == true)
                      Positioned(
                          bottom: 0,
                          left: 30,
                          right: 30,
                          child: BlueButton(
                            title: 'Xoá',
                            height: 48,
                            bgColor: Colors.red,
                            action: () {
                              Utils.showAlertDialog(
                                context,
                                'Xác nhận',
                                'Bạn có chắc chắn muốn xoá phản ánh "${phanAnhHienTruongModel.tieuDePhanAnh}"?',
                                okStr: 'Đồng ý',
                                cancelStr: 'Huỷ',
                                callBackOK: () {
                                  controller.deletePaht();
                                },
                              );
                            },
                          )),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _builtItemInfo(String title, String info, {Color? textColor}) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            title,
            style: TextStyles.regular
                .copyWith(fontSize: 15, color: AppTheme.backgroundBlueColor),
          ),
        ),
        Flexible(
          child: Text(
            info,
            style: TextStyles.regular.copyWith(
                fontSize: 15, color: textColor ?? const Color(0xff637392)),
          ),
        )
      ],
    );
  }

  Widget _buildAttacFiles(VcorePahtDetailController controller,
      List<FileDinhKemModel> filesDinhKem) {
    List<FileDinhKemModel> listDocument = [];
    List<FileDinhKemModel> listMedia = [];

    //List photo and list file
    for (var element in filesDinhKem) {
      String name = element.name ?? '';
      if (name.isVideo() || name.isImage()) {
        listMedia.add(element);
      } else {
        listDocument.add(element);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        spaceHeight(10),
        if (listDocument.isNotEmpty) ...[
          Text(
            'Tệp đính kèm: ',
            style: TextStyles.regular
                .copyWith(fontSize: 15, color: AppTheme.backgroundBlueColor),
          ),
          spaceHeight(10),
          ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: listDocument.length,
              itemBuilder: (ctx, index) {
                FileDinhKemModel file = listDocument[index];
                return InkWell(
                  onTap: () {
                    controller.downloadAndOpen(file);
                    // old logic download and share
                    //controller.downloadAndShare(file.guid, file.name ?? '');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      file.name ?? '',
                      style: TextStyles.italic.copyWith(
                          fontSize: 15, color: AppTheme.backgroundBlueColor),
                    ),
                  ),
                );
              }),
          spaceHeight(10),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: listMedia.length,
          itemBuilder: (ctx, index) {
            FileDinhKemModel model = listMedia[index];
            String idFile = model.guid ?? '';
            String fileName = model.name ?? '';
            bool isVideo = fileName.isVideoFileName;
            bool isPhoto = fileName.isImageFileName;
            String fileUrl = '${ServicesUrl().baseUrlFileDownload}$idFile';
            logSuccess(fileUrl);
            return GestureDetector(
              onTap: () {
                if (!isPhoto) {
                  controller.downloadAndOpen(model);
                  // controller.downloadAndShare(idFile, fileName);
                } else {
                  Get.to(
                      () => PhotoGalleryView(
                            photos: [
                              fileUrl,
                            ],
                            startPage: 0,
                          ),
                      fullscreenDialog: true);
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // -- Thum
                  !isPhoto
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const SizedBox())
                      : CachedNetworkImage(
                          // width: 110,
                          // height: 80,
                          httpHeaders: Globals().headerToken(),
                          fit: BoxFit.cover,
                          progressIndicatorBuilder: (context, url, progress) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          imageUrl: '$fileUrl?width=220&height=220&quality=100',
                        ),

                  // -- video
                  if (isVideo)
                    const Icon(
                      Icons.play_circle_outline_rounded,
                      color: AppTheme.backgroundBlueColor,
                      size: 40,
                    )
                ],
              ),
            );
          },
        )
      ],
    );
  }

  Widget _builtResultProcess(VcorePahtDetailController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        spaceHeight(30),
        // Icon
        Row(
          children: [
            svgAsset('assets/images/ic_question_send.svg'),
            spaceWidth(20),
            Text(
              'Kết quả xử lý',
              style: TextStyles.semiBold
                  .copyWith(fontSize: 15, color: AppTheme.backgroundBlueColor),
            )
          ],
        ),
        spaceHeight(16),
        // detail
        Text(
          controller.xylyModel.value?.noiDungXuLy ?? '',
          style: TextStyles.regular.copyWith(fontSize: 15),
        )
      ],
    );
  }
}
