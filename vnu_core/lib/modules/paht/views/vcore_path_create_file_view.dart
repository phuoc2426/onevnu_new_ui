import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/extensions/xfile_ext.dart';
import 'package:vnu_core/models/file_upload_model.dart';
import 'package:vnu_core/themes/app_theme.dart';

class VcorePathCreateFileView extends StatefulWidget {
  final FileUploadModel fileUploadModel;
  final VoidCallback? onDelete;
  const VcorePathCreateFileView(
      {super.key, required this.fileUploadModel, this.onDelete});

  @override
  State<VcorePathCreateFileView> createState() =>
      _VcorePathCreateFileViewState();
}

class _VcorePathCreateFileViewState extends State<VcorePathCreateFileView> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        OpenFilex.open(widget.fileUploadModel.source.path);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Obx(
          () => Stack(
            fit: StackFit.expand,
            children: [
              // -- Thum
              if (widget.fileUploadModel.thumbnailFile.value != null) ...[
                Image.file(
                  widget.fileUploadModel.thumbnailFile.value!,
                  fit: BoxFit.cover,
                ),
              ],

              if (widget.fileUploadModel.source.isVideo == false) ...[
                Image.file(
                  File(widget.fileUploadModel.source.path),
                  fit: BoxFit.cover,
                ),
              ],

              // -- video
              if (widget.fileUploadModel.source.isVideo)
                const Icon(
                  Icons.play_circle_outline_rounded,
                  color: AppTheme.backgroundBlueColor,
                  size: 40,
                ),

              // Uploading
              if (widget.fileUploadModel.status.value ==
                  UploadFileState.uploading)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Spacer(),

                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      spaceHeight(10),
                      Text(
                        'Tải lên ${widget.fileUploadModel.processing.value}%',
                        style: TextStyles.regular.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                            shadows: [BoxShadow(color: Colors.black)]),
                      )
                    ],
                  ),
                ),

              // Upload success
              if (widget.fileUploadModel.status.value ==
                  UploadFileState.success)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Colors.green,
                      ),
                      spaceHeight(4),
                      Text(
                        'Tải lên\nthành công',
                        textAlign: TextAlign.center,
                        style: TextStyles.regular.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                            shadows: [BoxShadow(color: Colors.black)]),
                      ),
                    ],
                  ),
                ),

              // Upload success
              if (widget.fileUploadModel.status.value == UploadFileState.failed)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: IconButton(
                    onPressed: () {
                      widget.fileUploadModel.excUpload();
                    },
                    icon: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_rounded,
                          color: Colors.red,
                        ),
                        spaceHeight(4),
                        Text(
                          'Lỗi\nThử lại',
                          textAlign: TextAlign.center,
                          style: TextStyles.regular.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                              shadows: [BoxShadow(color: Colors.black)]),
                        ),
                      ],
                    ),
                  ),
                ),

              Positioned(
                right: 4,
                bottom: 4,
                child: GestureDetector(
                  onTap: () {
                    Utils.showAlertDialog(
                      context,
                      'Xác nhận',
                      'Bạn có chắc chắn muốn xoá ảnh?',
                      okStr: 'Đồng ý',
                      cancelStr: 'Huỷ',
                      withoutBinding: true,
                      callBackOK: () {
                        if (widget.onDelete != null) {
                          widget.onDelete!();
                        }
                      },
                    );
                  },
                  child: const Icon(
                    Icons.delete,
                    color: AppTheme.backgroundBlueColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
