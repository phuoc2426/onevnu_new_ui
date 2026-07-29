import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/log.dart';

const kLoginUserName = 'kLoginUserName';
const kLoginPassword = 'kLoginPassword';
const kLoginToken = 'kLoginToken';
const kLoginRefreshToken = 'kLoginRefreshToken';

const kSessionPrincipalType = 'kSessionPrincipalType';
const kPrincipalTypeUser = 'USER';
const kPrincipalTypeApplicant = 'APPLICANT';

const kApplicantAccessToken = 'kApplicantAccessToken';
const kApplicantRefreshToken = 'kApplicantRefreshToken';
const kLoginEnableBio = 'kLoginEnableBio';
const kMaKhuVuc = 'kMaKhuVuc';

class DataRepository {
  final _secureStorage = const FlutterSecureStorage();

  DataRepository._internal() {
    //Local secure storage
  }

  static final DataRepository _singleton = DataRepository._internal();
  factory DataRepository() {
    return _singleton;
  }

  // Local storage
  Future<void> saveSecureUserLogin(String username, String password) async {
    await Future.wait<void>([
      _secureStorage.write(key: kLoginUserName, value: username),
      _secureStorage.write(key: kLoginPassword, value: password),
    ]);
  }

  Future<void> saveSecureKey(String key, String value) async {
    dlog('DataRepository -------------> saveSecureKey -| $key |-');
    await _secureStorage.write(key: key, value: value);
  }

  Future<void> deleteSecureKey(String? key) async {
    dlog('DataRepository -------------> deleteSecureKey -| $key |-');
    if (key != null && key.isNotEmpty) {
      await _secureStorage.delete(key: key);
    }
  }

  Future<String?> getSecureSaveKey(String? key) async {
    dlog('DataRepository -------------> getSecureSaveKey -| $key |-');
    if (key == null) return null;
    return _secureStorage.read(key: key);
  }

  //Local databas
}
