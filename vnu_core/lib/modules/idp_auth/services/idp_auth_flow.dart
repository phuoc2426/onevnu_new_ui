import 'package:flutter/material.dart';
import 'package:vnu_core/modules/idp_auth/config/idp_auth_config.dart';
import 'package:vnu_core/modules/idp_auth/repository/idp_auth_repository.dart';
import 'package:vnu_core/modules/idp_auth/services/idp_onevnu_session_service.dart';
import 'package:vnu_core/modules/idp_auth/views/idp_login_webview.dart';

class IdpAuthFlow {
  IdpAuthFlow._internal();

  static final IdpAuthFlow _instance = IdpAuthFlow._internal();

  factory IdpAuthFlow() => _instance;

  Future<bool> login(BuildContext context) async {
    final IdpWebLoginResult? webResult =
        await Navigator.of(context).push<IdpWebLoginResult>(
      MaterialPageRoute<IdpWebLoginResult>(
        builder: (_) => IdpLoginWebView(
          startUri: IdpAuthConfig.buildStartUri(),
        ),
      ),
    );

    if (webResult == null) return false;
    if (!webResult.isSuccess) {
      throw StateError(webResult.error ?? 'Đăng nhập IdP không thành công.');
    }

    final response =
        await IdpAuthRepository().redeemTicket(webResult.ticket!);
    await IdpOneVnuSessionService().apply(response);
    return true;
  }
}
