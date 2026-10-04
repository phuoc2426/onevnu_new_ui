import 'dart:convert';

import 'package:vnu_core/common/error/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/widgets/vcore_action_dialog.dart';

import '../../../models/model.dart';

class VcoreProfilePersonInfoController extends GetxController {
  BuildContext? context;

  Rx<StudentInfoModel> sinhvienEdit = StudentInfoModel().obs;

  RxList<QuocGiaModel> listQuocGia = RxList([]);
  RxList<TinhThanhModel> listTinhThanhPho = RxList([]);
  RxList<DanTocModel> listDanToc = RxList([]);
  RxList<TonGiaoModel> listTonGiao = RxList([]);

  RxList<KhuVucUuTienModel> listKhuVucUuTien = RxList([]);

  // Quan Huyen
  RxList<QuanHuyenModel> listQuanHuyenQueQuan = RxList([]);
  RxList<QuanHuyenModel> listQuanHuyenNoiSinh = RxList([]);
  RxList<QuanHuyenModel> listQuanHuyenThuongTru = RxList([]);
  RxList<QuanHuyenModel> listQuanHuyenNoiOHienNay = RxList([]);
  RxList<QuanHuyenModel> listQuanHuyenDiaChiLL = RxList([]);
  RxList<QuanHuyenModel> listQuanHuyenDiaChiTamTru = RxList([]);
  bool configValueOk = false;

  /// CCCD mới chỉ được chấp nhận sau khi QR thẻ căn cước đã được quét và
  /// họ tên trên QR khớp với hồ sơ sinh viên hiện tại. Không lưu QR raw.
  final RxString verifiedQrCccd = ''.obs;
  final RxString verifiedQrFullName = ''.obs;
  final Rxn<DateTime> verifiedQrDob = Rxn<DateTime>();

  /// Bat mui ten noi khi form co bat ky thay doi nao chua luu.
  final RxBool hasUnsavedChanges = false.obs;
  final RxBool requireCccdVerificationForKtx = false.obs;
  final RxBool hasPendingQrVerification = false.obs;
  String _initialFormSnapshot = '';
  Worker? _dirtyWorker;

  void applyVerifiedCccdFromQr({
    required String cccd,
    required String fullName,
    required DateTime dateOfBirth,
  }) {
    final String normalized = cccd.trim();
    verifiedQrCccd.value = normalized;
    verifiedQrFullName.value = fullName.trim();
    verifiedQrDob.value = dateOfBirth;
    hasPendingQrVerification.value = true;
    hasUnsavedChanges.value = true;
    sinhvienEdit.update((StudentInfoModel? item) {
      item?.soCmtCccd = normalized;
    });
  }

  void clearCccdVerificationContext() {
    requireCccdVerificationForKtx.value = false;
    hasPendingQrVerification.value = false;
    verifiedQrCccd.value = '';
    verifiedQrFullName.value = '';
    verifiedQrDob.value = null;
  }

  bool get hasPendingVerifiedCccdChange {
    final String oldCccd =
        Globals().thongTinSinhVienModel.value?.soCmtCccd?.trim() ?? '';
    final String newCccd = sinhvienEdit.value.soCmtCccd?.trim() ?? '';
    return newCccd.isNotEmpty &&
        newCccd != oldCccd &&
        verifiedQrCccd.value == newCccd;
  }

  String _formSnapshot(StudentInfoModel value) => jsonEncode(value.toJson());

  void _recomputeDirtyState() {
    if (_initialFormSnapshot.isEmpty) {
      hasUnsavedChanges.value = false;
      return;
    }
    hasUnsavedChanges.value =
        _formSnapshot(sinhvienEdit.value) != _initialFormSnapshot ||
        hasPendingQrVerification.value;
  }

  @override
  void onInit() {
    super.onInit();

    getDataDropdown();

    if (Globals().thongTinSinhVienModel.value != null) {
      configValueOk = true;
      configWithSinhVienModel(Globals().thongTinSinhVienModel.value!);
      _prepareDirtyTracking();
    }
  }

