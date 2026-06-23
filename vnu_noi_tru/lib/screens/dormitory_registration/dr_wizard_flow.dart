import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/loading_overlay.dart';
import 'package:vnu_noi_tru/cubit/dormitory_registration_cubit.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'dr_step1_period_screen.dart';
import 'dr_step2_dormitory_screen.dart';
import 'dr_step3_info_screen.dart';
import 'dr_step4_review_screen.dart';
import 'package:vnu_noi_tru/repository/dormitory_registration_repository.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/themes/app_theme.dart';

class DRWizardFlow extends StatefulWidget {
  final MyRegistrationModel? draft;

  const DRWizardFlow({super.key, this.draft});

  @override
  State<DRWizardFlow> createState() => _DRWizardFlowState();
}

class _DRWizardFlowState extends State<DRWizardFlow> {
  int _currentStep = 0;
  final _cubit = DormitoryRegistrationCubit();
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _uploadMessage = 'Đang xử lý...';
  bool _hasSavedOrSubmitted = false;

  static const String _uploadRegistrationMessage =
      '\u0110ang t\u1ea3i l\u00ean h\u1ed3 s\u01a1 \u0111\u0103ng k\u00fd...';

  // Global Keys for Steps validation
  final _step3FormKey = GlobalKey<FormState>();
  final _step3Key = GlobalKey<DRStep3InfoScreenState>();
  final _step4Key = GlobalKey<DRStep4ReviewScreenState>();

  @override
  void initState() {
    super.initState();
    _cubit.clearWizardData();
    _loadData();
  }

  void _loadData() async {
    await _cubit.getDormitories();
    await _cubit.getRoomTypes();
    await _cubit.getPriorityObjects();

    MyRegistrationModel? draft;
    if (widget.draft != null && widget.draft!.id != null) {
      try {
        await _cubit.getRegistrationDetail(widget.draft!.id!);
        if (_cubit.state is DormitoryRegistrationDetailLoaded) {
          draft =
              (_cubit.state as DormitoryRegistrationDetailLoaded).registration;
          _cubit.loadDraftData(draft);
        } else {
          draft = widget.draft!;
          _cubit.loadDraftData(draft);
        }
      } catch (e) {
        draft = widget.draft!;
        _cubit.loadDraftData(draft);
      }
    }
    if (_cubit.selectedDormitory?.id != null) {
      await _cubit.getRegistrationPeriods(
        dormitoryId: _cubit.selectedDormitory!.id!,
      );
      if (draft != null) {
        _cubit.loadDraftData(draft);
      }
    }
    await _cubit.getMyRegistrations();
  }

  Future<void> _nextStep() async {
    if (_currentStep == 0) {
      if (_cubit.selectedDormitory == null) {
        _showSnackbarError('Vui lòng chọn ký túc xá');
        return;
      }
      if (_cubit.selectedRoomType == null) {
        _showSnackbarError('Vui lòng chọn loại phòng');
        return;
      }
      await _cubit.getRegistrationPeriods(
        dormitoryId: _cubit.selectedDormitory!.id!,
      );
      if (_cubit.periods.isEmpty) {
        _showSnackbarError('Ký túc xá này chưa có đợt đăng ký đang mở');
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_cubit.selectedPeriod == null) {
        _showSnackbarError('Vui lòng chọn đợt đăng ký');
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_step3FormKey.currentState?.validate() != true) {
        _showSnackbarError('Vui lòng nhập đầy đủ các trường bắt buộc');
        return;
      }

      if (_cubit.cccdFrontFile == null && _cubit.cccdFrontAttachment == null) {
        _showSnackbarError('Vui lòng tải lên CCCD mặt trước');
        return;
      }

      if (_cubit.cccdBackFile == null && _cubit.cccdBackAttachment == null) {
        _showSnackbarError('Vui lòng tải lên CCCD mặt sau');
        return;
      }

      _step3Key.currentState?.saveDataToCubit();

      final confirmed = await _showReviewWarningDialogV3();
      if (confirmed == true) {
        setState(() => _currentStep = 3);
      }
    }
  }

