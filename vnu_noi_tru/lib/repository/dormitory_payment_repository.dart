import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_noi_tru/models/dormitory_payment/dormitory_invoice_model.dart';
import 'package:vnu_noi_tru/models/dormitory_payment/dormitory_payment_method_model.dart';

class DormitoryPaymentRepository {
  DormitoryPaymentRepository._internal() {
    _dio = DioOptions().createDio(_baseUrl);
  }

  static const String _baseUrl =
      'https://ktx.sohatech.vn/api/';

  static final DormitoryPaymentRepository _instance =
      DormitoryPaymentRepository._internal();

  factory DormitoryPaymentRepository() {
    return _instance;
  }

  late final Dio _dio;

  Future<DormitoryInvoiceResponse> getInvoices({
    required String identityNo,
  }) async {
    final String normalizedIdentityNo =
        identityNo.trim();

    if (normalizedIdentityNo.isEmpty) {
      throw ArgumentError(
        'CCCD không được để trống',
      );
    }

    final String encodedIdentityNo =
        Uri.encodeComponent(
      normalizedIdentityNo,
    );

    final Response<Map<String, dynamic>> response =
        await _dio.get<Map<String, dynamic>>(
      'students/$encodedIdentityNo/invoices',
      options: Options(
        headers: <String, dynamic>{
          'Accept': 'application/json',
        },
      ),
    );

    return DormitoryInvoiceResponse.fromJson(
      response.data ??
          const <String, dynamic>{},
    );
  }

  Future<DormitoryPaymentMethodResponse>
      getPaymentMethods({
    required int dormitoryId,
  }) async {
    final Response<Map<String, dynamic>> response =
        await _dio.get<Map<String, dynamic>>(
      'dormitory/$dormitoryId/payment-methods',
      options: Options(
        headers: <String, dynamic>{
          'Accept': 'application/json',
        },
      ),
    );

    return DormitoryPaymentMethodResponse.fromJson(
      response.data ??
          const <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>>
      uploadPaymentProof({
    required String identityNo,
    required Object invoiceId,
    required File proofImage,
    String? note,
    ProgressCallback? onSendProgress,
  }) async {
    final String normalizedIdentityNo =
        identityNo.trim();

    if (normalizedIdentityNo.isEmpty) {
      throw ArgumentError(
        'CCCD không được để trống',
      );
    }

    if (!await proofImage.exists()) {
      throw ArgumentError(
        'File minh chứng không tồn tại',
      );
    }

    final String encodedIdentityNo =
        Uri.encodeComponent(
      normalizedIdentityNo,
    );

    final String encodedInvoiceId =
        Uri.encodeComponent(
      invoiceId.toString(),
    );

    final FormData formData =
        FormData.fromMap(
      <String, dynamic>{
        'proof_image':
            await MultipartFile.fromFile(
          proofImage.path,
          filename: path.basename(
            proofImage.path,
          ),
        ),
        if (note != null &&
            note.trim().isNotEmpty)
          'note': note.trim(),
      },
    );

    final Response<Map<String, dynamic>> response =
        await _dio.post<Map<String, dynamic>>(
      'students/$encodedIdentityNo'
      '/invoices/$encodedInvoiceId'
      '/payment-proof',
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(
        headers: <String, dynamic>{
          'Accept': 'application/json',
        },
        contentType: 'multipart/form-data',
      ),
    );

    return response.data ??
        const <String, dynamic>{};
  }
}
