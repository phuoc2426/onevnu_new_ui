# 💻 Code Examples - Thực Hành Ngay

**Cập nhật:** 12/11/2025

---

## 📋 Mục Lục

1. [Hello World - Using vnu_core](#hello-world-using-vnucore)
2. [Creating a New Feature Module](#creating-a-new-feature-module)
3. [Working with APIs](#working-with-apis)
4. [State Management Patterns](#state-management-patterns)
5. [Using Common Utilities](#using-common-utilities)
6. [Creating Reusable Widgets](#creating-reusable-widgets)
7. [Repository Pattern](#repository-pattern)
8. [Error Handling](#error-handling)

---

## 🎯 Hello World - Using vnu_core

### **Sử dụng Logging:**

```dart
// File: lib/main.dart hoặc anywhere
import 'package:vnu_core/common/log.dart';

void main() {
  logInfo('App started');
  logSuccess('Configuration loaded');
  logWarning('API timeout approaching');
  logError('Critical error occurred');
}
```

**Output:**
```
ℹ️  App started
✅ Configuration loaded
⚠️  API timeout approaching
❌ Critical error occurred
```

### **Sử dụng Colors:**

```dart
import 'package:vnu_core/common/app_color.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.primary,
      child: Text(
        'Hello VNU',
        style: TextStyle(color: AppColor.white),
      ),
    );
  }
}
```

### **Sử dụng Text Styles:**

```dart
import 'package:vnu_core/common/app_text_styles.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Title', style: AppTextStyle.title),
        Text('Subtitle', style: AppTextStyle.subtitle),
        Text('Body', style: AppTextStyle.body),
        Text('Caption', style: AppTextStyle.caption),
      ],
    );
  }
}
```

### **Sử dụng Local Storage:**

```dart
import 'package:vnu_core/common/local_storage.dart';

class UserPreferences {
  final _storage = LocalStorage();
  
  Future<void> saveUserName(String name) async {
    await _storage.save('user_name', name);
  }
  
  Future<String?> getUserName() async {
    return await _storage.read('user_name');
  }
  
  Future<void> clearAll() async {
    await _storage.clear();
  }
}
```

---

## 🏗️ Creating a New Feature Module

### **Step 1: Create Module Structure**

```bash
mkdir -p features/my_feature/{
  cubits,
  data,
  models,
  repository,
  screens,
  widgets
}
```

### **Step 2: Create pubspec.yaml (if new package)**

```yaml
# my_feature_module/pubspec.yaml
name: my_feature_module
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
  dio: ^5.4.3+1
  flutter_bloc: ^8.1.1
  freezed_annotation: ^2.4.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner:
  freezed:
  json_serializable:
```

### **Step 3: Create Models**

```dart
// my_feature/lib/models/my_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_model.freezed.dart';
part 'my_model.g.dart';

@freezed
class MyData with _$MyData {
  const factory MyData({
    required String id,
    required String title,
    String? description,
    DateTime? createdAt,
  }) = _MyData;

  factory MyData.fromJson(Map<String, dynamic> json) =>
      _$MyDataFromJson(json);
}
```

### **Step 4: Create API Layer**

```dart
// my_feature/lib/data/my_api.dart
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../models/my_model.dart';

part 'my_api.g.dart';

@RestApi(baseUrl: 'https://api.example.com')
abstract class MyApi {
  factory MyApi(Dio dio, {String baseUrl}) = _MyApi;

  @GET('/api/v1/data')
  Future<List<MyData>> fetchAllData();

  @GET('/api/v1/data/{id}')
  Future<MyData> fetchDataById(@Path('id') String id);

  @POST('/api/v1/data')
  Future<MyData> createData(@Body() MyData data);

  @PUT('/api/v1/data/{id}')
  Future<MyData> updateData(
    @Path('id') String id,
    @Body() MyData data,
  );

  @DELETE('/api/v1/data/{id}')
  Future<void> deleteData(@Path('id') String id);
}
```

### **Step 5: Create Repository**

```dart
// my_feature/lib/repository/my_repository.dart
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/common/local_storage.dart';
import '../data/my_api.dart';
import '../models/my_model.dart';

class MyRepository {
  final MyApi api;
  final LocalStorage localStorage;

  MyRepository({
    required this.api,
    required this.localStorage,
  });

  Future<List<MyData>> getAllData() async {
    try {
      logInfo('Fetching all data from API');
      
      final data = await api.fetchAllData();
      
      // Cache locally
      await localStorage.save('all_data', 
        data.map((e) => e.toJson()).toList());
      
      return data;
    } catch (e) {
      logError('Failed to fetch data: $e');
      
      // Try loading from cache
      final cached = await localStorage.read('all_data');
      if (cached != null) {
        return (cached as List)
          .map((e) => MyData.fromJson(e))
          .toList();
      }
      
      rethrow;
    }
  }

  Future<MyData> getDataById(String id) async {
    try {
      return await api.fetchDataById(id);
    } catch (e) {
      logError('Failed to fetch data by id: $e');
      rethrow;
    }
  }

  Future<MyData> createNewData(MyData data) async {
    try {
      logInfo('Creating new data');
      return await api.createData(data);
    } catch (e) {
      logError('Failed to create data: $e');
      rethrow;
    }
  }
}
```

### **Step 6: Create State Classes**

```dart
// my_feature/lib/cubit/my_feature_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/my_model.dart';

part 'my_feature_state.freezed.dart';

@freezed
class MyFeatureState with _$MyFeatureState {
  const factory MyFeatureState.initial() = _Initial;
  const factory MyFeatureState.loading() = _Loading;
  const factory MyFeatureState.success(List<MyData> data) = _Success;
  const factory MyFeatureState.error(String message) = _Error;
}
```

### **Step 7: Create Cubit**

```dart
// my_feature/lib/cubit/my_feature_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/common/log.dart';
import '../repository/my_repository.dart';
import '../models/my_model.dart';
import 'my_feature_state.dart';

class MyFeatureCubit extends Cubit<MyFeatureState> {
  final MyRepository repository;

  MyFeatureCubit(this.repository) : super(const MyFeatureState.initial());

  Future<void> loadAllData() async {
    try {
      emit(const MyFeatureState.loading());
      
      final data = await repository.getAllData();
      
      logSuccess('Data loaded successfully');
      emit(MyFeatureState.success(data));
    } catch (e) {
      logError('Failed to load data: $e');
      emit(MyFeatureState.error(e.toString()));
    }
  }

  Future<void> refreshData() async {
    await loadAllData();
  }
}
```

### **Step 8: Create Screens & Widgets**

```dart
// my_feature/lib/screens/my_feature_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/common/app_color.dart';
import '../cubit/my_feature_cubit.dart';
import '../cubit/my_feature_state.dart';
import '../widgets/my_data_list_widget.dart';

class MyFeatureScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Feature'),
        backgroundColor: AppColor.primary,
      ),
      body: BlocBuilder<MyFeatureCubit, MyFeatureState>(
        builder: (context, state) {
          return state.when(
            initial: () {
              // Load data on initial
              context.read<MyFeatureCubit>().loadAllData();
              return const SizedBox.shrink();
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            success: (data) => MyDataListWidget(
              data: data,
              onRefresh: () {
                return context.read<MyFeatureCubit>().refreshData();
              },
            ),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $message'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MyFeatureCubit>().loadAllData();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### **Step 9: Create Reusable Widgets**

```dart
// my_feature/lib/widgets/my_data_list_widget.dart
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../models/my_model.dart';
import 'my_data_item_widget.dart';

class MyDataListWidget extends StatefulWidget {
  final List<MyData> data;
  final Future<void> Function() onRefresh;

  const MyDataListWidget({
    required this.data,
    required this.onRefresh,
  });

  @override
  State<MyDataListWidget> createState() => _MyDataListWidgetState();
}

class _MyDataListWidgetState extends State<MyDataListWidget> {
  late RefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No data available'),
          ],
        ),
      );
    }

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: () async {
        try {
          await widget.onRefresh();
          _refreshController.refreshCompleted();
        } catch (e) {
          _refreshController.refreshFailed();
        }
      },
      child: ListView.builder(
        itemCount: widget.data.length,
        itemBuilder: (context, index) {
          return MyDataItemWidget(data: widget.data[index]);
        },
      ),
    );
  }
}

// my_feature/lib/widgets/my_data_item_widget.dart
import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_color.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import '../models/my_model.dart';

class MyDataItemWidget extends StatelessWidget {
  final MyData data;
  final VoidCallback? onTap;

  const MyDataItemWidget({
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(
          data.title,
          style: AppTextStyle.subtitle,
        ),
        subtitle: data.description != null
            ? Text(
                data.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppColor.primary),
        onTap: onTap,
      ),
    );
  }
}
```

---

## 📡 Working with APIs

### **Setup Dio & Retrofit:**

```dart
// common/api_client.dart
import 'package:dio/dio.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  late Dio _dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example.com',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Add logging
    _dio.interceptors.add(
      TalkerDioLogger(
        settings: const TalkerDioLoggerSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
          printResponseMessage: true,
        ),
      ),
    );

    // Add token interceptor
    _dio.interceptors.add(TokenInterceptor());
  }

  Dio get dio => _dio;
}

