import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

extension XfileExt on XFile {
  bool get isVideo {
    String? mimeType = lookupMimeType(path);
    if (mimeType?.contains('video') == true) {
      return true;
    }
    return false;
  }
}
