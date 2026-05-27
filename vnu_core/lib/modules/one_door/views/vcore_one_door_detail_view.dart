import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:octo_image/octo_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/models/thu_tuc_mot_cua_model.dart';
import 'package:vnu_core/modules/one_door/controllers/vcore_one_door_detail_controller.dart';
import 'package:vnu_core/widgets/navi_widget.dart';

class VcoreOneDoorDetailView extends GetView<VcoreOneDoorDetailController> {
  final ThuTucMotCuaModel thuTucMotCuaModel;

  const VcoreOneDoorDetailView({super.key, required this.thuTucMotCuaModel});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreOneDoorDetailController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return Scaffold(
          appBar: NaviWidget(
            titleStr: 'Nội dung chi tiết thủ tục',
          ),
          backgroundColor: AppColor.bgColor,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(18),
                    child: Center(
                      child: Text(
                        thuTucMotCuaModel.tenThuTuc?.toUpperCase() ?? '',
                        style: TextStyles.semiBold
                            .copyWith(color: AppColor.textBlueColor),
                      ),
                    ),
                  ),
                  spaceHeight(16),

                  // Content
                  Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nội dung chi tiết',
                            style: TextStyles.semiBold
                                .copyWith(color: Colors.black),
                          ),
                          spaceHeight(20),
                          Html(
                            data: thuTucMotCuaModel.htmlNoiDung,
                            onLinkTap: (url, attributes, element) {
                              logSuccess('Tap url --> $url');
                              if (url != null) {
                                launchUrl(Uri.parse(url));
                              }
                            },
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
//                           Text(
//                             '''1. Mẫu đơn đề nghị đổi giấp phép lái xe
// Mẫu đơn đề nghị đổi giấy phép lái xe là mẫu tại phụ lục 19 ban hành kèm theo Thông tư 12/2017/TT-BGTVT.

// 2. Mẫu đơn đề nghị cấp lại giấy phép lái xe
// Mẫu đơn đề nghị cấp lại giấy phép lái xe là mẫu tại phụ lục 19 ban hành kèm theo Thông tư 12/2017/TT-BGTVT.

// 3. Một số quy định về đổi, cấp lại giấy phép lái xe
// * Các trường hợp cấp lại giấy phép lái xe:
// ''',
//                             style: TextStyles.regular
//                                 .copyWith(color: Colors.black),
//                           )
                        ],
                      )),
                  spaceHeight(10),

                  //File attachs
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thành phần hồ sơ',
                          style:
                              TextStyles.semiBold.copyWith(color: Colors.black),
                        ),
                        spaceHeight(20),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (context, index) => spaceHeight(10),
                          itemCount:
                              thuTucMotCuaModel.thanhPhanHoSo?.length ?? 0,
                          itemBuilder: (context, index) {
                            ThanhPhanHoSo hoSo =
                                thuTucMotCuaModel.thanhPhanHoSo![index];
                            return InkWell(
                              onTap: () {
                                //Download file and open share
                                //
                                logWarning('Download and share file..');
                                controller.downloadHoSoAndShare(hoSo);
                              },
                              child: Row(
                                children: [
                                  Text(
                                    (hoSo.tenHoSo ?? '').isNotEmpty
                                        ? (hoSo.tenHoSo ?? '')
                                        : (hoSo.tenFileDinhKem ?? ''),
                                    style: TextStyles.regular.copyWith(
                                        color: AppColor.textBlueColor),
                                  ),
                                  spaceWidth(3),
                                  svgAsset('assets/images/ic_download.svg')
                                ],
                              ),
                            );
                          },
                        ),
                        spaceHeight(10)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
