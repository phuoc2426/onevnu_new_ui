import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/profile/controllers/vcore_profile_photos_controller.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_photos_detail_view.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';

import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcoreProfilePhotosView extends GetView<VcoreProfilePhotosController> {
  const VcoreProfilePhotosView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreProfilePhotosController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            controller.refreshData();
          },
          child: Obx(
            () => VcoreModuleScaffold(
              title: 'Quản lý ảnh cá nhân',
              body: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SmartRefresher(
                  controller: controller.refreshController,
                  enablePullUp: true,
                  onRefresh: controller.refreshData,
                  //onLoading: controller.loadMoreData,
                  header: const WaterDropHeader(),
                  footer: const RefreshFooterWidget(),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.listAnhCaNhan.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6),
                    itemBuilder: (ctx, index) {
                      AnhCaNhanModel anhCaNhanModel =
                          controller.listAnhCaNhan[index];
                      return GestureDetector(
                        onTap: () {
                          Get.to(
                            () => VcoreProfilePhotosDetailView(
                              guid: anhCaNhanModel.guid ?? '',
                              onDelete: () {
                                controller.deleteAnhCaNhan(anhCaNhanModel);
                              },
                            ),
                            fullscreenDialog: true,
                          );
                        },
                        child: CachedNetworkImage(
                          imageUrl:
                              '${ServicesUrl().baseUrlFileDownload}${anhCaNhanModel.guid}$kParamThumbImage',
                          cacheKey:
                              '${ServicesUrl().baseUrlFileDownload}${anhCaNhanModel.guid}',
                          httpHeaders: Globals().headerToken(),
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              ),
              floatingActionButton: svgAction(
                'assets/images/ic_profile_camera.svg',
                action: () {
                  controller.pickPhoto();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class VcoreProfilePhotsSectionWidget extends StatefulWidget {
  const VcoreProfilePhotsSectionWidget({super.key});

  @override
  State<VcoreProfilePhotsSectionWidget> createState() =>
      _VcoreProfilePhotsSectionWidgetState();
}

class _VcoreProfilePhotsSectionWidgetState
    extends State<VcoreProfilePhotsSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '09/05/2024',
          style: TextStyles.semiBold.copyWith(fontSize: AppFontSizes.large),
        ),
        spaceHeight(8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6),
          itemBuilder: (ctx, index) {
            return GestureDetector(
              onTap: () {
                // Get.to(() => const VcoreProfilePhotosDetailView(),
                //     fullscreenDialog: true);
              },
              child: CachedNetworkImage(
                imageUrl:
                    'https://img.freepik.com/free-psd/3d-illustration-person-with-sunglasses_23-2149436188.jpg',
                cacheKey:
                    'https://img.freepik.com/free-psd/3d-illustration-person-with-sunglasses_23-2149436188.jpg',
              ),
            );
          },
        )
      ],
    );
  }
}
