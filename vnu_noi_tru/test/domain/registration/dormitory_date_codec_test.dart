import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_noi_tru/domain/registration/dormitory_date_codec.dart';

void main() {
  group('DormitoryDateCodec date-only contract', () {
    test('keeps an already date-only DOB unchanged', () {
      expect(DormitoryDateCodec.normalize('2005-09-11'), '2005-09-11');
    });

    test('does not shift a positive-offset datetime to another date', () {
      expect(
        DormitoryDateCodec.normalize('2005-09-11T23:30:00+14:00'),
        '2005-09-11',
      );
    });

    test('does not shift a negative-offset datetime to another date', () {
      expect(
        DormitoryDateCodec.normalize('2005-09-11T17:00:00-07:00'),
        '2005-09-11',
      );
    });

    test('uses DateTime calendar components without UTC conversion', () {
      expect(
        DormitoryDateCodec.normalize(DateTime(2005, 9, 11, 23, 59)),
        '2005-09-11',
      );
    });

    test('accepts Vietnamese display format but emits API date only', () {
      expect(DormitoryDateCodec.normalize('11/09/2005'), '2005-09-11');
    });

    test('rejects datetime/date text that cannot be safely normalized', () {
      expect(
        () => DormitoryDateCodec.normalize('September 11, 2005 12:00'),
        throwsFormatException,
      );
    });
  });
}
