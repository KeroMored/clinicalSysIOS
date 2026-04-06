import 'package:flutter/foundation.dart';

import '../data/models/daily_activity_model.dart';
import '../data/repositories/daily_activity_local_repository.dart';
import '../data/repositories/daily_activity_remote_repository.dart';

class DailyActivitySyncService {
  final DailyActivityLocalRepository _localRepository;
  final DailyActivityRemoteRepository _remoteRepository;

  DailyActivitySyncService({
    DailyActivityLocalRepository? localRepository,
    DailyActivityRemoteRepository? remoteRepository,
  }) : _localRepository = localRepository ?? DailyActivityLocalRepository(),
       _remoteRepository = remoteRepository ?? DailyActivityRemoteRepository();

  /// Called on app start/resume.
  /// Strategy:
  /// 1) Detect day rollover and queue previous day locally.
  /// 2) Upload pending days in batch-like loop (write-only, no listeners).
  Future<void> syncPendingDays(String userId) async {
    try {
      await _localRepository.rolloverAndQueuePreviousDayIfNeeded(userId);

      final pending = await _localRepository.getPendingQueue(userId);
      if (pending.isEmpty) return;

      final remaining = <DailyActivityModel>[];

      for (final entry in pending) {
        try {
          await _remoteRepository.uploadDailyEntry(
            userId: userId,
            entry: entry,
          );
        } catch (_) {
          remaining.add(entry);
        }
      }

      await _localRepository.replacePendingQueue(userId, remaining);
    } catch (e) {
      debugPrint('Daily activity sync failed: $e');
    }
  }

  /// Lightweight local update during the day (no network call).
  Future<void> addLocalActivity({
    required String userId,
    required int stepsDelta,
    required double metersDelta,
  }) async {
    await _localRepository.addActivityDelta(
      userId,
      stepsDelta: stepsDelta,
      metersDelta: metersDelta,
    );
  }
}
