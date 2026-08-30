import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/modules/shapeshifter/models/shapeshifter_feature.dart';
import 'package:vnu_core/modules/shapeshifter/repository/shapeshifter_repository.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Generic Shapeshifter WebView shell - B2.6.
///
/// There is no Shapeshifter database/web session in the new flow.
/// Flutter sends the current ONEVNU access token only in the FIRST bootstrap
/// request header. The Shapeshifter backend validates it against ONEVNU and
/// responds with a signed HttpOnly cookie. Subsequent fetch/upload calls use
/// that cookie automatically.
///
/// Personal data is also copied to ONEVNU_SHAPE_PREFILL as convenience data so
/// the form can paint immediately. That cookie is NOT trusted as identity.
class VcoreShapeshifterWebView extends StatefulWidget {
  const VcoreShapeshifterWebView({
    super.key,
    required this.feature,
  });

  final ShapeshifterFeature feature;

  @override
  State<VcoreShapeshifterWebView> createState() =>
      _VcoreShapeshifterWebViewState();
}

class _VcoreShapeshifterWebViewState
    extends State<VcoreShapeshifterWebView> with WidgetsBindingObserver {
  static const String _prefillCookieName = 'ONEVNU_SHAPE_PREFILL';
  static const String _nativeChannelName = 'OneVnuNative';

  late final WebViewController _controller;
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  final ImagePicker _imagePicker = ImagePicker();

  int _progress = 0;
  bool _preparing = true;
  bool _openingExternal = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        _nativeChannelName,
        onMessageReceived: _onNativeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _errorMessage = null;
                _progress = 0;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _progress = 100);
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame == false) return;
            setState(() {
              _errorMessage = error.description.trim().isEmpty
                  ? 'Không tải được nội dung.'
                  : error.description;
            });
          },
          onNavigationRequest: _onNavigationRequest,
        ),
      );

    unawaited(_configureAndroidFileSelector());
    unawaited(_prepareAndLoad());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshRegistrationData(manual: false, source: 'resume'));
    }
  }

  Future<void> _refreshRegistrationData({
    required bool manual,
    required String source,
  }) async {
    if (_preparing || _errorMessage != null) return;
    try {
      final manualJs = manual ? 'true' : 'false';
      final safeSource = jsonEncode(source);
      await _controller.runJavaScript('''
        (() => {
          if (typeof window.__ONEVNU_SHAPE_REFRESH__ === 'function') {
            window.__ONEVNU_SHAPE_REFRESH__({manual: $manualJs, source: $safeSource});
            return;
          }
          window.dispatchEvent(new CustomEvent('onevnu:refresh', {
            detail: {manual: $manualJs, source: $safeSource}
          }));
        })();
      ''');
    } catch (error) {
      debugPrint('[SHAPE-REFRESH] native refresh failed: $error');
      if (manual) {
        await _controller.reload();
      }
    }
  }

  Future<void> _configureAndroidFileSelector() async {
    if (_controller.platform is! AndroidWebViewController) return;
    final android = _controller.platform as AndroidWebViewController;
    await android.setAllowFileAccess(true);
    await android.setAllowContentAccess(true);
    await android.setOnShowFileSelector(_onAndroidFileSelector);
  }

  Future<List<String>> _onAndroidFileSelector(FileSelectorParams params) async {
    try {
      final acceptTypes = params.acceptTypes
          .map((e) => e.toLowerCase().trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final acceptsImage = acceptTypes.isEmpty ||
          acceptTypes.any((e) => e == 'image/*' || e.startsWith('image/'));
      final acceptsPdf = acceptTypes.any(
        (e) => e == 'application/pdf' || e.contains('pdf'),
      );
      final imageOnly = acceptsImage && !acceptsPdf;
      final multiple = params.mode == FileSelectorMode.openMultiple;

      if (params.isCaptureEnabled && imageOnly) {
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
          requestFullMetadata: false,
        );
        return photo == null ? <String>[] : <String>[_fileUri(photo.path)];
      }

      if (imageOnly) {
        if (multiple) {
          final images = await _imagePicker.pickMultiImage(
            imageQuality: 90,
            requestFullMetadata: false,
          );
          return images
              .map((file) => _fileUri(file.path))
              .where((uri) => uri.isNotEmpty)
              .toList();
        }

        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
          requestFullMetadata: false,
        );
        return image == null ? <String>[] : <String>[_fileUri(image.path)];
      }

      final result = await FilePicker.pickFiles(
        allowMultiple: multiple,
        type: acceptsPdf ? FileType.custom : FileType.any,
        allowedExtensions: acceptsPdf
            ? const <String>['jpg', 'jpeg', 'png', 'webp', 'pdf']
            : null,
        withData: false,
        withReadStream: false,
      );

      if (result == null) return <String>[];
      return result.files
          .map((file) => file.path)
          .whereType<String>()
          .map(_fileUri)
          .where((uri) => uri.isNotEmpty)
          .toList();
    } catch (error) {
      if (mounted) {
        snackBarWarning('Không mở được bộ chọn ảnh/tệp: $error');
      }
      return <String>[];
    }
  }

  String _fileUri(String path) {
    final value = path.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('file://') || value.startsWith('content://')) {
      return value;
    }
    return Uri.file(value).toString();
  }

  Future<void> _prepareAndLoad() async {
    if (mounted) {
      setState(() {
        _preparing = true;
        _errorMessage = null;
        _progress = 0;
      });
    }

    try {
      final webUri = Uri.parse(widget.feature.webUrl);
      final scheme = webUri.scheme.toLowerCase();
      if ((scheme != 'http' && scheme != 'https') || webUri.host.isEmpty) {
        throw StateError('Địa chỉ WebView không hợp lệ.');
      }

      // Best-effort only: auth must NEVER block opening the WebView.
      // If ONEVNU has a usable token we attach it to the bootstrap request so
      // Shapeshifter can create its HttpOnly cookie. If not, the web page still
      // opens normally in guest mode.
      final repository = ShapeshifterRepository();
      String token = '';
      try {
        token = await repository.currentAccessToken();
      } catch (error) {
        debugPrint('[SHAPE-AUTH] optional token unavailable: $error');
      }
      debugPrint(
        '[SHAPE-AUTH] feature=${widget.feature.code} '
        'tokenPresent=${token.isNotEmpty} tokenLength=${token.length}',
      );

      final profile = await _buildPrefillProfile();
      final encodedProfile = _encodeProfile(profile);

      // Prefill is convenience data only. Failure to set this cookie must not
      // prevent the feature page from opening.
      try {
        await _cookieManager.setCookie(
          WebViewCookie(
            name: _prefillCookieName,
            value: encodedProfile,
            domain: webUri.host,
            path: '/shapeshifter/app/',
          ),
        );
      } catch (error) {
        debugPrint('[SHAPE-PREFILL] cookie unavailable: $error');
      }

      final returnPath = webUri.hasQuery
          ? '${webUri.path}?${webUri.query}'
          : webUri.path;
      final bootstrapUri = webUri.replace(
        path: '/shapeshifter/api/auth/bootstrap',
        queryParameters: <String, String>{
          'featureCode': widget.feature.code,
          'returnPath': returnPath,
        },
        fragment: '',
      );

      if (!mounted) return;
      setState(() => _preparing = false);

      // Always open the WebView. Authentication/profile headers are additive,
      // not a prerequisite for rendering the web feature.
      await _controller.loadRequest(
        bootstrapUri,
        headers: <String, String>{
          'X-OneVNU-Client': 'flutter-webview',
          'X-OneVNU-Feature': widget.feature.code,
          'X-OneVNU-Profile': encodedProfile,
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );
    } catch (error) {
      debugPrint('[SHAPE-AUTH-ERROR] feature=${widget.feature.code} error=$error');
      if (!mounted) return;
      setState(() {
        _preparing = false;
        _errorMessage = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  Future<Map<String, String>> _buildPrefillProfile() async {
    final student = Globals().thongTinSinhVienModel.value;
    final currentUser = Globals().currentUserModel.value;
    final classModel = Globals().lopDaoTaoModel.value;
    final prefs = await SharedPreferences.getInstance();

    String firstNotEmpty(Iterable<String?> values) {
      for (final value in values) {
        final text = value?.trim() ?? '';
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    return <String, String>{
      'fullName': firstNotEmpty(<String?>[
        student?.hoVaTen,
        currentUser?.hoVaTen,
        prefs.getString('applicant_fullname'),
      ]),
      'studentCode': firstNotEmpty(<String?>[
        student?.maSinhVien,
        currentUser?.tenDangNhap,
      ]),
      'phoneNumber': firstNotEmpty(<String?>[
        currentUser?.soDienThoai,
        student?.mobile,
        student?.tel,
        prefs.getString('applicant_phone_number'),
        prefs.getString('applicant_phone'),
      ]),
      'unitId': currentUser?.guidDonVi?.trim() ?? '',
      'unitName': firstNotEmpty(<String?>[
        prefs.getString('applicant_university_name'),
      ]),
      'className': classModel?.ten?.trim() ?? '',
      'source': 'ONEVNU_FLUTTER',
    };
  }

  String _encodeProfile(Map<String, String> profile) {
    final bytes = utf8.encode(jsonEncode(profile));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  void _onNativeMessage(JavaScriptMessage message) {
    try {
      final dynamic decoded = jsonDecode(message.message);
      if (decoded is Map && decoded['type'] == 'close') {
        if (mounted) Navigator.of(context).maybePop();
        return;
      }
      if (decoded is Map && decoded['type'] == 'auth_error') {
        // Authentication is best-effort. Keep the WebView visible and only log
        // the signal for diagnostics; do not replace the page with an error UI.
        debugPrint(
          '[SHAPE-AUTH] web auth unavailable status=${decoded['status'] ?? ''} '
          'message=${decoded['message'] ?? ''}',
        );
        return;
      }
    } catch (_) {
      if (message.message == 'close' && mounted) {
        Navigator.of(context).maybePop();
      }
    }
  }

  Future<void> _openInBrowser() async {
    if (_openingExternal) return;
    if (mounted) setState(() => _openingExternal = true);
    try {
      final uri = Uri.parse(widget.feature.webUrl);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw StateError('Không thể mở trình duyệt trên thiết bị.');
      }
    } catch (error) {
      if (mounted) {
        snackBarWarning(error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _openingExternal = false);
    }
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    if (_isExternalScheme(uri)) {
      unawaited(_openExternal(uri));
      return NavigationDecision.prevent;
    }

    // Behave like a normal WebView: allow ordinary HTTP/HTTPS navigation.
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') {
      return NavigationDecision.navigate;
    }

    snackBarWarning('Liên kết này không được hỗ trợ.');
    return NavigationDecision.prevent;
  }

  bool _isExternalScheme(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'tel' || scheme == 'mailto' || scheme == 'sms';
  }

  Future<void> _openExternal(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      snackBarWarning('Không thể mở liên kết ngoài.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      children: [
        if (!_preparing && _errorMessage == null)
          Positioned.fill(child: WebViewWidget(controller: _controller)),
        if (_progress < 100 && !_preparing && _errorMessage == null)
          Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(
              value: _progress <= 0 ? null : _progress / 100,
              minHeight: 2,
              color: widget.feature.primaryColor,
              backgroundColor: Colors.transparent,
            ),
          ),
        if (_preparing)
          _StatusView(
            title: 'Đang tải chức năng',
            message: 'Đang chuẩn bị ${widget.feature.label}...',
            loading: true,
            color: widget.feature.primaryColor,
          ),
        if (!_preparing && _errorMessage != null)
          _StatusView(
            title: 'Không tải được nội dung',
            message: _errorMessage!,
            loading: false,
            color: widget.feature.primaryColor,
            onRetry: () {
              setState(() => _errorMessage = null);
              unawaited(_prepareAndLoad());
            },
            onOpenExternal: _openInBrowser,
            openingExternal: _openingExternal,
          ),
      ],
    );

    return VcoreModuleScaffold(
      title: widget.feature.label,
      backgroundColor: Colors.white,

      // Tự truyền leading để nút Back luôn xuất hiện
      showBackButton: false,
      leading: BackButton(
        color: Colors.black,
        onPressed: () => Navigator.of(context).maybePop(),
      ),

      actions: [
        IconButton(
          color: Colors.black,
          tooltip: 'Làm mới hồ sơ',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _preparing
              ? null
              : () => unawaited(
            _refreshRegistrationData(
              manual: true,
              source: 'appbar',
            ),
          ),
        ),
      ],

      body: body,
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.title,
    required this.message,
    required this.loading,
    required this.color,
    this.onRetry,
    this.onOpenExternal,
    this.openingExternal = false,
  });

  final String title;
  final String message;
  final bool loading;
  final Color color;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenExternal;
  final bool openingExternal;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  CircularProgressIndicator(color: color)
                else
                  Icon(Icons.language_rounded, size: 46, color: color),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    height: 1.45,
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                if (!loading && (onRetry != null || onOpenExternal != null)) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      if (onRetry != null)
                        FilledButton(
                          onPressed: onRetry,
                          style: FilledButton.styleFrom(backgroundColor: color),
                          child: const Text('Thử lại'),
                        ),
                      if (onOpenExternal != null)
                        OutlinedButton.icon(
                          onPressed: openingExternal ? null : onOpenExternal,
                          icon: openingExternal
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.open_in_browser_rounded),
                          label: const Text('Mở bằng trình duyệt'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
