import 'dart:io';

void main() {
  final text = File('docx_clean.txt').readAsStringSync();
  print(text);
}
