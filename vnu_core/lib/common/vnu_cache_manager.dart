import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/globals.dart';

class VnuCacheManager {
  static const key = 'VnuCacheManager';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 20),
      // maxNrOfCacheObjects: 20,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileSystem: IOFileSystem(key),
      fileService: HttpFileService(),
    ),
  );

  static Future<File?> downloadAndCache(
      String url, String guid, String ext) async {
    var trackKey = guid;

    try {
      FileInfo? fileCached =
          await VnuCacheManager.instance.getFileFromCache(trackKey);
      if (fileCached?.file != null) {
        logSuccess(fileCached!.file.path);
        return fileCached.file;
      }

      var file = await VnuCacheManager.instance
          .getSingleFile(url, key: '${trackKey}_tmp');
      var trackFile = await VnuCacheManager.instance.putFileStream(
          url, file.openRead(),
          fileExtension: ext, key: trackKey);
      logSuccess(file.path);
      //Delete file temp
      file.deleteSync();

      return trackFile;
    } catch (e) {
      return null;
    }
  }
}

class VnuCacheFileManager {
  VnuCacheFileManager._internal() {}

  static final VnuCacheFileManager _singleton = VnuCacheFileManager._internal();

  factory VnuCacheFileManager() {
    return _singleton;
  }

  Future<bool> saveCacheFile(String name, String data) async {
    //var completer = Completer<bool>();
    return Future.delayed(Duration.zero, () async {
      if (Globals().usernameLogin.isEmpty) {
        logError(
            'Globals().usernameLogin not found. Cancel save custome file cache for user.');
        return false;
      }
      try {
        String newPath = await getPathWithName(name);
        var file = File(newPath);
        var raf = file.openSync(mode: FileMode.write);
        raf.writeStringSync(data);
        await raf.close();

        print(newPath);
        logSuccess('saveCacheFile --> $name');
        return true;
      } catch (e) {
        logError(e.toString());
      }
      return false;
    });
    //return completer.future;
  }

  deleteCacheFile(String name) async {
    if (Globals().usernameLogin.isEmpty) {
      logError(
          'Globals().usernameLogin not found. Cancel save custome file cache for user.');
      return false;
    }
    try {
      String newPath = await getPathWithName(name);
      var file = File(newPath);
      if (file.existsSync()) {
        file.delete();

        logWarning("DELETE file cache --> $newPath");
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<String?> getCacheFile(String name) async {
    return Future.delayed(
      Duration.zero,
      () async {
        try {
          String newPath = await getPathWithName(name);
          File file = File(newPath);
          if (file.existsSync()) {
            return file.readAsString();
          }
          return null;
        } catch (e) {
          logError(e.toString());
        }
      },
    );
  }

  Future<String> getPathWithName(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    String newPath = '${directory.path}/${Globals().usernameLogin}_$fileName';
    return newPath;
  }
}
