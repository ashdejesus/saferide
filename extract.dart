import 'dart:io';

void main() {
  final text = File('docx_clean.txt').readAsStringSync();
  final index = text.indexOf('Statement of the Problem', 2000); // Skip Table of Contents
  if (index != -1) {
    final end = (index + 3000 < text.length) ? index + 3000 : text.length;
    print(text.substring(index, end));
  } else {
    print('Not found after TOC');
  }
}
