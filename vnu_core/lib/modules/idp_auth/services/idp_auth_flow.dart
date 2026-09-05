import 'package:flutter/material.dart';
import 'package:vnu_core/modules/idp_auth/config/idp_auth_config.dart';
import 'package:vnu_core/modules/idp_auth/repository/idp_auth_repository.dart';
import 'package:vnu_core/modules/idp_auth/services/idp_onevnu_session_service.dart';
import 'package:vnu_core/modules/idp_auth/views/idp_login_webview.dart';
import 'package:vnu_core/services/app_config_service.dart';

class IdpAuthFlow {
  IdpAuthFlow._internal();

  static final IdpAuthFlow _instance = IdpAuthFlow._internal();

  factory IdpAuthFlow() => _instance;

  Future<bool> login(BuildContext context) async {
    Uri? startUri;

    // TEMP TEST: URL nằm duy nhất trong IdpAuthConfig.temporaryTestStartUrl.
    // Khi comment dòng gán idp-test ở IdpAuthConfig, giá trị này là null
    // và block ORIGINAL FLOW bên dưới chạy nguyên như source ban đầu.
    final String testStartUrl =
        IdpAuthConfig.temporaryTestStartUrl?.trim() ?? '';
    if (testStartUrl.isNotEmpty) {
      startUri = Uri.tryParse(testStartUrl);
    }

    // ORIGINAL FLOW: bắt buộc lấy IDP start URL từ GET /api/config.
    if (startUri == null) {
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

      final Uri? remoteUri = Uri.tryParse(remoteStartUrl);
      if (remoteUri == null ||
          !remoteUri.hasScheme ||
          (remoteUri.scheme != 'http' && remoteUri.scheme != 'https') ||
          remoteUri.host.isEmpty) {
        throw StateError('URL bắt đầu đăng nhập VNU IDP không hợp lệ.');
      }

      startUri = remoteUri;
    }

    final Uri resolvedStartUri = startUri!;
    if (!resolvedStartUri.hasScheme ||
        (resolvedStartUri.scheme != 'http' &&
            resolvedStartUri.scheme != 'https') ||
        resolvedStartUri.host.isEmpty) {
      throw StateError('URL bắt đầu đăng nhập VNU IDP không hợp lệ.');
    }

    final IdpWebLoginResult? webResult =
        await Navigator.of(context).push<IdpWebLoginResult>(
      MaterialPageRoute<IdpWebLoginResult>(
        builder: (_) => IdpLoginWebView(
          startUri: resolvedStartUri,
          // IDP có nhiều redirect nội bộ nên bật force-close để người dùng
          // luôn thoát được khỏi WebView, không bị mắc trong history SSO.
          forceCloseWebViewOnBack: true,
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
