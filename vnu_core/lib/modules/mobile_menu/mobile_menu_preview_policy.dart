/// Local fallback for the UI-only phase. This is NOT the live server menu API
/// and MUST NOT be used as the authorization guard for actual payments.
class MobileMenuPreviewPolicy {
  static const Map<String, bool> enabled = <String, bool>{
    'native:Lịch học & thi': true,
    'native:Điểm': true,
    'native:Đăng ký môn': true,
    'native:Việc làm': true,
    // Hidden everywhere in the mobile UI; code remains available.
    'native:Đồng bộ': false,
    // V5: hidden temporarily from all mobile function menus; backend untouched.
    'native:Học phí': false,
    'native:Tài liệu': true,
    'native:Điểm danh': true,
    'native:Học bổng': true,
    'native:Phản ánh': true,
    'native:Nội trú': true,
    'native:Thủ tục': true,
    'native:Phòng trọ': true,
    'native:Thư viện': true,
    'native:Bản đồ': true,
    'native:Hỏi đáp': true,
    'native:Cẩm nang': true,
  };

  static const Map<String, Set<int>> visibleToUniversities = <String, Set<int>>{
    'native:Học phí': <int>{4},
  };

  static bool isVisible(String key, {required int? universityId}) {
    if (enabled[key] == false) return false;
    final allowed = visibleToUniversities[key];
    if (allowed == null) return true;
    return universityId != null && allowed.contains(universityId);
  }
}
