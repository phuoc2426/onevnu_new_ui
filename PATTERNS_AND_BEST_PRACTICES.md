# 🎯 Patterns & Best Practices - ONE VNU Project

**Cập nhật:** 12/11/2025

---

## 📌 Mục Lục

1. [Architecture Pattern](#architecture-pattern)
2. [State Management Pattern](#state-management-pattern)
3. [Repository Pattern](#repository-pattern)
4. [Naming Conventions](#naming-conventions)
5. [Folder Structure](#folder-structure)
6. [Common Mistakes to Avoid](#common-mistakes-to-avoid)

---

## 🏛️ Architecture Pattern

Dự án sử dụng **Clean Architecture** với **Layered Architecture**:

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │  ← Screens, Widgets, UI
│        (UI + State Management)          │
├─────────────────────────────────────────┤
│         Domain Layer                    │  ← Models, Entities
├─────────────────────────────────────────┤
│      Repository Pattern Layer           │  ← Data logic
├─────────────────────────────────────────┤
│         Data Layer                      │  ← API, Local Storage
│     (API, Database, SharedPrefs)        │
└─────────────────────────────────────────┘
```

### **Các Layer:**

#### **1. Presentation Layer**
- **Screens** (Màn hình)
- **Widgets** (Component UI)
- **Cubits** (State management)

#### **2. Domain Layer**
- **Models** (Dữ liệu entities)
- **DTOs** (Data Transfer Objects)

#### **3. Repository Layer**
- **Repository** classes
- Combine API & Local data sources

#### **4. Data Layer**
- **API Client** (Retrofit)
- **Local Storage** (SharedPrefs, SQLite)
- **Network Services**

---

## 🎮 State Management Pattern

### **Cubit Pattern (Sử dụng trong dự án)**

**File Structure:**
```
feature/
├── cubits/
│   ├── feature_cubit.dart
│   └── feature_state.dart
└── screens/
    └── feature_screen.dart
```

**Example: News Cubit**

```dart
// File: vnu_noi_tru/lib/cubit/nt_news_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

class NtNewsCubit extends Cubit<NtNewsState> {
  final NtRepository repository;

  NtNewsCubit(this.repository) : super(const NtNewsState.initial());

  Future<void> fetchNews() async {
    try {
      emit(const NtNewsState.loading());
      final data = await repository.getNews();
      emit(NtNewsState.success(data));
    } catch (e) {
      emit(NtNewsState.error(e.toString()));
    }
  }
}

// File: vnu_noi_tru/lib/cubit/nt_news_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'nt_news_state.freezed.dart';

@freezed
class NtNewsState with _$NtNewsState {
  const factory NtNewsState.initial() = _Initial;
  const factory NtNewsState.loading() = _Loading;
  const factory NtNewsState.success(List<NtNews> data) = _Success;
  const factory NtNewsState.error(String message) = _Error;
}
```

**Sử dụng trong UI:**

```dart
// Listener approach
BlocListener<NtNewsCubit, NtNewsState>(
  listener: (context, state) {
    state.whenOrNull(
      success: (data) => print('Got ${data.length} news'),
      error: (message) => showErrorDialog(context, message),
    );
  },
  child: const NewsView(),
);

// Builder approach
BlocBuilder<NtNewsCubit, NtNewsState>(
  builder: (context, state) {
    return state.when(
      initial: () => const SizedBox.shrink(),
      loading: () => const LoadingWidget(),
      success: (data) => NewsListWidget(news: data),
      error: (message) => ErrorWidget(message: message),
    );
  },
);
```

---

## 🗄️ Repository Pattern

### **Cấu Trúc Repository**

```dart
// File: vnu_noi_tru/lib/repository/noitru_repository.dart
class NtRepository {
  final NtApi api;
  final LocalStorage localStorage;

  NtRepository({
    required this.api,
    required this.localStorage,
  });

  // Method để lấy dữ liệu từ API hoặc cache
  Future<List<NtNews>> getNews() async {
    try {
      // 1. Thử lấy từ API
      final response = await api.getNews();
      
      // 2. Cache kết quả cục bộ
      await localStorage.save('news_cache', response);
      
      return response;
    } catch (e) {
      // 3. Nếu API fail, lấy từ cache
      final cached = await localStorage.read('news_cache');
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }
}
```

### **Best Practice:**

1. **Repository điều phối** API calls và local storage
2. **Không mix** business logic giữa UI và repository
3. **Xử lý lỗi** ở repository layer
4. **Cache data** whenever possible

---

## ✍️ Naming Conventions

### **File Naming:**

| Loại | Quy ước | Ví dụ |
|------|--------|-------|
| Screens | `{feature}_screen.dart` | `nt_home_screen.dart` |
| Widgets | `{feature}_widget.dart` | `nt_boarding_item_widget.dart` |
| Cubits | `{feature}_cubit.dart` | `nt_news_cubit.dart` |
| States | `{feature}_state.dart` | `nt_news_state.dart` |
| Models | `{feature}_model.dart` | `nt_tin_tuc_model.dart` |
| Services | `{feature}_service.dart` | `auth_service.dart` |
| Repository | `{feature}_repository.dart` | `noitru_repository.dart` |

### **Class Naming:**

| Loại | Quy ước | Ví dụ |
|------|--------|-------|
| Screens | `{Feature}Screen` | `NtHomeScreen` |
| Widgets | `{Feature}Widget` | `NtBoardingItemWidget` |
| Cubits | `{Feature}Cubit` | `NtNewsCubit` |
| States | `{Feature}State` | `NtNewsState` |
| Models | `{Feature}Model` | `NtTinTucModel` |
| Services | `{Feature}Service` | `AuthService` |
| Repository | `{Feature}Repository` | `NtRepository` |

### **Variable Naming:**

```dart
// Good ✅
final userData = user.data;
final isLoading = true;
final newsList = [];

// Bad ❌
final userdata = user.data;
final loading = true;
final list = [];
```

### **Package Naming (Vietnamese):**

```
vnu_core           ← Core/base features
vnu_noi_tru        ← Nội trú (Dormitory)
```

---

## 📁 Folder Structure

### **Module-Based Structure:**

```
your_feature_module/
├── lib/
│   ├── common/                      # Enums, constants cho feature này
│   │   └── enum.dart
│   ├── cubit/                       # State management
│   │   ├── your_feature_cubit.dart
│   │   └── your_feature_state.dart
│   ├── data/                        # API & Request models
│   │   ├── your_api.dart
│   │   ├── your_response.dart
│   │   └── requests/
│   │       └── your_request.dart
│   ├── models/                      # Data models/entities
│   │   ├── your_model.dart
│   │   └── your_dto.dart
│   ├── modules/                     # Feature sub-modules
│   │   └── sub_feature/
│   │       ├── controllers/
│   │       ├── bindings/
│   │       └── views/
│   ├── repository/                  # Data repository
│   │   └── your_repository.dart
│   ├── screens/                     # Full page screens
│   │   └── your_screen.dart
│   ├── widgets/                     # Reusable widgets
│   │   └── your_widget.dart
│   ├── your_feature.dart            # Main entry point
│   ├── your_globals.dart            # Global variables
│   └── your_method_channel.dart     # Native integration
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

### **Quy tắc tổ chức:**

1. **Separate concerns** - mỗi file có một trách nhiệm
2. **Group by feature** - nhóm theo tính năng, không phải theo loại file
3. **Keep it flat** - tránh nesting quá sâu (max 3 levels)

---

## ⚠️ Common Mistakes to Avoid

### **❌ Mistake 1: Mixing Business Logic with UI**

```dart
// ❌ BAD
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            // API call trực tiếp trong UI
            final response = await http.get('api/url');
            final json = jsonDecode(response.body);
            // Parse data...
          },
          child: const Text('Load'),
        ),
      ],
    );
  }
}

// ✅ GOOD
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyFeatureCubit, MyFeatureState>(
      builder: (context, state) {
        return Column(
          children: [
            ElevatedButton(
              onPressed: () {
                context.read<MyFeatureCubit>().fetchData();
              },
              child: const Text('Load'),
            ),
          ],
        );
      },
    );
  }
}
```

### **❌ Mistake 2: Not Handling Async/Await**

```dart
// ❌ BAD
void loadData() {
  repository.getData(); // Ignoring Future
  // Code executes before data is loaded
}

// ✅ GOOD
Future<void> loadData() async {
  final data = await repository.getData();
  // Code executes after data is loaded
}
```

### **❌ Mistake 3: Not Using Proper Error Handling**

```dart
// ❌ BAD
try {
  final data = await api.fetchData();
} catch (e) {
  print(e); // Silent fail
}

// ✅ GOOD
try {
  final data = await api.fetchData();
} catch (e) {
  logError('Error fetching data: $e');
  emit(state.copyWith(error: e.toString()));
}
```

### **❌ Mistake 4: Duplicate Code**

```dart
// ❌ BAD - Duplicate
ElevatedButton(
  onPressed: () { /* Logic A */ },
  child: const Text('Button 1'),
);
ElevatedButton(
  onPressed: () { /* Similar Logic */ },
  child: const Text('Button 2'),
);

// ✅ GOOD - Extract to Widget
class MyButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const MyButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
```

### **❌ Mistake 5: Improper State Management**

```dart
// ❌ BAD - setState in StatefulWidget
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  List<String> items = [];

  void loadItems() {
    setState(() {
      items = newItems; // Causes UI rebuild
    });
  }
}

// ✅ GOOD - Use Cubit
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemsCubit, ItemsState>(
      builder: (context, state) {
        // Automatically updates when state changes
        return ListView(
          children: state.items.map((item) => Text(item)).toList(),
        );
      },
    );
  }
}
```

### **❌ Mistake 6: Poor Naming**

```dart
// ❌ BAD
final d = data; // What is 'd'?
final x = 10;  // Meaningless
void f() {} // What does 'f' do?

// ✅ GOOD
final userData = fetchedData;
final itemCount = 10;
void loadUserProfile() {}
```

### **❌ Mistake 7: Not Using Extensions**

```dart
// ❌ BAD - Duplicate formatting
Text(DateFormat('dd/MM/yyyy').format(date1));
Text(DateFormat('dd/MM/yyyy').format(date2));
Text(DateFormat('dd/MM/yyyy').format(date3));

// ✅ GOOD - Use extension
extension DateTimeExt on DateTime {
  String toFormattedString() {
    return DateFormat('dd/MM/yyyy').format(this);
  }
}

// Usage
Text(date1.toFormattedString());
Text(date2.toFormattedString());
Text(date3.toFormattedString());
```

### **❌ Mistake 8: Not Using Repository Pattern**

```dart
// ❌ BAD - Multiple sources of truth
class UserCubit extends Cubit<UserState> {
  @override
  Future<void> fetchUser() async {
    // Sometimes use SharedPrefs
    final cached = await sharedPrefs.get('user');
    
    // Sometimes use API
    final user = await api.getUser();
  }
}

// ✅ GOOD - Single source of truth
class UserCubit extends Cubit<UserState> {
  final UserRepository repository;

  @override
  Future<void> fetchUser() async {
    final user = await repository.getUser();
  }
}
```

---

## 📚 References & Examples

### **Xem các file ví dụ trong dự án:**

- **Cubit Example:** `vnu_noi_tru/lib/cubit/nt_news_cubit.dart`
- **Repository Example:** `vnu_noi_tru/lib/repository/noitru_repository.dart`
- **Model Example:** `vnu_noi_tru/lib/models/nt_tin_tuc_model.dart`
- **Screen Example:** `vnu_noi_tru/lib/screens/nt_home_screen.dart`
- **Widget Example:** `vnu_noi_tru/lib/widgets/nt_boarding_item_widget.dart`

---

## 🚀 Quick Tips

1. **Luôn sử dụng Cubit** cho state management, không dùng setState
2. **Tạo Repository** cho mỗi feature liên quan đến data
3. **Use Extensions** để tránh duplicate code
4. **Proper Error Handling** ở mọi nơi
5. **Log everything** để debugging dễ hơn
6. **Keep it simple** - KISS principle
7. **DRY** - Don't Repeat Yourself
8. **SOLID** principles

---

**Chúc bạn code vui vẻ! 💻**
