import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vnu_core/widgets/error_widget.dart';
import 'package:vnu_core/widgets/loading_indicator.dart';
import 'package:vnu_noi_tru/cubit/nt_register_cubit.dart';
import 'package:vnu_noi_tru/models/model.dart';

class NTRegisterImageWidget extends StatefulWidget {
  final NtFileMinhChungModel file;
  final Function(NtFileMinhChungModel file)? deleteAction;
  const NTRegisterImageWidget(
      {super.key, required this.file, this.deleteAction});

  @override
  State<NTRegisterImageWidget> createState() => _NTRegisterImageWidgetState();
}

class _NTRegisterImageWidgetState extends State<NTRegisterImageWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NtRegisterCubit, NtRegisterState>(
      bloc: widget.file.cubit,
      builder: (context, state) {
        if (state is NtRegisterLoading) {
          return const SizedBox(
            width: 90,
            height: 90,
            child: Center(
              child: LoadingIndicator(),
            ),
          );
        }
        if (state is NtRegisterUpLoadedError) {
          return SizedBox(
            width: 90,
            height: 90,
            child: Center(
              child: ErrorRefreshWidget(
                message: 'Lỗi tải file, thử lại',
                padding: 4,
                refreshAction: () {
                  widget.file.exeUploadFile();
                },
              ),
            ),
          );
        }
        return Stack(
          children: [
            Container(
              // width: 90,
              // height: 90,
              margin: const EdgeInsets.only(right: 2),
              child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      File(
                        widget.file.file?.path ?? '',
                      ),
                      fit: BoxFit.cover,
                    ),
                  )
                  // CachedNetworkImage(
                  //   imageUrl: Uri.file(widget.file.file?.path ?? '').toFilePath(),
                  // ),
                  ),
            ),
            Visibility(
              visible: widget.file.status == 1,
              child: Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 15,
                    ),
                    onPressed: () {
                      if (widget.deleteAction != null) {
                        widget.deleteAction!(widget.file);
                      }
                    },
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}
