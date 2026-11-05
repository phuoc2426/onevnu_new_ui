import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_session_cache.dart';

TuitionGatewaySession fakeSession(String token, {int? seconds}) =>
    TuitionGatewaySession(
      accessToken: token,
      canonicalStudentId: 'canonical-student-a',
      universityId: 4,
      expiresAtUtc: seconds == null
          ? null
          : DateTime.now().toUtc().add(Duration(seconds: seconds)),
    );

void main() {
  test('reuses valid gateway token in RAM across route openings', () async {
    final cache = TuitionGatewaySessionCache();
    var issues = 0;
    Future<TuitionGatewaySession> fetch() async {
      issues++;
      return fakeSession('gateway-token-a');
    }

    final first = await cache.getOrIssue(
      oneVnuJwt: 'onevnu-a', issue: fetch);
    final second = await cache.getOrIssue(
      oneVnuJwt: 'onevnu-a', issue: fetch);
    expect(first.accessToken, 'gateway-token-a');
    expect(second.accessToken, 'gateway-token-a');
    expect(issues, 1);
  });

  test('coalesces concurrent token requests', () async {
    final cache = TuitionGatewaySessionCache();
    final completer = Completer<TuitionGatewaySession>();
    var issues = 0;
    Future<TuitionGatewaySession> fetch() {
      issues++;
      return completer.future;
    }
    final a = cache.getOrIssue(oneVnuJwt: 'user-a', issue: fetch);
    final b = cache.getOrIssue(oneVnuJwt: 'user-a', issue: fetch);
    expect(issues, 1);
    completer.complete(fakeSession('shared'));
    expect((await a).accessToken, 'shared');
    expect((await b).accessToken, 'shared');
  });

  test('forces new token on 401 and then caches refreshed session', () async {
    final cache = TuitionGatewaySessionCache();
    var calls = 0;
    Future<TuitionGatewaySession> fetch() async =>
        fakeSession('token-${++calls}');

    expect((await cache.getOrIssue(
      oneVnuJwt: 'user-a', issue: fetch)).accessToken, 'token-1');
    expect((await cache.getOrIssue(
      oneVnuJwt: 'user-a', issue: fetch,
      forceRefresh: true)).accessToken, 'token-2');
    expect((await cache.getOrIssue(
      oneVnuJwt: 'user-a', issue: fetch)).accessToken, 'token-2');
    expect(calls, 2);
  });

  test('expired or nearly expired gateway token is replaced', () async {
    final cache = TuitionGatewaySessionCache();
    var calls = 0;
    Future<TuitionGatewaySession> fetch() async =>
        fakeSession('token-${++calls}', seconds: calls == 1 ? 20 : 500);
    await cache.getOrIssue(oneVnuJwt: 'user-a', issue: fetch);
    await cache.getOrIssue(oneVnuJwt: 'user-a', issue: fetch);
    expect(calls, 2);
  });

  test('switching ONEVNU account invalidates previous token', () async {
    final cache = TuitionGatewaySessionCache();
    await cache.getOrIssue(oneVnuJwt: 'user-a',
      issue: () async => fakeSession('student-a-token'));
    expect(cache.hasUsableSession('user-a'), isTrue);
    expect((await cache.getOrIssue(oneVnuJwt: 'user-b',
      issue: () async => fakeSession('student-b-token'))).accessToken,
      'student-b-token');
    expect(cache.hasUsableSession('user-a'), isFalse);
    expect(cache.hasUsableSession('user-b'), isTrue);
  });

  test('logout clear removes token and rejects stale in-flight result', () async {
    final cache = TuitionGatewaySessionCache();
    final completer = Completer<TuitionGatewaySession>();
    final pending = cache.getOrIssue(oneVnuJwt: 'user-a',
      issue: () => completer.future);
    final check = expectLater(pending, throwsStateError);
    cache.clear();
    completer.complete(fakeSession('stale-token'));
    await check;
    expect(cache.hasUsableSession('user-a'), isFalse);
  });
}
