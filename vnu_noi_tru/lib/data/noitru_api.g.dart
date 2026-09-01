// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'noitru_api.dart';

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main,avoid_redundant_argument_values

class _NoiTruApiProvider implements NoiTruApiProvider {
  _NoiTruApiProvider(this._dio, {this.baseUrl, this.errorLogger});

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<NoitruResponseDomitory<NtDanhSachQtxlModel>> getThongTinQuaTrinhXuLy(
    int MA_Yeu_Cau,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'MA_Yeu_Cau': MA_Yeu_Cau};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options =
        _setStreamType<NoitruResponseDomitory<NtDanhSachQtxlModel>>(
          Options(method: 'POST', headers: _headers, extra: _extra)
              .compose(
                _dio.options,
                'css/thongTinQuaTrinhXuLy',
                queryParameters: queryParameters,
                data: _data,
              )
              .copyWith(
                baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
              ),
        );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late NoitruResponseDomitory<NtDanhSachQtxlModel> _value;
    try {
      _value = NoitruResponseDomitory<NtDanhSachQtxlModel>.fromJson(
        _result.data!,
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<NoitruResponseDomitory<NtDanhSachTrungTamLuuTruModel>>
  getDanhSachTrungTamLuuTru() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options =
        _setStreamType<NoitruResponseDomitory<NtDanhSachTrungTamLuuTruModel>>(
          Options(method: 'GET', headers: _headers, extra: _extra)
              .compose(
                _dio.options,
                'css/danhSachTrungTamLuuTru',
                queryParameters: queryParameters,
                data: _data,
              )
              .copyWith(
                baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
              ),
        );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late NoitruResponseDomitory<NtDanhSachTrungTamLuuTruModel> _value;
    try {
      _value = NoitruResponseDomitory<NtDanhSachTrungTamLuuTruModel>.fromJson(
        _result.data!,
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<NoitruResponseDomitory<NtDanhSachDoiTuongUuTienModel>>
  getDanhSachDoiTuongUuTien() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options =
        _setStreamType<NoitruResponseDomitory<NtDanhSachDoiTuongUuTienModel>>(
          Options(method: 'GET', headers: _headers, extra: _extra)
              .compose(
                _dio.options,
                'css/danhSachDoiTuongUuTien',
                queryParameters: queryParameters,
                data: _data,
              )
              .copyWith(
                baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
              ),
        );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late NoitruResponseDomitory<NtDanhSachDoiTuongUuTienModel> _value;
    try {
      _value = NoitruResponseDomitory<NtDanhSachDoiTuongUuTienModel>.fromJson(
        _result.data!,
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<NoitruResponseDomitory<NtDanhSachPhongModel>> getDanhSachPhong(
    int ID_TrungTamLuuTru,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'ID_TrungTamLuuTru': ID_TrungTamLuuTru,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options =
        _setStreamType<NoitruResponseDomitory<NtDanhSachPhongModel>>(
          Options(method: 'GET', headers: _headers, extra: _extra)
              .compose(
                _dio.options,
                'css/danhSachLoaiPhong',
                queryParameters: queryParameters,
                data: _data,
              )
              .copyWith(
                baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
              ),
        );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late NoitruResponseDomitory<NtDanhSachPhongModel> _value;
    try {
      _value = NoitruResponseDomitory<NtDanhSachPhongModel>.fromJson(
        _result.data!,
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<NoitruResponseDomitory<NtDanhSachDotDangKyLuuTruModel>>
  getDanhSachDotDangKy() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options =
        _setStreamType<NoitruResponseDomitory<NtDanhSachDotDangKyLuuTruModel>>(
          Options(method: 'GET', headers: _headers, extra: _extra)
              .compose(
                _dio.options,
                'css/danhSachDotDangKyLuuTru',
                queryParameters: queryParameters,
                data: _data,
              )
              .copyWith(
                baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
              ),
        );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late NoitruResponseDomitory<NtDanhSachDotDangKyLuuTruModel> _value;
    try {
      _value = NoitruResponseDomitory<NtDanhSachDotDangKyLuuTruModel>.fromJson(
        _result.data!,
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<NoitruResponseDomitory<Object>> luuThongTinDangKy(
    LuuNoiTruRequest request,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(request.toJson());
    final _options = _setStreamType<NoitruResponseDomitory<Object>>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            'css/luuDangKyNoiTru',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late NoitruResponseDomitory<Object> _value;
    try {
      _value = NoitruResponseDomitory<Object>.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<NoitruResponseDomitory<ListPhieuDangKyNoiTruResponse>>
  getDanhSachPhieuDangKy(String CMND_CCCD) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'CMND_CCCD': CMND_CCCD};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options =
        _setStreamType<NoitruResponseDomitory<ListPhieuDangKyNoiTruResponse>>(
          Options(method: 'POST', headers: _headers, extra: _extra)
              .compose(
                _dio.options,
                'css/thongTinPhieuDangKyNoiTru',
                queryParameters: queryParameters,
                data: _data,
              )
              .copyWith(
                baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
              ),
        );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late NoitruResponseDomitory<ListPhieuDangKyNoiTruResponse> _value;
    try {
      _value = NoitruResponseDomitory<ListPhieuDangKyNoiTruResponse>.fromJson(
        _result.data!,
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<NoitruResponseDomitory<NtUrlPresignedModel>> getUrlPresigned(
    String fileName,
    String fileExtension,
    int fileSize,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'fileName': fileName,
      r'fileExtension': fileExtension,
      r'fileSize': fileSize,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options =
        _setStreamType<NoitruResponseDomitory<NtUrlPresignedModel>>(
          Options(method: 'GET', headers: _headers, extra: _extra)
              .compose(
                _dio.options,
                'css/layURLPresigned',
                queryParameters: queryParameters,
                data: _data,
              )
              .copyWith(
                baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
              ),
        );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late NoitruResponseDomitory<NtUrlPresignedModel> _value;
    try {
      _value = NoitruResponseDomitory<NtUrlPresignedModel>.fromJson(
        _result.data!,
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<NoiTruResponse<NtDanhSachTinTucModel>> getDanhSachTinTuc(
    String ID_ChuyenMuc,
    int PageNumber,
    int PageSize,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = {
      'ID_ChuyenMuc': ID_ChuyenMuc,
      'PageNumber': PageNumber,
      'PageSize': PageSize,
    };
    final _options = _setStreamType<NoiTruResponse<NtDanhSachTinTucModel>>(
      Options(
            method: 'POST',
            headers: _headers,
            extra: _extra,
            contentType: 'application/x-www-form-urlencoded',
          )
          .compose(
            _dio.options,
            'api/mobile/tintuc/xemDanhSachTinTuc',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late NoiTruResponse<NtDanhSachTinTucModel> _value;
    try {
      _value = NoiTruResponse<NtDanhSachTinTucModel>.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<NoiTruResponse<NtTinTucModel>> getChiTietTinTuc(int ID_TinTuc) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = {'ID_TinTuc': ID_TinTuc};
    final _options = _setStreamType<NoiTruResponse<NtTinTucModel>>(
      Options(
            method: 'POST',
            headers: _headers,
            extra: _extra,
            contentType: 'application/x-www-form-urlencoded',
          )
          .compose(
            _dio.options,
            'api/mobile/tintuc/chiTietTinTuc',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late NoiTruResponse<NtTinTucModel> _value;
    try {
      _value = NoiTruResponse<NtTinTucModel>.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<NoiTruResponse<NtThongBaoSoLuongChuaDocModel>>
  getThongBaoSoLuongChuaDoc() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options =
        _setStreamType<NoiTruResponse<NtThongBaoSoLuongChuaDocModel>>(
          Options(method: 'GET', headers: _headers, extra: _extra)
              .compose(
                _dio.options,
                'api/mobile/thongbao/soLuongChuaDoc',
                queryParameters: queryParameters,
                data: _data,
              )
              .copyWith(
                baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
              ),
        );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late NoiTruResponse<NtThongBaoSoLuongChuaDocModel> _value;
    try {
      _value = NoiTruResponse<NtThongBaoSoLuongChuaDocModel>.fromJson(
        _result.data!,
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<NoiTruResponse<Object>> danhDauDaDoc(int idD) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = {'ID': idD};
    final _options = _setStreamType<NoiTruResponse<Object>>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            'api/mobile/thongbao/danhDauDaDoc',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late NoiTruResponse<Object> _value;
    try {
      _value = NoiTruResponse<Object>.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<NoiTruResponse<NtDanhSachThongBaoModel>> getDanhSachThongBao(
    String TrangThai,
    int PageNumber,
    int PageSize,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = {
      'TrangThai': TrangThai,
      'PageNumber': PageNumber,
      'PageSize': PageSize,
    };
    final _options = _setStreamType<NoiTruResponse<NtDanhSachThongBaoModel>>(
      Options(
            method: 'POST',
            headers: _headers,
            extra: _extra,
            contentType: 'application/x-www-form-urlencoded',
          )
          .compose(
            _dio.options,
            'api/mobile/thongbao/xemDanhSach',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late NoiTruResponse<NtDanhSachThongBaoModel> _value;
    try {
      _value = NoiTruResponse<NtDanhSachThongBaoModel>.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<NoiTruResponse<NtDanhSachMenuModel>> getDanhSachMenu() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<NoiTruResponse<NtDanhSachMenuModel>>(
      Options(
            method: 'POST',
            headers: _headers,
            extra: _extra,
            contentType: 'application/x-www-form-urlencoded',
          )
          .compose(
            _dio.options,
            'api/mobile/menu/xemDanhSachMenu',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late NoiTruResponse<NtDanhSachMenuModel> _value;
    try {
      _value = NoiTruResponse<NtDanhSachMenuModel>.fromJson(_result.data!);
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

// dart format on
