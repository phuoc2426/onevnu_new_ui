import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

import 'package:vnu_noi_tru/cubit/dormitory_payment_cubit.dart';
import 'package:vnu_noi_tru/models/dormitory_payment/dormitory_invoice_model.dart';
import 'package:vnu_noi_tru/models/dormitory_payment/dormitory_payment_method_model.dart';
import 'package:vnu_noi_tru/utils/dormitory_image_upload_util.dart';

class DRInvoicesScreen extends StatefulWidget {
  final String identityNo;
  final int? dormitoryId;
  final String dormitoryName;

  /// Khoảng ngày đang hiển thị ở card lịch sử nội trú bên ngoài.
  /// Dùng làm fallback vì API receipts hiện chưa bắt buộc trả ngày kỳ thu.
  final DateTime? accommodationStartDate;
  final DateTime? accommodationEndDate;

  const DRInvoicesScreen({
    super.key,
    required this.identityNo,
    this.dormitoryId,
    required this.dormitoryName,
    this.accommodationStartDate,
    this.accommodationEndDate,
  });

  @override
  State<DRInvoicesScreen> createState() => _DRInvoicesScreenState();
}

class _DRInvoicesScreenState extends State<DRInvoicesScreen> {
  static const int _maxProofSizeMb = 5;
  static const int _maxProofSizeBytes = _maxProofSizeMb * 1024 * 1024;

  final DormitoryPaymentCubit _cubit = DormitoryPaymentCubit();

  final ImagePicker _imagePicker = ImagePicker();
  bool _isPickingPaymentProof = false;

