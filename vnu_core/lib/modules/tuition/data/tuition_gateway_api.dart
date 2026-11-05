import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import 'package:vnu_core/modules/tuition/data/tuition_student_payable_query.dart';
import 'package:vnu_core/modules/tuition/data/tuition_api_diagnostics.dart';

/// Issued ONLY by an authenticated ONEVNU server bridge; never store an API
/// key or allow the mobile client to choose studentCode / universityId.
class TuitionGatewaySession {
  const TuitionGatewaySession({required this.accessToken,
    required this.canonicalStudentId, required this.universityId,
    this.expiresAtUtc});
  final String accessToken;
  final String canonicalStudentId;
  final int universityId;
  final DateTime? expiresAtUtc;
  bool get isValid => universityId == 4 && accessToken.trim().isNotEmpty &&
    canonicalStudentId.trim().isNotEmpty &&
    (expiresAtUtc == null || expiresAtUtc!.isAfter(DateTime.now().toUtc()));
  bool get expiresSoon => expiresAtUtc != null &&
    !expiresAtUtc!.isAfter(DateTime.now().toUtc().add(const Duration(seconds: 45)));
}

class TuitionPaymentRequest {
  const TuitionPaymentRequest({required this.id, required this.status,
    this.imageBase64, this.payload, this.expiresAt, this.updatedAt, this.provider});
  final String id;
  final String status;
  final String? imageBase64;
  final String? payload;
  final DateTime? expiresAt;
  final DateTime? updatedAt;
  /// Gateway/provider display metadata only; never used for payment routing.
  final String? provider;
  bool get terminal => const <String>{'PAID','EXPIRED','CANCELLED'}
      .contains(status.toUpperCase());

  factory TuitionPaymentRequest.fromJson(Map<String, dynamic> data) {
    final rawQr=data['qr'];
    final qr=rawQr is Map ? Map<String, dynamic>.from(rawQr)
        : <String,dynamic>{};
    return TuitionPaymentRequest(
      id: (data['paymentRequestId'] ?? data['id'] ?? '').toString(),
      status: (data['status'] ?? 'PENDING').toString().toUpperCase(),
      imageBase64: (qr['imageBase64'] ?? data['qrImageBase64'])?.toString(),
      payload: (qr['payload'] ?? data['qrPayload'])?.toString(),
      provider: (qr['provider'] ?? data['bankName'] ??
          data['paymentProvider'] ?? data['paymentMethod'])?.toString(),
      expiresAt: DateTime.tryParse(data['expiresAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse((data['updatedAt'] ?? data['processedAt'] ??
          data['paidAt'])?.toString() ?? ''),
    );
  }

  TuitionPaymentRequest merge(TuitionPaymentRequest? previous) =>
      TuitionPaymentRequest(
        id: id, status: status,
        imageBase64: (imageBase64?.isNotEmpty ?? false)
            ? imageBase64 : previous?.imageBase64,
        payload: (payload?.isNotEmpty ?? false) ? payload : previous?.payload,
        expiresAt: expiresAt ?? previous?.expiresAt,
        updatedAt: updatedAt ?? previous?.updatedAt,
        provider: (provider?.isNotEmpty ?? false) ? provider : previous?.provider,
      );
}

class TuitionPaymentCancellation {
  const TuitionPaymentCancellation({required this.request,
    required this.lockReleased,required this.lockAttention,
    required this.replayed});
  final TuitionPaymentRequest request;
  final bool lockReleased;
  final bool lockAttention;
  final bool replayed;
}

/// Raised if a forced session refresh belongs to another student/account.
/// The caller must clear visible old-account payment information immediately.
class TuitionGatewayIdentityMismatchException implements Exception {
  const TuitionGatewayIdentityMismatchException();
  @override
  String toString() => 'Tuition session identity mismatch';
}

/// /cp1 requires a student-scoped Bearer token. No X_API_KEY is used here.
/// Writes are not automatically repeated after HTTP 401 or network failures.
class TuitionGatewayApi {
  TuitionGatewayApi(TuitionGatewaySession session, {
      Dio? dio, Future<TuitionGatewaySession> Function()? renewSession})
      : _session=session,
        _renewSession=renewSession,
        _dio=dio ?? Dio(BaseOptions(
          baseUrl:'https://onevnu-admin-api.vnu.edu.vn/ulis-tuition/api/v1',
          connectTimeout:const Duration(seconds:20),
          receiveTimeout:const Duration(seconds:20),
        )) {
    if (!session.isValid) {
      throw StateError('Only a valid ULIS gateway session is accepted');
    }
  }

