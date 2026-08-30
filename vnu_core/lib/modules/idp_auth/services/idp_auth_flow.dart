import 'package:flutter/material.dart';
import 'package:vnu_core/modules/idp_auth/repository/idp_auth_repository.dart';
import 'package:vnu_core/modules/idp_auth/services/idp_onevnu_session_service.dart';
import 'package:vnu_core/modules/idp_auth/views/idp_login_webview.dart';
import 'package:vnu_core/services/app_config_service.dart';

class IdpAuthFlow {
  IdpAuthFlow._internal();

  static final IdpAuthFlow _instance = IdpAuthFlow._internal();

  factory IdpAuthFlow() => _instance;

  Future<bool> login(BuildContext context) async {
    final AppConfigService configService = AppConfigService();
    await configService.ensureLoaded(forceRefresh: true);

    if (!configService.isLoadedSuccessfully) {
      throw StateError(
        configService.lastLoadError ??
            'Không tải được cấu hình đăng nhập từ máy chủ.',
      );
    }

    final config = configService.loginRuntimeConfig;
    final String remoteStartUrl = config.idpStartUrl.trim();
    if (!config.idpLogin || remoteStartUrl.isEmpty) {
      throw StateError(
        'VNU IDP hiện không được bật hoặc chưa có URL đăng nhập hợp lệ. '
        'Vui lòng sử dụng đăng nhập tài khoản/mật khẩu.',
      );
    }

    final Uri? startUri = Uri.tryParse(remoteStartUrl);
    if (startUri == null ||
        !startUri.hasScheme ||
        (startUri.scheme != 'http' && startUri.scheme != 'https') ||
        startUri.host.isEmpty) {
      throw StateError('URL bắt đầu đăng nhập VNU IDP không hợp lệ.');
    }

    final IdpWebLoginResult? webResult =
        await Navigator.of(context).push<IdpWebLoginResult>(
      MaterialPageRoute<IdpWebLoginResult>(
        builder: (_) => IdpLoginWebView(startUri: startUri),
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
