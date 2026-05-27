# 🔍 Chi Tiết Các File & Thư Mục Quan Trọng

**Cập nhật:** 12/11/2025

---

## 📂 Danh Sách File Quan Trọng Cần Biết

### **vnu_core/lib/common/ - Utilities Cơ Bản**

| File | Mục Đích | Sử Dụng |
|------|---------|--------|
| `app_color.dart` | Định nghĩa màu sắc toàn ứng dụng | Import & sử dụng `AppColor.*` |
| `app_text_styles.dart` | Text styles đã định sẵn | Import & sử dụng `AppTextStyle.*` |
| `base64_utils.dart` | Encode/decode Base64 | `base64Encode()`, `base64Decode()` |
| `convert_utitls.dart` | Convert data types | `convertToJson()`, `convertFromJson()` |
| `datetime_utils.dart` | Xử lý date/time | `formatDateTime()`, `parseDate()` |
| `debouncer.dart` | Debounce function calls | `Debouncer().run()` |
| `download_manager.dart` | Quản lý download file | `DownloadManager().downloadFile()` |
| `events.dart` | Event bus system | `eventBus.fire()`, `eventBus.on()` |
| `file_utils.dart` | Xử lý file | `getFileSize()`, `getFileExtension()` |
| `local_storage.dart` | SharedPreferences wrapper | `LocalStorage().save()`, `.read()` |
| `log.dart` | Logging system | `logInfo()`, `logError()`, `logSuccess()` |
| `map_utils.dart` | Map utilities | Map helpers & converters |
| `marker_icon_generator.dart` | Tạo custom marker icons | Cho Google Maps |
| `network_monitor.dart` | Monitor network connectivity | Auto-starts, check `isConnected` |
| `space_widget.dart` | Spacing helpers | `SizedBox` alternatives |
| `swipedetector.dart` | Detect swipe gestures | Gesture detection |
| `utils.dart` | General utilities | Mixed helper functions |
| `version_utils.dart` | Version checking | App version related |
| `vnu_cache_manager.dart` | Custom cache manager | Image/file caching |
| `weekdate_iso8601.dart` | ISO8601 date handling | Date parsing |

---

### **vnu_core/lib/constants/ - Hằng Số & Cấu Hình**

| File | Nội Dung |
|------|---------|
| `config.dart` | API URLs, configuration constants |
| `constant.dart` | Application-wide constants |
| `date_formater.dart` | Date format templates |
| `datetime_const.dart` | DateTime constants |
| `enum.dart` | Enums cho app (Status, Role, etc.) |

---

### **vnu_core/lib/extensions/ - Extension Methods**

**Lợi ích:** Thêm method mới vào existing types mà không subclass

| File | Mở Rộng Cho | Ví Dụ |
|------|------------|-------|
| `color_ext.dart` | Color | `color.isDark`, `color.inverted` |
| `context_ext.dart` | BuildContext | `context.showSnackBar()`, `context.pop()` |
| `date_time_extension.dart` | DateTime | `date.isToday`, `date.formatString()` |
| `extension_string.dart` | String | `string.isEmail()`, `string.toCapitalized()` |
| `iterables.dart` | List/Iterable | `list.firstOrNull()`, `list.groupBy()` |
| `map_ext.dart` | Map | `map.isEmpty`, `map.getOrNull()` |
| `xfile_ext.dart` | XFile (Image Picker) | File handling helpers |

**Cách Sử Dụng:**

```dart
import 'package:vnu_core/extensions/extension_string.dart';

String email = "user@example.com";
if (email.isEmail()) {
  print("Valid email");
}
```

---

### **vnu_core/lib/models/ - Data Models (Entities)**

**Mục đích:** Đại diện cho data structures của app

**Ví dụ Models:**
- `anh_ca_nhan_model.dart` - Avatar/Profile Image
- `bac_dao_tao_model.dart` - Education Level
- `ban_do_so_model.dart` - Digital Map
- `cam_nang_model.dart` - Guide/Handbook
- `cau_tra_loi_model.dart` - Answer/Reply
- `chu_de_model.dart` - Topic/Subject
- ...và nhiều model khác

