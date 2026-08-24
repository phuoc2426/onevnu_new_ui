import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/responsive/vnu_page_constraints.dart';
import 'package:vnu_core/widgets/responsive/vnu_page_padding.dart';
import 'package:vnu_core/widgets/vnu_module_app_bar.dart';

/// Default background for standard OneVNU module pages.
const Color kDefaultModuleBgColor = Color(0xFFF6F8FA);

/// Standard page shell for OneVNU feature pages.
///
/// P3 adds optional responsive page constraints/padding. The default remains
/// unrestricted so existing pages do not silently change layout until they are
/// explicitly migrated.
class VcoreModuleScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color backgroundColor;
  final Widget? leading;
  final VnuPageWidth pageWidth;
  final bool responsivePadding;

  const VcoreModuleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor = kDefaultModuleBgColor,
    this.leading,
    this.pageWidth = VnuPageWidth.unrestricted,
    this.responsivePadding = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = VnuPageConstraints(width: pageWidth, child: body);
    if (responsivePadding) {
      content = Padding(
        padding: VnuPagePadding.resolve(context),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: VnuModuleAppBar(
        title: title,
        leading: leading,
        actions: actions,
        showBackButton: showBackButton,
      ),
      body: SafeArea(child: content),
      floatingActionButton: floatingActionButton,
    );
  }
}
