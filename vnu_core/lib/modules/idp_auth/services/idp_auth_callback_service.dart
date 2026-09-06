import 'dart:async';

import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/modules/idp_auth/config/idp_auth_config.dart';

class IdpAuthCallbackResult {
  const IdpAuthCallbackResult._({this.ticket, this.error});

  final String? ticket;
  final String? error;

  bool get isSuccess => (ticket ?? '').isNotEmpty;

  factory IdpAuthCallbackResult.success(String ticket) =>
      IdpAuthCallbackResult._(ticket: ticket);

  factory IdpAuthCallbackResult.failure(String error) =>
      IdpAuthCallbackResult._(error: error);
}

/// Bridges the verified HTTPS App Link received by the host application back to
/// the in-flight IDP login Future. Ticket values are never logged.
class IdpAuthCallbackService {
  IdpAuthCallbackService._internal();

  static final IdpAuthCallbackService _instance =
      IdpAuthCallbackService._internal();

  factory IdpAuthCallbackService() => _instance;

  Completer<IdpAuthCallbackResult>? _waiter;
  IdpAuthCallbackResult? _pending;

  void prepareNewLogin() {
    _pending = null;
    final Completer<IdpAuthCallbackResult>? waiter = _waiter;
    _waiter = null;
    if (waiter != null && !waiter.isCompleted) {
      waiter.completeError(
        StateError('Một phiên đăng nhập VNU IDP mới đã thay thế phiên trước.'),
      );
    }
  }

  Future<IdpAuthCallbackResult> waitForCallback() {
    final IdpAuthCallbackResult? pending = _pending;
    if (pending != null) {
      _pending = null;
      return Future<IdpAuthCallbackResult>.value(pending);
    }

    _waiter?.completeError(
      StateError('Một phiên đăng nhập VNU IDP mới đã thay thế phiên trước.'),
    );
    final Completer<IdpAuthCallbackResult> waiter =
        Completer<IdpAuthCallbackResult>();
    _waiter = waiter;

    return waiter.future.timeout(
      IdpAuthConfig.callbackTimeout,
      onTimeout: () {
        if (identical(_waiter, waiter)) _waiter = null;
        throw TimeoutException(
          'Phiên đăng nhập VNU IDP đã hết thời gian chờ.',
          IdpAuthConfig.callbackTimeout,
        );
      },
    );
  }

  bool handleUri(Uri uri) {
    if (!IdpAuthConfig.isAppCallback(uri)) return false;

    final String ticket = uri.queryParameters['ticket']?.trim() ?? '';
    final String error = uri.queryParameters['error']?.trim() ?? '';
    final String friendlyError = switch (error) {
      'idp_account_mismatch' =>
        'Tài khoản VNU IDP vừa đăng nhập không khớp với tài khoản ONEVNU hiện tại.',
      'idp_provider_error' => 'VNU IDP đã từ chối hoặc hủy yêu cầu đăng nhập.',
      'missing_code' || 'missing_state' =>
        'Phản hồi đăng nhập VNU IDP không hợp lệ.',
      _ => 'Đăng nhập VNU IDP không thành công.',
    };

    final IdpAuthCallbackResult result = ticket.isNotEmpty
        ? IdpAuthCallbackResult.success(ticket)
        : IdpAuthCallbackResult.failure(friendlyError);

    dlog(
      '[IDP_BROWSER][APP_LINK] received=true success=${result.isSuccess}',
    );

    final Completer<IdpAuthCallbackResult>? waiter = _waiter;
    if (waiter != null && !waiter.isCompleted) {
      _waiter = null;
      waiter.complete(result);
    } else {
      // Covers process resume where App Link arrives just before login() starts
      // awaiting it. Only the one-time result is retained; no persistent token.
      _pending = result;
    }
    return true;
  }

  void cancelWait() {
    final Completer<IdpAuthCallbackResult>? waiter = _waiter;
    _waiter = null;
    if (waiter != null && !waiter.isCompleted) {
      waiter.completeError(StateError('Đã hủy đăng nhập VNU IDP.'));
    }
  }
}
