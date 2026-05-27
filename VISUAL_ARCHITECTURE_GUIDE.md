# 🎨 Visual Architecture Guide - ONE VNU Project

---

## 📊 Project Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     ONE VNU APP STORE                       │
│                    (Main Application)                        │
└──────────┬──────────────────────────────────────────────────┘
           │
           ├─────────────────────┬────────────────────┐
           │                     │                    │
      ┌────▼─────┐        ┌─────▼────┐       ┌──────▼──────┐
      │ vnu_core │        │vnu_noi_tru  │   │  inmapz   │
      │(Reusable)│        │  (Feature) │   │  (Maps)   │
      └────┬─────┘        └─────┬────┘       └──────┬──────┘
           │                    │                    │
     ┌─────▼──────────────────────────────────────────┐
     │      Shared Services & Utilities              │
     │  (API, Storage, Logging, etc)                 │
     └─────┬──────────────────────────────────────────┘
           │
     ┌─────▼──────────────────────────────────────────┐
     │         Firebase & External Services          │
     │ (Analytics, Messaging, Crashlytics, etc)      │
     └──────────────────────────────────────────────┘
```

---

## 🏗️ Layer Architecture (Clean Architecture)

```
┌──────────────────────────────────────────────────────┐
│          PRESENTATION LAYER (UI)                     │  ← Screens
│  ┌────────┬────────┬────────┬────────┐             │     Widgets
│  │Screen 1│Screen 2│Screen 3│Screen 4│             │     Cubits
│  └────────┴────────┴────────┴────────┘             │
└──────────────────────────────────────────────────────┘
                         ▲
                         │ Uses
                         │
┌──────────────────────────────────────────────────────┐
│           STATE MANAGEMENT LAYER                     │  ← Cubits
│  ┌──────┬──────┬──────┬──────────┐                │     States
│  │Cubit1│Cubit2│Cubit3│Cubit_N   │                │
│  └──────┴──────┴──────┴──────────┘                │
└──────────────────────────────────────────────────────┘
                         ▲
                         │ Uses
                         │
┌──────────────────────────────────────────────────────┐
│           REPOSITORY LAYER (Data Logic)              │  ← Repositories
│  ┌─────────────┬──────────────┬─────────────────┐ │     Controllers
│  │Repository 1 │ Repository 2 │ Repository N   │ │
│  └─────────────┴──────────────┴─────────────────┘ │
└──────────────────────────────────────────────────────┘
       ▲                               ▲
       │                               │
    Uses API                     Uses Local Storage
       │                               │
