 # 🚀 BẮT ĐẦU TẠI ĐÂY - Hướng dẫn Onboarding dự án ONE VNU

**Chào mừng Developer mới! 👋**

---

## ⚡ TL;DR (Tóm tắt nhanh)

Nếu bạn đang vội:

1. **Đọc QUICK_START_GUIDE.md trước** (5 phút)
2. **Chạy ứng dụng:**

```powershell
flutter pub get
flutter run
```
3. **Hỏi người có kinh nghiệm** nếu bạn gặp khó khăn

---

## 📚 Tài liệu hướng dẫn (Chọn theo nhu cầu)

### **Tôi muốn biết...**

| Câu hỏi | File | Thời gian |
|---|---:|---:|
| Dự án này là gì? | [ONBOARDING_GUIDE_VN.md](ONBOARDING_GUIDE_VN.md) | 30 phút |
| Cấu trúc mã nguồn | [FILE_STRUCTURE_GUIDE.md](FILE_STRUCTURE_GUIDE.md) | 15 phút |
| Làm sao tạo tính năng mới? | [CODE_EXAMPLES.md](CODE_EXAMPLES.md) | 30 phút |
| Phương pháp & best practices | [PATTERNS_AND_BEST_PRACTICES.md](PATTERNS_AND_BEST_PRACTICES.md) | 20 phút |
| Kiến trúc (hình ảnh) | [VISUAL_ARCHITECTURE_GUIDE.md](VISUAL_ARCHITECTURE_GUIDE.md) | 15 phút |
| Tóm tắt toàn bộ | [ONBOARDING_SUMMARY.md](ONBOARDING_SUMMARY.md) | 10 phút |
| Điều hướng tài liệu | [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) | 10 phút |

---

## 🎯 5 điều quan trọng cần biết

1. Đây là một monorepo gồm 3 module chính:

```
one_vnu_appstore/   ← Ứng dụng chính
vnu_core/           ← Bộ khung dùng chung (reusable)
vnu_noi_tru/        ← Module chức năng (Nội trú)
```

2. `vnu_core` là bộ khung chung (đáng đọc):
  - Chứa utilities, widgets, services, models
  - Bao gồm logging, theme, storage
  - Dùng lại cho các module/ứng dụng khác

3. Sử dụng **Cubit** (flutter_bloc) cho quản lý trạng thái

```dart
class MyFeatureCubit extends Cubit<MyState> { ... }
BlocBuilder<MyFeatureCubit, MyState>(...) { ... }
```

4. Áp dụng **Repository pattern** cho truy cập dữ liệu (API + cache)

```dart
class MyRepository {
  Future<List<T>> getData() async {
    // Gọi API + caching
  }
}
```

5. Ghi log và xử lý lỗi đầy đủ:

```dart
import 'package:vnu_core/common/log.dart';
logInfo('Thông tin');
logError('Lỗi xảy ra');
```

---

## 🏃 Cài đặt nhanh (5 phút)

Mở PowerShell (Windows) trong thư mục `one_vnu_appstore` và chạy:

```powershell
git clone <repo-url>
cd iworkspace_mobile_onevnu-master\one_vnu_appstore
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

Nếu gặp lỗi build thử:

```powershell
flutter clean; flutter pub get; flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📖 Thứ tự học đề xuất

### Buổi 1 - Nền tảng (Hôm nay)

1. `QUICK_START_GUIDE.md` (5 phút)
2. `ONBOARDING_GUIDE_VN.md` (30 phút)
3. `VISUAL_ARCHITECTURE_GUIDE.md` (15 phút)

Kết quả: hiểu tổng quan và cách chạy dự án.

### Buổi 2 - Chi tiết (Ngày sau)

1. `FILE_STRUCTURE_GUIDE.md` (15 phút)
2. `PATTERNS_AND_BEST_PRACTICES.md` (20 phút)
3. Dò mã trong `vnu_core/` (30 phút)

Kết quả: hiểu pattern & nơi đặt code.

### Buổi 3 - Thực hành

1. `CODE_EXAMPLES.md` (30 phút)
2. Tạo feature nhỏ (1-2 giờ)
3. Nhờ code review (30 phút)

Kết quả: sẵn sàng đóng góp.

---

## 🎮 Các nhiệm vụ thường gặp

