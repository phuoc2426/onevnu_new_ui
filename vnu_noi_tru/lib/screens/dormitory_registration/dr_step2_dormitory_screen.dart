import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/field/vnu_date_picker_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_noi_tru/cubit/dormitory_registration_cubit.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'package:vnu_core/common/app_text_styles.dart';

class DRStep2DormitoryScreen extends StatefulWidget {
  const DRStep2DormitoryScreen({super.key});

  @override
  State<DRStep2DormitoryScreen> createState() => _DRStep2DormitoryScreenState();
}

class _DRStep2DormitoryScreenState extends State<DRStep2DormitoryScreen> {
  String _selectedTab = 'Tất cả';

  String _shortDormName(String name) {
    final String normalized = name.toLowerCase();
    if (normalized.contains('qg-hn04') || normalized.contains('qghn04')) {
      return 'QG-HN04';
    }
    if (normalized.contains('ngoại ngữ') || normalized.contains('ngoaingu')) {
      return 'Ngoại ngữ';
    }
    if (normalized.contains('hòa lạc') || normalized.contains('hoalac')) {
      return 'Hòa Lạc';
    }
    if (normalized.contains('mễ trì') || normalized.contains('metri')) {
      return 'Mễ Trì';
    }
    if (name.contains('Khu A')) return 'Khu A';
    if (name.contains('Khu B')) return 'Khu B';
    if (normalized.contains('mỹ đình') || normalized.contains('mydinh')) {
      return 'Mỹ Đình';
    }
    return '';
  }

  String _dormMark(String name) {
    final String normalized = name.toLowerCase();
    if (normalized.contains('qg-hn04') || normalized.contains('qghn04')) {
      return 'QG-HN04';
    }
    if (normalized.contains('ngoại ngữ') || normalized.contains('ngoaingu')) {
      return 'NGOẠI NGỮ';
    }
    if (normalized.contains('hòa lạc') || normalized.contains('hoalac')) {
      return 'HÒA LẠC';
    }
    if (normalized.contains('mễ trì') || normalized.contains('metri')) {
      return 'MỄ TRÌ';
    }
    if (name.contains('Khu A')) return 'KHU A';
    if (name.contains('Khu B')) return 'KHU B';
    if (normalized.contains('mỹ đình') || normalized.contains('mydinh')) {
      return 'MỸ ĐÌNH';
    }
    return 'KTX';
  }

