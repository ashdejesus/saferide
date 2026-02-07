import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final database = AppDatabase();
  final auth = AuthService();
  final sync = SyncService(database);
  runApp(SafeRideApp(database: database, sync: sync, auth: auth));
}
