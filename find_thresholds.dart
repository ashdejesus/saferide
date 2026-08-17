import 'dart:io';

void main() {
  final text = File('docx_temp_utf8.txt').readAsStringSync();
  int idx = 0;
  while (true) {
    idx = text.indexOf('(1+', idx);
    if (idx == -1) break;
    print(text.substring(idx > 100 ? idx - 100 : 0, idx + 100).replaceAll('\n', ' '));
    idx += 3;
    print('---');
  }
}
