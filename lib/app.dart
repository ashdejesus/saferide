import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_database.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';
import 'services/preferences_service.dart';
import 'state/trip_controller.dart';
import 'theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/report_screen.dart';
import 'screens/trips_screen.dart';
import 'widgets/trip_action_sheet.dart';
import 'widgets/sync_widgets.dart';
import 'screens/auth_screen.dart';
import 'widgets/data_collection_agreement_dialog.dart';

class SafeRideApp extends StatefulWidget {
  const SafeRideApp({
    super.key,
    required this.database,
    required this.sync,
    required this.auth,
    required this.preferences,
  });

  final AppDatabase database;
  final SyncService sync;
  final AuthService auth;
  final PreferencesService preferences;

  @override
  State<SafeRideApp> createState() => _SafeRideAppState();
}

class _SafeRideAppState extends State<SafeRideApp> {
  int _selectedIndex = 0;
  StreamSubscription<User?>? _authSubscription;
  String _controllerScopeKey = 'signed_out';

  @override
  void initState() {
    super.initState();
    _handleAuthChanged(widget.auth.currentUser);
    _authSubscription = widget.auth.authStateChanges().listen(
      _handleAuthChanged,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _handleAuthChanged(User? user) {
    widget.database.configureForUser(
      uid: user?.uid,
      isAnonymous: user?.isAnonymous ?? false,
    );
    final nextScope = user == null
        ? 'signed_out'
        : (user.isAnonymous ? 'anon_${user.uid}' : 'user_${user.uid}');
    if (_controllerScopeKey != nextScope && mounted) {
      setState(() {
        _controllerScopeKey = nextScope;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: widget.database),
        Provider<AuthService>.value(value: widget.auth),
        ChangeNotifierProvider.value(value: widget.sync),
        ChangeNotifierProvider(
          key: ValueKey(_controllerScopeKey),
          create: (context) => TripController(database: widget.database),
        ),
      ],
      child: MaterialApp(
        title: 'SafeRide',
        theme: buildSafeRideTheme(),
        builder: (context, child) {
          return _AgreementCheckWrapper(
            preferences: widget.preferences,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: StreamBuilder<User?>(
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
                                controller.isTracking
                                    ? 'End Trip'
                                    : 'Start Trip',
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
                                isLabelVisible:
                                    controller.reportSeveritySum > 0,
                                label: Text(
                                  controller.reportSeveritySum.toString(),
                                ),
                                child: const Icon(Icons.report_outlined),
                              ),
                              selectedIcon: Badge(
                                isLabelVisible:
                                    controller.reportSeveritySum > 0,
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

/// Wrapper widget that shows agreement dialog from proper Material context
class _AgreementCheckWrapper extends StatefulWidget {
  const _AgreementCheckWrapper({
    required this.preferences,
    required this.child,
  });

  final PreferencesService preferences;
  final Widget child;

  @override
  State<_AgreementCheckWrapper> createState() => _AgreementCheckWrapperState();
}

class _AgreementCheckWrapperState extends State<_AgreementCheckWrapper> {
  bool _shownAgreement = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAgreementIfNeeded();
    });
  }

  void _showAgreementIfNeeded() {
    if (!_shownAgreement && !widget.preferences.hasAcceptedDataCollection) {
      _shownAgreement = true;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => DataCollectionAgreementDialog(
            onAccept: () => widget.preferences.acceptDataCollection(),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
