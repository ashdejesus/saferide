import 'dart:io';
import 'dart:convert';

void main() {
  final f = File(r'C:\Users\nicho\.gemini\antigravity-ide\brain\c103eeb6-7ec7-4fb4-8862-da50fa45b556\.system_generated\logs\transcript_full.jsonl');
  for (final line in f.readAsLinesSync()) {
    if (line.contains('The revision is an improvement')) {
      final json = jsonDecode(line);
      File('scratch/prompt9_full.txt').writeAsStringSync(json['content'] as String);
      print('Saved full prompt 9');
      break;
    }
  }
}
