import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/space_widget.dart';
import 'package:vnu_core/common/utils.dart';

/// Enum định nghĩa các category tin tức
enum NewsCategory {
  all,
  newsVNU,
  newsSchool,
}

extension NewsCategoryExtension on NewsCategory {
  String get title {
    switch (this) {
      case NewsCategory.all:
        return 'Tất cả';
      case NewsCategory.newsVNU:
        return 'Tin VNU';
      case NewsCategory.newsSchool:
        return 'Tin Trường';
    }
  }

  String get icon {
    switch (this) {
      case NewsCategory.all:
        return 'assets/images/ic_tabbar_news.svg';
      case NewsCategory.newsVNU:
        return 'assets/images/vnu_logo.svg';
      case NewsCategory.newsSchool:
        return 'assets/images/ic_tabbar_news.svg';
    }
  }
}

class VcoreNewsCategoryWidgetV2 extends StatefulWidget {
  final NewsCategory selectedCategory;
  final Function(NewsCategory) onCategorySelected;

  const VcoreNewsCategoryWidgetV2({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<VcoreNewsCategoryWidgetV2> createState() =>
      _VcoreNewsCategoryWidgetV2State();
}

class _VcoreNewsCategoryWidgetV2State extends State<VcoreNewsCategoryWidgetV2>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  final List<NewsCategory> _categories = NewsCategory.values;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Single row categories
          SizedBox(
            height: 56,
            child: Row(
              children: [
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => spaceWidth(8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _buildCategoryItem(
                        category: category,
                        isSelected: widget.selectedCategory == category,
                        onTap: () => widget.onCategorySelected(category),
                      );
                    },
                  ),
                ),
                // More/Less button
                _buildMoreButton(),
              ],
            ),
          ),
          // Expanded content (3 rows)
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildExpandedContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required NewsCategory category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color bgColor =
        isSelected ? const Color(0xff003392) : const Color(0xffF0F4FA);
    final Color textColor = isSelected ? Colors.white : const Color(0xff637392);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border:
              isSelected ? null : Border.all(color: const Color(0xffDDE3EE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: svgAsset(
                category.icon,
                color: textColor,
              ),
            ),
            spaceWidth(6),
            Text(
              category.title,
              style: TextStyles.medium.copyWith(
                fontSize: AppFontSizes.mediumSmall,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreButton() {
    return GestureDetector(
      onTap: _toggleExpand,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: const Color(0xffF0F4FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 300),
          child: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xff637392),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          const Divider(color: Color(0xffDDE3EE), height: 1),
          spaceHeight(12),
          // Info text
          Text(
            'Bạn có thể chọn loại tin tức muốn xem',
            style: TextStyles.regular.copyWith(
              fontSize: AppFontSizes.small,
              color: const Color(0xff879ABF),
            ),
          ),
        ],
      ),
    );
  }
}
