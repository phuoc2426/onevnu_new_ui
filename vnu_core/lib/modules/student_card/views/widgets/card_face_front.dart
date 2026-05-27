
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'fit_text.dart';

class CardFaceFront extends StatelessWidget {
  const CardFaceFront({
    super.key,
    required this.hoTen,
    required this.maSV,
    required this.ngaySinh,
    required this.GT,
    required this.khoaHoc,
    required this.khoa,
    required this.tenDonVi,
    required this.iconDonVi,
    required this.chuongTrinhDaoTao,
    required this.He,
    required this.HSD,
    required this.nganhHoc,
  });

  final String hoTen;
  final String maSV;
  final String ngaySinh;
  final String GT;
  final String khoaHoc;
  final String khoa;
  final String tenDonVi;
  final Widget iconDonVi;
  final String chuongTrinhDaoTao;
  final String He;
  final String HSD;
  final String nganhHoc;

  String _group4(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    final p = (d.isEmpty ? '0000000000000000' : d.padRight(16, '0')).substring(0, 16);
    return '${p.substring(0,4)} ${p.substring(4,8)} ${p.substring(8,12)} ${p.substring(12,16)}';
  }

  String _random16() {
    final rnd = math.Random();
    return List.generate(16, (_) => rnd.nextInt(10)).join();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF0C8C3A);
    const placeholder = Color(0xFFFFF3CD);

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight == double.infinity ? w * 54 / 86 : c.maxHeight;
      // base sizes
      final tHeader = w * 0.032;
      final tTitle  = w * 0.080;
      final tBody   = w * 0.038;
      final tMono   = w * 0.040;

      final bottomLine = _group4(_random16());

      return AspectRatio(
        aspectRatio: 86/54,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== A: Header (25% height) =====
                SizedBox(
                  height: (h * 0.25),
                  child: Container(
                    color: green,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // A1: logo trường (dùng icon tạm)
                        SizedBox(
                          width: w * 0.12,
                          child: Center(
                            child: iconDonVi, // theo API cũ; nếu chưa có thì dùng Icon
                          ),
                        ),
                        // A2: tên trường
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FitText('ĐẠI HỌC QUỐC GIA HÀ NỘI',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                  maxLines: 1, maxSize: tHeader, minSize: tHeader * .75),
                              FitText(tenDonVi.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  maxLines: 1, maxSize: tHeader * .95, minSize: tHeader * .7),
                            ],
                          ),
                        ),
                        // A3: logo BIDV tạm
                        SizedBox(
                          width: w * 0.12,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                              child: FitText('BIDV',
                                  maxLines: 1,
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                                  maxSize: tHeader, minSize: tHeader * .6),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                // ===== B: Thân (75% height) =====
                Expanded(
                  child: LayoutBuilder(builder: (context, bc) {
                    final bh = bc.maxHeight;
                    return Column(
                      children: [
                        // B1 + B2 chiếm 85% chiều cao B
                        SizedBox(
                          height: bh * 0.85,
                          child: Row(
                            children: [
                              // ---- B1: 30% chiều dài (rộng) ----
                              Expanded(
                                flex: 30,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Ảnh SV (placeholder)
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: placeholder,
                                          border: Border.all(color: const Color(0xFFBDBDBD)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Center(child: Icon(Icons.account_box, size: 56, color: Colors.black54)),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Mã SV
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFBDBDBD)),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: FitText('Mã SV: ' + (maSV.isEmpty ? '________' : maSV),
                                          maxLines: 1,
                                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                                          maxSize: tBody, minSize: tBody * .65),
                                    ),
                                    const SizedBox(height: 6),
                                    // Barcode từ mã SV (simple painter)
                                    SizedBox(
                                      height: 36,
                                      child: CustomPaint(
                                        painter: _SimpleBarcodePainter(maSV),
                                        child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // ---- B2: 70% chiều dài (rộng) ----
                              Expanded(
                                flex: 70,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Tiêu đề
                                    FitText('THẺ SINH VIÊN',
                                        style: const TextStyle(color: Color(0xFFCC0000), fontWeight: FontWeight.w900),
                                        maxLines: 1, maxSize: tTitle, minSize: tTitle * .6),
                                    const SizedBox(height: 6),
                                    // B22: thông tin cuộn
                                    Expanded(
                                      child: Scrollbar(
                                        thumbVisibility: false,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _info('Họ và tên', hoTen, tBody, bold: true),
                                              _info('Ngày sinh', ngaySinh, tBody),
                                              _info('GT', GT, tBody),
                                              _info('Khóa học', khoaHoc, tBody),
                                              _info('Hệ', He, tBody),
                                              _info('HSD', HSD, tBody),
                                              _info('Khoa', khoa, tBody),
                                              _info('CTĐT', chuongTrinhDaoTao, tBody, maxLines: 2),
                                              _info('Ngành học', nganhHoc, tBody, maxLines: 2),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ---- B3: 100% chiều dài, 15% chiều cao của B ----
                        SizedBox(
                          height: bh * 0.15,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: FitText(
                                bottomLine,
                                maxLines: 1,
                                style: const TextStyle(fontFamily: 'RobotoMono', fontWeight: FontWeight.w700, letterSpacing: 3.0),
                                maxSize: tMono, minSize: tMono * .6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _info(String label, String value, double size, {bool bold = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FitText(
        '$label: ' + value,
        maxLines: maxLines,
        style: TextStyle(color: Colors.black, fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
        maxSize: size, minSize: size * .65,
      ),
    );
  }
}

/// A very simple barcode: draw narrow/wide bars based on digits; not standard but good placeholder.
class _SimpleBarcodePainter extends CustomPainter {
  _SimpleBarcodePainter(this.data);
  final String data;

  @override
  void paint(Canvas canvas, Size size) {
    final d = (data.isEmpty ? '000000000000' : data.replaceAll(RegExp(r'\D'), ''));
    final paint = Paint()..color = Colors.black;
    final bg = Paint()..color = const Color(0xFFFFF3CD);
    // background placeholder
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4));
    canvas.drawRRect(rrect, bg);

    double x = 2;
    final h = size.height - 4;
    for (int i = 0; i < d.length; i++) {
      final v = int.parse(d[i]);
      final w = 1.0 + (v % 3); // 1..3 px width
      canvas.drawRect(Rect.fromLTWH(x, 2, w, h), paint);
      x += w + 1; // 1 px gap
      if (x > size.width - 2) break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
