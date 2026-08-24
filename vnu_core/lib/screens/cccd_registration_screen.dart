import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/vnu_module_app_bar.dart';
import 'package:dio/dio.dart';
import 'package:vnu_core/services/applicant/applicant_api_service.dart';
import 'package:vnu_core/common/error/app_error_reporter.dart';
import 'package:vnu_core/common/error/app_error_mapper.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vnu_core/screens/dashboard_screen.dart';

class CccdRegistrationScreen extends StatefulWidget {
  const CccdRegistrationScreen({super.key});

  @override
  State<CccdRegistrationScreen> createState() => _CccdRegistrationScreenState();
}

class _CccdRegistrationScreenState extends State<CccdRegistrationScreen> {
  static const String _defaultMobileApiBase =
      'https://onevnu-mobile-api.vnu.edu.vn';

  // Đồng bộ màu với VcoreAdmissionView
  static const Color primaryGreen = Color(0xFF006B36);
  static const Color lightGreen = Color(0xFFEFF9F1);
  static const Color pageBg = Color(0xFFF6F7FB);
  static const Color textMuted = Color(0xFF6B7280);

  final _formKey = GlobalKey<ShadFormState>();
  final TextEditingController _cccdController = TextEditingController();
  final ApplicantApiService _apiService = ApplicantApiService(
    _defaultMobileApiBase,
  );
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final cccd = _cccdController.text.trim();
    if (cccd.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập số CCCD');
      setState(() => _isLoading = false);
      return;
    }
    try {
      // Use the centralized API service for CCCD login.
      await _apiService.cccdLogin(cccd);
      // If no exception, login succeeded and token is stored securely.
      if (mounted) {
        _showToast(
          icon: LucideIcons.circleCheck,
          color: primaryGreen,
          title: 'Thành công',
          message: 'Xác thực CCCD thành công',
        );
        // Navigate to the new dashboard screen.
        Get.off(() => const DashboardScreen());
      }
    } on DioException catch (e, stack) {
      final appError = AppErrorMapper.fromDio(e);
      unawaited(AppErrorReporter.report(appError, stackTrace: stack));
      if (mounted) {
        setState(() => _errorMessage = appError.displayMessage);
      }
    } catch (e, stack) {
      final appError = AppErrorMapper.map(
        e,
        stackTrace: stack,
        fallbackMessage:
            'Không thể xác thực thông tin lúc này. Vui lòng thử lại.',
      );
      unawaited(AppErrorReporter.report(appError, stackTrace: stack));
      if (mounted) {
        setState(() => _errorMessage = appError.displayMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    ShadToaster.of(context).show(
      ShadToast(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(title),
          ],
        ),
        description: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _cccdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: const VnuModuleAppBar(
        title: 'Đăng ký thí sinh trúng tuyển',
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    ShadCard(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                      child: ShadForm(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ShadInputFormField(
                              id: 'cccd',
                              controller: _cccdController,
                              label: const Text('Số CCCD'),
                              placeholder: const Text('Ví dụ: 001234567890'),
                              description: const Text(
                                'Số căn cước công dân dùng để đối chiếu với danh sách trúng tuyển.',
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 20,
                              leading: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(LucideIcons.idCard, size: 18),
                              ),
                              validator: (value) {
                                final v = value.trim();
                                if (v.isEmpty) {
                                  return 'Vui lòng nhập số CCCD';
                                }
                                if (v.length != 12) {
                                  return 'Số CCCD phải gồm 12 chữ số';
                                }
                                if (!RegExp(r'^\d{12}$').hasMatch(v)) {
                                  return 'Số CCCD chỉ được chứa chữ số';
                                }
                                return null;
                              },
                              onChanged: (_) {
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                              },
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 14),
                              ShadAlert.destructive(
                                icon: const Icon(LucideIcons.circleAlert),
                                title: const Text('Không thể xác thực'),
                                description: Text(_errorMessage!),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ShadButton(
                                onPressed: _isLoading ? null : _submit,
                                backgroundColor: primaryGreen,
                                hoverBackgroundColor: primaryGreen.withOpacity(
                                  0.9,
                                ),
                                leading: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        LucideIcons.arrowRight,
                                        size: 16,
                                      ),
                                child: Text(
                                  _isLoading ? 'Đang xác thực...' : 'Xác nhận',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHelperNote(theme),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.graduationCap,
              color: primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xác thực thí sinh trúng tuyển',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Nhập số CCCD để tiếp tục đăng ký ký túc xá và các thủ tục nhập học.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelperNote(ShadThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.shieldCheck, size: 14, color: textMuted),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'Thông tin CCCD của bạn chỉ được dùng để đối chiếu với danh sách trúng tuyển và không được chia sẻ cho bên thứ ba.',
            style: TextStyle(fontSize: 11, height: 1.4, color: textMuted),
          ),
        ),
      ],
    );
  }
}


