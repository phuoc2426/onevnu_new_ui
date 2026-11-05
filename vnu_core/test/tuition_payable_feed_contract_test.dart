import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_receivable_lifecycle.dart';

const _session = TuitionGatewaySession(
  accessToken: 'test-token',
  canonicalStudentId: 'student-for-tests',
  universityId: 4,
);

TuitionGatewayApi fakeGateway(
    void Function(RequestOptions, RequestInterceptorHandler) respond) {
  final dio = Dio(BaseOptions(baseUrl: 'https://unit.test/'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: respond));
  return TuitionGatewayApi(_session, dio: dio);
}

void deliver(RequestOptions req, RequestInterceptorHandler handler,
    dynamic payload, {int status = 200}) {
  handler.resolve(Response<dynamic>(
    requestOptions: req, statusCode: status, data: payload,
  ));
}

void main() {
  test('HTTP 200 [] remains ambiguous, never a paid confirmation', () async {
    var posts = 0;
    final api = fakeGateway((req, handler) {
      expect(req.method, 'GET');
      expect(req.queryParameters['payableOnly'], false);
      if (req.method == 'POST') posts++;
      deliver(req, handler, <String, dynamic>{
        'items': <dynamic>[], 'nextCursor': null,
      });
    });
    expect(await api.payableAll(payableOnly: false), isEmpty);
    expect(posts, 0);
  });

  test('HTTP 200 malformed shape throws, not silently []', () async {
    final api = fakeGateway((req, handler) => deliver(req, handler,
      <String, dynamic>{'message': 'service unavailable'}));
    await expectLater(api.payableAll(), throwsA(isA<FormatException>()));
  });

  test('HTTP 200 with application-level error must not become []', () async {
    final api = fakeGateway((req, handler) => deliver(req, handler,
      <String, dynamic>{'success': false, 'items': <dynamic>[]}));
    await expectLater(api.payableAll(), throwsA(isA<FormatException>()));
  });

  test('HTTP 200 incomplete upstream snapshot cannot be trusted', () async {
    final api = fakeGateway((req, handler) => deliver(req, handler,
      <String, dynamic>{'snapshotComplete': false,
        'sourceHealth': 'DEGRADED', 'items': <dynamic>[]}));
    await expectLater(api.payableAll(), throwsA(isA<FormatException>()));
  });

  test('non-map item throws instead of being dropped', () async {
    final api = fakeGateway((req, handler) => deliver(req, handler,
      <String, dynamic>{'items': <dynamic>[1, 'bad']}));
    await expectLater(api.payableAll(), throwsA(isA<FormatException>()));
  });

  test('empty first page despite a positive total is inconsistent', () async {
    final api = fakeGateway((req, handler) => deliver(req, handler,
      <String, dynamic>{'items': <dynamic>[], 'nextCursor': null,
        'totalCount': 1}));
    await expectLater(api.payableAll(), throwsA(isA<FormatException>()));
  });

  test('wrapped gateway feed works, including payable=false locked rows', () async {
    final api = fakeGateway((req, handler) => deliver(req, handler,
      <String, dynamic>{'data': <String, dynamic>{
        'items': <dynamic>[<String, dynamic>{
          'receivableId': 'r-1',
          'outstandingAmount': '7150000',
          'payable': false,
          'hasActiveLock': true,
          'payabilityReasonCode': 'PAYMENT_IN_PROGRESS',
          'activePaymentRequest': <String, dynamic>{
            'paymentRequestId': 'pr-1', 'status': 'PENDING',
          },
        }],
        'nextCursor': null,
      }}));
    final rows = await api.payableAll(payableOnly: false);
    expect(rows, hasLength(1));
    final entry = TuitionReceivableState.fromJson(rows.single);
    expect(entry.activeRequestId, 'pr-1');
    expect(entry.payable, false);
    expect(entry.canCreate, false);
    expect(entry.outstandingAmount, 7150000);
  });

  test('root activePaymentRequestId recovers status GET without local memory', () {
    final state = TuitionReceivableState.fromJson(<String, dynamic>{
      'receivableId': 'r-locked', 'outstandingAmount': 7150000,
      'payable': false, 'hasActiveLock': true,
      'payabilityReasonCode': 'PAYMENT_IN_PROGRESS',
      'activePaymentRequestId': 'server-known-request',
    });
    expect(state.activeRequestId, 'server-known-request');
    expect(state.canCreate, false);
    expect(state.blockingReason, 'PAYMENT_IN_PROGRESS');
  });

  test('after reinstall, backend snapshot can restore QR into new API instance', () async {
    var posts = 0;
    var gets = 0;
    final api = fakeGateway((req, handler) {
      if (req.method == 'POST') posts++;
      gets++;
      if (req.path.endsWith('/payable')) {
        deliver(req, handler, <String, dynamic>{'items': <dynamic>[
          <String, dynamic>{
            'receivableId': 'r-1', 'outstandingAmount': '7150000',
            'payable': false,
            'activePaymentRequest': <String, dynamic>{
              'paymentRequestId': 'pr-from-server', 'status': 'PENDING',
              'qr': <String, dynamic>{'payload': 'BANK_RETURNED_QR'},
            },
          },
        ]});
      } else {
        deliver(req, handler, <String, dynamic>{
          'paymentRequestId': 'pr-from-server', 'status': 'PROCESSING',
          // The detail GET may omit QR, but the snapshot had it.
        });
      }
    });
    // This API has NO history / persisted local data, as after reinstall.
    final rows = await api.payableAll(payableOnly: false);
    final active = Map<String, dynamic>.from(
      rows.single['activePaymentRequest'] as Map);
    api.rememberActiveRequest(active);
    final refreshed = await api.status('pr-from-server');
    expect(refreshed.status, 'PROCESSING');
    expect(refreshed.payload, 'BANK_RETURNED_QR');
    expect(gets, 2);
    expect(posts, 0);
  });

  test('fresh client cannot invent a disappeared receivable', () async {
    final api = fakeGateway((req, handler) => deliver(req, handler,
      <String, dynamic>{'items': <dynamic>[]}));
    final rows = await api.payableAll(payableOnly: false);
    expect(rows, isEmpty);
    // A backend fix (full receivable feed / student-scoped recovery API) is
    // REQUIRED. No local cache survives uninstall; do not fabricate QR.
  });
}
