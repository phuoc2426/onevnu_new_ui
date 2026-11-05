import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/vnu_module_app_bar.dart';
import 'package:vnu_core/widgets/vnu_press_motion.dart';

/// Thiet ke noi dung hai dich vu. Header luon dung VnuModuleAppBar cua ONEVNU.
abstract final class StudentServiceUI {
  static const Color background = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF182820);
  static const Color secondary = Color(0xFF68756E);
  static const Color faint = Color(0xFF929B95);
  static const Color line = Color(0xFFE6EAE7);
  static const Color green = Color(0xFF08794D);
  static const Color pale = Color(0xFFF3F7F4);
  static const Color caution = Color(0xFFB26712);
  static const Color danger = Color(0xFFC13B35);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20);

  /// Su dung CHINH widget navbar cua cac phan he khac (Lich hoc, Diem...).
  /// Khong ve AppBar rieng cho mot cua va hoc phi.
  static PreferredSizeWidget appBar({
    required String title,
    required VoidCallback onBack,
    List<Widget> actions = const <Widget>[],
  }) => VnuModuleAppBar(
    title: title,
    foregroundColor: Colors.black,
    leading: VnuPressMotion(
      child: BackButton(color: Colors.black, onPressed: onBack),
    ),
    actions: actions,
  );

  /// Tat dark pressed overlay/ripple trong 2 module, chi giu animation scale.
  static Widget withoutTapHighlight(BuildContext context, Widget child) {
    final base = Theme.of(context);
    final transparent = MaterialStateProperty.all<Color>(Colors.transparent);
    final buttonStyle = ButtonStyle(
      splashFactory: NoSplash.splashFactory,
      overlayColor: transparent,
    );
    return Theme(
      data: base.copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        iconButtonTheme: IconButtonThemeData(style: buttonStyle),
        textButtonTheme: TextButtonThemeData(style: buttonStyle),
        outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
        filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      ),
      child: child,
    );
  }

  static InputDecoration field(String hint, {Widget? prefix}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: faint, fontSize: 14),
    prefixIcon: prefix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    filled: true,
    fillColor: const Color(0xFFF8F9F8),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: line)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: line)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: green, width: 1.4)),
  );
}

/// Chuyen trang/tab nhe: slide 10px + fade, khong phu lop toi khi cham.
class StudentViewSwitch extends StatelessWidget {
  const StudentViewSwitch({super.key, required this.pageKey, required this.child});
  final String pageKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
      reverseDuration: reduceMotion ? Duration.zero : const Duration(milliseconds: 190),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (content, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.035, 0),
            end: Offset.zero,
          ).animate(animation),
          child: content,
        ),
      ),
      child: KeyedSubtree(key: ValueKey<String>(pageKey), child: child),
    );
  }
}

class StudentSection extends StatelessWidget {
  const StudentSection(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Row(children: [
      Expanded(child: Text(title, style: const TextStyle(
        color: StudentServiceUI.ink, fontSize: 16,
        fontWeight: FontWeight.w700, letterSpacing: -0.25))),
      if (trailing != null) trailing!,
    ]),
  );
}

class StudentInfoLine extends StatelessWidget {
  const StudentInfoLine({super.key, required this.label, required this.value,
    this.valueColor, this.borders = true});
  final String label;
  final String value;
  final Color? valueColor;
  final bool borders;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(border: borders ? const Border(
      bottom: BorderSide(color: StudentServiceUI.line)) : null),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 4, child: Text(label, style: const TextStyle(
        color: StudentServiceUI.secondary, fontSize: 13.5, height: 1.4))),
      const SizedBox(width: 12),
      Expanded(flex: 6, child: Text(value, textAlign: TextAlign.end,
        style: TextStyle(color: valueColor ?? StudentServiceUI.ink,
          fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w600))),
    ]),
  );
}

class StudentStatus extends StatelessWidget {
  const StudentStatus(this.text, {super.key, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 6, height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 7),
      Flexible(child: Text(text, maxLines: 2,
        style: TextStyle(color: color, fontSize: 12,
          fontWeight: FontWeight.w600, height: 1.35))),
    ]);
}

class StudentSegment extends StatelessWidget {
  const StudentSegment({super.key, required this.labels,
    required this.selected, required this.onSelected});
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [for (final label in labels)
        VnuPressMotion(
          onTap: () => onSelected(label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minWidth: 88),
            margin: const EdgeInsets.only(right: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border(bottom: BorderSide(
              width: label == selected ? 2.5 : 1,
              color: label == selected ? StudentServiceUI.green : StudentServiceUI.line,
            ))),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              style: TextStyle(fontSize: 13.5,
                color: label == selected ? StudentServiceUI.green
                    : StudentServiceUI.secondary,
                fontWeight: label == selected ? FontWeight.w700
                    : FontWeight.w500),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ],
    ),
  );
}

class StudentActionBar extends StatelessWidget {
  const StudentActionBar({super.key, required this.text,
    required this.onPressed, this.loading = false, this.isDestructive = false});
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) => SafeArea(top: false, child: Container(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
    decoration: const BoxDecoration(color: Colors.white,
      border: Border(top: BorderSide(color: StudentServiceUI.line))),
    child: VnuPressMotion(
      enabled: !loading && onPressed != null,
      child: SizedBox(height: 48, width: double.infinity,
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            overlayColor: Colors.transparent,
            backgroundColor: isDestructive ? StudentServiceUI.danger
                : StudentServiceUI.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white)))
              : Text(text, style: const TextStyle(fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ),
      ),
    ),
  ));
}
