import 'dart:io';

void main() async {
  final file = File('CSC2-MANUSCRIPT-PREORAL (1).pdf');
  final server = await HttpServer.bind('localhost', 9876);
  print('Serving PDF at http://localhost:9876/');
  await for (final req in server) {
    req.response.headers.contentType = ContentType('application', 'pdf');
    req.response.headers.add('Access-Control-Allow-Origin', '*');
    await req.response.addStream(file.openRead());
    await req.response.close();
  }
}
