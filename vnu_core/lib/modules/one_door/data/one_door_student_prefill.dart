import 'package:intl/intl.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/repository/app_repository.dart';

/// User-visible, current-session student information resolved from OneVNU.
/// Do not silently manufacture school-year, faculty, or One Door case IDs.
class OneDoorStudentPrefill {
  const OneDoorStudentPrefill({
    required this.values,
    required this.usedLiveProfile,
    required this.warnings,
  });

  final Map<String, String> values;
  final bool usedLiveProfile;
  final List<String> warnings;

  int get filledCount => values.values.where((v) => v.trim().isNotEmpty).length;
}

class OneDoorStudentPrefillService {
  const OneDoorStudentPrefillService();

  static const Duration requestTimeout = Duration(seconds: 12);

  /// A school year is distinct from an enrollment cohort/niên khóa.
  /// This is a suggested academic-year label based on the local date;
  /// it can be corrected by the student on the document. No invented API.
  static String suggestedSchoolYear(DateTime now) {
    final begin = now.month >= 8 ? now.year : now.year - 1;
    return '$begin-${begin + 1}';
  }

  static Map<String, String> calendarValues(DateTime now) => <String, String>{
    'Ngay': '${now.day}',
    'Thang': '${now.month}',
    'Nam': '${now.year}',
    'NgayNop': DateFormat('dd/MM/yyyy').format(now),
    'NamHoc': suggestedSchoolYear(now),
  };

  /// Only reads endpoints that already exist in ApiRepository.
  /// Every lookup is scoped by the ID from the authenticated student record.
  Future<OneDoorStudentPrefill> load() async {
    final sessionToken = Globals().token.trim();
    if (sessionToken.isEmpty) {
      return OneDoorStudentPrefill(
        values: calendarValues(DateTime.now()), usedLiveProfile: false,
        warnings: const <String>['Không có phiên đăng nhập OneVNU để tải hồ sơ.'],
      );
    }
    final api = ApiRepository();
    final warnings = <String>[];
    var usedLiveProfile = false;
    var student = Globals().thongTinSinhVienModel.value;
    try {
      final live = await api.getSinhVienInfo().timeout(requestTimeout);
      if (Globals().token.trim() != sessionToken) {
        throw StateError('OneVNU session changed during profile loading');
      }
      student = live;
      Globals().thongTinSinhVienModel.value = live;
      usedLiveProfile = true;
    } catch (_) {
      if (Globals().token.trim() != sessionToken) {
        throw StateError('OneVNU session changed during profile loading');
      }
      warnings.add('Unable to refresh profile; using current-session cache if present.');
    }
    if (student == null) {
      warnings.add('Không có hồ sơ sinh viên: các trường cá nhân cần nhập thủ công.');
      return OneDoorStudentPrefill(
        values: calendarValues(DateTime.now()),
        usedLiveProfile: false, warnings: warnings,
      );
    }

    final info = student;

    String clean(String? value) => value?.trim() ?? '';
    final values = <String, String>{
      ...calendarValues(DateTime.now()),
      'HoTen': clean(info.hoVaTen),
      'MaSV': clean(info.maSinhVien),
      'NgaySinh': info.ngaySinh == null
          ? '' : DateFormat('dd/MM/yyyy').format(info.ngaySinh!),
      'CCCD': clean(info.soCmtCccd),
      'SoDienThoai': clean(info.mobile).isNotEmpty
          ? clean(info.mobile) : clean(info.tel),
      'Email': clean(info.email).isNotEmpty
          ? clean(info.email) : clean(info.emailKhac),
      // This is StudentInfoModel.maHoSo, a STUDENT profile reference;
      // it is NOT the One Door idDangKy assigned after POST /ho-so.
      'MaHoSo': clean(info.maHoSo),
      // No faculty name exists in the verified StudentInfoModel or the
      // class/major lookup models. Never pass university name as faculty.
      'TenKhoa': '',
    };
    warnings.add('Năm học được gợi ý theo ngày thiết bị; kiểm tra trước khi nộp.');
    if (values['MaHoSo']!.isEmpty) {
      warnings.add('Hồ sơ sinh viên OneVNU chưa có mã hồ sơ.');
    }

    void store(String key, String? value) {
      final next = clean(value);
      if (next.isNotEmpty) values[key] = next;
    }

    // Prefer a matching cached class immediately; the live lookup below
    // can confirm it. Never use a class from another student session.
    final cachedClass = Globals().lopDaoTaoModel.value;
    if (cachedClass != null && cachedClass.id == info.idLopDaoTao) {
      store('TenLop', cachedClass.ten);
    }

    final lookupTasks = <Future<void>>[];
    if (clean(info.idLopDaoTao).isNotEmpty) {
      lookupTasks.add(() async {
        try {
          final rows = await api.getDataLopDaoTao(
            info.idLopDaoTao, info.guidDonVi, info.idBacDaoTao,
            info.idHeDaoTao, info.idNganhDaoTao,
            info.idNienKhoaDaoTao, info.idChuongTrinhDaoTao,
          ).timeout(requestTimeout);
          final exact = rows.where((row) => row.id == info.idLopDaoTao).toList();
          final selected = exact.length == 1 ? exact.single :
              (rows.length == 1 ? rows.single : null);
          store('TenLop', selected?.ten);
        } catch (_) {
          warnings.add('Class lookup was unavailable.');
        }
      }());
    }
    if (clean(info.idHeDaoTao).isNotEmpty) {
      lookupTasks.add(() async {
        try {
          final rows = await api.getDataHeDaoTao(
            info.idHeDaoTao, info.guidDonVi, info.idBacDaoTao,
          ).timeout(requestTimeout);
          final exact = rows.where((row) => row.id == info.idHeDaoTao).toList();
          final selected = exact.length == 1 ? exact.single :
              (rows.length == 1 ? rows.single : null);
          store('He', selected?.ten);
        } catch (_) {
          warnings.add('Training-system lookup was unavailable.');
        }
      }());
    }
    if (clean(info.idNganhDaoTao).isNotEmpty) {
      lookupTasks.add(() async {
        try {
          final rows = await api.getDataNganhDaoTao(
            info.idNganhDaoTao, info.guidDonVi, info.idBacDaoTao,
          ).timeout(requestTimeout);
          final exact = rows.where((row) => row.id == info.idNganhDaoTao).toList();
          final selected = exact.length == 1 ? exact.single :
              (rows.length == 1 ? rows.single : null);
          store('NganhHoc', selected?.ten);
        } catch (_) {
          warnings.add('Major lookup was unavailable.');
        }
      }());
    }
    await Future.wait(lookupTasks);
    if (Globals().token.trim() != sessionToken) {
      throw StateError('OneVNU session changed during academic lookups');
    }
    // An academic cohort is not the CURRENT school year. A date-derived
    // suggestion was provided above; the student may edit it as needed.
    // Faculty is not present in verified profile/class/major model fields.
    if ((values['TenKhoa'] ?? '').trim().isEmpty) {
      warnings.add('Tên khoa chưa có từ API hồ sơ hiện tại: cần người dùng bổ sung.');
    }
    return OneDoorStudentPrefill(
      values: values,
      usedLiveProfile: usedLiveProfile,
      warnings: warnings,
    );
  }
}
