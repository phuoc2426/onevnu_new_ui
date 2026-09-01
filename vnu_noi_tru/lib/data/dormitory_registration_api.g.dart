
part of 'dormitory_registration_api.dart';

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main,avoid_redundant_argument_values

class _DormitoryRegistrationApi implements DormitoryRegistrationApi {
  _DormitoryRegistrationApi(this._dio, {this.baseUrl, this.errorLogger});

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<RegistrationPeriodResponse> getRegistrationPeriods() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<RegistrationPeriodResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
        _dio.options,
        'registration-periods',
        queryParameters: queryParameters,
        data: _data,
      )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late RegistrationPeriodResponse _value;
    try {
      _value = RegistrationPeriodResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<DormitoryListResponse> getDormitories() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<DormitoryListResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
        _dio.options,
        'list',
        queryParameters: queryParameters,
        data: _data,
      )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late DormitoryListResponse _value;
    try {
      _value = DormitoryListResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<RoomTypeListResponse> getRoomTypes() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<RoomTypeListResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
        _dio.options,
        'room-types',
        queryParameters: queryParameters,
        data: _data,
      )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late RoomTypeListResponse _value;
    try {
      _value = RoomTypeListResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<PriorityObjectListResponse> getPriorityObjects() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<PriorityObjectListResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
        _dio.options,
        'priority-objects',
        queryParameters: queryParameters,
        data: _data,
      )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late PriorityObjectListResponse _value;
    try {
      _value = PriorityObjectListResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<MyRegistrationResponse> getMyRegistrations(String studentCode) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _path = '/api/students/${Uri.encodeComponent(studentCode)}';
    final _options = _setStreamType<MyRegistrationResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
        _dio.options,
        _path,
        queryParameters: queryParameters,
        data: _data,
      )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late MyRegistrationResponse _value;
    try {
      _value = MyRegistrationResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<SingleRegistrationResponse> getRegistrationDetail(int id) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<SingleRegistrationResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
        _dio.options,
        'registrations/${id}',
        queryParameters: queryParameters,
        data: _data,
      )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late SingleRegistrationResponse _value;
    try {
      _value = SingleRegistrationResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<UploadedAttachmentListResponse> uploadAttachment(
      int studentId,
      String type,
      List<File> files,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = FormData();
    _data.fields.add(MapEntry('student_id', studentId.toString()));
    _data.fields.add(MapEntry('type', type));
    _data.files.addAll(
      files.map(
            (i) => MapEntry(
          'files[]',
          MultipartFile.fromFileSync(
            i.path,
            filename: i.path.split(Platform.pathSeparator).last,
          ),
        ),
      ),
    );
    final _options = _setStreamType<UploadedAttachmentListResponse>(
      Options(
        method: 'POST',
        headers: _headers,
        extra: _extra,
        contentType: 'multipart/form-data',
      )
          .compose(
        _dio.options,
        'attachments/upload',
        queryParameters: queryParameters,
        data: _data,
      )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late UploadedAttachmentListResponse _value;
    try {
      _value = UploadedAttachmentListResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<SingleRegistrationResponse> registerDormitory(
      RegistrationPayloadModel payload,
      ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(payload.toJson());
    final _options = _setStreamType<SingleRegistrationResponse>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
        _dio.options,
        'registrations',
        queryParameters: queryParameters,
        data: _data,
      )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late SingleRegistrationResponse _value;
    try {
      _value = SingleRegistrationResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override


  @override
  Future<RegistrationHistoryResponse> getRegistrationHistories(int id) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<RegistrationHistoryResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
        _dio.options,
        'registrations/${id}/histories',
        queryParameters: queryParameters,
        data: _data,
      )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late RegistrationHistoryResponse _value;
    try {
      _value = RegistrationHistoryResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(String dioBaseUrl, String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}
