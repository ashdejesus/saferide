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
                                    .withValues(alpha: 0.8),
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

/// Sync button with progress indicator
class SyncButton extends StatefulWidget {
  const SyncButton({super.key});

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> {
  bool _isManualSyncing = false;

  Future<void> _handleSync() async {
    if (_isManualSyncing) return;

    setState(() => _isManualSyncing = true);

    try {
      final sync = context.read<SyncService>();
      final result = await sync.syncPending();

      if (!mounted) return;

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
    final database = context.read<AppDatabase>();

    return FutureBuilder(
      future: database.getPendingCounts(),
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
