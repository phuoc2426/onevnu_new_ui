import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/cubit/auth_cubit.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/inmapz/vcore_immap_view.dart';
import 'package:vnu_core/modules/motel/views/vcore_motel_view.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_domain_dialog.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_textfield_widget.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/vnu_core.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

import '../constants/config.dart';
import 'package:vnu_core/common/app_text_styles.dart';

class VCoreLoginScreenV3 extends StatefulWidget {
  static const int serialTaps = 10;
  static const int tapDurationInMs = 7000;

  static int get timeNow => DateTime.now().millisecondsSinceEpoch;

  const VCoreLoginScreenV3({super.key});

  @override
  State<VCoreLoginScreenV3> createState() => _VCoreLoginScreenV3State();
}

class _VCoreLoginScreenV3State extends State<VCoreLoginScreenV3> {
  final AuthCubit _authCubit = AuthCubit();

  late BuildContext hubContext;

  final TextEditingController _studentCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final LocalAuthentication auth = LocalAuthentication();

  var startTap = VCoreLoginScreenV3.timeNow;
  var consecutiveTaps = 0;

  var isDeviceSupportBio = false;
  var isBioByFaceId = true;
  var isEnableLoginBio = false;

  var userNameLocal = '';
  var passwordLocal = '';

  bool _obscurePassword = true;

  static const Color green = Color(0xFF07964B);
  static const Color greenLight = Color(0xFF18C96A);
  static const Color greenDark = Color(0xFF008A43);

