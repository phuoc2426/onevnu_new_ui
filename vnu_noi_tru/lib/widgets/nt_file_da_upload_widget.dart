import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/themes/app_theme.dart';

import '../models/model.dart';

class NtFileDaUploadWidget extends StatefulWidget {
  final List<NtFileDaUploadModel> listFile;

  const NtFileDaUploadWidget({super.key, required this.listFile});

  @override
  State<NtFileDaUploadWidget> createState() => _NtFileDaUploadWidgetState();
}

class _NtFileDaUploadWidgetState extends State<NtFileDaUploadWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'File minh chứng',
              style: AppTheme.body2.copyWith(fontStyle: FontStyle.italic),
            ),
            svgAction('assets/images/ic_attach_file.svg', action: () {
              // _excPickerPhoto();
            })
          ],
        ),
        Container(
            height: 100,
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.listFile.length,
                itemBuilder: (ctx, index) {
                  return _item(widget.listFile[index]);
                })),
        const SizedBox(
          height: 8,
        )
      ],
    );
  }

  Widget _item(NtFileDaUploadModel model) {
    return AspectRatio(
      aspectRatio: 1,
      child: CachedNetworkImage(
        imageUrl: '${model.duongDanFile}',
        cacheKey: '${model.duongDanFile}',
      ),
    );
  }
}
