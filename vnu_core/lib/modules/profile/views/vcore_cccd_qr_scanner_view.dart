import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CccdQrScanResult {
  const CccdQrScanResult({
    required this.cccd,
    required this.fullName,
    required this.dateOfBirth,
  });

  final String cccd;
  final String fullName;
  final DateTime dateOfBirth;
}

/// Quét QR in trên thẻ CCCD.
///
/// Scanner chỉ đọc/parse dữ liệu. Việc xác minh authoritative vẫn chỉ chạy
/// khi người dùng bấm "Cập nhật" ở màn Thông tin cá nhân.
class VcoreCccdQrScannerView extends StatefulWidget {
  const VcoreCccdQrScannerView({
    super.key,
    this.trainingStudentCode = '',
    this.trainingFullName = '',
    this.trainingDateOfBirth,
  });

  final String trainingStudentCode;
  final String trainingFullName;
  final DateTime? trainingDateOfBirth;

  @override
  State<VcoreCccdQrScannerView> createState() =>
      _VcoreCccdQrScannerViewState();
}

class _VcoreCccdQrScannerViewState extends State<VcoreCccdQrScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );

  bool _processing = false;
  String? _error;
  CccdQrScanResult? _previewResult;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;

    String raw = '';
    for (final Barcode barcode in capture.barcodes) {
      final String value = barcode.rawValue?.trim() ?? '';
      if (value.isNotEmpty) {
        raw = value;
        break;
      }
    }
    if (raw.isEmpty) return;

    _processing = true;
    await _controller.stop();

    final CccdQrScanResult? result = _parseCccdQr(raw);
    if (!mounted) return;

    setState(() {
      _previewResult = result;
      _error = result == null
          ? 'Không đọc được đầy đủ CCCD, họ tên và ngày sinh từ mã QR. '
              'Vui lòng đưa đúng mã QR trên thẻ căn cước vào khung hình.'
          : null;
    });
  }

  Future<void> _scanAgain() async {
    if (!mounted) return;
    setState(() {
      _previewResult = null;
      _error = null;
      _processing = false;
    });
    try {
      await _controller.start();
    } catch (_) {
      // Camera lifecycle có thể đang khởi động lại.
    }
  }

  void _usePreview() {
    final CccdQrScanResult? result = _previewResult;
    if (result == null || !mounted) return;
    Navigator.of(context).pop<CccdQrScanResult>(result);
  }

  CccdQrScanResult? _parseCccdQr(String raw) {
    // QR CCCD chuẩn thường có dạng:
    // CCCD|CMND_cu|HO_TEN|DDMMYYYY|GIOI_TINH|DIA_CHI|NGAY_CAP|...
    //
    // QUAN TRỌNG: phải giữ cả field rỗng. Ví dụ:
    // 036203012334||Lê Minh Phước|24092003|Nam|...|12112025||||
    // Nếu loại field rỗng sau CCCD thì họ tên/ngày sinh sẽ bị lệch index.
    final List<String> parts = splitCccdQrFields(raw);

    String cccd = '';
    if (parts.isNotEmpty && RegExp(r'^\d{12}$').hasMatch(parts[0])) {
      cccd = parts[0];
    } else {
      for (final String part in parts) {
        if (RegExp(r'^\d{12}$').hasMatch(part)) {
          cccd = part;
          break;
        }
      }
    }
    if (cccd.isEmpty) return null;

    String fullName = '';
    if (parts.length > 2 && _looksLikePersonName(parts[2])) {
      fullName = parts[2].trim();
    }

    DateTime? dob;
    if (parts.length > 3) {
      dob = parseCccdDateOfBirth(parts[3]);
    }

    // Fallback cho reader không giữ đúng vị trí trường.
    // Với ngày sinh, nếu có nhiều ngày 8 số (ngày sinh + ngày cấp), chọn ngày
    // sớm nhất để tránh nhầm ngày cấp CCCD thành ngày sinh.
    if (dob == null) {
      final List<DateTime> candidates = <DateTime>[];
      for (final String part in parts) {
        final DateTime? candidate = parseCccdDateOfBirth(part);
        if (candidate != null) candidates.add(candidate);
      }
      if (candidates.isNotEmpty) {
        candidates.sort((DateTime a, DateTime b) => a.compareTo(b));
        dob = candidates.first;
      }
    }
    if (dob == null) return null;

    // Nếu tên không ở index chuẩn, ưu tiên chuỗi chữ ngay trước field ngày sinh.
    if (fullName.isEmpty) {
      int dobIndex = -1;
      for (int i = 0; i < parts.length; i++) {
        final DateTime? candidate = parseCccdDateOfBirth(parts[i]);
        if (candidate != null && sameCalendarDate(candidate, dob)) {
          dobIndex = i;
          break;
        }
      }
      if (dobIndex > 0) {
        for (int i = dobIndex - 1; i >= 0; i--) {
          if (_looksLikePersonName(parts[i])) {
            fullName = parts[i].trim();
            break;
          }
        }
      }
    }

    if (fullName.isEmpty) return null;

    return CccdQrScanResult(
      cccd: cccd,
      fullName: fullName,
      dateOfBirth: dob,
    );
  }

  bool _looksLikePersonName(String value) {
    final String text = value.trim();
    if (text.isEmpty) return false;
    if (!RegExp(r'[A-Za-zÀ-ỹĐđ]').hasMatch(text)) return false;
    final String normalized = normalizeCccdName(text);
    if (normalized == 'NAM' || normalized == 'NU') return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quét QR căn cước công dân'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(controller: _controller, onDetect: _onDetect),
          IgnorePointer(
            child: Container(color: Colors.black.withOpacity(0.16)),
          ),
          SafeArea(
            child: _previewResult == null && _error == null
                ? _buildScanInstruction()
                : _buildParsedResultCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanInstruction() {
    return Column(
      children: <Widget>[
        const Spacer(),
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.78),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 34,
              ),
              SizedBox(height: 10),
              Text(
                'Đưa mã QR trên thẻ căn cước vào khung hình. '
                'Sau khi quét, hãy đối chiếu họ tên và ngày sinh trước khi sử dụng dữ liệu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParsedResultCard() {
    final CccdQrScanResult? result = _previewResult;
    final DateTime? trainingDob = widget.trainingDateOfBirth?.toLocal();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111815).withOpacity(0.97),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.badge_outlined, color: Color(0xFF70D69A)),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Thông tin đọc từ căn cước',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (result != null) ...<Widget>[
              _infoRow('CCCD', result.cccd, boldValue: true),
              const SizedBox(height: 9),
              _nameCompareBlock(
                label: 'Họ tên trên CCCD',
                value: normalizeCccdName(result.fullName),
              ),
              const SizedBox(height: 9),
              _nameCompareBlock(
                label: 'Họ tên dữ liệu đào tạo',
                value: normalizeCccdName(widget.trainingFullName),
              ),
              const Divider(color: Colors.white24, height: 22),
              _infoRow(
                'Ngày sinh CCCD',
                formatCccdDate(result.dateOfBirth),
                boldValue: true,
              ),
              const SizedBox(height: 7),
              _infoRow(
                'Ngày sinh đào tạo',
                trainingDob == null ? '(chưa có)' : formatCccdDate(trainingDob),
                boldValue: true,
              ),
              const SizedBox(height: 12),
              const Text(
                'Hệ thống sẽ kiểm tra lại CCCD, họ tên và ngày sinh khi bạn bấm Cập nhật ở Thông tin cá nhân.',
                style: TextStyle(
                  color: Color(0xFF9CB1A4),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ] else ...<Widget>[
              Text(
                _error ?? 'Không đọc được QR căn cước.',
                style: const TextStyle(
                  color: Color(0xFFFFB4AB),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scanAgain,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Quét lại'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                  ),
                ),
                if (result != null) ...<Widget>[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _usePreview,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Sử dụng dữ liệu'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nameCompareBlock({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9CB1A4),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? '(CHƯA CÓ)' : value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            height: 1.2,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool boldValue = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 142,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9CB1A4),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: boldValue ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tách field QR nhưng KHÔNG loại field rỗng, vì `||` là một field hợp lệ
/// trong payload CCCD và quyết định vị trí của họ tên/ngày sinh.
List<String> splitCccdQrFields(String raw) {
  if (raw.contains('|')) {
    return raw
        .split('|')
        .map((String value) => value.trim())
        .toList(growable: false);
  }
  if (raw.contains(';')) {
    return raw
        .split(';')
        .map((String value) => value.trim())
        .toList(growable: false);
  }
  return raw
      .split(RegExp(r'[\r\n]+'))
      .map((String value) => value.trim())
      .toList(growable: false);
}

DateTime? parseCccdDateOfBirth(String value) {
  final String digits = value.replaceAll(RegExp(r'\D'), '');
  // Ngày sinh QR CCCD: DDMMYYYY, ví dụ 24092003 => 24/09/2003.
  if (digits.length != 8) return null;

  final int? day = int.tryParse(digits.substring(0, 2));
  final int? month = int.tryParse(digits.substring(2, 4));
  final int? year = int.tryParse(digits.substring(4, 8));
  if (day == null || month == null || year == null) return null;
  if (year < 1900 || year > DateTime.now().year) return null;

  final DateTime candidate = DateTime(year, month, day);
  if (candidate.year != year ||
      candidate.month != month ||
      candidate.day != day) {
    return null;
  }
  return candidate;
}

String normalizeCccdName(String value) {
  String result = value.toUpperCase();
  const Map<String, String> groups = <String, String>{
    'A': 'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ',
    'E': 'ÈÉẸẺẼÊỀẾỆỂỄ',
    'I': 'ÌÍỊỈĨ',
    'O': 'ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ',
    'U': 'ÙÚỤỦŨƯỪỨỰỬỮ',
    'Y': 'ỲÝỴỶỸ',
    'D': 'Đ',
  };
  for (final MapEntry<String, String> entry in groups.entries) {
    for (final int rune in entry.value.runes) {
      result = result.replaceAll(String.fromCharCode(rune), entry.key);
    }
  }
  return result
      .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool sameCalendarDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String formatCccdDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)}/${value.year.toString().padLeft(4, '0')}';
}
