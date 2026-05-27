import 'package:image_picker/image_picker.dart';
import 'package:vnu_noi_tru/cubit/nt_register_cubit.dart';

class NtFileMinhChungModel {
  XFile? file;
  double? process;
  int? status = 0; // 0 dang upload / 1 thanh cong / -1 loi
  int? fileSize;
  String? fileName;
  // Hệ thống hỗ trợ sinh viên
  int? fileMinhChungId;
  String? urlUpload;
  String? prefixDTUU;

  NtRegisterCubit cubit = NtRegisterCubit();

  NtFileMinhChungModel(
      {this.file,
      this.process,
      this.status,
      this.fileName,
      this.fileSize,
      this.prefixDTUU});

  exeUploadFile() {
    cubit.uploadFile(this, prefixDTUU ?? '0001');
  }
}
