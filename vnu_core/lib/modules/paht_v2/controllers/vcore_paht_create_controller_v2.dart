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
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/exam_schedule/views/vcore_dropdown_select_widget.dart';
import 'package:vnu_core/repository/app_repository.dart';

class VcorePahtCreateControllerV2 extends GetxController {
  BuildContext? context;

  final RxList<KhuVucBanDoModel> listKhuVuc = RxList<KhuVucBanDoModel>([]);
  final Rxn<KhuVucBanDoModel> currentKhuVuc = Rxn<KhuVucBanDoModel>();

  final RxList<PhanAnhHienTruongChuDeModel> listChuDe = RxList<PhanAnhHienTruongChuDeModel>([]);
  final Rxn<PhanAnhHienTruongChuDeModel> currentChuDe = Rxn<PhanAnhHienTruongChuDeModel>();

  final RxList<FileUploadModel> listFiles = RxList<FileUploadModel>([]);
  final Rxn<LatLng> locationPoint = Rxn<LatLng>();

  final RxInt titleLength = 0.obs;
  final RxInt contentLength = 0.obs;

  String diaDiemPhanAnh = '';
  String tieuDePhanAnh = '';
  String noidungPhanAnh = '';

  @override
  void onInit() {
    super.onInit();
    getTatCaChuDe();
    getTatKhuVucBanDo();
  }

  Future<void> getTatCaChuDe() async {
    try {
      listChuDe.value = await ApiRepository().getPahtTatCaChuDe();
      if (listChuDe.isNotEmpty) {
        currentChuDe.value = listChuDe.first;
      }
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  void changeChuDeDropdown(VcoreDropdownModel model) {
    final obj = listChuDe.firstWhereOrNull((element) => element.guid == model.guid);
    if (obj != null) {
      currentChuDe.value = obj;
    }
  }

  Future<void> getTatKhuVucBanDo() async {
    try {
      listKhuVuc.value = await ApiRepository().getTatKhuVucBanDo();
      if (listKhuVuc.isNotEmpty) {
        currentKhuVuc.value = listKhuVuc.first;
      }
    } catch (e) {
      snackBarError(e.toString());
    }
  }

  void changeKhuVucDropdown(VcoreDropdownModel model) {
    final obj = listKhuVuc.firstWhereOrNull((element) => element.guid == model.guid);
    if (obj != null) {
      currentKhuVuc.value = obj;
    }
  }

  void onTitleChanged(String value) {
    tieuDePhanAnh = value.trim();
    titleLength.value = tieuDePhanAnh.length;
  }

  void onContentChanged(String value) {
    noidungPhanAnh = value.trim();
    contentLength.value = noidungPhanAnh.length;
  }

  Future<void> excCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      final model = FileUploadModel(file);
      listFiles.add(model);
      model.excUpload();
    }
  }

  Future<void> excCameraVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickVideo(source: ImageSource.camera);
    if (file == null) return;