┌──────▼──────────────┬────────────────▼──────────────┐
│    DATA LAYER       │                               │
├─────────────────────┼───────────────────────────────┤
│    API Client       │   Local Storage               │
│    (Retrofit/Dio)   │   (SharedPrefs, SQLite)       │
│                     │                               │
│    External APIs    │   Cache Manager               │
│    - Firebase       │   File Management             │
│    - Google Maps    │                               │
└─────────────────────┴───────────────────────────────┘
```

---

## 🗂️ Module Structure - vnu_core (Reusable)

```
vnu_core/
│
├── common/                    ← Utilities & Helpers
│   ├── log.dart              ✅ Logging
│   ├── app_color.dart        ✅ Colors
│   ├── app_text_styles.dart  ✅ Text Styles
│   ├── local_storage.dart    ✅ Data Storage
│   ├── datetime_utils.dart   ✅ Date Utils
│   ├── download_manager.dart ✅ Download Files
│   └── ... (13 more files)
│
├── constants/                 ← Configuration
│   ├── config.dart
│   ├── constant.dart
│   ├── enum.dart
│   └── date_formater.dart
│
├── cubit/                     ← State Management
│   ├── auth_cubit.dart
│   ├── file_cubit.dart
│   └── map_cubit.dart
│
├── data/                      ← API Layer
│   ├── app_api.dart          (Retrofit endpoints)
│   └── api_response.dart
│
├── models/                    ← Data Entities
│   ├── anh_ca_nhan_model.dart
│   ├── cam_nang_model.dart
│   └── ... (30+ models)
│
├── repository/                ← Data Access
│   ├── app_repository.dart
│   └── data_repository.dart
│
├── extensions/                ← Extend Types
│   ├── extension_string.dart
│   ├── context_ext.dart
│   └── ... (6 more)
│
├── screens/                   ← Base Screens
│   ├── vcore_splash_screen.dart
│   ├── vcore_login_screen.dart
│   └── vcore_preview_pdf_screen.dart
│
├── modules/                   ← Feature Modules
│   ├── bookmark/
│   ├── browser/
│   ├── news/
│   ├── question/
│   ├── system_news/
│   ├── tabbar/
│   └── paht/
│
├── services/                  ← Services
│   └── services_url.dart
│
├── widgets/                   ← Reusable Components
├── themes/                    ← Theming
└── vnu_core.dart              ← Main Entry Point
```

---

## 🗂️ Module Structure - vnu_noi_tru (Feature)

```
vnu_noi_tru/
│
├── cubit/                     ← State Management
│   ├── nt_news_cubit.dart
│   ├── nt_register_cubit.dart
│   └── *_state.dart
│
├── data/                      ← API & DTOs
│   ├── noitru_api.dart        (API endpoints)
│   ├── noitru_response.dart   (Response models)
│   └── requests/
│       └── luu_noi_tru_request.dart
│
├── models/                    ← Domain Models
│   ├── noi_tru_phieu_dang_ky_model.dart
│   ├── nt_danh_sach_phong_model.dart
│   ├── nt_tin_tuc_model.dart
│   └── ... (14 more models)
│
├── modules/                   ← Feature Sub-modules
│   └── boarding/
│       ├── controllers/       (GetX Controllers)
│       └── views/             (Screens & Widgets)
│
├── repository/                ← Data Repository
│   ├── noitru_repository.dart
│   └── noitru_dormitory_repository.dart
│
├── screens/                   ← Full Screens
│   ├── nt_home_screen.dart
│   ├── nt_dang_ky_noi_tru_screen.dart
│   └── ... (8 screens)
│
├── widgets/                   ← Reusable Components
│   ├── nt_boarding_item_widget.dart
│   ├── nt_register_cmnd_widget.dart
│   └── ... (9 widgets)
│
├── common/                    ← Feature Constants
│   └── enum.dart
│
└── vnu_noi_tru.dart           ← Main Entry Point
```

---

## 🔄 Data Flow Diagram

```
┌──────────────┐
│   UI Screen  │
│  (Flutter)   │
└──────┬───────┘
       │ calls
       ▼
┌──────────────┐
│    Cubit     │  ← State Management
│ (Handles     │    (Loading, Success, Error)
│  business    │
│  logic)      │
└──────┬───────┘
       │ uses
       ▼
┌──────────────┐
│  Repository  │  ← Data Layer Coordinator
│ (Gets data   │    (API + Local Storage)
│  from        │
│  sources)    │
└──────┬───────┘
       │
    ┌──┴──┐
    │     │
    ▼     ▼
 ┌────┐┌──────────┐
 │API ││Local DB  │  ← Data Sources
 │    ││Storage   │
 └────┘└──────────┘
```

---

## 📊 Cubit State Flow

```
┌─────────────┐
│  Initial    │  ← App starts
└──────┬──────┘
       │ User action
       ▼
┌─────────────┐
│  Loading    │  ← Show spinner
└──────┬──────┘
       │ API call
       ├─────────────┬──────────────┐
       │             │              │
    Success       Error        Timeout
       ▼             ▼              ▼
  ┌────────┐  ┌──────────┐  ┌──────────┐
  │Success │  │Error Msg │  │Retry Btn │
  │(Data)  │  │(Show msg)│  │(Retry)   │
  └────────┘  └──────────┘  └──────────┘
