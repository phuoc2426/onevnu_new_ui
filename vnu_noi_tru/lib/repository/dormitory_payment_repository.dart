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

  static const String _baseUrl = 'https://ktx.sohatech.vn/api/';

  static final DormitoryPaymentRepository _instance =
      DormitoryPaymentRepository._internal();

  factory DormitoryPaymentRepository() {
    return _instance;
  }

  late final Dio _dio;

  /// Lấy toàn bộ biên lai của sinh viên.
  ///
  /// API mới:
  /// GET /students/{identityNo}/receipts
  Future<DormitoryInvoiceResponse> getReceipts({
    required String identityNo,
  }) async {
    final String normalizedIdentityNo = identityNo.trim();

    if (normalizedIdentityNo.isEmpty) {
      throw ArgumentError('CCCD không được để trống');
    }

    final String encodedIdentityNo =
        Uri.encodeComponent(normalizedIdentityNo);

    final Response<Map<String, dynamic>> response =
        await _dio.get<Map<String, dynamic>>(
      'students/$encodedIdentityNo/receipts',
      options: Options(
        headers: <String, dynamic>{
          'Accept': 'application/json',
        },
      ),
    );

    return DormitoryInvoiceResponse.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  /// Giữ lại tên hàm cũ để các nơi chưa cập nhật vẫn biên dịch được.
  Future<DormitoryInvoiceResponse> getInvoices({
    required String identityNo,
  }) {
    return getReceipts(identityNo: identityNo);
  }

  Future<DormitoryPaymentMethodResponse> getPaymentMethods({
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
      response.data ?? const <String, dynamic>{},
    );
  }

  /// Gửi ảnh minh chứng chuyển khoản cho một biên lai.
  ///
  /// API mới:
  /// POST /students/{identityNo}/receipts/{receipt}/payment-proof
  /// multipart field bắt buộc: proof_image
  Future<Map<String, dynamic>> uploadPaymentProof({
    required String identityNo,
    required Object receiptId,
    required File proofImage,
    String? note,
    ProgressCallback? onSendProgress,
  }) async {
    final String normalizedIdentityNo = identityNo.trim();

    if (normalizedIdentityNo.isEmpty) {
      throw ArgumentError('CCCD không được để trống');
    }

    if (!await proofImage.exists()) {
      throw ArgumentError('File minh chứng không tồn tại');
    }

    final String normalizedReceiptId = receiptId.toString().trim();

    if (normalizedReceiptId.isEmpty) {
      throw ArgumentError('Mã biên lai không hợp lệ');
    }

    final String encodedIdentityNo =
        Uri.encodeComponent(normalizedIdentityNo);
    final String encodedReceiptId =
        Uri.encodeComponent(normalizedReceiptId);

    final String? normalizedNote = note?.trim();

    if (normalizedNote != null && normalizedNote.length > 500) {
      throw ArgumentError('Ghi chú không được vượt quá 500 ký tự');
    }

    final FormData formData = FormData.fromMap(
      <String, dynamic>{
        'proof_image': await MultipartFile.fromFile(
          proofImage.path,
          filename: path.basename(proofImage.path),
        ),
        if (normalizedNote != null && normalizedNote.isNotEmpty)
          'note': normalizedNote,
      },
    );

    final Response<Map<String, dynamic>> response =
        await _dio.post<Map<String, dynamic>>(
      'students/$encodedIdentityNo'
      '/receipts/$encodedReceiptId'
      '/payment-proof',
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(
        headers: <String, dynamic>{
          'Accept': 'application/json',
        },
        contentType: Headers.multipartFormDataContentType,
      ),
    );

    return response.data ?? const <String, dynamic>{};
  }
}