    final String path = file.path;
    if (path.toLowerCase().endsWith('.mov')) {
      Utils.showProgress(context);
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        path,
        quality: VideoQuality.DefaultQuality,
        deleteOrigin: false,
      );
      Utils.dismissProgress(context);
      logSuccess(mediaInfo?.path ?? 'NULL Compress failed');
      if (mediaInfo?.file != null) {
        final model = FileUploadModel(XFile(mediaInfo!.file!.path));
        listFiles.add(model);
        model.prepareThumbForVideo();
        model.excUpload();
      }
    } else {
      final model = FileUploadModel(file);
      listFiles.add(model);
      model.excUpload();
    }
  }

  Future<void> excPickerPhotoVideo() async {
    logInfo('Picker excPickerPhotoVideo');
    Utils.showProgress(context);
    final ImagePicker picker = ImagePicker();
    List<XFile> files = await picker.pickMultipleMedia(maxHeight: 1920, maxWidth: 1920);

    bool isNeedAlert = false;
    if (Platform.isAndroid) {
      files = files.where((file) {
        final path = file.path;
        if (path.isVideo() || path.isImage() || (file.mimeType?.contains('video') == true) || (file.mimeType?.contains('image') == true)) {
          return true;
        }
        isNeedAlert = true;
        return false;
      }).toList();
    }

    Utils.dismissProgress(context);
    if (isNeedAlert) {
      snackBarWarning('Ứng dụng chỉ hỗ trợ ảnh và video.');
    }
    if (files.isEmpty) return;

    Utils.showAlertDialog(
      context,
      'Xác nhận',
      'Bạn có chắc chắn muốn tải tệp lên?',
      okStr: 'Đồng ý',
      cancelStr: 'Huỷ',
      withoutBinding: true,
      callBackOK: () async {
        if (kDebugMode) {
          for (final image in files) {
            try {
              logInfo(image.name);
              final fileSize = await image.length();
              logInfo(fileSize.toString());
            } catch (e) {
              logError(e.toString());
            }
          }
        }

        Utils.showProgress(context);
        final List<FileUploadModel> uploadModels = [];
        for (final element in files) {
          final fileSize = await element.length();
          if (fileSize > Globals().maxSizeMbUploadPaht * 1024 * 1024) {
            snackBarWarning('Tệp lựa chọn không được lớn hơn 30mb.');
            continue;
          }

          try {
            if (element.path.toLowerCase().endsWith('.mov')) {
              final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
                element.path,
                quality: VideoQuality.DefaultQuality,
                deleteOrigin: false,
              );
              logSuccess(mediaInfo?.path ?? 'NULL Compress failed');
              if (mediaInfo?.file != null) {
                uploadModels.add(FileUploadModel(XFile(mediaInfo!.file!.path)));
              } else {
                uploadModels.add(FileUploadModel(element));
              }
            } else {
              uploadModels.add(FileUploadModel(element));
            }
          } catch (e) {
            logError(e.toString());
          }
        }

        Utils.dismissProgress(context);
        listFiles.addAll(uploadModels);
        for (final element in uploadModels) {
          element.prepareThumbForVideo();
          element.excUpload();
        }
      },
    );
  }

  void submitPhanAnh() {
    if ((currentChuDe.value?.guid ?? '').isEmpty) {
      snackBarWarning('Bạn cần chọn chủ đề phản ánh.');
      return;
    }
    if ((currentKhuVuc.value?.guid ?? '').isEmpty) {
      snackBarWarning('Bạn cần chọn khu vực phản ánh.');
      return;
    }
    if (diaDiemPhanAnh.trim().isEmpty) {
      snackBarWarning('Bạn cần nhập địa điểm phản ánh.');
      return;
    }
    if (tieuDePhanAnh.trim().isEmpty) {
      snackBarWarning('Bạn cần nhập tiêu đề phản ánh.');
      return;
    }
    if (tieuDePhanAnh.trim().length > 100) {
      snackBarWarning('Tiêu đề phản ánh không được vượt quá 100 ký tự.');
      return;
    }
    if (noidungPhanAnh.trim().isEmpty) {
      snackBarWarning('Bạn cần nhập nội dung phản ánh.');
      return;
    }
    if (noidungPhanAnh.trim().length > 2000) {
      snackBarWarning('Nội dung phản ánh không được vượt quá 2000 ký tự.');
      return;
    }
    if (listFiles.length > 3) {
      snackBarWarning('Chỉ được tải tối đa 3 tệp đính kèm.');
      return;
    }

    for (final element in listFiles) {
      if (element.status.value == UploadFileState.uploading) {
        snackBarWarning('Đang tải files đính kèm, vui lòng đợi quá trình tải files thành công.');
        return;
      }
    }

    _excSubmitPhanAnh();
  }

  Future<void> _excSubmitPhanAnh() async {
    Utils.showProgress(context);
    try {
      final List<String> fileIds = [];
      for (final element in listFiles) {
        if ((element.uploadResult?.guid ?? '').isNotEmpty) {
          fileIds.add(element.uploadResult?.guid ?? '');
        }
      }

      String? mapDiaDiem;
      if (locationPoint.value?.latitude != null && locationPoint.value?.longitude != null) {
        mapDiaDiem = '${locationPoint.value?.latitude},${locationPoint.value?.longitude}';
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

      await ApiRepository().createPaht(request);
      Utils.dismissProgress(context);
      Get.back(result: true);
      snackBarSuccess('Thông tin phản ánh đã được gửi thành công.');
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }
}
