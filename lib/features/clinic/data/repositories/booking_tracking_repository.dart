import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking_model.dart';

class BookingTrackingInfo {
  final String clinicId;
  final String doctorName;
  final String departmentName;
  final int bookingNumber;
  final DateTime appointmentDate;
  final String? userId;

  const BookingTrackingInfo({
    required this.clinicId,
    required this.doctorName,
    required this.departmentName,
    required this.bookingNumber,
    required this.appointmentDate,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'clinicId': clinicId,
      'doctorName': doctorName,
      'departmentName': departmentName,
      'bookingNumber': bookingNumber,
      'appointmentDate': appointmentDate.toIso8601String(),
      'userId': userId,
    };
  }

  factory BookingTrackingInfo.fromJson(Map<String, dynamic> json) {
    return BookingTrackingInfo(
      clinicId: json['clinicId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      departmentName: json['departmentName'] ?? '',
      bookingNumber: json['bookingNumber'] ?? 0,
      appointmentDate:
          DateTime.tryParse(json['appointmentDate'] ?? '') ?? DateTime.now(),
      userId: json['userId'],
    );
  }

  String get id => buildTrackingId(
    clinicId: clinicId,
    bookingNumber: bookingNumber,
    appointmentDate: appointmentDate,
    userId: userId,
  );

  static String buildTrackingId({
    required String clinicId,
    required int bookingNumber,
    required DateTime appointmentDate,
    String? userId,
  }) {
    final normalizedUserId = (userId == null || userId.trim().isEmpty)
        ? 'guest'
        : userId.trim();
    return '$normalizedUserId|$clinicId|$bookingNumber|'
        '${appointmentDate.toIso8601String()}';
  }
}

class BookingQueueStatus {
  final int currentNumber;
  final int patientsAhead;
  final int totalActive;

  const BookingQueueStatus({
    required this.currentNumber,
    required this.patientsAhead,
    required this.totalActive,
  });
}

class BookingTrackingRepository {
  static const String _forceReloadKey = 'clinic_booking_tracking_force_reload';
  static const String _trackingListKey = 'clinic_booking_tracking_list';
  static const String _hiddenIdsKey = 'clinic_booking_tracking_hidden_ids';
  static const String _trackingKey = 'clinic_booking_tracking_info';
  static const String _hiddenKey = 'clinic_booking_tracking_hidden';

  final FirebaseFirestore _firestore;

  BookingTrackingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveTracking(BookingTrackingInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = await _loadSnapshot(prefs);
    final updated = [...snapshot.items];
    final existingIndex = updated.indexWhere((item) => item.id == info.id);
    if (existingIndex >= 0) {
      updated[existingIndex] = info;
    } else {
      updated.add(info);
    }
    await _persistTrackings(prefs, updated);
    final hiddenIds = {...snapshot.hiddenIds}..remove(info.id);
    await _persistHiddenIds(prefs, hiddenIds);
  }

  Future<BookingTrackingInfo?> loadTracking({String? userId}) async {
    final trackings = await loadTrackings(userId: userId);
    if (trackings.isEmpty) return null;
    trackings.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
    return trackings.first;
  }

  Future<List<BookingTrackingInfo>> loadTrackings({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = await _loadSnapshot(prefs);
    if (userId == null) return snapshot.items;
    return snapshot.items.where((item) => item.userId == userId).toList();
  }

  Future<Set<String>> loadHiddenTrackingIds() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = await _loadSnapshot(prefs);
    return snapshot.hiddenIds;
  }

  Future<void> setTrackingHidden(String trackingId, bool hidden) async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = await _loadSnapshot(prefs);
    final updated = {...snapshot.hiddenIds};
    if (hidden) {
      updated.add(trackingId);
    } else {
      updated.remove(trackingId);
    }
    await _persistHiddenIds(prefs, updated);
  }

  Future<void> setTrackingHiddenForClinic({
    required String clinicId,
    required bool hidden,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = await _loadSnapshot(prefs);
    final updated = {...snapshot.hiddenIds};
    final matchingIds = snapshot.items
        .where(
          (item) =>
              item.clinicId == clinicId &&
              (userId == null || item.userId == userId),
        )
        .map((item) => item.id);

    if (hidden) {
      updated.addAll(matchingIds);
    } else {
      updated.removeAll(matchingIds);
    }
    await _persistHiddenIds(prefs, updated);
  }

  Future<void> removeTracking(String trackingId) async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = await _loadSnapshot(prefs);
    final updatedItems = snapshot.items
        .where((item) => item.id != trackingId)
        .toList();
    await _persistTrackings(prefs, updatedItems);

    final updatedHidden = {...snapshot.hiddenIds}..remove(trackingId);
    await _persistHiddenIds(prefs, updatedHidden);
  }

