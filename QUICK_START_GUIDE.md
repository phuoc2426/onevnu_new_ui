# 🚀 Quick Start Guide - Bắt Đầu Nhanh

**Cho developer mới - Cần biết ngay!**

---

## ⚡ Top 5 Điều Cần Biết Trước

1. **Dự án là Flutter monorepo** - Có 3 modules chính
2. **vnu_core là bộ khung chung** - Tái sử dụng được
3. **Dùng Cubit cho state management** - Không dùng setState
4. **Repository pattern** - Tách UI và data logic
5. **Log everything** - Sử dụng `logInfo()`, `logError()` từ vnu_core

---

## 📁 Cấu Trúc Dự Án (30 giây hiểu)

```
iworkspace_mobile_onevnu/
├── one_vnu_appstore/     ← Main app (sử dụng others)
├── vnu_core/             ← Core module (reusable) ⭐
├── vnu_noi_tru/          ← Feature module (Nội trú)
└── inmapz/               ← Map module
```

---

## 🎯 Công Việc Thường Ngày

### **Viết chức năng mới:**

```dart
// 1. Tạo Cubit + State
// 2. Tạo Repository (nếu cần API)
// 3. Tạo Screen/Widget
// 4. Sử dụng trong main app
```

### **Sử dụng vnu_core utilities:**

```dart
import 'package:vnu_core/common/log.dart';
logInfo('message');

import 'package:vnu_core/common/app_color.dart';
Container(color: AppColor.primary);

import 'package:vnu_core/common/local_storage.dart';
await localStorage.save('key', 'value');
```

### **State management (Cubit):**

```dart
// Cubit
class MyCubit extends Cubit<MyState> {
  MyCubit() : super(const MyState.initial());
  
  void doSomething() {
    emit(const MyState.loading());
    // Do work...
    emit(const MyState.success(data));
  }
}

// Screen
BlocBuilder<MyCubit, MyState>(
  builder: (context, state) {
    return state.when(
      initial: () => Text('Init'),
      loading: () => CircularProgressIndicator(),
      success: (data) => Text('$data'),
    );
  },
)
```

---

## 🔥 Must Know Files

| File | Bạn sẽ dùng | Bên trong |
|------|-----------|----------|
| `log.dart` | ✅✅✅ | Logging |
| `app_color.dart` | ✅✅✅ | Colors |
| `app_text_styles.dart` | ✅✅ | Text styles |
| `local_storage.dart` | ✅✅ | Save/read data |
| `*_cubit.dart` | ✅✅✅ | State management |
| `*_model.dart` | ✅✅ | Data structures |
| `*_repository.dart` | ✅✅ | Data access |

---

## 📝 Code Template (Copy-Paste)

### **Cubit Mới:**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_cubit_state.freezed.dart';

@freezed
class MyState with _$MyState {
  const factory MyState.initial() = _Initial;
  const factory MyState.loading() = _Loading;
  const factory MyState.success(List<String> data) = _Success;
  const factory MyState.error(String message) = _Error;
}

class MyCubit extends Cubit<MyState> {
  MyCubit() : super(const MyState.initial());

  Future<void> loadData() async {
    emit(const MyState.loading());
    try {
      // TODO: Add your logic
      emit(const MyState.success([]));
    } catch (e) {
      emit(MyState.error(e.toString()));
    }
  }
}
```

### **Screen Mới:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'my_cubit.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: BlocBuilder<MyCubit, MyState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const Center(child: CircularProgressIndicator()),
            success: (data) => ListView(
              children: data.map((e) => Text(e)).toList(),
            ),
            error: (message) => Center(child: Text('Error: $message')),
          );
        },
      ),
    );
  }
}
```

### **Model Mới:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_model.freezed.dart';
part 'my_model.g.dart';

@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    required String name,
    String? description,
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
}
```

---

## 🛠️ Setup Lần Đầu (5 phút)

```bash
# 1. Clone
git clone <repo>

# 2. Get dependencies
cd one_vnu_appstore
flutter pub get

# 3. Generate code (nếu cần)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run
flutter run
```

---

## 🚦 Workflow Viết Feature Mới

### **Bước 1: Tạo file cấu trúc**
```
features/my_new_feature/
├── cubit/
│   ├── my_new_feature_cubit.dart
│   └── my_new_feature_state.dart
├── models/
│   └── my_model.dart
├── screens/
│   └── my_screen.dart
└── widgets/
    └── my_widget.dart
