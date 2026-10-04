import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/modules/auth_mode/login_runtime_config.dart';
import 'package:vnu_core/modules/idp_auth/config/idp_auth_config.dart';
import 'package:vnu_core/services/app_config_service.dart';

/// Single gate for deciding where ONEVNU login-mode configuration comes from.
///
/// The rest of the app must not independently re-read /api/config to decide
/// whether an IDP login button/flow is allowed. This prevents a static internal
/// test build from being overwritten by the production `idp_login=false` flag.
class LoginConfigResolver {
  LoginConfigResolver._internal();

  static final LoginConfigResolver _instance = LoginConfigResolver._internal();

  factory LoginConfigResolver() => _instance;

  Future<LoginRuntimeConfig> resolve({bool forceRefresh = true}) async {
    if (IdpAuthConfig.useStaticLoginConfig) {
      const LoginRuntimeConfig config = IdpAuthConfig.staticLoginRuntimeConfig;
      logInfo(
        '[LOGIN_CONFIG_RESOLVER] source=STATIC '
        'idpLogin=${config.idpLogin} qrEnabled=${config.qrEnabled}',
      );
      return config;
    }

    final AppConfigService service = AppConfigService();
    await service.ensureLoaded(forceRefresh: forceRefresh);
    if (!service.isLoadedSuccessfully) {
      throw StateError(
        service.lastLoadError ??
            'Không tải được cấu hình đăng nhập từ máy chủ.',
      );
    }

    final LoginRuntimeConfig config = service.loginRuntimeConfig;
    logInfo(
      '[LOGIN_CONFIG_RESOLVER] source=API '
      'idpLogin=${config.idpLogin} qrEnabled=${config.qrEnabled}',
    );
    return config;
  }

  /// Re-check immediately before the user enters a login flow.
  ///
  /// Static diagnostic mode deliberately bypasses /api/config. API-driven mode
  /// performs the original last-second server check.
  Future<LoginRuntimeConfig> verifyBeforeSubmit() async {
    if (IdpAuthConfig.useStaticLoginConfig) {
      const LoginRuntimeConfig config = IdpAuthConfig.staticLoginRuntimeConfig;
      logInfo(
        '[LOGIN_CONFIG_VERIFY] source=STATIC '
        'idpLogin=${config.idpLogin}',
      );
      return config;
    }

    final LoginRuntimeConfig config =
        await AppConfigService().fetchLatestLoginRuntimeConfig();
    logInfo(
      '[LOGIN_CONFIG_VERIFY] source=API idpLogin=${config.idpLogin}',
    );
    return config;
  }
}
