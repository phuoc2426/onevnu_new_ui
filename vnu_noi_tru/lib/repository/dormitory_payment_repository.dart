import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/services/app_config_service.dart';
import 'package:vnu_core/services/dio_options.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_noi_tru/models/dormitory_payment/dormitory_invoice_model.dart';
import 'package:vnu_noi_tru/models/dormitory_payment/dormitory_payment_method_model.dart';

class DormitoryPaymentRepository {
  DormitoryPaymentRepository._internal();

  static final DormitoryPaymentRepository _instance =
      DormitoryPaymentRepository._internal();

  factory DormitoryPaymentRepository() => _instance;

  Dio? _dio;
  String _dioBaseUrl = '';

  Future<Dio> _getDio() async {
    await AppConfigService().ensureLoaded();

    final String baseUrl = ServicesUrl().effectiveKtxApiUrl;
    if (baseUrl.isEmpty) {
      throw StateError(
        'KTX API URL is unavailable. Check /api/config on '
        '${ServicesUrl.defaultBaseUrl}.',
      );
    }

    if (_dio == null || _dioBaseUrl != baseUrl) {
      _dio?.close(force: true);
      _dio = DioOptions().createDio(baseUrl);
      _dioBaseUrl = baseUrl;
      logInfo('DormitoryPaymentRepository API from config: $baseUrl');
    }

    return _dio!;
  }

