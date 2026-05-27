import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/themes/app_theme.dart';

class NtContainerDropboxWidget extends StatefulWidget {
  final String title;
  final String? value;
  final VoidCallback? onSelecte;
  final bool? activeSelect;
  const NtContainerDropboxWidget(
      {super.key,
      required this.title,
      this.onSelecte,
      this.activeSelect = false,
      required this.value});

  @override
  State<NtContainerDropboxWidget> createState() =>
      _NtContainerDropboxWidgetState();
}

class _NtContainerDropboxWidgetState extends State<NtContainerDropboxWidget> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.activeSelect == true
          ? () {
              if (widget.onSelecte != null) {
                widget.onSelecte!();
              }
            }
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: AppTheme.body2.copyWith(fontStyle: FontStyle.italic),
          ),
          Container(
            // height: 46,
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            padding:
                const EdgeInsets.only(left: 10, right: 8, bottom: 8, top: 8),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xffBAC6DE))),
            child: Row(
              children: [
                Expanded(
                    child: Text(
                  widget.value ?? '',
                  style: AppTheme.body2,
                )),
                svgAsset('assets/images/ic_arrow_down.svg')
              ],
            ),
          )
        ],
      ),
    );
  }
}
