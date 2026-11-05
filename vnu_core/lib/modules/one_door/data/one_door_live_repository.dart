import 'package:vnu_core/modules/one_door/data/one_door_demo_repository.dart';
import 'package:vnu_core/modules/one_door/data/one_door_live_api.dart';

/// The server accepted the POST and returned a registration ID, but the
/// follow-up GET failed. Never suggest resubmitting a potentially saved case.
class OneDoorSubmittedButDetailUnavailable implements Exception {
  const OneDoorSubmittedButDetailUnavailable(this.registrationId);
  final String registrationId;
}

/// Resolved procedure details with traceable delivery option provenance.
/// No backend IDs are fabricated when the lookup is unavailable.
class OneDoorResolvedDetail {
  const OneDoorResolvedDetail({
    required this.procedure,
    this.deliveryFromLookup = false,
    this.deliveryWarning,
  });
  final OneDoorProcedure procedure;
  final bool deliveryFromLookup;
  final String? deliveryWarning;
}

/// Public unit item from the documented /public/thu-tuc/theo-cap schema.
class OneDoorUnitOption {
  const OneDoorUnitOption({required this.id, required this.name, this.level});
  final int id;
  final String name;
  final int? level;
}

enum OneDoorProcedureGroup { school, university, unclassified }

/// Uses authoritative IDs from /theo-cap, never a guessed capDonVi number.
class OneDoorScopeCatalog {
  const OneDoorScopeCatalog({required this.universityId,
    required this.universityName, required this.schools,
    required this.universityProcedureIds});
  final int? universityId;
  final String universityName;
  final List<OneDoorUnitOption> schools;
  final Set<String> universityProcedureIds;

  String? nameOfUnit(int? id) {
    if (id == null) return null;
    if (id == universityId) return universityName;
    for (final school in schools) {
      if (school.id == id) return school.name;
    }
    return null;
  }

  OneDoorProcedureGroup groupOf(OneDoorProcedure p) {
    if (universityProcedureIds.contains(p.id) ||
        (universityId != null && p.unitId == universityId)) {
      return OneDoorProcedureGroup.university;
    }
    if (p.unitId != null && schools.any((school) => school.id == p.unitId)) {
      return OneDoorProcedureGroup.school;
    }
    return OneDoorProcedureGroup.unclassified;
  }
}

/// One Door user data adapter. Never seeds synthetic records.
class OneDoorLiveRepository implements OneDoorRepository {
  OneDoorLiveRepository(this._api);
  final OneDoorLiveApi _api;

  String _str(Map<String,dynamic> o,String key) => o[key]?.toString() ?? '';
  int _int(dynamic o) => o is num ? o.round() : int.tryParse('$o') ?? 0;
  Map<String,dynamic> _obj(dynamic raw) {
    if (raw is! Map) return <String,dynamic>{};
    var item = Map<String,dynamic>.from(raw);
    for (var i=0; i<2; i++) {
      final nested=item['data'] ?? item['result'];
      if (nested is! Map) break;
      item=Map<String,dynamic>.from(nested);
    }
    return item;
  }
  List<Map<String,dynamic>> _array(dynamic raw) => raw is List
    ? raw.whereType<Map>().map(_obj).toList() : <Map<String,dynamic>>[];

  OneDoorProcedure _procedure(Map<String,dynamic> data) {
    final deliveries=<String,String>{};
    for (final h in _array(data['hinhThucs'])) {
      final id=_str(h,'idHinhThuc');
      final name=_str(h,'tenHinhThuc');
      if (id.isNotEmpty && name.isNotEmpty) deliveries[name]=id;
    }
    return OneDoorProcedure(
      id:_str(data,'idThuTuc'),
      name:_str(data,'tenThuTuc'),
      domain:_str(data,'tenLinhVuc'),
      processingDays:_int(data['thoiGianThucHien']),
      fee:_int(data['lePhi']),
      hasFee:data['lePhi'] != null,
      hasProcessingDays:data['thoiGianThucHien'] != null,
      unitId: data['idDV'] == null ? null : _int(data['idDV']),
      unitName: _str(data, 'tenDonVi'),
      unitLevel: data['capDonVi'] == null ? null : _int(data['capDonVi']),
      unitLevelName: _str(data, 'capDonViText'),
      audience: _str(data, 'tenDoiTuong'),
      papers:_array(data['giayTos']).map((m)=>OneDoorPaper(
        _str(m,'idGiayTo'),_str(m,'tenGiayTo'),
        isRequired:m['batBuoc']==true,
        hasTemplate:m['coFileMau']==true)).toList(),
      deliveryMethods: deliveries,
    );
  }

