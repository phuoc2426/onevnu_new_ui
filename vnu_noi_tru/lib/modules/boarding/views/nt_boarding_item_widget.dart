import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';

class NtBoardingItemWidget extends StatefulWidget {
  const NtBoardingItemWidget({super.key});

  @override
  State<NtBoardingItemWidget> createState() => _NtBoardingItemWidgetState();
}

class _NtBoardingItemWidgetState extends State<NtBoardingItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đăng ký nội trú đợt II',
            style:
                TextStyles.semiBold.copyWith(fontSize: 15, color: Colors.black),
          ),
          spaceHeight(10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Ngày gửi:',
                      style: TextStyles.regular.copyWith(
                          fontSize: 13, color: const Color(0xff637392)),
                    ),
                    Text(
                      '15/01/2024  18:00',
                      style: TextStyles.regular.copyWith(fontSize: 13),
                    )
                  ],
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  'Đang xét duyệt',
                  style: TextStyles.semiBold
                      .copyWith(fontSize: 13, color: Color(0xffFB8500)),
                ),
              ),
            ],
          ),
          spaceHeight(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lý do từ chối:',
                style: TextStyles.regular
                    .copyWith(fontSize: 13, color: const Color(0xff637392)),
              ),
              Expanded(
                child: Text(
                  'Phòng ký túc đang sửa chữa',
                  style: TextStyles.regular.copyWith(fontSize: 13),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
