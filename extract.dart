import 'dart:io';

void main() {
  final text = File('docx_clean.txt').readAsStringSync();
  final start = text.indexOf('Mathematical Model Formulation');
  if (start != -1) {
    print(text.substring(start, start + 12000));
  } else {
    print('Not found');
  }
}
