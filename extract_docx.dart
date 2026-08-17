import 'dart:io';

void main() {
  final text = File('docx_temp_utf8.txt').readAsStringSync();
  final formatted = text.replaceAll('. ', '.\n').replaceAll('  ', '\n');
  File('docx_paragraphs.txt').writeAsStringSync(formatted);
}
