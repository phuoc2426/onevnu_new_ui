import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/models/phong_tro_model.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/photo_gallery_view.dart';

class VcoreMotelDetailView extends StatefulWidget {
  final PhongTroModel phongTroModel;
  const VcoreMotelDetailView({super.key, required this.phongTroModel});

  @override
  State<VcoreMotelDetailView> createState() => _VcoreMotelDetailViewState();
}

class _VcoreMotelDetailViewState extends State<VcoreMotelDetailView> {
  List<String> photos = [
    // 'https://s-housing.vn/wp-content/uploads/2022/09/thiet-ke-phong-tro-dep-24.jpg',
    // 'https://s-housing.vn/wp-content/uploads/2022/09/thiet-ke-phong-tro-dep-7.jpg',
    // 'https://s-housing.vn/wp-content/uploads/2022/09/thiet-ke-phong-tro-dep-25.jpg',
    // 'https://s-housing.vn/wp-content/uploads/2022/09/thiet-ke-phong-tro-dep-6.jpg',
    // 'https://s-housing.vn/wp-content/uploads/2022/09/thiet-ke-phong-tro-dep-33.jpg',
    // 'https://s-housing.vn/wp-content/uploads/2022/09/thiet-ke-phong-tro-dep-17.jpg'
  ];

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    photos = (widget.phongTroModel.guidFileAnhNhaTros ?? []).map((e) {
      return "${ServicesUrl().baseUrlFileDownload}$e";
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NaviWidget(
        titleStr: 'Thông tin nhà trọ',
      ),
      backgroundColor: AppColor.bgColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Slider
                  Stack(
                    alignment: AlignmentDirectional.bottomCenter,
                    children: [
                      photos.isNotEmpty
                          ? CarouselSlider(
                              options: CarouselOptions(
                                // height: 400,
                                aspectRatio: 16 / 9,
                                viewportFraction: 1.0,
                                initialPage: 0,
                                enableInfiniteScroll: false,
                                reverse: false,
                                autoPlay: true,
                                // autoPlayInterval: Duration(seconds: 3),
                                // autoPlayAnimationDuration: Duration(milliseconds: 800),
                                // autoPlayCurve: Curves.fastOutSlowIn,
                                // enlargeCenterPage: true,
                                // enlargeFactor: 0.3,
                                onPageChanged: (index, reason) {
                                  setState(() {
                                    currentIndex = index;
                                  });
                                },
                                scrollDirection: Axis.horizontal,
                              ),
                              items: photos.map((e) {
                                return GestureDetector(
                                    onTap: () {
                                      Get.to(
                                          () => PhotoGalleryView(
                                                photos: photos,
                                                startPage: photos.indexOf(e),
                                              ),
                                          fullscreenDialog: true);
                                    },
                                    child: CachedNetworkImage(
                                      imageUrl: e,
                                      cacheKey: e,
                                      httpHeaders: Globals().headerToken(),
                                      progressIndicatorBuilder:
                                          (context, url, progress) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    ));
                              }).toList(),
                            )
                          : Image.asset(
                              'assets/images/img_no_image.png',
                              package: kPackageName,
                            ),

                      //
                      photos.isNotEmpty
                          ? Container(
                              decoration: BoxDecoration(
                                  color: Color(0xff637392).withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8)),
                              width: 66,
                              height: 32,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Center(
                                child: Text(
                                  '${currentIndex + 1}/${photos.length}',
                                  style: TextStyles.semiBold.copyWith(
                                      fontSize: 15, color: Colors.white),
                                ),
                              ),
                            )
                          : spaceHeight(0)
                    ],
                  ),

                  // info
                  Container(
                    color: Colors.white,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chủ trọ: ${widget.phongTroModel.tenChuTro}',
                          style: TextStyles.bold.copyWith(
                              fontSize: 15, color: const Color(0xff118A40)),
                        ),
                        spaceHeight(10),
                        textBlock('Giá phòng:',
                            '${widget.phongTroModel.giaThueFromString()} - ${widget.phongTroModel.giaThueToString()}'),
                        spaceHeight(10),
                        textBlock('Diện tích:',
                            '${widget.phongTroModel.dienTichFrom ?? ''} - ${widget.phongTroModel.dienTichTo ?? ''} m2'),
                        spaceHeight(10),
                        Row(
                          children: [
                            Expanded(
                              child: textBlock('Số phòng:',
                                  '${widget.phongTroModel.soLuongPhong}'),
                            ),
                            Expanded(
                              child: textBlock('Ngày đăng:',
                                  widget.phongTroModel.ngayDangString()),
                            ),
                          ],
                        ),
                        spaceHeight(10),
                        textBlock(
                            'Địa chỉ:', widget.phongTroModel.diaChi ?? ''),
                      ],
                    ),
                  ),
                  spaceHeight(10),

                  // Desciption
                  Container(
                    color: Colors.white,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mô tả chi tiết',
                          style: TextStyles.bold.copyWith(
                              fontSize: 15, color: const Color(0xff181E39)),
                        ),
                        spaceHeight(12),
                        Visibility(
                          visible:
                              (widget.phongTroModel.thietBiTrongPhong ?? '')
                                  .isNotEmpty,
                          child: Text(
                            widget.phongTroModel.thietBiTrongPhong ?? '',
                            style: TextStyles.regular,
                          ),
                        ),
                        Visibility(
                          visible:
                              (widget.phongTroModel.thietBiTrongPhong ?? '')
                                  .isNotEmpty,
                          child: const Divider(
                            color: Color(0xffE0E0E0),
                          ),
                        ),
                        Text(
                          widget.phongTroModel.moTaChiTiet ?? '',
                          style: TextStyles.regular,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fix call button
          InkWell(
            onTap: () {
              launchUrlString(
                  "tel://${widget.phongTroModel.soDienThoai ?? ''}");
            },
            child: Container(
              color: const Color(0xff007F3E),
              child: SafeArea(
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      svgAsset('assets/images/ic_motel_call.svg'),
                      spaceWidth(20),
                      Text(
                        'Gọi: ',
                        style: TextStyles.bold
                            .copyWith(color: Colors.white, fontSize: 15),
                      ),
                      Text(
                        widget.phongTroModel.soDienThoai ?? '',
                        style: TextStyles.regular
                            .copyWith(color: Colors.white, fontSize: 15),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget textBlock(String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.regular.copyWith(color: const Color(0xff637392)),
        ),
        spaceWidth(5),
        Expanded(
          child: Text(
            content,
            style: TextStyles.regular,
          ),
        )
      ],
    );
  }
}