  TuitionGatewaySession _session;
  /// Identity returned by the trusted backend; used ONLY to namespace RAM cache.
  String get canonicalStudentId => _session.canonicalStudentId;
  final Dio _dio;
  final Future<TuitionGatewaySession> Function()? _renewSession;
  Future<TuitionGatewaySession>? _refreshInFlight;
  bool _forceRenew=false;
  final Map<String,String> _createKeys=<String,String>{};
  final Map<String,String> _recreateKeys=<String,String>{};
  final Map<String,TuitionPaymentRequest> _knownRequests=
      <String,TuitionPaymentRequest>{};

  Options get _options => Options(headers:<String,String>{
    'Authorization':'Bearer ${_session.accessToken}',
    // Flutter Web: avoid two unnecessary CORS-preflight request headers.
    // Native retains the V6 no-cache policy; all platforms still require
    // Cache-Control: no-store in the server RESPONSE.
    if (!kIsWeb) 'Cache-Control':'no-store',
    if (!kIsWeb) 'Pragma':'no-cache',
  });

  Future<void> _renew() async {
    final renew=_renewSession;
    if (renew==null) throw StateError('Gateway session expired; reopen payment');
    _refreshInFlight ??= renew();
    try {
      final fresh=await _refreshInFlight!;
      if (!fresh.isValid || fresh.universityId!=_session.universityId ||
          fresh.canonicalStudentId!=_session.canonicalStudentId) {
        throw const TuitionGatewayIdentityMismatchException();
      }
      _session=fresh;
      _forceRenew=false;
    } finally {
      _refreshInFlight=null;
    }
  }

  /// Explicit UI refresh bypasses the RAM session cache, while retaining
  /// this API instance's request snapshots and idempotency keys. The backend
  /// may issue a NEW ULIS token; this never refreshes the ONEVNU login JWT.
  Future<void> refreshSession() async {
    _forceRenew = true;
    TuitionApiDiagnostics.instance.record('SESSION_REFRESH', 'START');
    try {
      await _renew();
      TuitionApiDiagnostics.instance.record('SESSION_REFRESH', 'OK');
    } catch (_) {
      TuitionApiDiagnostics.instance.record('SESSION_REFRESH', 'FAILED');
      rethrow;
    }
  }

  Future<Response<dynamic>> _send(
      Future<Response<dynamic>> Function(Options options) action, {
      required String stage, bool safeGet=false}) async {
    final trace = TuitionApiDiagnostics.instance;
    final watch = Stopwatch()..start();
    trace.record(stage, 'START');
    try {
      if (_session.expiresSoon || _forceRenew) await _renew();
      Response<dynamic> result;
      try {
        result = await action(_options);
      } on DioException catch (error) {
        if (error.response?.statusCode != 401) rethrow;
        _forceRenew = true;
        if (!safeGet || _renewSession == null) rethrow;
        trace.record(stage, 'RETRY_AFTER_401', statusCode: 401,
          elapsedMs: watch.elapsedMilliseconds);
        await _renew();
        result = await action(_options);
      }
      trace.record(stage, 'OK', statusCode: result.statusCode,
        elapsedMs: watch.elapsedMilliseconds);
      return result;
    } on DioException catch (error) {
      trace.record(stage, 'FAILED', statusCode: error.response?.statusCode,
        elapsedMs: watch.elapsedMilliseconds,
        note: error.type.name);
      if (kIsWeb && stage == 'PAYABLE' &&
          error.type == DioExceptionType.connectionError &&
          error.response == null) {
        // Web masks CORS/preflight failures as a transport error. Only the
        // browser Network tab can distinguish CORS, TLS and unreachable host.
        // Never log tokens, student IDs, QR payloads or full request URLs.
        trace.record('PAYABLE_WEB', 'CHECK_NETWORK',
          note: 'inspect_OPTIONS_and_GET_in_Chrome_DevTools;'
            'possible_CORS_TLS_or_network');
      }
      rethrow;
    } catch (_) {
      trace.record(stage, 'FAILED', elapsedMs: watch.elapsedMilliseconds,
        note: 'client_exception');
      rethrow;
    }
  }

