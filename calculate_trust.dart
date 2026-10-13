import 'dart:io';

void main() {
  final lines = File('passenger_reports.csv').readAsLinesSync();
  if (lines.isEmpty) return;

  final headers = lines[0].split(',');
  final passengerIdx = headers.indexOf('passengerId');
  final isVerifiedIdx = headers.indexOf('isVerified');
  final isFlaggedIdx = headers.indexOf('isFlagged');

  final Map<String, List<Map<String, dynamic>>> userReports = {};

  for (int i = 1; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) continue;
    final row = lines[i].split(',');
    if (row.length <= passengerIdx) continue;

    final passengerId = row[passengerIdx];
    final isVerified = row[isVerifiedIdx].toLowerCase() == 'true';
    final isFlagged = row[isFlaggedIdx].toLowerCase() == 'true';

    userReports.putIfAbsent(passengerId, () => []);
    userReports[passengerId]!.add({
      'isVerified': isVerified,
      'isFlagged': isFlagged
    });
  }

  print('User ID,Total Reports,Conforming Reports,Credibility (Trust Score)');
  for (var entry in userReports.entries) {
    final total = entry.value.length;
    final conforming = entry.value.where((r) => r['isFlagged'] == false).length;
    final credibility = conforming / total; // Basic formula
    print('${entry.key},$total,$conforming,$credibility');
  }
}
