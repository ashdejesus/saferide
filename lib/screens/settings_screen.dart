import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/permission_service.dart';
import '../services/preferences_service.dart';
import '../state/trip_controller.dart';
import '../widgets/section_header.dart';
import 'algo_simulator_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _devTapCount = 0;
  bool _isDevModeEnabled = false;
  late Future<bool> _batteryExemptFuture;

  @override
  void initState() {
    super.initState();
    _batteryExemptFuture = PermissionService.isBatteryOptimizationExempt();
    _isDevModeEnabled = Provider.of<PreferencesService>(context, listen: false).isDevModeEnabled;
  }

  void _refreshBatteryStatus() {
    setState(() {
      _batteryExemptFuture = PermissionService.isBatteryOptimizationExempt();
    });
  }

  void _onDevTap() {
    if (_isDevModeEnabled) return;
    _devTapCount++;
    if (_devTapCount >= 5) {
      setState(() {
        _isDevModeEnabled = true;
      });
      Provider.of<PreferencesService>(context, listen: false).setDevMode(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Developer mode enabled')),
      );
    }
  }
  Future<void> _handleSignOut(
    BuildContext context,
    AuthService auth,
    SyncService sync,
    TripController tripController,
  ) async {
    final user = auth.currentUser;
    if (user == null) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    if (tripController.isTracking) {
      await tripController.stopTrip();
    }

    await sync.syncPending();
    await auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }



  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService?>(context);
    final sync = Provider.of<SyncService>(context, listen: false);
    final tripController = context.watch<TripController>();
    final user = auth?.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _onDevTap,
          child: const Text('Settings'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(title: 'Account'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(user?.email ?? 'Not signed in'),
                subtitle: user == null ? null : Text('UID: ${user.uid}'),
              ),
            ),
          ),
          const SizedBox(height: 20),



          if (_isDevModeEnabled) ...[
            const SectionHeader(title: 'Developer & Testing'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Developer Test Mode'),
                      subtitle: const Text('Bypass minimum speed limits (11 km/h) to allow testing sensors manually.'),
                      value: tripController.testMode,
                      onChanged: tripController.isTracking ? null : (val) {
                        tripController.setTestMode(val);
                        if (!val) {
                          setState(() {
                            _isDevModeEnabled = false;
                            _devTapCount = 0;
                          });
                          Provider.of<PreferencesService>(context, listen: false).setDevMode(false);
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.calculate_outlined),
                      title: const Text('Algorithm Simulator (Manual)'),
                      subtitle: const Text('Interactive input-output simulator.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AlgoSimulatorScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          const SectionHeader(title: 'Privacy'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings_applications),
                    title: const Text('App Permissions'),
                    subtitle: const Text('Manage location and sensor permissions'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      if (!kIsWeb) {
                        Geolocator.openAppSettings();
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Data Collection Agreement'),
                    subtitle: const Text('View or manage data collection preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Data Collection Notice'),
                          content: const Text(
                            'You have already accepted the data collection agreement. Location tracking and sensor data is securely processed to provide safety features.',
                          ),
                          actions: [
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  FutureBuilder<bool>(
                    future: _batteryExemptFuture,
                    builder: (context, snapshot) {
                      final isExempt = snapshot.data ?? true;
                      return ListTile(
                        leading: Icon(
                          isExempt ? Icons.battery_full : Icons.battery_alert,
                          color: isExempt
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                        title: const Text('Battery Optimization'),
                        subtitle: Text(
                          isExempt
                              ? 'Unrestricted — trip recording will work in the background'
                              : 'Restricted — GPS may stop when screen is off',
                        ),
                        trailing: isExempt
                            ? Icon(Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary)
                            : FilledButton.tonal(
                                onPressed: () async {
                                  await PermissionService
                                      .requestBatteryOptimizationExemption();
                                  _refreshBatteryStatus();
                                },
                                child: const Text('Fix'),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (user != null)
            ElevatedButton.icon(
              onPressed: () => _handleSignOut(context, auth!, sync, tripController),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