  Future<void> requestTrackingReload() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_forceReloadKey, true);
  }

  Future<bool> consumeTrackingReload() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldReload = prefs.getBool(_forceReloadKey) ?? false;
    if (shouldReload) {
      await prefs.setBool(_forceReloadKey, false);
    }
    return shouldReload;
  }

  Future<BookingQueueStatus> fetchQueueStatus(BookingTrackingInfo info) async {
    final startOfDay = DateTime(
      info.appointmentDate.year,
      info.appointmentDate.month,
      info.appointmentDate.day,
    );
    final endOfDay = DateTime(
      info.appointmentDate.year,
      info.appointmentDate.month,
      info.appointmentDate.day,
      23,
      59,
      59,
    );

    final snapshot = await _firestore
        .collection('bookings')
        .where('clinicId', isEqualTo: info.clinicId)
        .where(
          'appointmentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'appointmentDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
        )
        .get();

    if (snapshot.docs.isEmpty) {
      return BookingQueueStatus(
        currentNumber: info.bookingNumber,
        patientsAhead: 0,
        totalActive: 0,
      );
    }

    final bookings = snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();

    final activeBookings = bookings
        .where(
          (booking) =>
              booking.status != BookingStatus.cancelled &&
              booking.status != BookingStatus.completed,
        )
        .toList();

    if (activeBookings.isEmpty) {
      return BookingQueueStatus(
        currentNumber: info.bookingNumber,
        patientsAhead: 0,
        totalActive: 0,
      );
    }

    var currentNumber = activeBookings.first.bookingNumber;
    for (final booking in activeBookings) {
      if (booking.bookingNumber < currentNumber) {
        currentNumber = booking.bookingNumber;
      }
    }

    final ahead = info.bookingNumber - currentNumber;

    return BookingQueueStatus(
      currentNumber: currentNumber,
      patientsAhead: ahead < 0 ? 0 : ahead,
      totalActive: activeBookings.length,
    );
  }

  Future<_TrackingSnapshot> _loadSnapshot(SharedPreferences prefs) async {
    var items = _decodeTrackingList(prefs.getString(_trackingListKey));
    var hiddenIds = _decodeHiddenIds(prefs.getString(_hiddenIdsKey));

    if (items.isEmpty) {
      final legacyRaw = prefs.getString(_trackingKey);
      if (legacyRaw != null && legacyRaw.isNotEmpty) {
        final legacyDecoded = jsonDecode(legacyRaw);
        if (legacyDecoded is Map) {
          final legacyInfo = BookingTrackingInfo.fromJson(
            Map<String, dynamic>.from(legacyDecoded),
          );
          items = [legacyInfo];
          if (prefs.getBool(_hiddenKey) ?? false) {
            hiddenIds = {legacyInfo.id};
          }
          await _persistTrackings(prefs, items);
          await _persistHiddenIds(prefs, hiddenIds);
        }
      }

      await prefs.remove(_trackingKey);
      await prefs.remove(_hiddenKey);
    }

    return _TrackingSnapshot(items, hiddenIds);
  }

  List<BookingTrackingInfo> _decodeTrackingList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    final result = <BookingTrackingInfo>[];
    for (final item in decoded) {
      if (item is Map) {
        result.add(
          BookingTrackingInfo.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }
    return result;
  }

  Set<String> _decodeHiddenIds(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! List) return {};
    return decoded.whereType<String>().toSet();
  }

  Future<void> _persistTrackings(
    SharedPreferences prefs,
    List<BookingTrackingInfo> items,
  ) async {
    final payload = items.map((item) => item.toJson()).toList();
    await prefs.setString(_trackingListKey, jsonEncode(payload));
  }

  Future<void> _persistHiddenIds(
    SharedPreferences prefs,
    Set<String> hiddenIds,
  ) async {
    await prefs.setString(_hiddenIdsKey, jsonEncode(hiddenIds.toList()));
  }
}

class _TrackingSnapshot {
  final List<BookingTrackingInfo> items;
  final Set<String> hiddenIds;

  const _TrackingSnapshot(this.items, this.hiddenIds);
}
