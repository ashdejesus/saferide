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
  // Context factor sliders for adaptive thresholds: θ(t) = θ₀ · C_r · C_v · C_t
  double _roadCondition = 0.5; // C_r(t): 0.0 = poor, 1.0 = good
  double _vehicleType = 0.5; // C_v(t): 0.0 = heavy, 1.0 = light
  double _trafficLevel = 0.5; // C_t(t): 0.0 = heavy, 1.0 = light
  Future<void> _promptAnonymousUpgrade(
    BuildContext context,
    AuthService auth,
    SyncService sync,
  ) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    var isSubmitting = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !isSubmitting,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Register to keep saved trips'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Guest accounts must register before signing out so trips can be saved to your account.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password (min 6 chars)',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();

                            if (!email.contains('@') || password.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Enter a valid email and password.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() => isSubmitting = true);
                            try {
                              await auth.upgradeAnonymousAccountWithEmail(
                                email,
                                password,
                              );
                              final result = await sync.syncPending();
                              if (!context.mounted) {
                                return;
                              }
                              if (result.success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Account registered. Trips are now saved to your account.',
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Registered, but sync failed: ${result.message}',
                                    ),
                                  ),
                                );
                              }
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            } catch (error) {
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                              setDialogState(() => isSubmitting = false);
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Register'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      emailController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _handleSignOut(
    BuildContext context,
    AuthService auth,
    SyncService sync,
  ) async {
    final user = auth.currentUser;
    if (user == null) {
      return;
    }

    if (user.isAnonymous) {
      await _promptAnonymousUpgrade(context, auth, sync);
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
    final tripController = Provider.of<TripController>(context);
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
                  : Text(
                      user.isAnonymous
                          ? 'Guest account (${user.uid})'
                          : 'UID: ${user.uid}',
                    ),
            ),
            if (user?.isAnonymous == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Register your guest account before signing out to keep your saved trips.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: user == null
                  ? null
                  : () => _handleSignOut(context, auth!, sync),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),

            // ── Trip Context Factors ──
            // θ(t) = θ₀ · C_r(t) · C_v(t) · C_t(t)
            const SizedBox(height: 32),
            Text(
              'Trip Context Factors',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Adjust detection sensitivity based on current conditions. '
              'These factors dynamically scale the adaptive thresholds '
              'for event detection (θ = θ₀ × C_r × C_v × C_t).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            // Road Condition slider: C_r(t)
            _buildContextSlider(
              context: context,
              label: 'Road Condition',
              value: _roadCondition,
              lowLabel: 'Poor',
              highLabel: 'Good',
              icon: Icons.terrain,
              onChanged: (val) {
                setState(() => _roadCondition = val);
                tripController.updateContextFactors(
                  roadCondition: _roadCondition,
                  vehicleType: _vehicleType,
                  trafficLevel: _trafficLevel,
                );
              },
            ),

            // Vehicle Type slider: C_v(t)
            _buildContextSlider(
              context: context,
              label: 'Vehicle Type',
              value: _vehicleType,
              lowLabel: 'Heavy',
              highLabel: 'Light',
              icon: Icons.directions_bus,
              onChanged: (val) {
                setState(() => _vehicleType = val);
                tripController.updateContextFactors(
                  roadCondition: _roadCondition,
                  vehicleType: _vehicleType,
                  trafficLevel: _trafficLevel,
                );
              },
            ),

            // Traffic Level slider: C_t(t)
            _buildContextSlider(
              context: context,
              label: 'Traffic Level',
              value: _trafficLevel,
              lowLabel: 'Heavy',
              highLabel: 'Light',
              icon: Icons.traffic,
              onChanged: (val) {
                setState(() => _trafficLevel = val);
                tripController.updateContextFactors(
                  roadCondition: _roadCondition,
                  vehicleType: _vehicleType,
                  trafficLevel: _trafficLevel,
                );
              },
            ),

            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current multipliers: '
                        'Road ${tripController.contextRoad.toStringAsFixed(2)}, '
                        'Vehicle ${tripController.contextVehicle.toStringAsFixed(2)}, '
                        'Traffic ${tripController.contextTraffic.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextSlider({
    required BuildContext context,
    required String label,
    required double value,
    required String lowLabel,
    required String highLabel,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        Row(
          children: [
            Text(lowLabel, style: Theme.of(context).textTheme.bodySmall),
            Expanded(
              child: Slider(
                value: value,
                onChanged: onChanged,
              ),
            ),
            Text(highLabel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
