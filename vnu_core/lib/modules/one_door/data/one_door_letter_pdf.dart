import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Exports what the student actually previewed as a PDF attachment.
/// Screenshots are encoded as lossless RGB image streams, preserving Vietnamese
/// without requiring network fonts or modifying an official Word/PDF template.
/// Long documents are split into A4 pages instead of silently cutting content.
Future<String> exportOneDoorLetterPdf(GlobalKey previewKey) async {
  final context = previewKey.currentContext;
  final boundary = context?.findRenderObject();
  if (boundary is! RenderRepaintBoundary || boundary.debugNeedsPaint) {
    throw StateError('Bản xem trước chưa sẵn sàng. Vui lòng thử lại.');
  }
  if (boundary.size.width <= 0 || boundary.size.height <= 0) {
    throw StateError('Không thể đo kích thước đơn.');
  }
  // Protect constrained mobile devices from huge raster captures.
  if (boundary.size.height > 842 * 4.0) {
    throw StateError('Đơn dài hơn 4 trang A4. Vui lòng rút gọn nội dung.');
  }
  const pixelRatio = 2.0;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (raw == null) throw StateError('Không thể kết xuất bản xem trước.');
    final width = image.width;
    final height = image.height;
    final rgba = raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes);
    if (rgba.length < width * height * 4) {
      throw StateError('Dữ liệu ảnh tài liệu không đầy đủ.');
    }
    final rowsPerPage = math.max(1, (width * 842 / 595).floor());
    final pageCount = (height / rowsPerPage).ceil();
    final writer = _SimpleA4PdfWriter(pageCount);
    for (var page = 0; page < pageCount; page++) {
      final startRow = page * rowsPerPage;
      final rows = math.min(rowsPerPage, height - startRow);
      final rgb = Uint8List(width * rows * 3);
      for (var y = 0; y < rows; y++) {
        var source = ((startRow + y) * width) * 4;
        var target = y * width * 3;
        for (var x = 0; x < width; x++) {
          final a = rgba[source + 3];
          // White blend any transparent pixels, as a printed page does.
          for (var c = 0; c < 3; c++) {
            final value = rgba[source + c];
            rgb[target + c] = a == 255
                ? value
                : ((value * a + 255 * (255 - a)) ~/ 255);
          }
          source += 4;
          target += 3;
        }
      }
      writer.addPage(width, rows, ZLibEncoder().convert(rgb));
    }
    final directory = await getTemporaryDirectory();
    final filename = 'onevnu_don_${DateTime.now().microsecondsSinceEpoch}.pdf';
    final file = File('${directory.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(writer.finish(), flush: true);
    return file.path;
  } finally {
    image.dispose();
  }
}

class _SimpleA4PdfWriter {
  _SimpleA4PdfWriter(this.pageCount);
  final int pageCount;
  final BytesBuilder _bytes = BytesBuilder(copy: false);
  final List<int> _offsets = <int>[0];
  int _length = 0;
  int _currentPage = 0;

  void _text(String value) {
    final bytes = latin1.encode(value);
    _bytes.add(bytes);
    _length += bytes.length;
  }

  void _binary(List<int> bytes) {
    _bytes.add(bytes);
    _length += bytes.length;
  }

  void _object(int id, String value) {
    _offsets.add(_length);
    _text('$id 0 obj\n$value\nendobj\n');
  }

  void _stream(int id, String header, List<int> data) {
    _offsets.add(_length);
    _text('$id 0 obj\n<< $header /Length ${data.length} >>\nstream\n');
    _binary(data);
    _text('\nendstream\nendobj\n');
  }

  void addPage(int width, int rows, List<int> flateRgb) {
    if (_currentPage == 0) {
      _text('%PDF-1.4\n');
      _object(1, '<< /Type /Catalog /Pages 2 0 R >>');
      final refs = List<String>.generate(pageCount, (i) => '${3 + i * 3} 0 R');
      _object(2, '<< /Type /Pages /Count $pageCount /Kids [${refs.join(' ')}] >>');
    }
    final pageId = 3 + _currentPage * 3;
    final contentsId = pageId + 1;
    final imageId = pageId + 2;
    final heightPt = rows * 595.0 / width;
    final y = 842.0 - heightPt;
    _object(pageId, '<< /Type /Page /Parent 2 0 R '
        '/MediaBox [0 0 595 842] '
        '/Resources << /XObject << /Im0 $imageId 0 R >> >> '
        '/Contents $contentsId 0 R >>');
    final command = 'q\n595 0 0 ${heightPt.toStringAsFixed(3)} 0 '
        '${y.toStringAsFixed(3)} cm\n/Im0 Do\nQ\n';
    _stream(contentsId, '', latin1.encode(command));
    _stream(imageId, '/Type /XObject /Subtype /Image '
        '/Width $width /Height $rows /ColorSpace /DeviceRGB '
        '/BitsPerComponent 8 /Filter /FlateDecode', flateRgb);
    _currentPage++;
  }

  Uint8List finish() {
    if (_currentPage != pageCount) {
      throw StateError('Số trang PDF không khớp.');
    }
    final startXref = _length;
    final size = 3 + pageCount * 3;
    _text('xref\n0 $size\n0000000000 65535 f \n');
    for (var id = 1; id < size; id++) {
      _text('${_offsets[id].toString().padLeft(10, '0')} 00000 n \n');
    }
    _text('trailer\n<< /Size $size /Root 1 0 R >>\n'
        'startxref\n$startXref\n%%EOF\n');
    return _bytes.takeBytes();
  }
}
