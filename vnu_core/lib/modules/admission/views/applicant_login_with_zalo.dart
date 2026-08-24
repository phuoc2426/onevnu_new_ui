import 'package:flutter/material.dart';
import 'package:vnu_core/screens/vcore_login_screen_v4.dart';
import 'package:vnu_core/widgets/zalo_chat_bubble.dart';

/// Wrapper dành riêng cho tab đăng nhập Applicant bằng CCCD.
///
/// Dùng V4 nhưng vẫn giữ nguyên luồng Applicant cũ, nhờ đó giảm xung đột với luồng
/// đăng nhập sinh viên hiện có.
class ApplicantLoginWithZalo extends StatelessWidget {
  const ApplicantLoginWithZalo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: <Widget>[
        VCoreLoginScreenV4(initialApplicantTab: true),
        ZaloChatBubble(
          edgeInsets: EdgeInsets.fromLTRB(12, 12, 16, 24),
        ),
      ],
    );
  }
}
