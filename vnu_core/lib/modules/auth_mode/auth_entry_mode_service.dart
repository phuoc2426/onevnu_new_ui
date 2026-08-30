import 'package:vnu_core/modules/auth_mode/login_runtime_config.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/app_config_service.dart';

const String kSessionAuthEntryMode = 'kSessionAuthEntryMode';
const String kAuthEntryModePassword = 'PASSWORD';
const String kAuthEntryModeIdp = 'IDP';

class QrAccessDecision {
  const QrAccessDecision({required this.allowed, required this.message});

  final bool allowed;
  final String message;
}

class AuthEntryModeService {
  AuthEntryModeService._internal();

  static final AuthEntryModeService _instance = AuthEntryModeService._internal();

  factory AuthEntryModeService() => _instance;

  Future<void> markPassword() {
    return DataRepository().saveSecureKey(
      kSessionAuthEntryMode,
      kAuthEntryModePassword,
    );
  }

  Future<void> markIdp() {
    return DataRepository().saveSecureKey(
      kSessionAuthEntryMode,
      kAuthEntryModeIdp,
    );
  }

  Future<String> currentMode() async {
    return (await DataRepository().getSecureSaveKey(kSessionAuthEntryMode))
            ?.trim()
            .toUpperCase() ??
        '';
  }

  Future<QrAccessDecision> qrAccessDecision() async {
    final AppConfigService configService = AppConfigService();
    await configService.ensureLoaded(forceRefresh: true);

    if (!configService.isLoadedSuccessfully) {
      return QrAccessDecision(
        allowed: false,
        message: configService.lastLoadError ??
            'Không tải được cấu hình đăng nhập. Chức năng QR tạm thời không khả dụng.',
      );
    }

    final LoginRuntimeConfig config = configService.loginRuntimeConfig;

    if (!config.idpLogin || !config.qrEnabled) {
      return const QrAccessDecision(
        allowed: false,
        message:
            'Mã QR xác minh chỉ sử dụng khi hệ thống đang bật đăng nhập VNU IDP. '
            'Phiên đăng nhập tài khoản/mật khẩu không sử dụng được QR.',
      );
    }

    final String mode = await currentMode();
    if (mode == kAuthEntryModeIdp) {
      return const QrAccessDecision(allowed: true, message: '');
    }

    if (mode == kAuthEntryModePassword) {
      return const QrAccessDecision(
        allowed: false,
        message:
            'Bạn đang đăng nhập bằng tài khoản/mật khẩu dự phòng. '
            'Chức năng QR không khả dụng. Hãy đăng nhập lại bằng VNU IDP để sử dụng QR.',
      );
    }

    return const QrAccessDecision(
      allowed: false,
      message:
          'Chưa xác định được phiên đăng nhập VNU IDP. '
          'Vui lòng đăng xuất và đăng nhập lại bằng VNU IDP để sử dụng QR.',
    );
  }
}
