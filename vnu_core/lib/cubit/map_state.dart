part of 'map_cubit.dart';

@immutable
abstract class MapState {}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapShowHub extends MapState {}

class MapDismissHub extends MapState {}

class MapError extends MapState {
  final String message;
  MapError(this.message);
}

class MapLoadedSuccess extends MapState {
  final BanDoSoModel banDoSo;
  MapLoadedSuccess(this.banDoSo);
}