  Future<DormitoryInvoiceResponse> getReceipts({
    required String identityNo,
  }) async {
    final String normalizedIdentityNo = identityNo.trim();
    if (normalizedIdentityNo.isEmpty) {
      throw ArgumentError('CCCD không được để trống');
    }

    final Dio dio = await _getDio();
    final String encodedIdentityNo = Uri.encodeComponent(normalizedIdentityNo);

    final Response<Map<String, dynamic>> response =
        await dio.get<Map<String, dynamic>>(
      'students/$encodedIdentityNo/receipts',
      options: Options(
        headers: <String, dynamic>{'Accept': 'application/json'},
      ),
    );

    return DormitoryInvoiceResponse.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  Future<DormitoryInvoiceResponse> getInvoices({required String identityNo}) {
    return getReceipts(identityNo: identityNo);
  }

  Future<DormitoryPaymentMethodResponse> getPaymentMethods({
    required int dormitoryId,
  }) async {
    final Dio dio = await _getDio();

    final Response<Map<String, dynamic>> response =
        await dio.get<Map<String, dynamic>>(
      'dormitory/$dormitoryId/payment-methods',
      options: Options(
        headers: <String, dynamic>{'Accept': 'application/json'},
      ),
    );

    return DormitoryPaymentMethodResponse.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  /// API mới cho phép gửi nhiều minh chứng trong cùng một lần và bổ sung
  /// nhiều lần cho cùng payment đang pending.
  ///
  /// POST /students/{identityNo}/receipts/{receipt}/payment-proof
  /// multipart: proof_images[] + note
  Future<Map<String, dynamic>> uploadPaymentProof({
    required String identityNo,
    required Object receiptId,
    required List<File> proofImages,
    String? note,
    ProgressCallback? onSendProgress,
  }) async {
    final String normalizedIdentityNo = identityNo.trim();
    if (normalizedIdentityNo.isEmpty) {
      throw ArgumentError('CCCD không được để trống');
    }

    if (proofImages.isEmpty) {
      throw ArgumentError('Vui lòng chọn ít nhất một ảnh minh chứng');
    }

    final String normalizedReceiptId = receiptId.toString().trim();
    if (normalizedReceiptId.isEmpty) {
      throw ArgumentError('Mã biên lai không hợp lệ');
    }

    final String? normalizedNote = note?.trim();
    if (normalizedNote != null && normalizedNote.length > 500) {
      throw ArgumentError('Ghi chú không được vượt quá 500 ký tự');
    }

    final FormData formData = FormData();
    int totalBytes = 0;

    for (int index = 0; index < proofImages.length; index++) {
      final File file = proofImages[index];
      if (!await file.exists()) {
        throw ArgumentError('Có ảnh minh chứng không còn tồn tại trên thiết bị');
      }

      totalBytes += await file.length();
      final String extension = path.extension(file.path).toLowerCase();
      final MediaType contentType = extension == '.png'
          ? MediaType('image', 'png')
          : MediaType('image', 'jpeg');

      formData.files.add(
        MapEntry<String, MultipartFile>(
          'proof_images[]',
          await MultipartFile.fromFile(
            file.path,
            filename:
                'payment_proof_${DateTime.now().millisecondsSinceEpoch}_$index${extension.isEmpty ? '.jpg' : extension}',
            contentType: contentType,
          ),
        ),
      );
    }

    if (normalizedNote != null && normalizedNote.isNotEmpty) {
      formData.fields.add(MapEntry<String, String>('note', normalizedNote));
    }

    logInfo(
      '[PAYMENT-PROOF-UPLOAD] platform=${Platform.operatingSystem} '
      'files=${proofImages.length} bytes=$totalBytes',
    );

    final String encodedIdentityNo = Uri.encodeComponent(normalizedIdentityNo);
    final String encodedReceiptId = Uri.encodeComponent(normalizedReceiptId);
    final Dio dio = await _getDio();

    try {
      final Response<Map<String, dynamic>> response =
          await dio.post<Map<String, dynamic>>(
        'students/$encodedIdentityNo/receipts/$encodedReceiptId/payment-proof',
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          headers: <String, dynamic>{'Accept': 'application/json'},
          contentType: Headers.multipartFormDataContentType,
        ),
      );

      logInfo(
        '[PAYMENT-PROOF-UPLOAD-SUCCESS] status=${response.statusCode} '
        'files=${proofImages.length}',
      );

      return response.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      logWarning(
        '[PAYMENT-PROOF-UPLOAD-ERROR] '
        'type=${error.type} status=${error.response?.statusCode}',
      );
      rethrow;
    }
  }

  /// Compatibility wrapper cho code cũ nếu còn nơi gọi 1 file.
  Future<Map<String, dynamic>> uploadSinglePaymentProof({
    required String identityNo,
    required Object receiptId,
    required File proofImage,
    String? note,
    ProgressCallback? onSendProgress,
  }) {
    return uploadPaymentProof(
      identityNo: identityNo,
      receiptId: receiptId,
      proofImages: <File>[proofImage],
      note: note,
      onSendProgress: onSendProgress,
    );
  }

  /// Xóa một proof riêng lẻ. Backend chỉ cho xóa khi payment còn pending.
  Future<Map<String, dynamic>> deletePaymentProof({
    required String identityNo,
    required Object receiptId,
    required Object proofId,
  }) async {
    final String normalizedIdentityNo = identityNo.trim();
    final String normalizedReceiptId = receiptId.toString().trim();
    final String normalizedProofId = proofId.toString().trim();

    if (normalizedIdentityNo.isEmpty ||
        normalizedReceiptId.isEmpty ||
        normalizedProofId.isEmpty) {
      throw ArgumentError('Thiếu thông tin minh chứng cần xóa');
    }

    final Dio dio = await _getDio();
    final String encodedIdentityNo = Uri.encodeComponent(normalizedIdentityNo);
    final String encodedReceiptId = Uri.encodeComponent(normalizedReceiptId);
    final String encodedProofId = Uri.encodeComponent(normalizedProofId);

    final Response<Map<String, dynamic>> response =
        await dio.delete<Map<String, dynamic>>(
      'students/$encodedIdentityNo/receipts/$encodedReceiptId/'
      'payment-proof/$encodedProofId',
      options: Options(
        headers: <String, dynamic>{'Accept': 'application/json'},
      ),
    );

    return response.data ?? const <String, dynamic>{};
  }
}
