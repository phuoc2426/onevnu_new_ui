import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/field/vnu_text_field.dart';

typedef StringCallback = void Function(String text);

/// Legacy profile adapter.
///
/// P2V2 routes profile text inputs through the shared VNU Field System. A
/// single-line value keeps a stable height and uses Flutter's native
/// horizontal text scrolling. Multiline fields continue to wrap vertically.
@Deprecated('Use VnuTextField from vnu_core/widgets/field/vnu_field.dart')
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

  const VcoreProfileTextFieldWidget({
    super.key,
    required this.title,
    required this.hintText,
    this.value,
    this.isRequired = false,
    this.isDisable = false,
    this.maxLine,
    this.autoFocus,
    this.keyboardType,
    this.onChange,
    required this.onSubmitted,
  });

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
    textEditingController.text = widget.value ?? '';
  }

  @override
  void didUpdateWidget(covariant VcoreProfileTextFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.value ?? '';
    if (next != textEditingController.text) {
      textEditingController.value = textEditingController.value.copyWith(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxLines = widget.maxLine ?? 1;
    return VnuTextField(
      label: widget.title,
      hintText: widget.hintText,
      controller: textEditingController,
      requiredField: widget.isRequired,
      enabled: true,
      readOnly: widget.isDisable,
      keyboardType: widget.keyboardType,
      maxLines: maxLines,
      minLines: maxLines == 1 ? 1 : 1,
      autofocus: widget.autoFocus ?? false,
      onChanged: widget.onChange,
      onSubmitted: widget.onSubmitted,
    );
  }
}
