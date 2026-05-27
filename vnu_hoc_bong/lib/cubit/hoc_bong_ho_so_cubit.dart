import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/common/log.dart';

import '../repository/hoc_bong_repository.dart';
import 'hoc_bong_states.dart';

class HocBongHoSoCubit extends Cubit<HocBongHoSoState> {
  final HocBongRepository repository;

  HocBongHoSoCubit(this.repository) : super(const HocBongHoSoState());

  Future<void> loadMine() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await repository.getHoSoCuaToi();
      emit(state.copyWith(loading: false, items: items));
    } catch (e) {
      logError('HocBongHoSoCubit.loadMine: $e');
      emit(state.copyWith(loading: false, error: 'Không tải được hồ sơ của tôi'));
    }
  }

  Future<void> loadDetail(int id) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final detail = await repository.getHoSoDetail(id);
      emit(state.copyWith(loading: false, detail: detail));
    } catch (e) {
      logError('HocBongHoSoCubit.loadDetail: $e');
      emit(state.copyWith(loading: false, error: 'Không tải được chi tiết hồ sơ'));
    }
  }

  void setFilter(String filter) => emit(state.copyWith(filter: filter));
}
