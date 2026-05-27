import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/common/log.dart';

import '../repository/hoc_bong_repository.dart';
import 'hoc_bong_states.dart';

class HocBongListCubit extends Cubit<HocBongListState> {
  final HocBongRepository repository;

  HocBongListCubit(this.repository) : super(const HocBongListState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await repository.getHocBongList();
      emit(state.copyWith(loading: false, items: items));
      logSuccess('Loaded ${items.length} học bổng');
    } catch (e) {
      logError('HocBongListCubit.load: $e');
      emit(state.copyWith(loading: false, error: 'Không tải được danh sách học bổng'));
    }
  }

  Future<void> refresh() => load();

  void setFilter(String filter) => emit(state.copyWith(filter: filter));
}
