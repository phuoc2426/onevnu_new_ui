import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/common/log.dart';

import '../repository/hoc_bong_repository.dart';
import 'hoc_bong_states.dart';

class HocBongDetailCubit extends Cubit<HocBongDetailState> {
  final HocBongRepository repository;

  HocBongDetailCubit(this.repository) : super(const HocBongDetailState());

  Future<void> load(int id) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final detail = await repository.getHocBongDetail(id);
      final validate = await repository.validateHocBong(id);
      final draft = await repository.getDraft(id).catchError((_) => null);
      emit(state.copyWith(loading: false, detail: detail, validateResult: validate, draft: draft));
    } catch (e) {
      logError('HocBongDetailCubit.load: $e');
      emit(state.copyWith(loading: false, error: 'Không tải được chi tiết học bổng'));
    }
  }
}
