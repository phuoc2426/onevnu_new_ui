import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/sync/vneid_callback_parser.dart';

void main() {
  test('parses path callback format', () {
    final data = parseVneidCallback(
      Uri.parse('https://onevnu-admin.vnu.edu.vn/vneid/callback/TEST123|1'),
    );

    expect(data?.transactionCode, 'TEST123');
    expect(data?.result, '1');
  });

  test('parses query callback format', () {
    final data = parseVneidCallback(
      Uri.parse(
        'https://onevnu-admin.vnu.edu.vn/vneid/callback'
        '?transactionCode=TEST123&result=1',
      ),
    );

    expect(data?.transactionCode, 'TEST123');
    expect(data?.result, '1');
  });

  test('parses fallback query parameter names', () {
    final data = parseVneidCallback(
      Uri.parse(
        'https://onevnu-admin.vnu.edu.vn/vneid/callback'
        '?transitionCode=TEST123&resultCode=2',
      ),
    );

    expect(data?.transactionCode, 'TEST123');
    expect(data?.result, '2');
  });

  test('ignores non callback links', () {
    final data = parseVneidCallback(
      Uri.parse('https://onevnu-admin.vnu.edu.vn/not-vneid/TEST123|1'),
    );

    expect(data, isNull);
  });

  test('returns null for invalid callback payload', () {
    final data = parseVneidCallback(
      Uri.parse('https://onevnu-admin.vnu.edu.vn/vneid/callback?result=1'),
    );

    expect(data, isNull);
  });
}