  static const Color textDark = Color(0xFF101936);
  static const Color textMuted = Color(0xFF7B849A);
  static const Color hint = Color(0xFF9AA2B7);
  static const Color border = Color(0xFFE3E7EE);

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      if (ServicesUrl().baseUrl.contains('rteam.vn')) {
        _studentCodeController.text = '20032496';
        _passwordController.text = '1';
      } else {
        _studentCodeController.text = '21010442';
        _passwordController.text = 'VnuDuac@#2024';
      }
    }

    try {
      _checkBio();
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  void dispose() {
    _authCubit.close();
    _studentCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBio() async {
    final String name =
        await DataRepository().getSecureSaveKey(kLoginUserName) ?? '';

    if (name.isNotEmpty) {
      _studentCodeController.text = name;
    }

    try {
      isEnableLoginBio =
          (await DataRepository().getSecureSaveKey(kLoginEnableBio) ?? '')
              .isNotEmpty;
    } catch (e) {
      logError(e.toString());
    }

    final List<BiometricType> availableBiometrics =
    await auth.getAvailableBiometrics();

    if (availableBiometrics.isEmpty) {
      isDeviceSupportBio = false;
      return;
    }

    final bool hasBio = availableBiometrics.contains(BiometricType.face) ||
        availableBiometrics.contains(BiometricType.fingerprint);

    if (hasBio) {
      userNameLocal =
          await DataRepository().getSecureSaveKey(kLoginUserName) ?? '';
      passwordLocal =
          await DataRepository().getSecureSaveKey(kLoginPassword) ?? '';

      if (!mounted) return;

      setState(() {
        isDeviceSupportBio = true;
        isBioByFaceId = availableBiometrics.contains(BiometricType.face);
      });
    }
  }

  void _login() {
    FocusManager.instance.primaryFocus?.unfocus();

    _authCubit.loginMobile(
      _studentCodeController.text.trim(),
      _passwordController.text.trim(),
      '',
      '',
    );
  }

  Future<void> _loginWithBio() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (userNameLocal.isEmpty || passwordLocal.isEmpty) {
      snackBarWarning('Bạn cần đăng nhập trước khi sử dụng tính năng này.');
      return;
    }

    if (!isEnableLoginBio) {
      snackBarWarning('Bạn cần đăng nhập và bật tính năng trong mục Cá nhân');
      return;
    }

    try {
      final response = await auth.authenticate(
        localizedReason: isBioByFaceId
            ? 'Quét khuôn mặt để đăng nhập'
            : 'Quét vân tay để đăng nhập',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (response) {
        _authCubit.loginMobile(
          userNameLocal,
          passwordLocal,
          '',
          '',
        );
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  void _handleSecretTap() {
    final now = VCoreLoginScreenV3.timeNow;
    final userExceededTapDuration =
        now - startTap > VCoreLoginScreenV3.tapDurationInMs;

    if (userExceededTapDuration) {
      consecutiveTaps = 0;
      startTap = now;
    }

    consecutiveTaps++;

    if (consecutiveTaps == VCoreLoginScreenV3.serialTaps) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => VcoreProfileDomainDialog(
          openTalker: () {
            _openTalker();
          },
        ),
      ).then((v) async {
        await VnuCore().addFirebaseTokenSwitchDomain(
          ServicesUrl().firebaseToken,
        );
      });
    }
  }

  void _openTalker() {
    var password = '';
    final buttonWidth = MediaQuery.of(context).size.width / 4;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
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
                  title: 'Mật khẩu',
                  hintText: 'Nhập mật khẩu',
                  value: password,
                  autoFocus: true,
                  onChange: (text) {
                    password = text;
                  },
                  onSubmitted: (text) {
                    password = text;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    WhiteButton(
                      width: buttonWidth,
                      title: 'Hủy',
                      action: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 12),
                    BlueButton(
                      width: buttonWidth,
                      title: 'Xác nhận',
                      bgColor: AppColors.greenAccent,
                      action: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((v) async {
      if (password.isEmpty) {
        return;
      }

      if (password == kLogPass) {
        Get.to(
              () => TalkerScreen(talker: Globals().talker),
        );
      } else {
        snackBarError('Mật khẩu không đúng.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ProgressHubWidget(
        contextComplete: (ctx) {
          hubContext = ctx;
        },
        child: BlocListener<AuthCubit, AuthState>(
          bloc: _authCubit,
          listener: (context, state) {
            if (state is AuthError) {
              snackBarError(state.message);
            }

            if (state is AuthShowHub) {
              Utils.showProgress(hubContext);
            }

            if (state is AuthDismissHub) {
              Utils.dismissProgress(hubContext);
            }
          },
          child: BlocBuilder<AuthCubit, AuthState>(
            bloc: _authCubit,
            builder: (context, state) {
              return Stack(
                children: [
                  const _LoginBackground(),

                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double screenWidth = constraints.maxWidth;
                        final double screenHeight = constraints.maxHeight;

                        final double horizontalPadding =
                        screenWidth < 390 ? 24 : 30;

                        // Chỉnh card đăng nhập lên/xuống ở đây.
                        // Tăng số này nếu muốn div đăng nhập xuống thấp hơn.
                        final double cardTop = screenHeight < 720
                            ? 155
                            : screenHeight < 800
                            ? 175
                            : 200;

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            cardTop,
                            horizontalPadding,
                            24,
                          ),
                          child: _LoginCard(
                            studentCodeController: _studentCodeController,
                            passwordController: _passwordController,
                            obscurePassword: _obscurePassword,
                            isDeviceSupportBio: isDeviceSupportBio,
                            isBioByFaceId: isBioByFaceId,
                            onLogin: _login,
                            onBioLogin: _loginWithBio,
                            onTogglePassword: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  Positioned(
                    top: 105,
                    left: 24,
                    right: 24,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _handleSecretTap,
                      child: const _HeaderText(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/bg-login1.png',
            fit: BoxFit.cover,

            // Nếu ảnh nằm trong package vnu_core thì mở dòng dưới:
            // package: 'vnu_core',
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Chào mừng \n'),
              TextSpan(
                text: 'bạn trở lại!',
                style: TextStyle(
                  color: _VCoreLoginScreenV3State.green,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _VCoreLoginScreenV3State.textDark,
            fontSize: AppFontSizes.font28,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),


        Text(
          'OneVNU – Kết nối mọi tiện ích sinh viên',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _VCoreLoginScreenV3State.textMuted,
            fontSize: AppFontSizes.font11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.studentCodeController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isDeviceSupportBio,
    required this.isBioByFaceId,
    required this.onLogin,
    required this.onBioLogin,
    required this.onTogglePassword,
  });

  final TextEditingController studentCodeController;
  final TextEditingController passwordController;

  final bool obscurePassword;
  final bool isDeviceSupportBio;
  final bool isBioByFaceId;

  final VoidCallback onLogin;
  final VoidCallback onBioLogin;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.75),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InputField(
            controller: studentCodeController,
            icon: Icons.person_outline_rounded,
            hintText: 'Mã sinh viên',
          ),

          const SizedBox(height: 12),

          _InputField(
            controller: passwordController,
            icon: Icons.lock_outline_rounded,
            hintText: 'Mật khẩu',
            obscureText: obscurePassword,
            suffixIcon: obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            onSuffixTap: onTogglePassword,
          ),

          const SizedBox(height: 16),

          const _LoginOptionsRow(),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _MainLoginButton(onTap: onLogin),
              ),
              if (isDeviceSupportBio) ...[
                const SizedBox(width: 12),
                _BioLoginButton(
                  isBioByFaceId: isBioByFaceId,
                  onTap: onBioLogin,
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          const _DividerText(),

          const SizedBox(height: 16),

          const _UtilityButtons(),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.icon,
    required this.hintText,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return _GlassLikeBox(
      height: 56,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: _VCoreLoginScreenV3State.textDark,
          fontSize: AppFontSizes.mediumLarge,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: _VCoreLoginScreenV3State.hint,
            fontSize: AppFontSizes.mediumLarge,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: _VCoreLoginScreenV3State.green,
            size: 24,
          ),
          suffixIcon: suffixIcon == null
              ? null
              : InkWell(
            onTap: onSuffixTap,
            borderRadius: BorderRadius.circular(24),
            child: Icon(
              suffixIcon,
              color: _VCoreLoginScreenV3State.textMuted,
              size: 22,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 17,
          ),
        ),
      ),
    );
  }
}

class _GlassLikeBox extends StatelessWidget {
  const _GlassLikeBox({
    required this.child,
    required this.height,
    this.borderRadius = 16,
  });

  final Widget child;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LoginOptionsRow extends StatelessWidget {
  const _LoginOptionsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(
          Icons.check_circle,
          color: _VCoreLoginScreenV3State.green,
          size: 22,
        ),
        SizedBox(width: 5),
        Expanded(
          child: Text(
            'Ghi nhớ đăng nhập',
            style: TextStyle(
              color: _VCoreLoginScreenV3State.textMuted,
              fontSize: AppFontSizes.small,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 8),
        Text(
          'Quên mật khẩu?',
          style: TextStyle(
            color: _VCoreLoginScreenV3State.green,
            fontSize: AppFontSizes.mediumSmall,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MainLoginButton extends StatelessWidget {
  const _MainLoginButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                _VCoreLoginScreenV3State.greenLight,
                _VCoreLoginScreenV3State.greenDark,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _VCoreLoginScreenV3State.green.withOpacity(0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Đăng nhập',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppFontSizes.large,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BioLoginButton extends StatelessWidget {
  const _BioLoginButton({
    required this.isBioByFaceId,
    required this.onTap,
  });

  final bool isBioByFaceId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: _VCoreLoginScreenV3State.greenDark,
            boxShadow: [
              BoxShadow(
                color: _VCoreLoginScreenV3State.green.withOpacity(0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(
              isBioByFaceId
                  ? 'assets/images/ic_faceid.svg'
                  : 'assets/images/ic_touch.svg',
              package: kPackageName,
              color: Colors.white,
              width: 25,
              height: 25,
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerText extends StatelessWidget {
  const _DividerText();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Divider(
            color: _VCoreLoginScreenV3State.border,
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Các tiện ích khác',
            style: TextStyle(
              color: _VCoreLoginScreenV3State.textMuted,
              fontSize: AppFontSizes.mediumSmall,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: _VCoreLoginScreenV3State.border,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _UtilityButtons extends StatelessWidget {
  const _UtilityButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _UtilityButton(
            icon: Icons.home_work_outlined,
            title: 'Phòng trọ',
            onTap: () {
              Get.to(() => const VcoreMotelView());
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _UtilityButton(
            icon: Icons.map_outlined,
            title: 'Bản đồ',
            onTap: () {
              Get.to(() => const VcoreImmapView());
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _UtilityButton(
            icon: Icons.support_agent_outlined,
            title: 'Hỗ trợ',
            onTap: () {
              Utils.openUrl(
                'https://www.facebook.com/supportdangkyhocvnu',
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UtilityButton extends StatelessWidget {
  const _UtilityButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _GlassLikeBox(
          height: 62,
          borderRadius: 16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: _VCoreLoginScreenV3State.green,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _VCoreLoginScreenV3State.textDark,
                  fontSize: AppFontSizes.small,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}