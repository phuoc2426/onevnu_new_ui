import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcoreProfileSetupBioView extends StatefulWidget {
  const VcoreProfileSetupBioView({super.key});

  @override
  State<VcoreProfileSetupBioView> createState() =>
      _VcoreProfileSetupBioViewState();
}

class _VcoreProfileSetupBioViewState extends State<VcoreProfileSetupBioView> {
  bool isEnableLogin = false;

  final LocalAuthentication auth = LocalAuthentication();
  var isDeviceSupportBio = false;
  var isBioByFaceId = true;

  @override
  void initState() {
    super.initState();
    _checkBio();
  }

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: isBioByFaceId ? 'Cài đặt khuôn mặt' : 'Cài đặt vân tay',
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Text(
              isBioByFaceId
                  ? 'Đăng nhập bằng khuôn mặt'
                  : 'Đăng nhập bằng vân tay',
              style: TextStyles.medium.copyWith(fontSize: 16),
            ),
            const Spacer(),
            Switch(
              // This bool value toggles the switch.
              value: isEnableLogin,
              activeColor: Colors.green,
              onChanged: (bool value) {
                // This is called when the user toggles the switch.
                _changeLogin(value);
              },
            )
          ],
        ),
      ),
    );
  }

  _checkBio() async {
    isEnableLogin =
        (await DataRepository().getSecureSaveKey(kLoginEnableBio) ?? '')
            .isNotEmpty;

    final List<BiometricType> availableBiometrics =
        await auth.getAvailableBiometrics();

    if (availableBiometrics.isEmpty) {
      // NO biometrics are enrolled.
      isDeviceSupportBio = false;
      snackBarError('Thiết bị không hỗ trợ xác thực khuôn mặt hoặc vân tay.');
      return;
    }

    if (availableBiometrics.contains(BiometricType.strong) ||
        availableBiometrics.contains(BiometricType.face) ||
        availableBiometrics.contains(BiometricType.fingerprint)) {
      // Specific types of biometrics are available.
      // Use checks like this with caution!
      setState(() {
        isDeviceSupportBio = true;
        isBioByFaceId = availableBiometrics.contains(BiometricType.face);
      });
    }
  }

  _changeLogin(bool active) async {
    var response = await auth.authenticate(
      localizedReason:
          'Scan your fingerprint (or face or whatever) to authenticate',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );

    if (response) {
      if (active) {
        DataRepository().saveSecureKey(kLoginEnableBio, 'true');
      } else {
        DataRepository().deleteSecureKey(kLoginEnableBio);
      }
      setState(() {
        isEnableLogin = active;
      });
    }
  }
}