  Future<void> _prepareDirtyTracking() async {
    // Hoan thanh cac buoc hydrate tu dong truoc khi chup snapshot ban dau de
    // mui ten khong tu bat chi vi controller dang nap du lieu nen.
    await refreshQuanHuyenDiaChiTamTru();
    _initialFormSnapshot = _formSnapshot(sinhvienEdit.value);
    hasUnsavedChanges.value = hasPendingQrVerification.value;
    _dirtyWorker?.dispose();
    _dirtyWorker = ever<StudentInfoModel>(
      sinhvienEdit,
      (StudentInfoModel _) => _recomputeDirtyState(),
    );
  }

  @override
  void onClose() {
    _dirtyWorker?.dispose();
    super.onClose();
  }

  configWithSinhVienModel(StudentInfoModel sinhvien) {
    //
    sinhvienEdit.value = StudentInfoModel(
      //email
      email: sinhvien.email,
      emailKhac: sinhvien.emailKhac,

      //Bacsic
      tenKhac: sinhvien.tenKhac,

      idQuocGia: sinhvien.idQuocGia,
      idDanToc: sinhvien.idDanToc,

      idTonGiao: sinhvien.idTonGiao,
      nhomMau: sinhvien.nhomMau,

      canNang: sinhvien.canNang,
      chieuCao: sinhvien.chieuCao,

      soCmtCccd: sinhvien.soCmtCccd,
      ngayCapCmtCccd: sinhvien.ngayCapCmtCccd,
      idNoiCapCmtCccdTinhThanhPho: sinhvien.idNoiCapCmtCccdTinhThanhPho,
      idDoiTuongUuTien: sinhvien.idDoiTuongUuTien,

      nangKhieu: sinhvien.nangKhieu,

      //Que quan
      idQueQuanQuocGia: sinhvien.idQueQuanQuocGia,
      idQueQuanTinhThanhPho: sinhvien.idQueQuanTinhThanhPho,
      idQueQuanQuanHuyen: sinhvien.idQueQuanQuanHuyen,
      queQuanPhuongXa: sinhvien.queQuanPhuongXa,

      // - Noi Sinh
      idNoiSinhQuocGia: sinhvien.idNoiSinhQuocGia,
      idNoiSinhQuanHuyen: sinhvien.idNoiSinhQuanHuyen,
      idNoiSinhTinhThanhPho: sinhvien.idNoiSinhTinhThanhPho,
      noiSinhPhuongXa: sinhvien.noiSinhPhuongXa,

      // - Ho khau thuong tru
      idHoKhauThuongTruTinhThanhPho: sinhvien.idHoKhauThuongTruTinhThanhPho,
      idHoKhauThuongTruQuanHuyen: sinhvien.idHoKhauThuongTruQuanHuyen,
      hoKhauThuongTruPhuongXa: sinhvien.hoKhauThuongTruPhuongXa,
      hoKhauThuongTruDuongThon: sinhvien.hoKhauThuongTruDuongThon,
      hoKhauThuongTruSoNha: sinhvien.hoKhauThuongTruSoNha,

      // - Noi o hien nay
      idNoiOHienNayQuocGia: sinhvien.idNoiOHienNayQuocGia,
      idNoiOHienNayTinhThanhPho: sinhvien.idNoiOHienNayTinhThanhPho,
      idNoiOHienNayQuanHuyen: sinhvien.idNoiOHienNayQuanHuyen,
      noiOHienNayPhuongXa: sinhvien.noiOHienNayPhuongXa,
      noiOHienNayDuongThon: sinhvien.noiOHienNayDuongThon,
      noiOHienNaySoNha: sinhvien.noiOHienNaySoNha,

      // - Dia chi lien lac
      idDiaChiLienLacQuocGia: sinhvien.idDiaChiLienLacQuocGia,
      idDiaChiLienLacTinhThanhPho: sinhvien.idDiaChiLienLacTinhThanhPho,
      idDiaChiLienLacQuanHuyen: sinhvien.idDiaChiLienLacQuanHuyen,
      diaChiLienLacPhuongXa: sinhvien.diaChiLienLacPhuongXa,
      diaChiLienLacDuongThon: sinhvien.diaChiLienLacDuongThon,
      diaChiLienLacSoNha: sinhvien.diaChiLienLacSoNha,

      //Phone
      mobile: sinhvien.mobile,
      tel: sinhvien.tel,

      // - Nhap Ngu
      isBoDoi: sinhvien.isBoDoi,
      nhapNgu: sinhvien.nhapNgu,
      xuatNgu: sinhvien.xuatNgu,

      // -- Thong tin doan
      isDoan: sinhvien.isDoan,
      noiVaoDoan: sinhvien.noiVaoDoan,
      ngayVaoDoan: sinhvien.ngayVaoDoan,
      viTriCaoNhatDoan: sinhvien.viTriCaoNhatDoan,

      // -- Thong tin dang
      isDang: sinhvien.isDang,
      ngayVaoDang: sinhvien.ngayVaoDang,
      ngayVaoDangChinhThuc: sinhvien.ngayVaoDangChinhThuc,
      noiVaoDang: sinhvien.noiVaoDang,
      viTriCaoNhatDang: sinhvien.viTriCaoNhatDang,

      // - Dia chi tam tru
      diaChiTamTru: sinhvien.diaChiTamTru,
      diaChiTamTruQuocGia: sinhvien.diaChiTamTruQuocGia,
      diaChiTamTruTinhThanhPho: sinhvien.diaChiTamTruTinhThanhPho,
      diaChiTamTruQuanHuyen: sinhvien.diaChiTamTruQuanHuyen,
      diaChiTamTruPhuongXa: sinhvien.diaChiTamTruPhuongXa,
      diaChiTamTruDuongThon: sinhvien.diaChiTamTruDuongThon,
      diaChiTamTruSoNha: sinhvien.diaChiTamTruSoNha,
    );
  }

