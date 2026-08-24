import '../error/app_error.dart';

enum AppViewStatus {
  initial,
  loading,
  success,
  empty,
  error,
}

class AppViewState<T> {
  const AppViewState._({
    required this.status,
    this.data,
    this.error,
  });

  final AppViewStatus status;
  final T? data;
  final AppError? error;

  const AppViewState.initial() : this._(status: AppViewStatus.initial);

  const AppViewState.loading({T? previousData})
      : this._(status: AppViewStatus.loading, data: previousData);

  const AppViewState.success(T data)
      : this._(status: AppViewStatus.success, data: data);

  const AppViewState.empty()
      : this._(status: AppViewStatus.empty);

  const AppViewState.failure(AppError error, {T? previousData})
      : this._(
          status: AppViewStatus.error,
          data: previousData,
          error: error,
        );

  bool get isLoading => status == AppViewStatus.loading;
  bool get hasData => data != null;
}