```

### **Bước 2: Viết Model**
```dart
// my_model.dart
// Copy template từ trên
```

### **Bước 3: Viết State**
```dart
// my_feature_state.dart
@freezed
class MyFeatureState with _$MyFeatureState {
  // Define states
}
```

### **Bước 4: Viết Cubit**
```dart
// my_feature_cubit.dart
class MyFeatureCubit extends Cubit<MyFeatureState> {
  // Business logic
}
```

### **Bước 5: Viết Screen**
```dart
// my_screen.dart
class MyScreen extends StatelessWidget {
  // UI using BlocBuilder
}
```

### **Bước 6: Gunakan di main app**
```dart
// one_vnu_appstore/lib/main.dart
// Add route & provider
```

---

## 🐛 Debugging

### **Logging (Everywhere!):**
```dart
import 'package:vnu_core/common/log.dart';

logInfo('This is info');
logError('This is error');
logSuccess('This is success');
logWarning('This is warning');
```

### **Check Network:**
```dart
import 'package:vnu_core/common/network_monitor.dart';

final isOnline = NetworkMonitor().isConnected;
```

### **Check State:**
```dart
// Gunakan DevTools
# flutter pub global activate devtools
# devtools
```

---

## ⚠️ Top Mistakes (Hindari!)

❌ **Menaruh logic di UI**
```dart
// ❌ BAD
ElevatedButton(
  onPressed: () async {
    final data = await http.get(url);
    // ... process in UI
  },
)

// ✅ GOOD
ElevatedButton(
  onPressed: () {
    context.read<MyCubit>().loadData();
  },
)
```

❌ **Tidak handle errors**
```dart
// ❌ BAD
final data = await api.fetch(); // Silent fail?

// ✅ GOOD
try {
  emit(const State.loading());
  final data = await api.fetch();
  emit(State.success(data));
} catch (e) {
  emit(State.error(e.toString()));
}
```

❌ **Duplicate code**
```dart
// ❌ BAD
Text('Title', style: TextStyle(fontSize: 20));
Text('Subtitle', style: TextStyle(fontSize: 20));

// ✅ GOOD
import 'package:vnu_core/common/app_text_styles.dart';
Text('Title', style: AppTextStyle.title);
Text('Subtitle', style: AppTextStyle.subtitle);
```

---

## 📚 Dokumentasi File

| File | Apa Itu |
|------|--------|
| `ONBOARDING_GUIDE_VN.md` | 📖 Panduan lengkap (baca ini dulu!) |
| `PATTERNS_AND_BEST_PRACTICES.md` | 🏛️ Architecture patterns |
| `FILE_STRUCTURE_GUIDE.md` | 📁 Detail setiap file/folder |
| `CODE_EXAMPLES.md` | 💻 Contoh code nyata |
| `QUICK_START_GUIDE.md` | 🚀 Panduan ini (cepat!) |

---

## 🆘 Bantuan Cepat

### **Q: Dimana tempat untuk utilities?**
A: Di `vnu_core/lib/common/`

### **Q: Bagaimana manage state?**
A: Gunakan Cubit + Freezed (lihat CODE_EXAMPLES.md)

### **Q: Bagaimana handle API?**
A: Gunakan Repository pattern (lihat CODE_EXAMPLES.md)

### **Q: Dimana widgets reusable?**
A: Di `vnu_core/lib/widgets/` atau `modules/*/views/`

### **Q: Bagaimana reuse code di module lain?**
A: Import dari `vnu_core` atau package lain

### **Q: Error "No provider found"?**
A: Pastikan Cubit/Provider di-register di main app

---

## 🎓 Checklist Onboarding

- [ ] Baca ONBOARDING_GUIDE_VN.md
- [ ] Pahami struktur monorepo
- [ ] Tahu vnu_core = reusable framework
- [ ] Bisa membuat Cubit + State
- [ ] Bisa membuat Screen sederhana
- [ ] Bisa sử dụng utilities dari vnu_core
- [ ] Bisa handle API dengan Repository
- [ ] Bisa debug dengan log
- [ ] Mengerti error handling
- [ ] Siap coding feature baru!

---

## 🚀 Next Steps

1. **Baca ONBOARDING_GUIDE_VN.md** - Pahami big picture
2. **Lihat CODE_EXAMPLES.md** - Contoh nyata
3. **Explore vnu_core/** - Pelajari utilities
4. **Buat feature kecil** - Practice
5. **Tanya senior** - Jika bingung

---

**Selamat datang ke ONE VNU Project! 👋**

**Punya pertanyaan? Baca dokumentasi yang relevan atau tanya senior! 💪**
