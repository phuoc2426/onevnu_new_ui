import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';

class VcoreProfileInfoHeaderWidget extends StatelessWidget {
  final String title;
  const VcoreProfileInfoHeaderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43,
      width: double.infinity,
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: const Color(0xffE7E7E7)))),
      child: Row(
        children: [
          svgAsset('assets/images/ic_profile_info_header.svg'),
          spaceWidth(18),
          Expanded(
            child: Text(
              title,
              style: TextStyles.semiBold.copyWith(color: Colors.black),
            ),
          ),
          svgAsset('assets/images/ic_profile_info_next.svg'),
          spaceWidth(12)
        ],
      ),
    );
  }
}
