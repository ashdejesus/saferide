import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/sync_service.dart';
import '../data/app_database.dart';
import 'm3_progress_indicators.dart';

/// Floating sync status indicator that shows when syncing is in progress
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!sync.isSyncing) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 8,
      left: 20,
      right: 20,
      child: SafeArea(
        child: Card(
          elevation: 4,
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                M3CircularProgress(
                  value: sync.syncProgress,
                  size: 20,
                  strokeWidth: 2.5,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Syncing data...',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sync.syncedItems != null && sync.totalItems != null)
                        Text(
                          '${sync.syncedItems} of ${sync.totalItems} items',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onPrimaryContainer
                                    .withOpacity(0.8),
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sync button with progress indicator.
///
/// Caches the pending-counts future in [initState] so that [FutureBuilder]
/// doesn't restart the DB query on every rebuild (which would flash through
/// [ConnectionState.waiting] and cause a visible flicker).
class SyncButton extends StatefulWidget {
  const SyncButton({super.key});

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> {
  bool _isManualSyncing = false;
  late Future<PendingCounts> _pendingFuture;

  @override
  void initState() {
    super.initState();
    _pendingFuture = context.read<AppDatabase>().getPendingCounts();
  }

  /// Re-query pending counts after a sync so the button reflects the new state.
  void _refresh() {
    setState(() {
      _pendingFuture = context.read<AppDatabase>().getPendingCounts();
    });
  }

  Future<void> _handleSync() async {
    if (_isManualSyncing) return;

    setState(() => _isManualSyncing = true);

    try {
      final sync = context.read<SyncService>();
      final result = await sync.syncPending();

      if (!mounted) return;

      _refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Synced ${result.tripsSynced} trips, ${result.reportsSynced} reports'
                : 'Sync failed: ${result.message}',
          ),
          backgroundColor: result.success
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isManualSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();

    return FutureBuilder<PendingCounts>(
      future: _pendingFuture,
      builder: (context, snapshot) {
        final counts = snapshot.data;
        final hasPending = counts != null && counts.total > 0;

        return ProgressButton(
          label: 'Sync',
          icon: Icons.cloud_upload,
          isLoading: sync.isSyncing || _isManualSyncing,
          onPressed: hasPending ? () => _handleSync() : null,
        );
      },
    );
  }
}

/// Listens for Wi-Fi connections and prompts the user to sync offline data
class WifiSyncListener extends StatefulWidget {
  final Widget child;
  const WifiSyncListener({super.key, required this.child});

  @override
  State<WifiSyncListener> createState() => _WifiSyncListenerState();
}

class _WifiSyncListenerState extends State<WifiSyncListener> {
  late final Stream<List<ConnectivityResult>> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
    
    _connectivityStream.listen((List<ConnectivityResult> results) async {
      if (results.contains(ConnectivityResult.wifi)) {
        if (!mounted) return;
        final database = context.read<AppDatabase>();
        final counts = await database.getPendingCounts();
        
        if (counts.total > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("You're on Wi-Fi! 📶 Sync your pending trips now without using your mobile data."),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'Sync Now',
                onPressed: () {
                  context.read<SyncService>().syncPending();
                },
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Banner shown when there are unsynced items pending upload.
///
/// Uses a cached future (set in [initState]) to avoid re-querying the DB on
/// every rebuild — which was causing a flicker as [FutureBuilder] flashed
/// through [ConnectionState.waiting] each time a parent notified listeners.
class PendingSyncBanner extends StatefulWidget {
  const PendingSyncBanner({super.key});

  @override
  State<PendingSyncBanner> createState() => _PendingSyncBannerState();
}

class _PendingSyncBannerState extends State<PendingSyncBanner> {
  late Future<PendingCounts> _pendingFuture;

  @override
  void initState() {
    super.initState();
    _pendingFuture = context.read<AppDatabase>().getPendingCounts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PendingCounts>(
      future: _pendingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
        final counts = snapshot.data;
        if (counts == null || counts.total == 0) return const SizedBox.shrink();
        return Card(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          margin: const EdgeInsets.only(top: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You have pending items to sync.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
