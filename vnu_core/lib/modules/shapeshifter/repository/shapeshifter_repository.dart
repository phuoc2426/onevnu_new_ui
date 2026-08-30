import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/shapeshifter/models/shapeshifter_feature.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/services_url.dart';

enum ShapeshifterPlacement { home, my }

extension ShapeshifterPlacementApi on ShapeshifterPlacement {
  String get apiValue => name.toUpperCase();
}

class ShapeshifterApiException implements Exception {
  const ShapeshifterApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ShapeshifterRepository {
  ShapeshifterRepository._internal();

  static final ShapeshifterRepository _instance =
      ShapeshifterRepository._internal();

  factory ShapeshifterRepository() => _instance;

  Dio _client() {
    return Dio(
      BaseOptions(
        baseUrl: ServicesUrl().baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: const <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<List<ShapeshifterFeature>> getFeatures({
    ShapeshifterPlacement placement = ShapeshifterPlacement.home,
  }) async {
    final token = await currentAccessToken(required: true);
    try {
      final response = await _client().get<dynamic>(
        'api/shapeshifter/features',
        queryParameters: <String, dynamic>{'placement': placement.apiValue},
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer $token'},
        ),
      );
      final data = response.data;
      if (data is! List) return const <ShapeshifterFeature>[];

      final features = data
          .whereType<Map>()
          .map(
            (item) => ShapeshifterFeature.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          // Backend đã lọc enabled / audience STUDENT-APPLICANT / placement.
          // Flutter chỉ kiểm tra dữ liệu tối thiểu để render; không tự loại feature
          // theo authMode vì registry có thể bổ sung mode mới mà app chưa biết.
          .where(
            (feature) =>
                feature.code.isNotEmpty &&
                feature.label.isNotEmpty &&
                feature.webUrl.isNotEmpty,
          )
          .toList()
        ..sort((a, b) {
          final int left = placement == ShapeshifterPlacement.my
              ? a.mySortOrder
              : a.sortOrder;
          final int right = placement == ShapeshifterPlacement.my
              ? b.mySortOrder
              : b.sortOrder;
          return left.compareTo(right);
        });
      return features;
    } on DioException catch (error) {
      throw _mapError(error, 'Không tải được danh sách chức năng.');
    }
  }

  /// Returns the current ONEVNU access token for either Student or
  /// Admitted Student. If the JWT is already expired (or about to expire), this
  /// method uses the refresh token that the app already owns and updates the
  /// same secure-storage keys before opening the WebView.
  ///
  /// The access token is used only on the first /auth/bootstrap navigation.
  Future<String> currentAccessToken({bool required = false}) async {
    final storage = DataRepository();

    String token = Globals().token.trim();
    if (token.isEmpty) {
      final principalType =
          (await storage.getSecureSaveKey(kSessionPrincipalType))
                  ?.trim()
                  .toUpperCase() ??
              '';
      final key = principalType == kPrincipalTypeApplicant
          ? kApplicantAccessToken
          : kLoginToken;
      token = (await storage.getSecureSaveKey(key))?.trim() ?? '';
    }

    if (token.isNotEmpty && !_shouldRefresh(token)) {
      Globals().token = token;
      ApiRepository().setToken(token);
      return token;
    }

    // Refresh only when needed. Failure is non-blocking here: the existing
    // token is returned and ONEVNU remains the authority that decides whether it
    // is still acceptable during bootstrap.
    try {
      final principalType =
          (await storage.getSecureSaveKey(kSessionPrincipalType))
                  ?.trim()
                  .toUpperCase() ??
              '';

      if (principalType == kPrincipalTypeApplicant) {
        final refresh = firstNonEmpty(<String?>[
          Globals().refreshToken,
          await storage.getSecureSaveKey(kApplicantRefreshToken),
        ]);
        if (refresh.isNotEmpty) {
          final refreshed = await ApiRepository().applicantRefreshToken(refresh);
          final newAccess = refreshed.accessToken.trim();
          final newRefresh = refreshed.refreshToken.trim();
          if (newAccess.isNotEmpty) {
            token = newAccess;
            Globals().token = newAccess;
            Globals().refreshToken = newRefresh;
            ApiRepository().setToken(newAccess);
            await storage.saveSecureKey(kApplicantAccessToken, newAccess);
            if (newRefresh.isNotEmpty) {
              await storage.saveSecureKey(kApplicantRefreshToken, newRefresh);
            }
          }
        }
      } else {
        final refresh = firstNonEmpty(<String?>[
          Globals().refreshToken,
          await storage.getSecureSaveKey(kLoginRefreshToken),
        ]);
        if (refresh.isNotEmpty) {
          final refreshed = await ApiRepository().refreshToken(refresh);
          final newAccess = refreshed.accessToken?.trim() ?? '';
          final newRefresh = refreshed.refreshToken?.trim() ?? '';
          if (newAccess.isNotEmpty) {
            token = newAccess;
            Globals().token = newAccess;
            Globals().refreshToken = newRefresh;
            ApiRepository().setToken(newAccess);
            await storage.saveSecureKey(kLoginToken, newAccess);
            if (newRefresh.isNotEmpty) {
              await storage.saveSecureKey(kLoginRefreshToken, newRefresh);
            }
          }
        }
      }
    } catch (_) {
      // The bootstrap request will perform the authoritative validation.
    }

    if (token.isNotEmpty) {
      Globals().token = token;
      ApiRepository().setToken(token);
      return token;
    }

    if (required) {
      throw const ShapeshifterApiException(
        'Không tìm thấy thông tin đăng nhập ONEVNU.',
        statusCode: 401,
      );
    }
    return '';
  }

  bool _shouldRefresh(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return false;
      final expValue = payload['exp'];
      final exp = expValue is num
          ? expValue.toInt()
          : int.tryParse(expValue?.toString() ?? '');
      if (exp == null) return false;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp <= now + 120;
    } catch (_) {
      return false;
    }
  }

  String firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
  }

  ShapeshifterApiException _mapError(
    DioException error,
    String fallback,
  ) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    String? message;

    if (data is Map) {
      for (final key in const ['message', 'error', 'detail']) {
        final value = data[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) {
          message = value;
          break;
        }
      }
    } else if (data is String && data.trim().isNotEmpty) {
      message = data.trim();
    }

    if (status == 403) {
      message ??= 'Tài khoản hiện tại không được phép sử dụng chức năng này.';
    }

    return ShapeshifterApiException(message ?? fallback, statusCode: status);
  }
}
