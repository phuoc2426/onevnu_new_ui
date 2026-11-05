/// CP1 list-payable contract. Only documented server-side filters are sent.
/// Local state/QR/search/sort filters are intentionally NOT sent to CP1.
class TuitionStudentPayableQuery {
  const TuitionStudentPayableQuery({
    this.termId,
    this.collectionPeriodCode,
    this.payableOnly = false,
  });

  final String? termId;
  final String? collectionPeriodCode;
  final bool payableOnly;

  bool get hasServerFilters =>
      (termId?.trim().isNotEmpty ?? false) ||
      (collectionPeriodCode?.trim().isNotEmpty ?? false) || payableOnly;

  Map<String, dynamic> asQueryParameters({
    required int limit,
    String? cursor,
  }) {
    if (limit < 1 || limit > 200) {
      throw RangeError.range(limit, 1, 200, 'limit');
    }
    final term = termId?.trim() ?? '';
    final period = collectionPeriodCode?.trim() ?? '';
    if (term.isNotEmpty &&
        !RegExp(r'^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$').hasMatch(term)) {
      throw const FormatException('termId must be a UUID');
    }
    if (period.length > 100) {
      throw const FormatException('collectionPeriodCode is too long');
    }
    final params = <String, dynamic>{'limit': limit};
    // Existing CP1 @Type(Boolean) interprets a literal 'false' as true.
    // Sending no payableOnly query means the FULL list by contract.
    if (payableOnly) params['payableOnly'] = true;
    if (term.isNotEmpty) params['termId'] = term;
    if (period.isNotEmpty) params['collectionPeriodCode'] = period;
    if (cursor != null && cursor.isNotEmpty) params['cursor'] = cursor;
    return params;
  }
}
