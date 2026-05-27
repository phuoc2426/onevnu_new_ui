import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class VnuDownLoadManager {
  static final VnuDownLoadManager _singleton = VnuDownLoadManager._internal();

  factory VnuDownLoadManager() {
    return _singleton;
  }

  VnuDownLoadManager._internal() {
    //Check and create folder download
  }

  String? _localPath;

  Future downloadFile(
    String url,
    String? name, {
    Function(int progress, int fileSize)? onProgress,
    required Function(String path) onComplete,
    Function(String e)? onError,
  }) async {
    var dio = Dio();
    String fullPath = "";
    final extDir = await getTemporaryDirectory();
    fullPath = "${extDir.path}/$name";
    File file = File(fullPath);
    if (file.existsSync()) {
      onComplete(file.path);
    } else {
      try {
        Response response = await dio.get(
          url,
          onReceiveProgress: (int progress, int fileSize) {
            if (onProgress != null) {
              onProgress(progress, fileSize);
            }
          },
          options: Options(
              responseType: ResponseType.bytes,
              followRedirects: false,
              validateStatus: (status) {
                return status! < 500;
              }),
        );
        var raf = file.openSync(mode: FileMode.write);
        raf.writeFromSync(response.data);
        await raf.close();
        onComplete(fullPath);
      } catch (e) {
        if (onError != null) {
          onError(e.toString());
        }
      }
    }
  }

  openFile(String path) {
    OpenFilex.open(path);
  }
}
