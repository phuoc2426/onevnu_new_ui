part of 'dormitory_payment_cubit.dart';

sealed class DormitoryPaymentState {
  const DormitoryPaymentState();
}

class DormitoryPaymentInitial extends DormitoryPaymentState {
  const DormitoryPaymentInitial();
}

class DormitoryPaymentLoading extends DormitoryPaymentState {
  const DormitoryPaymentLoading();
}

class DormitoryPaymentLoaded extends DormitoryPaymentState {
  final List<DormitoryInvoiceModel> invoices;
  final List<DormitoryPaymentMethodModel> methods;

  const DormitoryPaymentLoaded({
    required this.invoices,
    required this.methods,
  });
}

class DormitoryPaymentUploading extends DormitoryPaymentState {
  final double progress;

  const DormitoryPaymentUploading(this.progress);
}

class DormitoryPaymentUploadSuccess extends DormitoryPaymentState {
  final String message;

  const DormitoryPaymentUploadSuccess(this.message);
}

class DormitoryPaymentError extends DormitoryPaymentState {
  final String message;

  const DormitoryPaymentError(this.message);
}
