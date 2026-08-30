import 'package:vnu_core/common/error/app_feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/cubit/auth_cubit.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/admission/controllers/applicant_auth_controller.dart';
import 'package:vnu_core/modules/inmapz/vcore_immap_view.dart';
import 'package:vnu_core/modules/idp_auth/services/idp_auth_flow.dart';
import 'package:vnu_core/modules/auth_mode/login_runtime_config.dart';
import 'package:vnu_core/services/app_config_service.dart';
import 'package:vnu_core/modules/motel/vcore_motel_webview.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_domain_dialog.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_forgot_pass_view_v2.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_textfield_widget.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/vnu_core.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/field/vnu_text_field.dart';

enum _LoginMode { student, applicant }

class VCoreLoginScreenV4 extends StatefulWidget {
  static const int serialTaps = 10;
  static const int tapDurationInMs = 7000;

  static int get timeNow => DateTime.now().millisecondsSinceEpoch;

  const VCoreLoginScreenV4({super.key, this.initialApplicantTab = false});

  final bool initialApplicantTab;

  @override
  State<VCoreLoginScreenV4> createState() => _VCoreLoginScreenV4State();
}

class _VCoreLoginScreenV4State extends State<VCoreLoginScreenV4> {
  final AuthCubit _authCubit = AuthCubit();

  final ApplicantAuthController _applicantAuthController =
      ApplicantAuthController();

  final TextEditingController _studentCodeController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final LocalAuthentication auth = LocalAuthentication();

  late BuildContext hubContext;

  _LoginMode _loginMode = _LoginMode.student;

  int startTap = VCoreLoginScreenV4.timeNow;
  int consecutiveTaps = 0;

  bool isDeviceSupportBio = false;
  bool isBioByFaceId = true;
  bool isEnableLoginBio = false;
  bool _obscurePassword = true;
  bool _idpLoading = false;
  bool _loginConfigLoading = true;
  LoginRuntimeConfig _loginRuntimeConfig = LoginRuntimeConfig.defaults;
  String? _loginConfigError;
  bool _loginConfigRefreshRunning = false;

  String userNameLocal = '';
  String passwordLocal = '';

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

    _loginMode = widget.initialApplicantTab
        ? _LoginMode.applicant
        : _LoginMode.student;

    if (kDebugMode) {
      if (ServicesUrl().baseUrl.contains('rteam.vn')) {
        _studentCodeController.text = '20032496';
        _passwordController.text = '1';
      } else {
        _studentCodeController.text = '21010442';
        _passwordController.text = 'VnuDuac@#2024';
      }
    }

