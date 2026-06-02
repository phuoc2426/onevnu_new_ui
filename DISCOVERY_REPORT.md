# DISCOVERY REPORT
Generated: 2026-05-28
Agent: Google AI Agent (Antigravity)

## STATUS
- [x] Phase 1: Codebase exploration
- [ ] Phase 2: API exploration (CHẶN: cần DORMITORY_API_TOKEN từ dev)
- [ ] Phase 3: Architecture decisions
- [ ] Phase 4: Ready to code

---

## 1.1 Package Map

### App chính:
- **Package:** `one_vnu_appstore` — đường dẫn: `./one_vnu_appstore/`
- Dependencies: phụ thuộc `vnu_core` và `vnu_noi_tru` (path local)

### vnu_core:
- **Path:** `./vnu_core/`
- **Vai trò:** Core module — chứa utilities, widgets, themes, state management, API, models chung
- **Type:** Flutter plugin/package

### vnu_noi_tru:
- **Path:** `./vnu_noi_tru/`
- **Vai trò:** Module chức năng nội trú
- **Dependencies:** phụ thuộc `vnu_core` (path: `../vnu_core`)

### vnu_hoc_bong:
- **Path:** `./vnu_hoc_bong/`
- **Vai trò:** Module học bổng (không liên quan đến tính năng hiện tại)

### Quan hệ phụ thuộc:
```
one_vnu_appstore → vnu_core, vnu_noi_tru
vnu_noi_tru → vnu_core
```

---

## 1.2 State Management

### Pattern chính: **Cubit** (flutter_bloc)
- GetX cũng được dùng cho DI và navigation (`Get.put`, `Get.to`)
- Cubit là pattern chính cho business logic

### File Cubit mẫu:
- `vnu_noi_tru/lib/cubit/nt_register_cubit.dart`
- Class: `NtRegisterCubit extends Cubit<NtRegisterState>`

### Cấu trúc State class:
- **KHÔNG dùng freezed** cho state đã có
- Dùng **abstract class + subclasses** truyền thống
- Mỗi trạng thái là class riêng: `NtRegisterInitial`, `NtRegisterLoading`, `NtRegisterShowHub`, `NtRegisterDismissHub`, `NtRegisterLoadedError(message)`, etc.
- State dùng `@immutable` annotation
- Dùng `part of` directive (state file là part of cubit file)

### Repository pattern: **CÓ**
- `NoitruDormitoryRepository` — singleton pattern
- `NoiTruRepository` — singleton pattern
- Cả hai dùng `DioOptions().createDio(baseUrl)` để tạo Dio client

### BlocProvider:
- Wrap ở **page level** — mỗi screen tạo `BlocProvider` riêng

---

## 1.3 Module Nội Trú Hiện Có

### Cấu trúc thư mục vnu_noi_tru:
```
vnu_noi_tru/lib/
├── common/              → enum.dart
├── cubit/
│   ├── nt_news_cubit.dart + state
│   └── nt_register_cubit.dart + state
├── data/
│   ├── noitru_api.dart (Retrofit)
│   ├── noitru_reponse_domitory.dart (Response wrapper dormitory API)
│   ├── noitru_response.dart (Response wrapper news/thongbao API)
│   └── requests/
│       └── luu_noi_tru_request.dart
├── models/              → 17 model files
├── modules/boarding/    → controllers + views
├── repository/
│   ├── noitru_repository.dart (news, thongbao)
│   └── noitru_dormitory_repository.dart (đăng ký nội trú)
├── screens/             → 8 screen files
├── widgets/             → 9 widget files
├── nt_globals.dart
└── vnu_noi_tru.dart     → barrel export (singleton VNUNoiTru)
```

### Các màn hình đã có:
- `nt_home_screen.dart` — Trang chủ nội trú
- `nt_dang_ky_noi_tru_screen.dart` — Đăng ký nội trú (screen hiện tại)
- `nt_chitiet_thong_tin_noi_tru_screen.dart` — Chi tiết
- `nt_register_process_screen.dart` — Quá trình xử lý
- `nt_tabbar_screen.dart` — TabBar screen
- `nt_left_menu_screen.dart` — Menu trái
- `nt_notify_screen.dart` / `nt_notify_list_screen.dart` — Thông báo

