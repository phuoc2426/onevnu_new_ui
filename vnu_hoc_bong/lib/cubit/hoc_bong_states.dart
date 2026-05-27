import '../models/hoc_bong_models.dart';

class HocBongListState {
  final bool loading;
  final String? error;
  final List<HocBongModel> items;
  final String filter;

  const HocBongListState({
    this.loading = false,
    this.error,
    this.items = const [],
    this.filter = 'ALL',
  });

  HocBongListState copyWith({bool? loading, String? error, List<HocBongModel>? items, String? filter}) {
    return HocBongListState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
      filter: filter ?? this.filter,
    );
  }
}

class HocBongDetailState {
  final bool loading;
  final String? error;
  final HocBongDetailModel? detail;
  final HocBongValidateResultModel? validateResult;
  final HocBongHoSoModel? draft;

  const HocBongDetailState({
    this.loading = false,
    this.error,
    this.detail,
    this.validateResult,
    this.draft,
  });

  HocBongDetailState copyWith({
    bool? loading,
    String? error,
    HocBongDetailModel? detail,
    HocBongValidateResultModel? validateResult,
    HocBongHoSoModel? draft,
  }) {
    return HocBongDetailState(
      loading: loading ?? this.loading,
      error: error,
      detail: detail ?? this.detail,
      validateResult: validateResult ?? this.validateResult,
      draft: draft ?? this.draft,
    );
  }
}

class HocBongFormState {
  final bool loading;
  final bool saving;
  final bool submitting;
  final String? error;
  final String? message;
  final HocBongDetailModel? detail;
  final HocBongHoSoModel? draft;
  final Map<String, dynamic> values;
  final Map<String, String> pendingFilePaths;
  final bool dirty;
  final HocBongValidateResultModel? validateResult;

  const HocBongFormState({
    this.loading = false,
    this.saving = false,
    this.submitting = false,
    this.error,
    this.message,
    this.detail,
    this.draft,
    this.values = const {},
    this.pendingFilePaths = const {},
    this.dirty = false,
    this.validateResult,
  });

  HocBongFormState copyWith({
    bool? loading,
    bool? saving,
    bool? submitting,
    String? error,
    String? message,
    HocBongDetailModel? detail,
    HocBongHoSoModel? draft,
    Map<String, dynamic>? values,
    Map<String, String>? pendingFilePaths,
    bool? dirty,
    HocBongValidateResultModel? validateResult,
  }) {
    return HocBongFormState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      submitting: submitting ?? this.submitting,
      error: error,
      message: message,
      detail: detail ?? this.detail,
      draft: draft ?? this.draft,
      values: values ?? this.values,
      pendingFilePaths: pendingFilePaths ?? this.pendingFilePaths,
      dirty: dirty ?? this.dirty,
      validateResult: validateResult ?? this.validateResult,
    );
  }
}

class HocBongHoSoState {
  final bool loading;
  final String? error;
  final List<HocBongHoSoModel> items;
  final HocBongHoSoModel? detail;
  final String filter;

  const HocBongHoSoState({
    this.loading = false,
    this.error,
    this.items = const [],
    this.detail,
    this.filter = 'ALL',
  });

  HocBongHoSoState copyWith({
    bool? loading,
    String? error,
    List<HocBongHoSoModel>? items,
    HocBongHoSoModel? detail,
    String? filter,
  }) {
    return HocBongHoSoState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
      detail: detail ?? this.detail,
      filter: filter ?? this.filter,
    );
  }
}
