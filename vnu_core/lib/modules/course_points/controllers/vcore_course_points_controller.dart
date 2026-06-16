import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnu_core/common/gpa_cache_manager.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/repository/app_repository.dart';

import '../../../ai_radar/ai/local_ai_radar_engine.dart';
import '../../../ai_radar/cache/ai_axis_cache.dart';
import '../../../ai_radar/embedding/onnx_embedding_model.dart';
import '../../../ai_radar/models/academic_course.dart';
import '../../../ai_radar/models/ai_radar_analysis.dart';
import '../../../globals.dart';
import '../../../models/model.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/extensions/extension_string.dart';

class VcoreCoursePointsController extends GetxController {
  BuildContext? context;

  RxList<String> danhSachKieuTruong = RxList([]);
  Rxn<String> kieuTruong = Rxn();

  RxList<HocKyModel> danhSachHocKy = RxList([]);
  Rxn<HocKyModel> hocKy = Rxn();

  RxList<DiemThiHocKyModel> diemThiHocKy = RxList([]);
  Rxn<DiemTrungBinhModel> diemTrungBinhHocKy = Rxn();
  RxMap<String, List<DiemThiHocKyModel>> diemThiTheoHocKy = RxMap();
  RxList<BrcChungChiModel> chungChis = RxList([]);
  RxString chungChiError = ''.obs;
  RxBool isCheckingDiemSources = false.obs;

  final Map<String, Map<String, dynamic>> _mobileFullCache = {};

  // 0: Điểm học phần, 1: AI phân tích năng lực
  RxInt selectedTabIndex = 0.obs;

  RxBool isTheoChuongTrinhDaoTao = true.obs;

  RefreshController refreshController = RefreshController();

  int pageIndex = 1;
  int pageSize = 20;

  // AI Radar states
  Rxn<AiRadarAnalysis> aiRadarAnalysis = Rxn();
  RxString schoolName = 'Đại học Quốc gia Hà Nội'.obs;
  RxString majorName = 'Ngành đào tạo chưa xác định'.obs;
  RxBool isLoadingAi = false.obs;
  RxString loadingStateText = ''.obs;

  // Chỉ dùng để tránh gọi AI lặp nhiều lần khi user bấm tab AI.
  RxBool hasRequestedAiAnalysis = false.obs;

  late final AiAxisCache _cache = AiAxisCache();