  OneDoorRecordStatus _status(Map<String,dynamic> row) {
    final value=_str(row,'trangThaiText').toLowerCase();
    if (value.contains('bổ sung') || value.contains('bo sung')) {
      return OneDoorRecordStatus.supplement;
    }
    if (value.contains('hoàn thành') || value.contains('hoan thanh')) {
      return OneDoorRecordStatus.completed;
    }
    if (value.contains('hủy') || value.contains('huy')) {
      return OneDoorRecordStatus.cancelled;
    }
    if (value.contains('từ chối') || value.contains('tu choi')) {
      return OneDoorRecordStatus.rejected;
    }
    return OneDoorRecordStatus.processing;
  }

  OneDoorRecord _record(Map<String,dynamic> row,{OneDoorProcedure? procedure}) {
    final history=<OneDoorActivity>[];
    for (final item in _array(row['lichSuXuLys'])) {
      final date=DateTime.tryParse(_str(item,'thoiGian'));
      if (date==null) continue;
      history.add(OneDoorActivity(
        title:_str(item,'moTaQuyTrinh'),time:date,
        note:_str(item,'lyDo')));
    }
    final papers=<String,String>{};
    for (final item in _array(row['giayToNops'])) {
      final key=_str(item,'idGiayTo');
      if (key.isNotEmpty && item['daNop']==true) {
        papers[key]=_str(item,'tenFile');
      }
    }
    final p=procedure ?? OneDoorProcedure(
      id:_str(row,'idThuTuc'),name:_str(row,'tenThuTuc'),
      domain:'',processingDays:0,fee:0,papers:const <OneDoorPaper>[]);
    return OneDoorRecord(
      id:_str(row,'idDangKy'),procedure:p,
      createdAt:DateTime.tryParse(_str(row,'ngayDangKy')) ?? DateTime.now(),
      requestText:_str(row,'yeuCau'),
      deliveryMethod:_str(row,'hinhThucNhanKetQua'),
      quantity:_int(row['soLuongBan'])>0?_int(row['soLuongBan']):1,
      paperFileNames:papers,status:_status(row),
      reason:_str(row,'lyDo'),history:history,
    );
  }

  Future<List<Map<String,dynamic>>> _loadPages(Future<dynamic> Function(int) action) async {
    final result=<Map<String,dynamic>>[];
    for (var page=1;page<=40;page++) {
      final data=_obj(await action(page));
      final batch=_array(data['items']);
      result.addAll(batch);
      final more=data['hasNextPage'];
      if (more != true || batch.isEmpty) return result;
      if (page == 40) {
        throw StateError('One Door has more results than the safe paging limit');
      }
    }
    return result;
  }

  @override
  Future<List<OneDoorProcedure>> listProcedures() async {
    final rows=await _loadPages((page)=>_api.listProcedures(page:page,pageSize:100));
    return rows.map(_procedure).where((p)=>p.id.isNotEmpty).toList();
  }

