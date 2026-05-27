import 'dart:async';
import 'dart:io' show Directory, File, FileMode;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../common/log.dart';
import '../constants/enum.dart';
import '../globals.dart';

class FileUtil {
  static Future<String> findLocalPath() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  static Future<String> iOfficeFolderPath() async {
    return (await FileUtil.findLocalPath());
  }

  static Future<String> handleFileName(String localPath, String name) async {
    String nameCache = name;
    String fullPath = "$localPath/$nameCache";
    File fileDownload = File(fullPath);
    var i = 0;
    while (await fileDownload.exists()) {
      if (nameCache.contains("($i)")) {
        nameCache = name.replaceAll("($i)", "");
      }
      i = i + 1;
      final nameSplit = nameCache.split('.');
      if (nameSplit.isNotEmpty) {
        if (nameSplit.length == 2) {
          nameCache = '${nameSplit[0]}($i).${nameSplit[1]}';
        } else if (nameSplit.length > 2) {
          for (var i = 0; i < nameSplit.length - 1; i++) {
            nameCache = '$nameCache${nameSplit[i]}';
          }
          nameCache = '$nameCache($i).${nameSplit[nameSplit.length - 1]}';
        } else {
          nameCache = name;
        }
      } else {
        nameCache = name;
      }
      fullPath = "$localPath/$nameCache";
      fileDownload = File(fullPath);
    }
    return fullPath;
  }

  static String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}

class DownLoadManager {
  static final DownLoadManager _singleton = DownLoadManager._internal();

  factory DownLoadManager() {
    return _singleton;
  }

  DownLoadManager._internal() {
    //Check and create folder download
    prepare();
  }

  // String iStorageDownloadLink(String fileId) {
  //   return '$kBaseUrl$kStorageDownloadPath/$fileId';
  // }

  String? _localPath;

  Future<void> prepare() async {
    //Get Path
    _localPath = await FileUtil.iOfficeFolderPath();
    logSuccess(_localPath ?? '');
    //Save Folder
    final savedDir = Directory(_localPath!);
    final hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
  }

  Future downloadFile(
    String url,
    String? name,
    DownloadMode mode, {
    Function(int progress, int fileSize)? onProgress,
    required String guid,
    required Function(String path) onComplete,
    Function(String e)? onError,
  }) async {
    if (_localPath == null) {
      await prepare();
    }
    var dio = Dio();
    String fullPath = "", fullDir = "";
    fullDir = "${_localPath ?? ''}/$guid";
    fullPath = "$fullDir/$name";
    if (mode == DownloadMode.PreviewTemp) {
      final extDir = await getTemporaryDirectory();
      fullDir = "${extDir.path}/$guid";
      fullPath = "$fullDir/$name";
    }
    final directory = Directory(fullDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final File file = File(fullPath);
    var isExist = false;
    try {
      isExist = await file.exists();
    } catch (e) {
      isExist = false;
    }
    if (isExist) {
      onComplete(file.path);
    } else {
      logInfo('downloadFile ---> $url');
      try {
        String token = Globals().token;
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
            headers: {'Authorization': 'Bearer $token'},
            validateStatus: (status) {
              return status! < 500;
            },
          ),
        );
        var raf = file.openSync(mode: FileMode.write);
        raf.writeFromSync(response.data);
        await raf.close();
        onComplete(file.path);
      } catch (e) {
        if (onError != null) {
          onError(e.toString());
        }
      }
    }
  }
}
