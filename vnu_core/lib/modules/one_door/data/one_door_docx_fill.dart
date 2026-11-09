import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Inspects *the DOCX bytes*, not only the HTTP 200 response. Word templates
/// can split {YeuCau} across w:t runs; every paragraph is inspected as a whole.
/// No text values are written to API Debug and nothing is sent to a third party.
class OneDoorDocxInspection {
  const OneDoorDocxInspection({
    required this.hasMainDocument,
    required this.hasYeuCauPlaceholder,
    required this.hasExpectedYeuCau,
  });
  final bool hasMainDocument;
  final bool hasYeuCauPlaceholder;
  final bool hasExpectedYeuCau;
}

class OneDoorDocxFillResult {
  const OneDoorDocxFillResult({
    required this.bytes,
    required this.replacements,
    required this.inspection,
  });
  final List<int> bytes;
  final int replacements;
  final OneDoorDocxInspection inspection;
}

/// Local safety net for DOCX preview. It is used ONLY for an API-created DOCX
/// and, if necessary, the corresponding official raw template. The exact
/// resulting bytes are attached and later submitted, so preview != upload
/// can never happen because of this helper.
class OneDoorDocxFill {
  OneDoorDocxFill._();

  static const int _maxCompressed = 10 * 1024 * 1024;
  static const int _maxXmlBytes = 6 * 1024 * 1024;
  static const int _maxFileCount = 2500;
  static const int _maxTotalExpanded = 80 * 1024 * 1024;
  static final RegExp _placeholder = RegExp(r'\{\s*([A-Za-z][A-Za-z0-9_]*)\s*\}');

  static Archive _decode(List<int> bytes) {
    if (bytes.isEmpty || bytes.length > _maxCompressed) {
      throw const FormatException('DOCX trống hoặc vượt quá 10 MB.');
    }
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    if (archive.files.isEmpty || archive.files.length > _maxFileCount) {
      throw const FormatException('DOCX có số thành phần bất thường.');
    }
    var total = 0;
    for (final entry in archive.files) {
      if (entry.name.startsWith('_xmlsignatures/')) {
        // Never rewrite a digitally signed Office document.
        throw const FormatException('DOCX có chữ ký số; không thể sửa nội dung.');
      }
      total += entry.size;
      if (entry.size > _maxTotalExpanded || total > _maxTotalExpanded) {
        throw const FormatException('Tệp DOCX giải nén vượt giới hạn an toàn.');
      }
    }
    return archive;
  }

  static bool _isWordXml(String name) =>
      name == 'word/document.xml' ||
      RegExp(r'^word/(header|footer)[0-9]+\.xml$').hasMatch(name);

  static Iterable<XmlElement> _paragraphs(XmlDocument doc) => doc.descendants
      .whereType<XmlElement>()
      .where((node) => node.localName == 'p');

  static List<XmlElement> _textNodes(XmlElement paragraph) => paragraph.descendants
      .whereType<XmlElement>()
      .where((node) => node.localName == 't')
      .toList();

  static String _paragraphText(XmlElement paragraph) =>
      _textNodes(paragraph).map((node) => node.innerText).join();

  static OneDoorDocxInspection inspect(List<int> bytes, String expectedYeuCau) {
    final archive = _decode(bytes);
    var hasMain = false;
    var hasPlaceholder = false;
    var hasExpected = false;
    for (final entry in archive.files) {
      if (!entry.isFile || !_isWordXml(entry.name)) continue;
      if (entry.name == 'word/document.xml') hasMain = true;
      if (entry.size > _maxXmlBytes) {
        throw const FormatException('Phần XML trong DOCX quá lớn.');
      }
      final data = entry.readBytes();
      if (data == null) throw const FormatException('Không đọc được XML của DOCX.');
      final doc = XmlDocument.parse(utf8.decode(data));
      for (final paragraph in _paragraphs(doc)) {
        final content = _paragraphText(paragraph);
        if (RegExp(r'\{\s*YeuCau\s*\}', caseSensitive: false).hasMatch(content)) {
          hasPlaceholder = true;
        }
        if (expectedYeuCau.trim().isNotEmpty &&
            content.contains(expectedYeuCau.trim())) {
          hasExpected = true;
        }
      }
    }
    return OneDoorDocxInspection(
      hasMainDocument: hasMain,
      hasYeuCauPlaceholder: hasPlaceholder,
      hasExpectedYeuCau: hasExpected,
    );
  }

