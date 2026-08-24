import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/common/error/app_error_reporter.dart';
import 'package:vnu_core/common/error/app_error_mapper.dart';
import 'package:vnu_core/cubit/file_cubit.dart';
import 'package:vnu_core/widgets/error_widget.dart';
import 'package:vnu_core/widgets/loading_indicator.dart';
import 'package:vnu_core/widgets/navi_widget.dart';

class VCorePreviewPdfScreen extends StatefulHookWidget {
  final String? title;
  final String fileId;

  const VCorePreviewPdfScreen({
    super.key,
    required this.title,
    required this.fileId,
  });

  @override
  State<VCorePreviewPdfScreen> createState() => _VCorePreviewPdfScreenState();
}

class _VCorePreviewPdfScreenState extends State<VCorePreviewPdfScreen> {
  final FileCubit _fileCubit = FileCubit();

  @override
  void dispose() {
    _fileCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      _fileCubit.getDetailFileId(widget.fileId);
      return null;
    }, [widget.fileId]);
    final currentPage = useState(0);
    final isReady = useState(false);
    final errorMessage = useState('');
    return Scaffold(
      appBar: NaviWidget(
        titleStr: widget.title ?? 'Xem chi tiết file',
        leftAction: svgAction('assets/images/ic_navi_back.svg', action: () {
          Navigator.pop(context);
        }),
      ),
      backgroundColor: Colors.white,
      body: BlocBuilder<FileCubit, FileState>(
        bloc: _fileCubit,
        builder: (context, state) {
          if (state is FileLoadedErrorState) {
            return Center(
              child: ErrorRefreshWidget(
                message: state.message,
                refreshAction: () => _fileCubit.getDetailFileId(widget.fileId),
              ),
            );
          }
          if (state is FileLoadedSuccessState) {
            return Stack(
              fit: StackFit.expand,
              children: [
                PDFView(
                  filePath: state.localPath,
                  pageFling: false,
                  pageSnap: false,
                  defaultPage: currentPage.value,
                  onRender: (_pages) async {
                    await Future.delayed(
                      const Duration(seconds: 1),
                      () => setState(() {
                        isReady.value = true;
                      }),
                    );
                  },
                  onError: (error) {
                    final appError = AppErrorMapper.map(
                      error,
                      fallbackMessage:
                          'Không thể hiển thị tài liệu. Vui lòng thử lại.',
                    );
                    errorMessage.value = appError.userMessage;
                    unawaited(AppErrorReporter.report(appError));
                  },
                  onPageError: (page, error) {
                    final appError = AppErrorMapper.map(
                      error,
                      fallbackMessage:
                          'Không thể hiển thị trang tài liệu này.',
                    );
                    errorMessage.value = appError.userMessage;
                    unawaited(AppErrorReporter.report(
                      appError,
                      context: <String, Object?>{'pdfPage': page},
                    ));
                  },
                  onPageChanged: (int? page, int? total) {
                    currentPage.value = page ?? 0;
                  },
                ),
                errorMessage.value.isEmpty
                    ? !isReady.value
                        ? const Center(child: LoadingIndicator())
                        : Container()
                    : VnuErrorState(
                        title: 'Không thể hiển thị tài liệu',
                        message: errorMessage.value,
                        compact: true,
                      )
              ],
            );
          }

          return const Center(child: LoadingIndicator());
        },
      ),
    );
  }
}

