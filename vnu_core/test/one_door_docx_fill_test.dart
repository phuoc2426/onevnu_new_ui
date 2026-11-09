import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnu_core/modules/one_door/data/one_door_docx_fill.dart';

List<int> buildFixture(String body) {
  final archive = Archive();
  archive.addFile(ArchiveFile.string('[Content_Types].xml',
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"/>'));
  archive.addFile(ArchiveFile.bytes('word/document.xml', utf8.encode(
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:body><w:p>$body</w:p></w:body></w:document>')));
  return ZipEncoder().encode(archive);
}

void main() {
  test('fills the original one-run YeuCau placeholder', () {
    final input = buildFixture('<w:r><w:t>Lý do chuyển đến {YeuCau}</w:t></w:r>');
    final result = OneDoorDocxFill.fill(input, {
      'YeuCau': 'Nộp địa phương', 'IdLyDo': '1',
    });
    expect(result.replacements, 1);
    expect(result.inspection.hasExpectedYeuCau, isTrue);
    expect(result.inspection.hasYeuCauPlaceholder, isFalse);
    expect(OneDoorDocxFill.inspect(input, 'Nộp địa phương')
        .hasYeuCauPlaceholder, isTrue);
  });

  test('fills YeuCau split across Word runs without losing suffix', () {
    final input = buildFixture('<w:r><w:t>Lý do {Yeu</w:t></w:r>'
        '<w:r><w:t>Cau}......</w:t></w:r>');
    final result = OneDoorDocxFill.fill(input, {
      'YeuCau': 'Nộp địa phương',
    });
    expect(result.replacements, 1);
    expect(result.inspection.hasExpectedYeuCau, isTrue);
    expect(result.inspection.hasYeuCauPlaceholder, isFalse);
  });

  test('escapes XML special characters and fills another field', () {
    final input = buildFixture('<w:r><w:t>{YeuCau} - {HoTen}</w:t></w:r>');
    final result = OneDoorDocxFill.fill(input, {
      'YeuCau': 'A & B < C', 'HoTen': 'Test',
    });
    expect(result.replacements, 2);
    expect(result.inspection.hasExpectedYeuCau, isTrue);
    expect(result.inspection.hasYeuCauPlaceholder, isFalse);
  });

  test('does not rewrite a template without any known placeholders', () {
    final input = buildFixture('<w:r><w:t>Document without variable</w:t></w:r>');
    final result = OneDoorDocxFill.fill(input, {'YeuCau': 'Nộp địa phương'});
    expect(result.replacements, 0);
    expect(result.bytes, input);
    expect(result.inspection.hasExpectedYeuCau, isFalse);
  });
}