  getDataDropdown() async {
    try {
      var response = await ApiRepository().getDataQuocGia(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
      );
      listQuocGia.value = response;
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getDataTinhThanhPho(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
      );
      listTinhThanhPho.value = response;
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getDataDanToc(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
      );
      listDanToc.value = response;
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getDataTonGiao(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
      );
      listTonGiao.value = response;
    } catch (e) {
      logError(e.toString());
    }

    try {
      var response = await ApiRepository().getDataKhuVucUuTien(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
      );
      listKhuVucUuTien.value = response;
    } catch (e) {
      logError(e.toString());
    }

    //Get quan huyen
    try {
      String? idTinhThanhPho =
          Globals().thongTinSinhVienModel.value?.idQueQuanTinhThanhPho;
      var response = await ApiRepository().getDataQuanHuyen(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        idTinhThanhPho,
      );
      listQuanHuyenQueQuan.value = response;
      if (idTinhThanhPho ==
          Globals().thongTinSinhVienModel.value?.idNoiSinhTinhThanhPho) {
        listQuanHuyenNoiSinh.value = response;
      }
      if (idTinhThanhPho ==
          Globals()
              .thongTinSinhVienModel
              .value
              ?.idHoKhauThuongTruTinhThanhPho) {
        listQuanHuyenThuongTru.value = response;
      }
      if (idTinhThanhPho ==
          Globals().thongTinSinhVienModel.value?.idNoiOHienNayTinhThanhPho) {
        listQuanHuyenNoiOHienNay.value = response;
      }
      if (idTinhThanhPho ==
          Globals().thongTinSinhVienModel.value?.idDiaChiLienLacTinhThanhPho) {
        listQuanHuyenDiaChiLL.value = response;
      }
    } catch (e) {
      logError(e.toString());
    }

    if (Globals().thongTinSinhVienModel.value?.idNoiSinhTinhThanhPho !=
        Globals().thongTinSinhVienModel.value?.idQueQuanTinhThanhPho) {
      try {
        String? idTinhThanhPho =
            Globals().thongTinSinhVienModel.value?.idNoiSinhTinhThanhPho;
        var response = await ApiRepository().getDataQuanHuyen(
          null,
          Globals().thongTinSinhVienModel.value?.guidDonVi,
          idTinhThanhPho,
        );
        listQuanHuyenNoiSinh.value = response;
      } catch (e) {
        logError(e.toString());
      }
    }

    if (Globals().thongTinSinhVienModel.value?.idHoKhauThuongTruTinhThanhPho !=
        Globals().thongTinSinhVienModel.value?.idQueQuanTinhThanhPho) {
      try {
        String? idTinhThanhPho = Globals()
            .thongTinSinhVienModel
            .value
            ?.idHoKhauThuongTruTinhThanhPho;
        var response = await ApiRepository().getDataQuanHuyen(
          null,
          Globals().thongTinSinhVienModel.value?.guidDonVi,
          idTinhThanhPho,
        );
        listQuanHuyenThuongTru.value = response;
      } catch (e) {
        logError(e.toString());
      }
    }
    if (Globals().thongTinSinhVienModel.value?.idNoiOHienNayTinhThanhPho !=
        Globals().thongTinSinhVienModel.value?.idQueQuanTinhThanhPho) {
      try {
        String? idTinhThanhPho =
            Globals().thongTinSinhVienModel.value?.idNoiOHienNayTinhThanhPho;
        var response = await ApiRepository().getDataQuanHuyen(
          null,
          Globals().thongTinSinhVienModel.value?.guidDonVi,
          idTinhThanhPho,
        );
        listQuanHuyenNoiOHienNay.value = response;
      } catch (e) {
        logError(e.toString());
      }
    }

    if (Globals().thongTinSinhVienModel.value?.idDiaChiLienLacTinhThanhPho !=
        Globals().thongTinSinhVienModel.value?.idQueQuanTinhThanhPho) {
      try {
        String? idTinhThanhPho =
            Globals().thongTinSinhVienModel.value?.idDiaChiLienLacTinhThanhPho;
        var response = await ApiRepository().getDataQuanHuyen(
          null,
          Globals().thongTinSinhVienModel.value?.guidDonVi,
          idTinhThanhPho,
        );
        listQuanHuyenDiaChiLL.value = response;
      } catch (e) {
        logError(e.toString());
      }
    }
  }

