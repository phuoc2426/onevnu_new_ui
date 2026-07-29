import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/notify/views/vcore_notify_view_v3.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/repository/applicant_session_repository.dart';
import 'package:vnu_core/screens/vcore_admission_view.dart';
import 'package:vnu_noi_tru/screens/dormitory_registration/dr_my_registration_screen.dart';

class YourSpaceScreen extends StatefulWidget {
  final String fullName;

  const YourSpaceScreen({
    super.key,
    required this.fullName,
  });

  @override
  State<YourSpaceScreen> createState() =>
      _YourSpaceScreenState();
}

class _YourSpaceScreenState extends State<YourSpaceScreen>
    with WidgetsBindingObserver {
  int _systemUnreadCount = 0;

  bool _isLoadingUnreadCount = false;
  bool _isLoggingOut = false;

  int _buildCount = 0;
  DateTime? _screenOpenedAt;
  String? _currentRouteName;

  void _log(String message) {
    debugPrint('[YOUR_SPACE] $message');
  }

  void _logException(
      String action,
      Object error,
      StackTrace stackTrace,
      ) {
    logError(
      '[YOUR_SPACE][$action] '
          'Error: $error\n'
          'StackTrace: $stackTrace',
    );

    debugPrint(
      '[YOUR_SPACE][$action] Error: $error',
    );

    debugPrintStack(
      label: '[YOUR_SPACE][$action] StackTrace',
      stackTrace: stackTrace,
    );
  }

  @override
  void initState() {
    super.initState();

    _screenOpenedAt = DateTime.now();

    WidgetsBinding.instance.addObserver(this);

    _log(
      'initState | '
          'fullName=${widget.fullName} | '
          'mounted=$mounted',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _log(
        'Frame đầu tiên hoàn thành | '
            'mounted=$mounted',
      );

      if (!mounted) {
        _log(
          'Không gọi notification API vì '
              'widget đã unmounted sau frame đầu tiên',
        );
        return;
      }

      final ModalRoute<dynamic>? route =
      ModalRoute.of(context);

      _currentRouteName = route?.settings.name;

      _log(
        'Thông tin route sau frame đầu tiên | '
            'routeName=${route?.settings.name} | '
            'isCurrent=${route?.isCurrent} | '
            'canPop=${route?.canPop}',
      );

      _loadSystemUnreadCount();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final ModalRoute<dynamic>? route =
    ModalRoute.of(context);

    final String? newRouteName =
        route?.settings.name;

    if (_currentRouteName != newRouteName) {
      _log(
        'Route thay đổi | '
            'oldRoute=$_currentRouteName | '
            'newRoute=$newRouteName',
      );

      _currentRouteName = newRouteName;
    }

    _log(
      'didChangeDependencies | '
          'routeName=${route?.settings.name} | '
          'isCurrent=${route?.isCurrent} | '
          'canPop=${route?.canPop}',
    );
  }

  @override
  void didUpdateWidget(
      covariant YourSpaceScreen oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    _log(
      'didUpdateWidget | '
          'oldFullName=${oldWidget.fullName} | '
          'newFullName=${widget.fullName}',
    );
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    _log(
      'App lifecycle thay đổi | state=$state',
    );
  }

  @override
  void deactivate() {
    final ModalRoute<dynamic>? route =
    ModalRoute.of(context);

    _log(
      'deactivate | '
          'routeName=${route?.settings.name} | '
          'isCurrent=${route?.isCurrent}',
    );

    super.deactivate();
  }

  @override
  void dispose() {
    final DateTime now = DateTime.now();

    final int? aliveMilliseconds =
    _screenOpenedAt == null
        ? null
        : now
        .difference(_screenOpenedAt!)
        .inMilliseconds;

    _log(
      'dispose | '
          'Thời gian tồn tại=${aliveMilliseconds ?? 0}ms | '
          'unreadCount=$_systemUnreadCount | '
          'isLoadingUnread=$_isLoadingUnreadCount | '
          'isLoggingOut=$_isLoggingOut',
    );

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _log(
      'Người dùng kéo để làm mới màn hình',
    );

    await _loadSystemUnreadCount();

    _log(
      'Hoàn thành làm mới màn hình',
    );
  }

  Future<void> _loadSystemUnreadCount() async {
    if (_isLoadingUnreadCount) {
      _log(
        'Bỏ qua tải unread count vì '
            'đang có request khác chạy',
      );
      return;
    }

    _isLoadingUnreadCount = true;

    final DateTime startedAt = DateTime.now();

    _log(
      'Bắt đầu tải số thông báo chưa đọc | '
          'mounted=$mounted | '
          'currentCount=$_systemUnreadCount',
    );

    try {
      final int count = await ApiRepository()
          .getNotificationCount(
        isRead: false,
      );

      final int elapsedMilliseconds =
          DateTime.now()
              .difference(startedAt)
              .inMilliseconds;

      _log(
        'Notification API thành công | '
            'count=$count | '
            'elapsed=${elapsedMilliseconds}ms | '
            'mounted=$mounted',
      );

      if (!mounted) {
        _log(
          'Không setState unread count vì '
              'YourSpaceScreen đã unmounted',
        );
        return;
      }

      final int oldCount =
          _systemUnreadCount;

      setState(() {
        _systemUnreadCount = count;
      });

      _log(
        'Đã cập nhật unread count | '
            'oldCount=$oldCount | '
            'newCount=$count',
      );
    } catch (error, stackTrace) {
      _logException(
        'LOAD_NOTIFICATION_COUNT',
        error,
        stackTrace,
      );

      _log(
        'Notification API lỗi, '
            'chuyển unread count về 0 | '
            'mounted=$mounted',
      );

      if (!mounted) {
        _log(
          'Không setState count=0 vì '
              'YourSpaceScreen đã unmounted',
        );
        return;
      }

      setState(() {
        _systemUnreadCount = 0;
      });

      _log(
        'Đã xử lý lỗi notification an toàn, '
            'màn hình vẫn tiếp tục hoạt động',
      );
    } finally {
      _isLoadingUnreadCount = false;

      final int elapsedMilliseconds =
          DateTime.now()
              .difference(startedAt)
              .inMilliseconds;

      _log(
        'Kết thúc tải unread count | '
            'elapsed=${elapsedMilliseconds}ms | '
            'mounted=$mounted | '
            'count=$_systemUnreadCount',
      );
    }
  }

  Future<void> _openSystemNotifications() async {
    _log(
      'Chuẩn bị mở VcoreNotifyViewV3 | '
          'systemOnly=true | '
          'unreadCount=$_systemUnreadCount',
    );

    try {
      final dynamic result = await Get.to(
            () => const VcoreNotifyViewV3(
          systemOnly: true,
        ),
        transition: Transition.rightToLeft,
        duration: const Duration(
          milliseconds: 250,
        ),
      );

      _log(
        'VcoreNotifyViewV3 đã đóng | '
            'result=$result | '
            'mounted=$mounted',
      );

      if (!mounted) {
        _log(
          'Không tải lại unread count vì '
              'YourSpaceScreen đã unmounted',
        );
        return;
      }

      await _loadSystemUnreadCount();
    } catch (error, stackTrace) {
      _logException(
        'OPEN_NOTIFICATION_SCREEN',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _openDormitoryScreen() async {
    _log(
      'Chuẩn bị mở DRMyRegistrationScreen',
    );

    try {
      final dynamic result = await Get.to(
            () => const DRMyRegistrationScreen(),
        transition: Transition.rightToLeft,
        duration: const Duration(
          milliseconds: 250,
        ),
      );

      _log(
        'DRMyRegistrationScreen đã đóng | '
            'result=$result | '
            'mounted=$mounted',
      );
    } catch (error, stackTrace) {
      _logException(
        'OPEN_DORMITORY_SCREEN',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _openMenu() async {
    if (_isLoggingOut) {
      _log(
        'Không mở menu vì đang đăng xuất',
      );
      return;
    }

    _log(
      'Người dùng bấm nút menu',
    );

    try {
      final dynamic result =
      await Get.bottomSheet(
        _LogoutBottomSheet(
          isLoading: _isLoggingOut,
          onConfirm: _logout,
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );

      _log(
        'Bottom sheet menu đã đóng | '
            'result=$result | '
            'mounted=$mounted',
      );
    } catch (error, stackTrace) {
      _logException(
        'OPEN_LOGOUT_BOTTOM_SHEET',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      _log(
        'Bỏ qua yêu cầu đăng xuất vì '
            'đang có tiến trình đăng xuất',
      );
      return;
    }

    _isLoggingOut = true;

    if (mounted) {
      setState(() {});
    }

    final DateTime startedAt =
    DateTime.now();

    _log(
      'Bắt đầu đăng xuất | '
          'mounted=$mounted',
    );

    try {
      try {
        _log(
          'Bắt đầu gọi applicantSignout trên server',
        );

        await ApiRepository()
            .applicantSignout();

        _log(
          'Server applicantSignout thành công',
        );
      } catch (error, stackTrace) {
        logError(
          '[APPLICANT_LOGOUT] '
              'Server logout error: '
              '$error\n$stackTrace',
        );

        debugPrint(
          '[YOUR_SPACE][LOGOUT] '
              'Server logout lỗi nhưng vẫn tiếp tục '
              'xóa session local: $error',
        );

        debugPrintStack(
          label:
          '[YOUR_SPACE][LOGOUT_SERVER] StackTrace',
          stackTrace: stackTrace,
        );
      }

      _log(
        'Bắt đầu xóa ApplicantSessionRepository',
      );

      await ApplicantSessionRepository()
          .clear();

      _log(
        'Đã xóa ApplicantSessionRepository',
      );

      Globals().token = '';
      Globals().refreshToken = '';

      _log(
        'Đã xóa token và refreshToken trong Globals',
      );

      ApiRepository().setToken('');

      _log(
        'Đã xóa token trong ApiRepository',
      );

      final int elapsedMilliseconds =
          DateTime.now()
              .difference(startedAt)
              .inMilliseconds;

      _log(
        'Chuẩn bị Get.offAll về '
            'VcoreAdmissionView | '
            'elapsed=${elapsedMilliseconds}ms',
      );

      Get.offAll(
            () => const VcoreAdmissionView(),
      );

      _log(
        'Đã gửi lệnh Get.offAll '
            'đến VcoreAdmissionView',
      );
    } catch (error, stackTrace) {
      _logException(
        'LOGOUT_CLEAR_SESSION',
        error,
        stackTrace,
      );

      if (!mounted) {
        _log(
          'Không hiện SnackBar lỗi đăng xuất vì '
              'YourSpaceScreen đã unmounted',
        );
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Không thể đăng xuất: $error',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    } finally {
      _isLoggingOut = false;

      if (mounted) {
        setState(() {});
      }

      _log(
        'Kết thúc tiến trình đăng xuất | '
            'mounted=$mounted',
      );
    }
  }

  String? get _unreadBadge {
    if (_systemUnreadCount <= 0) {
      return null;
    }

    if (_systemUnreadCount > 99) {
      return '99+';
    }

    return _systemUnreadCount.toString();
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;

    final ModalRoute<dynamic>? route =
    ModalRoute.of(context);

    _log(
      'build lần $_buildCount | '
          'mounted=$mounted | '
          'routeName=${route?.settings.name} | '
          'isCurrent=${route?.isCurrent} | '
          'canPop=${route?.canPop} | '
          'unreadCount=$_systemUnreadCount | '
          'isLoadingUnread=$_isLoadingUnreadCount | '
          'isLoggingOut=$_isLoggingOut',
    );

    return WillPopScope(
      onWillPop: () async {
        final ModalRoute<dynamic>? currentRoute =
        ModalRoute.of(context);

        _log(
          'Nhận yêu cầu Back/Pop | '
              'routeName=${currentRoute?.settings.name} | '
              'isCurrent=${currentRoute?.isCurrent} | '
              'canPop=${currentRoute?.canPop}',
        );

        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.homeBg,
        body: SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bg2.png',
                  fit: BoxFit.cover,
                  errorBuilder: (
                      context,
                      error,
                      stackTrace,
                      ) {
                    logError(
                      '[YOUR_SPACE][BACKGROUND_IMAGE] '
                          'Không tải được assets/images/bg2.png: '
                          '$error\n$stackTrace',
                    );

                    debugPrint(
                      '[YOUR_SPACE] '
                          'Không tải được ảnh nền bg2.png, '
                          'dùng màu nền thay thế',
                    );

                    return Container(
                      color: AppColors.homeBg,
                    );
                  },
                ),
              ),
              SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: AppColors.brandGreen,
                  child: SingleChildScrollView(
                    physics:
                    const AlwaysScrollableScrollPhysics(),
                    padding:
                    const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 24),
                        _buildServicesSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Chào, ${widget.fullName}',
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize:
                  AppFontSizes.mediumLarge,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Không gian cá nhân của tân sinh viên',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize:
                  AppFontSizes.font12_5,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildNotificationButton(),
        const SizedBox(width: 8),
        _buildMenuButton(context),
      ],
    );
  }

  Widget _buildNotificationButton() {
    final String? badge =
        _unreadBadge;

    return Semantics(
      button: true,
      label: badge == null
          ? 'Thông báo hệ thống'
          : 'Thông báo hệ thống, '
          '$badge thông báo chưa đọc',
      child: Material(
        color: Colors.transparent,
        borderRadius:
        BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            _log(
              'Người dùng bấm nút thông báo '
                  'ở phần header',
            );

            _openSystemNotifications();
          },
          borderRadius:
          BorderRadius.circular(14),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _HeaderIconContainer(
                icon: Icons
                    .notifications_none_rounded,
                iconColor:
                AppColors.brandGreen,
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    constraints:
                    const BoxConstraints(
                      minWidth: 19,
                      minHeight: 19,
                    ),
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    alignment:
                    Alignment.center,
                    decoration:
                    const BoxDecoration(
                      color:
                      Colors.redAccent,
                      shape:
                      BoxShape.circle,
                    ),
                    child: Text(
                      badge,
                      style:
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context,
      ) {
    return Material(
      color: Colors.transparent,
      borderRadius:
      BorderRadius.circular(14),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(14),
        onTap: _openMenu,
        child:
        const _HeaderIconContainer(
          icon: Icons.more_horiz,
          iconColor:
          AppColors.brandGreen,
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    const List<_ServiceItem> services = [
      _ServiceItem(
        label: 'Nội trú',
        icon: Icons.home_work_rounded,
        color: Color(0xFFBF5AF2),
        type: _ServiceType.dormitory,
      ),
      _ServiceItem(
        label: 'Thông báo',
        icon: Icons
            .notifications_active_outlined,
        color: Color(0xFF34C759),
        type: _ServiceType.notification,
      ),
    ];

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'DỊCH VỤ CỦA BẠN',
            style: TextStyle(
              color: AppColors.brandGreen,
              fontSize:
              AppFontSizes.mediumSmall,
              fontWeight:
              FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: services.length,
          itemBuilder: (
              context,
              index,
              ) {
            return _buildServiceCard(
              context,
              services[index],
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(
      BuildContext context,
      _ServiceItem item,
      ) {
    return Material(
      color: Colors.transparent,
      borderRadius:
      BorderRadius.circular(18),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(18),
        onTap: () {
          _log(
            'Người dùng bấm dịch vụ | '
                'label=${item.label} | '
                'type=${item.type}',
          );

          switch (item.type) {
            case _ServiceType.dormitory:
              _openDormitoryScreen();
              break;

            case _ServiceType.notification:
              _openSystemNotifications();
              break;
          }
        },
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color:
                Colors.black.withOpacity(
                  0.06,
                ),
                blurRadius: 14,
                offset:
                const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration:
                      BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(
                          18,
                        ),
                        gradient:
                        LinearGradient(
                          begin:
                          Alignment.topLeft,
                          end: Alignment
                              .bottomRight,
                          colors: [
                            item.color
                                .withOpacity(
                              0.08,
                            ),
                            item.color
                                .withOpacity(
                              0.18,
                            ),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .white
                                .withOpacity(
                              0.8,
                            ),
                            blurRadius: 6,
                            offset:
                            const Offset(
                              -2,
                              -2,
                            ),
                          ),
                          BoxShadow(
                            color: item.color
                                .withOpacity(
                              0.18,
                            ),
                            blurRadius: 12,
                            offset:
                            const Offset(
                              3,
                              5,
                            ),
                          ),
                        ],
                      ),
                      child: Icon(
                        item.icon,
                        size: 26,
                        color: item.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      child: Text(
                        item.label,
                        textAlign:
                        TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          color:
                          AppColors.darkNavy,
                          fontSize: AppFontSizes
                              .font11_5,
                          fontWeight:
                          FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (item.type ==
                  _ServiceType
                      .notification &&
                  _unreadBadge != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    constraints:
                    const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 5,
                    ),
                    alignment:
                    Alignment.center,
                    decoration:
                    const BoxDecoration(
                      color:
                      Colors.redAccent,
                      shape:
                      BoxShape.circle,
                    ),
                    child: Text(
                      _unreadBadge!,
                      style:
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconContainer
    extends StatelessWidget {
  final IconData icon;
  final Color iconColor;

  const _HeaderIconContainer({
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(
              0.8,
            ),
            blurRadius: 4,
            offset: const Offset(-1, -1),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(
              0.08,
            ),
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 22,
      ),
    );
  }
}

enum _ServiceType {
  dormitory,
  notification,
}

class _ServiceItem {
  final String label;
  final IconData icon;
  final Color color;
  final _ServiceType type;

  const _ServiceItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class _LogoutBottomSheet
    extends StatelessWidget {
  final Future<void> Function() onConfirm;
  final bool isLoading;

  const _LogoutBottomSheet({
    super.key,
    required this.onConfirm,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[YOUR_SPACE][LOGOUT_SHEET] '
          'build | isLoading=$isLoading',
    );

    return SafeArea(
      top: false,
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 24,
        ),
        decoration:
        const BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration:
                BoxDecoration(
                  color:
                  Colors.grey.shade300,
                  borderRadius:
                  BorderRadius.circular(
                    99,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn có chắc muốn đăng xuất?',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn sẽ cần sử dụng CCCD và số điện thoại '
                  'đã đăng ký với nhà trường để đăng nhập lại.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              enabled: !isLoading,
              leading: isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(
                Icons.logout,
                color:
                Colors.redAccent,
              ),
              title: Text(
                isLoading
                    ? 'Đang đăng xuất...'
                    : 'Đăng xuất',
              ),
              onTap: isLoading
                  ? null
                  : () async {
                debugPrint(
                  '[YOUR_SPACE]'
                      '[LOGOUT_SHEET] '
                      'Người dùng xác nhận đăng xuất',
                );

                Get.back();

                debugPrint(
                  '[YOUR_SPACE]'
                      '[LOGOUT_SHEET] '
                      'Đã đóng bottom sheet, '
                      'bắt đầu gọi onConfirm',
                );

                await onConfirm();
              },
            ),
            ListTile(
              enabled: !isLoading,
              leading:
              const Icon(Icons.close),
              title: const Text('Hủy'),
              onTap: isLoading
                  ? null
                  : () {
                debugPrint(
                  '[YOUR_SPACE]'
                      '[LOGOUT_SHEET] '
                      'Người dùng hủy đăng xuất',
                );

                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}