- Tạo màn hình mới: xem `CODE_EXAMPLES.md` → Creating a New Feature Module
- Dùng tiện ích `vnu_core`: xem `QUICK_START_GUIDE.md` hoặc `FILE_STRUCTURE_GUIDE.md`
- Gọi API: xem `CODE_EXAMPLES.md` → Working with APIs
- Không biết thư mục: xem `FILE_STRUCTURE_GUIDE.md`
- Quản lý trạng thái: xem `PATTERNS_AND_BEST_PRACTICES.md`

---

## ⚠️ Những điều nên tránh

- Đặt logic (gọi API, xử lý dữ liệu) trực tiếp trong widget UI — dùng Cubit/Repository thay thế.
- Bỏ qua xử lý lỗi.
- Không dùng hệ thống logging chuẩn (dùng `vnu_core/common/log.dart`).

Ví dụ đúng/không đúng đã có trong `CODE_EXAMPLES.md`.

---

## ✅ Checklist - Bạn sẵn sàng nếu

- [ ] Đã đọc `QUICK_START_GUIDE.md`
- [ ] Chạy ứng dụng thành công
- [ ] Hiểu cấu trúc monorepo
- [ ] Biết `vnu_core` là gì
- [ ] Hiểu Cubit và có thể tạo Cubit cơ bản
- [ ] Có thể tạo màn hình cơ bản
- [ ] Sử dụng được utilities (log, storage, extensions)
- [ ] Biết cách kiểm soát lỗi

---

## 🆘 Trợ giúp & lỗi thường gặp

| Vấn đề | Giải pháp |
|---|---|
| "Module not found" | Chạy `flutter pub get` ở folder tương ứng |
| "No provider found" | Đăng ký provider/Cubit trong `main.dart` hoặc nơi khởi tạo |
| Lỗi build | `flutter clean` rồi `flutter pub get`, chạy lại build_runner nếu cần |
| Freezed/Codegen chưa generate | `flutter pub run build_runner build --delete-conflicting-outputs` |
| Không tìm file | Xem `FILE_STRUCTURE_GUIDE.md` hoặc dùng tìm kiếm IDE |

---

## 📱 Stack công nghệ (tóm tắt)

- Ngôn ngữ: Dart
- Framework: Flutter
- State management: Cubit (flutter_bloc)
- HTTP/API: Dio + Retrofit
- Lưu trữ: SharedPreferences, Secure Storage
- Logging: Talker
- Firebase: Messaging, Analytics, Crashlytics
- Kiến trúc: Clean Architecture + Repository Pattern

---

## 🎓 Lộ trình học ngắn gọn

Day 1: đọc tài liệu chính và chạy app
Day 2-3: học patterns, xem code trong `vnu_core`
Day 4-5: làm feature nhỏ và nộp code review

---

## � Tham khảo nhanh (mã ví dụ)

Logging:

```dart
import 'package:vnu_core/common/log.dart';
logInfo('Thông tin');
logError('Lỗi');
```

Local storage:

```dart
import 'package:vnu_core/common/local_storage.dart';
await LocalStorage().save('key', value);
final v = await LocalStorage().read('key');
```

Extensions:

```dart
import 'package:vnu_core/extensions/extension_string.dart';
final ok = 'email@example.com'.isEmail();
```

---

## 📞 Liên hệ

- Vấn đề kỹ thuật: hỏi senior developer
- Câu hỏi kiến trúc: hỏi team lead
- Câu hỏi quy trình: hỏi manager

---

## 📚 Danh sách tài liệu

1. `START_HERE.md` (file này)
2. `QUICK_START_GUIDE.md`
3. `ONBOARDING_GUIDE_VN.md`
4. `PATTERNS_AND_BEST_PRACTICES.md`
5. `FILE_STRUCTURE_GUIDE.md`
6. `CODE_EXAMPLES.md`
7. `VISUAL_ARCHITECTURE_GUIDE.md`
8. `DOCUMENTATION_INDEX.md`
9. `ONBOARDING_SUMMARY.md`

---

**Trạng thái:** Sẵn sàng để bắt đầu coding ✅

**Bắt đầu ngay:** mở `QUICK_START_GUIDE.md` và làm theo các bước đầu tiên.

---

Chúc bạn học tốt và code hiệu quả! 🚀