### Route pattern:
- Sử dụng **GetX navigation** (`Get.to`, `Get.put`)
- Không dùng go_router hay AutoRoute
- Entry point: `VNUNoiTru()` singleton class từ `vnu_noi_tru.dart`

---

## 1.4 HTTP / API Layer

### HTTP client: **Dio** + **Retrofit**
- API file chính: `vnu_noi_tru/lib/data/noitru_api.dart`
- Class: `NoiTruApiProvider` (Retrofit `@RestApi()`)
- Generated file: `noitru_api.g.dart`

### Base URL config:
- **Dormitory API (cũ):** `kBaseUrlDormitory = "https://onevnu-mobile-api.vnu.edu.vn/api-dms/api/v1/"`
  - File: `vnu_core/lib/constants/config.dart`
- **Dormitory API (mới — runbook):** `https://ktx.sohatech.vn/api/dormitory/`
  - ⚠️ API mới khác hoàn toàn với API cũ

### Auth method: **Bearer token**
- Token lưu trong `Globals().token` (memory — singleton)
- Token cũng lưu vào `SecureStorage` qua key `kLoginToken`
- Interceptor: `ApiInterceptor` trong `vnu_core/lib/services/dio_options.dart`
- Interceptor xử lý: token inject + 401 handling + connectivity check

### DioOptions:
```dart
class DioOptions {
  Dio createDio(String baseUrl) {
    Dio client = Dio()
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = Duration(seconds: 60)
      ..interceptors.addAll([
        ApiInterceptor(),     // Token Bearer inject
        TalkerDioLogger(...), // Logging
      ]);
    // Bad certificate bypass
    return client;
  }
}
```

### Cách tạo request mẫu (từ NoitruDormitoryRepository):
```dart
_dio = DioOptions().createDio(kBaseUrlDormitory);
_apiClient = NoiTruApiProvider(_dio);
// Gọi API:
var response = await _apiClient.getDanhSachDotDangKy();
```

### Response wrapper:
- `NoitruResponseDomitory<T>` — cho dormitory API
  - Fields: `resultCode (int?)`, `resultMessage (String?)`, `data (T)`
  - Converter xử lý generic type → fromJson
- `NoiTruResponse<T>` — cho news/thongbao API
  - Fields: `resultCode (String?)`, `resultMessage (String?)`, `data (T)`

---

## 1.5 Widget & Theme Inventory

### Colors (AppTheme — `vnu_core/lib/themes/app_theme.dart`):
| Constant | Hex | Mô tả |
|---|---|---|
| `backgroundColor` | #F6F9FE | Background chính |
| `backgroundBlueColor` | #003392 | Blue chính (Primary) |
| `white` | #FFFFFF | White |
| `nearlyWhite` | #FAFAFA | Near white |
| `spacer` | #F2F2F2 | Spacer |
| `borderColor` | #D6DADE | Border |
| `textTitleColor` | #212944 | Text title |
| `textColor` | #2A3556 | Text chính |
| `textSubColor` | #777B89 | Text phụ |
| `textHighLightColor` | #4188F1 | Text highlight |
| `colorMain` | #007F3E | Green chính |
| `colorWarning` | #F89C23 | Warning |
| `colorError` | Colors.red | Error |
| `colorSuccess` | #43A047 | Success |
| `colorLightBlue` | #4188F1 | Light blue |
| `activeGreen` | #22C55E | Active green |

### AppColor (vnu_core/lib/common/app_color.dart):
| Constant | Hex |
|---|---|
| `bgColor` | #F6F9FE |
| `bgChildColor` | #002770 |
| `textBlueColor` | #003392 |
| `greenColor` | #00B247 |

### Text Styles (AppTheme):
- Font: `OpenSans`
- `display1`: 36px bold
- `headline5`: 24px
- `headline6`: 24px w500
- `subtitle1`: 16px normal
- `subtitle2`: 14px w500
- `body1`: 16px normal
- `body2`: 14px normal (dùng nhiều nhất)
- `caption`: 12px
- `button`: 14px w500

