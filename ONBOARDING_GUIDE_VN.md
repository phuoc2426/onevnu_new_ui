# 📚 Hướng Dẫn Onboarding Dự Án ONE VNU AppStore

**Ngày cập nhật:** 12/11/2025  
**Mục đích:** Giúp developer mới nắm vững cấu trúc dự án và biết cách tái sử dụng các component

---

## 📋 Mục Lục

1. [Cấu Trúc Dự Án](#cấu-trúc-dự-án)
2. [Các Module Chính](#các-module-chính)
3. [Stack Công Nghệ](#stack-công-nghệ)
4. [Cách Sử Dụng Lại Code (Reusable)](#cách-sử-dụng-lại-code-reusable)
5. [Các Utility & Helper Quan Trọng](#các-utility--helper-quan-trọng)
6. [Hướng Dẫn Nhanh](#hướng-dẫn-nhanh)

---

## 🏗️ Cấu Trúc Dự Án

```
iworkspace_mobile_onevnu-master/
├── one_vnu_appstore/          # 📱 Ứng dụng chính (main app)
├── vnu_core/                  # 🎯 Core module - Bộ khung chung (TÁI SỬ DỤNG)
├── vnu_noi_tru/               # 🏢 Module cho chức năng nội trú
└── inmapz/                    # 🗺️ Module bản đồ tùy chỉnh
```

### Mô Tả Chi Tiết:

#### **1. `one_vnu_appstore/` - Ứng Dụng Chính**
- **Loại:** Ứng dụng Flutter chính
- **Vai trò:** Tích hợp tất cả các module con
- **Dependencies:** Phụ thuộc vào `vnu_core` và `vnu_noi_tru`
- **Nền tảng hỗ trợ:** Android, iOS, Web, Windows, Linux, macOS
- **Chứa:**
  - `lib/main.dart` - Entry point chính
  - `firebase.json` - Cấu hình Firebase
  - `assets/images/` - Tài nguyên hình ảnh

#### **2. `vnu_core/` - Core Module (★ Quan Trọng Nhất ★)**
- **Loại:** Flutter plugin/package
- **Vai trò:** Bộ khung chung cho toàn dự án - SỬ DỤNG LẠI ĐƯỢC
- **Người có thể sử dụng:** `one_vnu_appstore`, `vnu_noi_tru`, và các dự án khác
- **Chứa:**
  - Utility functions
  - Common widgets
  - State management (Cubit)
  - API integration
  - Themes & styles
  - Models & DTOs
  - Services

#### **3. `vnu_noi_tru/` - Module Nội Trú**
- **Loại:** Flutter package (tính năng đặc thù)
- **Vai trò:** Quản lý chức năng đăng ký nội trú
- **Dependencies:** Phụ thuộc vào `vnu_core`
- **Chứa:**
  - Screens (Màn hình)
  - Cubits (State management)
  - Models (Dữ liệu)
  - Widgets (Component UI)
  - Repository (Lấy dữ liệu)

#### **4. `inmapz/` - Module Bản Đồ**
- **Loại:** Custom map plugin
- **Vai trò:** Xử lý các chức năng liên quan bản đồ

---

## 🎯 Các Module Chính

### **vnu_core Module Structure**

```
vnu_core/lib/
├── common/                  # 🔧 Tiện ích & Utility
│   ├── app_color.dart           # Màu sắc app
│   ├── app_text_styles.dart     # Text styles
│   ├── base64_utils.dart        # Encode/decode Base64
│   ├── convert_utitls.dart      # Convert data
│   ├── datetime_utils.dart      # Xử lý date/time
│   ├── debouncer.dart          # Debouncer function
│   ├── download_manager.dart   # Quản lý download file
│   ├── events.dart             # Event bus
│   ├── file_utils.dart         # Xử lý file
│   ├── local_storage.dart      # Local storage (SharedPrefs)
│   ├── log.dart                # Logging
│   ├── map_utils.dart          # Map utilities
│   ├── marker_icon_generator.dart  # Tạo marker icon
│   ├── network_monitor.dart    # Monitor kết nối mạng
│   ├── space_widget.dart       # Space widget helper
│   ├── swipedetector.dart      # Detect swipe gestures
│   ├── utils.dart              # Các utility khác
│   └── version_utils.dart      # Version checking
│
├── constants/               # 📌 Hằng số
│   ├── config.dart             # Cấu hình API
│   ├── constant.dart           # Hằng số chung
│   ├── date_formater.dart      # Date format constants
│   ├── datetime_const.dart     # DateTime constants
│   └── enum.dart               # Enums
│
├── cubit/                   # 🎮 State Management (Cubit)
│   ├── auth_cubit.dart         # Xác thực người dùng
│   ├── auth_state.dart
│   ├── file_cubit.dart         # Quản lý file
│   ├── file_state.dart
│   ├── map_cubit.dart          # Quản lý bản đồ
│   └── map_state.dart
│
├── data/                    # 📡 API & Data Layer
│   ├── api_response.dart       # Response model
│   ├── app_api.dart            # API endpoints
│   └── api_reponse_domitory.dart
│
├── data_request/            # 📨 Request DTOs
│   ├── nguon_tin_request.dart
│   ├── phan_anh_hien_truong_request.dart
│   ├── tao_hoi_dap_request.dart
│   └── tao_lien_ket_danh_dau_request.dart
│
├── extensions/              # 🔌 Extensions (Mở rộng)
│   ├── color_ext.dart          # Extension cho Color
│   ├── context_ext.dart        # Extension cho BuildContext
│   ├── date_time_extension.dart
│   ├── extension_string.dart   # Extension cho String
│   ├── iterables.dart
│   ├── map_ext.dart            # Extension cho Map
│   └── xfile_ext.dart          # Extension cho XFile
│
├── hooks/                   # 🪝 Flutter Hooks
│   └── use_async_effect.dart
│
├── models/                  # 🏷️ Data Models (Entity)
│   ├── anh_ca_nhan_model.dart
│   ├── bac_dao_tao_model.dart
│   ├── cam_nang_model.dart
│   ├── chu_de_model.dart
│   └── ... (khoảng 30+ models khác)
│
├── modules/                 # 📦 Feature Modules
│   ├── bookmark/
│   ├── browser/
│   ├── news/
│   ├── paht/
│   ├── question/
│   ├── system_news/
│   ├── tabbar/
│   └── ... (và nhiều module khác)
│
├── repository/              # 🗄️ Data Repository
│   ├── app_repository.dart
│   └── data_repository.dart
│
├── screens/                 # 📺 Màn hình
│   ├── vcore_login_screen.dart
│   ├── vcore_splash_screen.dart
│   ├── vcore_preview_pdf_screen.dart
│   └── ...
│
├── services/                # 🛠️ Services
│   └── services_url.dart
│
├── themes/                  # 🎨 Themes
│
├── widgets/                 # 🧩 Reusable Widgets
│
└── vnu_core.dart           # Main entry point
```

### **vnu_noi_tru Module Structure**

```
vnu_noi_tru/lib/
├── common/                  # Enum & Constant
├── cubit/                   # State Management
│   ├── nt_news_cubit.dart
│   ├── nt_register_cubit.dart
│   └── nt_*_state.dart
├── data/                    # API & Models
│   ├── noitru_api.dart
│   └── requests/
├── models/                  # Data Models
│   ├── nt_danh_sach_*_model.dart
│   ├── nt_tin_tuc_model.dart
│   └── ...
├── modules/                 # Features
│   └── boarding/            # Chức năng nội trú
│       ├── controllers/
│       └── views/
├── repository/              # Data layer
├── screens/                 # Screens
└── widgets/                 # Widgets
```

---

## 🔧 Stack Công Nghệ

### **Framework & Language:**
- **Flutter:** UI framework
- **Dart:** Programming language (phiên bản >= 3.1.2)

### **State Management:**
- **Flutter Bloc/Cubit:** State management pattern
- **GetX:** Navigation & dependency injection (Get)

### **API & Networking:**
- **Dio:** HTTP client
- **Retrofit:** Type-safe REST client
- **Talker:** Logging HTTP requests/responses

### **Firebase:**
- `firebase_core` - Firebase initialization
- `firebase_messaging` - Push notifications
- `firebase_analytics` - Event tracking
- `firebase_crashlytics` - Crash reporting
- `firebase_remote_config` - Remote configuration

### **Data Storage:**
- **SharedPreferences:** Local key-value storage
- **Flutter Secure Storage:** Secure storage
- **SQLFlite:** Local database (nếu cần)
- **Flutter Cache Manager:** File caching

### **UI/UX:**
- **Flutter Material Design**
- **Flutter HTML:** Render HTML content
- **Photo View:** Image viewer
- **Video Player:** Video playback
- **Google Maps Flutter:** Maps integration
- **Carousel Slider:** Carousel component
- **Pull to Refresh:** Refresh gesture

### **Utilities:**
- **UUID:** Generate unique IDs
- **Google Fonts:** Custom fonts
- **Intl:** Internationalization & localization
- **Permission Handler:** Manage app permissions
- **Geolocator:** Geolocation services
- **Local Auth:** Biometric authentication
- **File Picker & Image Picker:** File selection
- **Flutter SVG:** SVG rendering

### **Development Tools:**
- **Flutter Hooks:** Reusable stateful logic
- **Build Runner:** Code generation
- **Freezed:** Immutable models
- **JSON Serializable:** JSON serialization

---

## 💾 Cách Sử Dụng Lại Code (Reusable)

### **1️⃣ Sử Dụng vnu_core trong Ứng Dụng Khác**

**Bước 1:** Thêm dependency trong `pubspec.yaml` của ứng dụng mới:

```yaml
dependencies:
  vnu_core:
    path: '../vnu_core'  # Hoặc path tương đối
```

**Bước 2:** Import và sử dụng:

```dart
import 'package:vnu_core/vnu_core.dart';

// Sử dụng VnuCore singleton
VnuCore().initialize();
```

### **2️⃣ Sử Dụng Specific Utilities**

**Example 1: Sử dụng Log Utility**
```dart
import 'package:vnu_core/common/log.dart';

logInfo('This is info message');
logError('This is error message');
logSuccess('This is success message');
logWarning('This is warning message');
```

**Example 2: Sử Dụng Date Utils**
```dart
import 'package:vnu_core/common/datetime_utils.dart';

String formattedDate = formatDateTime(DateTime.now());
bool isExpired = isDateExpired(expiryDate);
```

**Example 3: Sử Dụng Local Storage**
```dart
import 'package:vnu_core/common/local_storage.dart';

LocalStorage storage = LocalStorage();
await storage.save('key', 'value');
String? value = await storage.read('key');
```

**Example 4: Sử Dụng Download Manager**
```dart
import 'package:vnu_core/common/download_manager.dart';

DownloadManager downloadManager = DownloadManager();
await downloadManager.downloadFile(url, fileName);
```

### **3️⃣ Sử Dụng Cubit (State Management)**

**Example 1: Sử Dụng Auth Cubit**
```dart
import 'package:vnu_core/cubit/auth_cubit.dart';

// Trong BlocListener hoặc Builder
BlocListener<AuthCubit, AuthState>(
  listener: (context, state) {
    if (state is AuthSuccess) {
      // Handle success
    }
  },
  child: YourWidget(),
);
```

**Example 2: Tạo Cubit Mới Tuân Theo Pattern**
```dart
// Xem vnu_core/cubit/auth_cubit.dart làm template
// File Structure:
// - your_cubit.dart
// - your_state.dart

// Sử dụng Freezed for immutability
import 'package:freezed_annotation/freezed_annotation.dart';

part 'your_state.freezed.dart';

@freezed
class YourState with _$YourState {
  const factory YourState.initial() = _Initial;
  const factory YourState.loading() = _Loading;
  const factory YourState.success(String data) = _Success;
  const factory YourState.error(String message) = _Error;
}
```

### **4️⃣ Sử Dụng Models & DTOs**

**Example:**
```dart
// Import model từ vnu_core
import 'package:vnu_core/models/model.dart';

// Models được tự động generate JSON serialization
MyModel model = MyModel.fromJson(jsonData);
Map<String, dynamic> json = model.toJson();
```

### **5️⃣ Sử Dụng API/Repository**

```dart
import 'package:vnu_core/repository/app_repository.dart';

final repository = AppRepository();
final response = await repository.fetchSomeData();

// Hoặc với error handling
try {
  final response = await repository.fetchData();
  if (response.isSuccess) {
    // Handle success
  } else {
    // Handle error
  }
} catch (e) {
  logError(e.toString());
}
```

### **6️⃣ Tạo Module Mới Tương Tự vnu_noi_tru**

**Cấu trúc gợi ý:**
```
your_new_module/
├── lib/
│   ├── your_module.dart          # Main entry
│   ├── common/
│   ├── cubit/                    # State management
│   ├── data/                     # API & DTOs
│   ├── models/
│   ├── modules/                  # Features
│   ├── repository/
│   ├── screens/
│   └── widgets/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

**pubspec.yaml:**
```yaml
name: your_new_module
version: 0.0.1

environment:
  sdk: ">=3.1.2 <4.0.0"
  flutter: ">=2.5.0"

dependencies:
  flutter:
    sdk: flutter
  vnu_core:
    path: '../vnu_core'
  # Add other dependencies
```

---

## 🧰 Các Utility & Helper Quan Trọng

### **1. Logging System**
```dart
// File: vnu_core/common/log.dart
logInfo('message');      // Thông tin
logError('message');     // Lỗi
logSuccess('message');   // Thành công
logWarning('message');   // Cảnh báo
```

### **2. Color Definitions**
```dart
// File: vnu_core/common/app_color.dart
// Sử dụng màu toàn ứng dụng
```

### **3. Text Styles**
```dart
// File: vnu_core/common/app_text_styles.dart
// Các style text được định nghĩa sẵn
```

### **4. Network Monitoring**
```dart
import 'package:vnu_core/common/network_monitor.dart';
// Tự động monitor trạng thái mạng
```

### **5. Version Utils**
```dart
import 'package:vnu_core/common/version_utils.dart';
// Check version app, compare versions
```

### **6. File & Download Utils**
```dart
import 'package:vnu_core/common/file_utils.dart';
import 'package:vnu_core/common/download_manager.dart';
// Xử lý file, download
```

### **7. Extensions (Mở rộng)**

**String Extensions:**
```dart
import 'package:vnu_core/extensions/extension_string.dart';
String text = "hello";
// Sử dụng custom extensions
```

**BuildContext Extensions:**
```dart
import 'package:vnu_core/extensions/context_ext.dart';
// Sử dụng extensions cho BuildContext
```

**DateTime Extensions:**
```dart
import 'package:vnu_core/extensions/date_time_extension.dart';
// Sử dụng extensions cho DateTime
```

### **8. Constants**
```dart
// File: vnu_core/constants/constant.dart
// Các hằng số dự án
```

---

## 🚀 Hướng Dẫn Nhanh

### **Setup Dự Án Lần Đầu:**

```bash
# 1. Clone dự án
git clone <repo>

# 2. Vào thư mục dự án
cd iworkspace_mobile_onevnu-master

# 3. Get dependencies
cd one_vnu_appstore
flutter pub get

# 4. Generate code (nếu cần)
flutter pub run build_runner build --delete-conflicting-outputs

# 5. Run app
flutter run
```

### **Tạo Màn Hình Mới:**

1. Tạo file mới trong `screens/` hoặc `modules/<feature>/views/`
2. Tạo Cubit tương ứng nếu cần state management
3. Import và sử dụng trong main routing

### **Sử Dụng vnu_core Widgets:**

```dart
import 'package:vnu_core/widgets/your_widget.dart';
```

### **Debugging:**

- Sử dụng `logInfo()`, `logError()` từ `vnu_core/common/log.dart`
- Check Firebase Crashlytics cho production errors
- Sử dụng `Talker` để inspect HTTP requests (xem logs)

### **API Integration:**

```dart
// Xem vnu_core/data/app_api.dart
// Sử dụng Retrofit để định nghĩa endpoints
// Tự động generate code với build_runner
```

---

## 📝 Checklist Cho Developer Mới

- [ ] Hiểu cấu trúc monorepo (multiple modules)
- [ ] Biết vnu_core là bộ khung chung
- [ ] Hiểu Cubit cho state management
- [ ] Biết cách sử dụng lại code từ vnu_core
- [ ] Biết repository pattern cho data layer
- [ ] Quen thuộc với các utilities & helpers
- [ ] Biết cách thêm dependencies mới
- [ ] Hiểu Firebase integration
- [ ] Biết debugging & logging
- [ ] Quen thuộc với extension methods

---

## 🤝 Cần Giúp?

- **Documentation:** Xem README.md trong từng module
- **Code Examples:** Xem files trong `vnu_core/common/` hoặc `vnu_noi_tru/`
- **API Docs:** Xem `vnu_core/data/app_api.dart`
- **Models:** Xem `vnu_core/models/` để hiểu data structures

---

**Chúc bạn thành công với dự án! 🎉**
