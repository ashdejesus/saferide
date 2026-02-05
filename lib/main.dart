import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'services/sync_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  final sync = SyncService(database);
  runApp(SafeRideApp(database: database, sync: sync));
}