  refreshQuanHuyenQueQuan() async {
    listQuanHuyenQueQuan.value = [];
    try {
      String? idTinhThanhPho = sinhvienEdit.value.idQueQuanTinhThanhPho;
      var response = await ApiRepository().getDataQuanHuyen(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        idTinhThanhPho,
      );
      listQuanHuyenQueQuan.value = response;
    } catch (e) {
      logError(e.toString());
    }
  }

  refreshQuanHuyenNoiSinh() async {
    listQuanHuyenNoiSinh.value = [];
    try {
      String? idTinhThanhPho = sinhvienEdit.value.idNoiSinhTinhThanhPho;
      var response = await ApiRepository().getDataQuanHuyen(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        idTinhThanhPho,
      );
      listQuanHuyenNoiSinh.value = response;
    } catch (e) {
      logError(e.toString());
    }
  }

  refreshQuanHuyenHoKhauThuongTru() async {
    listQuanHuyenThuongTru.value = [];
    try {
      String? idTinhThanhPho = sinhvienEdit.value.idHoKhauThuongTruTinhThanhPho;
      var response = await ApiRepository().getDataQuanHuyen(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        idTinhThanhPho,
      );
      listQuanHuyenThuongTru.value = response;
    } catch (e) {
      logError(e.toString());
    }
  }

  refreshQuanHuyenNoiOHienNay() async {
    listQuanHuyenNoiOHienNay.value = [];
    try {
      String? idTinhThanhPho = sinhvienEdit.value.idNoiOHienNayTinhThanhPho;
      var response = await ApiRepository().getDataQuanHuyen(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        idTinhThanhPho,
      );
      listQuanHuyenNoiOHienNay.value = response;
    } catch (e) {
      logError(e.toString());
    }
  }

  refreshQuanHuyenDiaChiLL() async {
    listQuanHuyenDiaChiLL.value = [];
    try {
      String? idTinhThanhPho = sinhvienEdit.value.idDiaChiLienLacTinhThanhPho;
      var response = await ApiRepository().getDataQuanHuyen(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        idTinhThanhPho,
      );
      listQuanHuyenDiaChiLL.value = response;
    } catch (e) {
      logError(e.toString());
    }
  }

  refreshQuanHuyenDiaChiTamTru() async {
    final idTinhThanhPho = sinhvienEdit.value.diaChiTamTruTinhThanhPho;

    if (idTinhThanhPho == null || idTinhThanhPho.isEmpty) {
      listQuanHuyenDiaChiTamTru.clear();

      sinhvienEdit.update((item) {
        item?.diaChiTamTruQuanHuyen = "";
      });

      return;
    }

    try {
      final data = await ApiRepository().getDataQuanHuyen(
        null,
        Globals().thongTinSinhVienModel.value?.guidDonVi,
        idTinhThanhPho,
      );

      listQuanHuyenDiaChiTamTru.value = data;
    } catch (e) {
      logError(e.toString());
    }
  }

