
import 'package:flutter/material.dart';
import 'fit_text.dart';

/// BACK – dùng FitText cho tất cả text để tự căn cỡ như bản cũ.
class CardFaceBack extends StatelessWidget {
  const CardFaceBack({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth;
      final body  = width * 0.034;
      final head  = width * 0.036;
      final tiny  = width * 0.030;

      return AspectRatio(
        aspectRatio: 86/54,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // black stripe
                Container(height: 40, color: Colors.black),
                // body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFBDBDBD)),
                            ),
                            child: CustomPaint(
                              painter: _DotPatternPainter(),
                              child: Container(
                                alignment: Alignment.topLeft,
                                padding: const EdgeInsets.all(10),
                                child: FitText("Chữ ký sinh viên\nStudent's signature",
                                    maxLines: 2,
                                    style: const TextStyle(color: Colors.black),
                                    maxSize: tiny, minSize: tiny * .7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FitText('QUY ĐỊNH SỬ DỤNG THẺ',
                                      maxLines: 1,
                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
                                      maxSize: head, minSize: head * .7),
                                  const SizedBox(height: 4),
                                  FitText('1. Thẻ sinh viên dùng trong quá trình đào tạo tại ĐHQGHN. Nghiêm cấm mượn, cho mượn thẻ.',
                                      maxLines: 3, maxSize: body, minSize: body * .7,
                                      style: const TextStyle(height: 1.2)),
                                  FitText('2. Việc sử dụng thẻ này phải tuân thủ các điều khoản, điều kiện do BIDV và ĐHQGHN quy định.',
                                      maxLines: 3, maxSize: body, minSize: body * .7,
                                      style: const TextStyle(height: 1.2)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Color(0xFFBDBDBD)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FitText('napas>', maxLines: 1,
                                      style: const TextStyle(fontWeight: FontWeight.w700), maxSize: body, minSize: body * .7),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Color(0xFFBDBDBD)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FitText('BIDV Card', maxLines: 1,
                                      style: const TextStyle(fontWeight: FontWeight.w700), maxSize: body, minSize: body * .7),
                                ),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 12, color: const Color(0xFF0C8C3A)),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFBDBDBD);
    const step = 6.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x + 2, y + 2), 0.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
