import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/cubit/auth_cubit.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/inmapz/vcore_immap_view.dart';
import 'package:vnu_core/modules/motel/views/vcore_motel_view.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_create_view.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_domain_dialog.dart';
import 'package:vnu_core/modules/profile/views/widget/vcore_profile_textfield_widget.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/vnu_core.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

import '../constants/config.dart';

class VCoreLoginScreen extends StatefulWidget {
  static const int serialTaps = 10;
  static const int tapDurationInMs = 7000;

  static int get timeNow => DateTime.now().millisecondsSinceEpoch;

  const VCoreLoginScreen({super.key});

  @override
  State<VCoreLoginScreen> createState() => _VCoreLoginScreenState();
}

class _VCoreLoginScreenState extends State<VCoreLoginScreen> {
  final AuthCubit _authCubit = AuthCubit();
  late BuildContext hubContext;
  var startTap = VCoreLoginScreen.timeNow;

  var consecutiveTaps = 0;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _paswordController = TextEditingController();
  List<String> listLogo = [
    'assets/images/ic_logo_ngoai_ngu.png',
    'assets/images/ic_logo_ueb.png',
    'assets/images/ic_logo_khoa_hoc_tu_nhien.png',
    'assets/images/ic_logo_cong_nghe.png',
    'assets/images/ic_logo_dai_hoc_1.png',
    'assets/images/ic_logo_dai_hoc_2.png'
  ];

  final LocalAuthentication auth = LocalAuthentication();
  var isDeviceSupportBio = false;
  var isBioByFaceId = true;
  var isEnableLoginBio = false;

