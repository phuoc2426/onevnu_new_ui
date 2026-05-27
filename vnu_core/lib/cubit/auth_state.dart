part of 'auth_cubit.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthShowHub extends AuthState {}

class AuthDismissHub extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthSuccess extends AuthState {
  final LoginResponseModel loginResponseModel;
  AuthSuccess(this.loginResponseModel);
}

class AuthLoadingVanTay extends AuthState {}

class AuthErrorVanTay extends AuthState {
  final String message;
  AuthErrorVanTay(this.message);
}

class AuthSuccessVanTay extends AuthState {
  final LoginResponseModel loginResponseModel;
  AuthSuccessVanTay(this.loginResponseModel);
}

class AuthMessageSucess extends AuthState {
  final String message;
  AuthMessageSucess(this.message);
}
