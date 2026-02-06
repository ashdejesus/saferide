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
import 'widgets/trip_action_sheet.dart';
import 'widgets/sync_widgets.dart';

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
        home: Consumer<TripController>(
          builder: (context, controller, _) {
            return Stack(
              children: [
                Scaffold(
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
                  floatingActionButtonLocation:
                      FloatingActionButtonLocation.centerFloat,
                  floatingActionButton: _selectedIndex == 0
                      ? AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOutBack,
                          switchOutCurve: Curves.easeIn,
                          child: FloatingActionButton.extended(
                            key: ValueKey(controller.isTracking),
                            onPressed: () => TripActionSheet.show(context),
                            icon: Icon(
                              controller.isTracking
                                  ? Icons.stop_circle
                                  : Icons.play_circle_fill,
                            ),
                            label: Text(
                              controller.isTracking ? 'End Trip' : 'Start Trip',
                            ),
                          ),
                        )
                      : null,
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    destinations: [
                      NavigationDestination(
                        icon: Badge(
                          isLabelVisible: controller.recentEvents.isNotEmpty,
                          label: Text(
                            controller.recentEvents.length.toString(),
                          ),
                          child: const Icon(Icons.dashboard_outlined),
                        ),
                        selectedIcon: Badge(
                          isLabelVisible: controller.recentEvents.isNotEmpty,
                          label: Text(
                            controller.recentEvents.length.toString(),
                          ),
                          child: const Icon(Icons.dashboard),
                        ),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Badge(
                          isLabelVisible: controller.reportSeveritySum > 0,
                          label: Text(controller.reportSeveritySum.toString()),
                          child: const Icon(Icons.report_outlined),
                        ),
                        selectedIcon: Badge(
                          isLabelVisible: controller.reportSeveritySum > 0,
                          label: Text(controller.reportSeveritySum.toString()),
                          child: const Icon(Icons.report),
                        ),
                        label: 'Report',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.map_outlined),
                        selectedIcon: Icon(Icons.map),
                        label: 'Map',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.list_alt_outlined),
                        selectedIcon: Icon(Icons.list_alt),
                        label: 'Trips',
                      ),
                    ],
                  ),
                ),
                const SyncStatusIndicator(),
              ],
            );
          },
        ),
      ),
    );
  }
}