  var userNameLocal = '';
  var passwordLocal = '';

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      if (ServicesUrl().baseUrl.contains('rteam.vn')) {
        //Dev
        _emailController.text =
            '20032496'; // '21030408'; // '23001189'; //'21030408';
        _paswordController.text = '1';
      } else {
        _emailController.text = '21010442';
        _paswordController.text = 'VnuDuac@#2024'; //'1';
      }
    }

    //Get saved user
    try {
      _checkBio();
    } catch (e) {
      logError(e.toString());
    }
  }

  _checkBio() async {
    String name = await DataRepository().getSecureSaveKey(kLoginUserName) ?? '';
    if (name.isNotEmpty) {
      _emailController.text = name;
    }

    try {
      isEnableLoginBio =
          (await DataRepository().getSecureSaveKey(kLoginEnableBio) ?? '')
              .isNotEmpty;
    } catch (e) {}

    final List<BiometricType> availableBiometrics =
        await auth.getAvailableBiometrics();

    if (availableBiometrics.isEmpty) {
      // NO biometrics are enrolled.
      isDeviceSupportBio = false;
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

      userNameLocal =
          await DataRepository().getSecureSaveKey(kLoginUserName) ?? '';
      passwordLocal =
          await DataRepository().getSecureSaveKey(kLoginPassword) ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff33AD4A),
      body: SafeArea(
        child: ProgressHubWidget(
          contextComplete: (ctx) {
            hubContext = ctx;
          },
          child: SingleChildScrollView(
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
                  if (state is AuthLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Stack(
                    // fit: StackFit.loose,
                    children: [
                      /// bg header
                      Positioned(
                        child: AspectRatio(
                          aspectRatio: 375 / 172,
                          child: SvgPicture.asset(
                            'assets/images/bg_header.svg',
                            package: kPackageName,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // body login
                      Container(
                        margin: const EdgeInsets.only(top: 147),
                        padding: const EdgeInsets.only(left: 24, right: 24),
                        width: double.infinity,
                        // height: MediaQuery.of(context).size.height - 147,
                        decoration: const BoxDecoration(
                          color: Color(0xffF6F9FE),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Logo
                            Container(
                              margin: const EdgeInsets.only(
                                  top: 36, bottom: 40, left: 30, right: 30),
                              child: GestureDetector(
                                onTap: () {
                                  final now = VCoreLoginScreen.timeNow;
                                  final userExceededTapDuration =
                                      now - startTap >
                                          VCoreLoginScreen.tapDurationInMs;

                                  if (userExceededTapDuration) {
                                    consecutiveTaps = 0;
                                    startTap = now;
                                  }

                                  consecutiveTaps++;

                                  if (consecutiveTaps ==
                                      VCoreLoginScreen.serialTaps) {
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) =>
                                          VcoreProfileDomainDialog(
                                        openTalker: () {
                                          _openTalker();
                                        },
                                      ),
                                    ).then((v) async {
                                      await VnuCore()
                                          .addFirebaseTokenSwitchDomain(
                                              ServicesUrl().firebaseToken);
                                    });
                                  }
                                },
                                child: Image.asset(
                                  'assets/images/ic_logo_vnu_full.png',
                                  package: 'vnu_noi_tru',
                                ),
                              ),
                              //     SvgPicture.asset(
                              //   'assets/images/ic_logo_vnu.svg',
                              //   package: kPackageName,
                              // )
                            ),

                            // Email
                            _formEmail(),
                            _formPassword(),
                            // GestureDetector(
                            //   onTap: () {
                            //     print('Quên mật khẩu');
                            //   },
                            //   child: const Padding(
                            //     padding: EdgeInsets.only(top: 8.0, bottom: 24),
                            //     child: Align(
                            //       alignment: Alignment.centerRight,
                            //       child: Text(
                            //         'Quên mật khẩu',
                            //         style: TextStyle(
                            //           color: Color(0xff466FFF),
                            //           decoration: TextDecoration.underline,
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            // ),
                            //
                            const SizedBox(
                              height: 40,
                            ),
                            // -- Login - van tay
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () {
                                    debugPrint('Login');
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    _authCubit.loginMobile(
                                        _emailController.text,
                                        _paswordController.text,
                                        '',
                                        '');
                                  },
                                  child: Container(
                                    height: 48,
                                    width: 230,
                                    decoration: BoxDecoration(
                                        color: const Color(0xff007F3E),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Center(
                                        child: Text(
                                      'Đăng nhập',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    )),
                                  ),
                                ),

                                // -- Van tay
                                //van tay
                                if (isDeviceSupportBio)
                                  Container(
                                    margin: const EdgeInsets.only(left: 20),
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xff007F3E),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: InkWell(
                                      onTap: () async {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        if (userNameLocal.isEmpty ||
                                            passwordLocal.isEmpty) {
                                          snackBarWarning(
                                              'Bạn cần đăng nhập trước khi sử dụng tính năng này.');
                                          return;
                                        }

                                        if (!isEnableLoginBio) {
                                          snackBarWarning(
                                              'Bạn cần đăng nhập và bật tính năng trong mục Cá nhân');
                                          return;
                                        }
                                        try {
                                          var response =
                                              await auth.authenticate(
                                            localizedReason:
                                                'Scan your fingerprint (or face or whatever) to authenticate',
                                            options: const AuthenticationOptions(
                                              stickyAuth: true,
                                              biometricOnly: true,
                                            ),
                                          );
                                          if (response) {
                                            _authCubit.loginMobile(
                                                userNameLocal,
                                                passwordLocal,
                                                '',
                                                '');
                                          }
                                          print(response);
                                        } catch (e) {
                                          logError(e.toString());
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            isBioByFaceId
                                                ? 'assets/images/ic_faceid.svg'
                                                : 'assets/images/ic_touch.svg',
                                            package: kPackageName,
                                            color: Colors.white,
                                          ),
                                          // const SizedBox(
                                          //   width: 8,
                                          // ),
                                          // Text(isBioByFaceId
                                          //     ? 'Đăng nhập bằng khuôn mặt'
                                          //     : 'Đăng nhập bằng vân tay')
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(
                              height: 32,
                            ),

                            spaceHeight(20),

                            //Map - nha tro
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Get.to(() => const VcoreMotelView());
                                  },
                                  child: Column(
                                    children: [
                                      svgAsset(
                                          'assets/images/ic_login_motel.svg'),
                                      spaceHeight(10),
                                      Text(
                                        'Phòng trọ',
                                        style: TextStyles.semiBold,
                                      ),
                                    ],
                                  ),
                                ),
                                spaceWidth(50),
                                InkWell(
                                  onTap: () {
                                    Get.to(() => const VcoreImmapView());
                                  },
                                  child: Column(
                                    children: [
                                      svgAsset(
                                          'assets/images/ic_login_map.svg'),
                                      spaceHeight(10),
                                      Text(
                                        'Xem bản đồ',
                                        style: TextStyles.semiBold,
                                      ),
                                    ],
                                  ),
                                ),
                                spaceWidth(50),
                                InkWell(
                                  onTap: () {
                                    Utils.openUrl(
                                        'https://www.facebook.com/supportdangkyhocvnu');
                                  },
                                  child: Column(
                                    children: [
                                      svgAsset('assets/images/ic_facebook.svg'),
                                      spaceHeight(10),
                                      Text(
                                        'Hỗ trợ',
                                        style: TextStyles.semiBold,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            spaceHeight(60),

                            //truong thanh vien
                            // Container(
                            //   margin: const EdgeInsets.only(top: 70),
                            //   child: Column(
                            //     children: [
                            //       const Padding(
                            //         padding: EdgeInsets.all(8.0),
                            //         child: Text('Các trường thành viên'),
                            //       ),
                            //       SizedBox(
                            //         height: 40,
                            //         width: double.infinity,
                            //         child: ListView.builder(
                            //             itemCount: listLogo.length,
                            //             scrollDirection: Axis.horizontal,
                            //             itemBuilder: (ctx, index) {
                            //               return Container(
                            //                   width: 40,
                            //                   height: 40,
                            //                   child: Image.asset(
                            //                     listLogo[index],
                            //                     package: 'vnu_core',
                            //                   )
                            //                   // svgAction(listLogo[index],
                            //                   //     action: () {}),
                            //                   );
                            //             }),
                            //       )
                            //     ],
                            //   ),
                            // )
                          ],
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tài khoản',
          style: TextStyle(fontSize: AppFontSizes.medium, color: Color(0xff2A3556)),
        ),
        Container(
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: TextField(
            style: const TextStyle(fontSize: AppFontSizes.medium, color: Color(0xff2A3556)),
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Nhập tài khoản',
              isDense: true,
              contentPadding: EdgeInsets.all(15),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
        )
      ],
    );
  }

  Widget _formPassword() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mật khẩu',
            style: TextStyle(fontSize: AppFontSizes.medium, color: Color(0xff2A3556)),
          ),
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: TextField(
              style: const TextStyle(fontSize: AppFontSizes.medium, color: Color(0xff2A3556)),
              controller: _paswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Nhập mật khẩu',
                isDense: true,
                contentPadding: EdgeInsets.all(15),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
          )
        ],
      ),
    );
  }

  //Private function
  _openTalker() {
    var password = "";
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
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).then(
      (v) async {
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
        //
      },
    );
  }
}
