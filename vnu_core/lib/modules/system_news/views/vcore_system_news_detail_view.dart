import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:octo_image/octo_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/system_news/controllers/vcore_system_news_controller.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcoreSystemNewsDetailView extends StatelessWidget {
  final TinHeThongModel tinTucModel;

  const VcoreSystemNewsDetailView({super.key, required this.tinTucModel});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: VcoreSystemNewsController(),
        tag: const Uuid().v4(),
        builder: (controller) {
          return VcoreModuleScaffold(
            title: 'Xem chi tiết tin tức',
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Content
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 23),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tinTucModel.tieuDe ?? '',
                          style: TextStyles.bold
                              .copyWith(fontSize: 20, color: Colors.black),
                        ),
                        spaceHeight(10),
                        Row(
                          children: [
                            Text(
                              tinTucModel.nguonTin ?? '',
                              style: TextStyles.regular.copyWith(
                                  fontSize: 13, color: AppColors.darkBlueAccent),
                            ),
                            const Spacer(),
                            Text(
                              DateTimeUtils.stringFromDateTime(
                                  tinTucModel.thoiGian,
                                  DateTimeConst.DATE_FORMAT),
                              style: TextStyles.regular.copyWith(
                                  fontSize: 13, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        // spaceHeight(10),
                        // Text(
                        //   controller.tintuc.value?.donViXuatBan ?? '',
                        //   style: TextStyles.regular.copyWith(
                        //       fontSize: 13, color: const Color(0xff118A40)),
                        // ),
                        spaceHeight(16),
                        //                   Text(
                        //                     '''Với chủ đề "Xây dựng chiến lược nền tảng phát triển đại học định hướng đổi mới sáng tạo", Diễn đàn nhấn mạnh vào việc phát triển các trụ cột chính là chính sách - đào tạo - nghiên cứu, chuyển giao tri thức, giúp tập trung và sâu rộng hóa các vấn đề quan trọng, từ việc xây dựng chính sách để tạo điều kiện cho đổi mới, đến việc cải thiện quy trình đào tạo và tăng cường nghiên cứu cũng như chuyển giao tri thức và công nghệ từ trường đại học ra cộng đồng, doanh nghiệp. Điều này sẽ đóng góp tích cực vào sự phát triển bền vững của đại học và sự phát triển của đất nước.
                        // Vai trò tiên phong đổi mới sáng tạo và khởi nghiệp của các trường đại học
                        // Phát biểu khai mạc diễn đàn, Phó Giám đốc ĐHQGHN Phạm Bảo Sơn cho biết: Đổi mới sáng tạo (ĐMST) đang trở thành yếu tố quyết định đối với năng lực cạnh tranh của các trường đại học trong nước và trên thế giới. Chính vì thế, việc tổ chức Diễn đàn ĐMST Quốc gia với các chủ để thảo luận thiết thực là một việc làm cần thiết không chỉ để gắn kết các nhà khoa học, các chuyên gia, các nhà hoạch định chính sách trong lĩnh vực KHCN&ĐMST''',
                        //                     style: TextStyles.regular.copyWith(color: Colors.black),
                        //                   ),
                        Html(
                          data: tinTucModel.noiDung,
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
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              ),
                            ),
                          ],
                        ),
                        spaceHeight(8),

                        (tinTucModel.guidFileDinhKems ?? []).isNotEmpty
                            ? _buildFileAttach(controller)
                            : spaceHeight(0),
                        spaceHeight(8),
                      ],
                    ),
                  ),

                  spaceHeight(20),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildFileAttach(VcoreSystemNewsController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            'Tệp đính kèm:',
            style: TextStyles.regular
                .copyWith(fontSize: 15, color: AppColors.darkBlueAccent),
          ),
        ),
        Expanded(
          flex: 6,
          child: InkWell(
            onTap: () {
              controller.downloadAndShare(tinTucModel.guidFileDinhKems?.first,
                  '${tinTucModel.tenFileDinhKems?.first}');
            },
            child: Text(
              '${tinTucModel.tenFileDinhKems?.first}',
              style: TextStyles.regular
                  .copyWith(fontSize: 15, color: AppColors.slateText),
            ),
          ),
        ),
      ],
    );
  }
}
