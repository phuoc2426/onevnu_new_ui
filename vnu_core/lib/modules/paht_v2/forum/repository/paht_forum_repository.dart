import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/paht_v2/forum/models/paht_forum_models.dart';
import 'package:vnu_core/modules/paht_v2/ktx/models/ktx_issue_models.dart';
import 'package:vnu_core/modules/paht_v2/ktx/repository/ktx_issue_repository.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/data_repository.dart';
import 'package:vnu_core/services/app_config_service.dart';
import 'package:vnu_core/services/services_url.dart';

class PahtForumApiException implements Exception {
  final String message;
  final int? statusCode;

  const PahtForumApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// API client riêng cho PAHT V2.
///
/// Không dùng Dio core để tránh interceptor của mobile API ghi đè Authorization
/// khi PAHT chạy trên host khác. Mỗi request gắn Bearer token ONEVNU hiện tại,
/// nếu gặp 401 sẽ refresh đúng một lần rồi retry.
class PahtForumRepository {
  PahtForumRepository._internal();

  static final PahtForumRepository _singleton =
      PahtForumRepository._internal();

  factory PahtForumRepository() => _singleton;

  Dio? _dio;
  String _baseUrl = '';
  final KtxIssueRepository _ktxRepository = KtxIssueRepository();
  final Map<int, _KtxResponseCountCacheEntry> _ktxResponseCountCache =
      <int, _KtxResponseCountCacheEntry>{};

  /// Cache GUID -> tên đơn vị từ Mobile API OneVNU. PAHT response có thể chỉ
  /// trả created_by_unit_ref; app resolve ref này nhưng không bao giờ render GUID.
  final Map<String, String> _unitNameCache = <String, String>{};
  bool _unitDirectoryLoaded = false;
  Future<void>? _unitDirectoryLoading;

  static const Duration _ktxCountCacheTtl = Duration(seconds: 20);

  Future<PahtBootstrap> getBootstrap() async {
    final dynamic data = await _get('bootstrap');
    return PahtBootstrap.fromJson(_asMap(data));
  }

  Future<List<PahtForumItem>> getTop({int limit = 3}) async {
    final dynamic data = await _get(
      'student/community/top',
      queryParameters: <String, dynamic>{'limit': limit.clamp(1, 20)},
    );
    final List<PahtForumItem> items = _asList(data)
        .map((Map<String, dynamic> item) => PahtForumItem.fromJson(item))
        .where(_isCommunityVisible)
        .toList(growable: false);
    return _withKtxResponseCounts(items);
  }

