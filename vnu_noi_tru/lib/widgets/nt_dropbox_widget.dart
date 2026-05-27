import 'package:flutter/material.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/themes/app_theme.dart';

class NTDropboxWidget extends StatefulWidget {
  final String title;
  final String? value;
  final List<String> listOption;
  final bool? activeSelect;
  final Function(String value, int index)? onSelected;
  const NTDropboxWidget(
      {super.key,
      required this.title,
      required this.value,
      required this.listOption,
      this.activeSelect = false,
      this.onSelected});

  @override
  State<NTDropboxWidget> createState() => _NTDropboxWidgetState();
}

class _NTDropboxWidgetState extends State<NTDropboxWidget> {
  @override
  Widget build(BuildContext context) {
    // int _indexSelected = widget.listOption.indexOf(widget.value ?? '');
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: AppTheme.body2.copyWith(fontStyle: FontStyle.italic),
          ),
          Container(
            height: 46,
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            padding: const EdgeInsets.only(left: 10, right: 8),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xffBAC6DE))),
            child: Row(
              children: [
                Expanded(
                    child: DropdownButton<String>(
                        items: _buildDropdown(),
                        value: widget.value,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: svgAsset('assets/images/ic_arrow_down.svg'),
                        onChanged: widget.activeSelect == false
                            ? null
                            : (value) {
                                if (value == null || widget.onSelected == null)
                                  return;
                                logSuccess(value);
                                widget.onSelected!(
                                    value, widget.listOption.indexOf(value));
                              }))
              ],
            ),
          )
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdown() {
    List<DropdownMenuItem<String>> list = [];
    for (var i = 0; i < widget.listOption.length; i++) {
      list.add(DropdownMenuItem<String>(
        value: widget.listOption[i],
        child: Container(
          margin: const EdgeInsets.all(8),
          child: Text(
            widget.listOption[i],
            style: AppTheme.body2.copyWith(fontWeight: FontWeight.normal),
          ),
        ),
      ));
    }
    return list;
  }
}
