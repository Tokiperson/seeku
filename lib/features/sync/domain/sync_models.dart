enum SyncDirection { upload, download, bidirectional }

enum SyncStatus { idle, syncing, completed, failed, conflict }

class SyncPlan {
  const SyncPlan({
    required this.direction,
    required this.includeCourses,
    required this.includeSettings,
  });

  final SyncDirection direction;
  final bool includeCourses;
  final bool includeSettings;
}

class SyncResult {
  const SyncResult({
    required this.status,
    required this.syncedItems,
    this.message,
  });

  final SyncStatus status;
  final int syncedItems;
  final String? message;
}

abstract class CloudSyncService {
  const CloudSyncService();

  Future<SyncResult> sync(SyncPlan plan);
  Stream<SyncStatus> watchStatus();
}
