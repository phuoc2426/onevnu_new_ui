import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/tuition/data/tuition_charge_category.dart';

void main() {
  test('Only the four real gateway codes can select distinct category colors', () {
    expect(TuitionChargeCategoryResolver.fromCode('FIRST_TIME'),
      TuitionChargeCategory.firstTime);
    expect(TuitionChargeCategoryResolver.fromCode('retake'),
      TuitionChargeCategory.retake);
    expect(TuitionChargeCategoryResolver.fromCode('IMPROVEMENT'),
      TuitionChargeCategory.improvement);
    expect(TuitionChargeCategoryResolver.fromCode('OUT_OF_PROGRAM'),
      TuitionChargeCategory.outOfProgram);
    expect(TuitionChargeCategoryResolver.fromCode('UNKNOWN'), isNull);
    expect(TuitionChargeCategoryResolver.fromCode(null), isNull);
    // Never infer "retake" from a Vietnamese display title.
    expect(TuitionChargeCategoryResolver.fromReceivable(<String,dynamic>{
      'name': 'Học phí học lại/cải thiện',
    }), isNull);
  });

  test('Prefers explicit receivable type over untrusted display text', () {
    expect(TuitionChargeCategoryResolver.fromReceivable(<String,dynamic>{
      'chargeType': 'IMPROVEMENT', 'title': 'Học phí bình thường',
    }), TuitionChargeCategory.improvement);
    expect(TuitionChargeCategoryResolver.fromReceivable(<String,dynamic>{
      'receivableType': <String,dynamic>{'code':'OUT_OF_PROGRAM'},
    }), TuitionChargeCategory.outOfProgram);
    expect(TuitionChargeCategoryResolver.fromReceivable(<String,dynamic>{
      'charges': [<String,dynamic>{'type':'FIRST_TIME'}],
    }), TuitionChargeCategory.firstTime);
  });

  test('All line items must agree to identify mixed payable invoices', () {
    expect(TuitionChargeCategoryResolver.fromReceivable(<String,dynamic>{
      'charges': [
        <String,dynamic>{'type':'RETAKE'},
        <String,dynamic>{'chargeType':'RETAKE'},
      ],
    }), TuitionChargeCategory.retake);
    expect(TuitionChargeCategoryResolver.fromReceivable(<String,dynamic>{
      'charges': [
        <String,dynamic>{'type':'RETAKE'},
        <String,dynamic>{'type':'OUT_OF_PROGRAM'},
      ],
    }), isNull);
    expect(TuitionChargeCategoryResolver.fromReceivable(<String,dynamic>{
      'charges': [
        <String,dynamic>{'type':'RETAKE'},
        <String,dynamic>{'description':'Không rõ loại'},
      ],
    }), isNull);
  });
}
