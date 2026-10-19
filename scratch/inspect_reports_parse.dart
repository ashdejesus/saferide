import 'dart:io';

void main() {
  final lines = File('saferide_passenger_reports.csv').readAsLinesSync();
  print('Total lines in file: ${lines.length}');
  var dataRows = 0;
  var validCols = 0;
  var outOfPh = 0;
  var badTs = 0;
  final phLatMin = 4.0, phLatMax = 21.0, phLonMin = 116.0, phLonMax = 128.0;

  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    dataRows++;
    final cols = line.split(',');
    if (cols.length < 14) {
      print('Row $i has ${cols.length} cols: $line');
      continue;
    }
    validCols++;
    final lat = double.tryParse(cols[5].trim()) ?? 0;
    final lon = double.tryParse(cols[6].trim()) ?? 0;
    if (lat < phLatMin || lat > phLatMax || lon < phLonMin || lon > phLonMax) {
      outOfPh++;
      print('Row $i out of PH: lat=$lat, lon=$lon, id=${cols[0]}');
    }
    final ts = DateTime.tryParse(cols[7].trim().replaceAll('Z', ''));
    if (ts == null) {
      badTs++;
      print('Row $i bad ts: ${cols[7]}');
    }
  }
  print('Data rows: $dataRows, validCols: $validCols, outOfPh: $outOfPh, badTs: $badTs');
}
