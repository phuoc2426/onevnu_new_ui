import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_noi_tru/models/dormitory_payment/dormitory_invoice_model.dart';
import 'package:vnu_noi_tru/models/dormitory_payment/dormitory_payment_method_model.dart';
import 'package:vnu_noi_tru/repository/dormitory_payment_repository.dart';

part 'dormitory_payment_state.dart';

class DormitoryPaymentCubit extends Cubit<DormitoryPaymentState> {
  DormitoryPaymentCubit() : super(const DormitoryPaymentInitial());

  final DormitoryPaymentRepository _repository =
      DormitoryPaymentRepository();

  /// Tên biến giữ nguyên để không phải đổi toàn bộ giao diện cũ.
  /// Dữ liệu thực tế hiện được lấy từ API receipts.
  List<DormitoryInvoiceModel> invoices = <DormitoryInvoiceModel>[];

  List<DormitoryPaymentMethodModel> paymentMethods =
      <DormitoryPaymentMethodModel>[];

  Future<void> loadData({
    required String identityNo,
    required int dormitoryId,
  }) async {
    if (isClosed) {
      return;
    }

    emit(const DormitoryPaymentLoading());

    try {
      try {
        final DormitoryInvoiceResponse response =
            await _repository.getReceipts(
          identityNo: identityNo,
        );

        invoices = response.invoices;
      } catch (error) {
        if (_isApiNotAvailable(error)) {
          invoices = <DormitoryInvoiceModel>[];
        } else {
          rethrow;
        }
      }

      try {
        final DormitoryPaymentMethodResponse response =
            await _repository.getPaymentMethods(
          dormitoryId: dormitoryId,
        );

        paymentMethods = response.methods
            .where(
              (DormitoryPaymentMethodModel item) => item.active,
            )
            .toList();
      } catch (_) {
        // API phương thức thanh toán lỗi thì vẫn hiển thị biên lai.
        paymentMethods = <DormitoryPaymentMethodModel>[];
      }

      if (isClosed) {
        return;
      }

      emit(
        DormitoryPaymentLoaded(
          invoices: invoices,
          methods: paymentMethods,
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      emit(DormitoryPaymentError(_cleanError(error)));
    }
  }

  Future<bool> uploadProof({
    required String identityNo,
    required Object receiptId,
    required File proofImage,
    required int dormitoryId,
    String? note,
  }) async {
    if (isClosed) {
      return false;
    }

    try {
      emit(const DormitoryPaymentUploading(0));

      final Map<String, dynamic> response =
          await _repository.uploadPaymentProof(
        identityNo: identityNo,
        receiptId: receiptId,
        proofImage: proofImage,
        note: note,
        onSendProgress: (int sent, int total) {
          if (total <= 0 || isClosed) {
            return;
          }

          emit(DormitoryPaymentUploading(sent / total));
        },
      );

      if (isClosed) {
        return false;
      }

      final String message = _responseMessage(response) ??
          'Đã gửi minh chứng chuyển khoản, chờ kế toán xác nhận.';

      emit(DormitoryPaymentUploadSuccess(message));

      await loadData(
        identityNo: identityNo,
        dormitoryId: dormitoryId,
      );

      return true;
    } catch (error) {
      if (!isClosed) {
        emit(DormitoryPaymentError(_cleanError(error)));
      }

      return false;
    }
  }

  String? _responseMessage(Map<String, dynamic> response) {
    final String value = response['message']?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  bool _isApiNotAvailable(Object error) {
    if (error is! DioException) {
      return false;
    }

    final int? statusCode = error.response?.statusCode;

    return statusCode == 404 || statusCode == 501;
  }

  String _cleanError(Object error) {
    if (error is DioException) {
      final dynamic responseData = error.response?.data;

      if (responseData is Map) {
        final dynamic message = responseData['message'];

        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }

        final dynamic errors = responseData['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final List<String> messages = <String>[];

          for (final dynamic value in errors.values) {
            if (value is Iterable) {
              messages.addAll(
                value.map((dynamic item) => item.toString()),
              );
            } else if (value != null) {
              messages.add(value.toString());
            }
          }

          if (messages.isNotEmpty) {
            return messages.join('\n');
          }
        }
      }

      return error.message ?? 'Không kết nối được máy chủ';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }
}
