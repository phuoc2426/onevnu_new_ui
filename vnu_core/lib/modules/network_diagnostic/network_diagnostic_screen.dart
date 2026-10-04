import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vnu_core/modules/network_diagnostic/network_diagnostic_service.dart';

const bool kOneVnuNetworkDiagnosticEnabled = bool.fromEnvironment(
  'ONEVNU_NETWORK_DIAGNOSTIC',
  defaultValue: true,
);

class NetworkDiagnosticScreen extends StatefulWidget {
  const NetworkDiagnosticScreen({super.key});

  @override
  State<NetworkDiagnosticScreen> createState() =>
      _NetworkDiagnosticScreenState();
}

class _NetworkDiagnosticScreenState extends State<NetworkDiagnosticScreen> {
  final NetworkDiagnosticService _service = NetworkDiagnosticService.instance;
  final TextEditingController _comparisonUrlController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _lines = <String>[];

  StreamSubscription<NetworkDiagnosticEvent>? _subscription;
  bool _running = false;
  Map<String, dynamic> _deviceInfo = <String, dynamic>{};
  Map<String, dynamic> _trustStore = <String, dynamic>{};

  static const List<String> _vnuTargets = <String>[
    'https://onevnu-mobile-api.vnu.edu.vn/api/config',
    'https://idp.vnu.edu.vn/auth/realms/vnu/',
    'https://vnu.edu.vn/',
  ];

  @override
  void initState() {
    super.initState();
    _subscription = _service.events.listen(_onNativeEvent, onError: (Object e) {
      _append('[NATIVE_STREAM_ERROR] $e');
    });
    unawaited(_loadDeviceInfo());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _comparisonUrlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    final Map<String, dynamic> info = await _service.getDeviceInfo();
    final Map<String, dynamic> trust = await _service.inspectTrustStore();
    if (!mounted) return;
    setState(() {
      _deviceInfo = info;
      _trustStore = trust;
    });
  }

  void _onNativeEvent(NetworkDiagnosticEvent event) {
    _append(event.toDisplayLine());
    if (event.scope == 'RUN' && event.stage == 'FINISHED') {
      if (mounted) setState(() => _running = false);
    }
  }

  List<String> _targets() {
    final List<String> values = List<String>.from(_vnuTargets);
    final String custom = _comparisonUrlController.text.trim();
    if (custom.isNotEmpty) values.add(custom);
    return values;
  }

  Future<void> _runAll() async {
    if (_running) return;

    final List<String> targets = _targets();
    setState(() {
      _running = true;
      _lines.clear();
    });

    _append('=== ONEVNU NETWORK / TLS DIAGNOSTIC ===');
    _append(_deviceSummary());
    _append(_trustSummary());
    _append(
      'Lưu ý: kiểm tra dùng trust store mặc định của Android. Không bỏ qua TLS và không ghi mật khẩu/token.',
    );

    final List<NetworkDiagnosticEvent> dartEvents =
        await _service.runDartHttpClientDiagnostics(targets);
    for (final NetworkDiagnosticEvent event in dartEvents) {
      _append(event.toDisplayLine());
    }

    final Map<String, dynamic> started =
        await _service.runNativeDiagnostics(targets);
    if (started['started'] != true) {
      _append('[NATIVE_NOT_STARTED] $started');
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _stop() async {
    await _service.stopNativeDiagnostics();
    if (!mounted) return;
    setState(() => _running = false);
    _append('[RUN] STOP_REQUESTED');
  }

  void _append(String value) {
    if (!mounted) return;
    setState(() {
      _lines.add(value);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  String _deviceSummary() {
    return 'DEVICE: ${_deviceInfo['manufacturer'] ?? ''} '
        '${_deviceInfo['model'] ?? ''}; '
        'Android ${_deviceInfo['androidRelease'] ?? '?'} '
        '(SDK ${_deviceInfo['sdkInt'] ?? '?'}); '
        'SecurityPatch=${_deviceInfo['securityPatch'] ?? '?'}; '
        'WebView=${_deviceInfo['webViewPackage'] ?? '?'} '
        '${_deviceInfo['webViewVersion'] ?? '?'}; '
        'Chrome=${_deviceInfo['chromeVersion'] ?? '?'}';
  }

  String _trustSummary() {
    return 'TRUST: GlobalSign Root R46=${_boolLabel(_trustStore['globalSignRootR46Present'])}; '
        'Root R3=${_boolLabel(_trustStore['globalSignRootR3Present'])}; '
        'Root R6=${_boolLabel(_trustStore['globalSignRootR6Present'])}; '
        'CA count=${_trustStore['certificateCount'] ?? '?'}';
  }

  String _boolLabel(dynamic value) => value == true ? 'CÓ' : 'KHÔNG';

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _lines.join('\n\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép nhật ký chẩn đoán.')),
    );
  }

  Color _levelColor(String line) {
    if (line.contains('[ERROR]') || line.contains('FAILED')) {
      return Colors.red.shade700;
    }
    if (line.contains('[WARN]')) return Colors.orange.shade800;
    if (line.contains('[OK]') || line.contains('HTTP_REACHED')) {
      return Colors.green.shade700;
    }
    return const Color(0xFF25324B);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Chẩn đoán kết nối VNU'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sao chép log',
            onPressed: _lines.isEmpty ? null : _copy,
            icon: const Icon(Icons.copy_all_outlined),
          ),
          IconButton(
            tooltip: 'Xóa log',
            onPressed: _lines.isEmpty
                ? null
                : () => setState(() => _lines.clear()),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildDeviceCard(),
            _buildControlPanel(),
            Expanded(child: _buildConsole()),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard() {
    final bool r46 = _trustStore['globalSignRootR46Present'] == true;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E6EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Thiết bị & kho chứng thư',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(_deviceSummary()),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Icon(
                r46 ? Icons.verified_rounded : Icons.warning_amber_rounded,
                size: 20,
                color: r46 ? Colors.green : Colors.orange.shade800,
              ),
              const SizedBox(width: 7),
              Expanded(child: Text(_trustSummary())),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Diagnostic này kiểm tra 4 lớp: Dart HttpClient → Android SSLSocket → '
            'HttpsURLConnection → Android WebView. Custom Tab/Chrome là tiến trình khác nên '
            'log nội bộ của nó chỉ ADB logcat mới xem đầy đủ 100%.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF667085)),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E6EF)),
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _comparisonUrlController,
            enabled: !_running,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'URL đối chứng (ví dụ web nhà trọ) - không bắt buộc',
              hintText: 'https://...',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _running ? null : _runAll,
                  icon: _running
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check_rounded),
                  label: Text(_running ? 'Đang kiểm tra...' : 'Kiểm tra toàn bộ'),
                ),
              ),
              if (_running) ...<Widget>[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _stop,
                  child: const Text('Dừng'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsole() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E6EF)),
      ),
      child: _lines.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nhấn “Kiểm tra toàn bộ” để xem trực tiếp lỗi DNS / TLS / HTTPS / WebView trên thiết bị này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF667085), height: 1.5),
                ),
              ),
            )
          : ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _lines.length,
              separatorBuilder: (_, __) => const Divider(height: 18),
              itemBuilder: (BuildContext context, int index) {
                final String line = _lines[index];
                return SelectableText(
                  line,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.45,
                    color: _levelColor(line),
                  ),
                );
              },
            ),
    );
  }
}