  updatePersonInfo() async {
    if (!configValueOk) {
      snackBarWarning('Không tìm thấy thông tin sinh viên');
      return;
    }

    final String oldCccd =
        Globals().thongTinSinhVienModel.value?.soCmtCccd?.trim() ?? '';
    final String newCccd = sinhvienEdit.value.soCmtCccd?.trim() ?? '';
    final bool cccdChanged = newCccd != oldCccd;
    final bool mustVerifyCccd =
        cccdChanged ||
        requireCccdVerificationForKtx.value ||
        hasPendingQrVerification.value;

    if (mustVerifyCccd) {
      final String studentCode =
          Globals().thongTinSinhVienModel.value?.maSinhVien?.trim() ?? '';
      if (studentCode.isEmpty) {
        snackBarWarning('Không xác định được mã sinh viên để đối chiếu CCCD.');
        return;
      }
      if (!RegExp(r'^\d{12}$').hasMatch(newCccd)) {
        snackBarWarning('CCCD mới phải gồm đúng 12 chữ số.');
        return;
      }
      if (verifiedQrCccd.value != newCccd ||
          verifiedQrFullName.value.trim().isEmpty ||
          verifiedQrDob.value == null) {
        snackBarWarning(
          'CCCD chỉ được cập nhật bằng cách quét QR trên thẻ căn cước.',
        );
        return;
      }
      if (cccdChanged) {
        final bool confirmed = await _confirmCccdChange(
          oldValue: oldCccd,
          newValue: newCccd,
        );
        if (!confirmed) return;
      }
    }

    Utils.showProgress(context);

    try {
      if (mustVerifyCccd) {
        // Backend xác minh lại họ tên/ngày sinh từ dữ liệu đào tạo, gọi KTX
        // /students/sync-student-code bằng MSSV lấy từ principal, rồi mới ghi
        // CCCD vào dữ liệu đào tạo. Không tin studentCode do client cung cấp.
        await ApiRepository().verifyCccdAndLink(
          identityNo: newCccd,
          fullName: verifiedQrFullName.value,
          dateOfBirth: verifiedQrDob.value!,
        );
      }

      // 1. Cập nhật các thông tin cá nhân còn lại. CCCD đã được backend
      // verify/link trước nên lần ghi này là idempotent với cùng số CCCD.
      await ApiRepository().updateSinhVienInfo(sinhvienEdit.value);

      // 2. Cập nhật địa chỉ tạm trú vào API mới
      await ApiRepository().updateDiaChiTamTru(sinhvienEdit.value);

      // 3. Refresh lại dữ liệu global
      await Globals().refreshStudentInfo();

      Utils.dismissProgress(context);
      Get.back(closeOverlays: true);
      snackBarSuccess('Cập nhật thông tin thành công.');
    } catch (e) {
      Utils.dismissProgress(context);
      if (_isCccdOwnershipConflict(e)) {
        await _showCccdSupportDialog();
        return;
      }
      if (mustVerifyCccd && _showCccdVerificationError(e)) {
        return;
      }
      AppFeedback.showError(e);
    }
  }

  Future<bool> _confirmCccdChange({
    required String oldValue,
    required String newValue,
  }) async {
    final BuildContext? dialogContext = context;
    if (dialogContext == null) return false;

    final bool? result = await showVcoreActionDialog<bool>(
      context: dialogContext,
      title: 'Xác nhận thay đổi CCCD',
      content:
          'CCCD là định danh duy nhất của sinh viên trên hệ thống.\n\n'
          'CCCD hiện tại: ${oldValue.isEmpty ? '(chưa có)' : oldValue}\n'
          'CCCD mới: $newValue\n\n'
          'Hãy kiểm tra thật kỹ trước khi cập nhật. Nếu hệ thống báo CCCD đã có người sở hữu, '
          'hãy gửi ticket tại it.vnu.edu.vn để được hỗ trợ.',
      leadingIcon: Icons.warning_amber_rounded,
      barrierDismissible: false,
      actions: const <VcoreDialogAction<bool>>[
        VcoreDialogAction<bool>(
          label: 'Kiểm tra lại',
          value: false,
          tone: VcoreDialogActionTone.secondary,
        ),
        VcoreDialogAction<bool>(
          label: 'Tôi xác nhận',
          value: true,
          icon: Icons.check_rounded,
          tone: VcoreDialogActionTone.primary,
        ),
      ],
    );
    return result == true;
  }

