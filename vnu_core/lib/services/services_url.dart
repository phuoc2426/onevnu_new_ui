import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ServicesUrl {
  static final ServicesUrl _singleton = ServicesUrl._internal();

  factory ServicesUrl() {
    return _singleton;
  }

  ServicesUrl._internal();

  late SharedPreferences _prefs;

  Future init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? get firebaseToken => _prefs.getString("firebase_token");

  set firebaseToken(String? token) {
    _prefs.setString("firebase_token", token ?? '');
  }

  String get baseUrl {
    final String domain =
        _prefs.getString("domain") ?? "https://onevnu-mobile-api.vnu.edu.vn";
    // _prefs.getString("domain") ?? "http://10.0.2.2:8083";
    // _prefs.getString("domain") ?? "http://10.241.99.23:8082";
    // _prefs.getString("domain") ?? "http://112.137.143.72:8082";

    //ip máy tính
    // _prefs.getString("domain") ?? "http://10.15.194.82:8083";
    // _prefs.getString("domain") ?? "http://192.168.1.47:8083";

    return domain.endsWith("/") ? domain : "$domain/";
  }

  String get baseUrlFileDownload {
    final String domain = _prefs.getString("domainFileDownload") ?? baseUrl;
    return "${domain.endsWith("/") ? domain : "$domain/"}api/file/download/";
  }

  String get baseUrlImage {
    return _prefs.getString("domainFileDownload") ?? baseUrl;
  }

  set baseUrlFileDownload(String? domain) {
    if (domain != null && domain.isNotEmpty) {
      _prefs.setString("domainFileDownload", domain);
    } else {
      _prefs.setString("domainFileDownload", baseUrl);
    }
  }

  set baseUrl(String domain) {
    _prefs.setString("domain", domain);
  }

  set topics(List<String> topics) {
    _prefs.setString("topics", jsonEncode(topics));
  }

  List<String> get topics {
    final String? tp = _prefs.getString("topics");
    if (tp == null || tp.isEmpty) {
      return [];
    }

    return json.decode(tp).cast<String>();
  }

  final String authenticate = 'api/auth/signin';
}