  late final LocalAiRadarEngine _aiEngine = LocalAiRadarEngine(
    embeddingModel: OnnxEmbeddingModel(
      modelAssetPath: 'assets/models/multilingual_e5_small.onnx',
      vocabAssetPath: 'assets/models/tokenizer_vocab.json',
    ),
    cache: _cache,
  );

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    refreshController.dispose();
    super.onClose();
  }

  Future<void> changeKieuTruong(String? displayName) async {
    final selected = danhSachKieuTruong.firstWhereOrNull(
      (e) => e.toDisplayName() == displayName,
    );

    if (selected == null) return;
    if (selected == kieuTruong.value) return;

    kieuTruong.value = selected;

    hocKy.value = null;
    danhSachHocKy.clear();

    diemThiHocKy.clear();
    diemThiTheoHocKy.clear();
    diemTrungBinhHocKy.value = null;
    chungChis.clear();
    chungChiError.value = '';

    aiRadarAnalysis.value = null;
    hasRequestedAiAnalysis.value = false;

    final cached = _mobileFullCache[selected];
    if (cached != null && _hasHocKyData(cached)) {
      _applyMobileFullResponse(cached);
      await _afterApplyFullResponse();
      return;
    }

    await getDanhSachHocKy();
  }

  Future<void> getDanhSachKieuTruong() async {
    kieuTruong.value = null;
    danhSachKieuTruong.clear();
    danhSachHocKy.clear();
    hocKy.value = null;
    diemThiHocKy.clear();
    diemThiTheoHocKy.clear();
    diemTrungBinhHocKy.value = null;
    chungChis.clear();
    chungChiError.value = '';
    aiRadarAnalysis.value = null;
    hasRequestedAiAnalysis.value = false;

    final candidates = <String>['TruongChinh', 'BangKep', 'TruongGui'];

    try {
      Utils.showProgress(context);
      isCheckingDiemSources.value = true;
      _mobileFullCache.clear();

      await _resolveStudentInfo();

      final available = <String>[];

      for (final source in candidates) {
        try {
          final full = await ApiRepository().getDiemSinhVienMobileFull(
            source,
            !isTheoChuongTrinhDaoTao.value,
          );

          if (_hasHocKyData(full)) {
            _mobileFullCache[source] = full;
            available.add(source);
          }
        } catch (e) {
          _mobileFullCache[source] = {'error': e.toString()};
        }
      }

      Utils.dismissProgress(context);
      isCheckingDiemSources.value = false;

      danhSachKieuTruong.value = available;

      if (available.isEmpty) {
        snackBarError('Không tìm thấy dữ liệu điểm ở BRC1, BRC2 hoặc BRC3.');
        return;
      }

      kieuTruong.value = available.contains('TruongChinh')
          ? 'TruongChinh'
          : available.first;

      _applyMobileFullResponse(_mobileFullCache[kieuTruong.value] ?? {});
      await _afterApplyFullResponse();
    } catch (e) {
      Utils.dismissProgress(context);
      isCheckingDiemSources.value = false;
      snackBarError(e.toString());
    }
  }

  Future<void> getDanhSachHocKy() async {
    hocKy.value = null;
    danhSachHocKy.clear();
    diemThiHocKy.clear();
    diemThiTheoHocKy.clear();
    diemTrungBinhHocKy.value = null;
    chungChis.clear();
    chungChiError.value = '';

    if (kieuTruong.value == null || kieuTruong.value!.isEmpty) {
      await getDanhSachKieuTruong();
      return;
    }

    await _loadData();
  }

  void changeHocKy(String? displayName) {
    final obj = danhSachHocKy.firstWhereOrNull(
      (element) => element.disPlayName() == (displayName ?? '_///_'),
    );

    if (obj != null) {
      hocKy.value = obj;
    }
  }

  void refreshData() {
    pageIndex = 1;
    _loadData();
  }

  void loadMoreData() {
    pageIndex += 1;
    _loadData();
  }

  void switchToGradeTab() {
    selectedTabIndex.value = 0;
  }

  void switchToAiTab() {
    selectedTabIndex.value = 1;

    if (aiRadarAnalysis.value != null) return;
    if (isLoadingAi.value) return;
    if (diemThiHocKy.isEmpty) return;
    if (hasRequestedAiAnalysis.value) return;

    hasRequestedAiAnalysis.value = true;
    runAiAnalysis();
  }

  Future<void> _resolveStudentInfo() async {
    final student = Globals().thongTinSinhVienModel.value;

    if (student == null) {
      schoolName.value = 'Đại học Quốc gia Hà Nội';
      majorName.value = 'Ngành đào tạo chưa xác định';
      return;
    }

    try {
      if (student.guidDonVi != null && student.guidDonVi!.isNotEmpty) {
        final donVi = await ApiRepository().getDonVi(student.guidDonVi!);
        schoolName.value = donVi.tenDonVi ?? 'Đại học Quốc gia Hà Nội';
      } else {
        schoolName.value = 'Đại học Quốc gia Hà Nội';
      }
    } catch (_) {
      schoolName.value = 'Đại học Quốc gia Hà Nội';
    }

    try {
      if (student.idNganhDaoTao != null && student.idNganhDaoTao!.isNotEmpty) {
        final listNganh = await ApiRepository().getDataNganhDaoTao(
          student.idNganhDaoTao,
          student.guidDonVi,
          student.idBacDaoTao,
        );

        final nganh = listNganh.firstWhereOrNull(
          (e) => e.id == student.idNganhDaoTao,
        );

        majorName.value = nganh?.ten ?? 'Ngành đào tạo chưa xác định';
      } else {
        majorName.value = 'Ngành đào tạo chưa xác định';
      }
    } catch (_) {
      majorName.value = 'Ngành đào tạo chưa xác định';
    }
  }

  Future<void> _loadData() async {
    diemThiHocKy.value = [];
    aiRadarAnalysis.value = null;
    hasRequestedAiAnalysis.value = false;

    try {
      // Không dùng cache cũ vì API mobile mới trả cấu trúc /full khác pipeline cũ.
      await _loadFromApi();

      refreshController.refreshCompleted();
      refreshController.loadComplete();
    } catch (e) {
      isLoadingAi.value = false;
      Utils.dismissProgress(context);
      refreshController.refreshCompleted();
      refreshController.loadComplete();
      snackBarError(e.toString());
    }
  }

  Future<bool> _loadFromCache(Map<String, dynamic> cachedData) async {
    try {
      if (cachedData['danhSachHocKy'] is List) {
        final List<dynamic> listHk = cachedData['danhSachHocKy'];

        danhSachHocKy.value = listHk
            .map((e) => HocKyModel.fromJson(e as Map<String, dynamic>))
            .toList();

        if (danhSachHocKy.isNotEmpty) {
          final currentHocKyId = hocKy.value?.id;
          final stillAvailable =
              currentHocKyId != null &&
              danhSachHocKy.any((e) => e.id == currentHocKyId);

          if (!stillAvailable) {
            hocKy.value = danhSachHocKy.first;
          }
        }
      }

      if (cachedData['kieuTruong'] is String) {
        kieuTruong.value = cachedData['kieuTruong'];
      }

      if (cachedData['deduplicatedList'] is List) {
        final List<dynamic> listCourses = cachedData['deduplicatedList'];

        final list = listCourses
            .map((e) => DiemThiHocKyModel.fromJson(e as Map<String, dynamic>))
            .toList();

        diemThiHocKy.value = list;

        final Map<String, List<DiemThiHocKyModel>> grouped = {};

        for (final course in list) {
          final hkId = course.idHocKy ?? '';

          if (!grouped.containsKey(hkId)) {
            grouped[hkId] = [];
          }

          grouped[hkId]!.add(course);
        }

        diemThiTheoHocKy.value = grouped;
      }

      final gpa4 = cachedData['gpaHe4']?.toString() ?? '0.00';
      final gpa10 = cachedData['gpaHe10']?.toString() ?? '0.00';
      final tcTichLuy = cachedData['tongTinChi']?.toString() ?? '0';

      diemTrungBinhHocKy.value = DiemTrungBinhModel(
        diemTrungBinhHe4HocKy: gpa4,
        diemTrungBinhHe4TichLuyDenHocKyHienTai: gpa4,
        diemTrungBinhHe10HocKy: gpa10,
        diemTrungBinhHe10TichLuyDenHocKyHienTai: gpa10,
        tongSoTinChiTichLuyHocKy: tcTichLuy,
        tongSoTinChiTichLuyTichLuyDenHocKyHienTai: tcTichLuy,
        tongSoTinChiTruotHocKy: '0',
        tongSoTinChiTruotTichLuyDenHocKyHienTai: '0',
      );

      await _resolveStudentInfo();
      await _loadAiAnalysisFromCacheOnly(diemThiHocKy.toList());

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadFromApi() async {
    Utils.showProgress(context);

    await _resolveStudentInfo();

    final currentSource = kieuTruong.value ?? 'TruongChinh';
    final cached = _mobileFullCache[currentSource];

    final full = cached != null && _hasHocKyData(cached)
        ? cached
        : await ApiRepository().getDiemSinhVienMobileFull(
            currentSource,
            !isTheoChuongTrinhDaoTao.value,
          );

    _mobileFullCache[currentSource] = full;
    _applyMobileFullResponse(full);

    Utils.dismissProgress(context);

    if (danhSachHocKy.isEmpty) {
      throw Exception(
        'Không tìm thấy danh sách học kỳ cho nguồn điểm đang chọn.',
      );
    }

    await _afterApplyFullResponse();
  }

  Future<void> _afterApplyFullResponse() async {
    final deduplicatedList = _deduplicateCourses(
      diemThiTheoHocKy.values.toList(),
    );

    diemThiHocKy.value = deduplicatedList;

    _calculateGpaStatistics(deduplicatedList);

    await _saveCalculatedDataToCache(deduplicatedList);

    await _loadAiAnalysisFromCacheOnly(deduplicatedList);
  }

  bool _hasHocKyData(Map<String, dynamic> full) {
    final hocKys = _asList(full['hocKys'] ?? full['hocKyList']);
    return hocKys.isNotEmpty;
  }

  Future<void> toggleXemCaMonNgoaiCtdt() async {
    isTheoChuongTrinhDaoTao.toggle();
    _mobileFullCache.clear();
    await getDanhSachKieuTruong();
  }

  void _applyMobileFullResponse(Map<String, dynamic> full) {
    final rawHocKys = _asList(full['hocKys'] ?? full['hocKyList']);
    final Map<String, List<DiemThiHocKyModel>> semesterMap = {};

    final parsedHocKys = <HocKyModel>[];

    for (final raw in rawHocKys) {
      if (raw is! Map) continue;

      final hkMap = Map<String, dynamic>.from(raw);

      final idHocKy = _text(hkMap['idHocKy'] ?? hkMap['termId'] ?? hkMap['id']);
      final tenHocKy = _text(
        hkMap['tenHocKy'] ?? hkMap['termName'] ?? hkMap['ten'],
      );
      final namHoc = _text(
        hkMap['namHoc'] ?? hkMap['nam'] ?? hkMap['yearStart'],
      );

      final hk = HocKyModel.fromJson({
        ...hkMap,
        'id': idHocKy,
        'idHocKy': idHocKy,
        'ten': tenHocKy,
        'tenHocKy': tenHocKy,
        'nam': namHoc,
        'namHoc': namHoc,
      });

      parsedHocKys.add(hk);

      final rawCourses = _asList(
        hkMap['diemMonHocs'] ?? hkMap['diemMonHoc'] ?? hkMap['diems'],
      );

      semesterMap[idHocKy] = rawCourses
          .whereType<Map>()
          .map(
            (course) =>
                _parseMobileCourse(Map<String, dynamic>.from(course), idHocKy),
          )
          .toList();
    }

    danhSachHocKy.value = parsedHocKys;

    if (danhSachHocKy.isNotEmpty) {
      final currentHocKyId = hocKy.value?.id;
      final stillAvailable =
          currentHocKyId != null &&
          danhSachHocKy.any((e) => e.id == currentHocKyId);

      hocKy.value = stillAvailable
          ? danhSachHocKy.firstWhere((e) => e.id == currentHocKyId)
          : danhSachHocKy.first;
    }

    diemThiTheoHocKy.value = semesterMap;

    final rawChungChi = _asList(
      full['chungChis'] ?? full['chungChiList'] ?? full['chungChisFromApi'],
    );

    chungChis.value = rawChungChi
        .whereType<Map>()
        .map((e) => BrcChungChiModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    chungChiError.value = '';
  }

  DiemThiHocKyModel _parseMobileCourse(
    Map<String, dynamic> raw,
    String idHocKy,
  ) {
    return DiemThiHocKyModel.fromJson({
      ...raw,
      'idHocKy': idHocKy,
      'idHocPhan': _text(raw['idHocPhan'] ?? raw['crdId'] ?? raw['CRD_ID']),
      'maHocPhan': _text(raw['maHocPhan'] ?? raw['crdCode'] ?? raw['CRD_CODE']),
      'tenHocPhan': _text(
        raw['tenHocPhan'] ?? raw['crdName'] ?? raw['CRD_NAME'],
      ),
      'soTinChi': _text(raw['soTinChi'] ?? raw['numCrd'] ?? raw['NUM_CRD']),
      'diemHe10': _text(
        raw['diemHe10'] ?? raw['pntOfficial'] ?? raw['PNT_OFFICIAL'],
      ),
      'diemHeChu': _text(
        raw['diemChu'] ??
            raw['diemHeChu'] ??
            raw['DIEM_CHU'] ??
            raw['DIEMCHUT'],
      ),
      'diemHe4': _text(raw['diemHe4'] ?? raw['DIEM_HE_4'] ?? raw['DIEM4T']),
    });
  }

  Future<void> reloadChungChi() async {
    final current = kieuTruong.value ?? 'TruongChinh';

    if (_mobileBrcKey(current) == 'brc2') {
      chungChis.clear();
      chungChiError.value = 'BRC2 không có chứng chỉ theo logic ASP.';
      return;
    }

    try {
      final response = await ApiRepository().getChungChiMobile(current);

      chungChis.value = response
          .map((e) => BrcChungChiModel.fromJson(e))
          .toList();

      chungChiError.value = '';
    } catch (e) {
      chungChiError.value = e.toString();
      chungChis.clear();
    }
  }

  String _mobileBrcKey(String kieuTruong) {
    switch (kieuTruong) {
      case 'BangKep':
        return 'brc2';
      case 'TruongGui':
        return 'brc3';
      case 'TruongChinh':
      default:
        return 'brc1';
    }
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return [];
  }

  String _text(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  List<DiemThiHocKyModel> _deduplicateCourses(
    List<List<DiemThiHocKyModel>> results,
  ) {
    final uniqueCourses = <String, DiemThiHocKyModel>{};

    for (final list in results) {
      for (final course in list) {
        final name = course.tenHocPhan?.trim() ?? '';

        if (name.isEmpty) continue;

        final key = '${course.maHocPhan?.trim() ?? ''}_$name';
        final existing = uniqueCourses[key];

        if (existing == null) {
          uniqueCourses[key] = course;
        } else {
          final existingGrade =
              double.tryParse(existing.diemHe10?.replaceAll(',', '.') ?? '') ??
              0.0;

          final currentGrade =
              double.tryParse(course.diemHe10?.replaceAll(',', '.') ?? '') ??
              0.0;

          if (currentGrade > existingGrade) {
            uniqueCourses[key] = course;
          }
        }
      }
    }

    return uniqueCourses.values.toList();
  }

  void _calculateGpaStatistics(List<DiemThiHocKyModel> deduplicatedList) {
    double totalCredits = 0;
    double weightedGrade10 = 0;
    double weightedGrade4 = 0;
    int tcTichLuy = 0;
    int tcTruot = 0;

    for (final course in deduplicatedList) {
      final grade10 = double.tryParse(
        course.diemHe10?.replaceAll(',', '.') ?? '',
      );

      final grade4 = double.tryParse(
        course.diemHe4?.replaceAll(',', '.') ?? '',
      );

      final credits = double.tryParse(
        course.soTinChi?.replaceAll(',', '.') ?? '',
      );

      if (grade10 == null || credits == null) continue;

      weightedGrade10 += grade10 * credits;

      if (grade4 != null) {
        weightedGrade4 += grade4 * credits;
      }

      totalCredits += credits;

      if (grade10 >= 4.0) {
        tcTichLuy += credits.round();
      } else {
        tcTruot += credits.round();
      }
    }

    final gpa10 = totalCredits > 0 ? (weightedGrade10 / totalCredits) : 0.0;
    final gpa4 = totalCredits > 0 ? (weightedGrade4 / totalCredits) : 0.0;

    diemTrungBinhHocKy.value = DiemTrungBinhModel(
      diemTrungBinhHe4HocKy: gpa4.toStringAsFixed(2),
      diemTrungBinhHe4TichLuyDenHocKyHienTai: gpa4.toStringAsFixed(2),
      diemTrungBinhHe10HocKy: gpa10.toStringAsFixed(2),
      diemTrungBinhHe10TichLuyDenHocKyHienTai: gpa10.toStringAsFixed(2),
      tongSoTinChiTichLuyHocKy: tcTichLuy.toString(),
      tongSoTinChiTichLuyTichLuyDenHocKyHienTai: tcTichLuy.toString(),
      tongSoTinChiTruotHocKy: tcTruot.toString(),
      tongSoTinChiTruotTichLuyDenHocKyHienTai: tcTruot.toString(),
    );
  }

  Future<void> _saveCalculatedDataToCache(
    List<DiemThiHocKyModel> deduplicatedList,
  ) async {
    try {
      final gpa = diemTrungBinhHocKy.value;

      final data = {
        'gpaHe4': double.tryParse(gpa?.diemTrungBinhHe4HocKy ?? '0') ?? 0.0,
        'gpaHe10': double.tryParse(gpa?.diemTrungBinhHe10HocKy ?? '0') ?? 0.0,
        'tongTinChi': int.tryParse(gpa?.tongSoTinChiTichLuyHocKy ?? '0') ?? 0,
        'soKyDaHoc': danhSachHocKy.length,
        'deduplicatedList': deduplicatedList.map((e) => e.toJson()).toList(),
        'danhSachHocKy': danhSachHocKy.map((e) => e.toJson()).toList(),
        'kieuTruong': kieuTruong.value ?? '',
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bg_cached_gpa_data', jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _loadAiAnalysisFromCacheOnly(
    List<DiemThiHocKyModel> courses,
  ) async {
    if (courses.isEmpty) {
      aiRadarAnalysis.value = null;
      hasRequestedAiAnalysis.value = false;
      return;
    }

    final signature = buildCourseSignature(courses);

    final cacheKey = AiAxisCache.buildKey(
      school: schoolName.value,
      major: majorName.value,
    );

    final cachedSig = await _cache.getSignature(cacheKey);
    final cachedAnalysis = await _cache.getAnalysis(cacheKey);

    if (cachedSig == signature && cachedAnalysis != null) {
      aiRadarAnalysis.value = cachedAnalysis;
    } else {
      aiRadarAnalysis.value = null;
      hasRequestedAiAnalysis.value = false;
    }
  }

  String buildCourseSignature(List<DiemThiHocKyModel> list) {
    return list
        .map((e) {
          final name = e.tenHocPhan?.trim() ?? '';
          final grade = e.diemHe10?.trim() ?? '';
          final credits = e.soTinChi?.trim() ?? '';
          return '${name}_${grade}_$credits';
        })
        .join('|');
  }

  Future<void> runAiAnalysis() async {
    final deduplicatedList = diemThiHocKy.toList();

    if (deduplicatedList.isEmpty) {
      snackBarError('Không tìm thấy học phần để phân tích.');
      return;
    }

    hasRequestedAiAnalysis.value = true;
    isLoadingAi.value = true;

    try {
      loadingStateText.value = 'AI đang xác định ngành học...';
      await Future.delayed(const Duration(milliseconds: 500));

      loadingStateText.value = 'AI đang thiết kế bộ mũi nhọn theo ngành...';
      await Future.delayed(const Duration(milliseconds: 500));

      loadingStateText.value =
          'AI đang chấm điểm học phần lên từng mũi nhọn...';
      await Future.delayed(const Duration(milliseconds: 500));

      loadingStateText.value = 'AI đang vẽ radar...';
      await Future.delayed(const Duration(milliseconds: 500));

      final academicCourses = deduplicatedList.map((e) {
        final grade =
            double.tryParse(e.diemHe10?.replaceAll(',', '.') ?? '') ?? 0.0;

        final credits =
            double.tryParse(e.soTinChi?.replaceAll(',', '.') ?? '') ?? 3.0;

        return AcademicCourse(
          name: e.tenHocPhan ?? 'Học phần không tên',
          grade: grade,
          credits: credits,
          description: e.maHocPhan != null
              ? 'Mã học phần: ${e.maHocPhan}'
              : null,
        );
      }).toList();

      final analysis = await _aiEngine.analyze(
        school: schoolName.value,
        major: majorName.value,
        courses: academicCourses,
      );

      final cacheKey = AiAxisCache.buildKey(
        school: schoolName.value,
        major: majorName.value,
      );

      final signature = buildCourseSignature(deduplicatedList);

      await _cache.saveAnalysis(cacheKey, signature, analysis);

      aiRadarAnalysis.value = analysis;
    } catch (e) {
      hasRequestedAiAnalysis.value = false;
      snackBarError(e.toString());
    } finally {
      isLoadingAi.value = false;
    }
  }
}

class BrcChungChiModel {
  final String trangThai;
  final String ctfId;
  final String tenChungChi;
  final String moTa;
  final String soQuyetDinh;
  final String ngayQuyetDinh;

  const BrcChungChiModel({
    required this.trangThai,
    required this.ctfId,
    required this.tenChungChi,
    required this.moTa,
    required this.soQuyetDinh,
    required this.ngayQuyetDinh,
  });

  factory BrcChungChiModel.fromJson(Map<String, dynamic> json) {
    final trangThai = _string(json['trangThai'] ?? json['status']);
    final soQuyetDinh = _string(
      json['soQuyetDinh'] ?? json['soQD'] ?? json['So_QD'],
    );
    final hasPassed =
        trangThai.toLowerCase().contains('đạt') ||
        trangThai.toLowerCase().contains('dat') ||
        soQuyetDinh.isNotEmpty ||
        _string(json['stdId'] ?? json['Std_id'] ?? json['STD_ID']).isNotEmpty;

    return BrcChungChiModel(
      trangThai: trangThai.isNotEmpty
          ? trangThai
          : (hasPassed ? 'Đạt' : 'Chưa đạt'),
      ctfId: _string(
        json['ctfId'] ?? json['ctfID'] ?? json['idChungChi'] ?? json['CTF_ID'],
      ),
      tenChungChi: _string(
        json['tenChungChi'] ?? json['ctfName'] ?? json['CTF_NAME'],
      ),
      moTa: _string(json['moTa'] ?? json['ctfDesc'] ?? json['CTF_DESC']),
      soQuyetDinh: soQuyetDinh,
      ngayQuyetDinh: _string(
        json['ngayQuyetDinh'] ?? json['ngayQD'] ?? json['Ngay_QD'],
      ),
    );
  }

  bool get daDat {
    final s = trangThai.toLowerCase();
    return s.contains('đạt') || s.contains('dat') || soQuyetDinh.isNotEmpty;
  }

  static String _string(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }
}
