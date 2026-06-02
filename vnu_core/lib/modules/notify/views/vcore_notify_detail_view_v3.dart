import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/common/datetime_utils.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/constants/datetime_const.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/common/vnu_cache_manager.dart';
import 'package:vnu_core/services/services_url.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import '../../../common/space_widget.dart';

class VcoreNotifyDetailViewV3 extends StatefulWidget {
  final String title;
  final String htmlContent;
  final String? sender;
  final DateTime? date;
  final String? category;
  final List<String>? fileGuids;
  final List<String>? fileNames;
  final bool showMetadata;

  const VcoreNotifyDetailViewV3({
    super.key,
    required this.title,
    required this.htmlContent,
    this.sender,
    this.date,
    this.category,
    this.fileGuids,
    this.fileNames,
    this.showMetadata = true,
  });

  @override
  State<VcoreNotifyDetailViewV3> createState() => _VcoreNotifyDetailViewV3State();
}

class _VcoreNotifyDetailViewV3State extends State<VcoreNotifyDetailViewV3> {
  
  Future<void> _downloadAndShare(String guid, String fileName) async {
    if (guid.isEmpty) {
      snackBarError('Không tìm thấy thông tin tệp đính kèm.');
      return;
    }
    Utils.showProgress(context);

    String url = '${ServicesUrl().baseUrlFileDownload}$guid';
    try {
      File? file = await VnuCacheManager.downloadAndCache(
        url,
        guid,
        fileName.fileExtension(),
      );
      Utils.dismissProgress(context);

      if (file != null) {
        logSuccess(file.path);
        await Share.shareXFiles([XFile(file.path)], subject: fileName);
      } else {
        snackBarError('Không thể tải tệp đính kèm');
      }
    } catch (e) {
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    }
  }

  Future<void> _shareTextContent() async {
    final plainText = widget.htmlContent
        .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    String metadataText = '';
    if (widget.showMetadata) {
      if (widget.sender != null) metadataText += "\nNgười gửi: ${widget.sender}";
      if (widget.date != null) {
        metadataText += "\nNgày: ${DateTimeUtils.stringFromDateTime(widget.date!.toLocal(), DateTimeConst.U_SECOND_FORMAT)}";
      }
    }

    final shareBody = "${widget.title}\n\n$plainText$metadataText";
    await Share.share(shareBody, subject: widget.title);
  }

  @override
  Widget build(BuildContext context) {
    final hasFiles = widget.fileGuids != null && 
                     widget.fileGuids!.isNotEmpty && 
                     widget.fileNames != null && 
                     widget.fileNames!.isNotEmpty;

    final hasMetadata = widget.showMetadata && (
      widget.date != null || 
      (widget.sender != null && widget.sender!.isNotEmpty) || 
      (widget.category != null && widget.category!.isNotEmpty)
    );

    return VcoreModuleScaffold(
      title: 'Chi tiết thông báo',
      showBackButton: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ribbon Header style
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'THÔNG BÁO',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: AppFontSizes.font11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        spaceHeight(16),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: TextStyles.semiBold.copyWith(
                            fontSize: AppFontSizes.extraLarge,
                            color: AppColors.darkNavy,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                spaceHeight(16),
                
                // Metadata Wrapped Row (Only displays fields returned from the API)
                if (hasMetadata)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xffF7FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xffEDF2F7)),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 10,
                        alignment: WrapAlignment.start,
                        children: [
                          if (widget.date != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xff718096)),
                                spaceWidth(6),
                                Text(
                                  DateTimeUtils.stringFromDateTime(
                                    widget.date!.toLocal(),
                                    DateTimeConst.U_SECOND_FORMAT,
                                  ),
                                  style: const TextStyle(fontSize: AppFontSizes.small, color: Color(0xff4A5568)),
                                ),
                              ],
                            ),
                          if (widget.sender != null && widget.sender!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_rounded, size: 14, color: Color(0xff718096)),
                                spaceWidth(6),
                                Flexible(
                                  child: Text(
                                    widget.sender!,
                                    style: const TextStyle(fontSize: AppFontSizes.small, color: Color(0xff4A5568)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (widget.category != null && widget.category!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_offer_rounded, size: 13, color: Color(0xff718096)),
                                spaceWidth(6),
                                Text(
                                  widget.category!,
                                  style: const TextStyle(fontSize: AppFontSizes.small, color: Color(0xff4A5568)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                
                if (hasMetadata)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: const Divider(color: Color(0xffEDF2F7), thickness: 1),
                  ),

                // Spaced and Styled Body Typography Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Html(
                    data: widget.htmlContent,
                    onLinkTap: (url, attributes, element) {
                      if (url != null) {
                        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      }
                    },
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14.5),
                        lineHeight: const LineHeight(1.6),
                        color: const Color(0xff2D3748),
                        fontFamily: 'Inter',
                      ),
                      "p": Style(
                        margin: Margins.only(bottom: 16),
                      ),
                      "ul": Style(
                        margin: Margins.only(bottom: 16),
                        padding: HtmlPaddings.only(left: 20),
                      ),
                      "ol": Style(
                        margin: Margins.only(bottom: 16),
                        padding: HtmlPaddings.only(left: 20),
                      ),
                      "li": Style(
                        margin: Margins.only(bottom: 8),
                      ),
                      "blockquote": Style(
                        margin: Margins.symmetric(vertical: 16, horizontal: 8),
                        padding: HtmlPaddings.only(left: 16, top: 8, bottom: 8),
                        backgroundColor: const Color(0xffF7FAFC),
                        border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
                      ),
                      "a": Style(
                        color: AppColors.primary,
                        textDecoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                      "strong": Style(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1A202C),
                      ),
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: const Divider(color: Color(0xffEDF2F7), thickness: 1),
                ),

                // Attachments / Share section with App Color buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasFiles) ...[
                        const Text(
                          'Tài liệu đính kèm:',
                          style: TextStyle(
                            fontSize: AppFontSizes.mediumSmall,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff4A5568),
                          ),
                        ),
                        spaceHeight(10),
                        ...List.generate(widget.fileGuids!.length, (index) {
                          final fileGuid = widget.fileGuids![index];
                          final fileName = widget.fileNames!.length > index
                              ? widget.fileNames![index]
                              : 'Tài liệu đính kèm';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => _downloadAndShare(fileGuid, fileName),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xffF0F4FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xffD2E1F3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.attach_file_rounded, color: Color(0xff003392), size: 18),
                                    spaceWidth(10),
                                    Expanded(
                                      child: Text(
                                        fileName,
                                        style: const TextStyle(
                                          fontSize: AppFontSizes.mediumSmall,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xff003392),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.share_rounded, color: Color(0xff003392), size: 16),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        spaceHeight(12),
                      ],
                      
                      // CTA Button style: app color linear gradient
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2F9E44), // AppColors.primary
                              Color(0xFF047747), // AppColors.brandGreen
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.24),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _shareTextContent,
                            borderRadius: BorderRadius.circular(16),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.share_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Chia sẻ thông báo này',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: AppFontSizes.font14_5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
