import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/config.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/constants/enum.dart';
import '../../../common/space_widget.dart';

class VcoreNotifyItemWidgetV3 extends StatelessWidget {
  final ThongBaoModel? thongBaoModel;
  final ThongBaoDaoTaoModel? daoTaoModel;
  final bool isRead;
  final VoidCallback onTap;

  const VcoreNotifyItemWidgetV3({
    super.key,
    this.thongBaoModel,
    this.daoTaoModel,
    required this.isRead,
    required this.onTap,
  });

  String _stripHtml(String? text) {
    if (text == null) return '';
    return text.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  _buildIconSection(),
                  spaceWidth(14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          thongBaoModel != null
                              ? (thongBaoModel!.tieuDe ?? '')
                              : _stripHtml(daoTaoModel!.tieuDe),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.semiBold.copyWith(
                            fontSize: AppFontSizes.font14_5,
                            color: isRead ? const Color(0xff4A5568) : const Color(0xff1A202C),
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                          ),
                        ),
                        spaceHeight(6),
                        // Subtitle / Preview text
                        if (thongBaoModel != null && thongBaoModel!.noiDung?.isNotEmpty == true)
                          Text(
                            thongBaoModel!.noiDung ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyles.regular.copyWith(
                              fontSize: AppFontSizes.font12_5,
                              color: const Color(0xff718096),
                            ),
                          ),
                        spaceHeight(6),
                        // Sender and Date info
                        Row(
                          children: [
                            if (thongBaoModel != null && thongBaoModel!.tenNguoiGui?.isNotEmpty == true)
                              Expanded(
                                child: Text(
                                  thongBaoModel!.tenNguoiGui ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyles.medium.copyWith(
                                    fontSize: AppFontSizes.font11,
                                    color: AppColors.darkBlueAccent,
                                  ),
                                ),
                              )
                            else
                              const Expanded(
                                child: Text(
                                  'Phòng Đào tạo',
                                  style: TextStyle(
                                    fontSize: AppFontSizes.font11,
                                    color: Color(0xffFF9500),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            spaceWidth(8),
                            if (thongBaoModel != null && thongBaoModel!.ngayGui != null)
                              Text(
                                DateTimeUtils.stringFromDateTime(
                                  thongBaoModel!.ngayGui?.toLocal(),
                                  DateTimeConst.U_SECOND_FORMAT,
                                ),
                                style: TextStyles.regular.copyWith(
                                  fontSize: AppFontSizes.font11,
                                  color: const Color(0xffA0AEC0),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  spaceWidth(12),
                  // Facebook-style red dot
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconSection() {
    if (daoTaoModel != null) {
      return Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Color(0xffFFF4E5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.school_rounded,
          color: Color(0xffFF9500),
          size: 22,
        ),
      );
    }

    final type = thongBaoModel?.loaiNotification;
    final guidImg = thongBaoModel?.guidAnhHienThi;

    if (guidImg != null && guidImg.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: CachedNetworkImage(
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          imageUrl: '${ServicesUrl().baseUrlFileDownload}$guidImg$kParamThumbImage',
          cacheKey: '${ServicesUrl().baseUrlFileDownload}$guidImg',
          errorWidget: (context, url, error) => _buildFallbackIcon(type),
        ),
      );
    }
    return _buildFallbackIcon(type);
  }

  Widget _buildFallbackIcon(String? type) {
    IconData iconData = Icons.notifications_rounded;
    Color iconColor = const Color(0xff003392);
    Color bgColor = const Color(0xffE8F4FF);

    if (type == LoaiThongBao.CamNang.name) {
      iconData = Icons.menu_book_rounded;
      iconColor = const Color(0xffFF9500);
      bgColor = const Color(0xffFFF4E5);
    } else if (type == LoaiThongBao.TinTuc.name ||
               type == LoaiThongBao.Cmsvnu_TinTuc.name ||
               type == LoaiThongBao.Cmsvnu_ThongBao.name) {
      iconData = Icons.article_rounded;
      iconColor = const Color(0xff007AFF);
      bgColor = const Color(0xffE5F2FF);
    } else if (type == LoaiThongBao.TinHeThong.name) {
      iconData = Icons.info_outline_rounded;
      iconColor = const Color(0xff34C759);
      bgColor = const Color(0xffEAF9EE);
    } else if (type == LoaiThongBao.CauHoi.name ||
               type == LoaiThongBao.ChuDeCauHoi.name ||
               type == LoaiThongBao.TraLoiCauHoi.name) {
      iconData = Icons.question_answer_rounded;
      iconColor = const Color(0xffAF52DE);
      bgColor = const Color(0xffF5EBFB);
    } else if (type == LoaiThongBao.PhongTro.name) {
      iconData = Icons.home_work_rounded;
      iconColor = const Color(0xff5856D6);
      bgColor = const Color(0xffEEEEFF);
    } else if (type == LoaiThongBao.HuongDanSuDung.name) {
      iconData = Icons.menu_book_outlined;
      iconColor = const Color(0xffFFCC00);
      bgColor = const Color(0xffFFFBE6);
    } else if (type == LoaiThongBao.TraLoiPhanAnh.name) {
      iconData = Icons.chat_bubble_outline_rounded;
      iconColor = const Color(0xffFF3B30);
      bgColor = const Color(0xffFFEBEA);
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 22,
      ),
    );
  }
}
