import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/question/controllers/vcore_question_detail_controller.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

class VcoreQuestionDetailView extends GetView<VcoreQuestionDetailController> {
  final HoiDapModel question;
  const VcoreQuestionDetailView({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreQuestionDetailController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        if (controller.cauTraLoi.value == null) {
          controller.getCauTraLoi(question.guid ?? '');
        }
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: Scaffold(
            appBar: NaviWidget(
              titleStr: 'Thông tin chi tiết',
            ),
            backgroundColor: AppColor.bgColor,
            body: Obx(
              () => SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              svgAsset('assets/images/ic_question_person.svg'),
                              spaceWidth(15),
                              Expanded(
                                child: Text(
                                  question.cauHoi ?? '',
                                  style: TextStyles.semiBold.copyWith(
                                      fontSize: 15,
                                      color: const Color(0xff181E39)),
                                ),
                              )
                            ],
                          ),
                          spaceHeight(16),
                          itemInfo('Chủ đề:', question.tenChuDe ?? ''),
                          spaceHeight(16),
                          itemInfo(
                              'Ngày gửi:',
                              DateTimeUtils.stringFromDateTime(
                                  question.thoiGianGui,
                                  DateTimeConst.U_SECOND_FORMAT)),
                          spaceHeight(16),
                          Visibility(
                            visible:
                                ((question.guidFileDinhKems ?? []).isNotEmpty),
                            child: InkWell(
                              onTap: () {
                                controller.downloadAndShare(
                                    question.guidFileDinhKems?.first,
                                    question.tenFileDinhKem ?? '');
                              },
                              child: itemInfo('File đính kèm:',
                                  question.tenFileDinhKem ?? ''),
                            ),
                          ),
                        ],
                      ),
                    ),
                    spaceHeight(10),
                    Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: controller.isLoadingAnswer.value
                            ? Center(
                                child: Column(
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Text(
                                      'Lấy dữ liệu câu trả lời',
                                      style: TextStyles.regular,
                                    )
                                  ],
                                ),
                              )
                            : buildCauTraLoi(
                                controller.cauTraLoi.value, controller)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget itemInfo(String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            style: TextStyles.regular
                .copyWith(fontSize: 15, color: const Color(0xff003392)),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            content,
            style: TextStyles.regular
                .copyWith(fontSize: 15, color: const Color(0xff637392)),
          ),
        ),
      ],
    );
  }

  Widget buildCauTraLoi(
      CauTraLoiModel? cauTraLoi, VcoreQuestionDetailController controller) {
    if (cauTraLoi == null) {
      return Center(
        child: Column(
          children: [
            Text(
              'Chưa có câu trả lời.',
              style: TextStyles.regular,
            ),
            spaceHeight(100),
            BlueButton(
              title: 'Xoá',
              height: 48,
              bgColor: Colors.red,
              action: () {
                debugPrint('Send question');
                controller.deleteQuestion(question.guid);
              },
            )
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            svgAsset('assets/images/ic_question_send.svg'),
            spaceWidth(15),
            Expanded(
              child: Text(
                'Trả lời',
                style: TextStyles.semiBold
                    .copyWith(fontSize: 15, color: const Color(0xff181E39)),
              ),
            )
          ],
        ),
        spaceHeight(16),
        Row(
          children: [
            Expanded(
              child: Text(
                '${cauTraLoi.tenNguoiTraLoi} đã trả lời',
                style: TextStyles.semiBold
                    .copyWith(color: const Color(0xff003392)),
              ),
            ),
            Text(
              DateTimeUtils.stringFromDateTime(
                  cauTraLoi.thoiGianTraLoi, DateTimeConst.U_SECOND_FORMAT),
              style:
                  TextStyles.semiBold.copyWith(color: const Color(0xff637392)),
            ),
          ],
        ),
        spaceHeight(16),
        Text(
          cauTraLoi.traLoi ?? '',
          style: TextStyles.regular.copyWith(fontSize: 15),
        ),
        spaceHeight(16),
        Visibility(
            visible: (cauTraLoi.tenFileDinhKemTraLoi ?? '').isNotEmpty,
            child: InkWell(
              onTap: () {
                controller.downloadAndShare(
                    cauTraLoi.guidFileDinhKemsTraLoi?.first,
                    cauTraLoi.tenFileDinhKemTraLoi ?? '');
              },
              child: itemInfo(
                  'File đính kèm:', cauTraLoi.tenFileDinhKemTraLoi ?? ''),
            )),
      ],
    );
  }
}