  Future<Map<String,dynamic>> _payablePage({
      required TuitionStudentPayableQuery query,
      required int limit,String? cursor}) async {
    // Always request the whole receivable feed, including locked / paid rows.
    // Treat schema errors differently from a valid but temporarily empty page.
    final response=await _send((opt)=>_dio.get<dynamic>(
      '/cp1/students/${Uri.encodeComponent(_session.canonicalStudentId)}/payable',
      queryParameters:query.asQueryParameters(limit:limit,cursor:cursor),
      options:opt),
      safeGet:true, stage:'PAYABLE');
    final trace=TuitionApiDiagnostics.instance;
    try {
      final page=_strictPayablePage(response.data);
      final rows=page['items'] as List<dynamic>;
      // Diagnostic metadata is intentionally limited to shapes and counts.
      // Never log the response body, IDs, QR contents or authentication tokens.
      final rawTotal=page['totalCount']??page['total'];
      final total=int.tryParse(rawTotal?.toString()??'');
      final upstreamTrace = response.headers.value('x-request-id') ??
          response.headers.value('x-correlation-id');
      // Log ONLY structural metadata and an opaque request/correlation ID.
      // Never log token, studentId, receivable IDs, bank payload or amounts.
      final cleanedTrace = upstreamTrace?.replaceAll(
          RegExp(r'[^a-zA-Z0-9._:-]'), '') ?? '';
      final traceId = cleanedTrace.isEmpty ? 'absent' :
          (cleanedTrace.length > 64
              ? cleanedTrace.substring(0, 64) : cleanedTrace);
      trace.record('PAYABLE_SHAPE', rows.isEmpty?'EMPTY':'ROWS',
        note:'format=${page['_shape']};items=${rows.length};'
          'next=${page['nextCursor']==null?0:1};'
          'total=${total==null?'unknown':(total==0?'zero':'positive')};'
          'fullFeed=${!query.payableOnly};queryPayableOnly=${query.payableOnly ? 'true' : 'omitted'};gatewayRequestId=$traceId');
      if (rows.isEmpty && page['nextCursor'] == null &&
          total != null && total > 0) {
        // A non-empty declared total with no rows and no continuation is a
        // broken snapshot: never treat it as a verified zero balance.
        throw const FormatException('empty_page_positive_total');
      }
      return page;
    } on FormatException catch (error) {
      trace.record('PAYABLE_SHAPE', 'MALFORMED',
        note:error.message); // Messages below are fixed codes only.
      rethrow;
    }
  }

  Future<List<Map<String,dynamic>>> payable({bool payableOnly=false,
      int limit=50,String? cursor,String? termId,
      String? collectionPeriodCode}) async {
    final data=await _payablePage(
      query:TuitionStudentPayableQuery(
        payableOnly:payableOnly,termId:termId,
        collectionPeriodCode:collectionPeriodCode),
      limit:limit,cursor:cursor);
    final items=data['items'] as List<dynamic>; // validated by parser
    return items.map((item)=>Map<String,dynamic>.from(item as Map)).toList();
  }

  /// Do not silently drop pages or non-object rows. A corrupt/partial page
  /// must never become a false "no debt" conclusion.
  Future<List<Map<String,dynamic>>> payableAll({bool payableOnly=false,
      int pageSize=50,String? termId,String? collectionPeriodCode}) async {
    final result=<Map<String,dynamic>>[];
    final query=TuitionStudentPayableQuery(payableOnly:payableOnly,
      termId:termId,collectionPeriodCode:collectionPeriodCode);
    String? cursor;
    final seen=<String>{};
    for(var page=0; page<40; page++) {
      final data=await _payablePage(query:query,
          limit:pageSize,cursor:cursor);
      final items=data['items'] as List<dynamic>; // validated by parser
      result.addAll(items.map((item)=>Map<String,dynamic>.from(item as Map)));
      final next=data['nextCursor']?.toString();
      if(next==null||next.isEmpty) return result;
      if(!seen.add(next)) throw const FormatException('cursor_loop');
      cursor=next;
    }
    throw const FormatException('paging_limit_exceeded');
  }

  /// Seed the QR snapshot returned by GET payable(activePaymentRequest).
  /// GET /payment-requests/{id} may omit qr; the next status() merges with
  /// this provider-issued snapshot. NEVER generate a QR from amount/bill ID.
  TuitionPaymentRequest rememberHistoricalRequest(Map<String,dynamic> historical) {
    return rememberActiveRequest(historical);
  }

