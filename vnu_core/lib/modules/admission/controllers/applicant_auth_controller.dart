import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:dio/dio.dart'; // Added for DioError handling
import 'package:vnu_core/modules/admission/views/applicant_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../globals.dart';
import '../../../repository/data_repository.dart';

class ApplicantAuthController extends GetxController {
  BuildContext? context;

  final cccdController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;

  // Domain sẽ được truyền từ bên ngoài nếu cần, hoặc dùng mặc định
  String? domain;

  Future<void> register() async {
    final cccd = cccdController.text.trim();
    if (cccd.isEmpty) {
      Utils.showAlertDialog(
        context,
        "Lỗi",
        "Vui lòng nhập số CCCD",
        okStr: "Đóng",
        cancelStr: null,
        withoutBinding: true,
      );
      return;
    }

    isLoading.value = true;
    Utils.showProgress(context);
    try {
      // Gọi API đăng ký, API sẽ trả về lỗi nếu tài khoản đã tồn tại
      final response = await ApiRepository().applicantRegister(cccd);

      // Kiểm tra response để xác định trạng thái
      if (response.containsKey('error')) {
        // Trường hợp API trả về thông báo lỗi chi tiết
        final errorMsg = response['error'].toString();

        Utils.dismissProgress(context);
        Utils.showAlertDialog(
          context,
          "Lỗi",
          errorMsg,
          okStr: "Đóng",
          cancelStr: null,
          withoutBinding: true,
        );
        return;
      }

      // Nếu không có lỗi, lưu trạng thái đăng ký vào cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('applicant_cccd', cccd);
      await prefs.setBool('applicant_registered', true);

      Utils.dismissProgress(context);

      // Hiển thị dialog thành công thay vì snackbar
      Utils.showAlertDialog(
        context,
        "Thành công",
        "Mật khẩu đã được gửi đến email của bạn. Vui lòng kiểm tra thư mục spam nếu không thấy mail",
        okStr: "Đóng",
        cancelStr: null,
        withoutBinding: true,
        callBackOK: () {
          Get.back(); // quay lại màn hình login
        },
      );
    } on DioError catch (dioErr) {
      // Xử lý lỗi mạng / server trả về mã lỗi
      final errMsg = _extractErrorMessage(dioErr.response?.data);
      debugPrint('Register DioError: $errMsg');

      Utils.dismissProgress(context);
      Utils.showAlertDialog(
        context,
        "Lỗi",
        errMsg,
        okStr: "Đóng",
        cancelStr: null,
        withoutBinding: true,
      );
    } catch (e) {
      // Các lỗi không phải DioError
      debugPrint('Register error: $e');
      Utils.dismissProgress(context);
      Utils.showAlertDialog(
        context,
        "Lỗi",
        e.toString(),
        okStr: "Đóng",
        cancelStr: null,
        withoutBinding: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic> && data['error'] != null) {
      return data['error'].toString();
    }

    return 'Lỗi không xác định';
  }

  Future<void> login() async {
    final cccd = cccdController.text.trim();
    final password = passwordController.text.trim();
    if (cccd.isEmpty || password.isEmpty) {
      snackBarError('Vui lòng nhập đầy đủ CCCD và mật khẩu');
      return;
    }

    isLoading.value = true;
    Utils.showProgress(context);
    try {
      final response = await ApiRepository().applicantLogin(cccd, password);
      final token = response['accessToken'] as String?;
      final fullName = response['fullName'] as String? ?? 'Sinh viên';
      final email = response['email'] as String? ?? '';
      // final cccdServer = response['cccd'] as String? ?? cccd; // nếu cần xác nhận
      if (token == null) throw Exception('Token không tồn tại');

      // Lưu token vào SharedPreferences để các màn hình UI có thể truy cập nhanh
      // Lưu token và thông tin thí sinh vào SharedPreferences với key riêng
      // để không bị nhầm lẫn với token sinh viên.
      final prefs = await SharedPreferences.getInstance();
      const applicantTokenKey = 'applicant_access_token';
      await prefs.setString(applicantTokenKey, token);
      await prefs.setString('applicant_cccd', cccd); // từ ô nhập
      await prefs.setString('applicant_email', email);
      await prefs.setString('applicant_fullname', fullName);

      // Đồng thời lưu token vào cơ chế cache chung của app (DataRepository + Globals)
      // để splash screen và các request HTTP có thể tự động lấy token giống như sinh viên.
      Globals().token = token;
      // Sử dụng key chung kLoginToken để tương thích với splash screen
      DataRepository().saveSecureKey(kLoginToken, token);
      // Cập nhật Dio instance với token mới để các request tiếp theo (đổi mật khẩu, ...) có token trong header
      ApiRepository().setToken(token);
      Utils.dismissProgress(context);
      Get.off(() => ApplicantHomeScreen(fullName: fullName));
    } catch (e) {
      // Ghi log lỗi để dễ dàng truy vết
      debugPrint('Login error: $e');
      Utils.dismissProgress(context);
      snackBarError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void dispose() {
    cccdController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
