import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../state/trip_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _handleSignOut(
    BuildContext context,
    AuthService auth,
    SyncService sync,
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
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(user?.email ?? 'Not signed in'),
              subtitle: user == null
                  ? null
                  : Text('UID: ${user.uid}'),
            ),
            const SizedBox(height: 24),
            Text(
              'Developer & Testing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            SwitchListTile(
              title: const Text('Developer Test Mode'),
              subtitle: const Text('Bypass minimum speed limits (11 km/h) to allow testing sensors by manually shaking the phone.'),
              value: tripController.testMode,
              onChanged: (val) {
                tripController.setTestMode(val);
              },
            ),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Context Factors (Adaptive Sensitivity)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('Road Condition (Poor to Good)'),
            Slider(
              value: tripController.contextRoad,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: tripController.contextRoad.toStringAsFixed(1),
              onChanged: (val) {
                tripController.updateContextFactors(
                  roadCondition: val,
                  envNoise: tripController.contextEnvNoise,
                  trafficDensity: tripController.contextTraffic,
                );
              },
            ),
            const Text('Environmental Noise (Low to High)'),
            Slider(
              value: tripController.contextEnvNoise,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: tripController.contextEnvNoise.toStringAsFixed(1),
              onChanged: (val) {
                tripController.updateContextFactors(
                  roadCondition: tripController.contextRoad,
                  envNoise: val,
                  trafficDensity: tripController.contextTraffic,
                );
              },
            ),
            const Text('Traffic Density (Light to Heavy)'),
            Slider(
              value: tripController.contextTraffic,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: tripController.contextTraffic.toStringAsFixed(1),
              onChanged: (val) {
                tripController.updateContextFactors(
                  roadCondition: tripController.contextRoad,
                  envNoise: tripController.contextEnvNoise,
                  trafficDensity: val,
                );
              },
            ),
            const Divider(),
            const SizedBox(height: 24),
            Text(
              'Privacy',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Data Collection Agreement'),
              subtitle: const Text('View or manage data collection preferences'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => ScaffoldMessenger(
                    child: Builder(
                      builder: (scaffoldContext) => Scaffold(
                        backgroundColor: Colors.transparent,
                        body: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                            child: Card(
                              margin: const EdgeInsets.all(24),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Data Collection Notice', style: Theme.of(context).textTheme.headlineSmall),
                                    const SizedBox(height: 16),
                                    const Text('You have already accepted the data collection agreement. Location tracking and sensor data is securely processed to provide safety features.'),
                                    const SizedBox(height: 24),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: user == null
                  ? null
                  : () => _handleSignOut(context, auth!, sync),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
