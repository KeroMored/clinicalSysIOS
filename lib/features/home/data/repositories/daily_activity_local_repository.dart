import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_activity_model.dart';

class DailyActivityLocalRepository {
  String _key(String userId, String field) => 'daily_activity.$userId.$field';

  Future<DailyActivityModel> getOrCreateToday(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DailyActivityModel.buildDateKey(DateTime.now());
    final storedDay = prefs.getString(_key(userId, 'current_day'));

    if (storedDay != todayKey) {
      return _resetCurrentDay(userId, todayKey);
    }

    return DailyActivityModel(
      dateKey: todayKey,
      steps: prefs.getInt(_key(userId, 'current_steps')) ?? 0,
      meters: prefs.getDouble(_key(userId, 'current_meters')) ?? 0.0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(_key(userId, 'current_updated_at')) ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> addActivityDelta(
    String userId, {
    required int stepsDelta,
    required double metersDelta,
  }) async {
    final current = await getOrCreateToday(userId);
    final updated = current.copyWith(
      steps: (current.steps + stepsDelta).clamp(0, 999999),
      meters: (current.meters + metersDelta).clamp(0, 9999999).toDouble(),
      updatedAt: DateTime.now(),
    );

    await _saveCurrent(userId, updated);
  }

  Future<void> setTodayAbsolute(
    String userId, {
    required int steps,
    required double meters,
  }) async {
    final current = await getOrCreateToday(userId);
    final updated = current.copyWith(
      steps: steps.clamp(0, 999999),
      meters: meters.clamp(0, 9999999).toDouble(),
      updatedAt: DateTime.now(),
    );
    await _saveCurrent(userId, updated);
  }

  Future<DailyActivityModel?> rolloverAndQueuePreviousDayIfNeeded(
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DailyActivityModel.buildDateKey(DateTime.now());
    final storedDay = prefs.getString(_key(userId, 'current_day'));

    if (storedDay == null) {
      await _resetCurrentDay(userId, todayKey);
      return null;
    }

    if (storedDay == todayKey) {
      return null;
    }

    final previous = DailyActivityModel(
      dateKey: storedDay,
      steps: prefs.getInt(_key(userId, 'current_steps')) ?? 0,
      meters: prefs.getDouble(_key(userId, 'current_meters')) ?? 0.0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(_key(userId, 'current_updated_at')) ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );

    if (previous.steps > 0 || previous.meters > 0) {
      await _enqueuePending(userId, previous);
    }

    await _resetCurrentDay(userId, todayKey);
    return previous;
  }

  Future<List<DailyActivityModel>> getPendingQueue(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId, 'pending_queue'));
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map(
          (item) =>
              DailyActivityModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> replacePendingQueue(
    String userId,
    List<DailyActivityModel> queue,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(queue.map((e) => e.toJson()).toList());
    await prefs.setString(_key(userId, 'pending_queue'), encoded);
  }

  Future<void> enqueueCurrentDayForManualFlush(String userId) async {
    final current = await getOrCreateToday(userId);
    if (current.steps == 0 && current.meters == 0) return;
    await _enqueuePending(userId, current);
  }

  Future<void> _enqueuePending(String userId, DailyActivityModel entry) async {
    final queue = await getPendingQueue(userId);

    // Upsert by dateKey to avoid duplicates if app restarts a lot.
    final index = queue.indexWhere((item) => item.dateKey == entry.dateKey);
    if (index >= 0) {
      queue[index] = entry;
    } else {
      queue.add(entry);
    }

    await replacePendingQueue(userId, queue);
  }

  Future<void> _saveCurrent(String userId, DailyActivityModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId, 'current_day'), model.dateKey);
    await prefs.setInt(_key(userId, 'current_steps'), model.steps);
    await prefs.setDouble(_key(userId, 'current_meters'), model.meters);
    await prefs.setInt(
      _key(userId, 'current_updated_at'),
      model.updatedAt.millisecondsSinceEpoch,
    );
  }

  Future<DailyActivityModel> _resetCurrentDay(
    String userId,
    String dayKey,
  ) async {
    final model = DailyActivityModel(
      dateKey: dayKey,
      steps: 0,
      meters: 0,
      updatedAt: DateTime.now(),
    );
    await _saveCurrent(userId, model);
    return model;
  }
}