### Widgets tái sử dụng:

| Widget | Class | File | Params |
|---|---|---|---|
| Blue Button | `BlueButton` | `vnu_core/lib/widgets/buttons_widget.dart` | `title, action, padding?, width?, height?, isShowLoading?, bgColor?` |
| White Button | `WhiteButton` | `vnu_core/lib/widgets/buttons_widget.dart` | `title, action, padding?, width?, height?` |
| Progress HUD | `ProgressHubWidget` | `vnu_core/lib/widgets/progress_hub_widget.dart` | `child, contextComplete?` |
| Empty Data | `EmptyDataWidget` | `vnu_core/lib/widgets/empty_data_widget.dart` | none |
| Loading Overlay | `LoadingOverlay` | `vnu_core/lib/widgets/loading_overlay.dart` | `isLoading, child, opacity?, color?, progressIndicator?` |
| Loading Indicator | `LoadingIndicator` | `vnu_core/lib/widgets/loading_indicator.dart` | `height?, radius?, color?` |
| Module Scaffold | `VcoreModuleScaffold` | `vnu_core/lib/widgets/vcore_module_scaffold.dart` | - |
| Dropdown (nội trú) | `NtDropboxWidget` | `vnu_noi_tru/lib/widgets/nt_dropbox_widget.dart` | - |
| Container Dropbox | `NtContainerDropboxWidget` | `vnu_noi_tru/lib/widgets/nt_container_dropbox_widget.dart` | - |
| File Upload Widget | `NtFileDaUploadWidget` | `vnu_noi_tru/lib/widgets/nt_file_da_upload_widget.dart` | - |
| Register CMND | `NtRegisterCmndWidget` | `vnu_noi_tru/lib/widgets/nt_register_cmnd_widget.dart` | - |
| Register Image | `NtRegisterImageWidget` | `vnu_noi_tru/lib/widgets/nt_register_image_widget.dart` | - |

### Snackbar helper:
- Không tìm thấy custom snackbar helper riêng
- Dùng `ScaffoldMessenger.of(context).showSnackBar()` trực tiếp hoặc `Get.snackbar()`

### AppBar:
- Dùng `AppBar()` mặc định của Flutter Material
- Không có custom AppBar class riêng

---

## 1.6 User/Student Data

### StudentInfoModel:
- **File:** `vnu_core/lib/models/student_info_model.dart`
- **Cách lấy:** `Globals().thongTinSinhVienModel.value`
- **Reactive:** `Rxn<StudentInfoModel>` (GetX observable)

### Các field có sẵn (map vào student payload):
| Field cần | Field có trong StudentInfoModel | JSON key |
|---|---|---|
| student_code (mã SV) | ✅ `maSinhVien` | `maSinhVien` |
| full_name (họ tên) | ✅ `hoVaTen` | `hoVaTen` |
| dob (ngày sinh) | ✅ `ngaySinh` (DateTime?) | `ngaySinh` |
| gender (giới tính) | ✅ `gioiTinh` | `gioiTinh` |
| cccd (CCCD) | ✅ `soCmtCccd` | `soCMT_CCCD` |
| cccd_issue_date | ✅ `ngayCapCmtCccd` (DateTime?) | `ngayCapCMT_CCCD` |
| phone | ✅ `mobile` / `tel` | `mobile` / `tel` |
| email | ✅ `email` | `email` |
| hometown (quê quán) | ✅ `idQueQuanTinhThanhPho` | `idQueQuan_TinhThanhPho` |
| class (lớp) | ❌ KHÔNG CÓ trực tiếp — cần từ `LopDaoTaoModel` via `Globals().lopDaoTaoModel` |
| major (ngành) | ❌ KHÔNG CÓ trực tiếp — cần từ `idNganhDaoTao` reference |
| academic_year (niên khóa) | ❌ KHÔNG CÓ trực tiếp — cần từ `NienKhoaDaoTaoModel` |
| system (hệ đào tạo) | ❌ KHÔNG CÓ trực tiếp — cần từ `idHeDaoTao` reference |
| level (bậc) | ❌ KHÔNG CÓ trực tiếp — cần từ `idBacDaoTao` reference |
| university_name | ❌ KHÔNG CÓ trực tiếp — cần từ `guidDonVi` reference |
| temporary_address | ⚠️ Có `noiOHienNaySoNha` + `noiOHienNayDuongThon` + ... |

