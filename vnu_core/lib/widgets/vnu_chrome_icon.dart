import 'package:flutter/material.dart';

/// Asset-first icons in the existing ONEVNU Flutter package.
/// Sources live in docs/chrome_icons_svg and do not replace quick_access icons.
class VnuChromeIcon extends StatelessWidget {
  const VnuChromeIcon({super.key, required this.name, this.size = 28,
    this.semanticLabel, this.fallback = Icons.circle_outlined});
  final String name;
  final double size;
  final String? semanticLabel;
  final IconData fallback;

  static String forProfile(String label) {
    switch (label) {
      case 'Thông tin cá nhân': return 'personal';
      case 'Thông tin gia đình': return 'family';
      case 'Đổi ảnh đại diện': return 'avatar';
      case 'Liên kết đánh dấu': return 'bookmark';
      case 'Cài đặt sinh trắc học': return 'biometric';
      case 'Quản lý mật khẩu': return 'password';
      case 'Đăng xuất': return 'logout';
      default: return label.startsWith('Phiên bản:') ? 'version' : 'personal';
    }
  }

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/icons/app_chrome/$name.png', package: 'vnu_core',
    width: size, height: size, fit: BoxFit.contain,
    filterQuality: FilterQuality.medium, semanticLabel: semanticLabel,
    errorBuilder: (_, __, ___) => Icon(fallback, size: size),
  );
}