    _checkBio();
    _loadLoginRuntimeConfig(showLoading: true, reason: 'initial');
  }

  Future<void> _loadLoginRuntimeConfig({
    required bool showLoading,
    required String reason,
  }) async {
    if (_loginConfigRefreshRunning) return;

    _loginConfigRefreshRunning = true;

    if (showLoading && mounted) {
      setState(() {
        _loginConfigLoading = true;
        _loginConfigError = null;
      });
    }

    try {
      final AppConfigService configService = AppConfigService();
      await configService.ensureLoaded(forceRefresh: true);
      if (!mounted) return;

      setState(() {
        _loginRuntimeConfig = configService.loginRuntimeConfig;
        _loginConfigLoading = false;
        _loginConfigError = configService.isLoadedSuccessfully
            ? null
            : (configService.lastLoadError ??
                'Không tải được cấu hình đăng nhập từ máy chủ.');
      });

      logInfo(
        '[LOGIN_CONFIG_RUNTIME] reason=$reason '
        'loaded=${configService.isLoadedSuccessfully} '
        'idpLogin=${_loginRuntimeConfig.idpLogin} '
        'qrEnabled=${_loginRuntimeConfig.qrEnabled}',
      );
    } catch (error, stackTrace) {
      if (showLoading && mounted) {
        setState(() {
          _loginConfigLoading = false;
          _loginConfigError = error.toString();
        });
      }
      logError(
        '[LOGIN_CONFIG_RUNTIME] reason=$reason error=$error\n$stackTrace',
      );
    } finally {
      _loginConfigRefreshRunning = false;
    }
  }

  @override
  void dispose() {
    _authCubit.close();

    _studentCodeController.dispose();
    _passwordController.dispose();

    _applicantAuthController.onClose();

    super.dispose();
  }

  Future<void> _checkBio() async {
    try {
      final String savedUsername =
          await DataRepository().getSecureSaveKey(kLoginUserName) ?? '';

      if (savedUsername.isNotEmpty) {
        _studentCodeController.text = savedUsername;
      }

      final String enabledBio =
          await DataRepository().getSecureSaveKey(kLoginEnableBio) ?? '';

      isEnableLoginBio = enabledBio.isNotEmpty;

      final List<BiometricType> availableBiometrics = await auth
          .getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        if (!mounted) return;

        setState(() {
          isDeviceSupportBio = false;
        });

        return;
      }

      final bool hasBio =
          availableBiometrics.contains(BiometricType.face) ||
          availableBiometrics.contains(BiometricType.fingerprint);

      if (!hasBio) {
        if (!mounted) return;

        setState(() {
          isDeviceSupportBio = false;
        });

        return;
      }

      userNameLocal =
          await DataRepository().getSecureSaveKey(kLoginUserName) ?? '';

      passwordLocal =
          await DataRepository().getSecureSaveKey(kLoginPassword) ?? '';

      if (!mounted) return;

      setState(() {
        isDeviceSupportBio = true;

        isBioByFaceId = availableBiometrics.contains(BiometricType.face);
      });
    } catch (error, stackTrace) {
      logError(
        'Kiểm tra sinh trắc học lỗi: '
        '$error\n$stackTrace',
      );
    }
  }

  void _selectLoginMode(_LoginMode mode) {
    if (_loginMode == mode) return;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _loginMode = mode;
    });
  }

  Future<bool> _verifyLoginMethodBeforeSubmit({
    required bool expectedIdpLogin,
  }) async {
    if (_loginConfigRefreshRunning) {
      snackBarWarning(
        'Đang kiểm tra phương thức đăng nhập. Vui lòng thử lại.',
      );
      return false;
    }

    _loginConfigRefreshRunning = true;
    try {
      final bool methodShownBeforeCheck = _loginRuntimeConfig.idpLogin;
      final LoginRuntimeConfig latest =
          await AppConfigService().fetchLatestLoginRuntimeConfig();
      if (!mounted) return false;

      final bool methodChanged =
          latest.idpLogin != methodShownBeforeCheck;
      final bool clickedFlowIsStillValid =
          latest.idpLogin == expectedIdpLogin;

      setState(() {
        _loginRuntimeConfig = latest;
        _loginConfigError = null;
        _loginConfigLoading = false;
      });

      if (methodChanged || !clickedFlowIsStillValid) {
        // The server is the source of truth. Never continue the old flow after
        // /api/config says the active authentication method has changed.
        _studentCodeController.clear();
        _passwordController.clear();
        userNameLocal = '';
        passwordLocal = '';

        snackBarWarning(
          latest.idpLogin
              ? 'Phương thức đăng nhập đã chuyển sang tài khoản VNU. '
                  'Màn hình đã được cập nhật, vui lòng đăng nhập lại.'
              : 'Phương thức đăng nhập đã chuyển sang mã sinh viên và mật khẩu. '
                  'Màn hình đã được cập nhật, vui lòng nhập lại thông tin.',
        );

        logInfo(
          '[LOGIN_METHOD_CHECK] changed=true '
          'shownIdp=$methodShownBeforeCheck '
          'clickedIdp=$expectedIdpLogin '
          'actualIdp=${latest.idpLogin}',
        );
        return false;
      }

      logInfo(
        '[LOGIN_METHOD_CHECK] changed=false actualIdp=${latest.idpLogin}',
      );
      return true;
    } catch (error, stackTrace) {
      logError(
        '[LOGIN_METHOD_CHECK] direct_check_failed=true error=$error\n$stackTrace',
      );

      // Do not continue with a stale cached method. Otherwise an IDP screen can
      // remain visible after the server has switched to password login and the
      // user only sees a downstream IdpAuthFlow error.
      if (mounted) {
        snackBarWarning(
          'Không kiểm tra được phương thức đăng nhập hiện tại. '
          'Vui lòng kiểm tra kết nối và thử lại.',
        );
      }
      return false;
    } finally {
      _loginConfigRefreshRunning = false;
    }
  }

  Future<void> _loginStudent() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final bool canContinue = await _verifyLoginMethodBeforeSubmit(
      expectedIdpLogin: false,
    );
    if (!canContinue || !mounted) return;

    _authCubit.loginMobile(
      _studentCodeController.text.trim(),
      _passwordController.text.trim(),
      '',
      '',
    );
  }

  Future<void> _loginWithIdp() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_idpLoading) return;

    final bool canContinue = await _verifyLoginMethodBeforeSubmit(
      expectedIdpLogin: true,
    );
    if (!canContinue || !mounted) return;

    setState(() => _idpLoading = true);

    try {
      final bool success = await IdpAuthFlow().login(context);

      if (!success) {
        return;
      }

      if (VnuCore().loginSucces != null) {
        VnuCore().loginSucces!(Globals().token);
      }
    } catch (error, stackTrace) {
      logError(
        'Đăng nhập tài khoản VNU lỗi: '
            '$error\n$stackTrace',
      );

      AppFeedback.showError(error);
    } finally {
      if (mounted) {
        setState(() => _idpLoading = false);
      }
    }
  }
  Future<void> _loginWithBio() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final bool canContinue = await _verifyLoginMethodBeforeSubmit(
      expectedIdpLogin: false,
    );
    if (!canContinue || !mounted) return;

    if (userNameLocal.isEmpty || passwordLocal.isEmpty) {
      snackBarWarning(
        'Bạn cần đăng nhập trước khi '
        'sử dụng tính năng này.',
      );
      return;
    }

    if (!isEnableLoginBio) {
      snackBarWarning(
        'Bạn cần đăng nhập và bật '
        'tính năng sinh trắc học '
        'trong mục Cá nhân.',
      );
      return;
    }

    try {
      final bool authenticated = await auth.authenticate(
        localizedReason: isBioByFaceId
            ? 'Quét khuôn mặt để đăng nhập'
            : 'Quét vân tay để đăng nhập',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!authenticated) return;

      _authCubit.loginMobile(userNameLocal, passwordLocal, '', '');
    } catch (error, stackTrace) {
      logError(
        'Đăng nhập sinh trắc học lỗi: '
        '$error\n$stackTrace',
      );
    }
  }

  void _handleSecretTap() {
    final int now = VCoreLoginScreenV4.timeNow;

    final bool exceededDuration =
        now - startTap > VCoreLoginScreenV4.tapDurationInMs;

    if (exceededDuration) {
      consecutiveTaps = 0;
      startTap = now;
    }

    consecutiveTaps++;

    if (consecutiveTaps != VCoreLoginScreenV4.serialTaps) {
      return;
    }

    consecutiveTaps = 0;
    startTap = now;

    showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return VcoreProfileDomainDialog(openTalker: _openTalker);
      },
    ).then((_) async {
      try {
        await VnuCore().addFirebaseTokenSwitchDomain(
          ServicesUrl().firebaseToken,
        );
      } catch (error, stackTrace) {
        logError(
          'Đồng bộ FCM khi đổi domain lỗi: '
          '$error\n$stackTrace',
        );
      }
    });
  }

  void _openTalker() {
    String password = '';

    final double buttonWidth = MediaQuery.of(context).size.width / 4;

    showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                VcoreProfileTextFieldWidget(
                  title: 'Mật khẩu',
                  hintText: 'Nhập mật khẩu',
                  value: password,
                  autoFocus: true,
                  onChange: (String text) {
                    password = text;
                  },
                  onSubmitted: (String text) {
                    password = text;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    WhiteButton(
                      width: buttonWidth,
                      title: 'Hủy',
                      action: () {
                        Navigator.pop(dialogContext);
                      },
                    ),
                    const SizedBox(width: 12),
                    BlueButton(
                      width: buttonWidth,
                      title: 'Xác nhận',
                      bgColor: AppColors.greenAccent,
                      action: () {
                        Navigator.pop(dialogContext);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (password.isEmpty) return;

      if (password == kLogPass) {
        Get.to(() => TalkerScreen(talker: Globals().talker));
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
        contextComplete: (BuildContext progressContext) {
          hubContext = progressContext;

          _applicantAuthController.context = progressContext;
        },
        child: BlocListener<AuthCubit, AuthState>(
          bloc: _authCubit,
          listener: (BuildContext context, AuthState state) {
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
            builder: (BuildContext context, AuthState state) {
              return Stack(
                children: <Widget>[
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _handleSecretTap,
                    child: const _LoginBackground(),
                  ),
                  SafeArea(
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final double screenWidth = constraints.maxWidth;

                            final double screenHeight = constraints.maxHeight;

                            final double horizontalPadding = screenWidth < 390
                                ? 22
                                : 28;

                            final double cardTop = screenHeight < 720
                                ? 145
                                : screenHeight < 800
                                ? 168
                                : 192;

                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                cardTop,
                                horizontalPadding,
                                24,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 430,
                                  ),
                                  child: _LoginCard(
                                    loginMode: _loginMode,
                                    onLoginModeChanged: _selectLoginMode,
                                    studentCodeController:
                                        _studentCodeController,
                                    passwordController: _passwordController,
                                    applicantController:
                                        _applicantAuthController,
                                    obscurePassword: _obscurePassword,
                                    isDeviceSupportBio: isDeviceSupportBio,
                                    isBioByFaceId: isBioByFaceId,
                                    onStudentLogin: _loginStudent,
                                    onApplicantLogin:
                                        _applicantAuthController.login,
                                    onBioLogin: _loginWithBio,
                                    idpLoading: _idpLoading,
                                    onIdpLogin: _loginWithIdp,
                                    loginRuntimeConfig: _loginRuntimeConfig,
                                    loginConfigLoading: _loginConfigLoading,
                                    loginConfigError: _loginConfigError,
                                    onTogglePassword: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
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
      children: <Widget>[
        Positioned.fill(
          child: Image.asset('assets/images/bg-login1.png', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(color: Colors.white.withOpacity(0.08)),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.loginMode,
    required this.onLoginModeChanged,
    required this.studentCodeController,
    required this.passwordController,
    required this.applicantController,
    required this.obscurePassword,
    required this.isDeviceSupportBio,
    required this.isBioByFaceId,
    required this.onStudentLogin,
    required this.onApplicantLogin,
    required this.onBioLogin,
    required this.idpLoading,
    required this.onIdpLogin,
    required this.loginRuntimeConfig,
    required this.loginConfigLoading,
    required this.loginConfigError,
    required this.onTogglePassword,
  });

  final _LoginMode loginMode;

  final ValueChanged<_LoginMode> onLoginModeChanged;

  final TextEditingController studentCodeController;

  final TextEditingController passwordController;

  final ApplicantAuthController applicantController;

  final bool obscurePassword;
  final bool isDeviceSupportBio;
  final bool isBioByFaceId;

  final VoidCallback onStudentLogin;
  final VoidCallback onApplicantLogin;
  final VoidCallback onBioLogin;
  final bool idpLoading;
  final VoidCallback onIdpLogin;
  final LoginRuntimeConfig loginRuntimeConfig;
  final bool loginConfigLoading;
  final String? loginConfigError;
  final VoidCallback onTogglePassword;

  bool get _isStudent => loginMode == _LoginMode.student;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.75), width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _LoginModeTabs(
            selectedMode: loginMode,
            onChanged: onLoginModeChanged,
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                ),
              );
            },
            child: _isStudent ? _buildStudentEntry() : _buildApplicantForm(),
          ),
          const SizedBox(height: 24),
          const _DividerText(),
          const SizedBox(height: 16),
          const _UtilityButtons(),
        ],
      ),
    );
  }

  Widget _buildStudentEntry() {
    if (loginConfigLoading) {
      return const Padding(
        key: ValueKey<String>('login-config-loading'),
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Đang chuẩn bị đăng nhập...',
              style: TextStyle(
                color: _VCoreLoginScreenV4State.textMuted,
                fontSize: AppFontSizes.small,
              ),
            ),
          ],
        ),
      );
    }

    final String configError = loginConfigError?.trim() ?? '';

    if (configError.isNotEmpty) {
      return Column(
        key: const ValueKey<String>('student-config-error'),
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD99C),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.cloud_off_rounded,
                  color: Color(0xFF9A6515),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Không thể kết nối đến hệ thống đăng nhập. '
                        'Vui lòng kiểm tra kết nối mạng và thử lại.',
                    style: TextStyle(
                      color: Color(0xFF805313),
                      fontSize: AppFontSizes.small,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      );
    }

    if (!loginRuntimeConfig.idpLogin) {
      return _buildStudentForm();
    }

    return Column(
      key: const ValueKey<String>('student-login-idp'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _VCoreLoginScreenV4State.green.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _VCoreLoginScreenV4State.green.withOpacity(0.14),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.account_circle_outlined,
                color: _VCoreLoginScreenV4State.green,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sử dụng tài khoản VNU để truy cập OneVNU.',
                  style: TextStyle(
                    color: _VCoreLoginScreenV4State.textDark,
                    fontSize: AppFontSizes.small,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _IdpLoginButton(
          isLoading: idpLoading,
          onTap: idpLoading ? null : onIdpLogin,
        ),
      ],
    );
  }
  Widget _buildStudentForm() {
    return Column(
      key: const ValueKey<String>('student-login-form'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _InputField(
          controller: studentCodeController,
          icon: Icons.person_outline_rounded,
          hintText: 'Mã sinh viên',
          textInputAction: TextInputAction.next,
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
          textInputAction: TextInputAction.done,
          onSubmitted: (String value) {
            onStudentLogin();
          },
        ),
        const SizedBox(height: 16),
        const _LoginOptionsRow(),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            Expanded(
              child: _MainLoginButton(
                title: 'Đăng nhập',
                onTap: onStudentLogin,
              ),
            ),
            if (isDeviceSupportBio) ...[
              const SizedBox(width: 12),
              _BioLoginButton(isBioByFaceId: isBioByFaceId, onTap: onBioLogin),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildApplicantForm() {
    return Column(
      key: const ValueKey<String>('applicant-login-form'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _InputField(
          controller: applicantController.cccdController,
          icon: Icons.badge_outlined,
          hintText: 'Số CCCD',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        _InputField(
          controller: applicantController.phoneNumberController,
          icon: Icons.phone_outlined,
          hintText: 'Số điện thoại đã đăng ký',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          onSubmitted: (String value) {
            onApplicantLogin();
          },
        ),
        const SizedBox(height: 14),
        const _ApplicantLoginNotice(),
        const SizedBox(height: 18),
        Obx(
          () => _MainLoginButton(
            title: 'Đăng nhập tân sinh viên',
            isLoading: applicantController.isLoading.value,
            onTap: applicantController.isLoading.value
                ? null
                : onApplicantLogin,
          ),
        ),
      ],
    );
  }
}

class _LoginModeTabs extends StatelessWidget {
  const _LoginModeTabs({required this.selectedMode, required this.onChanged});

  final _LoginMode selectedMode;
  final ValueChanged<_LoginMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _LoginModeTab(
            title: 'Sinh viên',
            icon: Icons.school_outlined,
            selected: selectedMode == _LoginMode.student,
            onTap: () {
              onChanged(_LoginMode.student);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _LoginModeTab(
            title: 'Tân sinh viên',
            icon: Icons.how_to_reg_outlined,
            selected: selectedMode == _LoginMode.applicant,
            onTap: () {
              onChanged(_LoginMode.applicant);
            },
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _LoginModeTab extends StatelessWidget {
  const _LoginModeTab({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.fontSize,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final double? fontSize;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[
                      _VCoreLoginScreenV4State.greenLight,
                      _VCoreLoginScreenV4State.greenDark,
                    ],
                  )
                : null,
            color: selected ? null : Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFFE1E8E4),
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: _VCoreLoginScreenV4State.green.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.035),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 21,
                color: selected
                    ? Colors.white
                    : _VCoreLoginScreenV4State.textMuted,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : _VCoreLoginScreenV4State.textMuted,
                    fontSize: fontSize ?? AppFontSizes.mediumSmall,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicantLoginNotice extends StatelessWidget {
  const _ApplicantLoginNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _VCoreLoginScreenV4State.green.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _VCoreLoginScreenV4State.green.withOpacity(0.14),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            color: _VCoreLoginScreenV4State.green,
            size: 19,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dành cho tân sinh viên '
              'có tên trong danh sách '
              'trúng tuyển. Sử dụng CCCD '
              'và số điện thoại đã đăng ký '
              'với nhà trường.',
              style: TextStyle(
                color: _VCoreLoginScreenV4State.textMuted,
                fontSize: AppFontSizes.small,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    // Do not wrap a floating outlined field with a second painted border.
    // The previous glass container crossed the floating label notch on some
    // Android font metrics and visually cut the top of the first label.
    return VnuTextField(
      controller: controller,
      label: hintText,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autocorrect: false,
      enableSuggestions: !obscureText,
      cursorColor: _VCoreLoginScreenV4State.green,
      style: const TextStyle(
        color: _VCoreLoginScreenV4State.textDark,
        fontSize: AppFontSizes.mediumLarge,
        fontWeight: FontWeight.w500,
      ),
      leading: Icon(
        icon,
        color: _VCoreLoginScreenV4State.green,
        size: 24,
      ),
      trailing: suffixIcon == null
          ? null
          : InkWell(
              onTap: onSuffixTap,
              borderRadius: BorderRadius.circular(24),
              child: Icon(
                suffixIcon,
                color: _VCoreLoginScreenV4State.textMuted,
                size: 22,
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
      constraints: BoxConstraints(minHeight: height),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
        boxShadow: <BoxShadow>[
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
    return Row(
      children: <Widget>[
        const Icon(
          Icons.check_circle,
          color: _VCoreLoginScreenV4State.green,
          size: 22,
        ),
        const SizedBox(width: 5),
        const Expanded(
          child: Text(
            'Ghi nhớ đăng nhập',
            style: TextStyle(
              color: _VCoreLoginScreenV4State.textMuted,
              fontSize: AppFontSizes.small,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Get.to(() => const VcoreProfileForgotPassViewV2.loginSupport());
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              'Quên mật khẩu?',
              style: TextStyle(
                color: _VCoreLoginScreenV4State.green,
                fontSize: AppFontSizes.mediumSmall,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MainLoginButton extends StatelessWidget {
  const _MainLoginButton({
    required this.title,
    required this.onTap,
    this.isLoading = false,
  });

  final String title;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: onTap == null
                  ? <Color>[
                      _VCoreLoginScreenV4State.greenLight.withOpacity(0.55),
                      _VCoreLoginScreenV4State.greenDark.withOpacity(0.55),
                    ]
                  : const <Color>[
                      _VCoreLoginScreenV4State.greenLight,
                      _VCoreLoginScreenV4State.greenDark,
                    ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _VCoreLoginScreenV4State.green.withOpacity(0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    title,
                    style: const TextStyle(
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
  const _BioLoginButton({required this.isBioByFaceId, required this.onTap});

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
            color: _VCoreLoginScreenV4State.greenDark,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _VCoreLoginScreenV4State.green.withOpacity(0.22),
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

class _IdpDividerText extends StatelessWidget {
  const _IdpDividerText();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(
          child: Divider(color: _VCoreLoginScreenV4State.border, thickness: 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Hoặc đăng nhập tập trung',
            style: TextStyle(
              color: _VCoreLoginScreenV4State.textMuted,
              fontSize: AppFontSizes.mediumSmall,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: _VCoreLoginScreenV4State.border, thickness: 1),
        ),
      ],
    );
  }
}

class _IdpLoginButton extends StatelessWidget {
  const _IdpLoginButton({
    required this.onTap,
    required this.isLoading,
  });

  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _VCoreLoginScreenV4State.green.withOpacity(0.34),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (isLoading)
                const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: _VCoreLoginScreenV4State.green,
                  ),
                )
              else
                const Icon(
                  Icons.account_balance_rounded,
                  color: _VCoreLoginScreenV4State.green,
                  size: 23,
                ),
              const SizedBox(width: 10),
              const Text(
                'Đăng nhập',
                style: TextStyle(
                  color: _VCoreLoginScreenV4State.textDark,
                  fontSize: AppFontSizes.mediumLarge,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.open_in_browser_rounded,
                color: _VCoreLoginScreenV4State.textMuted,
                size: 18,
              ),
            ],
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
      children: <Widget>[
        Expanded(
          child: Divider(color: _VCoreLoginScreenV4State.border, thickness: 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Các tiện ích khác',
            style: TextStyle(
              color: _VCoreLoginScreenV4State.textMuted,
              fontSize: AppFontSizes.mediumSmall,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: _VCoreLoginScreenV4State.border, thickness: 1),
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
      children: <Widget>[
        Expanded(
          child: _UtilityButton(
            icon: Icons.home_work_outlined,
            title: 'Phòng trọ',
            onTap: openMotelWebView,
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
                'https://www.facebook.com/'
                'supportdangkyhocvnu',
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
            children: <Widget>[
              Icon(icon, color: _VCoreLoginScreenV4State.green, size: 22),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _VCoreLoginScreenV4State.textDark,
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
