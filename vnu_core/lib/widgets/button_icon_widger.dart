import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/themes/app_theme.dart';

class ButtonIconWidget extends StatefulWidget {
  final String iconCode;
  final String title;
  final double? padding;
  final double? width;
  final double? height;
  final Color? textColor;
  final Color? bgColor;
  final Color? borderColor;
  final VoidCallback? action;

  const ButtonIconWidget({
    super.key,
    required this.title,
    this.padding = 8,
    this.width,
    this.height,
    required this.iconCode,
    this.action,
    this.textColor = Colors.white,
    this.bgColor = AppTheme.backgroundBlueColor,
    this.borderColor = AppTheme.backgroundBlueColor,
  });

  @override
  State<ButtonIconWidget> createState() => _ButtonIconWidgetState();
}

class _ButtonIconWidgetState extends State<ButtonIconWidget> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (widget.action != null) {
          widget.action!();
        }
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: EdgeInsets.all(widget.padding ?? 8.0),
        constraints: const BoxConstraints(
          minWidth: 80,
        ),
        decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.borderColor ?? AppTheme.backgroundBlueColor,
            )),
        child: Row(
          children: [
            Icon(
                IconData(widget.iconCode.parseImageInt(),
                    fontFamily: 'MaterialIcons'),
                size: 20,
                color: widget.textColor),
            const SizedBox(
              width: 4,
            ),
            Center(
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTheme.body2.copyWith(color: widget.textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