  bool _showCccdVerificationError(Object error) {
    if (error is! DioException) return false;
    final dynamic data = error.response?.data;
    if (data is! Map) return false;

    final String code = data['code']?.toString().trim() ?? '';
    final String message = data['message']?.toString().trim() ?? '';
    const Set<String> verificationCodes = <String>{
      'TRAINING_IDENTITY_INCOMPLETE',
      'STUDENT_CODE_MISMATCH',
      'CCCD_NAME_MISMATCH',
      'CCCD_DOB_INVALID',
      'CCCD_DOB_MISMATCH',
      'CCCD_OWNED_BY_OTHER_STUDENT',
      'KTX_LINK_CONFLICT',
      'KTX_LINK_REJECTED',
      'KTX_LINK_FAILED',
      'KTX_UNAVAILABLE',
    };
    if (!verificationCodes.contains(code) || message.isEmpty) return false;
    snackBarWarning(message);
    return true;
  }

  bool _isCccdOwnershipConflict(Object error) {
    int? statusCode;
    final List<String> parts = <String>[error.toString()];

    void collect(dynamic value) {
      if (value == null) return;
      if (value is Map) {
        for (final MapEntry<dynamic, dynamic> entry in value.entries) {
          parts.add(entry.key.toString());
          collect(entry.value);
        }
        return;
      }
      if (value is Iterable && value is! String) {
        for (final dynamic item in value) collect(item);
        return;
      }
      parts.add(value.toString());
    }

    if (error is DioException) {
      statusCode = error.response?.statusCode;
      collect(error.response?.data);
      collect(error.message);
    }

    final String text = parts.join(' ').toLowerCase();
    final bool mentionsCccd =
        text.contains('cccd') ||
        text.contains('căn cước') ||
        text.contains('can cuoc') ||
        text.contains('std_idcard');
    final bool mentionsConflict =
        text.contains('đã có người sở hữu') ||
        text.contains('đã tồn tại') ||
        text.contains('da ton tai') ||
        text.contains('duplicate') ||
        text.contains('unique') ||
        text.contains('conflict');

    return mentionsCccd &&
        mentionsConflict &&
        (statusCode == null || statusCode == 409 || statusCode == 422);
  }

  Future<void> _showCccdSupportDialog() async {
    final BuildContext? dialogContext = context;
    if (dialogContext == null) {
      snackBarWarning(
        'CCCD này đang được gắn với một sinh viên khác. Vui lòng gửi ticket tại it.vnu.edu.vn để được hỗ trợ.',
      );
      return;
    }

    await showVcoreActionDialog<bool>(
      context: dialogContext,
      title: 'CCCD đã có người sở hữu',
      content:
          'Số CCCD này đang được gắn với một sinh viên khác. Vui lòng kiểm tra lại số đã quét.\n\n'
          'Nếu đây đúng là CCCD của bạn, hãy gửi ticket hỗ trợ tại it.vnu.edu.vn để được kiểm tra và gỡ liên kết cũ.',
      leadingIcon: Icons.report_problem_outlined,
      actions: const <VcoreDialogAction<bool>>[
        VcoreDialogAction<bool>(
          label: 'Đã hiểu',
          value: true,
          icon: Icons.check_rounded,
          tone: VcoreDialogActionTone.primary,
        ),
      ],
    );
  }

  updateDiaChiTamTru() async {
    if (!configValueOk) {
      snackBarWarning('Không tìm thấy thông tin sinh viên');
      return;
    }

    Utils.showProgress(context);

    try {
      await ApiRepository().updateDiaChiTamTru(sinhvienEdit.value);

      await Globals().refreshStudentInfo();

      Utils.dismissProgress(context);
      Get.back(closeOverlays: true);
      snackBarSuccess('Cập nhật địa chỉ tạm trú thành công.');
    } catch (e) {
      Utils.dismissProgress(context);
      AppFeedback.showError(e);
    }
  }
}
