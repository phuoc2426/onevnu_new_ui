import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_gateway_api.dart';
import 'package:vnu_core/modules/tuition/data/tuition_session_recovery_policy.dart';

void main() {
  group('three consecutive PAYABLE failures', () {
    test('renews only on third bad snapshot, once in each failure episode', () {
      final policy = TuitionSessionRecoveryPolicy();
      expect(policy.recordRecoverableMiss(), isFalse);
      expect(policy.recordRecoverableMiss(), isFalse);
      expect(policy.consecutiveMisses, 2);
      expect(policy.recordRecoverableMiss(), isTrue);
      expect(policy.recordRecoverableMiss(), isFalse);
      expect(policy.recordRecoverableMiss(), isFalse);
      expect(policy.rotatedInEpisode, isTrue);
      policy.recordVerifiedFeed();
      expect(policy.consecutiveMisses, 0);
      expect(policy.recordRecoverableMiss(), isFalse);
      expect(policy.recordRecoverableMiss(), isFalse);
      expect(policy.recordRecoverableMiss(), isTrue);
    });

    test('manual re-issue prevents an immediate automatic token storm', () {
      final policy = TuitionSessionRecoveryPolicy();
      policy.recordManualRotation();
      for (var i = 0; i < 7; i++) {
        expect(policy.recordRecoverableMiss(), isFalse);
      }
      policy.recordVerifiedFeed();
      expect(policy.recordRecoverableMiss(), isFalse);
      expect(policy.recordRecoverableMiss(), isFalse);
      expect(policy.recordRecoverableMiss(), isTrue);
    });
  });

  test('two device tokens can read same unpaid locked bill independently',
      () async {
    var refreshedOnDeviceB = 0;
    final seen = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid/'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      expect(request.method, 'GET');
      expect(request.queryParameters['payableOnly'], false);
      seen.add(request.headers['Authorization']?.toString() ?? '');
      handler.resolve(Response<dynamic>(
        requestOptions: request,
        statusCode: 200,
        data: <String, dynamic>{'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'receivableId': 'same-receivable',
            'payable': false,
            'hasActiveLock': true,
            'payabilityReasonCode': 'PAYMENT_IN_PROGRESS',
            'outstandingAmount': '7150000',
            'activePaymentRequest': <String, dynamic>{
              'paymentRequestId': 'pending-request', 'status': 'PENDING',
            },
          },
        ]},
      ));
    }));
    const first = TuitionGatewaySession(
      accessToken: 'device-A',
      canonicalStudentId: 'same-student', universityId: 4);
    const second = TuitionGatewaySession(
      accessToken: 'device-B',
      canonicalStudentId: 'same-student', universityId: 4);
    final deviceA = TuitionGatewayApi(first, dio: dio);
    final deviceB = TuitionGatewayApi(second, dio: dio,
      renewSession: () async {
        refreshedOnDeviceB++;
        return const TuitionGatewaySession(
          accessToken: 'device-B-new',
          canonicalStudentId: 'same-student', universityId: 4);
      });
    expect((await deviceA.payableAll()).single['payable'], false);
    expect((await deviceB.payableAll()).single['hasActiveLock'], true);
    await deviceB.refreshSession();
    expect((await deviceB.payableAll()).single['receivableId'],
      'same-receivable');
    expect((await deviceA.payableAll()).single['receivableId'],
      'same-receivable');
    expect(refreshedOnDeviceB, 1);
    expect(seen, <String>[
      'Bearer device-A', 'Bearer device-B',
      'Bearer device-B-new', 'Bearer device-A',
    ]);
    // The Flutter clients are independent; production backend MUST also
    // accept these concurrent credentials for the same canonical student.
  });
}
