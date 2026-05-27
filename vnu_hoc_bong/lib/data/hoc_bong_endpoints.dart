/// Đường dẫn API học bổng (sinh viên).
///
/// Backend admin: `/api/admin/hoc-bong/*` (HocBongController, HocBongHoSoController, …).
/// App mobile dùng prefix `/api/app/hoc-bong` — cùng cấu trúc path con với admin.
abstract final class HocBongEndpoints {
  static const base = '/api/app/hoc-bong';

  /// GET — danh sách đợt học bổng (tương ứng admin GET `/api/admin/hoc-bong`).
  static const list = base;

  /// GET — chi tiết đợt học bổng.
  static String detail(int id) => '$base/$id';

  /// GET — kiểm tra điều kiện đăng ký.
  static String validate(int id) => '$base/$id/validate';

  /// GET/POST — bản nháp theo đợt.
  static String draftByHocBong(int hocBongId) => '$base/$hocBongId/draft';

  /// PUT — cập nhật bản nháp hồ sơ (dưới `ho-so-cua-toi`, tránh trùng `/{id}`).
  static String draftByHoSo(int hoSoId) => '$base/ho-so-cua-toi/$hoSoId/draft';

  /// POST — upload minh chứng.
  static String uploadMinhChung(int hoSoId) => '$base/ho-so-cua-toi/$hoSoId/upload-minh-chung';

  /// POST — nộp hồ sơ.
  static String submitHoSo(int hoSoId) => '$base/ho-so-cua-toi/$hoSoId/submit';

  /// GET — hồ sơ của sinh viên (`AppHocBongHoSoController`).
  static const hoSoList = '$base/ho-so-cua-toi';

  /// GET — chi tiết hồ sơ của sinh viên.
  static String hoSoDetail(int id) => '$base/ho-so-cua-toi/$id';

  /// GET — loại học bổng (tương ứng admin GET `/api/admin/hoc-bong/loai`).
  static const loaiList = '$base/loai';

  /// GET — xem trước file (tương ứng admin GET `/api/admin/hoc-bong/file/{id}/preview`).
  static String filePreview(int fileId) => '$base/file/$fileId/preview';
}
