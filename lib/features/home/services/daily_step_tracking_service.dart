import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/daily_health_tips.dart';
import '../data/models/daily_activity_model.dart';
import '../data/repositories/daily_activity_local_repository.dart';

class DailyStepTrackingService {
  DailyStepTrackingService._internal();
  static final DailyStepTrackingService _instance =
      DailyStepTrackingService._internal();
  factory DailyStepTrackingService() => _instance;

  final DailyActivityLocalRepository _localRepository =
      DailyActivityLocalRepository();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _permissionPromptedKey =
      'daily_activity.permission_prompted_once';
  static const String _sensorBaseDayKey = 'daily_activity.%s.sensor_base_day';
  static const String _sensorBaseValueKey =
      'daily_activity.%s.sensor_base_value';
  static const String _lastLatKey = 'daily_activity.%s.last_lat';
  static const String _lastLngKey = 'daily_activity.%s.last_lng';
  static const String _walkNotificationsEnabledKey =
      'daily_activity.%s.walk_notifications_enabled';
  static const String _lastSummaryNotificationDayKey =
      'daily_activity.%s.last_summary_notification_day';
  static const String _walkChannelId = 'daily_health_tips';
  static const int _walkSummaryNotificationId = 68110;

  final ValueNotifier<DailyActivityModel?> todayNotifier =
      ValueNotifier<DailyActivityModel?>(null);
  final ValueNotifier<bool> permissionGrantedNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<bool> walkNotificationsEnabledNotifier =
      ValueNotifier<bool>(true);

  Timer? _midnightTimer;
  Timer? _sensorWatchdogTimer;
  StreamSubscription<StepCount>? _stepSubscription;

  String? _activeUserId;
  bool _isRefreshing = false;
  bool _pendingRefresh = false;
  bool _isApplyingSensorEvent = false;
  int? _pendingSensorTotal;
  int? _latestSensorTotal;
  DateTime? _lastSensorEventAt;
  bool _localNotificationsReady = false;

  Future<void> start(
    String userId, {
    bool requestPermissionIfDenied = false,
  }) async {
    final granted =
        permissionGrantedNotifier.value ||
        await ensureActivityPermission(
          requestIfDenied: requestPermissionIfDenied,
        );
    permissionGrantedNotifier.value = granted;

    if (!granted) return;

    if (_activeUserId != null && _activeUserId != userId) {
      await stop();
      permissionGrantedNotifier.value = true;
    }

    _activeUserId = userId;
    await _loadWalkNotificationPreference(userId);
    await _ensureLocalNotificationsReady();
    await _refreshToday();
    _scheduleMidnightReset();
    _scheduleSensorWatchdog();
    await _ensureSensorListener();

    // Pull current value immediately so UI updates without waiting for next sensor event.
    await refreshFromSensorOnce();
  }

  Future<void> stop() async {
    _midnightTimer?.cancel();
    _midnightTimer = null;
    _sensorWatchdogTimer?.cancel();
    _sensorWatchdogTimer = null;

    await _stepSubscription?.cancel();
    _stepSubscription = null;

    _activeUserId = null;
    _isRefreshing = false;
    _pendingRefresh = false;
    _isApplyingSensorEvent = false;
    _pendingSensorTotal = null;
    _latestSensorTotal = null;
    _lastSensorEventAt = null;

    todayNotifier.value = null;
    permissionGrantedNotifier.value = false;
  }

