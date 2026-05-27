import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/data_request/phan_anh_hien_truong_request.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/file_upload_model.dart';
import 'package:vnu_core/modules/exam_schedule/views/vcore_dropdown_select_widget.dart';
import 'package:vnu_core/repository/app_repository.dart';

import '../../../models/model.dart';

class VcorePahtCreateController extends GetxController {
  BuildContext? context;
  // Khu vuc
  RxList<KhuVucBanDoModel> listKhuVuc = RxList([]);
  Rxn<KhuVucBanDoModel> currentKhuVuc = Rxn();

  //Chu de
  RxList<PhanAnhHienTruongChuDeModel> listChuDe = RxList();
  Rxn<PhanAnhHienTruongChuDeModel> currentChuDe = Rxn();

  String diaDiemPhanAnh = '';
  String tieuDePhanAnh = '';
  String noidungPhanAnh = '';

  RxList<FileUploadModel> listFiles = RxList([]);

  Rxn<LatLng> locationPoint = Rxn();

  @override
  void onInit() {
    super.onInit();

    getTatCaChuDe();

    getTatKhuVucBanDo();
  }

  getTatCaChuDe() async {
    try {
      listChuDe.value = await ApiRepository().getPahtTatCaChuDe();
      if (listChuDe.isNotEmpty) {
        currentChuDe.value = listChuDe.first;
      }
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  changeChuDeDropdown(VcoreDropdownModel model) {
    PhanAnhHienTruongChuDeModel? obj =
        listChuDe.firstWhereOrNull((element) => element.guid == model.guid);
    if (obj != null) {
      currentChuDe.value = obj;
    }
  }

  getTatKhuVucBanDo() async {
    try {
      listKhuVuc.value = await ApiRepository().getTatKhuVucBanDo();
      if (listKhuVuc.isNotEmpty) {
        currentKhuVuc.value = listKhuVuc.first;
      }
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  changeKhuVucDropdown(VcoreDropdownModel model) {
    KhuVucBanDoModel? obj =
        listKhuVuc.firstWhereOrNull((element) => element.guid == model.guid);
    if (obj != null) {
      currentKhuVuc.value = obj;
    }
  }

  excCamera() async {
    final ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      FileUploadModel model = FileUploadModel(file);
      listFiles.add(model);
      model.excUpload();
    }
  }

  excCameraVideo() async {
    final ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickVideo(source: ImageSource.camera);
    if (file != null) {
      String path = file.path;
      if (path.toLowerCase().endsWith('.mov')) {
        // Convert mov to mp4
        Utils.showProgress(context);

        MediaInfo? mediaInfo = await VideoCompress.compressVideo(
          path,
          quality: VideoQuality.DefaultQuality,
          deleteOrigin: false, // It's false by default
        );
        Utils.dismissProgress(context);
        logSuccess(mediaInfo?.path ?? 'NULL Compress failed');
        if (mediaInfo?.file != null) {
          FileUploadModel model = FileUploadModel(XFile(mediaInfo!.file!.path));
          listFiles.add(model);
          model.prepareThumbForVideo();
          model.excUpload();
        }
      } else {
        //Add and upload video
        FileUploadModel model = FileUploadModel(file);
        listFiles.add(model);
        model.excUpload();
      }
    }
  }

  excPickerPhotoVideo() async {
    logInfo('Picker excPickerPhotoVideo');
    Utils.showProgress(context);
    final ImagePicker _picker = ImagePicker();
    List<XFile> images =
        await _picker.pickMultipleMedia(maxHeight: 1920, maxWidth: 1920);

    // filter image only by android allow pick files
    bool isNeedAlert = false;
    if (Platform.isAndroid) {
      images = images.where((file) {
        String path = file.path;

        if (path.isVideo() ||
            path.isImage() ||
            (file.mimeType?.contains('video') == true) ||
            (file.mimeType?.contains('image') == true)) {
          return true;
        }
        ;
        isNeedAlert = true;
        return false;
      }).toList();
    }

    if (isNeedAlert) {
      snackBarWarning('Ứng dụng chỉ hỗ trợ ảnh và video.');
    }

    Utils.dismissProgress(context);
    if (images.isNotEmpty) {
      Utils.showAlertDialog(
        context,
        'Xác nhận',
        'Bạn có chắc chắn muốn tải tệp lên?',
        okStr: 'Đồng ý',
        cancelStr: 'Huỷ',
        withoutBinding: true,
        callBackOK: () async {
          if (kDebugMode) {
            try {
              images.forEach((image) async {
                logInfo(image.name);
                int fileSize = await image.length();
                logInfo(fileSize.toString());
              });
            } catch (e) {
              logError(e.toString());
            }
          }

          Utils.showProgress(context);
          List<FileUploadModel> listFilesModel = [];
          for (var element in images) {
            int fileSize = await element.length();
            if (fileSize > Globals().maxSizeMbUploadPaht * 1024 * 1024) {
              snackBarWarning('Tệp lựa chọn không được lớn hơn 30mb.');
            } else {
              try {
                if (element.path.toLowerCase().endsWith('.mov')) {
                  MediaInfo? mediaInfo = await VideoCompress.compressVideo(
                    element.path,
                    quality: VideoQuality.DefaultQuality,
                    deleteOrigin: false, // It's false by default
                  );
                  Utils.dismissProgress(context);
                  logSuccess(mediaInfo?.path ?? 'NULL Compress failed');
                  if (mediaInfo?.file != null) {
                    FileUploadModel model =
                        FileUploadModel(XFile(mediaInfo!.file!.path));
                    listFilesModel.add(model);
                  } else {
                    listFilesModel.add(FileUploadModel(element));
                  }
                } else {
                  listFilesModel.add(FileUploadModel(element));
                }
              } catch (e) {
                logError(e.toString());
              }
            }
          }

          Utils.dismissProgress(context);

          listFiles.addAll(listFilesModel);

          for (var element in listFilesModel) {
            element.prepareThumbForVideo();
            element.excUpload();
          }
        },
      );
    }
  }

  submitPhanAnh() {
    if (currentChuDe.value?.guid == null) {
      snackBarWarning('Bạn cần chọn chủ đề phản ánh.');
      return;
    }
    if (currentKhuVuc.value?.guid == null) {
      snackBarWarning('Bạn cần chọn khu vực phản ánh.');
      return;
    }
    if (diaDiemPhanAnh.isEmpty) {
      snackBarWarning('Bạn cần nhập địa điểm phản ánh.');
      return;
    }
    if (noidungPhanAnh.isEmpty) {
      snackBarWarning('Bạn cần nhập nội dung phản ánh.');
      return;
    }
    Utils.showProgress(context);

    if (listFiles.isNotEmpty) {
      //exc upload file
      for (var element in listFiles) {
        if (element.status.value == UploadFileState.uploading) {
          snackBarWarning(
              'Đang tải files đính kèm, vui lòng đợi quá trình tải files thành công');
          return;
        }
      }
    }

    _excSubmitPhanAnh();
  }

  _excSubmitPhanAnh() async {
    Utils.showProgress(context);
    try {
      List<String> fileIds = [];
      for (var element in listFiles) {
        // Upload file success --> uploadResult != null
        if ((element.uploadResult?.guid ?? '').isNotEmpty) {
          fileIds.add(element.uploadResult?.guid ?? '');
        }
      }

      String? mapDiaDiem;
      if (locationPoint.value?.latitude != null &&
          locationPoint.value?.longitude != null) {
        mapDiaDiem =
            '${locationPoint.value?.latitude},${locationPoint.value?.longitude}';
      }

      final request = PhanAnhHienTruongRequest(
        guidChuDe: currentChuDe.value?.guid ?? '',
        guidKhuVucBanDo: currentKhuVuc.value?.guid ?? '',
        tieuDePhanAnh: tieuDePhanAnh,
        diaDiemPhanAnh: diaDiemPhanAnh,
        mapDiaDiemPhanAnh: mapDiaDiem,
        noiDungPhanAnh: noidungPhanAnh,
        guidFileDinhKemsPhanAnh: fileIds,
      );
      var _ = await ApiRepository().createPaht(request);
      Utils.dismissProgress(context);

      Get.back();
      snackBarSuccess('Thông tin phản ánh đã được gửi thành công.');
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }
}
