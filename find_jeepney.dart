import 'dart:io';

void main() {
  final text = File('docx_temp_utf8.txt').readAsStringSync();
  int idx = 0;
  while (true) {
    idx = text.indexOf('Jeepney', idx);
    if (idx == -1) break;
    print(text.substring(idx - 50, idx + 50));
    idx += 7;
  }
}