**Mẫu Model:**
```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'your_model.freezed.dart';
part 'your_model.g.dart';

@freezed
class YourModel with _$YourModel {
  const factory YourModel({
    required String id,
    required String name,
    String? description,
  }) = _YourModel;

  factory YourModel.fromJson(Map<String, dynamic> json) =>
      _$YourModelFromJson(json);
}
```

**Sử dụng:**
```dart
final model = YourModel(id: '1', name: 'Test');
final json = model.toJson();
final model2 = YourModel.fromJson(json);
```

---

### **vnu_core/lib/data/ - API & Network Layer**

| File | Chức Năng |
|------|----------|
| `api_response.dart` | Generic API response wrapper |
| `api_reponse_domitory.dart` | Domitory-specific response |
| `app_api.dart` | All API endpoints (Retrofit) |

**API Response Structure:**
```dart
// Generic wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
}

// Usage
final response = await api.fetchNews();
if (response.success) {
  final data = response.data;
}
```

---

### **vnu_core/lib/cubit/ - State Management**

| File | Quản Lý |
|------|--------|
| `auth_cubit.dart` + `auth_state.dart` | Authentication state |
| `file_cubit.dart` + `file_state.dart` | File operations state |
| `map_cubit.dart` + `map_state.dart` | Map/Location state |

**Pattern:**
```dart
// Cubit handle business logic
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  
  AuthCubit(this.repository) : super(const AuthState.initial());
  
  Future<void> login(String email, String password) async {
    emit(const AuthState.loading());
    try {
      final user = await repository.login(email, password);
      emit(AuthState.success(user));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }
}

// State definition
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.success(User user) = _Success;
  const factory AuthState.error(String message) = _Error;
}
```

---

### **vnu_core/lib/repository/ - Data Access Layer**

| File | Chức Năng |
|------|----------|
| `app_repository.dart` | General app data access |
| `data_repository.dart` | Specific data operations |

**Mục đích:** Abstraction layer giữa Cubit và API

```dart
class AppRepository {
  final AppApi api;
  final LocalStorage localStorage;
  
  AppRepository({
    required this.api,
    required this.localStorage,
  });
  
  Future<User> getUser() async {
    try {
      // Try cache first
      final cached = await localStorage.read('user');
      if (cached != null) return User.fromJson(cached);
      
      // Then try API
      final user = await api.fetchUser();
      
      // Cache for later
      await localStorage.save('user', user.toJson());
      
      return user;
    } catch (e) {
      logError('Failed to get user: $e');
      rethrow;
    }
  }
}
```

---

### **vnu_core/lib/screens/ - Page Templates**

| Screen | Tujuan |
|--------|--------|
| `vcore_splash_screen.dart` | Splash/Loading page |
| `vcore_login_screen.dart` | Login page |
| `vcore_preview_pdf_screen.dart` | PDF viewer |

---

### **vnu_core/lib/modules/ - Feature Modules**

Setiap module adalah feature yang berdiri sendiri:

```
modules/
├── bookmark/           # Bookmark feature
├── browser/            # Web/HTML viewer
├── news/               # News feature
├── paht/               # Something specific
├── question/           # Q&A feature
├── system_news/        # System announcements
└── tabbar/             # Tab navigation
```

**Struktur setiap module:**
```
module_name/
├── controllers/        # GetX controllers (if used)
├── models/             # Module-specific models
├── views/              # UI screens/widgets
└── widgets/            # Reusable components
```

---

### **vnu_core/lib/services/ - Services**

| File | Layanan |
|------|---------|
| `services_url.dart` | Service URLs & endpoints |

---

### **vnu_core/lib/vnu_core.dart - Entry Point**

**Main initialization:**
```dart
class VnuCore {
  static final VnuCore _singleton = VnuCore._internal();
  
  factory VnuCore() => _singleton;
  
  VnuCore._internal() {
    // Initialize services
    NetworkMonitor().startListen();
  }
  
  // Main methods untuk initialize app
  void initialize() {
    // Setup app
  }
}
```

---

## 📦 vnu_noi_tru Module Structure

### **Key Files:**

