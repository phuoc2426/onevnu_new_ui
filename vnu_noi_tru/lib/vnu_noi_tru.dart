library vnu_noi_tru;

export 'screens/dormitory_registration/dr_my_registration_screen.dart';
export 'screens/dormitory_registration/dr_wizard_flow.dart';


import 'package:vnu_core/common/log.dart';

/// A Calculator.
///
class VNUNoiTru {
  String? token;

  VNUNoiTru._internal();

  static final VNUNoiTru _singleton = VNUNoiTru._internal();

  factory VNUNoiTru() {
    return _singleton;
  }

  void configAcessToken(String accessToken) {
    token = accessToken;
  }

  void handleNotificationTapped(Map<String, dynamic>? message) {
    logSuccess('//// handle Notification $message');
  }
}
