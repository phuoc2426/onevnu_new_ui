import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/diem_hoc_phan_model.dart';
import 'package:vnu_core/models/diem_thi_hoc_ky_model.dart';
import 'package:vnu_core/repository/app_repository.dart';

class VcoreCoursePointsDetailWidget extends StatefulWidget {
  final String kieuTruong;
  final DiemThiHocKyModel diemThiHocKyModel;
  const VcoreCoursePointsDetailWidget(
      {super.key, required this.kieuTruong, required this.diemThiHocKyModel});

  @override
  State<VcoreCoursePointsDetailWidget> createState() =>
      _VcoreCoursePointsDetailWidgetState();
}

class _VcoreCoursePointsDetailWidgetState
    extends State<VcoreCoursePointsDetailWidget> {
  var isLoadingDiemHocPhan = true;
  List<DiemHocPhanModel> listDiemMonHoc = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  _getDiemHocPhanHocKy(BuildContext context) async {
    isLoadingDiemHocPhan = true;
    try {
      var response = await ApiRepository().getDiemHocPhanHocKy(
          widget.diemThiHocKyModel.idHocKy ?? '',
          widget.kieuTruong,
          widget.diemThiHocKyModel.idHocPhan ?? '');

      isLoadingDiemHocPhan = false;
      setState(() {
        listDiemMonHoc = response;
      });
    } catch (e) {
      setState(() {
        isLoadingDiemHocPhan = false;
      });
      snackBarError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (listDiemMonHoc.isEmpty) {
      _getDiemHocPhanHocKy(context);
    }
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(26),
      // constraints: BoxConstraints(maxHeight: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Thông tin điểm môn học',
            style: TextStyles.semiBold
                .copyWith(fontSize: AppFontSizes.extraLarge, color: AppColors.darkBlueAccent),
          ),
          spaceHeight(30),
          Text(
            widget.diemThiHocKyModel.tenHocPhan ?? '',
            style:
                TextStyles.semiBold.copyWith(fontSize: AppFontSizes.extraLarge, color: Colors.black),
          ),
          spaceHeight(30),

          totalPoint(),
          spaceHeight(10),

          Expanded(
            child: ListView.separated(
              // shrinkWrap: true,
              // physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (ctx, index) {
                return itemPoint(listDiemMonHoc[index]);
              },
              separatorBuilder: (_, __) => spaceHeight(10),
              itemCount: listDiemMonHoc.length,
            ),
          ),

          spaceHeight(60),
          // Close button
          OutlinedButton(
            onPressed: () {
              Get.back();
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(width: 1.0, color: AppColors.darkBlueAccent),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                'Đóng',
                style: TextStyles.semiBold
                    .copyWith(fontSize: AppFontSizes.large, color: AppColors.darkBlueAccent),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget totalPoint() {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.lightGreyBg,
          borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.symmetric(horizontal: 26, vertical: 10),
      width: double.infinity,
      child: Row(
        children: [
          Text(
            'Tổng điểm:',
            style:
                TextStyles.regular.copyWith(fontSize: AppFontSizes.extraLarge, color: Colors.black),
          ),
          const Spacer(),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                //color: const Color(0xff00803D),
                border: Border.all(color: AppColors.gradeVeryStrong),
                borderRadius: BorderRadius.circular(21)),
            child: Center(
              child: Text(widget.diemThiHocKyModel.diemHe10 ?? '',
                  style: TextStyles.regular
                      .copyWith(fontSize: AppFontSizes.mediumLarge, color: Colors.orange)),
            ),
          )
        ],
      ),
    );
  }

  Widget itemPoint(DiemHocPhanModel diemHocPhan) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.lightGreyBg,
          borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
      width: double.infinity,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                diemHocPhan.loaiDiemHocPhan ?? '',
                style: TextStyles.semiBold
                    .copyWith(fontSize: AppFontSizes.mediumLarge, color: Colors.black),
              ),
            ],
          ),
          //
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              children: [
                Expanded(
                    flex: 4,
                    child:
                        itemTotalPoint('Trọng số:', diemHocPhan.trongSo ?? '')),
                //Expanded(flex: 3, child: itemTotalPoint('Lần thi:', '1')),
                Expanded(
                    flex: 3,
                    child: itemTotalPoint('Điểm:', diemHocPhan.diemHe10 ?? '')),
              ],
            ),
          ),
          //
          // Row(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     Text(
          //       'Ghi chú:',
          //       style: TextStyles.regular
          //           .copyWith(fontSize: AppFontSizes.mediumLarge, color: const Color(0xff637392)),
          //     ),
          //     spaceWidth(20),
          //     const Expanded(
          //         child: Text(
          //             'Nội dung ghi chú Ghi chúGhi chúGhi chúGhi chúGhi chúGhi chúGhi chúGhi chúGhi chúGhi chúGhi chúGhi chú'))
          //   ],
          // )
        ],
      ),
    );
  }

  Widget itemTotalPoint(String title, String content) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyles.regular
              .copyWith(fontSize: AppFontSizes.mediumLarge, color: AppColors.slateText),
        ),
        spaceWidth(2),
        Text(
          content,
          style: TextStyles.regular
              .copyWith(color: AppColors.darkBlueAccent, fontSize: AppFontSizes.large),
        ),
      ],
    );
  }
}
