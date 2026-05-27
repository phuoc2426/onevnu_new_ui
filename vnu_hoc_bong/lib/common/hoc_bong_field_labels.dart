/// Nhãn hiển thị khi API/DB không có `tenTruong`.
const Map<String, String> hocBongFieldLabelsVi = {
  'bank_account_type': 'Loại tài khoản ngân hàng',
  'bank_account': 'Số tài khoản ngân hàng',
  'minh_chung_ren_luyen': 'Minh chứng rèn luyện',
  'minh_chung_hoc_ngheo': 'Minh chứng học nghèo',
};

String hocBongLabelFromMaTruong(String maTruong) {
  final key = maTruong.trim().toLowerCase();
  if (key.isEmpty) return 'Trường thông tin';
  final mapped = hocBongFieldLabelsVi[key];
  if (mapped != null) return mapped;

  return key
      .split(RegExp(r'[_\s]+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p.length == 1 ? p.toUpperCase() : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
      .join(' ');
}