  /// Locally fills placeholders that remain in the server output, or rebuilds
  /// an entire preview from the official template when needed. Plain XML text
  /// replacement is not sufficient: Word may split {YeuCau} into many w:t runs.
  /// This method edits only Word XML text nodes, preserving tables, styles,
  /// media and relationships in the DOCX package.
  static OneDoorDocxFillResult fill(List<int> bytes, Map<String, String> values) {
    final archive = _decode(bytes);
    final normalized = <String, String>{
      for (final entry in values.entries) entry.key.toLowerCase(): entry.value,
    };
    final output = Archive();
    var changes = 0;
    var hasMain = false;
    for (final entry in archive.files) {
      if (!entry.isFile) {
        output.addFile(ArchiveFile.directory(entry.name));
        continue;
      }
      final data = entry.readBytes();
      if (data == null) throw const FormatException('Không đọc được DOCX.');
      if (!_isWordXml(entry.name)) {
        output.addFile(ArchiveFile.bytes(entry.name, data));
        continue;
      }
      if (entry.name == 'word/document.xml') hasMain = true;
      if (data.length > _maxXmlBytes) {
        throw const FormatException('XML trong DOCX vượt giới hạn an toàn.');
      }
      final doc = XmlDocument.parse(utf8.decode(data));
      var partChanges = 0;
      for (final paragraph in _paragraphs(doc)) {
        partChanges += _fillParagraph(paragraph, normalized);
      }
      changes += partChanges;
      output.addFile(ArchiveFile.bytes(entry.name, partChanges == 0
          ? data : Uint8List.fromList(utf8.encode(doc.toXmlString()))));
    }
    if (!hasMain) throw const FormatException('DOCX thiếu word/document.xml.');
    final updated = changes == 0 ? bytes : ZipEncoder().encode(output);
    if (updated.length > _maxCompressed) {
      throw const FormatException('DOCX đã điền vượt quá 10 MB.');
    }
    final inspection = inspect(updated, values['YeuCau'] ?? '');
    return OneDoorDocxFillResult(
      bytes: updated,
      replacements: changes,
      inspection: inspection,
    );
  }

  static int _fillParagraph(XmlElement paragraph, Map<String, String> values) {
    final nodes = _textNodes(paragraph);
    if (nodes.isEmpty) return 0;
    final original = nodes.map((node) => node.innerText).join();
    final matches = _placeholder.allMatches(original)
        .where((match) => values.containsKey(match.group(1)!.toLowerCase()))
        .toList();
    if (matches.isEmpty) return 0;
    // Edit right to left so offsets of earlier placeholders stay valid.
    for (final match in matches.reversed) {
      final replacement = values[match.group(1)!.toLowerCase()]!;
      var currentPosition = 0;
      int startNode = -1;
      int endNode = -1;
      int startOffset = 0;
      int endOffset = 0;
      for (var i = 0; i < nodes.length; i++) {
        final length = nodes[i].innerText.length;
        if (startNode < 0 && match.start < currentPosition + length) {
          startNode = i;
          startOffset = match.start - currentPosition;
        }
        if (startNode >= 0 && match.end <= currentPosition + length) {
          endNode = i;
          endOffset = match.end - currentPosition;
          break;
        }
        currentPosition += length;
      }
      if (startNode < 0 || endNode < 0) {
        throw const FormatException('Không xác định được vị trí biến Word.');
      }
      final first = nodes[startNode].innerText;
      final last = nodes[endNode].innerText;
      if (startNode == endNode) {
        nodes[startNode].innerText = first.substring(0, startOffset) +
            replacement + last.substring(endOffset);
      } else {
        nodes[startNode].innerText = first.substring(0, startOffset) + replacement;
        for (var i = startNode + 1; i < endNode; i++) {
          nodes[i].innerText = '';
        }
        nodes[endNode].innerText = last.substring(endOffset);
      }
      for (var i = startNode; i <= endNode; i++) {
        nodes[i].setAttribute('xml:space', 'preserve');
      }
    }
    return matches.length;
  }
}
