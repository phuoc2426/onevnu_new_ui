import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/news/controllers/vcore_jobs_controller_v2.dart';
import 'package:vnu_core/modules/news/views/vcore_news_detail_view.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/widgets/container_dissmis.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/refresher_footer_widget.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcoreJobsViewV2 extends GetView<VcoreJobsControllerV2> {
  const VcoreJobsViewV2({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcoreJobsControllerV2>(
      init: VcoreJobsControllerV2(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            if (controller.listJobs.isEmpty) {
              controller.refreshData();
            }
          },
          child: VcoreModuleScaffold(
            title: 'Cơ hội việc làm',
            showBackButton: true,
            body: ContainerAutoDissmis(
              child: Column(
                children: [
                  // Premium Search Bar
                  Container(
                    height: 64,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            Icon(Icons.search_rounded,
                                color: Colors.grey.shade500, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: controller.textEditingController,
                                style: TextStyles.regular.copyWith(
                                  fontSize: AppFontSizes.medium,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText:
                                      'Tìm kiếm tin tuyển dụng, việc làm...',
                                  hintStyle: TextStyles.regular.copyWith(
                                    color: Colors.grey.shade400,
                                    fontSize: AppFontSizes.mediumSmall,
                                  ),
                                ),
                                onSubmitted: (value) {
                                  controller.refreshData();
                                },
                              ),
                            ),
                            if (controller
                                .textEditingController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  controller.textEditingController.clear();
                                  controller.refreshData();
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Job List View
                  Expanded(
                    child: Obx(() {
                      if (controller.listJobs.isEmpty) {
                        return _buildEmptyState();
                      }

                      return SmartRefresher(
                        controller: controller.refreshController,
                        enablePullDown: true,
                        enablePullUp: true,
                        onRefresh: controller.refreshData,
                        onLoading: controller.loadMoreData,
                        header: const WaterDropHeader(),
                        footer: const RefreshFooterWidget(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: controller.listJobs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = controller.listJobs[index];
                            return _buildJobCard(context, item);
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobCard(BuildContext context, TinTucModel item) {
    // Check if the post has an image thumbnail
    final bool hasImage = item.guidFileAnhDaiDiens?.isNotEmpty == true;
    final String imageUrl = hasImage
        ? '${ServicesUrl().baseUrlFileDownload}${item.guidFileAnhDaiDiens!.first}'
        : '';

    return InkWell(
      onTap: () {
        Utils.hideKeyboard();
        Get.to(
          () => VcoreNewsDetailView(
            tinTucModel: item,
            screenTitle: 'Chi tiết việc làm',
            relatedTitle: 'VIỆC LÀM LIÊN QUAN',
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left icon or image
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  imageUrl: '$imageUrl$kParamThumbImage',
                  cacheKey: imageUrl,
                  httpHeaders: Globals().headerToken(),
                  errorWidget: (context, error, stackTrace) =>
                      _buildFallbackJobIcon(),
                ),
              )
            else
              _buildFallbackJobIcon(),

            const SizedBox(width: 12),

            // Middle contents
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.tieuDe ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSizes.medium,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.3,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.donViXuatBan ?? 'Nhà tuyển dụng',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppFontSizes.small,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 10, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        item.thoiGianTao != null
                            ? DateTimeUtils.stringFromDateTime(
                                item.thoiGianTao, DateTimeConst.DATE_FORMAT)
                            : '',
                        style: TextStyle(
                          fontSize: AppFontSizes.extraSmall,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Align(
              alignment: Alignment.center,
              child: Icon(Icons.chevron_right_rounded,
                  color: Colors.grey, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackJobIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.work_rounded,
          color: Color(0xFF2E7D32),
          size: 26,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_off_outlined,
            size: 54,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có tin tuyển dụng nào được đăng tải',
            style: TextStyles.regular.copyWith(
              color: Colors.grey.shade400,
              fontSize: AppFontSizes.medium,
            ),
          ),
        ],
      ),
    );
  }
}
