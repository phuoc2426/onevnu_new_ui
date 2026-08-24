import 'package:vnu_core/common/error/app_error_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/modules/qr/models/qr_resolution.dart';
import 'package:vnu_core/modules/qr/repository/qr_repository.dart';

part 'qr_state.dart';

class QrCubit extends Cubit<QrState> {
  QrCubit({QrRepository? repository})
      : _repository = repository ?? QrRepository(),
        super(QrInitial());

  final QrRepository _repository;

  Future<void> resolve(String rawQr) async {
    if (rawQr.trim().isEmpty || state is QrResolving) return;

    emit(QrResolving());
    try {
      final resolution = await _repository.resolve(rawQr);
      emit(QrResolved(resolution));
    } catch (e) {
      emit(QrFailure(AppErrorMapper.map(e).userMessage));
    }
  }

  Future<void> execute(QrResolution resolution) async {
    emit(QrExecuting(resolution));
    try {
      final result = await _repository.execute(resolution.sessionId);
      emit(QrExecuted(resolution, result));
    } catch (e) {
      emit(QrFailure(AppErrorMapper.map(e).userMessage));
    }
  }

  Future<void> cancel(QrResolution resolution) async {
    try {
      await _repository.cancel(resolution.sessionId);
    } catch (_) {
      // Cancel is best-effort from the mobile UX.
    }
    emit(QrInitial());
  }

  void reset() => emit(QrInitial());
}