  Future<void> _ensureSensorListener() async {
    if (_stepSubscription != null) return;

    try {
      _stepSubscription = Pedometer.stepCountStream.listen(
        (event) {
          _latestSensorTotal = event.steps;
          _lastSensorEventAt = DateTime.now();
          _queueSensorTotal(event.steps);
        },
        onError: (error) {
          debugPrint('stepCountStream error: $error');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Failed to start step listener: $e');
    }
  }

  void _queueSensorTotal(int total) {
    _pendingSensorTotal = total;
    unawaited(_drainSensorQueue());
  }

  Future<void> _drainSensorQueue() async {
    if (_isApplyingSensorEvent) return;
    _isApplyingSensorEvent = true;

    try {
      while (_pendingSensorTotal != null) {
        final sensorTotal = _pendingSensorTotal!;
        _pendingSensorTotal = null;

        final userId = _activeUserId;
        if (userId == null) continue;

        await _applySensorTotalToToday(userId, sensorTotal);
      }
    } finally {
      _isApplyingSensorEvent = false;
    }
  }

  Future<void> _applySensorTotalToToday(
    String userId,
    int currentTotal, {
    bool forceTimestampTouch = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DailyActivityModel.buildDateKey(DateTime.now());
    final baseDayKey = _sensorBaseDayKey.replaceFirst('%s', userId);
    final baseValueKey = _sensorBaseValueKey.replaceFirst('%s', userId);

    final storedBaseDay = prefs.getString(baseDayKey);
    int? baseValue = prefs.getInt(baseValueKey);

    // Detect day change and reset baseline immediately
    if (storedBaseDay != todayKey) {
      final current = await _localRepository.getOrCreateToday(userId);
      baseValue = currentTotal - current.steps;
      await prefs.setString(baseDayKey, todayKey);
      await prefs.setInt(baseValueKey, baseValue);
    } else if (baseValue == null) {
      final current = await _localRepository.getOrCreateToday(userId);
      baseValue = currentTotal - current.steps;
      await prefs.setInt(baseValueKey, baseValue);
    }

    // Sensor can reset after reboot; rebuild baseline to avoid negative jumps.
    if (currentTotal < baseValue) {
      final current = await _localRepository.getOrCreateToday(userId);
      baseValue = currentTotal - current.steps;
      await prefs.setInt(baseValueKey, baseValue);
      await prefs.setString(baseDayKey, todayKey);
    }

    final current = await _localRepository.getOrCreateToday(userId);
    final sensorSteps = (currentTotal - baseValue).clamp(0, 999999);
    final mergedSteps = sensorSteps > current.steps
        ? sensorSteps
        : current.steps;
    final mergedMeters = mergedSteps * 0.75;

    final unchanged =
        current.steps == mergedSteps &&
        (current.meters - mergedMeters).abs() < 0.01;
    if (unchanged && !forceTimestampTouch) return;

    await _localRepository.setTodayAbsolute(
      userId,
      steps: mergedSteps,
      meters: mergedMeters,
    );

    todayNotifier.value = current.copyWith(
      dateKey: todayKey,
      steps: mergedSteps,
      meters: mergedMeters,
      updatedAt: DateTime.now(),
    );
  }

  Future<int?> _readSensorTotalOnce() async {
    try {
      final sensor = await Pedometer.stepCountStream.first.timeout(
        const Duration(seconds: 4),
      );
      _latestSensorTotal = sensor.steps;
      return sensor.steps;
    } on TimeoutException {
      return _latestSensorTotal;
    } catch (e) {
      debugPrint('readSensorTotalOnce error: $e');
      return _latestSensorTotal;
    }
  }

  Future<void> refreshFromSensorOnce() async {
    await _refreshFromSensorOnceInternal(forceTimestampTouch: false);
  }

  Future<void> refreshFromSensorOnceForceTouch() async {
    await _refreshFromSensorOnceInternal(forceTimestampTouch: true);
  }

  Future<void> _refreshFromSensorOnceInternal({
    required bool forceTimestampTouch,
  }) async {
    final userId = _activeUserId;
    if (userId == null) return;

    if (_isRefreshing) {
      _pendingRefresh = true;
      return;
    }

    _isRefreshing = true;
    try {
      do {
        _pendingRefresh = false;

        final granted = await ensureActivityPermission(requestIfDenied: false);
        if (!granted) {
          await _refreshToday();
          continue;
        }

        await _ensureSensorListener();
        final before = await _localRepository.getOrCreateToday(userId);
        final total = _latestSensorTotal ?? await _readSensorTotalOnce();
        if (total != null) {
          await _applySensorTotalToToday(
            userId,
            total,
            forceTimestampTouch: forceTimestampTouch,
          );
        }

        final afterSensor = await _localRepository.getOrCreateToday(userId);
        final sensorDidNotIncrease = afterSensor.steps <= before.steps;
        if (sensorDidNotIncrease) {
          await _tryApplyLocationFallback(
            userId,
            requestPermissionIfDenied: forceTimestampTouch,
            forceTimestampTouch: forceTimestampTouch,
          );
        }

        await _refreshToday();
      } while (_pendingRefresh);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> persistNow() async {
    await refreshFromSensorOnce();
  }

  Future<void> setWalkNotificationsEnabled(bool enabled) async {
    final userId = _activeUserId;
    if (userId == null) {
      walkNotificationsEnabledNotifier.value = enabled;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _walkNotificationsEnabledKey.replaceFirst('%s', userId),
      enabled,
    );
    walkNotificationsEnabledNotifier.value = enabled;
  }

  void _scheduleSensorWatchdog() {
    _sensorWatchdogTimer?.cancel();
    _sensorWatchdogTimer = Timer.periodic(const Duration(seconds: 20), (
      _,
    ) async {
      final userId = _activeUserId;
      if (userId == null || _isRefreshing) return;

      final lastEvent = _lastSensorEventAt;
      if (lastEvent == null ||
          DateTime.now().difference(lastEvent) > const Duration(seconds: 45)) {
        // Recover from silent stream stalls seen on some devices after idle periods.
        await _stepSubscription?.cancel();
        _stepSubscription = null;
        await _ensureSensorListener();
        await _refreshFromSensorOnceInternal(forceTimestampTouch: false);
      }
    });
  }

  Future<void> _tryApplyLocationFallback(
    String userId, {
    required bool requestPermissionIfDenied,
    required bool forceTimestampTouch,
  }) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied &&
          requestPermissionIfDenied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );

      final prefs = await SharedPreferences.getInstance();
      final latKey = _lastLatKey.replaceFirst('%s', userId);
      final lngKey = _lastLngKey.replaceFirst('%s', userId);

      final previousLat = prefs.getDouble(latKey);
      final previousLng = prefs.getDouble(lngKey);

      await prefs.setDouble(latKey, position.latitude);
      await prefs.setDouble(lngKey, position.longitude);

      if (previousLat == null || previousLng == null) {
        if (forceTimestampTouch) {
          final current = await _localRepository.getOrCreateToday(userId);
          await _localRepository.setTodayAbsolute(
            userId,
            steps: current.steps,
            meters: current.meters,
          );
        }
        return;
      }

      // Ignore inaccurate fixes and tiny jitter/noise.
      if (position.accuracy > 45) return;

      final distanceMeters = Geolocator.distanceBetween(
        previousLat,
        previousLng,
        position.latitude,
        position.longitude,
      );

      if (distanceMeters < 6 || distanceMeters > 120) {
        if (forceTimestampTouch) {
          final current = await _localRepository.getOrCreateToday(userId);
          await _localRepository.setTodayAbsolute(
            userId,
            steps: current.steps,
            meters: current.meters,
          );
        }
        return;
      }

      await _localRepository.addActivityDelta(
        userId,
        stepsDelta: (distanceMeters / 0.75).round(),
        metersDelta: distanceMeters,
      );
    } catch (_) {
      // Keep fallback silent. Sensor flow remains primary source.
    }
  }

  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    var nextSummaryTime = DateTime(now.year, now.month, now.day, 0, 0);
    if (!nextSummaryTime.isAfter(now)) {
      nextSummaryTime = nextSummaryTime.add(const Duration(days: 1));
    }
    final delay = nextSummaryTime.difference(now);

    _midnightTimer = Timer(delay, () async {
      try {
        final userId = _activeUserId;
        if (userId != null) {
          final previousDay = await _localRepository
              .rolloverAndQueuePreviousDayIfNeeded(userId);
          if (previousDay != null) {
            await _maybeSendMidnightSummary(userId, previousDay);
          }
          await _resetBaselineForToday(userId);
          await _refreshToday();
        }
      } catch (e) {
        debugPrint('midnight reset error: $e');
      } finally {
        _scheduleMidnightReset();
      }
    });
  }

  Future<void> _resetBaselineForToday(String userId) async {
    final total = _latestSensorTotal ?? await _readSensorTotalOnce();
    if (total == null) return;

    final prefs = await SharedPreferences.getInstance();
    final todayKey = DailyActivityModel.buildDateKey(DateTime.now());
    await prefs.setString(
      _sensorBaseDayKey.replaceFirst('%s', userId),
      todayKey,
    );
    await prefs.setInt(_sensorBaseValueKey.replaceFirst('%s', userId), total);
  }

  Future<void> _refreshToday() async {
    final userId = _activeUserId;
    if (userId == null) return;
    todayNotifier.value = await _localRepository.getOrCreateToday(userId);
  }

  Future<void> _ensureLocalNotificationsReady() async {
    if (_localNotificationsReady) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(initSettings);

    const walkChannel = AndroidNotificationChannel(
      _walkChannelId,
      'النصائح اليومية',
      description: 'إشعار يومي بمعلومة صحية وملخص المشي',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(walkChannel);

    _localNotificationsReady = true;
  }

  Future<void> _loadWalkNotificationPreference(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool(
          _walkNotificationsEnabledKey.replaceFirst('%s', userId),
        ) ??
        true;
    walkNotificationsEnabledNotifier.value = enabled;
  }

  Future<void> _maybeSendMidnightSummary(
    String userId,
    DailyActivityModel previousDay,
  ) async {
    if (!walkNotificationsEnabledNotifier.value) return;

    final dayKey = previousDay.dateKey;
    final prefs = await SharedPreferences.getInstance();
    final sentDay = prefs.getString(
      _lastSummaryNotificationDayKey.replaceFirst('%s', userId),
    );
    if (sentDay == dayKey) return;

    await _ensureLocalNotificationsReady();

    final tip = DailyHealthTips.getTipForDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final body =
        '$tip\n\nمشى اليوم: ${previousDay.meters.toStringAsFixed(0)} متر - التقييم: ${previousDay.performanceLabel}';

    await _localNotifications.show(
      _walkSummaryNotificationId,
      'معلومة على الماشي',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _walkChannelId,
          'النصائح اليومية',
          channelDescription: 'إشعار يومي بمعلومة صحية وملخص المشي',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: 'معلومة على الماشي',
          ),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );

    await prefs.setString(
      _lastSummaryNotificationDayKey.replaceFirst('%s', userId),
      dayKey,
    );
  }

  Future<void> requestPermissionOnFirstLaunch() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final prompted = prefs.getBool(_permissionPromptedKey) ?? false;
      if (prompted) return;

      await prefs.setBool(_permissionPromptedKey, true);
      final granted = await ensureActivityPermission(requestIfDenied: true);
      permissionGrantedNotifier.value = granted;
    } on MissingPluginException {
      debugPrint('permission_handler plugin not ready (first launch).');
      permissionGrantedNotifier.value = false;
    } catch (e) {
      debugPrint('requestPermissionOnFirstLaunch error: $e');
      permissionGrantedNotifier.value = false;
    }
  }

  Future<bool> ensureActivityPermission({
    required bool requestIfDenied,
    bool openSettingsIfPermanentlyDenied = false,
  }) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return true;

    try {
      var status = await Permission.activityRecognition.status;
      if (status.isGranted) {
        permissionGrantedNotifier.value = true;
        return true;
      }

      if (requestIfDenied) {
        status = await Permission.activityRecognition.request();
        if (status.isGranted) {
          permissionGrantedNotifier.value = true;
          return true;
        }
      }

      if (openSettingsIfPermanentlyDenied &&
          (status.isPermanentlyDenied || status.isRestricted)) {
        await openAppSettings();
      }

      permissionGrantedNotifier.value = false;
      return false;
    } on MissingPluginException {
      debugPrint(
        'permission_handler plugin not ready (ensureActivityPermission).',
      );
      permissionGrantedNotifier.value = false;
      return false;
    } catch (e) {
      debugPrint('ensureActivityPermission error: $e');
      permissionGrantedNotifier.value = false;
      return false;
    }
  }

  Future<bool> requestActivityPermissionFromCard() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return true;

    try {
      final status = await Permission.activityRecognition.request();
      if (status.isGranted) {
        permissionGrantedNotifier.value = true;
        return true;
      }

      if (status.isPermanentlyDenied || status.isRestricted) {
        await openAppSettings();
      }

      permissionGrantedNotifier.value = false;
      return false;
    } on MissingPluginException {
      debugPrint('permission_handler plugin not ready (card request).');
      permissionGrantedNotifier.value = false;
      return false;
    } catch (e) {
      debugPrint('requestActivityPermissionFromCard error: $e');
      permissionGrantedNotifier.value = false;
      return false;
    }
  }
}
