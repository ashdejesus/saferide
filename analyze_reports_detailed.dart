import 'dart:io';

void main() {
  final lines = File('passenger_reports.csv').readAsLinesSync();
  print('Total lines in passenger_reports.csv: ${lines.length}');
  final headers = lines[0].split(',');
  final isVerIdx = headers.indexOf('isVerified');
  final isFlagIdx = headers.indexOf('isFlagged');
  final verCountIdx = headers.indexOf('verificationCount');
  final tripIdIdx = headers.indexOf('tripId');
  final sevIdx = headers.indexOf('severity');
  final catIdx = headers.indexOf('category');

  int verifiedTrue = 0;
  int verifiedFalse = 0;
  int flaggedTrue = 0;
  int withTripId = 0;

  Map<String, int> categories = {};

  for (int i = 1; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) continue;
    final row = lines[i].split(',');
    if (row.length <= isVerIdx) continue;

    bool isVer = row[isVerIdx].toLowerCase() == 'true';
    bool isFlag = row[isFlagIdx].toLowerCase() == 'true';
    String tripId = row[tripIdIdx].trim();
    String cat = row[catIdx].trim();

    if (isVer) verifiedTrue++; else verifiedFalse++;
    if (isFlag) flaggedTrue++;
    if (tripId.isNotEmpty) withTripId++;
    categories[cat] = (categories[cat] ?? 0) + 1;
  }

  print('isVerified: true=$verifiedTrue, false=$verifiedFalse');
  print('isFlagged: true=$flaggedTrue');
  print('Reports associated with a tripId: $withTripId');
  print('\nCategories:');
  categories.forEach((k, v) => print('  $k: $v'));
}
