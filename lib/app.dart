import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_database.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';
import 'state/trip_controller.dart';
import 'theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/report_screen.dart';
import 'screens/trips_screen.dart';
import 'widgets/trip_action_sheet.dart';
import 'widgets/sync_widgets.dart';
import 'screens/auth_screen.dart';

class SafeRideApp extends StatefulWidget {
  const SafeRideApp({
    super.key,
    required this.database,
    required this.sync,
    required this.auth,
  });

  final AppDatabase database;
  final SyncService sync;
  final AuthService auth;

  @override
  State<SafeRideApp> createState() => _SafeRideAppState();
}

class _SafeRideAppState extends State<SafeRideApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: widget.database),
        Provider<AuthService>.value(value: widget.auth),
        ChangeNotifierProvider.value(value: widget.sync),
        ChangeNotifierProvider(
          create: (context) => TripController(database: widget.database),
        ),
      ],
      child: MaterialApp(
        title: 'SafeRide',
        theme: buildSafeRideTheme(),
        home: StreamBuilder(
          stream: widget.auth.authStateChanges(),
          initialData: widget.auth.currentUser,
          builder: (context, snapshot) {
            final user = snapshot.data;
            if (user == null) {
              return const AuthScreen();
            }
            return Consumer<TripController>(
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
                      floatingActionButton: Visibility(
                        visible: _selectedIndex == 0,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 120),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            final fade = CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            );
                            final slide =
                                Tween<Offset>(
                                  begin: const Offset(0, 0.18),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOut,
                                  ),
                                );
                            return FadeTransition(
                              opacity: fade,
                              child: SlideTransition(
                                position: slide,
                                child: child,
                              ),
                            );
                          },
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
                        ),
                      ),
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
                              isLabelVisible:
                                  controller.recentEvents.isNotEmpty,
                              label: Text(
                                controller.recentEvents.length.toString(),
                              ),
                              child: const Icon(Icons.dashboard_outlined),
                            ),
                            selectedIcon: Badge(
                              isLabelVisible:
                                  controller.recentEvents.isNotEmpty,
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
                              label: Text(
                                controller.reportSeveritySum.toString(),
                              ),
                              child: const Icon(Icons.report_outlined),
                            ),
                            selectedIcon: Badge(
                              isLabelVisible: controller.reportSeveritySum > 0,
                              label: Text(
                                controller.reportSeveritySum.toString(),
                              ),
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
            );
          },
        ),
      ),
    );
  }
}
