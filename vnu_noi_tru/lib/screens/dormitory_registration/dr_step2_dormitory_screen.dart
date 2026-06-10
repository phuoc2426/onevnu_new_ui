import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_noi_tru/cubit/dormitory_registration_cubit.dart';
import 'package:vnu_noi_tru/models/model.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_noi_tru/widgets/nt_custom_dropdown.dart';

class DRStep2DormitoryScreen extends StatefulWidget {
  const DRStep2DormitoryScreen({super.key});

  @override
  State<DRStep2DormitoryScreen> createState() => _DRStep2DormitoryScreenState();
}

class _DRStep2DormitoryScreenState extends State<DRStep2DormitoryScreen> {
  String _selectedTab = 'Tất cả';

  String _formatMoney(dynamic value) {
    if (value == null) return '0';
    double? parsed;
    if (value is num) {
      parsed = value.toDouble();
    } else if (value is String) {
      parsed = double.tryParse(value);
    }
    return NumberFormat('#,##0', 'vi_VN').format(parsed ?? 0.0);
  }

  String _shortDormName(String name) {
    if (name.contains('Mễ Trì')) return 'Mễ Trì';
    if (name.contains('Khu A')) return 'Khu A';
    if (name.contains('Khu B')) return 'Khu B';
    if (name.contains('Mỹ Đình')) return 'Mỹ Đình';
    return '';
  }

  String _dormMark(String name) {
    if (name.contains('Mễ Trì')) return 'MỄ TRÌ';
    if (name.contains('Khu A')) return 'KHU A';
    if (name.contains('Khu B')) return 'KHU B';
    if (name.contains('Mỹ Đình')) return 'MỸ ĐÌNH';
    return 'KTX';
  }

  List<DormitoryModel> get _filteredDormitories {
    final cubit = context.read<DormitoryRegistrationCubit>();
    final list = cubit.dormitories;
    if (_selectedTab == 'Tất cả') return list;
    return list.where((d) => (d.name ?? '').contains(_selectedTab)).toList();
  }

  List<RoomTypeModel> get _filteredRoomTypes {
    final cubit = context.read<DormitoryRegistrationCubit>();
    final list = cubit.roomTypes;
    final student = Globals().thongTinSinhVienModel.value;
    if (student == null) return list;
    final targetGender = student.gioiTinh?.toLowerCase() == 'nữ'
        ? 'female'
        : 'male';
    return list
        .where(
          (element) => element.gender == null || element.gender == targetGender,
        )
        .toList();
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
                // Card: Room Type selection
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
                              Icons.meeting_room_outlined,
                              color: Color(0xFF078B3E),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Loại phòng',
                              style: TextStyle(
                                fontSize: AppFontSizes.small,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111318),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Room Grid
                        _buildRoomGrid(cubit),
                      ],
                    ),
                  ),
                ),
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
                        const SizedBox(height: 14),
                        // Custom Dropdown selection field
                        NtCustomDropdown<PriorityObjectModel>(
                          label: 'Đối tượng ưu tiên',
                          hintText: 'Chọn nếu có',
                          value: cubit.selectedPriorityObject,
                          items: cubit.priorityObjects,
                          itemAsString: (item) => item.name ?? '',
                          itemAsSubtitle: (item) => item.description ?? '',
                          clearable: true,
                          clearableText: 'Không có đối tượng ưu tiên',
                          onChanged: (value) {
                            setState(() {
                              cubit.selectedPriorityObject = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
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
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('Không có dữ liệu', style: TextStyle(color: Colors.grey)),
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
                _buildDormImage(d.name ?? ''),
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

  Widget _buildRoomGrid(DormitoryRegistrationCubit cubit) {
    final list = _filteredRoomTypes;

    if (list.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'Không có phòng phù hợp',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (cubit.selectedRoomType == null && list.isNotEmpty) {
      cubit.selectedRoomType = list.first;
    }

    return Column(
      children: list.map((r) {
        final isSelected = cubit.selectedRoomType?.id == r.id;
        final genderText = r.gender == 'female'
            ? 'Nữ'
            : r.gender == 'male'
            ? 'Nam'
            : 'Nam/Nữ';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              setState(() {
                cubit.selectedRoomType = r;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEAF8EF) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF078B3E)
                      : const Color(0xFFE3E6EB),
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRoomIcon(r.capacity ?? 0, r.gender ?? 'both'),
                  const SizedBox(width: 12),

                  // Quan trọng: Expanded để text không tràn ngang
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name ?? 'Loại phòng',
                          style: const TextStyle(
                            fontSize: AppFontSizes.font11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111318),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Quan trọng: Wrap để thông tin tự xuống dòng
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _roomInfoChip(Icons.wc_outlined, genderText),
                            _roomInfoChip(
                              Icons.people_alt_outlined,
                              'Sức chứa: ${r.capacity ?? 0} người',
                            ),
                            _roomInfoChip(
                              Icons.payments_outlined,
                              '${_formatMoney(r.price)}đ',
                              isPrice: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected
                        ? const Color(0xFF078B3E)
                        : const Color(0xFF9AA0A8),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _roomInfoChip(IconData icon, String text, {bool isPrice = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isPrice ? const Color(0xFFEAF8EF) : const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isPrice ? const Color(0xFF078B3E) : const Color(0xFF666B75),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isPrice
                  ? const Color(0xFF078B3E)
                  : const Color(0xFF444A54),
              fontWeight: isPrice ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDormImage(String dormName) {
    String assetPath = '';
    final nameLower = dormName.toLowerCase();
    if (nameLower.contains('ngoại ngữ') || nameLower.contains('ngoaingu')) {
      assetPath = 'assets/images/ktxngoaingu.png';
    } else if (nameLower.contains('hòa lạc') || nameLower.contains('hoalac')) {
      assetPath = 'assets/images/ktxhoalac.png';
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

  Widget _buildRoomIcon(int capacity, String gender) {
    String assetPath = '';
    final isFemale = gender.toLowerCase() == 'female';
    final isMale = gender.toLowerCase() == 'male';

    if (capacity == 4) {
      if (isMale) {
        assetPath = 'assets/images/icon_nam_4.png';
      } else if (isFemale) {
        assetPath = 'assets/images/iconnu_4.png';
      }
    } else if (capacity == 6 || capacity == 8) {
      if (isMale) {
        assetPath = 'assets/images/iconnam_8.png';
      } else if (isFemale) {
        assetPath = 'assets/images/iconnu_8.png';
      }
    }

    if (assetPath.isEmpty) {
      return Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Color(0xFFEAF8EF),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.grid_view_outlined,
          color: Color(0xFF078B3E),
          size: 18,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(19),
      child: Image.asset(
        assetPath,
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        errorBuilder: (context, err, stack) {
          return Image.asset(
            'packages/vnu_noi_tru/$assetPath',
            width: 38,
            height: 38,
            fit: BoxFit.cover,
            errorBuilder: (context, err2, stack2) {
              return Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF8EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.grid_view_outlined,
                  color: Color(0xFF078B3E),
                  size: 18,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
