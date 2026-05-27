import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/repository/app_repository.dart';

part 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit() : super(MapInitial());
  getDanhSachBanDoSo() async {
    // emit(MapLoading());
    // try {
    //   var reponse =
    //       await ApiRepository().xemDSCacLoaiBanDoSo(Globals().maKhuVuc);
    //   if (reponse.resultCode == '0') {
    //     emit(MapLoadedSuccess(reponse.data));
    //   } else {
    //     emit(MapError(reponse.resultMessage ?? ''));
    //   }
    // } catch (e) {
    //   emit(MapError(e.toString()));
    // }
  }
}
