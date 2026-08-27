import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';

import 'vnu_field_decoration.dart';
import 'vnu_field_metrics.dart';
import 'vnu_field_shell.dart';
import 'vnu_horizontal_readable_value.dart';

/// Floating-label surface for select/date/read-only controls.
class VnuReadOnlyField extends StatefulWidget {
  const VnuReadOnlyField({
    super.key,
    required this.displayText,
    required this.placeholder,
    this.label,
    this.onTap,
    this.enabled = true,
    this.errorText,
    this.requiredField = false,
    this.guideTargetId,
    this.leading,
    this.trailing,
    this.margin,
    this.compact = false,
    this.hasValue,
  });

  final String? label;
  final String displayText;
  final String placeholder;
  final VoidCallback? onTap;
  final bool enabled;
  final String? errorText;
  final bool requiredField;
  final String? guideTargetId;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry? margin;
  final bool compact;
  final bool? hasValue;

  @override
  State<VnuReadOnlyField> createState() => _VnuReadOnlyFieldState();
}

class _VnuReadOnlyFieldState extends State<VnuReadOnlyField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool effectiveHasValue =
        widget.hasValue ?? widget.displayText.trim().isNotEmpty;
    final bool hasError =
        widget.errorText != null && widget.errorText!.trim().isNotEmpty;
    final String shownText =
        effectiveHasValue ? widget.displayText : widget.placeholder;

    final TextStyle textStyle = TextStyles.medium.copyWith(
      fontSize: AppFontSizes.mediumSmall,
      color: !widget.enabled
          ? AppColors.textHint
          : effectiveHasValue
              ? AppColors.textPrimary
              : AppColors.textHint,
    );

    final Widget decorated = Focus(
      focusNode: _focusNode,
      child: Semantics(
        button: widget.onTap != null,
        enabled: widget.enabled,
        label: <String?>[widget.label, shownText]
            .whereType<String>()
            .where((String value) => value.trim().isNotEmpty)
            .join(', '),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled && widget.onTap != null
                ? () {
                    _focusNode.requestFocus();
                    widget.onTap!.call();
                  }
                : null,
            borderRadius: BorderRadius.circular(VnuFieldMetrics.radius),
            child: InputDecorator(
              isFocused: _focusNode.hasFocus,
              isEmpty: !effectiveHasValue,
              decoration: VnuFieldDecoration.build(
                label: widget.label,
                // Placeholder and label are usually the same semantic concept.
                // Do not render a second hint while the label rests inside.
                hintText: _focusNode.hasFocus && !effectiveHasValue
                    ? widget.placeholder
                    : null,
                requiredField: widget.requiredField,
                enabled: widget.enabled,
                readOnly: true,
                hasError: hasError,
                prefixIcon: widget.leading,
                suffixIcon: widget.trailing,
                compact: widget.compact,
              ).copyWith(
                constraints: BoxConstraints(
                  minHeight: VnuFieldMetrics.minHeightFor(
                    context,
                    compact: widget.compact,
                  ),
                ),
              ),
              child: effectiveHasValue
                  ? VnuHorizontalReadableValue(text: shownText, style: textStyle)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    return VnuFieldShell(
      errorText: widget.errorText,
      enabled: widget.enabled,
      margin: widget.margin,
      guideTargetId: widget.guideTargetId,
      child: decorated,
    );
  }
}
