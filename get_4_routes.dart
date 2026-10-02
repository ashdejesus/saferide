import 'dart:convert';
import 'dart:io';

void main() async {
  final routes = [
    {'name': 'route_calamba', 'coords': '121.1561,14.2046;121.1293,14.2183'}, // SM Calamba to Mayapa
    {'name': 'route_cabuyao', 'coords': '121.1278,14.2561;121.1235,14.2753'}, // Pulo to Cabuyao Proper
    {'name': 'route_starosa', 'coords': '121.1098,14.2983;121.0545,14.2389'}, // Balibago to Nuvali
    {'name': 'route_binan',   'coords': '121.0965,14.3168;121.0858,14.3315'}, // Pavilion to Olivarez
  ];

  final buffer = StringBuffer();
  buffer.writeln('class MockRoutes {');

  for (var r in routes) {
    print('Fetching ${r['name']}...');
    final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/${r['coords']}?geometries=geojson&overview=full');
    final req = await HttpClient().getUrl(url);
    final res = await req.close();
    final data = await res.transform(utf8.decoder).join();
    final json = jsonDecode(data);
    
    if (json['routes'] == null || json['routes'].isEmpty) {
       print('Error fetching ${r['name']}');
       continue;
    }
    final coords = json['routes'][0]['geometry']['coordinates'] as List;
    final dartList = coords.map((c) => "{'lat': ${c[1]}, 'lng': ${c[0]}}").join(',\n');
    
    buffer.writeln('  static const ${r['name']} = [');
    buffer.writeln(dartList);
    buffer.writeln('  ];\n');
  }

  buffer.writeln('}');
  await File('lib/data/mock_routes.dart').writeAsString(buffer.toString());
  print('Done! mock_routes.dart updated.');
}