| File/Folder | Mục Đích |
|------------|---------|
| `nt_globals.dart` | Global variables cho module |
| `vnu_noi_tru.dart` | Main entry point |
| `common/enum.dart` | Module-specific enums |
| `cubit/*` | Cubit states untuk feature |
| `data/noitru_api.dart` | API endpoints |
| `data/noitru_response.dart` | Response models |
| `models/*` | Domain models |
| `repository/*` | Data repository |
| `screens/*` | Full pages |
| `widgets/*` | Reusable components |

### **Interesting Classes:**

```dart
// Dormitory registration
- NtPhieuDangKyModel       // Registration form
- NtDanhSachDotDangKyModel // Registration period
- NtDanhSachPhongModel     // Room list
- NtDanhSachTrungTamModel  // Dormitory centers
- NtFileMinHChungModel     // Proof documents
```

---

## 🧠 Cara Menemukan Kode

### **Jika ingin tahu tentang Feature X:**

1. **Cari di `vnu_core/modules/X/`**
   ```bash
   # Contoh: Feature bookmark
   ls vnu_core/lib/modules/bookmark/
   ```

2. **Cari Cubit-nya:**
   ```bash
   # File: vnu_core/cubit/X_cubit.dart
   # File: vnu_core/cubit/X_state.dart
   ```

3. **Cari Model-nya:**
   ```bash
   # File: vnu_core/models/X_model.dart
   ```

4. **Cari screen/widget-nya:**
   ```bash
   # File: vnu_core/screens/X_screen.dart
   # File: vnu_core/widgets/X_widget.dart
   ```

### **Jika ingin menggunakan Utility Y:**

1. **Cari di `vnu_core/common/`**
   ```bash
   # Contoh: Logging
   import 'package:vnu_core/common/log.dart';
   ```

2. **Atau di `extensions/`**
   ```bash
   # Contoh: String extension
   import 'package:vnu_core/extensions/extension_string.dart';
   ```

---

## 🎨 Sering Dipakai (Must Know)

### **Absolute Must:**
1. ✅ `log.dart` - Logging everywhere
2. ✅ `app_color.dart` - Colors
3. ✅ `app_text_styles.dart` - Text styles
4. ✅ Cubit pattern - State management
5. ✅ Repository pattern - Data access

### **Sering Dipakai:**
6. `local_storage.dart` - SharedPrefs
7. `datetime_utils.dart` - Date handling
8. `extensions/*` - Memperpendek code
9. Models - Data structures
10. `network_monitor.dart` - Check connectivity

### **Kadang Dipakai:**
11. `download_manager.dart` - File downloads
12. `marker_icon_generator.dart` - Maps
13. `debouncer.dart` - Optimize calls
14. `file_utils.dart` - File operations

---

## 📝 Tips Menulis Kode Baru

### **Saat membuat Feature Baru:**

```
1. Buat folder di modules/ atau package baru
2. Buat Cubit + State files
3. Buat Models/DTOs
4. Buat Repository (optional tapi recommended)
5. Buat Screens & Widgets
6. Register routes & dependencies
7. Import & use di main app
```

### **Saat membuat Utility Baru:**

```
1. Apakah ini general? → common/
2. Apakah ini extension? → extensions/
3. Apakah ini model? → models/
4. Apakah ini enum/const? → constants/
```

---

## 🔗 File Dependencies

```
main.dart
  └── vnu_core.dart
      ├── cubit/ (state)
      ├── data/ (API)
      ├── repository/ (data access)
      ├── screens/ (UI)
      ├── models/ (entities)
      ├── common/ (utilities)
      ├── extensions/ (helpers)
      └── constants/ (config)
  └── vnu_noi_tru.dart
      ├── cubit/
      ├── data/
      ├── models/
      ├── repository/
      ├── screens/
      └── widgets/
```

---

## 💡 Memory Aid

| Abbr | Arti |
|------|------|
| nt_ | noi_tru (prefix untuk module) |
| vcore_ | vnu_core (prefix untuk core) |
| pb | phòng ban (department) |
| qt | quản trị (admin) |
| tk | tài khoản (account) |
| tư | tư vấn (consulting) |

---

**Bây giờ bạn sẽ dễ dàng điều hướng dự án! 🗺️**
