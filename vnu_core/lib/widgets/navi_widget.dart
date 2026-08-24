import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/vnu_module_app_bar.dart';

/// Compatibility adapter for legacy pages.
///
/// Existing `NaviWidget(...)` call sites now render the same header contract as
/// `VcoreModuleScaffold` (used by Lịch học & lịch thi). New pages should use
/// `VnuModuleAppBar` / `VcoreModuleScaffold` directly.
@Deprecated('Use VnuModuleAppBar or VcoreModuleScaffold')
class NaviWidget extends StatelessWidget implements PreferredSizeWidget {
  const NaviWidget({
    super.key,
    this.titleStr,
    this.leftAction,
    this.rightActions,
  });

  final String? titleStr;
  final Widget? leftAction;
  final List<Widget>? rightActions;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return VnuModuleAppBar(
      title: titleStr ?? '',
      leading: leftAction,
      actions: rightActions,
      showBackButton: leftAction == null,
    );
  }
}
