import 'package:flutter/material.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/loading_indicator.dart';

class WhiteButton extends StatelessWidget {
  final String title;
  final double? padding;
  final double? width;
  final double? height;
  final VoidCallback? action;
  const WhiteButton(
      {super.key,
      required this.title,
      this.padding = 8,
      this.width,
      this.height,
      this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action,
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.all(padding ?? 8.0),
        constraints: const BoxConstraints(minWidth: 80),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.backgroundBlueColor)),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.body2.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class BlueButton extends StatelessWidget {
  final String title;
  final double? padding;
  final double? width;
  final double? height;
  final VoidCallback? action;
  final bool? isShowLoading;
  final Color bgColor;
  const BlueButton(
      {super.key,
      required this.title,
      this.padding = 8,
      this.width,
      this.height,
      this.isShowLoading,
      this.action,
      this.bgColor = AppTheme.backgroundBlueColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (isShowLoading == true) {
          return;
        }
        if (action != null) {
          action!();
        }
      },
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.all(padding ?? 8.0),
        constraints: const BoxConstraints(
          minWidth: 80,
        ),
        decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: bgColor)),
        child: isShowLoading == true
            ? const LoadingIndicator(
                height: 17,
                radius: 8,
                color: Colors.white,
              )
            : Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTheme.body2.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }
}
