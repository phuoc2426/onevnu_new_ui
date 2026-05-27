# 📚 ONE VNU Project - Developer Documentation Index

**Buat: Developer Baru**  
**Update: 12/11/2025**  
**Bahasa: Tiếng Việt + English examples**

---

## 🎯 Mulai Dari Sini

Jika Anda adalah developer baru, ikuti urutan ini:

### **📖 WAJIB BACA (Mandatory)**

1. **[QUICK_START_GUIDE.md](QUICK_START_GUIDE.md)** ⚡ (5 menit)
   - Ringkasan singkat
   - Top 5 hal penting
   - Setup awal
   - Common mistakes
   - Quick troubleshooting

2. **[ONBOARDING_GUIDE_VN.md](ONBOARDING_GUIDE_VN.md)** 📖 (30 menit)
   - Cấu trúc proyek lengkap
   - Penjelasan setiap module
   - Stack teknologi
   - Cara reuse code
   - Utilities & helpers

3. **[PATTERNS_AND_BEST_PRACTICES.md](PATTERNS_AND_BEST_PRACTICES.md)** 🏛️ (20 menit)
   - Architecture patterns
   - State management
   - Repository pattern
   - Naming conventions
   - Common mistakes to avoid

4. **[FILE_STRUCTURE_GUIDE.md](FILE_STRUCTURE_GUIDE.md)** 📁 (15 menit)
   - Detail setiap file
   - Folder structure
   - Sering dipakai files
   - Cara menemukan kode

5. **[CODE_EXAMPLES.md](CODE_EXAMPLES.md)** 💻 (30 menit)
   - Contoh kode nyata
   - Copy-paste templates
   - Complete examples
   - Best practices code

---

## 🗂️ Struktur Dokumentasi

```
Documentation Files:
├── QUICK_START_GUIDE.md           ← Start here! (5 min)
├── ONBOARDING_GUIDE_VN.md         ← Comprehensive guide (30 min)
├── PATTERNS_AND_BEST_PRACTICES.md ← Architecture patterns (20 min)
├── FILE_STRUCTURE_GUIDE.md        ← File details (15 min)
├── CODE_EXAMPLES.md               ← Code samples (30 min)
└── DOCUMENTATION_INDEX.md         ← You are here!
```

---

## 🎓 Learning Path

### **Hari 1: Foundation (1-2 jam)**
- [ ] Baca QUICK_START_GUIDE.md
- [ ] Baca ONBOARDING_GUIDE_VN.md
- [ ] Pahami struktur folder
- [ ] Jalankan app untuk pertama kali

### **Hari 2-3: Deep Dive (2-3 jam)**
- [ ] Baca PATTERNS_AND_BEST_PRACTICES.md
- [ ] Baca FILE_STRUCTURE_GUIDE.md
- [ ] Explore kode di vnu_core/
- [ ] Explore kode di vnu_noi_tru/

### **Hari 4-5: Practice (3-4 jam)**
- [ ] Baca CODE_EXAMPLES.md
- [ ] Buat feature kecil
- [ ] Practice dengan Cubit
- [ ] Practice dengan Repository pattern

### **Minggu 2: Productive (Mulai coding!)**
- [ ] Buat feature yang ditugaskan
- [ ] Tanya senior jika bingung
- [ ] Review code dari senior
- [ ] Improve skills

---

## 📖 Panduan Per Topik

### **Saya ingin tahu tentang...**

