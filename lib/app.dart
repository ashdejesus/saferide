import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_database.dart';
import 'services/sync_service.dart';
import 'state/trip_controller.dart';
import 'theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/report_screen.dart';
import 'screens/trips_screen.dart';

class SafeRideApp extends StatefulWidget {
  const SafeRideApp({super.key, required this.database, required this.sync});

  final AppDatabase database;
  final SyncService sync;

  @override
  State<SafeRideApp> createState() => _SafeRideAppState();
}

class _SafeRideAppState extends State<SafeRideApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: widget.database),
        ChangeNotifierProvider.value(value: widget.sync),
        ChangeNotifierProvider(
          create: (context) => TripController(database: widget.database),
        ),
      ],
      child: MaterialApp(
        title: 'SafeRide',
        theme: buildSafeRideTheme(),
        home: Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                DashboardScreen(),
                ReportScreen(),
                MapScreen(),
                TripsScreen(),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.report_outlined),
                selectedIcon: Icon(Icons.report),
                label: 'Report',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: 'Trips',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
