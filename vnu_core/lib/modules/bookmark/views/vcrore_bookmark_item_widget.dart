import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/lien_ket_danh_dau_model.dart';
import 'package:vnu_core/modules/browser/views/vcore_browser_view.dart';

import '../../../common/app_text_styles.dart';

class VcoreBookmarkItemWidget extends StatefulWidget {
  final LienKetDanhDauModel lienKetDanhDauModel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isShowMore;

  const VcoreBookmarkItemWidget(
      {super.key,
      required this.lienKetDanhDauModel,
      required this.onEdit,
      required this.onDelete,
      this.isShowMore = true});

  @override
  State<VcoreBookmarkItemWidget> createState() =>
      _VcoreBookmarkItemWidgetState();
}

class _VcoreBookmarkItemWidgetState extends State<VcoreBookmarkItemWidget> {
  @override
  Widget build(BuildContext context) {
    var url = widget.lienKetDanhDauModel.lienKet ?? '';
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      url = uri.host;
    }

    return GestureDetector(
      onTap: () {
        Get.to(() => VcoreBrowserView(
            title: widget.lienKetDanhDauModel.tenLienKet ?? '',
            url: widget.lienKetDanhDauModel.lienKet ?? ''));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container(
            //   height: 32,
            //   width: 32,
            //   clipBehavior: Clip.hardEdge,
            //   decoration:
            //       BoxDecoration(borderRadius: BorderRadius.circular(16)),
            //   child: CachedNetworkImage(
            //     imageUrl:
            //         'https://www.vnu.edu.vn/upload/RIHT-HINHANH-TTSK/image/VNU%20WUR-QS%202023.jpg',
            //     fit: BoxFit.fill,
            //   ),
            // ),
            const SizedBox(
              height: 32,
              width: 32,
              child: Center(
                child: Icon(
                  Icons.bookmarks,
                  color: const Color(0xff003392),
                ),
              ),
            ),
            spaceWidth(8),
            //
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lienKetDanhDauModel.tenLienKet ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.regular.copyWith(fontSize: AppFontSizes.medium),
                  ),
                  Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.regular
                        .copyWith(fontSize: AppFontSizes.medium, color: const Color(0xff003392)),
                  )
                ],
              ),
            ),
            widget.isShowMore
                ? PopupMenuButton(
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          value: 'edit',
                          child: Center(
                            child: Text(
                              'Sửa',
                              style: TextStyles.regular
                                  .copyWith(color: Colors.black),
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Center(
                            child: Text(
                              'Xoá',
                              style: TextStyles.regular
                                  .copyWith(color: Colors.black),
                            ),
                          ),
                        )
                      ];
                    },
                    onSelected: (String value) {
                      print('You Click on po up menu item');
                      if (value == 'delete') {
                        widget.onDelete();
                      }
                      if (value == 'edit') {
                        widget.onEdit();
                      }
                    },
                    color: Colors.white,
                    child: Container(
                        margin: EdgeInsets.only(top: 8),
                        width: 30,
                        height: 44,
                        child: svgAsset('assets/images/ic_bookmark_more.svg',
                            fit: BoxFit.none)),
                  )
                : spaceHeight(0),

            // //More
            // GestureDetector(
            //   behavior: HitTestBehavior.opaque,
            //   onTap: () {
            //     print('tap...');
            //   },
            //   child: Container(
            //       margin: EdgeInsets.only(top: 8),
            //       width: 30,
            //       height: 44,
            //       child: svgAsset('assets/images/ic_bookmark_more.svg',
            //           fit: BoxFit.none)),
            // )
          ],
        ),
      ),
    );
  }
}
