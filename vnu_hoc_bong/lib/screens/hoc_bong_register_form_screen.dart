import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/utils.dart';

import '../cubit/hoc_bong_form_cubit.dart';
import '../cubit/hoc_bong_states.dart';
import '../repository/hoc_bong_repository.dart';
import '../widgets/hoc_bong_dynamic_form_field.dart';
import '../widgets/hoc_bong_empty_state.dart';
import '../widgets/hoc_bong_screen_shell.dart';

class HocBongRegisterFormScreen extends StatefulWidget {
  final int hocBongId;
  final HocBongRepository repository;

  const HocBongRegisterFormScreen({super.key, required this.hocBongId, required this.repository});

  @override
  State<HocBongRegisterFormScreen> createState() => _HocBongRegisterFormScreenState();
}

class _HocBongRegisterFormScreenState extends State<HocBongRegisterFormScreen> with WidgetsBindingObserver {
  late final HocBongFormCubit cubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    cubit = HocBongFormCubit(widget.repository, widget.hocBongId)..init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cubit.saveBeforeLeave();
    cubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      cubit.saveBeforeLeave();
    }
  }

  Future<bool> _onWillPop() async {
    await cubit.saveBeforeLeave();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: HocBongScreenShell(
        title: 'Đăng ký học bổng',
        body: BlocConsumer<HocBongFormCubit, HocBongFormState>(
          bloc: cubit,
          listener: (context, state) {
            final msg = state.error ?? state.message;
            if (msg != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          },
          builder: (context, state) {
            if (state.loading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenAccent),
                ),
              );
            }
            final detail = state.detail;
            if (detail == null) return HocBongEmptyState(title: state.error ?? 'Không tải được form đăng ký', onRetry: cubit.init);
            final fields = detail.formFields;
            if (fields.isEmpty) {
              return HocBongEmptyState(
                title: 'Chưa có trường thông tin đăng ký.\nVui lòng liên hệ phòng đào tạo hoặc thử lại sau.',
                onRetry: cubit.init,
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.hocBong.tenHocBong ?? 'Học bổng',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                state.dirty
                                    ? 'Đã lưu nháp trên thiết bị'
                                    : 'Bản nháp đã được lưu trên thiết bị',
                                style: TextStyle(color: Colors.green.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: fields.map((field) {
                              return HocBongDynamicFormField(
                                field: field,
                                value: state.values[field.maTruong],
                                pendingFilePath: state.pendingFilePaths[field.maTruong],
                                onChanged: (v) => cubit.updateField(field.maTruong, v),
                                onFileSelected: (File file) => cubit.uploadFileForField(field, file),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.submitting
                            ? null
                            : () {
                                Utils.showAlertDialog(
                                  context,
                                  'Xác nhận nộp hồ sơ',
                                  'Bạn có chắc chắn muốn nộp hồ sơ đăng ký học bổng này? Thông tin sau khi gửi sẽ không thể chỉnh sửa và được chuyển đến hội đồng xét tuyển.',
                                  cancelStr: 'Hủy',
                                  okStr: 'Đồng ý',
                                  callBackOK: () => cubit.submit(),
                                  withoutBinding: true,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          state.submitting ? 'Đang gửi hồ sơ...' : 'Gửi hồ sơ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