  final NumberFormat _currencyFormatter = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _cubit.loadData(
      identityNo: widget.identityNo,
      dormitoryId: widget.dormitoryId,
    );
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Hóa đơn & thanh toán',
      body: BlocConsumer<DormitoryPaymentCubit, DormitoryPaymentState>(
        bloc: _cubit,
        listener: (BuildContext context, DormitoryPaymentState state) {
          if (state is DormitoryPaymentUploadSuccess) {
            _showSuccess(state.message);
          }

          if (state is DormitoryPaymentError) {
            _showError(state.message);
          }
        },
        builder: (BuildContext context, DormitoryPaymentState state) {
          final bool isUploading = state is DormitoryPaymentUploading;

          final double uploadProgress = state is DormitoryPaymentUploading
              ? state.progress
              : 0;

          return Stack(
            children: <Widget>[
              _buildMainContent(state),

              if (isUploading) _buildUploadingOverlay(uploadProgress),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(DormitoryPaymentState state) {
    if (state is DormitoryPaymentLoading && _cubit.invoices.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.colorMain),
      );
    }

    if (state is DormitoryPaymentError && _cubit.invoices.isEmpty) {
      return _buildErrorState(state.message);
    }

    if (_cubit.invoices.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.colorMain,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ..._cubit.invoices.map(_buildInvoiceCard),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // =========================================================
  // Empty và Error
  // =========================================================

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.colorMain,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 30),
        children: <Widget>[
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF8EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 46,
              color: Color(0xFF078B3E),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có hóa đơn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSizes.medium,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111318),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Hóa đơn sẽ được hiển thị sau khi '
            'Ban quản lý ký túc xá hoàn tất '
            'việc duyệt hồ sơ và lập khoản thu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSizes.font11,
              color: Color(0xFF6A6E76),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Kiểm tra lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 30),
        children: <Widget>[
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Không tải được hóa đơn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSizes.medium,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppFontSizes.font11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Hóa đơn
  // =========================================================

  Widget _buildInvoiceCard(DormitoryInvoiceModel invoice) {
    final String? qrUrl = _resolveQrUrl(invoice);

    final DormitoryPaymentMethodModel? paymentMethod = _resolvePaymentMethod();

    final double remainingAmount = _calculateRemainingAmount(invoice);
    final String? periodRange = _invoicePeriodRange(invoice);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.05),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _invoiceStatusColor(invoice).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 22,
                    color: _invoiceStatusColor(invoice),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        invoice.displayTitle,
                        style: const TextStyle(
                          fontSize: AppFontSizes.mediumSmall,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111318),
                        ),
                      ),
                      if (periodRange != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.date_range_outlined,
                              size: 14,
                              color: Color(0xFF078B3E),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                periodRange,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: AppFontSizes.font11,
                                  color: Color(0xFF4F5660),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (invoice.code != null &&
                          invoice.code!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Mã hóa đơn: '
                          '${invoice.code}',
                          style: const TextStyle(
                            fontSize: AppFontSizes.font11,
                            color: Color(0xFF737780),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildInvoiceStatusBadge(invoice),
              ],
            ),

            const Divider(height: 26),

            _buildAmountRow(
              label: 'Tổng tiền',
              amount: invoice.totalAmount,
              isPrimary: true,
            ),

            if (invoice.paidAmount > 0)
              _buildAmountRow(
                label: 'Đã thanh toán',
                amount: invoice.paidAmount,
              ),

            if (!invoice.isPaid)
              _buildAmountRow(
                label: 'Còn phải trả',
                amount: remainingAmount,
                valueColor: Colors.red.shade700,
              ),

            if (invoice.billingPeriodName != null &&
                invoice.billingPeriodName!.trim().isNotEmpty)
              _buildInfoRow(
                label: 'Kỳ thanh toán',
                value: invoice.billingPeriodName!,
              ),

            if (invoice.dueDate != null)
              _buildInfoRow(
                label: 'Hạn thanh toán',
                value: DateFormat('dd/MM/yyyy').format(invoice.dueDate!),
                valueColor: _isOverdue(invoice) ? Colors.red : null,
              ),

            if (invoice.description != null &&
                invoice.description!.trim().isNotEmpty)
              _buildInfoRow(label: 'Nội dung', value: invoice.description!),

            if (invoice.paymentCode != null &&
                invoice.paymentCode!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildPaymentCodeBox(invoice.paymentCode!),
            ],

            const SizedBox(height: 16),

            _buildQrSection(invoice: invoice, qrUrl: qrUrl),

            if (paymentMethod != null) ...[
              const SizedBox(height: 16),
              _buildBankInformation(paymentMethod),
            ],

            if (invoice.payments.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLatestPaymentBox(invoice),
            ],

            const SizedBox(height: 18),

            _buildProofButton(invoice),
          ],
        ),
      ),
    );
  }

  String? _invoicePeriodRange(DormitoryInvoiceModel invoice) {
    final DateTime? start =
        invoice.resolvedPeriodStartDate ?? widget.accommodationStartDate;
    final DateTime? end =
        invoice.resolvedPeriodEndDate ?? widget.accommodationEndDate;

    if (start != null && end != null) {
      return 'Từ ${_formatShortDate(start)} đến ${_formatShortDate(end)}';
    }

    if (start != null) {
      return 'Từ ${_formatShortDate(start)}';
    }

    if (end != null) {
      return 'Đến ${_formatShortDate(end)}';
    }

    return null;
  }

  String _formatShortDate(DateTime value) {
    return DateFormat('dd/MM/yy').format(value.toLocal());
  }

  Widget _buildAmountRow({
    required String label,
    required double amount,
    bool isPrimary = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isPrimary
                    ? AppFontSizes.mediumSmall
                    : AppFontSizes.font11,
                color: isPrimary
                    ? const Color(0xFF111318)
                    : const Color(0xFF666B75),
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${_formatMoney(amount)} đ',
            style: TextStyle(
              fontSize: isPrimary
                  ? AppFontSizes.mediumSmall
                  : AppFontSizes.font11,
              color:
                  valueColor ??
                  (isPrimary
                      ? const Color(0xFF078B3E)
                      : const Color(0xFF111318)),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 115,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: AppFontSizes.font11,
                color: Color(0xFF666B75),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppFontSizes.font11,
                color: valueColor ?? const Color(0xFF111318),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Trạng thái hóa đơn
  // =========================================================

  Widget _buildInvoiceStatusBadge(DormitoryInvoiceModel invoice) {
    final Color color = _invoiceStatusColor(invoice);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _invoiceStatusText(invoice),
        style: TextStyle(
          fontSize: AppFontSizes.extraSmall,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _invoiceStatusColor(DormitoryInvoiceModel invoice) {
    if (invoice.isPaid) {
      return AppTheme.colorSuccess;
    }

    if (invoice.hasPendingPayment) {
      return Colors.orange;
    }

    if (_isOverdue(invoice)) {
      return AppTheme.colorError;
    }

    final String status = invoice.status?.toLowerCase().trim() ?? '';

    switch (status) {
      case 'paid':
      case 'completed':
      case 'success':
        return AppTheme.colorSuccess;

      case 'pending':
      case 'waiting':
        return Colors.orange;

      case 'overdue':
        return AppTheme.colorError;

      case 'cancelled':
      case 'canceled':
        return Colors.grey;

      default:
        return Colors.blue;
    }
  }

  String _invoiceStatusText(DormitoryInvoiceModel invoice) {
    if (invoice.isPaid) {
      return 'Đã thanh toán';
    }

    if (invoice.hasPendingPayment) {
      return 'Chờ xác nhận';
    }

    if (_isOverdue(invoice)) {
      return 'Quá hạn';
    }

    if (invoice.statusLabel != null && invoice.statusLabel!.trim().isNotEmpty) {
      return invoice.statusLabel!;
    }

    switch (invoice.status?.toLowerCase().trim()) {
      case 'paid':
        return 'Đã thanh toán';

      case 'pending':
        return 'Chờ xác nhận';

      case 'unpaid':
        return 'Chưa thanh toán';

      case 'overdue':
        return 'Quá hạn';

      case 'cancelled':
      case 'canceled':
        return 'Đã hủy';

      default:
        return 'Chưa thanh toán';
    }
  }

  bool _isOverdue(DormitoryInvoiceModel invoice) {
    if (invoice.isPaid || invoice.dueDate == null) {
      return false;
    }

    final DateTime today = DateTime.now();

    final DateTime currentDate = DateTime(today.year, today.month, today.day);

    final DateTime dueDate = DateTime(
      invoice.dueDate!.year,
      invoice.dueDate!.month,
      invoice.dueDate!.day,
    );

    return dueDate.isBefore(currentDate);
  }

  double _calculateRemainingAmount(DormitoryInvoiceModel invoice) {
    if (invoice.remainingAmount > 0) {
      return invoice.remainingAmount;
    }

    final double calculated = invoice.totalAmount - invoice.paidAmount;

    return calculated > 0 ? calculated : 0;
  }

  // =========================================================
  // Nội dung chuyển khoản
  // =========================================================

  Widget _buildPaymentCodeBox(String paymentCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2D99C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Nội dung chuyển khoản',
            style: TextStyle(
              fontSize: AppFontSizes.font11,
              color: Color(0xFF71612F),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Expanded(
                child: SelectableText(
                  paymentCode,
                  style: const TextStyle(
                    fontSize: AppFontSizes.mediumSmall,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D351A),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Sao chép',
                onPressed: () => _copyPaymentCode(paymentCode),
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 19,
                  color: Color(0xFF078B3E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyPaymentCode(String paymentCode) async {
    await Clipboard.setData(ClipboardData(text: paymentCode));

    if (!mounted) {
      return;
    }

    _showSuccess('Đã sao chép nội dung chuyển khoản');
  }

  // =========================================================
  // QR
  // =========================================================

  String? _resolveQrUrl(DormitoryInvoiceModel invoice) {
    final String? invoiceQr = invoice.bankTransferQrUrl?.trim();

    if (invoiceQr != null && invoiceQr.isNotEmpty) {
      return invoiceQr;
    }

    for (final method in _cubit.paymentMethods) {
      final String? methodQr = method.qrImageUrl?.trim();

      if (method.active && methodQr != null && methodQr.isNotEmpty) {
        return methodQr;
      }
    }

    return null;
  }

  DormitoryPaymentMethodModel? _resolvePaymentMethod() {
    for (final method in _cubit.paymentMethods) {
      if (method.active) {
        return method;
      }
    }

    return _cubit.paymentMethods.isNotEmpty
        ? _cubit.paymentMethods.first
        : null;
  }

  Widget _buildQrSection({
    required DormitoryInvoiceModel invoice,
    required String? qrUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Mã QR thanh toán',
          style: TextStyle(
            fontSize: AppFontSizes.mediumSmall,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111318),
          ),
        ),
        const SizedBox(height: 12),

        if (qrUrl == null)
          _buildEmptyQr()
        else
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showQrPreview(qrUrl),
              child: Container(
                width: 230,
                height: 230,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Image.network(
                  qrUrl,
                  fit: BoxFit.contain,
                  loadingBuilder:
                      (
                        BuildContext context,
                        Widget child,
                        ImageChunkEvent? loadingProgress,
                      ) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.colorMain,
                          ),
                        );
                      },
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Không tải được mã QR',
                              style: TextStyle(
                                fontSize: AppFontSizes.font11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        );
                      },
                ),
              ),
            ),
          ),

        if (qrUrl != null) ...[
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Chạm vào mã QR để xem lớn',
              style: TextStyle(
                fontSize: AppFontSizes.extraSmall,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyQr() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: <Widget>[
          Icon(Icons.qr_code_2_rounded, size: 54, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            'Chưa có mã QR thanh toán',
            style: TextStyle(
              fontSize: AppFontSizes.mediumSmall,
              fontWeight: FontWeight.bold,
              color: Color(0xFF555A63),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Vui lòng sử dụng thông tin tài khoản '
            'ngân hàng hoặc liên hệ Ban quản lý.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: AppFontSizes.font11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showQrPreview(String qrUrl) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Mã QR thanh toán',
                        style: TextStyle(
                          fontSize: AppFontSizes.medium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Image.network(
                  qrUrl,
                  width: 320,
                  height: 320,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const SizedBox(
                      height: 220,
                      child: Center(child: Text('Không tải được mã QR')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // Thông tin ngân hàng
  // =========================================================

  Widget _buildBankInformation(
    DormitoryPaymentMethodModel method,
  ) {
    final bool hasInformation =
        _hasText(method.name) ||
        _hasText(method.typeLabel) ||
        _hasText(method.bankName) ||
        _hasText(method.accountNumber) ||
        _hasText(method.accountName) ||
        _hasText(method.branchName);

    if (!hasInformation) {
      return const SizedBox.shrink();
    }

    final String title = _hasText(method.name)
        ? method.name!.trim()
        : (_hasText(method.typeLabel)
              ? method.typeLabel!.trim()
              : 'Chuyển khoản ngân hàng');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FAF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFB7E2C5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCF3E4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  size: 22,
                  color: Color(0xFF078B3E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'THÔNG TIN CHUYỂN KHOẢN',
                      style: TextStyle(
                        fontSize: AppFontSizes.extraSmall,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: Color(0xFF078B3E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppFontSizes.mediumSmall,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF152019),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_hasText(method.bankName)) ...[
            const SizedBox(height: 16),
            _buildTransferInfoRow(
              label: 'Ngân hàng',
              value: method.bankName!.trim(),
              emphasize: true,
            ),
          ],
          if (_hasText(method.accountNumber)) ...[
            const SizedBox(height: 14),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _copyAccountNumber(
                  method.accountNumber!.trim(),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    12,
                    8,
                    12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF078B3E),
                      width: 1.3,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'SỐ TÀI KHOẢN',
                              style: TextStyle(
                                fontSize:
                                    AppFontSizes.extraSmall,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Color(0xFF637169),
                              ),
                            ),
                            const SizedBox(height: 5),
                            SelectableText(
                              method.accountNumber!.trim(),
                              style: const TextStyle(
                                fontSize: 21,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                                color: Color(0xFF078B3E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sao chép số tài khoản',
                        onPressed: () => _copyAccountNumber(
                          method.accountNumber!.trim(),
                        ),
                        icon: const Icon(
                          Icons.content_copy_rounded,
                          color: Color(0xFF078B3E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            const Row(
              children: <Widget>[
                Icon(
                  Icons.touch_app_outlined,
                  size: 15,
                  color: Color(0xFF66736B),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Chạm vào số tài khoản hoặc biểu tượng sao chép.',
                    style: TextStyle(
                      fontSize: AppFontSizes.extraSmall,
                      color: Color(0xFF66736B),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_hasText(method.accountName)) ...[
            const SizedBox(height: 14),
            _buildTransferInfoRow(
              label: 'Chủ tài khoản',
              value: method.accountName!.trim(),
              emphasize: true,
            ),
          ],
          if (_hasText(method.branchName)) ...[
            const SizedBox(height: 10),
            _buildTransferInfoRow(
              label: 'Chi nhánh',
              value: method.branchName!.trim(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransferInfoRow({
    required String label,
    required String value,
    bool emphasize = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 105,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: AppFontSizes.font11,
              color: Color(0xFF667169),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppFontSizes.font11,
              height: 1.35,
              fontWeight:
                  emphasize ? FontWeight.w800 : FontWeight.w600,
              color: emphasize
                  ? const Color(0xFF152019)
                  : const Color(0xFF303A34),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _copyAccountNumber(
    String accountNumber,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: accountNumber),
    );

    if (!mounted) {
      return;
    }

    _showSuccess(
      'Đã sao chép số tài khoản $accountNumber',
    );
  }

  // =========================================================
  // Minh chứng đã gửi
  // =========================================================

  Widget _buildLatestPaymentBox(DormitoryInvoiceModel invoice) {
    final DormitoryPaymentModel payment = invoice.latestPayment!;

    final String status = payment.status?.toLowerCase().trim() ?? '';

    Color color;
    IconData icon;
    String title;

    // Receipt là trạng thái nghiệp vụ cuối cùng. Khi biên lai đã được xác nhận
    // thanh toán, không tiếp tục hiển thị Payment cũ là pending.
    if (invoice.isPaid) {
      color = AppTheme.colorSuccess;
      icon = Icons.check_circle_rounded;
      title = 'Minh chứng đã được xác nhận';
    } else {
      switch (status) {
        case 'approved':
        case 'confirmed':
        case 'paid':
        case 'completed':
        case 'success':
          color = AppTheme.colorSuccess;
          icon = Icons.check_circle_rounded;
          title = 'Minh chứng đã được xác nhận';
          break;

        case 'rejected':
          color = AppTheme.colorError;
          icon = Icons.cancel_rounded;
          title = 'Minh chứng bị từ chối';
          break;

        default:
          color = Colors.orange;
          icon = Icons.hourglass_top_rounded;
          title = 'Minh chứng đang chờ xác nhận';
          break;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: AppFontSizes.font11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),

          if (payment.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Ngày gửi: '
              '${DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt!)}',
              style: const TextStyle(
                fontSize: AppFontSizes.font11,
                color: Color(0xFF666B75),
              ),
            ),
          ],

          if (_hasText(payment.note)) ...[
            const SizedBox(height: 6),
            Text(
              'Ghi chú: ${payment.note}',
              style: const TextStyle(
                fontSize: AppFontSizes.font11,
                color: Color(0xFF666B75),
              ),
            ),
          ],

          if (!invoice.isPaid && _hasText(payment.rejectionReason)) ...[
            const SizedBox(height: 6),
            Text(
              'Lý do từ chối: '
              '${payment.rejectionReason}',
              style: const TextStyle(
                fontSize: AppFontSizes.font11,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // Upload minh chứng
  // =========================================================

  Widget _buildProofButton(DormitoryInvoiceModel invoice) {
    if (invoice.isPaid) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Đã thanh toán'),
        ),
      );
    }

    if (invoice.hasPendingPayment) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.hourglass_top_rounded),
          label: const Text('Đang chờ xác nhận thanh toán'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _pickPaymentProof(invoice),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF078B3E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.upload_file_rounded),
        label: Text(
          invoice.hasRejectedPayment
              ? 'Gửi lại minh chứng thanh toán'
              : 'Gửi minh chứng thanh toán',
        ),
      ),
    );
  }

  Future<void> _pickPaymentProof(DormitoryInvoiceModel invoice) async {
    if (invoice.id == null) {
      _showError('Không tìm thấy mã biên lai');
      return;
    }

    if (_isPickingPaymentProof) {
      return;
    }

    _isPickingPaymentProof = true;
    File? originalFile;
    File? normalizedProofFile;

    try {
      final XFile? selectedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        // Chỉ giảm sơ bộ khi chọn ảnh. Bước chuẩn hóa JPEG phía dưới mới là
        // bước bắt buộc cho cả Android và iOS, đặc biệt với HEIC/HEIF trên iOS.
        imageQuality: 100,
      );

      if (selectedImage == null) {
        return;
      }

      final File selectedFile = File(selectedImage.path);
      originalFile = selectedFile;
      final File preparedProofFile =
          await DormitoryImageUploadUtil.normalizeToJpeg(selectedFile);
      normalizedProofFile = preparedProofFile;

      final int fileSize = await preparedProofFile.length();
      if (fileSize > _maxProofSizeBytes) {
        _showError(
          'Ảnh minh chứng không được vượt quá '
          '$_maxProofSizeMb MB',
        );
        return;
      }

      if (!mounted) {
        return;
      }

      final PaymentProofConfirmResult? confirmResult =
          await _showProofConfirmDialog(preparedProofFile);

      if (confirmResult == null || !confirmResult.confirmed) {
        return;
      }

      await _cubit.uploadProof(
        identityNo: widget.identityNo,
        receiptId: invoice.id!,
        proofImage: preparedProofFile,
        note: confirmResult.note,
        dormitoryId: widget.dormitoryId,
      );
    } catch (error) {
      if (mounted) {
        _showError(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      _isPickingPaymentProof = false;
      await DormitoryImageUploadUtil.deleteTemporaryFile(
        normalizedFile: normalizedProofFile,
        originalFile: originalFile,
      );
    }
  }

  Future<PaymentProofConfirmResult?>
      _showProofConfirmDialog(
    File proofFile,
  ) {
    return showDialog<PaymentProofConfirmResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _PaymentProofConfirmDialog(
          proofFile: proofFile,
        );
      },
    );
  }

  // =========================================================
  // Upload overlay
  // =========================================================

  Widget _buildUploadingOverlay(double progress) {
    final int percent = (progress.clamp(0.0, 1.0) * 100).round();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.45),
        alignment: Alignment.center,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(
                value: progress > 0 ? progress : null,
                color: AppTheme.colorMain,
              ),
              const SizedBox(height: 18),
              const Text(
                'Đang gửi minh chứng...',
                style: TextStyle(
                  fontSize: AppFontSizes.mediumSmall,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                progress > 0 ? '$percent%' : 'Vui lòng không đóng màn hình',
                style: const TextStyle(
                  fontSize: AppFontSizes.font11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // Helpers
  // =========================================================

  String _formatMoney(double amount) {
    return _currencyFormatter.format(amount);
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  void _showSuccess(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF078B3E),
        content: Row(
          children: <Widget>[
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.colorError,
        content: Row(
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}


class _PaymentProofConfirmDialog
    extends StatefulWidget {
  final File proofFile;

  const _PaymentProofConfirmDialog({
    required this.proofFile,
  });

  @override
  State<_PaymentProofConfirmDialog> createState() =>
      _PaymentProofConfirmDialogState();
}

class _PaymentProofConfirmDialogState
    extends State<_PaymentProofConfirmDialog> {
  late final TextEditingController
      _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _close() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
  }

  void _submit() {
    final String note =
        _noteController.text.trim();

    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(
      PaymentProofConfirmResult(
        confirmed: true,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight =
        MediaQuery.of(context).size.height * 0.86;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 +
                  MediaQuery.of(context)
                      .viewInsets
                      .bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Xác nhận minh chứng',
                        style: TextStyle(
                          fontSize:
                              AppFontSizes.medium,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: _close,
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  constraints:
                      const BoxConstraints(
                    minHeight: 180,
                    maxHeight: 280,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(14),
                    child: Image.file(
                      widget.proofFile,
                      fit: BoxFit.contain,
                      errorBuilder: (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return const Center(
                          child: Text(
                            'Không hiển thị được ảnh',
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 500,
                  textInputAction:
                      TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText:
                        'Ghi chú thanh toán',
                    hintText:
                        'Ví dụ: Đã chuyển khoản lúc 10:30',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFFFF8E7),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFF766220),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ảnh cần nhìn rõ số tiền, '
                          'thời gian và nội dung '
                          'chuyển khoản.',
                          style: TextStyle(
                            fontSize:
                                AppFontSizes.font11,
                            height: 1.35,
                            color:
                                Color(0xFF766220),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (
                    BuildContext context,
                    BoxConstraints constraints,
                  ) {
                    final bool useColumn =
                        constraints.maxWidth < 330;

                    final Widget cancelButton =
                        OutlinedButton(
                      onPressed: _close,
                      child: const Text(
                        'Chọn lại',
                      ),
                    );

                    final Widget submitButton =
                        FilledButton.icon(
                      onPressed: _submit,
                      style:
                          FilledButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF078B3E,
                        ),
                        foregroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                      ),
                      icon: const Icon(
                        Icons.send_rounded,
                      ),
                      label: const Text(
                        'Gửi minh chứng',
                      ),
                    );

                    if (useColumn) {
                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: <Widget>[
                          submitButton,
                          const SizedBox(height: 10),
                          cancelButton,
                        ],
                      );
                    }

                    return Row(
                      children: <Widget>[
                        Expanded(
                          child: cancelButton,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: submitButton,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class PaymentProofConfirmResult {
  final bool confirmed;
  final String? note;

  const PaymentProofConfirmResult({required this.confirmed, this.note});
}
