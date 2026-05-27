import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/file_utils.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/modules/question/controllers/vcore_question_create_controller.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/container_dissmis.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

import '../../exam_schedule/views/vcore_dropdown_select_widget.dart';

class VcoreQuestionCreateView extends GetView<VcoreQuestionCreateController> {
  const VcoreQuestionCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreQuestionCreateController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            if (controller.currentChuDe.value == null) {
              controller.getTatCaChuDe();
            }
          },
          child: Scaffold(
            appBar: NaviWidget(
              titleStr: 'Thêm mới câu hỏi',
            ),
            backgroundColor: AppColor.bgColor,
            body: SafeArea(
              child: ContainerAutoDissmis(
                child: Obx(
                  () => Column(
                    children: [
                      Expanded(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                //---- Chu De
                                Row(
                                  children: [
                                    Text('Chủ đề',
                                        style: TextStyles.regular
                                            .copyWith(color: Colors.black)),
                                    Text(
                                      ' *',
                                      style: TextStyles.regular
                                          .copyWith(color: Colors.red),
                                    )
                                  ],
                                ),

                                // drop
                                Container(
                                  height: 58,
                                  color: Colors.white,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Center(
                                    child: VcoreDropdownSelectWidget(
                                      items: controller.listChuDe
                                          .map((e) => e.tenChuDe ?? '')
                                          .toList(),
                                      hint: 'Chọn chủ đề',
                                      value: controller
                                          .currentChuDe.value?.tenChuDe,
                                      onSelected: (value) {
                                        controller.changeChuDe(value);
                                      },
                                    ),
                                  ),
                                ),

                                //--- Noi dung cau hoi
                                spaceHeight(16),
                                Row(
                                  children: [
                                    Text('Nội dung câu hỏi',
                                        style: TextStyles.regular
                                            .copyWith(color: Colors.black)),
                                    Text(
                                      ' *',
                                      style: TextStyles.regular
                                          .copyWith(color: Colors.red),
                                    )
                                  ],
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8, bottom: 24),
                                  child: TextField(
                                    controller:
                                        controller.textEditingController,
                                    style: TextStyles.regular,
                                    autofocus: false,
                                    maxLines: 10,
                                    decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.all(8),
                                        border: textFieldBorder(),
                                        enabledBorder: textFieldBorder(),
                                        focusedBorder: textFieldBorder()),
                                  ),
                                ),

                                //---- file
                                Row(
                                  children: [
                                    Text(
                                      'File đính kèm',
                                      style: TextStyles.italic,
                                    ),
                                    spaceWidth(20),
                                    IconButton(
                                        onPressed: () {
                                          Utils.hideKeyboard();
                                          if (controller
                                                  .uploadFileState.value ==
                                              UploadFileState.uploading) {
                                            snackBarError(
                                                'Tệp đính kèm đang được tải lên');
                                          }
                                          controller.pickFileAttach();
                                        },
                                        icon: const Icon(Icons.attach_file))
                                  ],
                                ),
                                Obx(() {
                                  return Container(
                                    child: controller.fileAttach.value != null
                                        ? itemFileUploaded(controller)
                                        : controller.uploadFileState.value ==
                                                UploadFileState.uploading
                                            ? Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10),
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              )
                                            : const SizedBox(),
                                  );
                                })
                              ],
                            ),
                          ),
                        ),
                      ),

                      //--- Button Send
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: BlueButton(
                          title: 'Gửi câu hỏi',
                          height: 48,
                          action: () {
                            Utils.showAlertDialog(
                              context,
                              'Xác nhận',
                              'Bạn có chắc chắn muốn gửi câu hỏi?',
                              okStr: 'Đồng ý',
                              cancelStr: 'Huỷ',
                              callBackOK: () {
                                debugPrint('Send question');
                                controller.guiCauHoi();
                              },
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget itemFileUploaded(VcoreQuestionCreateController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.fileAttach.value?.name ?? '',
                  style: TextStyles.regular,
                ),
                Text(
                  FileUtil.formatBytes(
                      controller.fileAttach.value?.size ?? 0, 2),
                  style: TextStyles.regular,
                ),
              ],
            ),
          ),
          IconButton(
              onPressed: () {
                controller.deleteFileDinhKem();
              },
              icon: const Icon(Icons.close))
        ],
      ),
    );
  }

  OutlineInputBorder textFieldBorder() {
    return OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF879ABF)),
        borderRadius: BorderRadius.circular(10));
  }
}
