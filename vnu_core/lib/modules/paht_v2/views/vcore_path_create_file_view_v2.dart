import 'package:flutter/material.dart';
import 'package:vnu_core/models/file_upload_model.dart';

class VcorePathCreateFileViewV2 extends StatelessWidget {
  final FileUploadModel fileUploadModel;
  final VoidCallback onDelete;

  const VcorePathCreateFileViewV2({
    super.key,
    required this.fileUploadModel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xffF3F6F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffE4EAF2)),
          ),
          child: const Center(
            child: Icon(Icons.insert_drive_file_outlined, color: Color(0xff637392)),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onDelete,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
