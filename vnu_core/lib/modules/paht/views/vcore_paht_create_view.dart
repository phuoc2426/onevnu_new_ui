import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/modules/exam_schedule/views/vcore_dropdown_select_widget.dart';
import 'package:vnu_core/modules/paht/controllers/vcore_paht_create_controller.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_textfield_widget.dart';
import 'package:vnu_core/screens/vcore_select_location_view.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/container_dissmis.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

import 'vcore_path_create_file_view.dart';

class VcorePahtCreateView extends GetView<VcorePahtCreateController> {
  const VcorePahtCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcorePahtCreateController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return Scaffold(
            appBar: NaviWidget(
              titleStr: 'Gửi phản ánh',
            ),
            backgroundColor: AppColor.bgColor,
            body: ProgressHubWidget(
              contextComplete: (hubContext) {
                controller.context = hubContext;
              },
              child: ContainerAutoDissmis(
                child: Obx(
                  () => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 23),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          //
                          _titleRequire('Chủ đề', true),
                          VcoreDropdown2SelectWidget(
                            items: controller.listChuDe
                                .map((e) => VcoreDropdownModel(
                                    text: e.tenChuDe ?? '', guid: e.guid ?? ''))
                                .toList(),
                            hint: 'Chọn chủ đề',
                            selectedGuid: controller.currentChuDe.value?.guid,
                            onSelected: (value) {
                              controller.changeChuDeDropdown(value);
                            },
                          ),
                          //
                          spaceHeight(11),
                          _titleRequire('Khu vực', true),
                          VcoreDropdown2SelectWidget(
                            items: controller.listKhuVuc
                                .map((e) => VcoreDropdownModel(
                                    text: e.tenKhuVucBanDo ?? '',
                                    guid: e.guid ?? ''))
                                .toList(),
                            hint: 'Chọn khu vực',
                            selectedGuid: controller.currentKhuVuc.value?.guid,
                            onSelected: (value) {
                              controller.changeKhuVucDropdown(value);
                            },
                          ),

                          //
                          spaceHeight(11),
                          VcoreProfileTextFieldWidget(
                            title: 'Địa điểm phản ánh',
                            hintText: 'Nhập cụ thể địa điểm',
                            isRequired: true,
                            maxLine: 2,
                            value: controller.diaDiemPhanAnh,
                            onChange: (text) {
                              controller.diaDiemPhanAnh = text.trim();
                            },
                            onSubmitted: (value) {},
                          ),

                          if (controller.locationPoint.value != null) ...[
                            spaceHeight(8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Vị trí được chọn:\n    Kinh độ: ${controller.locationPoint.value?.longitude} \n    Vĩ độ: ${controller.locationPoint.value?.latitude}',
                                style: TextStyles.regular.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],

                          spaceHeight(14),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              Utils.hideKeyboard();
                              var result =
                                  await Get.to(() => VcoreSelectLocationView(
                                        selectedLocation:
                                            controller.locationPoint.value,
                                      ));
                              if (result != null && result is LatLng) {
                                controller.locationPoint.value = result;
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.pin_drop_rounded,
                                  color: AppTheme.backgroundBlueColor,
                                ),
                                Text(
                                  'Chọn địa điểm từ bản đồ',
                                  style: TextStyles.semiBold.copyWith(
                                      fontSize: 13,
                                      color: AppTheme.backgroundBlueColor),
                                )
                              ],
                            ),
                          ),

                          //
                          spaceHeight(16),
                          VcoreProfileTextFieldWidget(
                            title: 'Tiêu đề phản ánh',
                            hintText: 'Nhập tiêu đề phản ánh',
                            isRequired: true,
                            maxLine: 2,
                            value: controller.tieuDePhanAnh,
                            onChange: (text) {
                              controller.tieuDePhanAnh = text.trim();
                            },
                            onSubmitted: (value) {},
                          ),

                          //
                          spaceHeight(16),
                          VcoreProfileTextFieldWidget(
                            title: 'Nội dung phản ánh',
                            hintText: 'Nhập nội dung phản ánh',
                            isRequired: true,
                            maxLine: 6,
                            value: controller.noidungPhanAnh,
                            onChange: (text) {
                              controller.noidungPhanAnh = text.trim();
                            },
                            onSubmitted: (value) {},
                          ),

                          //Pick anhr video
                          spaceHeight(16),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {},
                            child: Row(
                              children: [
                                Text(
                                  'Ảnh/Video          ',
                                  style: TextStyles.regular.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                                svgAction('assets/images/ic_attach_file.svg',
                                    action: () {
                                  Utils.hideKeyboard();
                                  controller.excPickerPhotoVideo();
                                }),
                                spaceWidth(6),
                                IconButton(
                                  onPressed: () {
                                    controller.excCamera();
                                  },
                                  icon: const Icon(Icons.camera_alt_rounded),
                                ),
                                spaceWidth(6),
                                IconButton(
                                  onPressed: () {
                                    controller.excCameraVideo();
                                  },
                                  icon: const Icon(
                                    Icons.videocam_rounded,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          //List videos, photos
                          if (controller.listFiles.isNotEmpty)
                            _buildAttachFiles(controller),

                          //
                          spaceHeight(16),
                          Text(
                            'Lưu ý: Thông tin người gửi phản ánh hoàn toàn được giữ bảo mật đối với đơn vị bị phản ánh để đảm bảo các ảnh hưởng liên quan khác.',
                            style: TextStyles.italic,
                          ),

                          spaceHeight(40),
                          BlueButton(
                            title: 'Gửi phản ánh',
                            action: () {
                              controller.submitPhanAnh();
                            },
                          ),
                          spaceHeight(30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ));
      },
    );
  }

  Widget _titleRequire(String title, bool isRequired) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyles.regular
                  .copyWith(fontSize: 13, color: Colors.black),
            ),
            Text(
              isRequired ? ' *' : '',
              style:
                  TextStyles.regular.copyWith(fontSize: 13, color: Colors.red),
            )
          ],
        ),
        spaceHeight(8),
      ],
    );
  }

  Widget _buildAttachFiles(VcorePahtCreateController controller) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: controller.listFiles.length,
      itemBuilder: (ctx, index) {
        final file = controller.listFiles[index];
        return VcorePathCreateFileView(
          fileUploadModel: file,
          onDelete: () {
            controller.listFiles.removeAt(index);
          },
        );
      },
    );
  }
}
