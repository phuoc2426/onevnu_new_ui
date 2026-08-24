import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/common/log.dart';

void main() {
  test('sanitizeLogMessage redacts bearer and credentials', () {
    const source =
        'Authorization: Bearer abc.def.ghi password=secret123 '
        'refresh_token=refresh-secret cccd=001234567890';

    final sanitized = sanitizeLogMessage(source);

    expect(sanitized, isNot(contains('abc.def.ghi')));
    expect(sanitized, isNot(contains('secret123')));
    expect(sanitized, isNot(contains('refresh-secret')));
    expect(sanitized, isNot(contains('001234567890')));
    expect(sanitized, contains('[REDACTED]'));
  });

  test('sanitizeLogMessage keeps normal diagnostic text', () {
    const source = '[SCHEDULE_LOAD] status=completed semesterId=050';
    expect(sanitizeLogMessage(source), source);
  });
}
