import 'package:shared_preferences/shared_preferences.dart';

const ACCESS_TOKEN = "ACCESS_TOKEN";
const REFRESH_TOKEN = "REFRESH_TOKEN";
const kUSER_INFO = "USER_INFO";
const kUSER_ENABLE_LOGIN_BIO = "kUSER_ENABLE_LOGIN_BIO";

class LocalStorage {
  final SharedPreferences sharedPreferences;
  LocalStorage({required this.sharedPreferences});

  String getAccessToken() {
    return sharedPreferences.getString(ACCESS_TOKEN) ?? '';
  }

  void saveAccessToken(String accessToken) {
    sharedPreferences.setString(ACCESS_TOKEN, accessToken);
  }

  String getRefreshToken() {
    return sharedPreferences.getString(REFRESH_TOKEN) ?? '';
  }

  void saveRefreshToken(String refreshToken) {
    sharedPreferences.setString(REFRESH_TOKEN, refreshToken);
  }

  // void saveUserInfo(User? user) {
  //   if (user == null) return;
  //   // User userFromJson(String str) => User.fromJson(json.decode(str));
  //   sharedPreferences.setString(kUSER_INFO, user.to);
  // }

  // User? getUserLocal() {
  //   String jsonString = sharedPreferences.getString(kUSER_INFO) ?? '';
  //   if (jsonString.isNotEmpty) {
  //     return userFromJson(jsonString);
  //   }
  //   return null;
  // }
}
