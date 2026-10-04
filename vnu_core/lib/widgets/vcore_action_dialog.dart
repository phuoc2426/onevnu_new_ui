import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum VcoreDialogActionTone { primary, secondary, danger }

class VcoreDialogAction<T> {
  final String label;
  final T value;
  final IconData? icon;
  final VcoreDialogActionTone tone;
  final bool enabled;

  const VcoreDialogAction({
    required this.label,
    required this.value,
    this.icon,
    this.tone = VcoreDialogActionTone.secondary,
    this.enabled = true,
  });
}

Future<T?> showVcoreActionDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  required List<VcoreDialogAction<T>> actions,
  bool barrierDismissible = false,
  IconData? leadingIcon,
}) {
  assert(actions.isNotEmpty && actions.length <= 3);
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext dialogContext) {
      return VcoreActionDialog<T>(
        title: title,
        content: content,
        actions: actions,
        leadingIcon: leadingIcon,
      );
    },
  );
}

class VcoreActionDialog<T> extends StatelessWidget {
  final String title;
  final String content;
  final List<VcoreDialogAction<T>> actions;
  final IconData? leadingIcon;

  const VcoreActionDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.leadingIcon,
  }) : assert(actions.length > 0 && actions.length <= 3);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (leadingIcon != null) ...<Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(leadingIcon, color: primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: leadingIcon == null ? 1 : 5),
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.78),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                _DialogActionBar<T>(actions: actions),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogActionBar<T> extends StatelessWidget {
  final List<VcoreDialogAction<T>> actions;

  const _DialogActionBar({required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = 8;
        final double totalGap = gap * math.max(0, actions.length - 1);
        final double itemWidth = constraints.maxWidth.isFinite
            ? math.max(0, (constraints.maxWidth - totalGap) / actions.length)
            : 120;

        return Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            for (int i = 0; i < actions.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: gap),
              Expanded(
                child: _DialogActionButton<T>(
                  action: actions[i],
                  expectedWidth: itemWidth,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DialogActionButton<T> extends StatelessWidget {
  final VcoreDialogAction<T> action;
  final double expectedWidth;

  const _DialogActionButton({
    required this.action,
    required this.expectedWidth,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final bool enabled = action.enabled;

    Color background;
    Color foreground;
    Color border;
    switch (action.tone) {
      case VcoreDialogActionTone.primary:
        background = enabled ? primary : primary.withOpacity(0.35);
        foreground = Colors.white;
        border = background;
        break;
      case VcoreDialogActionTone.danger:
        background = enabled ? theme.colorScheme.error : theme.colorScheme.error.withOpacity(0.35);
        foreground = theme.colorScheme.onError;
        border = background;
        break;
      case VcoreDialogActionTone.secondary:
        background = theme.colorScheme.surface;
        foreground = enabled
            ? theme.colorScheme.onSurface.withOpacity(0.86)
            : theme.colorScheme.onSurface.withOpacity(0.38);
        border = theme.dividerColor.withOpacity(0.72);
        break;
    }

    return SizedBox(
      height: 46,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => Navigator.of(context).pop(action.value) : null,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : expectedWidth;
              // On narrow 2/3-button dialogs the icon steals too much label
              // width. Hide it before the label becomes unusably narrow.
              final bool showIcon = action.icon != null && width >= 118;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: width < 96 ? 6 : 9),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (showIcon) ...<Widget>[
                      Icon(action.icon, size: 18, color: foreground),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: VcoreMarqueeText(
                        action.label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// One-line text that stays centered when it fits and becomes a seamless
/// marquee only when the text is wider than the available width.
///
/// IMPORTANT: the marquee does not use a Row with oversized text. The old
/// implementation clipped the pixels but the internal RenderFlex could still
/// report RIGHT OVERFLOWED BY ... before painting. This implementation lays
/// out each text copy as a Positioned child inside a clipped Stack, so children
/// are allowed to be wider than the viewport without creating a Flex overflow.
class VcoreMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final Duration startDelay;
  final double gap;

  const VcoreMarqueeText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.startDelay = const Duration(milliseconds: 650),
    this.gap = 28,
  });

  @override
  State<VcoreMarqueeText> createState() => _VcoreMarqueeTextState();
}

class _VcoreMarqueeTextState extends State<VcoreMarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _startTimer;
  double _configuredDistance = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant VcoreMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.gap != widget.gap) {
      _stop();
      _configuredDistance = -1;
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _stop() {
    _startTimer?.cancel();
    _startTimer = null;
    _controller.stop();
    _controller.value = 0;
  }

  void _configure(double distance) {
    if (!mounted || distance <= 0 || (_configuredDistance - distance).abs() < 0.5) return;
    _configuredDistance = distance;
    _stop();
    final int milliseconds = math.max(2600, (distance * 24).round());
    _controller.duration = Duration(milliseconds: milliseconds);
    _startTimer = Timer(widget.startDelay, () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle effectiveStyle = widget.style ?? DefaultTextStyle.of(context).style;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: widget.text, style: effectiveStyle),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout();

        final double available = constraints.maxWidth.isFinite
            ? math.max(0, constraints.maxWidth)
            : painter.width;

        if (available <= 0) {
          return const SizedBox.shrink();
        }

        if (painter.width <= available + 0.5) {
          if (_controller.isAnimating || _startTimer != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _stop();
                _configuredDistance = -1;
              }
            });
          }
          return SizedBox(
            width: available,
            child: Text(
              widget.text,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              textAlign: widget.textAlign,
              style: effectiveStyle,
            ),
          );
        }

        final double distance = painter.width + widget.gap;
        final double textHeight = math.max(18, painter.height);
        WidgetsBinding.instance.addPostFrameCallback((_) => _configure(distance));

        return SizedBox(
          width: available,
          height: textHeight,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double dx = -_controller.value * distance;
                return Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: <Widget>[
                    Positioned(
                      left: dx,
                      top: 0,
                      child: Text(
                        widget.text,
                        maxLines: 1,
                        softWrap: false,
                        style: effectiveStyle,
                      ),
                    ),
                    Positioned(
                      left: dx + distance,
                      top: 0,
                      child: Text(
                        widget.text,
                        maxLines: 1,
                        softWrap: false,
                        style: effectiveStyle,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