  Future<PahtForumPage> getCommunity({
    String search = '',
    int? topicId,
    String status = '',
    String sort = 'recent',
    int page = 0,
    int size = 20,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{
      'sort': sort,
      'page': page,
      'size': size,
    };
    if (search.trim().isNotEmpty) query['search'] = search.trim();
    if (topicId != null) query['topicId'] = topicId;
    if (status.trim().isNotEmpty) query['status'] = status.trim();

    final dynamic data = await _get(
      'student/community',
      queryParameters: query,
    );
    final PahtForumPage resultPage =
        _publicCommunityPage(PahtForumPage.fromJson(_asMap(data)));
    return _withKtxResponseCountsPage(resultPage);
  }

  Future<PahtForumPage> getMine({int page = 0, int size = 20}) async {
    final dynamic data = await _get(
      'student/mine',
      queryParameters: <String, dynamic>{'page': page, 'size': size},
    );
    return _withKtxResponseCountsPage(PahtForumPage.fromJson(_asMap(data)));
  }

  Future<PahtForumPage> getFollowing({int page = 0, int size = 20}) async {
    final dynamic data = await _get(
      'student/interests',
      queryParameters: <String, dynamic>{'page': page, 'size': size},
    );
    // Student following chỉ hiển thị phản ánh PUBLIC. Phản ánh PRIVATE của
    // chính người dùng vẫn xem tại "Phản ánh của tôi"; tuyệt đối không để
    // một PRIVATE cũ còn sót interest xuất hiện ở màn theo dõi.
    final PahtForumPage raw = PahtForumPage.fromJson(_asMap(data));
    final List<PahtForumItem> visible = raw.items
        .where(_isCommunityVisible)
        .toList(growable: false);
    if (visible.length != raw.items.length) {
      logWarning(
        '[PAHT_PRIVACY] student/interests returned PRIVATE items; hidden on Flutter.',
      );
    }
    return _withKtxResponseCountsPage(
      PahtForumPage(
        items: visible,
        total: raw.total,
        page: raw.page,
        size: raw.size,
        totalPages: raw.totalPages,
      ),
    );
  }

  Future<PahtForumDetail> getDetail(String guid) async {
    final dynamic data = await _get('student/feedback/$guid');
    final PahtForumDetail detail = PahtForumDetail.fromJson(_asMap(data));
    final PahtForumDetail withKtx = await _mergeKtxResponses(detail);
    return _resolveResponseUnitNames(withKtx);
  }

  Future<PahtForumDetail> _resolveResponseUnitNames(
    PahtForumDetail detail,
  ) async {
    final bool needsDirectory = detail.responses.any(
      (PahtResponseItem item) =>
          item.sourceSystem != 'KTX' &&
          item.unit.trim().isEmpty &&
          item.unitRef.trim().isNotEmpty,
    );
    if (!needsDirectory) return detail;

    await _ensureUnitDirectory();

    final List<PahtResponseItem> responses = detail.responses.map(
      (PahtResponseItem item) {
        if (item.sourceSystem == 'KTX' || item.unit.trim().isNotEmpty) {
          return item;
        }
        final String ref = item.unitRef.trim().toLowerCase();
        if (ref.isEmpty) return item;
        final String name = _unitNameCache[ref]?.trim() ?? '';
        if (name.isEmpty) {
          logWarning('[PAHT_UNIT] Không resolve được tên đơn vị cho unitRef=${item.unitRef}');
          return item;
        }
        return item.withUnitName(name);
      },
    ).toList(growable: false);

    return PahtForumDetail(
      item: detail.item,
      interested: detail.interested,
      publicLocationMode: detail.publicLocationMode,
      responses: responses,
      timeline: detail.timeline,
      attachments: detail.attachments,
      ktxIssueId: detail.ktxIssueId,
    );
  }

  Future<void> _ensureUnitDirectory() async {
    if (_unitDirectoryLoaded) return;
    final Future<void>? active = _unitDirectoryLoading;
    if (active != null) {
      await active;
      return;
    }

    final Future<void> job = _loadUnitDirectory();
    _unitDirectoryLoading = job;
    try {
      await job;
    } finally {
      _unitDirectoryLoading = null;
    }
  }

  Future<void> _loadUnitDirectory() async {
    try {
      final units = await ApiRepository().getTatCaDonVi();
      for (final unit in units) {
        final String ref = (unit.guid ?? '').trim().toLowerCase();
        final String name = (unit.tenDonVi ?? '').trim();
        if (ref.isNotEmpty && name.isNotEmpty) {
          _unitNameCache[ref] = name;
        }
      }
      _unitDirectoryLoaded = true;
    } catch (error) {
      // Không để lỗi danh mục đơn vị làm hỏng màn chi tiết PAHT. UI sẽ fallback
      // về "Đơn vị xử lý" thay vì hiển thị GUID kỹ thuật.
      logWarning('[PAHT_UNIT] Không tải được danh mục đơn vị: $error');
    }
  }

  /// Detail dùng từ Cộng đồng/Đang theo dõi.
  ///
  /// Backend vẫn là lớp bắt buộc phải kiểm soát quyền. Guard này là lớp thứ hai
  /// trên Flutter để PRIVATE không bao giờ được render nếu API community/detail
  /// trả nhầm dữ liệu. Visibility rỗng được chấp nhận để tương thích public view
  /// cũ vốn không trả field này.
  Future<PahtForumDetail> getPublicDetail(String guid) async {
    final PahtForumDetail detail = await getDetail(guid);
    if (!_isCommunityVisible(detail.item)) {
      logWarning(
        '[PAHT_PRIVACY] PRIVATE feedback blocked from community detail: $guid',
      );
      throw const PahtForumApiException(
        'Phản ánh này không còn được công khai trong cộng đồng.',
        statusCode: 404,
      );
    }
    return detail;
  }

  Future<List<PahtSimilarHit>> getSimilar(
    String query, {
    int topK = 8,
    bool useCache = true,
  }) async {
    final String q = query.trim();
    if (q.length < 15) return <PahtSimilarHit>[];

    final dynamic data = await _get(
      'student/similar',
      queryParameters: <String, dynamic>{
        'q': q,
        'topK': topK.clamp(1, 20),
        'useCache': useCache,
      },
    );
    final Map<String, dynamic> body = _asMap(data);
    final List<PahtSimilarHit> raw = _asList(body['hits'])
        .map((Map<String, dynamic> item) => PahtSimilarHit.fromJson(item))
        .toList(growable: false);

    // Lớp bảo vệ UI: backend v0.4.3 đã dedupe BM25, nhưng Flutter vẫn loại
    // trùng title/topic/area để dữ liệu cũ hoặc cache cũ không lặp trên màn hình.
    final Set<String> seen = <String>{};
    final List<PahtSimilarHit> deduped = <PahtSimilarHit>[];
    for (final PahtSimilarHit item in raw) {
      final String key = '${item.title}|${item.topic}|${item.area}'
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (key.isEmpty || !seen.add(key)) continue;
      deduped.add(item);
      if (deduped.length >= 3) break;
    }
    return deduped;
  }

  Future<PahtInterestResult> setInterest(
    String guid, {
    required bool interested,
  }) async {
    final dynamic data = interested
        ? await _put('student/feedback/$guid/interest')
        : await _delete('student/feedback/$guid/interest');
    return PahtInterestResult.fromJson(_asMap(data));
  }

  Future<Map<String, dynamic>> linkKtxIssue(String guid, int issueId) async {
    if (issueId <= 0) {
      throw const PahtForumApiException('KTX issueId không hợp lệ.');
    }
    final dynamic data = await _post(
      'student/feedback/$guid/external/ktx',
      data: <String, dynamic>{'issueId': issueId},
    );
    final Map<String, dynamic> body = _asMap(data);
    if (body['ok'] != true) {
      throw PahtForumApiException(
        (body['message'] ?? body['error'] ?? 'Chưa liên kết được phản ánh KTX.').toString(),
      );
    }
    return body;
  }

  Future<Map<String, dynamic>> deleteOwnFeedback(String guid) async {
    final dynamic data = await _delete('student/feedback/$guid');
    final Map<String, dynamic> body = _asMap(data);
    if (body['ok'] != true) {
      throw PahtForumApiException(
        (body['message'] ?? body['error'] ?? 'Không thể xóa phản ánh.').toString(),
      );
    }
    return body;
  }

  Future<PahtCreateResult> createFeedback({
    required List<int> topicIds,
    int? areaId,
    required String content,
    required String visibility,
    String locationText = '',
    double? latitude,
    double? longitude,
    String publicLocationMode = 'AREA_ONLY',
    List<Map<String, dynamic>> attachments = const <Map<String, dynamic>>[],
  }) async {
    final List<int> normalizedTopicIds = topicIds
        .where((int id) => id > 0)
        .toSet()
        .take(5)
        .toList(growable: false);
    if (normalizedTopicIds.isEmpty) {
      throw const PahtForumApiException('Vui lòng chọn ít nhất một chủ đề phản ánh.');
    }
    final Map<String, dynamic> body = <String, dynamic>{
      'topicId': normalizedTopicIds.first,
      'topicIds': normalizedTopicIds,
      'title': '',
      'content': content.trim(),
      'visibility': visibility.toUpperCase() == 'PRIVATE' ? 'PRIVATE' : 'PUBLIC',
      'publicLocationMode': publicLocationMode,
    };
    if (areaId != null) body['areaId'] = areaId;
    if (locationText.trim().isNotEmpty) {
      body['locationText'] = locationText.trim();
    }
    if (latitude != null && longitude != null) {
      body['latitude'] = latitude;
      body['longitude'] = longitude;
    }
    if (attachments.isNotEmpty) {
      body['attachments'] = attachments;
    }

    final dynamic data = await _post('student/feedback', data: body);
    return PahtCreateResult.fromJson(_asMap(data));
  }


  Future<PahtForumPage> _withKtxResponseCountsPage(PahtForumPage page) async {
    final List<PahtForumItem> items = await _withKtxResponseCounts(page.items);
    return PahtForumPage(
      items: items,
      total: page.total,
      page: page.page,
      size: page.size,
      totalPages: page.totalPages,
    );
  }

  Future<List<PahtForumItem>> _withKtxResponseCounts(
    List<PahtForumItem> items,
  ) async {
    final List<Future<PahtForumItem>> jobs = items.map((PahtForumItem item) async {
      final int? issueId = item.ktxIssueId;
      if (issueId == null || issueId <= 0) return item;
      final int ktxCount = await _ktxStaffResponseCount(issueId);
      if (ktxCount <= 0) return item;
      return item.copyWithResponseCount(item.responseCount + ktxCount);
    }).toList(growable: false);
    return Future.wait<PahtForumItem>(jobs);
  }

  Future<int> _ktxStaffResponseCount(int issueId) async {
    final DateTime now = DateTime.now();
    final _KtxResponseCountCacheEntry? cached = _ktxResponseCountCache[issueId];
    if (cached != null && now.isBefore(cached.expiresAt)) return cached.count;

    try {
      final KtxIssue issue = await _ktxRepository
          .getIssue(issueId)
          .timeout(const Duration(seconds: 3));
      final int count = issue.comments
          .where((KtxIssueComment item) =>
              !item.fromStudent && item.comment.trim().isNotEmpty)
          .length;
      _ktxResponseCountCache[issueId] = _KtxResponseCountCacheEntry(
        count: count,
        expiresAt: now.add(_ktxCountCacheTtl),
      );
      return count;
    } catch (error) {
      logWarning('[PAHT_KTX_COUNT] Không đọc được KTX issue #$issueId: $error');
      return cached?.count ?? 0;
    }
  }

  Future<PahtForumDetail> _mergeKtxResponses(PahtForumDetail detail) async {
    final int? issueId = detail.ktxIssueId ?? detail.item.ktxIssueId;
    if (issueId == null || issueId <= 0) return detail;

    try {
      final KtxIssue issue = await _ktxRepository.getIssue(issueId);
      final List<PahtResponseItem> merged = <PahtResponseItem>[...detail.responses];
      final Set<String> keys = merged.map(_responseKey).toSet();

      for (final KtxIssueComment comment in issue.comments) {
        if (comment.fromStudent || comment.comment.trim().isEmpty) continue;
        final PahtResponseItem response = PahtResponseItem(
          responseType: 'KTX_REPLY',
          content: comment.comment.trim(),
          unit: comment.senderName.trim().isEmpty
              ? 'Cán bộ KTX'
              : comment.senderName.trim(),
          createdAt: comment.createdAt,
          sourceSystem: 'KTX',
          externalResponseId: comment.id > 0 ? comment.id.toString() : '',
        );
        if (keys.add(_responseKey(response))) merged.add(response);
      }

      merged.sort((PahtResponseItem a, PahtResponseItem b) {
        final DateTime ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
      });

      _ktxResponseCountCache[issueId] = _KtxResponseCountCacheEntry(
        count: issue.comments
            .where((KtxIssueComment item) =>
                !item.fromStudent && item.comment.trim().isNotEmpty)
            .length,
        expiresAt: DateTime.now().add(_ktxCountCacheTtl),
      );
      return detail.copyWithResponses(merged);
    } catch (error) {
      // PAHT detail vẫn hiển thị bình thường nếu KTX tạm lỗi.
      logWarning('[PAHT_KTX_DETAIL] Không ghép được KTX issue #$issueId: $error');
      return detail;
    }
  }

  String _responseKey(PahtResponseItem response) {
    final String source = response.sourceSystem.trim().toUpperCase();
    final String externalId = response.externalResponseId.trim();
    if (source == 'KTX' && externalId.isNotEmpty) return 'KTX:$externalId';
    return '$source|${response.createdAt?.toIso8601String() ?? ''}|${response.content.trim()}';
  }

  bool _isCommunityVisible(PahtForumItem item) {
    // v_public_feed ở một số schema cũ không trả visibility nên giá trị có thể
    // rỗng. Chỉ chặn khi backend nói rõ PRIVATE; PUBLIC/rỗng được phép render.
    return item.visibility.trim().toUpperCase() != 'PRIVATE';
  }

  PahtForumPage _publicCommunityPage(PahtForumPage raw) {
    final List<PahtForumItem> visible = raw.items
        .where(_isCommunityVisible)
        .toList(growable: false);
    if (visible.length != raw.items.length) {
      logWarning(
        '[PAHT_PRIVACY] student/community returned PRIVATE items; hidden on Flutter.',
      );
    }
    return PahtForumPage(
      items: visible,
      // Giữ pagination metadata của server. Backend community phải PUBLIC-only;
      // Flutter chỉ là lớp phòng thủ, không thay thế phân quyền server.
      total: raw.total,
      page: raw.page,
      size: raw.size,
      totalPages: raw.totalPages,
    );
  }

  Future<dynamic> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _with401Retry<dynamic>(() async {
      final String token = await _requireAccessToken();
      final Dio client = await _client();
      final Response<dynamic> response = await client.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: _jsonOptions(token),
      );
      return response.data;
    });
  }

