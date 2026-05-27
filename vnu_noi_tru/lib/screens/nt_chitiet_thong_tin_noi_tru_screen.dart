import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:octo_image/octo_image.dart';
import 'package:vnu_core/common/download_manager.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/constants/constant.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/navi_widget.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_noi_tru/nt_globals.dart';
import 'package:vnu_noi_tru/repository/noitru_repository.dart';

import '../models/model.dart';

class NTChiTietThongTinNoiTruScreen extends StatefulWidget {
  final NtTinTucModel? tinTucModel;
  final String? title;
  final int? tinTucId;

  const NTChiTietThongTinNoiTruScreen(
      {Key? key, required this.tinTucModel, required this.tinTucId, this.title})
      : super(key: key);

  @override
  State<NTChiTietThongTinNoiTruScreen> createState() =>
      _NTChiTietThongTinNoiTruScreenState();
}

class _NTChiTietThongTinNoiTruScreenState
    extends State<NTChiTietThongTinNoiTruScreen> {
  late BuildContext hubContext;

  NtTinTucModel? tinTucModel;

  @override
  void initState() {
    super.initState();
    tinTucModel = widget.tinTucModel;
    if (tinTucModel == null) {
      _getDetail();
    }
  }

  _getDetail() {
    Future.delayed(Duration.zero, () async {
      if (widget.tinTucId == null) {
        return;
      }
      try {
        Utils.showProgress(hubContext);
        var response =
            await NoiTruRepository().getChiTietTinTuc(widget.tinTucId!);
        if (mounted) {
          Utils.dismissProgress(hubContext);
          setState(() {
            tinTucModel = response.data;
          });
        }
      } catch (e) {
        Utils.dismissProgress(hubContext);
        logError(e.toString());
        snackBarError(kMessageError);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NaviWidget(
        titleStr:
            widget.title ?? (NtGlobals().menuNameChuyenMuc ?? 'Trang chủ'),
        leftAction: svgAction('assets/images/ic_navi_back.svg', action: () {
          Navigator.pop(context);
        }),
      ),
      backgroundColor: Colors.white,
      body: ProgressHubWidget(
        contextComplete: (ctx) {
          hubContext = ctx;
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tinTucModel?.tieuDe ?? '',
                  style: AppTheme.body1.copyWith(
                      fontSize: 20,
                      color: Color(0xff00803D),
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  tinTucModel?.thoiGianXuatBan ?? '',
                  style: AppTheme.body1
                      .copyWith(fontSize: 13, color: Color(0xff637392)),
                ),
                const SizedBox(
                  height: 8,
                ),
                Html(
                  data: tinTucModel?.noiDung ?? '',
                  extensions: [
                    TagExtension(
                      tagsToExtend: {"img"},
                      builder: (context) => CssBoxWidget(
                        style: context.styledElement!.style,
                        child: CachedNetworkImage(
                          imageUrl: context.attributes['src'] ?? '',
                          cacheKey: context.attributes['src'] ?? '',
                          imageBuilder: (context, imageProvider) {
                            return OctoImage(image: imageProvider);
                          },
                          placeholder: (context, url) => Container(
                            height: 250,
                            width: 164,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        ),
                      ),
                    ),
                  ],
                ),
                // danh sach file
                _filesWidget(),
                const SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filesWidget() {
    if (tinTucModel?.filesDinhKem == null) {
      return const SizedBox();
    }
    return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: tinTucModel?.filesDinhKem?.length,
        itemBuilder: (ctx, index) {
          return _itemFile(tinTucModel!.filesDinhKem![index]);
        });
  }

  Widget _itemFile(NtNewsFileAttachModel file) {
    return InkWell(
      onTap: () {
        if (file.fileUrl == null || file.filename == null) {
          return;
        }
        //Download File
        Utils.showProgress(hubContext);
        VnuDownLoadManager().downloadFile(
          file.fileUrl!,
          file.filename,
          onComplete: (path) {
            //
            Utils.dismissProgress(hubContext);
            logSuccess(path);
            VnuDownLoadManager().openFile(path);
          },
          onError: (e) {
            Utils.dismissProgress(hubContext);
            snackBarError(e);
          },
        );
      },
      child: Row(
        children: [
          svgAction('assets/images/ic_attach_file.svg', height: 15),
          const SizedBox(
            width: 0,
          ),
          Expanded(
            child: Text(
              file.filename ?? '',
              style: AppTheme.body2,
            ),
          )
        ],
      ),
    );
  }
}
