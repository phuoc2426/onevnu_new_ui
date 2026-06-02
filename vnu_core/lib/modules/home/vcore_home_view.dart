import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/bookmark/views/vcore_bookmark_view.dart';
import 'package:vnu_core/modules/bookmark/views/vcrore_bookmark_item_widget.dart';
import 'package:vnu_core/modules/home/vcore_home_controller.dart';
import 'package:vnu_core/modules/home/vcore_home_news_widget.dart';
import 'package:vnu_core/modules/home/vcore_home_notify_daotao_widget.dart';
import 'package:vnu_core/modules/home/vcore_home_notify_widget.dart';
import 'package:vnu_core/modules/paht/views/vcore_paht_view.dart';
import 'package:vnu_core/modules/profile/views/vcore_profile_avatar_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';

import '../../models/model.dart';
import '../browser/views/vcore_html_view.dart';
import 'vcore_home_service_widget.dart';
import 'vcore_home_source_news_widget.dart';

const kCacheKeyListTinTucBySchool = 'listTinTucBySchool.json';
class VcoreHomeView extends GetView<VcoreHomeController> {
  const VcoreHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: VcoreHomeController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        controller.getLienKetDanhDau();
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
          },
          child: Scaffold(
            backgroundColor: const Color(0xffF6F9FE),
            body: SingleChildScrollView(
              child: Obx(
                    () => Column(
                  children: [
                    Stack(
                      alignment: AlignmentDirectional.bottomCenter,
                      children: [
                        Column(
                          children: [
                            svgAsset('assets/images/bg_home.svg',
                                fit: BoxFit.fitWidth,
                                width: MediaQuery.of(context).size.width),
                            spaceHeight(40),
                          ],
                        ),
                        boxUserProfile(),
                      ],
                    ),

                    spaceHeight(20),

                    //
                    boxServices(),
                    spaceHeight(20),



                    controller.listTinTucBySchool.isNotEmpty&&controller.listTinTuc2.isNotEmpty
                        ? boxNewsBySchool(controller.listTinTucBySchool, controller)
                        : spaceHeight(0),
                    spaceHeight(controller.listTinTucBySchool.isNotEmpty ? 20 : 0),

                    //
                    controller.listTinTuc.isNotEmpty
                        ? boxNews(controller.listTinTuc, controller)
                        : spaceHeight(0),
                    spaceHeight(controller.listTinTuc.isNotEmpty ? 20 : 0),


                    controller.listThongBaoDaoTao.isNotEmpty
                        ? boxNotifyDaoTao(controller)
                        : spaceHeight(0),
                    spaceHeight(
                        controller.listThongBaoDaoTao.isNotEmpty ? 20 : 0),

                    //Notify
                    controller.listTop10ThongBao.isNotEmpty
                        ? boxNotify(controller)
                        : spaceHeight(0),
                    spaceHeight(
                        controller.listTop10ThongBao.isNotEmpty ? 20 : 0),

                    //
                    controller.listLienKetDanhDau.isNotEmpty
                        ? boxBookmark(controller.listLienKetDanhDau)
                        : spaceHeight(0),
                    spaceHeight(
                        controller.listLienKetDanhDau.isNotEmpty ? 20 : 0),

                    //
                    controller.listNguonTin.isNotEmpty
                        ? boxSourceNewsVNU(controller.listNguonTin)
                        : spaceHeight(0),
                    spaceHeight(20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget boxUserProfile() {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Avatar
          const SizedBox(
            width: 56,
            height: 56,
            child: VcoreProfileAvatarWidget(
              url:
              'https://vnu.edu.vn/upload/2014/11/17202/image/Logo-VNU-1995.jpg',
              size: 56,
            ),
          ),
          spaceWidth(8),
          //Name

          Obx(
                () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    Globals().thongTinSinhVienModel.value?.hoVaTen ?? '',
                    style: TextStyles.bold
                        .copyWith(fontSize: AppFontSizes.mediumLarge, color: const Color(0xff181E39))
                ),
                spaceHeight(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "MSV:",
                      style: TextStyles.regular.copyWith(
                          color: const Color(0xff637392), fontSize: AppFontSizes.mediumSmall),
                    ),
                    const SizedBox(width: 2),
                    Text(
                        Globals().thongTinSinhVienModel.value?.maSinhVien ?? '',
                        style: TextStyles.regular.copyWith(
                            color: const Color(0xff2A3556), fontSize: AppFontSizes.mediumSmall)),
                  ],
                ),
                spaceHeight(4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Lớp:",
                        style: TextStyles.regular.copyWith(
                            color: const Color(0xff637392), fontSize: AppFontSizes.mediumSmall)),
                    const SizedBox(width: 2),
                    Text(Globals().lopDaoTaoModel.value?.ten ?? '',
                        style: TextStyles.regular.copyWith(
                            color: const Color(0xff2A3556), fontSize: AppFontSizes.mediumSmall)),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),
          //Truong

          Visibility(
            visible: false, //TODO: - temp hide logo current university
            child: Column(
              children: [
                const Spacer(),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CachedNetworkImage(
                    imageUrl:
                    'https://cdn.haitrieu.com/wp-content/uploads/2021/10/Logo-DH-Cong-Nghe-UET.png',
                    cacheKey:
                    'https://cdn.haitrieu.com/wp-content/uploads/2021/10/Logo-DH-Cong-Nghe-UET.png',
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget boxServices() {
    return Container(
      // height: 250,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          header('Dịch vụ', null),
          spaceHeight(16),
          const VcoreHomeServiceWidget()
        ],
      ),
    );
  }

  Widget boxNewsBySchool(
      List<TopTinTucModel> listTinTucBySchool,
      VcoreHomeController controller) {
    return FutureBuilder<String>(
      future: getGuildFromCache(), // Gọi hàm lấy guild từ cache
      builder: (context, snapshot) {
        String tenDonVi = snapshot.data ?? "Trường của bạn";
        String headerNBS = "Tin tức của $tenDonVi";
        List<TinTucModel> lst2 = controller.listTinTuc2;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              header(
                  headerNBS,
                  null
              ),
              spaceHeight(16),
              VcoreHomeNewsWidget(
                listTinTuc: listTinTucBySchool,
                onViewDetail: (tintuc) {
                  controller.viewDetailTopTinTucModel(tintuc);
                },
                type: 2,
                listTinTuc2: lst2,
              ),
            ],
          ),
        );
      },
    );
  }


// ✅ Hàm lấy guild từ cache
  Future<String> getGuildFromCache() async {
    try {
      String? cachedData = await VnuCacheFileManager().getCacheFile(kCacheKeyListTinTucBySchool);
      if (cachedData != null && cachedData.isNotEmpty) {
        var jsonData = jsonDecode(cachedData);
        return jsonData["guild"] ?? "";
      }
    } catch (e) {
      print("Lỗi khi lấy dữ liệu cache: ${e.toString()}");
    }
    return ""; // Trả về chuỗi rỗng nếu lỗi
  }


  Widget boxNews(
      List<TopTinTucModel> listTinTuc, VcoreHomeController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header('Tin tức của VNU', null),
          spaceHeight(16),
          VcoreHomeNewsWidget(
            listTinTuc: listTinTuc,
            onViewDetail: (tintuc) {
              controller.viewDetailTopTinTucModel(tintuc);
            },
          )
        ],
      ),
    );
  }

  Widget boxNotifyDaoTao(VcoreHomeController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header('Thông báo Đào tạo mới', null),
          spaceHeight(16),
          VcoreHomeNotifyDaoTaoWidget(
            listThongBao: controller.listThongBaoDaoTao,
            onViewDetail: (thongbao) {
              Get.to(
                VcoreHtmlView(
                    title: 'Thông báo Đào tạo', html: thongbao.noiDung ?? ''),
              );
            },
          )
        ],
      ),
    );
  }

  Widget boxNotify(VcoreHomeController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header('Thông báo VNU mới', null),
          spaceHeight(16),
          VcoreHomeNotifyWidget(
            listThongBao: controller.listTop10ThongBao.sublist(0,5),
            onViewDetail: (thongbao) {
              controller.viewDetailTopThongBaoModel(thongbao);
            },
          )
        ],
      ),
    );
  }

  Widget boxBookmark(List<LienKetDanhDauModel> listLienKetDanhDau) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header('Liên kết đánh dấu', () {
            Get.to(() => const VcoreBookmarkView());
          }),
          spaceHeight(16),
          ListView.separated(
              separatorBuilder: (context, index) => spaceHeight(15),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: listLienKetDanhDau.length,
              itemBuilder: (ctx, index) {
                return VcoreBookmarkItemWidget(
                  lienKetDanhDauModel: listLienKetDanhDau[index],
                  onEdit: () {},
                  onDelete: () {},
                  isShowMore: false,
                );
              })
        ],
      ),
    );
  }

  Widget boxSourceNewsVNU(List<NguonTinModel> listNguonTin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header('Nguồn tin VNU', null),
          spaceHeight(16),
          //Grid view item
          VcoreHomeSourceNewsWidget(
            listNguonTin: listNguonTin,
          )
        ],
      ),
    );
  }

  Widget header(String title, VoidCallback? action) {
    return Container(
      width: double.infinity, // Chiếm hết chiều rộng màn hình
      padding: const EdgeInsets.symmetric(vertical: 8), // Thêm padding cho chiều cao
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyles.bold.copyWith(
                fontSize: AppFontSizes.mediumLarge,
                color: const Color(0xff181E39),
              ),
              softWrap: true, // Cho phép xuống dòng
              overflow: TextOverflow.ellipsis, // Dấu ba chấm nếu dài quá
            ),
          ),
          const SizedBox(width: 8), // Khoảng cách giữa Text và Xem thêm
          action != null
              ? GestureDetector(
            onTap: action,
            child: Text(
              'Xem thêm',
              style: TextStyles.regular.copyWith(
                fontSize: AppFontSizes.small,
                color: const Color(0xff466FFF),
              ),
            ),
          )
              : const SizedBox()
        ],
      ),
    );
  }

}
