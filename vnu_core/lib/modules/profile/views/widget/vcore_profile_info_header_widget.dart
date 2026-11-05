import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';

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
          const Icon(Icons.description_outlined, size: 22, color: Color(0xFF466FFF)),
          spaceWidth(18),
          Expanded(
            child: Text(
              title,
              style: TextStyles.semiBold.copyWith(color: Colors.black),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF64748B)),
          spaceWidth(12)
        ],
      ),
    );
  }
}
