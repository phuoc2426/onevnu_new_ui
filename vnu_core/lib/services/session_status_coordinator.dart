import 'dart:async';

import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/repository/app_repository.dart';

/// P1B app-side fallback for server-side/Keycloak session revocation.
///
/// Security is enforced by the backend. This coordinator only improves UX so
/// a revoked session is noticed on cold-start/resume before the user taps a
/// business API. It never talks to Keycloak and never stores Keycloak sid.
class SessionStatusCoordinator {
  SessionStatusCoordinator._();

  static final SessionStatusCoordinator instance = SessionStatusCoordinator._();

  static const Duration _minInterval = Duration(seconds: 15);
  DateTime? _lastAttemptAt;
  Future<void>? _inFlight;

  Future<void> onStartup() async {
    // Give secure-storage/session restoration a short window on cold start.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await _check(reason: 'startup');
  }

  Future<void> onAppResumed() => _check(reason: 'resume');

  Future<void> _check({required String reason}) {
    final Future<void>? current = _inFlight;
    if (current != null) return current;

    final String token = Globals().token.trim();
    if (token.isEmpty) return Future<void>.value();

    final DateTime now = DateTime.now();
    final DateTime? previous = _lastAttemptAt;
    if (previous != null && now.difference(previous) < _minInterval) {
      return Future<void>.value();
    }
    _lastAttemptAt = now;

    final Future<void> future = _run(reason);
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
  }

  Future<void> _run(String reason) async {
    final Stopwatch watch = Stopwatch()..start();
    dlog('[P1B_SESSION][FLUTTER][STATUS_CHECK_BEGIN] reason=$reason');
    try {
      final Map<String, dynamic> response =
          await ApiRepository().getSessionStatus();
      dlog(
        '[P1B_SESSION][FLUTTER][STATUS_CHECK_OK] '
        'reason=$reason status=${response['status']} '
        'sessionBound=${response['sessionBound']} '
        'idpCheck=${response['idpCheck']} '
        'elapsedMs=${watch.elapsedMilliseconds}',
      );
    } catch (error) {
      // A 401 has already fired TokenExpiredEvent inside the global Dio
      // interceptor. Provider/network failures are intentionally fail-soft.
      logWarning(
        '[P1B_SESSION][FLUTTER][STATUS_CHECK_DEFERRED] '
        'reason=$reason type=${error.runtimeType} '
        'elapsedMs=${watch.elapsedMilliseconds}',
      );
    }
  }
}
