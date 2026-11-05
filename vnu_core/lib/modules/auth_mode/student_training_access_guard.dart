import 'package:dio/dio.dart';

/// An existing ONEVNU JWT does NOT imply an enrollment record.
/// Only an authoritative 404 from /api/sinhvien proves no training record.
class StudentTrainingAccessGuard {
  const StudentTrainingAccessGuard._();

  static const noTrainingRecord =
      'Tài khoản đã xác thực nhưng không có dữ liệu đào tạo của sinh viên. '
      'Bạn chưa thể truy cập chế độ sinh viên. '
      'Vui lòng sử dụng mục Đăng nhập khác hoặc liên hệ đơn vị đào tạo.';
  static const notLoaded =
      'Chưa tải được dữ liệu đào tạo. Vui lòng kiểm tra kết nối rồi thử lại. '
      'Không thể kết luận tài khoản không có hồ sơ sinh viên.';

  static bool isAuthoritativeMissing(Object error) =>
      error is DioException && error.response?.statusCode == 404;

  static String describe(Object error) =>
      isAuthoritativeMissing(error) ? noTrainingRecord : notLoaded;
}