  TuitionPaymentRequest rememberActiveRequest(Map<String,dynamic> active) {
    final raw = Map<String,dynamic>.from(active);
    final id = (raw['paymentRequestId'] ??
      raw['activePaymentRequestId'] ?? raw['id'])?.toString() ?? '';
    if (id.isEmpty) {
      throw const FormatException('activePaymentRequest has no ID');
    }
    raw['paymentRequestId'] = id;
    return _remember(raw);
  }

  TuitionPaymentRequest _remember(Map<String,dynamic> data) {
    final request=TuitionPaymentRequest.fromJson(data);
    if(request.id.isEmpty) {
      throw const FormatException('Gateway did not return paymentRequestId');
    }
    final merged=request.merge(_knownRequests[request.id]);
    _knownRequests[request.id]=merged;
    return merged;
  }

  /// Stable key per receivable while the create result is ambiguous. Explicit
  /// gateway acceptance or an existing active request clears this key.
  Future<TuitionPaymentRequest> create(String receivableId) async {
    final id=receivableId.trim();
    if(id.isEmpty) throw ArgumentError('receivableId required');
    final key=_createKeys.putIfAbsent(id,()=>const Uuid().v4());
    try {
      final response=await _send((opt)=>_dio.post<dynamic>(
        '/cp1/payment-requests',data:<String,dynamic>{
          'receivableId':id,'idempotencyKey':key,
        },options:opt), stage:'CREATE_REQUEST');
      final r=_remember(_paymentMap(response.data));
      _createKeys.remove(id);
      return r;
    } on DioException catch (error) {
      if(error.response?.statusCode!=409) rethrow;
      final data=_paymentMap(error.response?.data);
      final code=(data['error']??data['code'])?.toString()??'';
      if(!const <String>{'PAYMENT_REQUEST_ACTIVE','ACTIVE_REQUEST_EXISTS'}
          .contains(code)) rethrow;
      final details=data['details'];
      final active=details is Map ? (details['activePaymentRequestId']??
          details['paymentRequestId'])?.toString() : null;
      if(active==null||active.isEmpty) rethrow;
      _createKeys.remove(id);
      TuitionApiDiagnostics.instance.record('CREATE_REQUEST', 'ACTIVE_REQUEST',
        statusCode:409);
      return status(active);
    }
  }

  Future<TuitionPaymentRequest> status(String requestId) async {
    final response=await _send((opt)=>_dio.get<dynamic>(
      '/cp1/payment-requests/${Uri.encodeComponent(requestId)}',options:opt),
      safeGet:true, stage:'CHECK_STATUS');
    final raw=_paymentMap(response.data);
    final status = raw['status']?.toString().toUpperCase();
    if (!const <String>{'PENDING', 'PROCESSING', 'PAID',
        'EXPIRED', 'CANCELLED'}.contains(status)) {
      throw const FormatException('Invalid payment request status');
    }
    raw.putIfAbsent('paymentRequestId',()=>requestId);
    return _remember(raw);
  }

  /// POST /cp1/payment-requests/{id}/cancel (student owns this request).
  /// Do not retry POST automatically after 401 / timeout. The caller must
  /// explicitly confirm; CP1 may locally invalidate provider artifacts while
  /// still awaiting CP6 lock release.
  Future<TuitionPaymentCancellation> cancel(String requestId,
      {String? reason}) async {
    final response=await _send((opt)=>_dio.post<dynamic>(
      '/cp1/payment-requests/${Uri.encodeComponent(requestId)}/cancel',
      data:<String,dynamic>{
        if (reason!=null && reason.trim().isNotEmpty) 'reason':reason.trim(),
      },options:opt),stage:'CANCEL_REQUEST');
    final data=_paymentMap(response.data);
    final resultId=(data['paymentRequestId']??'').toString();
    if(resultId!=requestId ||
        data['status']?.toString().toUpperCase()!='CANCELLED') {
      throw const FormatException('Invalid cancellation response');
    }
    final cancellation=TuitionPaymentCancellation(
      request:_remember(data),
      lockReleased:data['lockReleased']==true,
      lockAttention:data['lockAttention']==true,
      replayed:data['replayed']==true,
    );
    return cancellation;
  }

