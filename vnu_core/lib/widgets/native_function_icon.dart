import 'package:flutter/material.dart';

/// Hand-made ONEVNU image asset set. The background tile remains a Flutter
/// decoration, so icons can be rescaled without blurring their pastel cards.
class NativeFunctionIcon extends StatelessWidget {
  const NativeFunctionIcon({super.key, required this.label, this.size = 30});
  final String label;
  final double size;

  static const Map<String, String> _assetNames = <String, String>{
    'Lịch học & thi': 'calendar',
    'Điểm': 'grades',
    'Đăng ký môn': 'course_registration',
    'Việc làm': 'jobs',
    'Đồng bộ': 'sync',
    'Học phí': 'tuition',
    'Thanh toán học phí': 'tuition',
    'Tài liệu': 'documents',
    'Điểm danh': 'attendance',
    'Học bổng': 'scholarship',
    'Phản ánh': 'feedback',
    'Phản ánh, góp ý': 'feedback',
    'Nội trú': 'dormitory',
    'Cập nhật tạm trú': 'location',
    'Phòng trọ': 'housing',
    'Thủ tục': 'one_door',
    'Thư viện': 'library',
    'Bản đồ': 'map',
    'Hỏi đáp': 'qa',
    'Cẩm nang': 'handbook',
    'Đăng ký phương tiện': 'globe',
  };

  @override
  Widget build(BuildContext context) {
    final icon = _assetNames[label] ?? 'globe';
    return Image.asset('assets/icons/quick_access/$icon.png',
      package: 'vnu_core', width: size, height: size,
      filterQuality: FilterQuality.medium,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

