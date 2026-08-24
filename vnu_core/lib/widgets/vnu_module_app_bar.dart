import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/widgets/field/vnu_horizontal_readable_value.dart';
import 'package:vnu_core/widgets/responsive/vnu_responsive_context.dart';

/// Header dùng chung cho các màn chức năng của OneVNU.
///
/// Nguyên tắc:
/// - Tiêu đề luôn căn giữa theo toàn bộ chiều rộng màn hình.
/// - Leading và actions không làm lệch title.
/// - Title dài có thể kéo ngang để đọc.
/// - Back/action luôn đứng cố định.
/// - Hỗ trợ text scaling.
class VnuModuleAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const VnuModuleAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor = Colors.white,
    this.foregroundColor = AppColors.textTitle,
  });

  final String title;

  /// Widget bên trái.
  ///
  /// Nếu null và [showBackButton] = true thì tự hiển thị BackButton
  /// khi route hiện tại có thể pop.
  final Widget? leading;

  /// Các action phía bên phải.
  final List<Widget>? actions;

  final bool showBackButton;
  final Color backgroundColor;
  final Color foregroundColor;

  static const double _normalToolbarHeight = 68.0;

  /// Chiều rộng mặc định dành cho back button.
  static const double _leadingReserve = 56.0;

  /// Mỗi action icon được reserve khoảng 48px.
  static const double _actionExtent = 48.0;

  /// Khoảng trống tối thiểu nếu một bên không có widget.
  static const double _emptySideReserve = 16.0;

  @override
  Size get preferredSize =>
      const Size.fromHeight(_normalToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    final effectiveLeading = leading ??
        (showBackButton && navigator.canPop()
            ? BackButton(
          color: foregroundColor,
          onPressed: () {
            Navigator.maybePop(context);
          },
        )
            : null);

    final effectiveActions =
        actions ?? const <Widget>[];

    final responsive =
    VnuResponsiveContext.of(context);

    final double toolbarHeight =
    responsive.isVeryLargeText
        ? 80.0
        : responsive.isLargeText
        ? 74.0
        : _normalToolbarHeight;

    // ---------------------------------------------------------
    // TÍNH VÙNG AN TOÀN HAI BÊN
    //
    // Ví dụ:
    //
    // LEFT = 56
    // RIGHT = 104
    //
    // thì cả hai phía của TITLE đều reserve 104.
    //
    // Nhờ vậy title vẫn nằm đúng tâm vật lý của màn hình.
    // ---------------------------------------------------------

    final double leftReserve =
    effectiveLeading != null
        ? _leadingReserve
        : _emptySideReserve;

    final double rightReserve =
    effectiveActions.isNotEmpty
        ? (effectiveActions.length *
        _actionExtent) +
        8.0
        : _emptySideReserve;

    final double sideReserve =
    math.max(leftReserve, rightReserve);

    return AppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      foregroundColor: foregroundColor,
      elevation: 0.5,
      shadowColor: AppColors.divider,

      toolbarHeight: toolbarHeight,

      // Quan trọng:
      // Không để AppBar tự bố trí leading/actions nữa.
      automaticallyImplyLeading: false,
      leading: null,
      actions: null,

      // Title của AppBar lúc này chiếm toàn bộ toolbar.
      centerTitle: false,
      titleSpacing: 0,

      title: SizedBox(
        width: double.infinity,
        height: toolbarHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // =================================================
            // TITLE
            // =================================================
            //
            // Positioned.fill giúp title lấy tâm của TOÀN BỘ
            // toolbar, không phải tâm khoảng trống còn lại.
            //
            // Padding hai bên bằng cùng sideReserve để title
            // không đè lên back/action.
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: sideReserve,
                ),
                child: Center(
                  child: Semantics(
                    header: true,
                    label: title,
                    excludeSemantics: true,
                    child:
                    VnuHorizontalReadableValue(
                      text: title,
                      textAlign: TextAlign.center,
                      centerWhenFits: true,
                      style:
                      TextStyles.bold.copyWith(
                        fontSize:
                        AppFontSizes.large,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // =================================================
            // LEFT
            // =================================================
            if (effectiveLeading != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: sideReserve,
                child: Align(
                  alignment:
                  Alignment.centerLeft,
                  child: effectiveLeading,
                ),
              ),

            // =================================================
            // RIGHT
            // =================================================
            if (effectiveActions.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: sideReserve,
                child: Align(
                  alignment:
                  Alignment.centerRight,
                  child: Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    mainAxisAlignment:
                    MainAxisAlignment.end,
                    children:
                    effectiveActions,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}