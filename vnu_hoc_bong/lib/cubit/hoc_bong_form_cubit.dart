import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/gpa_cache_manager.dart';

import '../models/hoc_bong_models.dart';
import '../repository/hoc_bong_repository.dart';
import 'hoc_bong_states.dart';

class HocBongFormCubit extends Cubit<HocBongFormState> {
  final HocBongRepository repository;
  final int hocBongId;
  Timer? _autoSaveTimer;

  HocBongFormCubit(this.repository, this.hocBongId) : super(const HocBongFormState());

  Future<void> init() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final detail = await repository.getHocBongDetail(hocBongId);
      final draft = await repository.getDraft(hocBongId).catchError((_) => null);
      final localDraft = await repository.readLocalDraft(hocBongId);
      final localPending = await repository.readLocalPendingFiles(hocBongId);
      HocBongValidateResultModel? validateResult;
      try {
        validateResult = await repository.validateHocBong(hocBongId);
      } catch (_) {}
      
      final values = <String, dynamic>{};
      bool isDirty = false;
      if (draft != null) values.addAll(draft.duLieuDangKy);
      if (localDraft != null && localDraft.isNotEmpty) {
        values.addAll(localDraft);
        isDirty = true;
      }

      final pendingFiles = <String, String>{};
      if (localPending != null && localPending.isNotEmpty) {
        pendingFiles.addAll(localPending);
        isDirty = true;
      }

      emit(state.copyWith(
        loading: false,
        detail: detail,
        draft: draft,
        values: values,
        pendingFilePaths: pendingFiles,
        dirty: isDirty,
        validateResult: validateResult,
      ));
    } catch (e) {
      logError('HocBongFormCubit.init: $e');
      emit(state.copyWith(loading: false, error: 'Không tải được form đăng ký'));
    }
  }

  void updateField(String key, dynamic value) {
    final next = Map<String, dynamic>.from(state.values)..[key] = value;
    emit(state.copyWith(values: next, dirty: true));
    repository.saveLocalDraft(hocBongId, next);
  }

  void setPendingFile(String key, String path) {
    final next = Map<String, String>.from(state.pendingFilePaths)..[key] = path;
    emit(state.copyWith(pendingFilePaths: next, dirty: true));
    repository.saveLocalPendingFiles(hocBongId, next);
  }

  Future<void> uploadFileForField(HocBongFormFieldModel field, File file) async {
    setPendingFile(field.maTruong, file.path);
  }

  Future<void> submit() async {
    emit(state.copyWith(submitting: true, error: null, message: null));
    try {
      double? gpa = state.validateResult?.gpaHe4TuTinh;
      int? tongTinChi = state.validateResult?.tongTinChiTinhGpa;
      final ketQuaValidate = state.validateResult?.result;

      final cachedGpa = await GpaCacheManager.getCachedGpaData();
      if (cachedGpa != null) {
        if (gpa == null || gpa == 0.0) {
          gpa = cachedGpa['gpaHe4'] as double?;
        }
        if (tongTinChi == null || tongTinChi == 0) {
          tongTinChi = cachedGpa['tongTinChi'] as int?;
        }
      }

      // Step 1: Create or update draft on the server to get/update the hoSo ID
      HocBongHoSoModel draft;
      if (state.draft?.id != null && state.draft!.id > 0) {
        draft = await repository.updateDraft(
          state.draft!.id,
          hocBongId,
          state.values,
          gpa: gpa,
          tongTinChi: tongTinChi,
          ketQuaValidate: ketQuaValidate,
        );
      } else {
        draft = await repository.saveDraft(
          hocBongId,
          state.values,
          gpa: gpa,
          tongTinChi: tongTinChi,
          ketQuaValidate: ketQuaValidate,
        );
      }

      // Step 2: Upload all local pending files to the server
      for (final entry in state.pendingFilePaths.entries) {
        final field = state.detail?.formFields.where((e) => e.maTruong == entry.key).firstOrNull;
        if (field != null) {
          await repository.uploadMinhChung(
            hoSoId: draft.id,
            file: File(entry.value),
            formFieldId: field.id,
            tenMinhChung: field.displayLabel,
          );
        }
      }

      // Step 3: Final submission
      final submitted = await repository.submitHoSo(draft.id);
      await repository.clearLocalDraft(hocBongId);
      await repository.clearLocalPendingFiles(hocBongId);
      emit(state.copyWith(
        submitting: false,
        draft: submitted,
        pendingFilePaths: {},
        dirty: false,
        message: 'Đã gửi hồ sơ đăng ký',
      ));
    } catch (e) {
      logError('HocBongFormCubit.submit: $e');
      emit(state.copyWith(
        submitting: false,
        error: 'Không gửi được hồ sơ. Vui lòng kiểm tra lại thông tin.',
      ));
    }
  }

  Future<void> saveBeforeLeave() async {
    // No-op: Do not save to server on leave anymore.
  }

  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    return super.close();
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
