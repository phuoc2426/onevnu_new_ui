import 'dart:io';
import 'dart:math';

import 'package:get/get.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/extensions/xfile_ext.dart';
import 'package:vnu_core/repository/app_repository.dart';

import 'file_dinh_kem_model.dart';

class FileUploadModel {
  XFile source;
  String? errorMessage;
  Rx<UploadFileState> status = (UploadFileState.none).obs;
  Rx<int> processing = 0.obs;

  //Info video
  Rxn<File> thumbnailFile = Rxn();

  Rxn<bool> isVideoFile = Rxn();

  FileDinhKemModel? uploadResult;

  FileUploadModel(this.source);

  Future<void> prepareThumbForVideo() async {
    if (isVideoFile.value != null) {
      return;
    }

    isVideoFile.value = source.isVideo;

    //Create thumb for video selected
    if (isVideoFile.value == true) {
      File fileThumb = await VideoCompress.getFileThumbnail(source.path,
          quality: 50, // default(100)
          position: -1 // default(-1)
          );
      logInfo("video souce --> ${source.path}");
      logSuccess('prepareThumbForVideo --> get thumb success');
      logSuccess(fileThumb.path);

      thumbnailFile.value = fileThumb;

      // XFile file = await VideoThumbnail.thumbnailFile(
      //   video: source.path,
      //   thumbnailPath: (await getTemporaryDirectory()).path,
      //   maxHeight:
      //       180, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
      //   maxWidth: 180,
      //   quality: 75,
      // );
      // logSuccess('prepareThumbForVideo --> get thumb success');
      // logSuccess(file.path);
      // thumbnailFile.value = File(file.path);
      // print('object');
    }
  }

  excUpload() async {
    // Test
    //return;
    if (status.value == UploadFileState.success ||
        status.value == UploadFileState.uploading ||
        uploadResult != null) {
      logError("Cancel excUpload...");
      return;
    }
    status.value = UploadFileState.uploading;

    try {
      // uploadFileState.value = UploadFileState.uploading;
      var response = await ApiRepository().uploadFile(
        File(source.path),
        onSendProgress: (count, total) {
          processing.value = count * 100 ~/ total;
          logInfo('Progress --> $processing');
        },
      );
      uploadResult = response;
      status.value = UploadFileState.success;
      logSuccess('upload success...');
    } catch (e) {
      status.value = UploadFileState.failed;
      snackBarError(e.toString());
    }
  }
}
