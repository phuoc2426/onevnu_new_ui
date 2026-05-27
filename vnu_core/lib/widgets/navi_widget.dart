import 'package:flutter/material.dart';
import 'package:vnu_core/common/utils.dart';

import '../themes/app_theme.dart';

class NaviWidget extends AppBar {
  final String? titleStr;

  final Widget? leftAction;
  final List<Widget>? rightActions;

  NaviWidget({super.key, this.titleStr, this.leftAction, this.rightActions});

  @override
  State<NaviWidget> createState() => _NaviWidgetState();
}

class _NaviWidgetState extends State<NaviWidget> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xff007F3E),
      flexibleSpace: Container(
        child: svgAsset('assets/images/bg_navi.svg',
            height: 120, fit: BoxFit.cover),
      ),
      centerTitle: false,
      shadowColor: Colors.transparent,
      titleSpacing: 0.0,
      leading: widget.leftAction,
      actions: widget.rightActions,
      title: widget.titleStr != null
          ? Padding(
              padding:
                  EdgeInsets.only(right: widget.rightActions == null ? 16 : 0),
              child: Text(
                widget.titleStr!,
                textAlign: TextAlign.start,
                maxLines: 2,  
                style: AppTheme.subtitle1
                    .copyWith(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          : null,
    );
  }
}
