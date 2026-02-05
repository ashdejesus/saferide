enum SyncStatus {
  pending,
  synced,
  failed;

  static SyncStatus fromString(String? value) {
    switch (value) {
      case 'synced':
        return SyncStatus.synced;
      case 'failed':
        return SyncStatus.failed;
      case 'pending':
      default:
        return SyncStatus.pending;
    }
  }

  String get label => name;
}
