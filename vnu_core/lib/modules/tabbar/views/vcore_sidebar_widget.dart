import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/extensions/map_ext.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/box_service_model.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/modules/cam_nang/views/vcore_cam_nang_view.dart';
import 'package:vnu_core/modules/course_points/views/vcore_course_points_view.dart';
import 'package:vnu_core/modules/exam_schedule/views/vcore_exam_schedule_view.dart';
import 'package:vnu_core/modules/hdsd/views/vcore_hdsd_view.dart';
import 'package:vnu_core/modules/inmapz/vcore_immap_view.dart';
import 'package:vnu_core/modules/motel/vcore_motel_webview.dart';
import 'package:vnu_core/modules/one_door/views/vcore_one_door_view.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_view.dart';
import 'package:vnu_core/modules/question/views/vcore_question_view.dart';
import 'package:vnu_core/modules/sync/views/vcore_sync_view.dart';
import 'package:vnu_core/modules/time_schedule/views/vcore_time_schedule_view.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_noi_tru/vnu_noi_tru.dart';

const _kCacheKeyListDichVu = 'listDichVu.json';

/// Sidebar item cho navigation
class SidebarNavItem {
  final IconData icon;
  final String label;
  final int tabIndex;

  const SidebarNavItem({
    required this.icon,
    required this.label,
    required this.tabIndex,
  });
}

/// Sidebar widget hiển thị dịch vụ + navigation
/// Thiết kế theo kiểu slide menu giống ảnh tham khảo
class VcoreSidebarWidget extends StatefulWidget {
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onClose;

  const VcoreSidebarWidget({
    super.key,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.onClose,
  });

  @override
  State<VcoreSidebarWidget> createState() => _VcoreSidebarWidgetState();
}

class _VcoreSidebarWidgetState extends State<VcoreSidebarWidget> {
  bool _isLoading = true;
  List<BoxServiceModel> _services = [];

  static const _navItems = <SidebarNavItem>[
    SidebarNavItem(icon: Icons.home_rounded, label: 'Trang chủ', tabIndex: 0),
    SidebarNavItem(
      icon: Icons.campaign_rounded,
      label: 'Tin hệ thống',
      tabIndex: 1,
    ),
    SidebarNavItem(icon: Icons.article_rounded, label: 'Tin tức', tabIndex: 2),
    SidebarNavItem(
      icon: Icons.notifications_rounded,
      label: 'Thông báo',
      tabIndex: 3,
    ),
    SidebarNavItem(icon: Icons.person_rounded, label: 'Cá nhân', tabIndex: 4),
  ];

  @override
  void initState() {
    super.initState();
    _loadCacheService();
    Future.delayed(Duration.zero, () => _loadService());
  }

  void _sortServices(List<BoxServiceModel> services) {
    List<String> priority = ["XemThoiKhoaBieu", "DiemMonHoc", "TheSinhVien"];
    services.sort((a, b) {
      int aIndex = priority.indexOf(a.loaiBoxDichVuEnum ?? '');
      int bIndex = priority.indexOf(b.loaiBoxDichVuEnum ?? '');
      if (aIndex == -1 && bIndex == -1) return 0;
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });
  }

  void _loadCacheService() {
    VnuCacheFileManager().getCacheFile(_kCacheKeyListDichVu).then((data) {
      try {
        var dataString = data ?? '';
        if (dataString.isEmpty) return;
        var dataJson = jsonDecode(dataString) as List;
        List<BoxServiceModel> listObj = [];
        for (var element in dataJson) {
          try {
            BoxServiceModel? model;
            if (element is Map<String, dynamic>) {
              model = BoxServiceModel.fromJson(element);
            } else if (element is Map<dynamic, dynamic>) {
              model = BoxServiceModel.fromJson(element.toStringDynamic());
            }
            if (model != null) {
              if (model.loaiBoxDichVuEnum?.mapTypeBoxService() !=
                  HomeService.XemLichThi) {
                listObj.add(model);
              }
            }
          } catch (e) {
            logError(e.toString());
          }
        }
        _sortServices(listObj);
        if (_services.isEmpty && mounted) {
          setState(() {
            _services = listObj;
            _isLoading = false;
          });
        }
      } catch (e) {
        logError(e.toString());
      }
    });
  }

