import 'dart:io';

void main() {
  final text = File('docx_temp_utf8.txt').readAsStringSync();
  final lines = text.split('\n');
  for (int i = 0; i < lines.length; i++) {
    var line = lines[i];
    if (line.contains('40') || line.contains('8.0') || line.contains('4.5') || line.contains('2.5')) {
      print(line);
    }
  }
}