```

---

## 🎯 Feature Development Workflow

```
START
  │
  ├─► 1. Design Model
  │     └─► (my_model.dart)
  │
  ├─► 2. Create State Classes
  │     └─► (my_state.dart) @freezed
  │
  ├─► 3. Create Cubit
  │     └─► (my_cubit.dart) with business logic
  │
  ├─► 4. Create API (if needed)
  │     └─► (my_api.dart) @RestApi
  │
  ├─► 5. Create Repository (if needed)
  │     └─► (my_repository.dart)
  │
  ├─► 6. Create Screens
  │     └─► (my_screen.dart) with BlocBuilder
  │
  ├─► 7. Create Widgets
  │     └─► (my_widget.dart) reusable components
  │
  ├─► 8. Register in Main App
  │     └─► (main.dart) routes & providers
  │
  ├─► 9. Test & Debug
  │     └─► Use logging, check states
  │
  └─► DONE! ✅
```

---

## 💾 Data Storage Strategy

```
┌──────────────────────────────────────────────┐
│          HOW DATA IS STORED                  │
└──────────────────────────────────────────────┘

┌─ TEMPORARY (During Session)
│  ├─ Cubit State (memory)
│  └─ Variables (RAM)
│
├─ SHORT TERM (Cleared on logout)
│  ├─ SharedPreferences (simple key-value)
│  ├─ Local Storage wrapper
│  └─ Cache Manager (images, files)
│
├─ PERSISTENT (Survives app restart)
│  ├─ SQLite Database
│  └─ File Storage
│
└─ SECURE (Encrypted storage)
   └─ Flutter Secure Storage (tokens, passwords)
```

---

## 🔐 Authentication Flow

```
┌─────────────┐
│   Login     │
│   Screen    │
└──────┬──────┘
       │ Email + Password
       ▼
┌──────────────────┐
│ Auth Repository  │  ← Handle auth logic
│ (Cubit)          │
└──────┬───────────┘
       │ API call
       ▼
┌──────────────────┐
│   Firebase /     │  ← API Server
│   Backend API    │
└──────┬───────────┘
       │
    ┌──┴──────────┐
    │             │
   OK           ERROR
    │             │
    ▼             ▼
 ┌──────┐    ┌──────────┐
 │Token │    │Error Msg │
 │Store │    │Show Error│
 │Cache │    │          │
 └──────┘    └──────────┘
    │
    ▼
 ┌──────────────┐
 │ Go to Home   │
 │ Screen       │
 └──────────────┘
```

---

## 🌐 Network Request Flow

```
┌───────────────┐
│  UI Action    │
│ (Button tap)  │
└───────┬───────┘
        │
        ▼
┌───────────────────────┐
│  Cubit (Loading)      │  emit(State.loading())
│  Show spinner         │
└───────┬───────────────┘
        │
        ▼
┌───────────────────────┐
│   Repository          │  Check cache first
│   (Get from cache     │  If no cache → API call
│    or API)            │
└───────┬───────────────┘
        │
        ├──────────────┬──────────────┐
        │              │              │
     Cache         API Success    API Error
        │              │              │
        ▼              ▼              ▼
   ┌─────────┐  ┌─────────┐  ┌──────────┐
   │Parse &  │  │Parse &  │  │Try Cache │
   │Return   │  │Cache    │  │If fail   │
   │Data     │  │Return   │  │Error Msg │
   └────┬────┘  └────┬────┘  └────┬─────┘
        │            │            │
        └────┬───────┴────────┬───┘
             │                │
            Data            Error
             │                │
             ▼                ▼
        ┌─────────┐   ┌──────────────┐
        │Cubit    │   │Cubit.error() │
        │.success()│   │Show error    │
        └─────────┘   └──────────────┘