  Future<void> _loadService() async {
    try {
      var response = await ApiRepository().getBoxServices();
      response = response
          .where(
            (element) =>
                element.loaiBoxDichVuEnum?.mapTypeBoxService() !=
                HomeService.XemLichThi,
          )
          .toList();
      _sortServices(response);
      if (mounted) {
        setState(() {
          _services = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      logError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      color: AppColors.sidebarBg,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            _buildHeader(topPadding),

            // ── Divider ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                color: AppColors.sidebarTextDim.withOpacity(0.25),
                height: 1,
              ),
            ),

            // ── Scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Dịch vụ ──
                    _buildSectionTitle('Dịch vụ'),
                    spaceHeight(4),
                    _buildServicesList(),
                    spaceHeight(16),

                    // ── Divider ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(
                        color: AppColors.sidebarTextDim.withOpacity(0.25),
                        height: 1,
                      ),
                    ),
                    spaceHeight(16),

                    // ── Navigation ──
                    _buildSectionTitle('Điều hướng'),
                    spaceHeight(4),
                    _buildNavList(),
                  ],
                ),
              ),
            ),

            // ── Footer / Logout ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                color: AppColors.sidebarTextDim.withOpacity(0.25),
                height: 1,
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double topPadding) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.sidebarAccent, width: 2),
              color: AppColors.sidebarCardBg,
            ),
            child: ClipOval(
              child: Obx(() {
                final guid =
                    Globals().currentUserModel.value?.guidFileAnhDaiDien
                        ?.toString() ??
                    '';
                if (guid.isNotEmpty) {
                  return CachedNetworkImage(
                    imageUrl: '${ServicesUrl().baseUrlFileDownload}$guid',
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.person,
                      color: AppColors.sidebarAccent,
                      size: 28,
                    ),
                  );
                }
                return const Icon(
                  Icons.person,
                  color: AppColors.sidebarAccent,
                  size: 28,
                );
              }),
            ),
          ),
          spaceWidth(12),
          // Name
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Globals().thongTinSinhVienModel.value?.hoVaTen ?? 'OneVNU',
                    style: TextStyles.bold.copyWith(
                      fontSize: AppFontSizes.mediumLarge,
                      color: AppColors.sidebarText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  spaceHeight(2),
                  Text(
                    Globals().thongTinSinhVienModel.value?.maSinhVien ?? '',
                    style: TextStyles.regular.copyWith(
                      fontSize: AppFontSizes.small,
                      color: AppColors.sidebarTextDim,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Close button
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.sidebarTextDim,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyles.bold.copyWith(
          fontSize: AppFontSizes.font11,
          color: AppColors.sidebarAccent,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    if (_isLoading && _services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.sidebarAccent,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final serviceModel = _services[index];
        final service = serviceModel.loaiBoxDichVuEnum?.mapTypeBoxService();
        return _buildServiceTile(serviceModel, service);
      },
    );
  }

  Widget _buildServiceTile(BoxServiceModel serviceModel, HomeService? service) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onClose();
          Future.delayed(const Duration(milliseconds: 250), () {
            _handleNaviService(service);
          });
        },
        splashColor: AppColors.sidebarAccent.withOpacity(0.15),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.sidebarCardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: serviceModel.icon?.isNotEmpty == true
                        ? CachedNetworkImage(
                            imageUrl: serviceModel.icon!,
                            color: AppColors.sidebarAccent,
                            errorWidget: (_, __, ___) => svgAsset(
                              'assets/images/${service?.icon}',
                              color: AppColors.sidebarAccent,
                            ),
                          )
                        : svgAsset(
                            'assets/images/${service?.icon}',
                            color: AppColors.sidebarAccent,
                          ),
                  ),
                ),
              ),
              spaceWidth(14),
              // Title
              Expanded(
                child: Text(
                  service?.title ?? serviceModel.tenBoxDichVu ?? '',
                  style: TextStyles.regular.copyWith(
                    fontSize: AppFontSizes.medium,
                    color: AppColors.sidebarText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.sidebarTextDim,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _navItems.length,
      itemBuilder: (context, index) {
        final item = _navItems[index];
        final isActive = item.tabIndex == widget.selectedTabIndex;
        return _buildNavTile(item, isActive);
      },
    );
  }

  Widget _buildNavTile(SidebarNavItem item, bool isActive) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onTabSelected(item.tabIndex);
          widget.onClose();
        },
        splashColor: AppColors.sidebarAccent.withOpacity(0.15),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: isActive
              ? BoxDecoration(
                  color: AppColors.sidebarAccent.withOpacity(0.12),
                  border: Border(
                    left: BorderSide(color: AppColors.sidebarAccent, width: 3),
                  ),
                )
              : null,
          child: Row(
            children: [
              Icon(
                item.icon,
                color: isActive
                    ? AppColors.sidebarAccent
                    : AppColors.sidebarTextDim,
                size: 22,
              ),
              spaceWidth(14),
              Text(
                item.label,
                style: TextStyles.regular.copyWith(
                  fontSize: AppFontSizes.medium,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? AppColors.sidebarAccent
                      : AppColors.sidebarText,
                ),
              ),
              if (item.tabIndex == 3) ...[
                const Spacer(),
                // Badge cho thông báo
                StreamBuilder<int>(
                  stream: Globals().unreadCountStream.stream,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    if (count <= 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${count > 99 ? '99+' : count}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.extraSmall,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.sidebarTextDim,
            size: 16,
          ),
          spaceWidth(8),
          Text(
            'OneVNU',
            style: TextStyles.regular.copyWith(
              fontSize: AppFontSizes.small,
              color: AppColors.sidebarTextDim,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNaviService(HomeService? service) {
    switch (service) {
      case HomeService.BanDoSo:
        Get.to(() => const VcoreImmapView());
        break;
      case HomeService.CamNang:
        Get.to(() => const VcoreCamNangView());
        break;
      case HomeService.DangKyNoiTru:
        Get.to(() => const DRMyRegistrationScreen());
        break;
      case HomeService.DiemMonHoc:
        Get.to(() => const VcoreCoursePointsView());
        break;
      case HomeService.HuongDanSuDung:
        Get.to(() => const VcoreHdsdView());
        break;
      case HomeService.MucHoiDap:
        Get.to(() => const VcoreQuestionView());
        break;
      case HomeService.ThuTucMotCua:
        Get.to(() => const VcoreOneDoorView());
        break;
      case HomeService.TimPhongTro:
        openMotelWebView();
        break;
      case HomeService.XemLichThi:
        Get.to(() => const VcoreExamScheduleView());
        break;
      case HomeService.XemThoiKhoaBieu:
        Get.to(() => const VcoreExamScheduleView());
        break;
      case HomeService.PhanAnhHienTruong:
        Get.to(() => const VcorePahtView());
        break;
      case HomeService.DongBo:
        Get.to(() => const VcoreSyncView());
        break;
      default:
        break;
    }
  }
}
