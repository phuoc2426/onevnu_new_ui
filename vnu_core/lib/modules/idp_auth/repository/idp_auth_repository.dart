import 'dart:io';

import 'package:dio/dio.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_core/services/services_url.dart';

class IdpAuthRepository {
  IdpAuthRepository._internal()
      : _dio = DioOptions().createDio(ServicesUrl().baseUrl);

  static final IdpAuthRepository _instance = IdpAuthRepository._internal();

  factory IdpAuthRepository() => _instance;

  final Dio _dio;

  /// Đổi one-time ticket do MA/Admin API tạo ra thành token ONEVNU.
  ///
  /// Lưu ý: response này là accessToken + refreshToken của ONEVNU,
  /// KHÔNG phải access/refresh token của IdP.
  Future<SigninResponse> redeemTicket(String ticket) async {
    final Response<Map<String, dynamic>> response =
        await _dio.post<Map<String, dynamic>>(
      '/api/auth/idp/redeem',
      data: <String, dynamic>{
        'ticket': ticket,
        if ((ServicesUrl().firebaseToken ?? '').trim().isNotEmpty)
          'deviceToken': ServicesUrl().firebaseToken!.trim(),
        'deviceInfo': Platform.isAndroid
            ? 'Android'
            : Platform.isIOS
                ? 'iOS'
                : Platform.operatingSystem,
      },
      options: Options(
        headers: const <String, dynamic>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
    final SigninResponse result = SigninResponse.fromJson(body);

    if ((result.accessToken ?? '').trim().isEmpty ||
        (result.refreshToken ?? '').trim().isEmpty) {
      throw StateError(
        'API /api/auth/idp/redeem không trả accessToken/refreshToken ONEVNU.',
      );
    }

    return result;
  }
}
