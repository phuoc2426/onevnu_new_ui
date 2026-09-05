import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vnu_core/common/error/app_error_mapper.dart';
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
import 'package:vnu_noi_tru/widgets/dormitory_ticket_card.dart';
import 'package:vnu_noi_tru/widgets/dormitory_leather_wallet_3d.dart';
import 'package:vnu_core/widgets/field/vnu_text_field.dart';

enum _InvoiceFilter { all, unpaid, pending, paid }

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
  static const int _maxProofSizeMb = 4;
  static const int _maxProofSizeBytes = _maxProofSizeMb * 1024 * 1024;

  final DormitoryPaymentCubit _cubit = DormitoryPaymentCubit();

  final ImagePicker _imagePicker = ImagePicker();
  bool _isPickingPaymentProof = false;

  final NumberFormat _currencyFormatter = NumberFormat('#,###', 'vi_VN');
  _InvoiceFilter _filter = _InvoiceFilter.all;

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

          if (state is DormitoryPaymentProofDeleteSuccess) {
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

    final List<DormitoryInvoiceModel> visibleInvoices = _filteredInvoices();

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.colorMain,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: <Widget>[
          _buildInvoiceDashboard(),
          const SizedBox(height: 16),
          if (visibleInvoices.isEmpty)
            _buildFilteredEmptyState()
          else
            ...visibleInvoices.map(_buildInvoiceCard),
        ],
      ),
    );
  }

  List<DormitoryInvoiceModel> _filteredInvoices() {
    switch (_filter) {
      case _InvoiceFilter.unpaid:
        return _cubit.invoices
            .where(
              (DormitoryInvoiceModel invoice) =>
                  !invoice.isPaid && !invoice.hasPendingPayment,
            )
            .toList();
      case _InvoiceFilter.pending:
        return _cubit.invoices
            .where((DormitoryInvoiceModel invoice) => invoice.hasPendingPayment)
            .toList();
      case _InvoiceFilter.paid:
        return _cubit.invoices
            .where((DormitoryInvoiceModel invoice) => invoice.isPaid)
            .toList();
      case _InvoiceFilter.all:
        return List<DormitoryInvoiceModel>.from(_cubit.invoices);
    }
  }

  Widget _buildInvoiceDashboard() {
    final int unpaidCount = _cubit.invoices
        .where(
          (DormitoryInvoiceModel invoice) =>
              !invoice.isPaid && !invoice.hasPendingPayment,
        )
        .length;
    final int pendingCount = _cubit.invoices
        .where((DormitoryInvoiceModel invoice) => invoice.hasPendingPayment)
        .length;
    final int paidCount = _cubit.invoices
        .where((DormitoryInvoiceModel invoice) => invoice.isPaid)
        .length;

    final double totalDebt = _cubit.invoices.fold<double>(
      0,
      (double total, DormitoryInvoiceModel invoice) =>
          total + (invoice.isPaid ? 0 : _calculateRemainingAmount(invoice)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DormitoryLeatherWallet3D(
          totalAmount: _formatMoney(totalDebt),
          unpaid: unpaidCount,
          pending: pendingCount,
          paid: paidCount,
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _buildFilterChip(_InvoiceFilter.all, 'Tất cả'),
              const SizedBox(width: 8),
              _buildFilterChip(_InvoiceFilter.unpaid, 'Cần thanh toán'),
              const SizedBox(width: 8),
              _buildFilterChip(_InvoiceFilter.pending, 'Chờ xác nhận'),
              const SizedBox(width: 8),
              _buildFilterChip(_InvoiceFilter.paid, 'Đã thanh toán'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: AppFontSizes.mediumLarge,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4F5660),
              fontSize: AppFontSizes.extraSmall,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(_InvoiceFilter filter, String label) {
    final bool selected = _filter == filter;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _filter = filter),
      label: Text(label),
      showCheckmark: false,
      side: BorderSide(
        color: selected ? const Color(0xFF078B3E) : const Color(0xFFE0E5E2),
      ),
      selectedColor: const Color(0xFFE8F6ED),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF078B3E) : const Color(0xFF5F6670),
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E9E7)),
      ),
      child: const Column(
        children: <Widget>[
          Icon(Icons.inbox_outlined, size: 38, color: Color(0xFF8A918D)),
          SizedBox(height: 10),
          Text(
            'Không có hóa đơn ở trạng thái này',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF555C57),
              fontWeight: FontWeight.w600,
            ),
          ),
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
    final double remainingAmount = _calculateRemainingAmount(invoice);
    final String? periodRange = _invoicePeriodRange(invoice);
    final Color accentColor = _ticketAccentColor(invoice);

    return DormitoryTicketCard(
      accentColor: accentColor,
      stubFraction: 0.76,
      footerHeight: 42,
      onBodyTap: () => _showInvoiceDetailsSheet(invoice),
      footer: _buildTicketFooter(invoice, qrUrl, accentColor),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double stubWidth =
              (constraints.maxWidth * 0.24).clamp(80.0, 96.0).toDouble();

          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 164),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    flex: 54,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildInvoiceStatusBadge(invoice),
                          if (invoice.hasRoomChange || invoice.adjustedCount > 0) ...<Widget>[
                            const SizedBox(height: 6),
                            _buildRoomChangeBadge(invoice),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            invoice.displayTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15181D),
                              height: 1.22,
                            ),
                          ),
                          const SizedBox(height: 7),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${_formatMoney(invoice.isPaid ? invoice.totalAmount : remainingAmount)} đ',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.35,
                                color: accentColor,
                                height: 1.05,
                              ),
                            ),
                          ),
                          const SizedBox(height: 9),
                          if (widget.dormitoryName.trim().isNotEmpty)
                            _buildTicketLine(
                              Icons.apartment_rounded,
                              widget.dormitoryName,
                            ),
                          if (periodRange != null) ...<Widget>[
                            const SizedBox(height: 4),
                            _buildTicketLine(
                              Icons.date_range_outlined,
                              periodRange,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 32,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
                      child: _buildTicketCompactMeta(invoice, accentColor),
                    ),
                  ),
                  SizedBox(
                    width: stubWidth,
                    child: _buildTicketStub(invoice, qrUrl, accentColor),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketCompactMeta(
    DormitoryInvoiceModel invoice,
    Color accentColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (invoice.dueDate != null) ...<Widget>[
          const Text(
            'Hạn thanh toán',
            style: TextStyle(
              fontSize: 9.5,
              color: Color(0xFF747C87),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: <Widget>[
              Icon(
                Icons.calendar_month_rounded,
                size: 14,
                color: _isOverdue(invoice)
                    ? AppTheme.colorError
                    : accentColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  DateFormat('dd/MM/yyyy').format(invoice.dueDate!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _isOverdue(invoice)
                        ? AppTheme.colorError
                        : const Color(0xFF303640),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (invoice.paymentCode != null &&
            invoice.paymentCode!.trim().isNotEmpty) ...<Widget>[
          const Text(
            'Mã thanh toán',
            style: TextStyle(
              fontSize: 9.5,
              color: Color(0xFF747C87),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  invoice.paymentCode!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF202630),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              InkWell(
                onTap: () => _copyPaymentCode(invoice.paymentCode!.trim()),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (invoice.proofCount > 0) ...<Widget>[
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(
                Icons.photo_library_outlined,
                size: 14,
                color: accentColor,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '${invoice.proofCount} minh chứng',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _showInvoiceDetailsSheet(invoice),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.info_outline_rounded, size: 13, color: accentColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Chi tiết',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketStub(
    DormitoryInvoiceModel invoice,
    String? qrUrl,
    Color accentColor,
  ) {
    if (qrUrl != null && !invoice.isPaid && !invoice.hasPendingPayment) {
      return InkWell(
        onTap: () => _showQrPreview(qrUrl),
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withOpacity(0.22)),
              ),
              child: Image.network(
                qrUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.qr_code_2_rounded,
                  size: 44,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Quét để\nthanh toán',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 8.5,
                color: accentColor,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ],
        ),
      );
    }

    final IconData icon;
    final String label;
    if (invoice.isPaid) {
      icon = Icons.check_circle_rounded;
      label = 'Đã thanh\ntoán';
    } else if (invoice.hasPendingPayment) {
      icon = Icons.photo_library_rounded;
      label = invoice.proofCount > 0
          ? '${invoice.proofCount} minh\nchứng'
          : 'Chờ xác\nnhận';
    } else {
      icon = Icons.upload_file_rounded;
      label = 'Gửi minh\nchứng';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.09),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, size: 34, color: accentColor),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: 8.8,
            color: accentColor,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
      ],
    );
  }

  Future<void> _showInvoiceDetailsSheet(DormitoryInvoiceModel invoice) async {
    final String? qrUrl = _resolveQrUrl(invoice);
    final DormitoryPaymentMethodModel? paymentMethod = _resolvePaymentMethod();
    final double remainingAmount = _calculateRemainingAmount(invoice);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDE2DF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            invoice.displayTitle,
                            style: const TextStyle(
                              fontSize: AppFontSizes.medium,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15181D),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildAmountRow(
                      label: 'Tổng tiền',
                      amount: invoice.totalAmount,
                      isPrimary: true,
                    ),
                    if (!invoice.isPaid)
                      _buildAmountRow(
                        label: 'Còn phải thanh toán',
                        amount: remainingAmount,
                        valueColor: _ticketAccentColor(invoice),
                      ),
                    if (invoice.dueDate != null)
                      _buildInfoRow(
                        label: 'Hạn thanh toán',
                        value: DateFormat('dd/MM/yyyy').format(invoice.dueDate!),
                        valueColor: _isOverdue(invoice)
                            ? AppTheme.colorError
                            : null,
                      ),
                    if (invoice.paymentCode != null &&
                        invoice.paymentCode!.trim().isNotEmpty)
                      _buildPaymentCodeBox(invoice.paymentCode!.trim()),
                    if (invoice.billingPeriodName != null &&
                        invoice.billingPeriodName!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        label: 'Kỳ thanh toán',
                        value: invoice.billingPeriodName!,
                      ),
                    ],
                    if (invoice.description != null &&
                        invoice.description!.trim().isNotEmpty)
                      _buildInfoRow(
                        label: 'Nội dung',
                        value: invoice.description!,
                      ),
                    if (qrUrl != null) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildQrSection(invoice: invoice, qrUrl: qrUrl),
                    ],
                    if (paymentMethod != null) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildBankInformation(paymentMethod),
                    ],
                    if (invoice.hasRoomChange || invoice.adjustedCount > 0) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildRoomChangeSummary(invoice),
                    ],
                    if (invoice.payments.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildPaymentProofsSection(invoice),
                    ],
                    if (!invoice.isPaid) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildProofButton(invoice),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTicketLine(IconData icon, String text) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 15, color: const Color(0xFF617067)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppFontSizes.extraSmall,
              color: Color(0xFF626A65),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketFooter(
    DormitoryInvoiceModel invoice,
    String? qrUrl,
    Color accentColor,
  ) {
    String label;
    IconData icon;
    VoidCallback? onTap;

    if (invoice.isPaid) {
      label = 'Đã thanh toán';
      icon = Icons.check_circle_rounded;
    } else if (invoice.hasPendingPayment) {
      label = 'Bổ sung minh chứng';
      icon = Icons.add_photo_alternate_rounded;
      onTap = () => _pickPaymentProof(invoice);
    } else if (qrUrl != null) {
      label = 'Thanh toán ngay';
      icon = Icons.qr_code_2_rounded;
      onTap = () => _showQrPreview(qrUrl);
    } else {
      label = invoice.hasRejectedPayment
          ? 'Gửi lại minh chứng'
          : 'Gửi minh chứng';
      icon = Icons.upload_file_rounded;
      onTap = () => _pickPaymentProof(invoice);
    }

    final Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 17, color: Colors.white),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: AppFontSizes.font11,
            ),
          ),
        ),
        if (onTap != null) ...<Widget>[
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ],
      ],
    );

    if (onTap == null) return Center(child: content);

    return InkWell(
      onTap: onTap,
      child: Center(child: content),
    );
  }

  Color _ticketAccentColor(DormitoryInvoiceModel invoice) {
    if (invoice.isPaid) return const Color(0xFF0A9B61);
    if (invoice.hasPendingPayment) return const Color(0xFFF59E0B);
    if (_isOverdue(invoice)) return const Color(0xFFE53935);
    return const Color(0xFF2563EB);
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              _invoiceStatusText(invoice),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
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

  Widget _buildPaymentProofsSection(DormitoryInvoiceModel invoice) {
    final DormitoryPaymentModel payment = invoice.latestPayment!;
    final List<DormitoryPaymentProofModel> proofs = payment.allProofImages;

    final Color color;
    final IconData icon;
    final String title;

    if (invoice.isPaid || payment.isConfirmed) {
      color = AppTheme.colorSuccess;
      icon = Icons.verified_rounded;
      title = 'Minh chứng đã được xác nhận';
    } else if (payment.isRejected) {
      color = AppTheme.colorError;
      icon = Icons.error_rounded;
      title = 'Minh chứng cần bổ sung';
    } else {
      color = const Color(0xFFF59E0B);
      icon = Icons.schedule_rounded;
      title = 'Minh chứng đang chờ xác nhận';
    }

    final bool allowDelete = payment.isPending && !invoice.isPaid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 21, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppFontSizes.font11,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      proofs.isEmpty
                          ? 'Chưa có ảnh minh chứng lưu trên hệ thống'
                          : '${proofs.length} minh chứng đã nộp',
                      style: const TextStyle(
                        fontSize: AppFontSizes.extraSmall,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (payment.createdAt != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Lần cập nhật gần nhất: '
              '${DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt!.toLocal())}',
              style: const TextStyle(
                fontSize: AppFontSizes.extraSmall,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
          if (_hasText(payment.note)) ...<Widget>[
            const SizedBox(height: 5),
            Text(
              'Ghi chú: ${payment.note}',
              style: const TextStyle(
                fontSize: AppFontSizes.font11,
                color: Color(0xFF4B5563),
                height: 1.35,
              ),
            ),
          ],
          if (!invoice.isPaid && _hasText(payment.rejectionReason)) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Lý do từ chối: ${payment.rejectionReason}',
                style: const TextStyle(
                  fontSize: AppFontSizes.font11,
                  color: Color(0xFFC62828),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (proofs.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double itemWidth = ((constraints.maxWidth - 16) / 3)
                    .clamp(82.0, 116.0)
                    .toDouble();
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: proofs.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final DormitoryPaymentProofModel proof = entry.value;
                    return SizedBox(
                      width: itemWidth,
                      child: _buildProofThumbnail(
                        invoice: invoice,
                        proof: proof,
                        index: index,
                        allowDelete: allowDelete,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProofThumbnail({
    required DormitoryInvoiceModel invoice,
    required DormitoryPaymentProofModel proof,
    required int index,
    required bool allowDelete,
  }) {
    return AspectRatio(
      aspectRatio: 0.92,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: Material(
              color: const Color(0xFFF3F5F4),
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: proof.url.trim().isEmpty
                    ? null
                    : () => _showProofImagePreview(proof.url),
                child: Image.network(
                  proof.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.62),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (allowDelete && proof.canDelete)
            Positioned(
              top: -5,
              right: -5,
              child: Material(
                color: const Color(0xFFE53935),
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _confirmDeleteProof(invoice, proof),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showProofImagePreview(String url) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.black,
          child: Stack(
            children: <Widget>[
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 260,
                    child: Center(
                      child: Text(
                        'Không tải được minh chứng',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton.filled(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.18),
                  ),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteProof(
    DormitoryInvoiceModel invoice,
    DormitoryPaymentProofModel proof,
  ) async {
    if (invoice.id == null || !proof.canDelete) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xóa minh chứng?'),
          content: const Text(
            'Minh chứng đang chờ xử lý sẽ được xóa khỏi hóa đơn. '
            'Bạn có thể tải lại ảnh khác ngay sau đó.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Giữ lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final bool deleted = await _cubit.deleteProof(
      identityNo: widget.identityNo,
      receiptId: invoice.id!,
      proofId: proof.id!,
      dormitoryId: widget.dormitoryId,
    );

    if (deleted && mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildRoomChangeBadge(DormitoryInvoiceModel invoice) {
    final String label = invoice.adjustedCount > 1
        ? 'Đã điều chỉnh ${invoice.adjustedCount} lần'
        : 'Có điều chỉnh phòng';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.swap_horiz_rounded, size: 13, color: Color(0xFF2563EB)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomChangeSummary(DormitoryInvoiceModel invoice) {
    final List<Widget> details = <Widget>[];

    if (_hasText(invoice.buildingName)) {
      details.add(_buildRoomChangeInfo(Icons.apartment_rounded, 'Tòa', invoice.buildingName!));
    }
    if (_hasText(invoice.roomNumber)) {
      details.add(_buildRoomChangeInfo(Icons.meeting_room_rounded, 'Phòng', invoice.roomNumber!));
    }
    if (_hasText(invoice.roomTypeName)) {
      details.add(_buildRoomChangeInfo(Icons.bed_rounded, 'Loại phòng', invoice.roomTypeName!));
    }
    if (invoice.roomTypePrice != null && invoice.roomTypePrice! > 0) {
      details.add(
        _buildRoomChangeInfo(
          Icons.payments_outlined,
          'Mức phí phòng',
          '${_formatMoney(invoice.roomTypePrice!)} đ',
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF0FDF4), Color(0xFFEFF6FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCDE9D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.swap_horiz_rounded, color: Color(0xFF078B3E), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hóa đơn đã gộp điều chỉnh phòng',
                  style: TextStyle(
                    fontSize: AppFontSizes.font11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12341F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            invoice.adjustedCount > 0
                ? 'Hệ thống đã cập nhật ${invoice.adjustedCount} lần điều chỉnh vào cùng một hóa đơn.'
                : 'Khoản chênh lệch do đổi phòng/loại phòng được theo dõi trên cùng hóa đơn này.',
            style: const TextStyle(
              fontSize: AppFontSizes.extraSmall,
              color: Color(0xFF526057),
              height: 1.35,
            ),
          ),
          if (details.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            ...details,
          ],
        ],
      ),
    );
  }

  Widget _buildRoomChangeInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: const Color(0xFF078B3E)),
          const SizedBox(width: 8),
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSizes.extraSmall,
                color: Color(0xFF667169),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppFontSizes.font11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
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

    final bool hasProofs = invoice.proofCount > 0;
    final bool pending = invoice.hasPendingPayment;

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
        icon: Icon(
          hasProofs ? Icons.add_photo_alternate_rounded : Icons.upload_file_rounded,
        ),
        label: Text(
          hasProofs || pending
              ? 'Bổ sung minh chứng thanh toán'
              : invoice.hasRejectedPayment
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

    if (_isPickingPaymentProof) return;

    _isPickingPaymentProof = true;
    final List<File> originalFiles = <File>[];
    final List<File> normalizedFiles = <File>[];

    try {
      final List<XFile> selectedImages = await _imagePicker.pickMultiImage(
        imageQuality: 100,
      );

      if (selectedImages.isEmpty) return;

      for (final XFile selectedImage in selectedImages) {
        final File selectedFile = File(selectedImage.path);
        originalFiles.add(selectedFile);

        final File preparedProofFile =
            await DormitoryImageUploadUtil.normalizeToJpeg(selectedFile);
        normalizedFiles.add(preparedProofFile);

        final int fileSize = await preparedProofFile.length();
        if (fileSize > _maxProofSizeBytes) {
          _showError(
            'Mỗi ảnh minh chứng không được vượt quá $_maxProofSizeMb MB',
          );
          return;
        }
      }

      if (!mounted) return;

      final PaymentProofConfirmResult? confirmResult =
          await _showProofConfirmDialog(normalizedFiles);

      if (confirmResult == null || !confirmResult.confirmed) return;

      await _cubit.uploadProof(
        identityNo: widget.identityNo,
        receiptId: invoice.id!,
        proofImages: normalizedFiles,
        note: confirmResult.note,
        dormitoryId: widget.dormitoryId,
      );
    } catch (error) {
      if (mounted) {
        _showError(
          AppErrorMapper.map(
            error,
            fallbackMessage: 'Không thể thực hiện thao tác này. Vui lòng thử lại.',
          ).userMessage,
        );
      }
    } finally {
      _isPickingPaymentProof = false;

      for (int index = 0; index < normalizedFiles.length; index++) {
        await DormitoryImageUploadUtil.deleteTemporaryFile(
          normalizedFile: normalizedFiles[index],
          originalFile: index < originalFiles.length ? originalFiles[index] : null,
        );
      }
    }
  }

  Future<PaymentProofConfirmResult?> _showProofConfirmDialog(
    List<File> proofFiles,
  ) {
    return showDialog<PaymentProofConfirmResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _PaymentProofConfirmDialog(
          proofFiles: proofFiles,
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


class _PaymentProofConfirmDialog extends StatefulWidget {
  final List<File> proofFiles;

  const _PaymentProofConfirmDialog({
    required this.proofFiles,
  });

  @override
  State<_PaymentProofConfirmDialog> createState() =>
      _PaymentProofConfirmDialogState();
}

class _PaymentProofConfirmDialogState
    extends State<_PaymentProofConfirmDialog> {
  late final TextEditingController _noteController;

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
    final String note = _noteController.text.trim();
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
    final double maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF8EF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF078B3E),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Xác nhận minh chứng',
                            style: TextStyle(
                              fontSize: AppFontSizes.medium,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15181D),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.proofFiles.length} ảnh sẽ được gửi cùng lần này',
                            style: const TextStyle(
                              fontSize: AppFontSizes.extraSmall,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: _close,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: widget.proofFiles.length == 1 ? 230 : 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.proofFiles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final File file = widget.proofFiles[index];
                      return Container(
                        width: widget.proofFiles.length == 1 ? 260 : 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8E4)),
                        ),
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(
                                  file,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Text('Không hiển thị được ảnh'),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 7,
                              left: 7,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.62),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  '${index + 1}/${widget.proofFiles.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                VnuFloatingTextFieldAdapter(
                  controller: _noteController,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 500,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú thanh toán',
                    hintText: 'Ví dụ: Nộp bổ sung chênh lệch đổi phòng',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFFFFF8E7), Color(0xFFF2FBF5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFF766220),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Có thể chọn nhiều ảnh và tiếp tục bổ sung minh chứng '
                          'sau lần gửi đầu tiên. Mỗi ảnh tối đa 4 MB.',
                          style: TextStyle(
                            fontSize: AppFontSizes.font11,
                            height: 1.35,
                            color: Color(0xFF5E552A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool useColumn = constraints.maxWidth < 330;

                    final Widget cancelButton = OutlinedButton(
                      onPressed: _close,
                      child: const Text('Chọn lại'),
                    );

                    final Widget submitButton = FilledButton.icon(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF078B3E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.send_rounded),
                      label: Text(
                        widget.proofFiles.length > 1
                            ? 'Gửi ${widget.proofFiles.length} minh chứng'
                            : 'Gửi minh chứng',
                      ),
                    );

                    if (useColumn) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          submitButton,
                          const SizedBox(height: 10),
                          cancelButton,
                        ],
                      );
                    }

                    return Row(
                      children: <Widget>[
                        Expanded(child: cancelButton),
                        const SizedBox(width: 12),
                        Expanded(child: submitButton),
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