### CurrentUserModel:
- **File:** `vnu_core/lib/models/current_user_model.dart`
- **Cách lấy:** `Globals().currentUserModel.value`
- Fields: `tenDangNhap, hoVaTen, email, soDienThoai, ngaySinh, gioiTinh, guidDonVi, guid`

### Cách lấy CMND/CCCD cho đăng ký:
```dart
String cmndCccd = await VnuCore().getLoginUserName() ?? '';
```
*(Hiện tại `nt_register_cubit.dart` dùng cách này)*

---

## 2.0 API — CHẶN

> ⚠️ **KHÔNG THỂ TIẾP TỤC PHASE 2**
> 
> Runbook yêu cầu gọi API tại `https://ktx.sohatech.vn/api/dormitory/` nhưng cần `DORMITORY_API_TOKEN`.
> Agent không có token này.
> 
> **Lưu ý quan trọng:** API mới trong runbook (`https://ktx.sohatech.vn/api/dormitory/`) hoàn toàn KHÁC với API cũ đang dùng (`https://onevnu-mobile-api.vnu.edu.vn/api-dms/api/v1/css/`).
> - API cũ: endpoints dạng `css/danhSachTrungTamLuuTru`, `css/luuDangKyNoiTru`
> - API mới: endpoints dạng `/registration-periods`, `/list`, `/room-types`
> - Response format hoàn toàn khác (API cũ dùng PascalCase JSON keys, API mới có thể dùng snake_case)
> 
> → Cần dev xác nhận: chỉ dùng API MỚI hay cần hỗ trợ cả API CŨ?

---

## 2.1–2.9 API Exploration

**Chờ dev cung cấp token để thực hiện.**

Sections cần điền:
- 2.1 GET /registration-periods
- 2.2 GET /list (Dormitories)
- 2.3 GET /room-types
- 2.4 GET /priority-objects
- 2.5 GET /registrations/me
- 2.6 POST /attachments/upload
- 2.7 POST /registrations (dry run)
- 2.8 GET /registrations/{id}/histories
- 2.9 Error format

---

## 3.1 Placement Decision (DỰ KIẾN — dựa trên codebase hiện có)

### Repository / Data layer:
- `DormitoryRegistrationRepository` đặt trong: **vnu_noi_tru**
- Lý do: module nội trú riêng biệt, tất cả repository dormitory đã ở đây
- Extend từ: **Tự tạo mới** (singleton pattern giống `NoitruDormitoryRepository`)
- Sử dụng HTTP client: `DioOptions().createDio(newBaseUrl)` từ `vnu_core/services/dio_options.dart`
- Auth token: tự động inject qua `ApiInterceptor` (đọc từ `Globals().token`)

### State Management:
- Dùng: **Cubit** (theo pattern đã có)
- `DormitoryRegistrationCubit extends Cubit<DormitoryRegistrationState>`
- State: **abstract class + subclasses** (theo pattern hiện có — KHÔNG dùng freezed)
- Đặt trong: `vnu_noi_tru/lib/cubit/`

### UI / Views:
- Đặt trong: `vnu_noi_tru/lib/screens/` và `vnu_noi_tru/lib/widgets/`
- Widget dùng lại:
  - Button: `BlueButton` / `WhiteButton` từ `package:vnu_core/widgets/buttons_widget.dart`
  - TextField: Flutter `TextFormField` mặc định (không có custom widget)
  - Loading: `ProgressHubWidget` từ `package:vnu_core/widgets/progress_hub_widget.dart`
  - AppBar: Flutter `AppBar` mặc định
  - Snackbar: `Get.snackbar()` hoặc `ScaffoldMessenger`
  - Empty: `EmptyDataWidget` từ `package:vnu_core/widgets/empty_data_widget.dart`
  - Loading Overlay: `LoadingOverlay` từ `package:vnu_core/widgets/loading_overlay.dart`
  - Dropdown: `NtDropboxWidget` / `NtContainerDropboxWidget` (hiện có trong vnu_noi_tru)