```

---

## 🎨 Widget Hierarchy Example

```
┌─────────────────────────────────────────┐
│            MyScreen (StatelessWidget)    │
│                                         │
│  Scaffold(                              │
│    appBar: AppBar(...),                 │
│    body: BlocBuilder<MyCubit, MyState>( │
│                                         │
│      ┌──────────────────────────────┐  │
│      │ Builder (context, state)     │  │
│      │                              │  │
│      │ ┌─────────────────────────┐ │  │
│      │ │ state.when(             │ │  │
│      │ │   loading: () => ...,    │ │  │
│      │ │   success: (data) => {   │ │  │
│      │ │                          │ │  │
│      │ │  ┌──────────────────┐   │ │  │
│      │ │  │ ListView(        │   │ │  │
│      │ │  │   children: [    │   │ │  │
│      │ │  │ ┌──────────────┐ │   │ │  │
│      │ │  │ │ MyItemWidget │ │   │ │  │
│      │ │  │ └──────────────┘ │   │ │  │
│      │ │  │ ]                │   │ │  │
│      │ │  └──────────────────┘   │ │  │
│      │ │   })                     │ │  │
│      │ └─────────────────────────┘ │  │
│      └──────────────────────────────┘  │
│    )                                   │
│  )                                     │
└─────────────────────────────────────────┘
```

---

## 🔌 Dependency Injection (Get)

```
┌──────────────────────────────────────────────┐
│   GetIt / Get Package                        │
│   (Dependency Injection Container)           │
└──────────────────────────────────────────────┘
           │
    ┌──────┴──────┬──────────┬──────────┐
    │             │          │          │
    ▼             ▼          ▼          ▼
┌────────┐   ┌────────┐  ┌────────┐  ┌────────┐
│ Cubit1 │   │Cubit2  │  │Repo1   │  │Repo2   │
└────────┘   └────────┘  └────────┘  └────────┘
    │             │          │          │
    └─────────────┴──────────┴──────────┘
            │
            ▼
        UI Widgets
        (Inject via Get.put()
         or BlocProvider)
```

---

## 🚀 App Initialization Flow

```
┌─────────────┐
│  main()     │
│ {           │
│  ..Setup..  │
│ }           │
└──────┬──────┘
       │
       ├─► Firebase.init()
       ├─► LocalStorage.init()
       ├─► NetworkMonitor.start()
       ├─► Setup GetIt / Dependencies
       ├─► Load user preferences
       │
       ▼
┌──────────────────┐
│ VnuCore.init()   │
│ VNUNoiTru.init() │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│   MyApp()        │  ← Main Flutter App
│ (MaterialApp)    │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ SplashScreen /   │
│ HomeScreen       │
│                  │
│ (Based on auth   │
│  state)          │
└──────────────────┘
```

---

## ✅ Code Quality Checklist Flow

```
┌─────────────┐
│ Write Code  │
└──────┬──────┘
       │
       ├─► Follow naming conventions? ✓
       │
       ├─► Use right pattern? ✓
       │   (Cubit, Repository, etc)
       │
       ├─► Handle errors? ✓
       │   (try-catch, error states)
       │
       ├─► Use logging? ✓
       │   (logInfo, logError, etc)
       │
       ├─► Reuse vnu_core? ✓
       │   (colors, utils, etc)
       │
       ├─► DRY (Don't Repeat)? ✓
       │   (Extract widgets, utils)
       │
       ├─► Code review? ✓
       │   (Ask senior)
       │
       └─► Ready to merge! 🎉
```

---

## 📈 Scaling Guide

```
Project Grows:

Start (1 feature)
├─ 1 Screen
├─ 1 Cubit
└─ Basic Models

Grow (3-5 features)
├─ Multiple Screens
├─ Multiple Cubits
├─ Repository Pattern
└─ Shared Services

Mature (10+ features)
├─ Module System
├─ Feature Isolation
├─ Centralized Auth
├─ Network Caching
├─ Error Handling
└─ Testing (Unit & Widget)

Scale (20+ features)
├─ Monorepo Structure ✅ (Already using!)
├─ Shared Core Module ✅ (vnu_core)
├─ Feature Modules ✅ (vnu_noi_tru)
├─ Dependency Management ✅ (pub/get)
└─ CI/CD Pipeline
```

---

**Visualisasi ini membantu Anda memahami bagaimana semuanya terhubung! 🎯**
