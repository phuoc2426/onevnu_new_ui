import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/events.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/cubit/auth_cubit.dart';
import 'package:vnu_core/globals.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vnu_core/vnu_core.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';

import '../constants/config.dart';
import '../widgets/navi_widget.dart';

class VCoreChangePassScreen extends StatefulWidget {
  const VCoreChangePassScreen({Key? key}) : super(key: key);

  @override
  State<VCoreChangePassScreen> createState() => _VCoreChangePassScreenState();
}

class _VCoreChangePassScreenState extends State<VCoreChangePassScreen> {
  AuthCubit _authCubit = AuthCubit();
  late BuildContext hubContext;

  TextEditingController _matKhauCuController = TextEditingController();
  TextEditingController _matKhauMoiController = TextEditingController();
  List<String> listLogo = [
    'assets/images/ic_logo_ngoai_ngu.png',
    'assets/images/ic_logo_ueb.png',
    'assets/images/ic_logo_khoa_hoc_tu_nhien.png',
    'assets/images/ic_logo_cong_nghe.png',
    'assets/images/ic_logo_dai_hoc_1.png',
    'assets/images/ic_logo_dai_hoc_2.png'
  ];

  @override
  void initState() {
    super.initState();   
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: NaviWidget(
        titleStr: 'Đổi mật khẩu',
        leftAction: svgAction('assets/images/ic_navi_back.svg', action: () {
          Navigator.pop(context);
        }),
      ),
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
                if(state is AuthMessageSucess){
                    snackBarSuccess (state.message);
                       Globals().clearSession();
                          VnuCore().gotoLogin();
                  }
              },
              child: BlocBuilder<AuthCubit, AuthState>(
                bloc: _authCubit,
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return Center(child: CircularProgressIndicator());
                  }
                  

                  return Stack(
                    // fit: StackFit.loose,
                    children: [                    
                      // body ChangePass
                      Container(
                        margin: const EdgeInsets.only(top: 50),
                        padding: const EdgeInsets.only(left: 24, right: 24),
                        width: double.infinity,
                        decoration: const BoxDecoration(
                            color: Color(0xffF6F9FE),
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32))),
                        child: Column(
                          children: [                            
                            _formMatKhauCu(),
                            _formMatKhauMoi(),
                            
                            const SizedBox(
                              height: 30,
                            ),
                            InkWell(
                              onTap: () {
                                print('ChangePass');
                                FocusManager.instance.primaryFocus?.unfocus();
                                _authCubit.doiMatKhau(_matKhauCuController.text,
                                    _matKhauMoiController.text);
                              },
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                    color: const Color(0xff007F3E),
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Center(
                                    child: Text(
                                  'Đổi mật khẩu',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                )),
                              ),
                            ),
                            const SizedBox(
                              height: 32,
                            ),
                            
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

  Widget _formMatKhauCu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mật khẩu cũ',
          style: TextStyle(fontSize: 14, color: Color(0xff2A3556)),
        ),
        Container(
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: TextField(
            style: TextStyle(fontSize: 14, color: Color(0xff2A3556)),
            controller: _matKhauCuController,
            decoration: const InputDecoration(
              hintText: 'Nhập mật khẩu cũ',
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

  Widget _formMatKhauMoi() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mật khẩu mới',
            style: TextStyle(fontSize: 14, color: Color(0xff2A3556)),
          ),
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: TextField(
              style: TextStyle(fontSize: 14, color: Color(0xff2A3556)),
              controller: _matKhauMoiController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Nhập mật khẩu mới',
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
}
