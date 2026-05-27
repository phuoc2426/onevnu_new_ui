import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_textfield_widget.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/vnu_core.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_noi_tru/repository/noitru_repository.dart';

class VcoreProfileDomainDialog extends HookWidget {
  final VoidCallback openTalker;
  const VcoreProfileDomainDialog({super.key, required this.openTalker});

  @override
  Widget build(BuildContext context) {
    final baseUrl = useState(ServicesUrl().baseUrl);
    final buttonWidth = MediaQuery.of(context).size.width / 4;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VcoreProfileTextFieldWidget(
              title: 'Domain',
              hintText: 'Nhập domain',
              value: baseUrl.value,
              onChange: (text) {
                baseUrl.value = text;
              },
              onSubmitted: (text) {
                baseUrl.value = text;
              },
            ),
            spaceHeight(10),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openTalker();
              },
              child: Text(
                'Open Talker Api',
                style: AppTheme.body2.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (kDebugMode) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      baseUrl.value = 'https://onevnu-test-mobileapi.rteam.vn/';
                    },
                    child: Text(
                      'rTeam Api',
                      style: AppTheme.body2.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      baseUrl.value = 'https://onevnu-mobile-api.vnu.edu.vn/';
                    },
                    child: Text(
                      'VNU Api',
                      style: AppTheme.body2.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WhiteButton(
                  width: buttonWidth,
                  title: "Hủy",
                  action: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 12),
                BlueButton(
                  width: buttonWidth,
                  title: "Xác nhận",
                  bgColor: AppColors.greenAccent,
                  action: () {
                    Navigator.pop(context);
                    ServicesUrl().baseUrl = baseUrl.value;
                    ApiRepository().setDomain(baseUrl.value);
                    NoiTruRepository().setDomain(baseUrl.value);
                    Globals().clearSession(deleteUserLogin: false);
                    VnuCore().gotoLogin();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
