import 'package:flutter/material.dart';
import '../widgets/loading_indicator.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class RefreshFooterWidget extends StatelessWidget {
  const RefreshFooterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomFooter(
      height: 100,
      builder: (BuildContext context, LoadStatus? mode) {
        Widget body;
        if (mode == LoadStatus.idle) {
          body = const SizedBox();
        } else if (mode == LoadStatus.loading) {
          body = const LoadingIndicator();
        } else if (mode == LoadStatus.failed) {
          body = const Text('"Tác vụ không thành công, vui lòng thử lại"');
        } else if (mode == LoadStatus.canLoading) {
          body = const SizedBox();
        } else if (mode == LoadStatus.noMore) {
          body = const SizedBox();
        } else {
          body = const Text("Không tìm thấy dữ liệu");
        }
        return SizedBox(
          height: 100,
          child: Center(child: body),
        );
      },
    );
  }
}
