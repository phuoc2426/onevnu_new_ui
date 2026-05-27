import 'package:event_bus/event_bus.dart';

final EventBus globalEvent = EventBus();

class CallingApiErrorEvent {
  final String message;

  CallingApiErrorEvent({required this.message});
}

class TokenExpiredEvent {}

class OpenMenuEvent {}

class FetchMenuSuccess {
  final String? menu;

  FetchMenuSuccess({required this.menu});
}

class SwitchedUserEvent {}

class FetchUnreadEvent {}