// common/token_interceptor.dart
class TokenInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add token if available
    final token = getToken(); // Get from localStorage
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401, refresh token, etc.
    handler.next(err);
  }
}
```

### **API Class dengan Retrofit:**

```dart
// data/api.dart
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

part 'api.g.dart';

@RestApi(baseUrl: 'https://api.example.com/v1')
abstract class AppApi {
  factory AppApi(Dio dio) = _AppApi;

  @GET('/news')
  Future<HttpResponse<List<NewsModel>>> getNews(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @GET('/news/{id}')
  Future<HttpResponse<NewsModel>> getNewsById(@Path('id') String id);

  @POST('/news')
  Future<HttpResponse<NewsModel>> createNews(@Body() CreateNewsRequest request);

  @PUT('/news/{id}')
  Future<HttpResponse<NewsModel>> updateNews(
    @Path('id') String id,
    @Body() UpdateNewsRequest request,
  );
}
```

---

## 🎮 State Management Patterns

### **Pattern 1: Simple State**

```dart
class SimpleCubit extends Cubit<SimpleState> {
  SimpleCubit() : super(const SimpleState.initial());

  void increment() {
    emit(SimpleState.success(state.count + 1));
  }

  void decrement() {
    emit(SimpleState.success(state.count - 1));
  }
}

@freezed
class SimpleState with _$SimpleState {
  const factory SimpleState.initial() = _Initial;
  const factory SimpleState.success(int count) = _Success;
  const factory SimpleState.error(String message) = _Error;
}
```

### **Pattern 2: With Repository**

```dart
class UserCubit extends Cubit<UserState> {
  final UserRepository repository;

