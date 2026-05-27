import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/widgets/buttons_widget.dart';

class VcoreMapFilterWidget extends StatefulWidget {
  final List<KhuVucBanDoModel> listKhuVuc;
  final KhuVucBanDoModel? currentKhuVuc;
  final Function(KhuVucBanDoModel? khuVuc) onChangeKhuVuc;
  const VcoreMapFilterWidget(
      {super.key,
      required this.listKhuVuc,
      this.currentKhuVuc,
      required this.onChangeKhuVuc});

  @override
  State<VcoreMapFilterWidget> createState() => _VcoreMapFilterWidgetState();
}

class _VcoreMapFilterWidgetState extends State<VcoreMapFilterWidget> {
  KhuVucBanDoModel? khuVucHienTai;
  KhuVucBanDoModel? khuVucMacDinh;

  @override
  void initState() {
    super.initState();

    khuVucHienTai = widget.currentKhuVuc;

    //Load khu vuc mac dinh
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 500),
      // height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              'Lọc theo khu vực',
              style: TextStyles.bold
                  .copyWith(color: const Color(0xff003392), fontSize: 15),
            ),
          ),
          spaceHeight(20),
          // Input content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Tìm kiếm theo khu vực khác
                  Text(
                    'Tìm kiếm theo khu vực khác',
                    style: TextStyles.semiBold
                        .copyWith(color: const Color(0xff181E39), fontSize: 15),
                  ),
                  spaceHeight(20),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemBuilder: (cxt, index) {
                      var khuVuc = widget.listKhuVuc[index];
                      var isSelected = khuVucHienTai?.guid == khuVuc.guid;
                      return InkWell(
                        onTap: () {
                          if (isSelected) {
                            setState(() {
                              khuVucHienTai = null;
                            });
                            return;
                          }
                          setState(() {
                            khuVucHienTai = khuVuc;
                          });
                        },
                        child:
                            itemKhuVuc(khuVuc.tenKhuVucBanDo ?? '', isSelected),
                      );
                    },
                    separatorBuilder: (_, __) => spaceHeight(6),
                    itemCount: widget.listKhuVuc.length,
                  ),
                  spaceHeight(10),
                  /*
                          const Divider(),
                          spaceHeight(20),

                          //Thay đổi khu vực hiển thị mặc định
                   
                          Text(
                            'Thay đổi khu vực hiển thị mặc định',
                            style: TextStyles.semiBold.copyWith(
                                color: const Color(0xff181E39), fontSize: 15),
                          ),
                          spaceHeight(20),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemBuilder: (cxt, index) {
                              var khuVuc = widget.listKhuVuc[index];
                              var isSelected =
                                  khuVucMacDinh?.guid == khuVuc.guid;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    khuVucMacDinh = khuVuc;
                                  });
                                },
                                child: itemKhuVuc(
                                    khuVuc.tenKhuVucBanDo ?? '', isSelected),
                              );
                            },
                            separatorBuilder: (_, __) => spaceHeight(6),
                            itemCount: widget.listKhuVuc.length,
                          ),
                          */
                ],
              ),
            ),
          ),
          // Action
          Row(
            children: [
              Expanded(
                child: WhiteButton(
                  width: double.infinity,
                  title: 'Đóng',
                  action: () {
                    Get.back();
                  },
                ),
              ),
              spaceWidth(22),
              Expanded(
                child: BlueButton(
                  width: double.infinity,
                  title: 'Áp dụng',
                  action: () {
                    Get.back(closeOverlays: true);

                    widget.onChangeKhuVuc(khuVucHienTai);
                  },
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget itemKhuVuc(String ten, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: isSelected ? const Color(0xffF3FAF9) : Colors.transparent,
      child: Row(
        children: [
          Text(
            ten,
            style: TextStyles.regular,
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(
              Icons.check,
              size: 20,
              color: Color(0xff2F9E44),
            ),
          ],
        ],
      ),
    );
  }
}
