import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';

import '../themes/app_theme.dart';

class ProgressHubWidget extends StatelessWidget {
  final Widget child;
  final Function(BuildContext hubContext)? contextComplete;
  const ProgressHubWidget(
      {super.key, required this.child, this.contextComplete});

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      indicatorWidget: const CupertinoActivityIndicator(
        radius: 14,
        color: AppTheme.colorMain,
      ),
      backgroundColor: Colors.white,
      textStyle: AppTheme.body2.copyWith(fontWeight: FontWeight.w500),
      child: Builder(builder: (ctx) {
        if (contextComplete != null) {
          contextComplete!(ctx);
        }
        return child;
      }),
    );
  }
}
