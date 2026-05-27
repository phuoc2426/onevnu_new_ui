import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/models/model.dart';

class VcoreSystemNewsItemWidget extends StatefulWidget {
  final TinHeThongModel tinTucModel;
  const VcoreSystemNewsItemWidget({super.key, required this.tinTucModel});

  @override
  State<VcoreSystemNewsItemWidget> createState() =>
      _VcoreSystemNewsItemWidgetState();
}

class _VcoreSystemNewsItemWidgetState extends State<VcoreSystemNewsItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, top: 8, right: 20, bottom: 15),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              //
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //
                    Text(
                      widget.tinTucModel.tieuDe ?? '',
                      style: TextStyles.regular,
                    ),
                    spaceHeight(8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.tinTucModel.nguonTin ?? '',
                            style: TextStyles.regular.copyWith(
                                fontSize: 13, color: const Color(0xff003392)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // nếu dài quá sẽ thành ...
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateTimeUtils.stringFromDateTime(
                              widget.tinTucModel.thoiGian,
                              DateTimeConst.DATE_FORMAT),
                          style: TextStyles.regular.copyWith(
                              fontSize: 13, color: const Color(0xff8E8E8E)),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
