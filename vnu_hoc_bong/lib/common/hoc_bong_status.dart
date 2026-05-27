import 'package:flutter/material.dart';

class HocBongStatusText {
  static String scholarship(String? value) {
    if (value == 'HoatDong' || value == 'Hoạt động' || value == 'ACTIVE') {
      return '';
    }
    switch (value) {
      case 'DRAFT':
        return 'Bản nháp';
      case 'PUBLISHED':
        return 'Đã công bố';
      case 'OPEN':
        return 'Đang mở đăng ký';
      case 'CLOSED':
        return 'Đã đóng đăng ký';
      case 'REVIEWING':
        return 'Đang xét duyệt';
      case 'RESULT_PUBLISHED':
        return 'Đã công bố kết quả';
      case 'COMPLETED':
        return 'Đã hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return value ?? 'Không xác định';
    }
  }

  static String application(String? value) {
    if (value == 'HoatDong' || value == 'Hoạt động' || value == 'ACTIVE') {
      return '';
    }
    switch (value) {
      case 'DRAFT':
        return 'Bản nháp';
      case 'SUBMITTED':
        return 'Đã gửi hồ sơ';
      case 'AUTO_CHECKED':
        return 'Đã kiểm tra tự động';
      case 'REVIEWING':
        return 'Đang xét duyệt';
      case 'NEED_MORE_INFO':
        return 'Cần bổ sung';
      case 'APPROVED':
        return 'Đã duyệt';
      case 'REJECTED':
        return 'Từ chối';
      case 'AWARDED':
        return 'Đã cấp học bổng';
      case 'WITHDRAWN':
        return 'Đã thu hồi';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return value ?? 'Không xác định';
    }
  }

  static String validate(String? value) {
    switch (value) {
      case 'PASS':
        return 'Đạt điều kiện';
      case 'FAIL':
        return 'Không đạt điều kiện';
      case 'NEED_MANUAL_REVIEW':
        return 'Cần kiểm tra thủ công';
      case 'WARNING':
        return 'Cần kiểm tra thêm';
      default:
        return value ?? 'Chưa kiểm tra';
    }
  }

  static String fileCheck(String? value) {
    switch (value) {
      case 'CHUA_KIEM_TRA':
        return 'Chưa kiểm tra';
      case 'HOP_LE':
        return 'Hợp lệ';
      case 'KHONG_HOP_LE':
        return 'Không hợp lệ';
      default:
        return value ?? 'Chưa kiểm tra';
    }
  }

  static Color color(String? value) {
    switch (value) {
      case 'OPEN':
      case 'PASS':
      case 'APPROVED':
      case 'AWARDED':
      case 'HOP_LE':
        return const Color(0xFF2F9E44);
      case 'DRAFT':
      case 'SUBMITTED':
      case 'AUTO_CHECKED':
      case 'REVIEWING':
      case 'NEED_MANUAL_REVIEW':
      case 'NEED_MORE_INFO':
      case 'CHUA_KIEM_TRA':
        return const Color(0xFFF59F00);
      case 'FAIL':
      case 'REJECTED':
      case 'WITHDRAWN':
      case 'CANCELLED':
      case 'KHONG_HOP_LE':
        return const Color(0xFFE03131);
      default:
        return const Color(0xFF667085);
    }
  }
}
