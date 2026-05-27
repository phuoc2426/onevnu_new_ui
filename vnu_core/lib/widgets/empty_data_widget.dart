import 'package:flutter/material.dart';
import 'package:vnu_core/themes/app_theme.dart';

class EmptyDataWidget extends StatelessWidget {
  const EmptyDataWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Không tìm thấy dữ liệu',
        style: AppTheme.body2,
      ),
    );
  }
}