  Future<bool?> _showReviewWarningDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.colorMain,
              secondary: AppTheme.colorMain,
            ),
          ),
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: Color(0xFF078B3E)),
                SizedBox(width: 8),
                Expanded(child: Text('Xác nhận thông tin')),
              ],
            ),
            content: const Text(
              'Hãy chắc chắn với các thông tin mà bạn gửi, nhất là với minh chứng và lý do.',
              style: TextStyle(height: 1.4),
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Kiểm tra lại'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Tiếp tục'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _showReviewWarningDialogV2() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(
                        Icons.verified_user_outlined,
                        color: AppTheme.colorMain,
                        size: 26,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'XÃ¡c nháº­n thÃ´ng tin',
                          style: TextStyle(
                            fontSize: AppFontSizes.extraLarge,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111318),
                            height: 1.2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'HÃ£y cháº¯c cháº¯n vá»›i cÃ¡c thÃ´ng tin mÃ  báº¡n gá»­i, nháº¥t lÃ  vá»›i minh chá»©ng vÃ  lÃ½ do.',
                    style: TextStyle(
                      fontSize: AppFontSizes.mediumSmall,
                      color: Color(0xFF444A54),
                      height: 1.45,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Kiá»ƒm tra láº¡i'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.colorMain,
                            side: const BorderSide(
                              color: AppTheme.colorMain,
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(
                              fontSize: AppFontSizes.mediumSmall,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Tiáº¿p tá»¥c'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.colorMain,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(
                              fontSize: AppFontSizes.mediumSmall,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showReviewWarningDialogV3() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(
                        Icons.verified_user_outlined,
                        color: AppTheme.colorMain,
                        size: 26,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'X\u00e1c nh\u1eadn th\u00f4ng tin',
                          style: TextStyle(
                            fontSize: AppFontSizes.extraLarge,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111318),
                            height: 1.2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'H\u00e3y ch\u1eafc ch\u1eafn v\u1edbi c\u00e1c th\u00f4ng tin m\u00e0 b\u1ea1n g\u1eedi, nh\u1ea5t l\u00e0 v\u1edbi minh ch\u1ee9ng v\u00e0 l\u00fd do.',
                    style: TextStyle(
                      fontSize: AppFontSizes.mediumSmall,
                      color: Color(0xFF444A54),
                      height: 1.45,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Ki\u1ec3m tra l\u1ea1i'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.colorMain,
                            side: const BorderSide(
                              color: AppTheme.colorMain,
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(
                              fontSize: AppFontSizes.mediumSmall,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Ti\u1ebfp t\u1ee5c'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.colorMain,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(
                              fontSize: AppFontSizes.mediumSmall,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _autoSaveDraft() async {
    if (_hasSavedOrSubmitted) return;
    if (_cubit.selectedPeriod == null ||
        _cubit.selectedDormitory == null ||
        _cubit.selectedRoomType == null) {
      return;
    }

    if (_currentStep >= 2) {
      _step3Key.currentState?.saveDataToCubit();
    }

    final student = Globals().thongTinSinhVienModel.value;
    if (student == null) return;

    final dobFormatted = student.ngaySinh != null
        ? DateFormat(
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
          ).format(student.ngaySinh!.toUtc())
        : '';
    final cccdIssueDateFormatted = student.ngayCapCmtCccd != null
        ? DateFormat(
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
          ).format(student.ngayCapCmtCccd!.toUtc())
        : '';

    final payload = await _cubit.buildRegistrationPayload(
      status: 'draft',
      reason: _cubit.tempReason ?? 'Lưu nháp đăng ký nội trú',
    );

    await _cubit.registerDormitory(payload);

    try {
      await _cubit.uploadCachedFiles();
      await DormitoryRegistrationRepository().registerDormitory(payload);
    } catch (e) {
      // Silent error catch
    }
  }

  Future<void> _autoSaveDraftAndExit() async {
    if (_hasSavedOrSubmitted) {
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    if (_cubit.selectedPeriod == null ||
        _cubit.selectedDormitory == null ||
        _cubit.selectedRoomType == null) {
      if (mounted) Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _uploadMessage = 'Đang tự động lưu nháp...';
    });

    try {
      await _autoSaveDraft();
    } catch (e) {
      // Ignore save draft error on exit
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _saveDraft() async {
    // If we are at Step 3 or 4, save data from forms to Cubit first
    if (_currentStep >= 2) {
      _step3Key.currentState?.saveDataToCubit();
    }

    if (_cubit.selectedPeriod == null) {
      _showSnackbarError('Thiếu thông tin đợt đăng ký');
      return;
    }
    if (_cubit.selectedDormitory == null) {
      _showSnackbarError('Thiếu thông tin ký túc xá');
      return;
    }
    if (_cubit.selectedRoomType == null) {
      _showSnackbarError('Thiếu thông tin loại phòng');
      return;
    }

    final uploadSuccess = await _cubit.uploadCachedFiles();
    if (!uploadSuccess) {
      return;
    }

    final student = Globals().thongTinSinhVienModel.value;
    if (student == null) {
      _showSnackbarError('Không tìm thấy thông tin sinh viên');
      return;
    }

    final dobFormatted = student.ngaySinh != null
        ? DateFormat(
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
          ).format(student.ngaySinh!.toUtc())
        : '';
    final cccdIssueDateFormatted = student.ngayCapCmtCccd != null
        ? DateFormat(
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
          ).format(student.ngayCapCmtCccd!.toUtc())
        : '';

    final payload = await _cubit.buildRegistrationPayload(
      status: 'draft',
      reason: _cubit.tempReason ?? 'Lưu nháp đăng ký nội trú',
    );

    await _cubit.registerDormitory(payload);

    _cubit.registerDormitory(payload);
  }

  Future<void> _submitRegistration() async {
    final reviewState = _step4Key.currentState;
    if (reviewState != null && !reviewState.isCommitted) {
      _showSnackbarError(
        'Bạn phải đồng ý cam kết thông tin cung cấp là chính xác',
      );
      return;
    }

    if (_cubit.selectedPeriod == null ||
        _cubit.selectedDormitory == null ||
        _cubit.selectedRoomType == null) {
      _showSnackbarError('Thiếu thông tin đăng ký');
      return;
    }

    final uploadSuccess = await _cubit.uploadCachedFiles();
    if (!uploadSuccess) {
      return;
    }

    final student = Globals().thongTinSinhVienModel.value;
    if (student == null) {
      _showSnackbarError('Không tìm thấy thông tin sinh viên');
      return;
    }

    final dobFormatted = student.ngaySinh != null
        ? DateFormat(
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
          ).format(student.ngaySinh!.toUtc())
        : '';
    final cccdIssueDateFormatted = student.ngayCapCmtCccd != null
        ? DateFormat(
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
          ).format(student.ngayCapCmtCccd!.toUtc())
        : '';

    final payload = await _cubit.buildRegistrationPayload(
      status: 'pending',
      reason: _cubit.tempReason ?? 'Đăng ký nội trú',
    );

    await _cubit.submitRegistration(payload);
    _cubit.registerDormitory(payload);
  }

  void _showSnackbarError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildStepContent() {
    Widget child;
    switch (_currentStep) {
      case 0:
        child = const DRStep2DormitoryScreen(key: ValueKey(0));
        break;
      case 1:
        child = const DRStep1PeriodScreen(key: ValueKey(1));
        break;
      case 2:
        child = KeyedSubtree(
          key: const ValueKey(2),
          child: DRStep3InfoScreen(key: _step3Key, formKey: _step3FormKey),
        );
        break;
      case 3:
        child = KeyedSubtree(
          key: const ValueKey(3),
          child: DRStep4ReviewScreen(key: _step4Key),
        );
        break;
      default:
        child = const DRStep1PeriodScreen(key: ValueKey(0));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DormitoryRegistrationCubit>(
      create: (context) => _cubit,
      child: BlocListener<DormitoryRegistrationCubit, DormitoryRegistrationState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state is DormitoryRegistrationShowHub) {
            setState(() {
              _isLoading = true;
              _uploadProgress = 0.0;
              _uploadMessage = 'Đang chuẩn bị hồ sơ...';
            });
          }
          if (state is DormitoryRegistrationUploadProgress) {
            setState(() {
              _isLoading = true;
              _uploadProgress = state.progress;
              _uploadMessage = state.message;
            });
          }
          if (state is DormitoryRegistrationDismissHub) {
            setState(() {
              _isLoading = false;
            });
          }

          if (state is DormitoryRegistrationSavedSuccess) {
            _hasSavedOrSubmitted = true;
            setState(() {
              _isLoading = false;
            });
            Navigator.pop(
              context,
              'Bạn đã đăng ký nội trú thành công, kết quả đăng ký sẽ được xử lý trong thời gian sớm nhất. Vui lòng chú ý điện thoại cá nhân.',
            );
          }

          if (state is DormitoryRegistrationError) {
            setState(() {
              _isLoading = false;
            });
            _showSnackbarError(state.message);
          }

          if (state is DormitoryRegistrationUploadError) {
            setState(() {
              _isLoading = false;
            });
            _showSnackbarError(state.message);
          }
        },
        child: PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            await _autoSaveDraftAndExit();
          },
          child: LoadingOverlay(
            isLoading: _isLoading,
            progressIndicator: Material(
              color: Colors.transparent,
              child: DefaultTextStyle(
                style: const TextStyle(decoration: TextDecoration.none),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _uploadProgress,
                              color: AppTheme.colorMain,
                              backgroundColor: const Color(0xFFEAF8EF),
                              strokeWidth: 6,
                            ),
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: AppFontSizes.medium,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.colorMain,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _uploadRegistrationMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: AppFontSizes.mediumSmall,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111318),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      if (false)
                        const Text(
                          'Äang táº£i lÃªn há»“ sÆ¡ Ä‘Äƒng kÃ½...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppFontSizes.mediumSmall,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111318),
                            decoration: TextDecoration.none,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            child: VcoreModuleScaffold(
              title: 'Đăng ký nội trú',
              showBackButton: true,
              body: Column(
                children: [
                  _buildStepIndicator(),
                  Expanded(child: _buildStepContent()),
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    double progressWidth = 0.0;

    switch (_currentStep) {
      case 0:
        progressWidth = 0.0;
        break;
      case 1:
        progressWidth = 1 / 3;
        break;
      case 2:
        progressWidth = 2 / 3;
        break;
      case 3:
        progressWidth = 1.0;
        break;
    }

    final steps = ['KTX & loại phòng', 'Chọn đợt', 'Hồ sơ cá nhân', 'Xác nhận'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          SizedBox(
            height: 35,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const circleSize = 35.0;
                final lineWidth = constraints.maxWidth - circleSize;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: circleSize / 2,
                      right: circleSize / 2,
                      top: 16.5,
                      child: Container(
                        height: 2,
                        color: const Color(0xFFE3E6EB),
                      ),
                    ),
                    Positioned(
                      left: circleSize / 2,
                      top: 16.5,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: 2,
                        width: lineWidth * progressWidth,
                        color: const Color(0xFF078B3E),
                      ),
                    ),
                    Row(
                      children: List.generate(4, (index) {
                        final isDone = index < _currentStep;
                        final isActive = index == _currentStep;

                        return Expanded(
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              width: circleSize,
                              height: circleSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone || isActive
                                    ? const Color(0xFF078B3E)
                                    : Colors.white,
                                border: Border.all(
                                  color: isDone || isActive
                                      ? const Color(0xFF078B3E)
                                      : const Color(0xFFCFD4DC),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: isDone
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: isActive || isDone
                                              ? Colors.white
                                              : const Color(0xFF555B64),
                                          fontWeight: FontWeight.w800,
                                          fontSize: AppFontSizes.mediumSmall,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(4, (index) {
              final isActive = index == _currentStep;
              final isDone = index < _currentStep;

              return Expanded(
                child: Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: AppFontSizes.extraExtraSmall,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive || isDone
                        ? const Color(0xFF078B3E)
                        : const Color(0xFF666B75),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isSaveDraftButton = _currentStep == 3;
    final isSubmitButton = _currentStep == 3;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3E6EB), width: 1.0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 51,
                child: OutlinedButton.icon(
                  onPressed: _prevStep,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'Quay lại',
                    style: TextStyle(
                      fontSize: AppFontSizes.mediumSmall,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF078B3E),
                    side: const BorderSide(
                      color: Color(0xFF078B3E),
                      width: 1.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: SizedBox(
                height: 51,
                child: FilledButton.icon(
                  onPressed: isSubmitButton ? _submitRegistration : _nextStep,
                  icon: Icon(
                    isSubmitButton
                        ? Icons.send_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isSubmitButton ? 'Gửi đăng ký' : 'Tiếp tục',
                    style: const TextStyle(
                      fontSize: AppFontSizes.mediumSmall,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF078B3E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
