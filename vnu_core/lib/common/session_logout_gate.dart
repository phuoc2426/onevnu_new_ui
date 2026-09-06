import 'package:vnu_core/common/log.dart';

/// Keeps a very short-lived barrier between a user-triggered logout and a new
/// login attempt on the same app process.
///
/// Logout UI is allowed to navigate immediately. Server revocation + critical
/// local secure-storage cleanup continue asynchronously. A new login waits for
/// that critical future so a fast re-login cannot race the previous
/// device logout and have its freshly-created credential revoked.
class SessionLogoutGate {
  SessionLogoutGate._();

  static Future<void>? _criticalFuture;
  static int _generation = 0;

  static bool get hasPendingCriticalLogout => _criticalFuture != null;

  static void begin(Future<void> criticalFuture) {
    final int generation = ++_generation;

    late final Future<void> wrapped;
    wrapped = criticalFuture.whenComplete(() {
      if (_generation == generation && identical(_criticalFuture, wrapped)) {
        _criticalFuture = null;
        dlog('[P1A_DIAG][LOGOUT_GATE][RELEASED] generation=$generation');
      }
    });

    _criticalFuture = wrapped;
    dlog('[P1A_DIAG][LOGOUT_GATE][ARMED] generation=$generation');
  }

  static Future<void> waitForCriticalLogout() async {
    final Future<void>? pending = _criticalFuture;
    if (pending == null) return;

    final Stopwatch watch = Stopwatch()..start();
    dlog('[P1A_DIAG][LOGOUT_GATE][WAIT_BEGIN]');

    try {
      // Do not put another timeout around persistent local cleanup. Starting a
      // new login before old secure-storage deletes finish can delete the newly
      // written token. Server signout is already bounded at the call site.
      await pending;
      dlog(
        '[P1A_DIAG][LOGOUT_GATE][WAIT_DONE] '
        'elapsedMs=${watch.elapsedMilliseconds}',
      );
    } catch (error) {
      dlog(
        '[P1A_DIAG][LOGOUT_GATE][WAIT_ERROR] '
        'type=${error.runtimeType} elapsedMs=${watch.elapsedMilliseconds}',
      );
    }
  }
}
