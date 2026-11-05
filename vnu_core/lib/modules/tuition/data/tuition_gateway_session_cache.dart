import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';

/// In-memory ONLY cache for the currently authenticated ONEVNU account.
///
/// Does not use disk, SharedPreferences or secure storage. The ONEVNU JWT is
/// already held by Globals; its value is only compared here to prevent using
/// a payment token from another login. clear() is called at local logout.
///
/// When provider TTL is absent, reuse until an authenticated CP1 GET receives
/// 401 and explicitly requests a new session. No assumed token lifetime.
class TuitionGatewaySessionCache {
  TuitionGatewaySessionCache();

  static final TuitionGatewaySessionCache instance =
      TuitionGatewaySessionCache();

  String? _oneVnuJwt;
  TuitionGatewaySession? _session;
  Future<TuitionGatewaySession>? _inFlight;
  bool _inFlightForced = false;
  int _generation = 0;

  bool hasUsableSession(String jwt) =>
      jwt.isNotEmpty && _oneVnuJwt == jwt &&
      _session != null && _session!.isValid && !_session!.expiresSoon;

  void clear() {
    _generation++;
    _oneVnuJwt = null;
    _session = null;
    _inFlight = null;
    _inFlightForced = false;
  }

  Future<TuitionGatewaySession> getOrIssue({
    required String oneVnuJwt,
    required Future<TuitionGatewaySession> Function() issue,
    bool forceRefresh = false,
  }) {
    final jwt = oneVnuJwt.trim();
    if (jwt.isEmpty) {
      clear();
      throw StateError('ONEVNU login required');
    }

    if (_oneVnuJwt != jwt) {
      clear();
      _oneVnuJwt = jwt;
    }
    if (!forceRefresh && hasUsableSession(jwt)) {
      return Future<TuitionGatewaySession>.value(_session!);
    }
    if (_inFlight != null && (!forceRefresh || _inFlightForced)) {
      return _inFlight!;
    }
    if (forceRefresh) {
      // A previous in-flight non-refresh token could already be rejected.
      // Force a new fetch and make its older response unusable.
      _generation++;
      _session = null;
    }
    final generation = _generation;
    late final Future<TuitionGatewaySession> pending;
    pending = Future<TuitionGatewaySession>.sync(issue).then((session) {
      if (_generation != generation || _oneVnuJwt != jwt) {
        throw StateError('ONEVNU account changed during ULIS token issuance');
      }
      if (!session.isValid) {
        throw StateError('Invalid ULIS payment session');
      }
      _session = session;
      return session;
    }).whenComplete(() {
      if (identical(_inFlight, pending)) {
        _inFlight = null;
        _inFlightForced = false;
      }
    });
    _inFlight = pending;
    _inFlightForced = forceRefresh;
    return pending;
  }
}