#### **Struktur Proyek**
- 🔗 [ONBOARDING_GUIDE_VN.md → Cấu Trúc Dự Án](ONBOARDING_GUIDE_VN.md#cấu-trúc-dự-án)
- 🔗 [FILE_STRUCTURE_GUIDE.md → Folder Structure](FILE_STRUCTURE_GUIDE.md#folder-structure)

#### **vnu_core Module (Reusable Framework)**
- 🔗 [ONBOARDING_GUIDE_VN.md → vnu_core Module](ONBOARDING_GUIDE_VN.md#vnu_core-module-structure)
- 🔗 [FILE_STRUCTURE_GUIDE.md → vnu_core Detail](FILE_STRUCTURE_GUIDE.md#vnu_core-module-structure)

#### **State Management (Cubit)**
- 🔗 [PATTERNS_AND_BEST_PRACTICES.md → State Management Pattern](PATTERNS_AND_BEST_PRACTICES.md#-state-management-pattern)
- 🔗 [CODE_EXAMPLES.md → State Management Patterns](CODE_EXAMPLES.md#-state-management-patterns)

#### **Repository Pattern**
- 🔗 [PATTERNS_AND_BEST_PRACTICES.md → Repository Pattern](PATTERNS_AND_BEST_PRACTICES.md#-repository-pattern)
- 🔗 [CODE_EXAMPLES.md → Repository Pattern](CODE_EXAMPLES.md#-repository-pattern)

#### **API Integration**
- 🔗 [CODE_EXAMPLES.md → Working with APIs](CODE_EXAMPLES.md#-working-with-apis)
- 🔗 [CODE_EXAMPLES.md → Complete Repository Example](CODE_EXAMPLES.md#complete-repository-example)

#### **Membuat Feature Baru**
- 🔗 [CODE_EXAMPLES.md → Creating a New Feature Module](CODE_EXAMPLES.md#-creating-a-new-feature-module)
- 🔗 [QUICK_START_GUIDE.md → Workflow](QUICK_START_GUIDE.md#-workflow-vilis-feature-baru)

#### **Utilities & Helpers**
- 🔗 [ONBOARDING_GUIDE_VN.md → Utilities & Helpers](ONBOARDING_GUIDE_VN.md#-các-utility--helper-quan-trọng)
- 🔗 [FILE_STRUCTURE_GUIDE.md → Sering Dipakai](FILE_STRUCTURE_GUIDE.md#sering-dipakai-must-know)

#### **Naming Conventions**
- 🔗 [PATTERNS_AND_BEST_PRACTICES.md → Naming Conventions](PATTERNS_AND_BEST_PRACTICES.md#-naming-conventions)

#### **Common Mistakes**
- 🔗 [PATTERNS_AND_BEST_PRACTICES.md → Common Mistakes](PATTERNS_AND_BEST_PRACTICES.md#-common-mistakes-to-avoid)
- 🔗 [QUICK_START_GUIDE.md → Top Mistakes](QUICK_START_GUIDE.md#-top-mistakes-hindari)

#### **Debugging & Logging**
- 🔗 [QUICK_START_GUIDE.md → Debugging](QUICK_START_GUIDE.md#-debugging)

#### **Code Examples**
- 🔗 [CODE_EXAMPLES.md → All Examples](CODE_EXAMPLES.md)

---

## 🔍 Quick Reference

### **File Paling Penting di vnu_core/lib/common/**

```dart
// Logging
import 'package:vnu_core/common/log.dart';
logInfo(), logError(), logSuccess(), logWarning()

// Colors
import 'package:vnu_core/common/app_color.dart';
AppColor.primary, AppColor.white, ...

// Text Styles
import 'package:vnu_core/common/app_text_styles.dart';
AppTextStyle.title, AppTextStyle.body, ...

// Local Storage
import 'package:vnu_core/common/local_storage.dart';
LocalStorage().save(), .read(), .clear()

// Date Utilities
import 'package:vnu_core/common/datetime_utils.dart';
formatDateTime(), parseDate(), isDateExpired()

// Extensions
import 'package:vnu_core/extensions/extension_string.dart';
string.isEmail(), string.toCapitalized()
```

### **State Management Pattern (Always Use)**

```dart
// 1. Create State
@freezed class MyState with _$MyState { ... }

// 2. Create Cubit
class MyCubit extends Cubit<MyState> { ... }

// 3. Use in Widget
BlocBuilder<MyCubit, MyState>(
  builder: (context, state) {
    return state.when(
      initial: () => ...,
      loading: () => ...,
      success: (data) => ...,
      error: (message) => ...,
    );
  },
)
```

### **Repository Pattern (For Data Access)**

```dart
// Repository handle:
// 1. API calls
// 2. Local caching
// 3. Error handling
// 4. Data transformation

class MyRepository {
  final MyApi api;
  final LocalStorage storage;

  Future<List<T>> getData() async {
    try {
      final data = await api.fetch();
      await storage.save('key', data);
      return data;
    } catch (e) {
      final cached = await storage.read('key');
      if (cached != null) return cached;
      rethrow;
    }
  }
}
```

---

## 🆘 Troubleshooting

### **"Module not found" error**
```
→ Solusi: Jalankan `flutter pub get` di folder module
```

### **"No provider found" error**
```
→ Solusi: Pastikan Cubit/Provider di-register di main.dart
```

### **Build error**
```
→ Solusi: flutter clean && flutter pub get && flutter pub run build_runner build
```

### **"Freezed not generated" error**
```
→ Solusi: flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📱 Project Stack Summary

| Aspek | Yang Digunakan |
|------|--------|
| **Language** | Dart |
| **Framework** | Flutter |
| **State Management** | Cubit (BLoC) |
| **API Client** | Retrofit + Dio |
| **Data Storage** | SharedPrefs + Local Storage |
| **Immutable Models** | Freezed |
| **JSON Serialization** | json_serializable |
| **Navigation** | Get |
| **Logging** | Talker |
| **Firebase** | Analytics, Messaging, Crashlytics, Remote Config |

---

## 🚀 Getting Started (Ulang)

### **Step 1: Setup (5 menit)**
```bash
cd iworkspace_mobile_onevnu-master/one_vnu_appstore
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### **Step 2: Read Documentation (2 jam)**
1. QUICK_START_GUIDE.md
2. ONBOARDING_GUIDE_VN.md
3. PATTERNS_AND_BEST_PRACTICES.md

### **Step 3: Explore Code (1 jam)**
- Explore vnu_core/lib/common/
- Explore vnu_noi_tru/lib/
- Read examples di CODE_EXAMPLES.md

### **Step 4: Code Your First Feature (2-3 jam)**
- Buat feature kecil
- Gunakan template dari CODE_EXAMPLES.md
- Follow patterns dari PATTERNS_AND_BEST_PRACTICES.md

### **Step 5: Get Code Review**
- Tunjukkan ke senior
- Dapatkan feedback
- Improve

---

## 💡 Pro Tips

1. **Selalu gunakan `logInfo()` untuk debugging** - Lebih baik dari print()
2. **Reuse utilities dari vnu_core** - Jangan duplicate code
3. **Buat extension method** - Untuk commonly used operations
4. **Gunakan Repository pattern** - Untuk semua data access
5. **Handle semua errors gracefully** - User experience penting
6. **Cache data whenever possible** - Improve performance
7. **Test feature Anda** - Jangan skip testing
8. **Minta code review** - Learn from others

---

## 📞 Butuh Bantuan?

1. **Cek dokumentasi ini** - Mungkin jawabannya di sini
2. **Explore kode yang serupa** - Di vnu_core atau vnu_noi_tru
3. **Tanya senior developer** - Mereka lebih experience
4. **Check Flutter docs** - https://flutter.dev/docs
5. **Search package documentation** - pub.dev

---

## 📋 Checklist - Anda Siap Jika:

- [ ] Sudah baca semua dokumentasi penting
- [ ] Mengerti struktur monorepo
- [ ] Tahu cara menggunakan Cubit
- [ ] Bisa menggunakan utilities dari vnu_core
- [ ] Mengerti Repository pattern
- [ ] Bisa handle API dengan Repository
- [ ] Mengerti error handling
- [ ] Bisa membuat feature sederhana
- [ ] Bisa debug dengan log
- [ ] Siap bertanya jika perlu

---

## 🎉 Selamat Datang!

Anda sekarang memiliki semua yang dibutuhkan untuk memulai development di ONE VNU Project!

**Ingat:**
- ✅ Pertanyaan itu hal yang bagus (jangan takut bertanya)
- ✅ Baca kode existing itu cara terbaik belajar
- ✅ Error adalah bagian dari learning process
- ✅ Konsistensi dalam naming & patterns sangat penting
- ✅ Code review adalah kesempatan untuk belajar

---

**Happy Coding! 🚀**

---

## 📚 File Reference

| File | Ukuran | Waktu Baca | Untuk |
|------|--------|-----------|-------|
| QUICK_START_GUIDE.md | ~3KB | 5 min | Ringkasan cepat |
| ONBOARDING_GUIDE_VN.md | ~15KB | 30 min | Comprehensive guide |
| PATTERNS_AND_BEST_PRACTICES.md | ~12KB | 20 min | Architecture |
| FILE_STRUCTURE_GUIDE.md | ~10KB | 15 min | File details |
| CODE_EXAMPLES.md | ~20KB | 30 min | Code samples |
| DOCUMENTATION_INDEX.md | ~8KB | 10 min | Navigation |

---

**Terakhir diupdate: 12 November 2025**  
**Oleh: GitHub Copilot**  
**Untuk: ONE VNU Project Team**
