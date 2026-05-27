import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';

typedef StringCallback = void Function(String text);

class VcoreProfileTextFieldWidget extends StatefulWidget {
  final String title;
  final String hintText;
  final String? value;
  final bool isRequired;
  final bool isDisable;
  final int? maxLine;
  final bool? autoFocus;
  final TextInputType? keyboardType;
  final StringCallback? onChange;
  final StringCallback onSubmitted;
  const VcoreProfileTextFieldWidget(
      {super.key,
      required this.title,
      required this.hintText,
      this.value,
      this.isRequired = false,
      this.isDisable = false,
      this.maxLine,
      this.autoFocus,
      this.keyboardType,
      this.onChange,
      required this.onSubmitted});

  @override
  State<VcoreProfileTextFieldWidget> createState() =>
      _VcoreProfileTextFieldWidgetState();
}

class _VcoreProfileTextFieldWidgetState
    extends State<VcoreProfileTextFieldWidget> {
  final TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      textEditingController.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value != null && (widget.value != textEditingController.text)) {
      textEditingController.text = widget.value ?? '';
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: TextStyles.regular
                  .copyWith(fontSize: 13, color: Colors.black),
            ),
            Text(
              widget.isRequired ? ' *' : '',
              style:
                  TextStyles.regular.copyWith(fontSize: 13, color: Colors.red),
            )
          ],
        ),
        spaceHeight(8),
        Container(
            width: double.infinity,
            height: widget.maxLine == null ? 40 : null,
            padding:
                EdgeInsets.symmetric(vertical: widget.maxLine == null ? 0 : 8),
            decoration: BoxDecoration(
                color:
                    widget.isDisable ? const Color(0xffF6F6F6) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xff879ABF))),
            child: Row(
              children: [
                spaceWidth(10),
                Expanded(
                    child: TextField(
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true, //Need for remove padding
                      contentPadding: EdgeInsets.zero,
                      hintText: widget.hintText,
                      hintStyle: TextStyles.regular
                          .copyWith(color: const Color(0xff879ABF)),
                      labelStyle: TextStyles.regular.copyWith(
                          color: widget.isDisable
                              ? const Color(0xff879ABF)
                              : Colors.black)),
                  controller: textEditingController,
                  keyboardType: widget.keyboardType,
                  readOnly: widget.isDisable,
                  maxLines: widget.maxLine ?? 1,
                  autofocus: widget.autoFocus ?? false,
                  style: TextStyles.regular.copyWith(
                      color: widget.isDisable
                          ? const Color(0xff879ABF)
                          : Colors.black),
                  onChanged: widget.onChange,
                  onSubmitted: (value) {
                    print('Search for key --> $value');
                    widget.onSubmitted(value);
                  },
                )),
              ],
            )),
      ],
    );
  }
}
