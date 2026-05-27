import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'package:vnu_noi_tru/widgets/nt_register_image_widget.dart';

class NTRegisterCmndWidget extends StatefulWidget {
  final String? prefixDTUU;
  final Function(List<NtFileMinhChungModel> fileMinhChung)? onChangeFiles;
  const NTRegisterCmndWidget(
      {super.key, required this.prefixDTUU, this.onChangeFiles});

  @override
  State<NTRegisterCmndWidget> createState() => _NTRegisterCmndWidgetState();
}

class _NTRegisterCmndWidgetState extends State<NTRegisterCmndWidget> {
  List<NtFileMinhChungModel> fileMinhChung = [];
  @override
  Widget build(BuildContext context) {
    if (widget.prefixDTUU == null) {
      return const SizedBox();
    }
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
              _excPickerPhoto();
            })
          ],
        ),
        Visibility(
          visible: fileMinhChung.isNotEmpty,
          child: Container(
            height: 100,
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fileMinhChung.length,
                itemBuilder: (ctx, index) {
                  return NTRegisterImageWidget(
                    file: fileMinhChung[index],
                    deleteAction: (image) {
                      fileMinhChung.remove(image);
                      setState(() {});
                    },
                  );
                }),
          ),
        ),
        const SizedBox(
          height: 8,
        )
      ],
    );
  }

  _excPickerPhoto() async {
    logInfo('Picker photo');
    final ImagePicker _picker = ImagePicker();
    XFile? image = await _picker.pickImage(
        maxHeight: 2000, maxWidth: 2000, source: ImageSource.gallery);
    if (image != null) {
      logInfo(image.name);
      int fileSize = await image.length();
      logInfo(fileSize.toString());

      NtFileMinhChungModel file = NtFileMinhChungModel(
          file: image,
          fileName: image.name,
          fileSize: fileSize,
          prefixDTUU: widget.prefixDTUU);
      file.exeUploadFile();
      fileMinhChung.add(file);

      setState(() {});
      if (widget.onChangeFiles != null) {
        widget.onChangeFiles!(fileMinhChung);
      }
    }
  }
}