  List<DormitoryModel> get _filteredDormitories {
    final cubit = context.read<DormitoryRegistrationCubit>();
    final list = cubit.dormitories;
    if (_selectedTab == 'Tất cả') return list;
    return list.where((d) => (d.name ?? '').contains(_selectedTab)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DormitoryRegistrationCubit>();
    final isLoading = cubit.state is DormitoryRegistrationLoading;

    return isLoading && cubit.dormitories.isEmpty
        ? const Center(
      child: CircularProgressIndicator(color: AppTheme.colorMain),
    )
        : SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card: Dormitory selection
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE3E6EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.business,
                        color: Color(0xFF078B3E),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Ký túc xá',
                        style: TextStyle(
                          fontSize: AppFontSizes.small,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111318),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tabs scroll bar
                  _buildTabs(),
                  const SizedBox(height: 16),
                  // Dormitories Grid
                  _buildDormGrid(cubit),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Loại phòng được hệ thống/KTX bố trí tự động.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBEAD6)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF078B3E),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Loại phòng sẽ do ký túc xá bố trí tự động. '
                        'Sinh viên không cần lựa chọn loại phòng khi đăng ký.',
                    style: TextStyle(
                      fontSize: AppFontSizes.small,
                      color: Color(0xFF1C2D22),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildStayPeriodCard(cubit),
          const SizedBox(height: 16),
          // Card: Priority Object
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE3E6EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        color: Color(0xFF078B3E),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Đối tượng ưu tiên',
                        style: TextStyle(
                          fontSize: AppFontSizes.small,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111318),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Có thể chọn một hoặc nhiều đối tượng phù hợp. '
                    'Bỏ chọn toàn bộ nếu không thuộc diện ưu tiên.',
                    style: TextStyle(
                      fontSize: AppFontSizes.extraSmall,
                      color: Color(0xFF666B75),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildPriorityObjectSelector(cubit),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStayPeriodCard(DormitoryRegistrationCubit cubit,) {
    final bool isCustom = cubit.selectedTermType == 5;
    final String? validationError =
    isCustom ? cubit.validateStayPeriod() : null;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE3E6EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(
                  Icons.date_range_rounded,
                  color: Color(0xFF078B3E),
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thời gian ở ký túc xá',
                    style: TextStyle(
                      fontSize: AppFontSizes.small,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111318),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Chọn kỳ ở dự kiến. Với Kỳ 1, Kỳ 2, Hè và Giữa kỳ, '
                  'hệ thống sẽ tự tính ngày bắt đầu và ngày kết thúc.',
              style: TextStyle(
                fontSize: AppFontSizes.extraSmall,
                color: Color(0xFF666B75),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _buildTermChip(cubit, 1, 'Kỳ 1'),
                _buildTermChip(cubit, 2, 'Kỳ 2'),
                _buildTermChip(cubit, 3, 'Hè'),
                _buildTermChip(cubit, 4, 'Giữa kỳ'),
                _buildTermChip(cubit, 5, 'Khác'),
              ],
            ),
            if (isCustom) ...<Widget>[
              const SizedBox(height: 16),
              _buildDateField(
                label: 'Ngày bắt đầu',
                value: cubit.customStartDate,
                icon: Icons.login_rounded,
                onTap: () => _pickStartDate(cubit),
              ),
              const SizedBox(height: 12),
              _buildDateField(
                label: 'Ngày kết thúc',
                value: cubit.customEndDate,
                icon: Icons.logout_rounded,
                onTap: () => _pickEndDate(cubit),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ngày bắt đầu phải sau ngày hiện tại; '
                    'ngày kết thúc phải sau ngày bắt đầu.',
                style: TextStyle(
                  fontSize: AppFontSizes.extraSmall,
                  color: Color(0xFF666B75),
                  height: 1.35,
                ),
              ),
              if (validationError != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  validationError,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: AppFontSizes.extraSmall,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTermChip(DormitoryRegistrationCubit cubit,
      int value,
      String label,) {
    final bool selected = cubit.selectedTermType == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFFEAF8EF),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected
            ? const Color(0xFF078B3E)
            : const Color(0xFFE3E6EB),
      ),
      labelStyle: TextStyle(
        color: selected
            ? const Color(0xFF078B3E)
            : const Color(0xFF41454C),
        fontWeight: selected
            ? FontWeight.w800
            : FontWeight.w500,
        fontSize: AppFontSizes.small,
      ),
      onSelected: (bool enabled) {
        if (!enabled) return;

        setState(() {
          cubit.selectTermType(value);
        });
      },
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFDDE3EA),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: 19,
              color: const Color(0xFF078B3E),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: AppFontSizes.extraSmall,
                      color: Color(0xFF666B75),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value == null
                        ? 'Chọn ngày'
                        : DateFormat('dd/MM/yyyy').format(value),
                    style: TextStyle(
                      fontSize: AppFontSizes.small,
                      fontWeight: FontWeight.w700,
                      color: value == null
                          ? const Color(0xFF8B919A)
                          : const Color(0xFF111318),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF078B3E),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate(DormitoryRegistrationCubit cubit,) async {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime firstDate = today.add(const Duration(days: 1));
    final DateTime initialDate =
    cubit.customStartDate != null &&
        cubit.customStartDate!.isAfter(today)
        ? cubit.customStartDate!
        : firstDate;

    final DateTime? selected = await VnuDatePickerSheet.show(
      context: context,
      title: 'Ngày bắt đầu ở',
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 5, 12, 31),
    );

    if (selected == null || !mounted) return;

    setState(() {
      cubit.setCustomStartDate(selected);
    });
  }

  Future<void> _pickEndDate(DormitoryRegistrationCubit cubit,) async {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime start =
        cubit.customStartDate ?? today.add(const Duration(days: 1));
    final DateTime firstDate = start.add(const Duration(days: 1));
    final DateTime initialDate =
    cubit.customEndDate != null &&
        cubit.customEndDate!.isAfter(start)
        ? cubit.customEndDate!
        : firstDate;

    final DateTime? selected = await VnuDatePickerSheet.show(
      context: context,
      title: 'Ngày kết thúc ở',
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 6, 12, 31),
    );

    if (selected == null || !mounted) return;

    setState(() {
      cubit.setCustomEndDate(selected);
    });
  }

  Widget _buildPriorityObjectSelector(
    DormitoryRegistrationCubit cubit,
  ) {
    if (cubit.priorityObjects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3E6EB)),
        ),
        child: const Text(
          'Chưa có dữ liệu đối tượng ưu tiên.',
          style: TextStyle(
            fontSize: AppFontSizes.small,
            color: Color(0xFF666B75),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (cubit.selectedPriorityObjects.isNotEmpty) ...<Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBEAD6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Đã chọn',
                  style: TextStyle(
                    fontSize: AppFontSizes.extraSmall,
                    color: Color(0xFF47614F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: cubit.selectedPriorityObjects
                      .map(
                        (PriorityObjectModel item) => InputChip(
                          label: Text(item.name ?? 'Đối tượng ưu tiên'),
                          onDeleted: () {
                            setState(() {
                              cubit.togglePriorityObject(item);
                            });
                          },
                          deleteIcon: const Icon(Icons.close_rounded, size: 17),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFB9DDC5)),
                          labelStyle: const TextStyle(
                            color: Color(0xFF078B3E),
                            fontWeight: FontWeight.w600,
                            fontSize: AppFontSizes.extraSmall,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        ...cubit.priorityObjects.map((PriorityObjectModel item) {
          final bool selected = cubit.isPriorityObjectSelected(item);
          final String itemKey =
              (item.id ?? item.name ?? item.hashCode).toString();

          return AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (
                Widget child,
                Animation<double> animation,
              ) {
                final Animation<Offset> slideAnimation =
                    Tween<Offset>(
                  begin: const Offset(-0.14, 0),
                  end: Offset.zero,
                ).animate(animation);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: child,
                  ),
                );
              },
              child: selected
                  ? SizedBox.shrink(
                      key: ValueKey<String>('selected-$itemKey'),
                    )
                  : Padding(
                      key: ValueKey<String>('available-$itemKey'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            cubit.togglePriorityObject(item);
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE3E6EB),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Checkbox(
                                value: false,
                                activeColor: const Color(0xFF078B3E),
                                visualDensity: VisualDensity.compact,
                                onChanged: (_) {
                                  setState(() {
                                    cubit.togglePriorityObject(item);
                                  });
                                },
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      item.name ?? 'Đối tượng ưu tiên',
                                      style: const TextStyle(
                                        fontSize: AppFontSizes.small,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111318),
                                      ),
                                    ),
                                    if ((item.description ?? '')
                                        .trim()
                                        .isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description!.trim(),
                                        style: const TextStyle(
                                          fontSize: AppFontSizes.extraSmall,
                                          color: Color(0xFF666B75),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTabs() {
    final cubit = context.read<DormitoryRegistrationCubit>();
    final List<String> tabs = ['Tất cả'];
    for (var d in cubit.dormitories) {
      final name = _shortDormName(d.name ?? '');
      if (name.isNotEmpty && !tabs.contains(name)) {
        tabs.add(name);
      }
    }

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final t = tabs[index];
          final isActive = _selectedTab == t;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(
                t,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF078B3E)
                      : const Color(0xFF41454C),
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.normal,
                  fontSize: AppFontSizes.small,
                ),
              ),
              selected: isActive,
              selectedColor: const Color(0xFFEAF8EF),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isActive
                      ? Colors.transparent
                      : const Color(0xFFE3E6EB),
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTab = t;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDormGrid(DormitoryRegistrationCubit cubit) {
    final list = _filteredDormitories;
    if (list.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              cubit.dormitoryFilterMessage ?? 'Không có ký túc xá phù hợp',
              style: const TextStyle(
                color: Colors.grey,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (cubit.selectedDormitory == null && list.isNotEmpty) {
      cubit.selectedDormitory = list.first;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 11,
        mainAxisSpacing: 11,
        mainAxisExtent: 185,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final d = list[index];
        final isSelected = cubit.selectedDormitory?.id == d.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              cubit.selectedDormitory = d;
              cubit.selectedPeriod = null;
              cubit.periods = [];
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF078B3E)
                    : const Color(0xFFE3E6EB),
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildDormImage(d),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    d.name ?? 'Ký túc xá',
                    style: const TextStyle(
                      fontSize: AppFontSizes.small,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111318),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  d.address ?? '',
                  style: const TextStyle(
                    fontSize: AppFontSizes.extraSmall,
                    color: Color(0xFF666B75),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Radio indicator
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF078B3E)
                          : const Color(0xFF9AA0A8),
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF078B3E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDormImage(DormitoryModel dormitory) {
    final String dormName = dormitory.name ?? '';
    String assetPath = '';
    final String nameLower = dormName.toLowerCase();

    // QG-HN04 ưu tiên ảnh local riêng, không dùng ảnh Hòa Lạc chung từ API.
    if (dormitory.id == 4 ||
        nameLower.contains('qg-hn04') ||
        nameLower.contains('qghn04') ||
        nameLower.contains('qg hn04')) {
      assetPath = 'assets/images/ktxqghn04.png';
    } else if (nameLower.contains('ngoại ngữ') ||
        nameLower.contains('ngoaingu')) {
      assetPath = 'assets/images/ktxngoaingu.png';
    } else if (nameLower.contains('hòa lạc') ||
        nameLower.contains('hoalac')) {
      assetPath = 'assets/images/ktxhoalac.png';
    } else if (nameLower.contains('mễ trì') ||
        nameLower.contains('metri') ||
        nameLower.contains('me tri')) {
      assetPath = 'assets/images/ktxmetri.png';
    }

    if (assetPath.isEmpty) {
      return Container(
        width: double.infinity,
        height: 76,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDFF4FF), Color(0xFFF7FBFF)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            _dormMark(dormName),
            style: const TextStyle(
              color: Color(0xFF5590B0),
              fontWeight: FontWeight.w800,
              fontSize: AppFontSizes.medium,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        assetPath,
        width: double.infinity,
        height: 76,
        fit: BoxFit.cover,
        errorBuilder: (context, err, stack) {
          return Image.asset(
            'packages/vnu_noi_tru/$assetPath',
            width: double.infinity,
            height: 76,
            fit: BoxFit.cover,
            errorBuilder: (context, err2, stack2) {
              return Container(
                width: double.infinity,
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDFF4FF), Color(0xFFF7FBFF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _dormMark(dormName),
                    style: const TextStyle(
                      color: Color(0xFF5590B0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }


}