  Future<dynamic> _post(String path, {required dynamic data}) {
    return _with401Retry<dynamic>(() async {
      final String token = await _requireAccessToken();
      final Dio client = await _client();
      final Response<dynamic> response = await client.post<dynamic>(
        path,
        data: data,
        options: _jsonOptions(token),
      );
      return response.data;
    });
  }

  Future<dynamic> _put(String path) {
    return _with401Retry<dynamic>(() async {
      final String token = await _requireAccessToken();
      final Dio client = await _client();
      final Response<dynamic> response = await client.put<dynamic>(
        path,
        options: _jsonOptions(token),
      );
      return response.data;
    });
  }

  Future<dynamic> _delete(String path) {
    return _with401Retry<dynamic>(() async {
      final String token = await _requireAccessToken();
      final Dio client = await _client();
      final Response<dynamic> response = await client.delete<dynamic>(
        path,
        options: _jsonOptions(token),
      );
      return response.data;
    });
  }

  Future<T> _with401Retry<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) {
        throw _mapDioException(error);
      }

      logWarning('[PAHT_V2_AUTH] PAHT trả 401, refresh token 1 lần.');
      final bool refreshed = await _refreshAccessToken();
      if (!refreshed) throw _mapDioException(error);

      try {
        return await request();
      } on DioException catch (retryError) {
        throw _mapDioException(retryError);
      }
    }
  }

  Future<Dio> _client() async {
    await AppConfigService().ensureLoaded();

    final String configured = ServicesUrl().effectivePahtApiUrl.trim();
    if (configured.isEmpty) {
      throw const PahtForumApiException(
        'Chưa có địa chỉ API Phản ánh, góp ý. Vui lòng tải lại cấu hình ứng dụng.',
      );
    }

    final String baseUrl = configured.endsWith('/')
        ? configured
        : '$configured/';

    if (_dio == null || _baseUrl != baseUrl) {
      _dio?.close(force: true);
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          responseType: ResponseType.json,
          headers: const <String, dynamic>{'Accept': 'application/json'},
        ),
      );
      _baseUrl = baseUrl;
      debugPrint('[PAHT_V2] API base URL: $baseUrl');
    }

    return _dio!;
  }

  Options _jsonOptions(String token) {
    return Options(
      contentType: Headers.jsonContentType,
      headers: <String, dynamic>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
  }

  Future<String> _requireAccessToken() async {
    String token = Globals().token.trim();
    if (token.isEmpty) {
      token = (await DataRepository().getSecureSaveKey(kLoginToken))?.trim() ?? '';
      if (token.isNotEmpty) {
        Globals().token = token;
        ApiRepository().setToken(token);
      }
    }

    if (token.isEmpty) {
      throw const PahtForumApiException(
        'Phiên đăng nhập không còn access token. Vui lòng đăng nhập lại.',
        statusCode: 401,
      );
    }
    return token;
  }

  Future<bool> _refreshAccessToken() async {
    try {
      String refreshToken = Globals().refreshToken.trim();
      if (refreshToken.isEmpty) {
        refreshToken =
            (await DataRepository().getSecureSaveKey(kLoginRefreshToken))
                    ?.trim() ??
                '';
      }
      if (refreshToken.isEmpty) return false;

      final response = await ApiRepository().refreshToken(refreshToken);
      final String accessToken = response.accessToken?.trim() ?? '';
      final String newRefreshToken = response.refreshToken?.trim() ?? '';
      if (accessToken.isEmpty) return false;

      Globals().token = accessToken;
      ApiRepository().setToken(accessToken);
      if (newRefreshToken.isNotEmpty) {
        Globals().refreshToken = newRefreshToken;
      }

      final List<Future<void>> writes = <Future<void>>[
        DataRepository().saveSecureKey(kLoginToken, accessToken),
      ];
      if (newRefreshToken.isNotEmpty) {
        writes.add(
          DataRepository().saveSecureKey(
            kLoginRefreshToken,
            newRefreshToken,
          ),
        );
      }
      await Future.wait<void>(writes);
      return true;
    } catch (error, stackTrace) {
      logError('[PAHT_V2_AUTH] Refresh token thất bại: $error\n$stackTrace');
      return false;
    }
  }

  PahtForumApiException _mapDioException(DioException error) {
    final int? status = error.response?.statusCode;
    final dynamic raw = error.response?.data;
    String message = '';
    if (raw is Map) {
      message = (raw['message'] ?? raw['error'] ?? '').toString().trim();
    }

    if (status == 401 || status == 403) {
      return PahtForumApiException(
        message.isEmpty
            ? 'Phiên đăng nhập không có quyền truy cập Phản ánh, góp ý.'
            : message,
        statusCode: status,
      );
    }
    if (status == 404) {
      return PahtForumApiException(
        message.isEmpty ? 'Không tìm thấy phản ánh.' : message,
        statusCode: status,
      );
    }
    if (status != null) {
      return PahtForumApiException(
        message.isEmpty ? 'Máy chủ PAHT trả về lỗi HTTP $status.' : message,
        statusCode: status,
      );
    }
    return const PahtForumApiException(
      'Không kết nối được máy chủ Phản ánh, góp ý.',
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const PahtForumApiException('Dữ liệu PAHT trả về không đúng định dạng.');
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((Map<dynamic, dynamic> item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}



class _KtxResponseCountCacheEntry {
  final int count;
  final DateTime expiresAt;

  const _KtxResponseCountCacheEntry({
    required this.count,
    required this.expiresAt,
  });
}