  Future<TuitionPaymentRequest> recreate(String requestId) async {
    // Never recreate a paid or still-active payment, even if UI is stale.
    final current=await status(requestId);
    if(!const <String>{'EXPIRED','CANCELLED'}.contains(current.status)) {
      throw StateError('Only expired/cancelled requests can be recreated');
    }
    final key=_recreateKeys.putIfAbsent(requestId,()=>const Uuid().v4());
    try {
      final response=await _send((opt)=>_dio.post<dynamic>(
        '/cp1/payment-requests/${Uri.encodeComponent(requestId)}/recreate',
        data:<String,dynamic>{'idempotencyKey':key},options:opt),
        stage:'RECREATE_REQUEST');
      final r=_remember(_paymentMap(response.data));
      _recreateKeys.remove(requestId);
      return r;
    } on DioException catch (error) {
      if (error.response?.statusCode != 409) rethrow;
      final data=_paymentMap(error.response?.data);
      final code=(data['error'] ?? data['result_code'] ?? data['code'])
          ?.toString().toUpperCase();
      if (!const <String>{'ACTIVE_REQUEST_EXISTS','PAYMENT_REQUEST_ACTIVE'}
          .contains(code)) rethrow;
      final details=data['details'];
      final newId=details is Map
          ? (details['activePaymentRequestId'] ??
              details['paymentRequestId'])?.toString()
          : null;
      if (newId == null || newId.isEmpty || newId == requestId) rethrow;
      _recreateKeys.remove(requestId);
      return status(newId);
    }
  }
}

Map<String,dynamic> _paymentMap(dynamic raw) {
  if(raw is! Map) throw const FormatException('Invalid payment response');
  var data=Map<String,dynamic>.from(raw);
  for(var i=0;i<2;i++) {
    final nested=data['data']??data['result'];
    if(nested is! Map) break;
    data=Map<String,dynamic>.from(nested);
  }
  return data;
}


/// Strictly separates an empty CP1 payable page from an unrecognized HTTP 200
/// JSON shape. The CP1 documented page uses `items`; we also accept transparent
/// `data` / `result` envelopes, including a direct list. Unknown schemas fail
/// loudly so they can be fixed against the real gateway contract.
Map<String,dynamic> _strictPayablePage(dynamic raw) {
  dynamic node=raw;
  dynamic nextCursor;
  dynamic totalCount;
  for(var depth=0;depth<4;depth++) {
    if(node is List) {
      if(node.any((item)=>item is! Map)) {
        throw const FormatException('non_object_items');
      }
      return <String,dynamic>{
        'items':node,'nextCursor':nextCursor,'totalCount':totalCount,
        '_shape':depth==0?'root_list':'wrapped_list',
      };
    }
    if(node is! Map) throw const FormatException('non_object_page');
    final page=Map<String,dynamic>.from(node);
    // Some proxies send HTTP 200 with an application-level failure. It is
    // NOT a successful empty feed even if an empty items array is present.
    if (page['success'] == false || page['ok'] == false ||
        (page['status']?.toString().toUpperCase() == 'ERROR')) {
      throw const FormatException('application_level_failure');
    }
    // If backend exposes completeness/health metadata, obey it. An incomplete
    // HTTP 200 page must not authorize new payments from apparently available
    // rows (and must not masquerade as an authoritative empty snapshot).
    final health = page['sourceHealth']?.toString().toUpperCase();
    if (page['snapshotComplete'] == false ||
        const <String>{'DEGRADED', 'PARTIAL', 'UNAVAILABLE', 'DOWN', 'ERROR'}
            .contains(health)) {
      throw const FormatException('upstream_snapshot_incomplete');
    }
    if(page.containsKey('nextCursor')) nextCursor=page['nextCursor'];
    if(page.containsKey('totalCount')) totalCount=page['totalCount'];
    if(page['items'] is List) {
      final items=page['items'] as List<dynamic>;
      if(items.any((item)=>item is! Map)) {
        throw const FormatException('non_object_items');
      }
      return <String,dynamic>{
        ...page,
        'nextCursor':page['nextCursor']??nextCursor,
        'totalCount':page['totalCount']??totalCount,
        '_shape':depth==0?'items_root':'items_wrapped',
      };
    }
    if(page.containsKey('items')) {
      throw const FormatException('items_not_list');
    }
    final nested=page['data']??page['result'];
    if(nested==null) throw const FormatException('items_missing');
    node=nested;
  }
  throw const FormatException('envelope_too_deep');
}