  /// The One Door OpenAPI spells the structure out explicitly; do not
  /// substitute hard-coded lists of universities or guessed capDonVi values.
  OneDoorScopeCatalog parseProcedureCatalog(dynamic raw) {
    final data = _obj(raw);
    final university = data['daiHocQuocGia'];
    final schoolsRaw = data['truongs'];
    if (university is! Map || schoolsRaw != null && schoolsRaw is! List) {
      throw const FormatException('Phân cấp thủ tục không đúng cấu trúc OpenAPI.');
    }
    final idRaw = university['idDonVi'];
    final universityId = idRaw == null ? null : _int(idRaw);
    final universityName = university['tenDonVi']?.toString().trim() ?? '';
    final schools = <OneDoorUnitOption>[];
    final seen = <int>{};
    for (final entry in schoolsRaw is List ? schoolsRaw : const <dynamic>[]) {
      if (entry is! Map || entry['idDonVi'] == null) continue;
      final id = _int(entry['idDonVi']);
      final name = entry['tenDonVi']?.toString().trim() ?? '';
      if (id <= 0 || name.isEmpty || !seen.add(id)) continue;
      schools.add(OneDoorUnitOption(
        id: id, name: name,
        level: entry['capDonVi'] == null ? null : _int(entry['capDonVi']),
      ));
    }
    schools.sort((a,b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final ids = <String>{};
    for (final item in data['thuTucDaiHocQuocGia'] is List
        ? data['thuTucDaiHocQuocGia'] as List : const <dynamic>[]) {
      if (item is! Map) continue;
      final id = item['idThuTuc']?.toString().trim() ?? '';
      if (id.isNotEmpty) ids.add(id);
    }
    if (universityId == null && schools.isEmpty && ids.isEmpty) {
      throw const FormatException('Phân cấp thủ tục chưa có ID đơn vị.');
    }
    return OneDoorScopeCatalog(
      universityId: universityId,
      universityName: universityName.isNotEmpty ? universityName : 'ĐHQGHN',
      schools: schools,
      universityProcedureIds: ids,
    );
  }

  Future<OneDoorScopeCatalog> procedureCatalog() async =>
      parseProcedureCatalog(await _api.procedureCatalog());

  /// Identify the CURRENT student's institution from the authenticated
  /// /nganh-cua-toi response. It exposes tenDonVi and dangChon, not idDonVi.
  /// Match one unique unit name to /theo-cap; ambiguous/unmatched => null.
  /// Do not infer another university from abbreviations or old local prefs.
  OneDoorUnitOption? parseCurrentSchool(
      dynamic raw, OneDoorScopeCatalog catalog) {
    dynamic rows = raw;
    for (var i = 0; i < 2 && rows is Map; i++) {
      rows = rows['data'] ?? rows['result'] ?? rows['items'];
    }
    if (rows is! List) {
      throw const FormatException('Danh sách ngành của tôi không hợp lệ.');
    }
    String canonical(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final selectedNames = <String>{};
    final allNames = <String>{};
    for (final row in rows) {
      if (row is! Map) continue;
      final name = canonical((row['tenDonVi'] ?? '').toString());
      if (name.isEmpty) continue;
      allNames.add(name);
      if (row['dangChon'] == true) selectedNames.add(name);
    }
    final candidates = selectedNames.isNotEmpty ? selectedNames : allNames;
    if (candidates.length != 1) return null;
    final matching = catalog.schools.where((unit) =>
        canonical(unit.name) == candidates.single).toList();
    return matching.length == 1 ? matching.single : null;
  }

  Future<OneDoorUnitOption?> currentSchool(OneDoorScopeCatalog catalog) async =>
      parseCurrentSchool(await _api.myAcademicMajors(), catalog);

  /// Extra label fields for an editable letter, not assumed identifiers.
  /// Never insert an internal ID in place of a user-visible program name.
  Future<Map<String, String>> letterAcademicFields() async {
    final raw = await _api.myAcademicMajors();
    dynamic rows = raw;
    for (var i = 0; i < 2 && rows is Map; i++) {
      rows = rows['data'] ?? rows['result'] ?? rows['items'];
    }
    if (rows is! List) return const <String, String>{};
    final options = rows.whereType<Map>().toList();
    if (options.isEmpty) return const <String, String>{};
    final selected = options.where((row) => row['dangChon'] == true).toList();
    final row = selected.length == 1 ? selected.first :
      (options.length == 1 ? options.first : null);
    if (row == null) return const <String, String>{};
    return <String, String>{
      'He': (row['tenHe'] ?? '').toString().trim(),
      'NganhHoc': (row['tenNganh'] ?? '').toString().trim(),
    };
  }

  Future<OneDoorTemplateFile> downloadPaperTemplate(String paperId) =>
      _api.paperTemplate(paperId);

  /// Official form already merged by server; content is view-only unless the
  /// backend supplies a document-editing contract.
  Future<OneDoorTemplateFile> downloadPrefilledPaper(String paperId) =>
      _api.paperTemplate(paperId, prefilled: true);

  /// Use the exact same decoder for the inspected raw GET as regular detail.
  OneDoorProcedure parseProcedureResponse(dynamic raw) => _procedure(_obj(raw));

  /// A missing/null/wrong-type `giayTos` is NOT the same as an empty list.
  bool hasCompletePaperList(dynamic raw) => _obj(raw)['giayTos'] is List;

  /// Only a true [] triggers the full delivery lookup. A missing/null/
  /// malformed field is not treated as an empty per-procedure list.
  bool needsDeliveryLookup(dynamic procedureRaw) {
    final raw = _obj(procedureRaw)['hinhThucs'];
    return raw is List && raw.isEmpty;
  }

  /// Decode the real lookup payload without assuming whether the API returns
  /// a root array or wraps it in data/result/items/hinhThucs.
  /// Preserve all distinct backend IDs even if two labels are identical.
  Map<String, String> parseDeliveryLookup(dynamic response) {
    dynamic payload = response;
    for (var depth = 0; depth < 6 && payload is! List; depth++) {
      if (payload is! Map) break;
      dynamic next;
      for (final key in const <String>[
        'items', 'hinhThucs', 'data', 'result', 'results', 'list', 'danhSach',
      ]) {
        final candidate = payload[key];
        if (candidate is List || candidate is Map) {
          next = candidate;
          break;
        }
      }
      if (next == null) break;
      payload = next;
    }
    if (payload is! List) {
      throw const FormatException('Lookup hình thức nhận không trả danh sách hợp lệ.');
    }

    final options = <String, String>{};
    final seenIds = <String>{};
    for (final item in payload) {
      if (item is! Map) continue;
      final id = (item['idHinhThuc'] ?? item['idHinhThucNhanKetQua'] ??
        item['id'] ?? item['value'])?.toString().trim() ?? '';
      final name = (item['tenHinhThuc'] ?? item['tenHinhThucNhanKetQua'] ??
        item['ten'] ?? item['name'] ?? item['label'])?.toString().trim() ?? '';
      if (id.isEmpty || name.isEmpty || !seenIds.add(id)) continue;
      var label = name;
      var suffix = 2;
      while (options.containsKey(label)) {
        label = '$name ($suffix)';
        suffix++;
      }
      options[label] = id;
    }
    return options;
  }

  OneDoorResolvedDetail resolveDeliveryLookup({
    required OneDoorProcedure procedure,
    required dynamic procedureRaw,
    dynamic lookupRaw,
    String? lookupFailure,
  }) {
    if (!needsDeliveryLookup(procedureRaw)) {
      return OneDoorResolvedDetail(procedure: procedure);
    }
    if (lookupFailure != null || lookupRaw == null) {
      return OneDoorResolvedDetail(procedure: procedure,
        deliveryWarning: lookupFailure ?? 'Danh mục hình thức nhận chưa sẵn sàng.');
    }
    Map<String, String> allOptions;
    try {
      allOptions = parseDeliveryLookup(lookupRaw);
    } on FormatException {
      return OneDoorResolvedDetail(procedure: procedure,
        deliveryWarning: 'Dữ liệu danh mục hình thức nhận không đúng cấu trúc.');
    }
    if (allOptions.isEmpty) {
      return OneDoorResolvedDetail(procedure: procedure,
        deliveryWarning: 'Danh mục hình thức nhận không có ID hợp lệ.');
    }
    return OneDoorResolvedDetail(deliveryFromLookup: true,
      procedure: OneDoorProcedure(
        id: procedure.id,
        name: procedure.name,
        domain: procedure.domain,
        processingDays: procedure.processingDays,
        fee: procedure.fee,
        papers: procedure.papers,
        description: procedure.description,
        deliveryMethods: allOptions,
        unitId: procedure.unitId,
        unitName: procedure.unitName,
        unitLevel: procedure.unitLevel,
        unitLevelName: procedure.unitLevelName,
        audience: procedure.audience,
        hasFee: procedure.hasFee,
        hasProcessingDays: procedure.hasProcessingDays,
      ),
    );
  }

  /// Production path: fetch the lookup only for explicit empty hinhThucs.
  /// A lookup failure leaves the detail readable, but prevents invalid POSTs.
  Future<OneDoorResolvedDetail> detailProcedureResolved(String id) async {
    final raw = await _api.procedure(id);
    if (!hasCompletePaperList(raw)) {
      throw const FormatException('Missing or invalid giayTos in One Door detail');
    }
    final procedure = parseProcedureResponse(raw);
    if (procedure.id != id) {
      throw const FormatException('One Door detail ID did not match requested ID');
    }
    if (!needsDeliveryLookup(raw)) {
      return OneDoorResolvedDetail(procedure: procedure);
    }
    try {
      final lookup = await _api.lookup('hinh-thuc-nhan-ket-qua');
      return resolveDeliveryLookup(
        procedure: procedure, procedureRaw: raw, lookupRaw: lookup);
    } catch (_) {
      return resolveDeliveryLookup(
        procedure: procedure, procedureRaw: raw,
        lookupFailure: 'Không tải được danh mục hình thức nhận. Hãy thử tải lại.',
      );
    }
  }

  /// Keep the older method contract available for existing call sites.
  Future<OneDoorProcedure> detailProcedure(String id) async =>
      (await detailProcedureResolved(id)).procedure;

  @override
  Future<List<OneDoorRecord>> myRecords() async {
    final rows=await _loadPages((page)=>_api.myRecords(page:page,pageSize:100));
    return rows.map((row)=>_record(row)).where((r)=>r.id.isNotEmpty).toList();
  }

  Future<OneDoorRecord> detailRecord(String id,{OneDoorProcedure? procedure}) async {
    return _record(_obj(await _api.record(id)),procedure:procedure);
  }

  Future<void> checkSubmissionConditions(String procedureId) async {
    final data = _obj(await _api.conditions(procedureId));
    final tuition = _obj(data['noHocPhi']);
    if (tuition['vuotMuc'] == true) {
      throw StateError('One Door does not allow submission due to tuition debt');
    }
  }

  @override
  Future<OneDoorRecord> submit({required OneDoorProcedure procedure,
      required String requestText,required String deliveryMethod,
      required int quantity,required Map<String,String> papers}) async {
    final deliveryId=procedure.deliveryMethods[deliveryMethod];
    if (deliveryId==null) throw StateError('Chưa chọn hình thức nhận hợp lệ của Một cửa.');
    if (quantity < 1) throw ArgumentError('Invalid number of copies');
    await checkSubmissionConditions(procedure.id);
    final response=_obj(await _api.submit(
      procedureId:procedure.id,request:requestText,
      deliveryMethodId:deliveryId,quantity:quantity,filesByPaperId:papers));
    final id=_str(response,'idDangKy');
    if (id.isEmpty) throw const FormatException('Một cửa không trả idDangKy');
    try {
      return await detailRecord(id,procedure:procedure);
    } catch (_) {
      // This is NOT a failed submission; the server already returned idDangKy.
      throw OneDoorSubmittedButDetailUnavailable(id);
    }
  }

  @override
  Future<void> cancel(OneDoorRecord record) async {
    await _api.cancel(record.id);
    record.status=OneDoorRecordStatus.cancelled;
  }

  @override
  Future<void> supplement(OneDoorRecord record,String note,Map<String,String> papers) async {
    await _api.supplement(record.id,note:note,filesByPaperId:papers);
    record.status=OneDoorRecordStatus.processing;
    record.reason='';
  }
}
