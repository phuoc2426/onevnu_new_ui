import 'package:flutter/material.dart';
import 'package:vnu_core/screens/vcore_login_screen_v4.dart';

/// Compatibility route for older code that still opens the former CCCD screen.
///
/// Applicant authentication is owned by VCoreLoginScreenV4 / ApplicantAuthController.
/// Do not create a second Applicant API service here.
@Deprecated('Use VCoreLoginScreenV4(initialApplicantTab: true) instead.')
class CccdRegistrationScreen extends StatelessWidget {
  const CccdRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VCoreLoginScreenV4(initialApplicantTab: true);
  }
}