  UserCubit(this.repository) : super(const UserState.initial());

  Future<void> fetchUser(String userId) async {
    emit(const UserState.loading());
    try {
      final user = await repository.getUserById(userId);
      emit(UserState.success(user));
    } catch (e) {
      emit(UserState.error(e.toString()));
    }
  }
}
```

### **Pattern 3: With Local Cache**

```dart
class CachedDataCubit extends Cubit<DataState> {
  final DataRepository repository;
  final LocalStorage localStorage;

  CachedDataCubit({
    required this.repository,
    required this.localStorage,
  }) : super(const DataState.initial());

  Future<void> getData() async {
    emit(const DataState.loading());
    try {
      // Try cache first
      final cached = await localStorage.read('data_cache');
      if (cached != null) {
        emit(DataState.success(cached));
      }

      // Then fetch fresh from API
      final fresh = await repository.fetchData();
      await localStorage.save('data_cache', fresh);
      emit(DataState.success(fresh));
    } catch (e) {
      emit(DataState.error(e.toString()));
    }
  }

  Future<void> refresh() async {
    await localStorage.remove('data_cache');
    await getData();
  }
}
```

---

## 🧰 Using Common Utilities

### **Using Extensions:**

```dart
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/extensions/context_ext.dart';

// String extensions
String email = "USER@EXAMPLE.COM";
print(email.toLowerCase());           // user@example.com
if (email.isEmail()) print("Valid");  // Valid

// BuildContext extensions
context.pop();                        // Navigator.pop(context)
context.showSnackBar("Message");      // Show snackbar
context.showLoading();                // Show loading dialog
```

### **Using DateTime Utils:**

```dart
import 'package:vnu_core/common/datetime_utils.dart';

final now = DateTime.now();
final formatted = formatDateTime(now);  // Formatted string
final parsed = parseDate("2024-12-25");  // Parse from string

final isToday = isSameDay(now, DateTime.now());
final isExpired = isDateExpired(expiryDate);
```

### **Using File Utils:**

```dart
import 'package:vnu_core/common/file_utils.dart';

final size = getFileSize(File('path/to/file'));
final ext = getFileExtension('document.pdf');  // 'pdf'
```

---

## 🧩 Creating Reusable Widgets

### **Generic Button Widget:**

```dart
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;