### Routes:
- Dùng **GetX navigation** (`Get.to()`)
- Expose từ package qua `VNUNoiTru` singleton class
- Route mới thêm trực tiếp vào navigation call

### Models — CHƯA XÁC ĐỊNH (cần Phase 2)
> Tên field thực tế từ API mới chưa biết. Cần gọi API để xác định JSON keys.

### Models CŨ đã có (tham khảo):
```
DanhSachDotDangKyLuuTru: id (int?), ID_DotDangKy (int?), tenDotDangKy (String?)
DanhSachTrungTamLuuTru: id (int?), ID_TrungTamLuuTru (int?), tenTrungTamLuuTru (String?)
DanhSachDoiTuongUuTien: id (int?), ID_DotDangKy (int?), tenDoiTuongUuTien (String?), prefix (String?)
DanhSachLoaiPhong: id (int?), ID_LoaiPhong (int?), tenLoaiPhong (String?), danhSachLoaiPhi, danhSachLoaiCoSoVatChat
LuuNoiTruRequest: CMND_CCCD, ID_DoiTuongUuTien (List<int>), TrangThai (int), ID_DotDangKy, ID_TrungTamLuuTru, ID_LoaiPhong, FilesDinhKem (List<int>)
NtUrlPresignedModel: FileId (int?), UploadUrl (String?)
DanhSachQuaTrinhXuLy: Id, DonViXuLy, NguoiXuLy, ThoiGian, NoiDung, TrangThai
```

---

## 3.2 Checklist sẵn sàng code

### Pre-code Checklist

#### Codebase:
- [x] Đã biết package chứa Repository (vnu_noi_tru)
- [x] Đã đọc ít nhất 1 Repository mẫu (NoitruDormitoryRepository) và biết cách dùng HTTP client
- [x] Đã biết state management pattern (Cubit + abstract state classes)
- [x] Đã đọc ít nhất 1 Cubit/State mẫu (NtRegisterCubit/NtRegisterState) → dùng subclasses, KHÔNG freezed
- [x] Đã biết route: GetX navigation (Get.to)
- [x] Đã biết AppTheme class (backgroundBlueColor = #003392)
- [x] Đã biết button widgets: BlueButton, WhiteButton
- [x] Đã biết TextField: dùng Flutter TextFormField mặc định
- [x] Đã biết Loading: ProgressHubWidget, LoadingOverlay, LoadingIndicator
- [x] Đã biết Snackbar: Get.snackbar() hoặc ScaffoldMessenger
- [x] Đã biết AppBar: Flutter AppBar mặc định
- [x] Đã biết user model có fields: maSinhVien, hoVaTen, ngaySinh, gioiTinh, soCmtCccd, mobile, email

#### API:
- [ ] ❌ Chưa gọi GET /registration-periods — cần token
- [ ] ❌ Chưa gọi GET /list — cần token
- [ ] ❌ Chưa gọi GET /room-types — cần token
- [ ] ❌ Chưa gọi GET /priority-objects — cần token
- [ ] ❌ Chưa gọi GET /registrations/me — cần token
- [ ] ❌ Chưa gọi POST /attachments/upload — cần token
- [ ] ❌ Chưa gọi POST /registrations — cần token
- [ ] ❌ Chưa biết error response format
- [ ] ❌ Chưa biết date format API dùng
- [ ] ❌ Chưa biết gender values API chấp nhận
- [ ] ❌ Chưa biết attachment type values hợp lệ

#### Quyết định:
- [x] Đã ghi rõ đặt code ở package nào cho từng layer
- [x] Đã ghi rõ dùng widget nào
- [ ] ❌ Model field names chưa xác định (chưa có response thực tế)
- [ ] ❌ DISCOVERY_REPORT chưa đầy đủ sections Phase 2
