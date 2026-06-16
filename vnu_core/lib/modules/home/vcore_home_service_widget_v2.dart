import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/extensions/map_ext.dart';
import 'package:vnu_core/models/box_service_model.dart';
import 'package:vnu_core/modules/course_points/views/vcore_course_points_view.dart';
import 'package:vnu_core/modules/inmapz/vcore_immap_view.dart';
import 'package:vnu_core/modules/motel/vcore_motel_webview.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_view.dart';
import 'package:vnu_core/modules/student_card/views/vcore_student_card_view.dart';
import 'package:vnu_core/modules/sync/views/vcore_sync_view.dart';
import 'package:vnu_core/modules/time_schedule/views/vcore_time_schedule_view.dart';
import 'package:vnu_core/repository/app_repository.dart';

import '../../constants/enum.dart';
import '../cam_nang/views/vcore_cam_nang_view.dart';
import '../exam_schedule/views/vcore_exam_schedule_view.dart';
import '../hdsd/views/vcore_hdsd_view.dart';
import '../one_door/views/vcore_one_door_view.dart';
import '../question/views/vcore_question_view.dart';
import 'package:vnu_noi_tru/vnu_noi_tru.dart';

const kCacheKeyListDichVu = 'listDichVu.json';

/// Widget dịch vụ V2 với khả năng expand/collapse
/// - Mặc định hiển thị 1 hàng horizontal scroll
/// - Khi nhấn nút More sẽ expand thành 3 hàng grid
class VcoreHomeServiceWidgetV2 extends StatefulHookWidget {
  const VcoreHomeServiceWidgetV2({super.key});

  @override
  State<VcoreHomeServiceWidgetV2> createState() =>
      _VcoreHomeServiceWidgetV2State();
}

class _VcoreHomeServiceWidgetV2State extends State<VcoreHomeServiceWidgetV2>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  bool _isExpanded = false;
  bool _isLoading = true;
  List<BoxServiceModel> _services = [];
  double _marginLeft = 0.0;

  // Số item hiển thị trên 1 hàng khi collapsed
  static const int _itemsPerRow = 4;
  // Số hàng khi expanded
  static const int _expandedRows = 3;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _loadCacheService();
    Future.delayed(Duration.zero, () => _loadService());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
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
    VnuCacheFileManager().getCacheFile(kCacheKeyListDichVu).then((data) {
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

      if (response.isNotEmpty) {
        try {
          var data = response.map((e) => e.toJson()).toList();
          VnuCacheFileManager().saveCacheFile(
            kCacheKeyListDichVu,
            jsonEncode(data),
          );
        } catch (e) {
          logError(e.toString());
        }
      } else {
        VnuCacheFileManager().deleteCacheFile(kCacheKeyListDichVu);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      logError(e.toString());
    }
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: _buildCollapsedView(),
          secondChild: _buildExpandedView(),
        ),
      ],
    );
  }

  /// View thu gọn - 1 hàng horizontal scroll
  Widget _buildCollapsedView() {
    if (_isLoading && _services.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 90,
          child: NotificationListener<ScrollUpdateNotification>(
            child: Row(
              children: [
                // Services list
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: _services.length,
                    separatorBuilder: (_, __) => spaceWidth(8),
                    itemBuilder: (context, index) {
                      final serviceModel = _services[index];
                      final service = serviceModel.loaiBoxDichVuEnum
                          ?.mapTypeBoxService();
                      return _buildServiceItem(serviceModel, service);
                    },
                  ),
                ),
                // More button
                _buildMoreButton(),
              ],
            ),
            onNotification: (notification) {
              if (_scrollController.position.maxScrollExtent > 0) {
                double newMargin =
                    (notification.metrics.pixels /
                        _scrollController.position.maxScrollExtent) *
                    (2.0 / 3.0) *
                    30.0;
                newMargin = max(0, newMargin);
                newMargin = min(newMargin, 20);
                setState(() {
                  _marginLeft = newMargin;
                });
              }
              return true;
            },
          ),
        ),
        // Scroll indicator
        _buildScrollIndicator(),
      ],
    );
  }

  /// View mở rộng - Grid 3 hàng
  Widget _buildExpandedView() {
    if (_isLoading && _services.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Tính số cột dựa trên screen width
    final screenWidth = MediaQuery.of(context).size.width - 32; // padding
    final itemWidth = (screenWidth - 24) / 4; // 4 items per row, 3 gaps

    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemCount: min(_services.length, _itemsPerRow * _expandedRows),
            itemBuilder: (context, index) {
              // Nút thu gọn ở vị trí cuối
              if (index ==
                  min(_services.length, _itemsPerRow * _expandedRows) - 1) {
                return _buildCollapseButton();
              }

              final serviceModel = _services[index];
              final service = serviceModel.loaiBoxDichVuEnum
                  ?.mapTypeBoxService();
              return _buildServiceItem(serviceModel, service);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(BoxServiceModel serviceModel, HomeService? service) {
    return InkWell(
      onTap: () => _handleNaviService(service),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: serviceModel.icon?.isNotEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: serviceModel.icon!,
                          errorWidget: (_, __, ___) =>
                              svgAsset('assets/images/${service?.icon}'),
                        )
                      : svgAsset('assets/images/${service?.icon}'),
                ),
              ),
            ),
            spaceHeight(6),
            Flexible(
              child: Text(
                service?.title ?? serviceModel.tenBoxDichVu ?? '',
                style: TextStyles.regular.copyWith(
                  fontSize: AppFontSizes.font11,
                  color: const Color(0xff374151),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreButton() {
    return GestureDetector(
      onTap: _toggleExpand,
      child: Container(
        width: 56,
        margin: const EdgeInsets.only(right: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Color(0xff6B7280),
                size: 22,
              ),
            ),
            spaceHeight(6),
            Text(
              'Xem thêm',
              style: TextStyles.regular.copyWith(
                fontSize: AppFontSizes.font11,
                color: const Color(0xff6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return GestureDetector(
      onTap: _toggleExpand,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.keyboard_arrow_up,
              color: Color(0xff6B7280),
              size: 24,
            ),
          ),
          spaceHeight(6),
          Text(
            'Thu gọn',
            style: TextStyles.regular.copyWith(
              fontSize: AppFontSizes.font11,
              color: const Color(0xff637392),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScrollIndicator() {
    return SizedBox(
      width: double.infinity,
      height: 20,
      child: Center(
        child: Stack(
          children: [
            Container(
              height: 5,
              width: 30,
              decoration: BoxDecoration(
                color: const Color(0xffDDE3EE),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Container(
              height: 5,
              width: 10,
              margin: EdgeInsets.only(left: _marginLeft),
              decoration: BoxDecoration(
                color: const Color(0xff003392),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
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
