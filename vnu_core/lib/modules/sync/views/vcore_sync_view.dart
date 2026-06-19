import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/sync/vneid_deep_link_service.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcoreSyncView extends StatefulWidget {
  const VcoreSyncView({super.key});

  @override
  State<VcoreSyncView> createState() => _VcoreSyncViewState();
}

class _VcoreSyncViewState extends State<VcoreSyncView> {
  static final Uri _vneidShareUri = Uri.parse(
    'https://universal.dancuquocgia.com/share',
  );

  StreamSubscription<VneidDeepLinkEvent>? _callbackSubscription;

  bool _isCallingShareInfo = false;
  bool _isOpeningVneid = false;
  bool _isCheckingStatus = false;

  String? _currentTransitionCode;
  String? _currentResultCode;
  String? _screenMessage;

  VneidShareInfoStatusModel? _currentStatus;

  bool get _isBusy =>
      _isCallingShareInfo || _isOpeningVneid || _isCheckingStatus;

  @override
  void initState() {
    super.initState();

    VneidDeepLinkService().isSyncViewVisible = true;

    _callbackSubscription =
        VneidDeepLinkService().callbackStream.listen((event) {
          VneidDeepLinkService().consumeLatestCallback();
          _handleVneidCallback(event);
        });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final event = VneidDeepLinkService().consumeLatestCallback();

      if (event != null) {
        await _handleVneidCallback(event);
        return;
      }

      await _restoreLatestCachedTicket();
    });
  }

  @override
  void dispose() {
    VneidDeepLinkService().isSyncViewVisible = false;
    _callbackSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startVneidSync() async {
    if (_isBusy) return;

    setState(() {
      _isCallingShareInfo = true;
      _currentTransitionCode = null;
      _currentResultCode = null;
      _currentStatus = null;
      _screenMessage = 'Đang kiểm tra và gửi thông tin chia sẻ với OneVNU...';
    });

    try {
      // Bước 1: gọi share-info trước.
      // API này có nhiệm vụ validate dữ liệu và gắn cờ để VNeID mở popup consent.
      await ApiRepository().shareVneidInfo();

      if (!mounted) return;

      setState(() {
        _isCallingShareInfo = false;
        _isOpeningVneid = true;
        _screenMessage =
        'Đã gửi thông tin. Đang mở VNeID để xác nhận chia sẻ...';
      });

      // Bước 2: share-info OK thì mới mở VNeID.
      final isOpened = await launchUrl(
        _vneidShareUri,
        mode: LaunchMode.externalApplication,
      );

      if (!isOpened) {
        if (!mounted) return;

        setState(() {
          _screenMessage = 'Không thể mở ứng dụng VNeID. Vui lòng thử lại.';
        });

        snackBarError('Không thể mở ứng dụng VNeID. Vui lòng thử lại.');
        return;
      }

      if (!mounted) return;

      setState(() {
        _screenMessage =
        'Vui lòng hoàn tất xác nhận chia sẻ trên ứng dụng VNeID.';
      });
    } catch (e) {
      logError('VNeID share-info error: $e');

      if (!mounted) return;

      final message = _errorMessage(e);

      setState(() {
        _screenMessage = message;
      });

      snackBarError(message);
    } finally {
      if (mounted) {
        setState(() {
          _isCallingShareInfo = false;
          _isOpeningVneid = false;
        });
      }
    }
  }

  Future<void> _handleVneidCallback(VneidDeepLinkEvent event) async {
    if (!mounted) return;

    final data = event.data;

    if (data == null) {
      setState(() {
        _screenMessage = 'Không nhận được kết quả hợp lệ từ VNeID.';
      });

      snackBarError('Không nhận được kết quả hợp lệ từ VNeID.');
      return;
    }

    final transitionCode = data.transactionCode.trim();
    final resultCode = data.result.trim();

    if (transitionCode.isEmpty || !const ['1', '2', '3'].contains(resultCode)) {
      setState(() {
        _screenMessage = 'Không nhận được kết quả hợp lệ từ VNeID.';
      });

      snackBarError('Không nhận được kết quả hợp lệ từ VNeID.');
      return;
    }

    setState(() {
      _currentTransitionCode = transitionCode;
      _currentResultCode = resultCode;
      _currentStatus = null;
    });

    await ApiRepository().upsertVneidSyncTicket(
      VneidSyncTicket(
        transactionCode: transitionCode,
        createdAt: DateTime.now(),
        status: null,
        message: _resultLabel(resultCode),
      ),
    );
    // await ApiRepository().upsertVneidSyncTicket(
    //   VneidSyncTicket(
    //     transactionCode: transitionCode,
    //     result: resultCode,
    //     status: null,
    //     message: _resultLabel(resultCode),
    //     createdAt: DateTime.now(),
    //   ),
    // );

    if (resultCode == '2') {
      setState(() {
        _screenMessage = 'Bạn chưa đồng ý chia sẻ thông tin từ VNeID.';
      });

      snackBarWarning('Bạn chưa đồng ý chia sẻ thông tin từ VNeID.');
      return;
    }

    if (resultCode == '3') {
      setState(() {
        _screenMessage = 'Phiên chia sẻ thông tin đã hết hạn. Vui lòng thử lại.';
      });

      snackBarWarning('Phiên chia sẻ thông tin đã hết hạn.');
      return;
    }

    // resultCode = 1
    await _checkVneidStatus(transitionCode);
  }

  Future<void> _checkVneidStatus(String transitionCode) async {
    if (_isCheckingStatus) return;

    setState(() {
      _isCheckingStatus = true;
      _screenMessage = 'Đã xác nhận chia sẻ. Đang kiểm tra trạng thái phiếu...';
    });

    try {
      final response = await ApiRepository().getVneidShareInfoStatus(
        transitionCode,
      );

      if (!mounted) return;

      final status = response.status?.toUpperCase();
      await ApiRepository().upsertVneidSyncTicket(
        VneidSyncTicket(
          transactionCode: transitionCode,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: response.status,
          studentCode: response.studentCode,
          fullName: response.fullName,
          identityNo: response.identityNo,
          message: response.message,
        ),
      );
      setState(() {
        _currentStatus = response;
        _screenMessage = response.message?.trim().isNotEmpty == true
            ? response.message
            : 'Đã nhận trạng thái phiếu đồng bộ.';
      });

      if (status == 'SUCCESS') {
        snackBarSuccess('Đồng bộ thông tin thành công.');
      } else if (status == 'PENDING') {
        snackBarWarning('Phiếu đồng bộ đang được xử lý.');
      } else {
        snackBarError(response.message ?? 'Đồng bộ thông tin thất bại.');
      }
    } catch (e) {
      logError('VNeID status error: $e');

      if (!mounted) return;

      final message = _errorMessage(e);

      setState(() {
        _screenMessage = message;
      });

      snackBarError(message);
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        final message = data['message'].toString().trim();

        if (message.isNotEmpty) {
          return message;
        }
      }

      if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }
    }

    return 'Đồng bộ thông tin thất bại. Vui lòng kiểm tra lại thông tin sinh viên.';
  }

  String _maskIdentityNo(String value) {
    final normalized = value.trim();

    if (normalized.length <= 4) {
      return normalized;
    }

    final last4 = normalized.substring(normalized.length - 4);
    return '********$last4';
  }

  String _statusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUCCESS':
        return 'Thành công';
      case 'PENDING':
        return 'Đang xử lý';
      case 'FAILED':
        return 'Thất bại';
      case 'EXPIRED':
        return 'Hết hạn';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status ?? 'Chưa có trạng thái';
    }
  }

  Color _statusBackgroundColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUCCESS':
        return const Color(0xFFE8F5E9);
      case 'PENDING':
        return const Color(0xFFFFF8E1);
      case 'FAILED':
        return const Color(0xFFFFEBEE);
      case 'EXPIRED':
        return const Color(0xFFFFF3E0);
      case 'CANCELLED':
        return const Color(0xFFF5F5F5);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  Color _statusForegroundColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUCCESS':
        return const Color(0xFF2E7D32);
      case 'PENDING':
        return const Color(0xFFF57F17);
      case 'FAILED':
        return const Color(0xFFC62828);
      case 'EXPIRED':
        return const Color(0xFFE65100);
      case 'CANCELLED':
        return const Color(0xFF616161);
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _resultLabel(String? resultCode) {
    switch (resultCode) {
      case '1':
        return 'Đã đồng ý chia sẻ';
      case '2':
        return 'Không đồng ý chia sẻ';
      case '3':
        return 'Phiên chia sẻ hết hạn';
      default:
        return 'Chưa có kết quả';
    }
  }

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Đồng bộ VNeID',
      showBackButton: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroCard(),
                    if (_currentTransitionCode != null) ...[
                      const SizedBox(height: 16),
                      _buildCallbackCard(),
                    ],
                    if (_currentStatus != null) ...[
                      const SizedBox(height: 16),
                      _buildStatusCard(_currentStatus!),
                    ],
                  ],
                ),
              ),
            ),
            _buildBottomSyncBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF2563EB),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đồng bộ dữ liệu VNeID',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Hệ thống sẽ kiểm tra thông tin và mở VNeID để bạn xác nhận chia sẻ dữ liệu.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreLatestCachedTicket() async {
    final tickets = await ApiRepository().getCachedVneidSyncTickets();

    if (!mounted || tickets.isEmpty) return;

    final latest = tickets.first;

    setState(() {
      _currentTransitionCode = latest.transactionCode;
      _currentResultCode = null;

      _screenMessage = latest.message?.trim().isNotEmpty == true
          ? latest.message
          : 'Đã khôi phục mã giao dịch gần nhất.';

      if (latest.status?.trim().isNotEmpty == true) {
        _currentStatus = VneidShareInfoStatusModel(
          txnId: latest.transactionCode,
          status: latest.status,
          studentCode: latest.studentCode,
          fullName: latest.fullName,
          identityNo: latest.identityNo,
          message: latest.message,
        );
      } else {
        _currentStatus = null;
      }
    });
  }

  Widget _buildCallbackCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.link_outlined,
            title: 'Kết quả xác nhận từ VNeID',
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            'Mã giao dịch',
            _currentTransitionCode ?? '',
          ),
          _buildInfoRow(
            'Kết quả',
            _resultLabel(_currentResultCode),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(VneidShareInfoStatusModel status) {
    final statusCode = status.status?.toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSectionHeader(
                  icon: Icons.assignment_outlined,
                  title: 'Phiếu trạng thái đồng bộ',
                ),
              ),
              _buildStatusChip(statusCode),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            'Mã giao dịch',
            status.txnId?.trim().isNotEmpty == true
                ? status.txnId!
                : _currentTransitionCode ?? '',
          ),
          if ((status.studentCode ?? '').isNotEmpty)
            _buildInfoRow('Mã sinh viên', status.studentCode!),
          if ((status.fullName ?? '').isNotEmpty)
            _buildInfoRow('Họ tên', status.fullName!),
          if ((status.identityNo ?? '').isNotEmpty)
            _buildInfoRow('Số định danh', _maskIdentityNo(status.identityNo!)),
          if ((status.message ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildMessageBox(status.message!),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ShadButton.outline(
              onPressed: _currentTransitionCode == null || _isCheckingStatus
                  ? null
                  : () => _checkVneidStatus(_currentTransitionCode!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isCheckingStatus) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ] else ...[
                    const Icon(Icons.refresh, size: 16),
                  ],
                  const SizedBox(width: 6),
                  const Text('Kiểm tra lại'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF475569),
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _statusBackgroundColor(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: _statusForegroundColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF334155),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildBottomSyncBar() {
    final buttonText = _isCallingShareInfo
        ? 'Đang gửi yêu cầu...'
        : _isOpeningVneid
        ? 'Đang mở VNeID...'
        : _isCheckingStatus
        ? 'Đang kiểm tra...'
        : 'Đồng bộ dữ liệu VNeID';

    final helperText = _screenMessage?.trim().isNotEmpty == true
        ? _screenMessage!
        : 'Nhấn để đồng bộ dữ liệu thông tin';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            helperText,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed: _isBusy ? null : _startVneidSync,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isBusy) ...[
                      const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.sync_rounded,
                        size: 18,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}