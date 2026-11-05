/// The four tuition CHARGE types. This is NOT a payment-status enum.
///
/// A type is trusted only when the gateway returns one of these exact codes;
/// we intentionally do not guess type from Vietnamese display text, bill name,
/// position or money amount. Unknown/mixed types retain the mint/sand UI fallback.
enum TuitionChargeCategory { firstTime, retake, improvement, outOfProgram }

extension TuitionChargeCategoryInfo on TuitionChargeCategory {
  String get code => switch (this) {
    TuitionChargeCategory.firstTime => 'FIRST_TIME',
    TuitionChargeCategory.retake => 'RETAKE',
    TuitionChargeCategory.improvement => 'IMPROVEMENT',
    TuitionChargeCategory.outOfProgram => 'OUT_OF_PROGRAM',
  };

  String get label => switch (this) {
    TuitionChargeCategory.firstTime => 'Học lần đầu',
    TuitionChargeCategory.retake => 'Học lại',
    TuitionChargeCategory.improvement => 'Học cải thiện',
    TuitionChargeCategory.outOfProgram => 'Ngoài chương trình',
  };
}

abstract final class TuitionChargeCategoryResolver {
  // Candidate keys are only READ; the VALUE must exactly match a valid code.
  // Add a field here if the backend contract introduces a different key.
  static const keys = <String>[
    'chargeType', 'chargeTypeCode', 'chargeCategory', 'feeType',
    'tuitionType', 'tuitionFeeType', 'tuitionChargeType',
    'receivableType', 'feeCategory', 'category', 'categoryCode',
    'type', 'charge_type', 'charge_type_code', 'fee_type',
  ];

  static TuitionChargeCategory? fromCode(Object? input) {
    // Some gateways wrap their enum as {code: "RETAKE"}.
    final Object? raw;
    if (input is Map) {
      raw = input['code'] ?? input['value'] ?? input['typeCode'];
    } else {
      raw = input;
    }
    if (raw is! String) return null;
    final code = raw.trim().toUpperCase()
        .replaceAll(RegExp(r'[\s-]+'), '_');
    return switch (code) {
      'FIRST_TIME' => TuitionChargeCategory.firstTime,
      'RETAKE' => TuitionChargeCategory.retake,
      'IMPROVEMENT' => TuitionChargeCategory.improvement,
      'OUT_OF_PROGRAM' => TuitionChargeCategory.outOfProgram,
      _ => null,
    };
  }

  static TuitionChargeCategory? _fromFields(Map<dynamic, dynamic> source) {
    for (final field in keys) {
      final parsed = fromCode(source[field]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static TuitionChargeCategory? fromReceivable(Map<String, dynamic> row) {
    // Prefer a receivable-wide category if the backend supplies it explicitly.
    final direct = _fromFields(row);
    if (direct != null) return direct;

    // Otherwise all line-items MUST agree, including known/unknown mixtures.
    // Picking only charges.first would colour a mixed invoice incorrectly.
    final charges = row['charges'];
    if (charges is! List || charges.isEmpty) return null;
    TuitionChargeCategory? shared;
    for (final charge in charges) {
      if (charge is! Map) return null;
      final category = _fromFields(charge);
      if (category == null) return null;
      if (shared != null && category != shared) return null;
      shared = category;
    }
    return shared;
  }
}