  const CustomButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColor.primary,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor ?? Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(color: textColor ?? Colors.white),
                  ),
                ],
              ),
      ),
    );
  }
}

// Usage
CustomButton(
  label: 'Login',
  onPressed: () {},
  icon: Icons.login,
)
```

### **Generic Card Widget:**

```dart
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double elevation;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const CustomCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(8),
    this.elevation = 2,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      color: backgroundColor,
      margin: margin,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

// Usage
CustomCard(
  onTap: () {},
  child: Column(
    children: [
      Text('Title'),
      SizedBox(height: 8),
      Text('Subtitle'),
    ],
  ),
)
```

---

## 🗄️ Repository Pattern

### **Complete Repository Example:**

```dart
class NtRepository {
  final NtApi api;
  final LocalStorage localStorage;
  final _networkMonitor = NetworkMonitor();

  NtRepository({
    required this.api,
    required this.localStorage,
  });

  /// Fetch news with caching strategy
  Future<List<NtNews>> getNews({bool forceRefresh = false}) async {
    try {
      // Return cache if available and not forced refresh
      if (!forceRefresh) {
        final cached = await _getFromCache('news_list');
        if (cached != null) {
          return cached;
        }
      }

      // Check network
      if (!_networkMonitor.isConnected) {
        throw Exception('No internet connection');
      }

      // Fetch from API
      final response = await api.getNews();
      
      // Cache
      await _saveToCache('news_list', response);
      
      return response;
    } catch (e) {
      // Try cache as fallback
      final cached = await _getFromCache('news_list');
      if (cached != null) {
        logWarning('Using cached data due to error: $e');
        return cached;
      }
      rethrow;
    }
  }

  /// Get single news detail
  Future<NtNews> getNewsDetail(String id) async {
    try {
      return await api.getNewsById(id);
    } catch (e) {
      logError('Failed to get news detail: $e');
      rethrow;
    }
  }

  /// Create/Share news
  Future<NtNews> shareNews(CreateNewsRequest request) async {
    try {
      final response = await api.shareNews(request);
      // Invalidate cache
      await localStorage.remove('news_list');
      return response;
    } catch (e) {
      logError('Failed to share news: $e');
      rethrow;
    }
  }

  // Private helpers
  Future<List<NtNews>?> _getFromCache(String key) async {
    try {
      final cached = await localStorage.read(key);
      if (cached == null) return null;
      return (cached as List).map((e) => NtNews.fromJson(e)).toList();
    } catch (e) {
      logWarning('Cache read failed: $e');
      return null;
    }
  }

  Future<void> _saveToCache(String key, List<NtNews> data) async {
    try {
      await localStorage.save(key, data.map((e) => e.toJson()).toList());
    } catch (e) {
      logWarning('Cache save failed: $e');
    }
  }
}
```

---

## 🚨 Error Handling

### **Global Error Handler:**

```dart
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is Exception) {
      return error.toString();
    } else {
      return 'An unknown error occurred';
    }
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';
      case DioExceptionType.badResponse:
        return 'Server error: ${error.response?.statusCode}';
      case DioExceptionType.badCertificate:
        return 'Certificate error. Please try again.';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet.';
      case DioExceptionType.unknown:
        return 'Unknown error occurred.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
    }
  }
}

// Usage in Cubit
Future<void> loadData() async {
  try {
    emit(const DataState.loading());
    final data = await repository.getData();
    emit(DataState.success(data));
  } catch (e) {
    final message = ErrorHandler.getErrorMessage(e);
    logError(message);
    emit(DataState.error(message));
  }
}
```

---

## 🎓 Best Practices Summary

✅ **Do:**
- Use Cubit for state management
- Use Repository pattern
- Handle errors gracefully
- Cache data when possible
- Use extensions to keep code DRY
- Log everything
- Use type-safe models (Freezed)
- Separate concerns

❌ **Don't:**
- Mix business logic with UI
- Ignore errors
- Hardcode values
- Create nested folders too deep
- Use setState for complex states
- Forget to handle loading states
- Mix multiple patterns
- Ignore naming conventions

---

**Sekarang Anda siap coding! 🚀**
