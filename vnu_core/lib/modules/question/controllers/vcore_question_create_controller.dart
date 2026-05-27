import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/data_request/tao_hoi_dap_request.dart';
import 'package:vnu_core/models/chu_de_model.dart';
import 'package:vnu_core/models/file_dinh_kem_model.dart';
import 'package:vnu_core/repository/app_repository.dart';

class VcoreQuestionCreateController extends GetxController {
  BuildContext? context;

  final TextEditingController textEditingController = TextEditingController();

  RxList<ChuDeModel> listChuDe = RxList([]);
  Rxn<ChuDeModel> currentChuDe = Rxn();
  final allChuDe = ChuDeModel(tenChuDe: 'Tất cả chủ đề', guid: '');

  Rxn<FileDinhKemModel> fileAttach = Rxn();

  Rx<UploadFileState> uploadFileState = UploadFileState.none.obs;

  @override
  void onInit() {
    super.onInit();

    // listChuDe.value = [allChuDe];
    // currentChuDe.value = allChuDe;
  }

  @override
  void onClose() {
    textEditingController.dispose();
    super.onClose();
  }

  getTatCaChuDe() async {
    try {
      Utils.showProgress(context);
      var response = await ApiRepository().getTatChuDeHoiDap();
      listChuDe.addAll(response);
      if (listChuDe.isNotEmpty) {
        currentChuDe.value = listChuDe.first;
      }
      Utils.dismissProgress(context);
    } catch (e) {
      snackBarError(e.toString());
      Utils.dismissProgress(context);
    }
  }

  changeChuDe(String? title) {
    ChuDeModel? obj = listChuDe
        .firstWhereOrNull((element) => element.tenChuDe == (title ?? "_///_"));
    if (obj != null) {
      currentChuDe.value = obj;
    }
  }

  pickFileAttach() async {
    if (fileAttach.value != null) {
      snackBarWarning('Bạn chỉ được chọn 1 file đính kèm');
    }
    //// VNU support attach file jpg,doc,docx,pdf,ppt,pptx,xls,xlsx,png,jpeg
    final List<String> allowedExtensions = [
      JPG.toLowerCase(),
      JPEG.toLowerCase(),
      DOC.toLowerCase(),
      DOCX.toLowerCase(),
      PDF.toLowerCase(),
      PPT.toLowerCase(),
      PPTX.toLowerCase(),
      XLS.toLowerCase(),
      XLSX.toLowerCase(),
      PNG.toLowerCase(),
      JPEG.toLowerCase(),
    ];
    FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: allowedExtensions);

    if (result != null) {
      List<File> files = result.paths.map((path) => File(path!)).toList();
      if (files.isNotEmpty) {
        Utils.showAlertDialog(
          context,
          'Xác nhận',
          'Bạn có chắc chắn muốn tải tệp lên?',
          okStr: 'Đồng ý',
          cancelStr: 'Huỷ',
          withoutBinding: true,
          callBackOK: () {
            uploadFileDinhKem(files.first);
          },
        );
      }
    } else {
      // User canceled the picker
    }
  }

  uploadFileDinhKem(File fileUpload) async {
    try {
      uploadFileState.value = UploadFileState.uploading;
      var response = await ApiRepository().uploadFileDinhKem(
        fileUpload,
        onSendProgress: (count, total) {
          print('Progress --> ${count * 100 / total}');
        },
      );
      fileAttach.value = response;
      uploadFileState.value = UploadFileState.none;
      logSuccess('upload success...');
    } catch (e) {
      uploadFileState.value = UploadFileState.none;
      snackBarError(e.toString());
    }
  }

  deleteFileDinhKem() {
    fileAttach.value = null;
  }

  guiCauHoi() async {
    if (currentChuDe.value == null) {
      snackBarWarning('Bạn cần chọn chủ đề.');
      return;
    }
    if (textEditingController.text.trim().isEmpty) {
      snackBarWarning('Bạn cần nhập nội dung câu hỏi.');
      return;
    }
    // Check file is uploading
    if (uploadFileState.value == UploadFileState.uploading) {
      snackBarWarning('Bạn vui lòng đợi tệp đính kèm được tải lên thành công.');
      return;
    }

    TaoHoiDapRequest request = TaoHoiDapRequest(
        guidChuDe: currentChuDe.value?.guid,
        guidFileDinhKems: fileAttach.value?.guid != null
            ? [fileAttach.value?.guid ?? '']
            : [],
        cauHoi: textEditingController.text.trim());
    Utils.showProgress(context);

    try {
      var response = await ApiRepository().guiCauHoiDap(request);
      Get.back(result: true);
      snackBarSuccess(
          'Gửi câu hỏi thành công, bạn sẽ nhận được thông báo khi có câu trả lời.');
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }
}
