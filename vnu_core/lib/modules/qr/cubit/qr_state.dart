part of 'qr_cubit.dart';

@immutable
abstract class QrState {}

class QrInitial extends QrState {}

class QrResolving extends QrState {}

class QrResolved extends QrState {
  QrResolved(this.resolution);
  final QrResolution resolution;
}

class QrExecuting extends QrState {
  QrExecuting(this.resolution);
  final QrResolution resolution;
}

class QrExecuted extends QrState {
  QrExecuted(this.resolution, this.result);
  final QrResolution resolution;
  final QrExecutionResult result;
}

class QrFailure extends QrState {
  QrFailure(this.message);
  final String message;
}
