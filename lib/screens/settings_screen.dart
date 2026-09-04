import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../state/trip_controller.dart';
import '../widgets/section_header.dart';
import 'algo_demo_screen.dart';

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

  String _getRoadLabel(double value) {
    if (value < 0.4) return 'Poor (Bumpy)';
    if (value < 0.7) return 'Fair (Normal)';
    return 'Good (Smooth)';
  }

  String _getNoiseLabel(double value) {
    if (value < 0.4) return 'Quiet';
    if (value < 0.7) return 'Moderate';
    return 'Loud';
  }

  String _getTrafficLabel(double value) {
    if (value < 0.4) return 'Light';
    if (value < 0.7) return 'Moderate';
    return 'Heavy';
  }

  Widget _buildContextSlider({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required String valueLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              valueLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        Slider(
          value: value,
          min: 0.0,
          max: 1.0,
          divisions: 2, // 3 easy steps: 0.0, 0.5, 1.0
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService?>(context);
    final sync = Provider.of<SyncService>(context, listen: false);
    final tripController = context.watch<TripController>();
    final user = auth?.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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

          const SectionHeader(title: 'Adaptive Context Factors'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Text(
              'Tell SafeRide about your typical route to help adjust the sensitivity of reckless driving alerts.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContextSlider(
                    title: 'Road Condition',
                    subtitle: 'Bumpy roads might trigger false braking alerts',
                    icon: Icons.add_road,
                    value: tripController.contextRoad,
                    valueLabel: _getRoadLabel(tripController.contextRoad),
                    onChanged: (val) {
                      tripController.updateContextFactors(
                        roadCondition: val,
                        envNoise: tripController.contextEnvNoise,
                        trafficDensity: tripController.contextTraffic,
                      );
                    },
                  ),
                  const Divider(height: 24),
                  _buildContextSlider(
                    title: 'Traffic Density',
                    subtitle: 'Heavy traffic naturally requires sudden stops',
                    icon: Icons.traffic,
                    value: tripController.contextTraffic,
                    valueLabel: _getTrafficLabel(tripController.contextTraffic),
                    onChanged: (val) {
                      tripController.updateContextFactors(
                        roadCondition: tripController.contextRoad,
                        envNoise: tripController.contextEnvNoise,
                        trafficDensity: val,
                      );
                    },
                  ),
                  const Divider(height: 24),
                  _buildContextSlider(
                    title: 'Environmental Noise',
                    subtitle: 'Loud vehicles or wind affect the microphone',
                    icon: Icons.volume_up,
                    value: tripController.contextEnvNoise,
                    valueLabel: _getNoiseLabel(tripController.contextEnvNoise),
                    onChanged: (val) {
                      tripController.updateContextFactors(
                        roadCondition: tripController.contextRoad,
                        envNoise: val,
                        trafficDensity: tripController.contextTraffic,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

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
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.science_outlined),
                    title: const Text('Live Algorithm Demo'),
                    subtitle: const Text('Real-time visualisation of all risk & trust scoring formulas.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AlgoDemoScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

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
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (user != null)
            ElevatedButton.icon(
              onPressed: () => _handleSignOut(context, auth!, sync),
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

